// 단방향 친구 그래프 데이터 레이어 — 코어 (PR18-A).
//
// V1.0 = follow/unfollow/isFollowing 3개만. 검색(searchByDisplayName)·
// 카운트(followersCountForBook)·리스트(listFollowers/Following)는 PR18-B에서
// 추가. follows 테이블 RLS는 self-only(SELECT/INSERT/DELETE 모두 본인의
// follower_id에 한해)로 제3자의 follow 그래프 사생활을 DB가 강제.
//
// 자기 자신 follow는 DB CHECK + 화면 본인 진입 redirect로 이중 차단.
// 여기서도 한 번 더 검증해 사용자에게 명확한 에러 메시지를 돌려준다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';

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
}

final followRepositoryProvider = Provider<FollowRepository>((ref) {
  return FollowRepository(supabase);
});
