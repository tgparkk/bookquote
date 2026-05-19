// 단방향 친구 그래프 데이터 레이어 (PR18-A 코어 + PR18-B 검색).
//
// V1.0 메서드:
// - follow/unfollow/isFollowing (PR18-A) — 토글 코어.
// - searchByDisplayName (PR18-B) — Me 친구 찾기 화면. DB RLS + 클라 단 명시 필터
//   이중 방어(DECISIONS 2026-05-18 P0).
// - followersCountForBook (PR18-D 예정), listFollowing/listFollowers (PR18-C 예정).
//
// follows 테이블 RLS는 self-only(본인 follower_id 관련 row만 select/insert/delete).
// 자기 자신 follow는 DB CHECK + 화면 본인 진입 redirect + 여기서 한 번 더 검증.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../profile/domain/profile.dart';

class FollowRepositoryException implements Exception {
  FollowRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'FollowRepositoryException($code): $message';
}

class FollowRepository {
  FollowRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'follows';

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw FollowRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    return uid;
  }

  /// 단방향 follow. upsert로 idempotent — 두 번 호출해도 안전.
  Future<void> follow(String userId) async {
    final uid = _requireUid();
    if (uid == userId) {
      throw FollowRepositoryException(
        'SELF_FOLLOW',
        '자기 자신은 팔로우할 수 없어요.',
      );
    }
    try {
      await _client.from(_table).upsert(<String, dynamic>{
        'follower_id': uid,
        'followee_id': userId,
      });
    } on PostgrestException catch (e) {
      throw FollowRepositoryException('INSERT_FAILED', e.message);
    }
  }

  /// 언팔로우. 없는 follow row를 지워도 무해(0 row deleted).
  Future<void> unfollow(String userId) async {
    final uid = _requireUid();
    try {
      await _client
          .from(_table)
          .delete()
          .eq('follower_id', uid)
          .eq('followee_id', userId);
    } on PostgrestException catch (e) {
      throw FollowRepositoryException('DELETE_FAILED', e.message);
    }
  }

  /// `userId`를 내가 팔로우 중인가? RLS가 본인 follower row 가시성을 보장.
  /// 미로그인이면 false (NOT_AUTHENTICATED throw하지 않음 — UI 단순화).
  Future<bool> isFollowing(String userId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final row = await _client
          .from(_table)
          .select('follower_id')
          .eq('follower_id', uid)
          .eq('followee_id', userId)
          .maybeSingle();
      return row != null;
    } on PostgrestException {
      // 정책 거부·일시 네트워크 오류 — UI는 "팔로우 아님"으로 안전 표시.
      return false;
    }
  }

  /// 내가 팔로우 중인 사용자 수 (PR18-B). 홈 친구 찾기 CTA 조건부 노출용.
  /// RLS가 본인 follower_id row만 가시화하므로 단순 select + 길이.
  /// 미로그인이면 0. 에러도 0(UI는 "친구 없음"으로 안전 fallback).
  Future<int> myFollowingCount() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    try {
      final rows = await _client
          .from(_table)
          .select('followee_id')
          .eq('follower_id', uid);
      return (rows as List).length;
    } on PostgrestException {
      return 0;
    }
  }

  /// 이 책을 서재에 담은 *친구* 수 (PR18-D 책 상세 "이 책을 담은 친구 N명").
  ///
  /// RLS가 게이트: `user_books_friends_read` 정책이 친구 + `is_library_public=true`
  /// 인 row만 통과시킴. 본인 row(`user_books_own`)는 보이므로 `neq(myUid)`로 제외.
  /// 미로그인은 RLS상 친구 read 0 row → 본인도 없으니 0.
  Future<int> countFriendsWithBook(String bookId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    try {
      final res = await _client
          .from('user_books')
          .select('user_id')
          .eq('book_id', bookId)
          .neq('user_id', uid)
          .count(CountOption.exact);
      return res.count;
    } on PostgrestException {
      return 0;
    }
  }

  /// 이 책을 담은 친구 프로필 목록 (PR18-D 시트 미니리스트). 카운트와 분리 — 시트
  /// 열릴 때만 fetch(lazy). 2-step: user_books 가시 row → profiles inFilter.
  Future<List<Profile>> friendsWithBook(
    String bookId, {
    int limit = 50,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const <Profile>[];
    try {
      final userBookRows = await _client
          .from('user_books')
          .select('user_id')
          .eq('book_id', bookId)
          .neq('user_id', uid)
          .order('added_at', ascending: false)
          .limit(limit);
      final ids = (userBookRows as List)
          .map((r) => (r as Map)['user_id'] as String?)
          .whereType<String>()
          .toList(growable: false);
      if (ids.isEmpty) return const <Profile>[];
      final profileRows = await _client
          .from('profiles')
          .select(
            'id, display_name, avatar_url, public_handle, is_library_public',
          )
          .inFilter('id', ids);
      final byId = <String, Profile>{
        for (final r in (profileRows as List).cast<Map<String, dynamic>>())
          r['id'] as String: Profile.fromRow(r),
      };
      return [for (final id in ids) if (byId[id] != null) byId[id]!];
    } on PostgrestException catch (e) {
      throw FollowRepositoryException('LIST_FAILED', e.message);
    }
  }

  /// `userId`의 팔로잉 목록 (PR18-C 친구 프로필 헤더 카운트 시트).
  ///
  /// follows SELECT RLS(2026-05-19 확장)가 게이트: ① 본인 관련 row 또는 ② 두 endpoint
  /// 모두 공개 프로필인 row만. 따라서 *비공개 프로필*의 팔로잉은 본인 외 0 row.
  ///
  /// 2-step: ① `follows` 정방향 row 가져오기(follower_id=userId) ② 거기서 추출한
  /// `followee_id` set으로 `profiles` 한 번에 조회. profiles SELECT RLS가 비공개
  /// 프로필을 거르므로 일부가 누락될 수 있음 → "공개 + 보이는 사용자"만 반환.
  Future<List<Profile>> listFollowing(String userId, {int limit = 100}) async {
    return _listFollowSide(
      keyColumn: 'follower_id',
      otherColumn: 'followee_id',
      keyValue: userId,
      limit: limit,
    );
  }

  /// `userId`의 팔로워 목록 (PR18-C). 동일 패턴, 방향만 반대.
  Future<List<Profile>> listFollowers(String userId, {int limit = 100}) async {
    return _listFollowSide(
      keyColumn: 'followee_id',
      otherColumn: 'follower_id',
      keyValue: userId,
      limit: limit,
    );
  }

  /// `userId`의 팔로잉/팔로워 카운트 (PR18-C 헤더). 카운트는 RLS 통과한 row만 —
  /// 비공개 프로필의 그래프는 (본인 외) 0으로 보일 수 있음. social proof V1 정책.
  Future<int> countFollowing(String userId) async =>
      _countFollowSide('follower_id', userId);
  Future<int> countFollowers(String userId) async =>
      _countFollowSide('followee_id', userId);

  Future<int> _countFollowSide(String column, String userId) async {
    try {
      final res = await _client
          .from(_table)
          .select(column)
          .eq(column, userId)
          .count(CountOption.exact);
      return res.count;
    } on PostgrestException {
      return 0;
    }
  }

  Future<List<Profile>> _listFollowSide({
    required String keyColumn,
    required String otherColumn,
    required String keyValue,
    required int limit,
  }) async {
    try {
      final followRows = await _client
          .from(_table)
          .select(otherColumn)
          .eq(keyColumn, keyValue)
          .order('created_at', ascending: false)
          .limit(limit);
      final ids = (followRows as List)
          .map((r) => (r as Map)[otherColumn] as String?)
          .whereType<String>()
          .toList(growable: false);
      if (ids.isEmpty) return const <Profile>[];
      final profileRows = await _client
          .from('profiles')
          .select(
            'id, display_name, avatar_url, public_handle, is_library_public',
          )
          .inFilter('id', ids);
      // 정렬 보존: follow 순서대로 reorder (profile 결과는 id 기준 임의 순)
      final byId = <String, Profile>{
        for (final r in (profileRows as List).cast<Map<String, dynamic>>())
          r['id'] as String: Profile.fromRow(r),
      };
      return [for (final id in ids) if (byId[id] != null) byId[id]!];
    } on PostgrestException catch (e) {
      throw FollowRepositoryException('LIST_FAILED', e.message);
    }
  }

  /// `display_name` `ilike '%query%'` 검색 (PR18-B). 공개 프로필만 반환.
  ///
  /// **이중 방어** (DECISIONS 2026-05-18 P0):
  /// ① `profiles` SELECT RLS = `using(is_library_public = true OR id = auth.uid())`가
  ///    1차 게이트. 비공개 프로필은 DB 단에서 0 row.
  /// ② 클라이언트 단에 `.eq('is_library_public', true)` 명시 필터로 본인이 비공개일 때
  ///    자기 자신이 결과에 나오는 케이스도 거른다(self는 검색 결과로 보지 않음).
  ///
  /// 빈 쿼리는 즉시 빈 리스트.
  Future<List<Profile>> searchByDisplayName(
    String query, {
    int limit = 20,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const <Profile>[];
    // ilike는 `%`/`_` 와일드카드라 사용자 입력에 포함되면 의미 변화. 단순 escape.
    final escaped =
        trimmed.replaceAll(r'\', r'\\').replaceAll('%', r'\%').replaceAll('_', r'\_');
    try {
      final rows = await _client
          .from('profiles')
          .select(
            'id, display_name, avatar_url, public_handle, is_library_public',
          )
          .ilike('display_name', '%$escaped%')
          .eq('is_library_public', true)
          .limit(limit);
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(Profile.fromRow)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw FollowRepositoryException('SEARCH_FAILED', e.message);
    }
  }
}

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(supabase);
});
