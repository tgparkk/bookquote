// 신고·차단 데이터 레이어 (PR25 — Google Play UGC 정책 대응).
//
// 친구 기능(PR18)으로 사용자끼리 인용구·프로필이 노출되므로 ① 신고 ② 차단이
// 정책상 필수. 본 repository가 두 동작의 DB 접점.
//
// - report — reports 테이블 INSERT. reporter만 본인 row 작성(RLS).
// - block/unblock — blocks 테이블 upsert/delete. blocks insert 트리거가 양방향
//   follow를 자동 정리(차단 = 즉시 언팔).
// - listBlocked — list_blocked_profiles RPC. 차단한 상대 프로필은 친구 RLS가
//   is_blocked_with로 가리므로 SECURITY DEFINER RPC로 표시 정보를 가져온다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../profile/domain/profile.dart';

class ModerationRepositoryException implements Exception {
  ModerationRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'ModerationRepositoryException($code): $message';
}

class ModerationRepository {
  ModerationRepository(this._client);

  final SupabaseClient _client;

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw ModerationRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    return uid;
  }

  /// 사용자 또는 인용구 신고. [reportedUserId]·[reportedQuoteId] 중 하나는 필수
  /// (DB CHECK도 동일 강제).
  Future<void> report({
    String? reportedUserId,
    String? reportedQuoteId,
    required String reason,
    String? detail,
  }) async {
    final uid = _requireUid();
    if (reportedUserId == null && reportedQuoteId == null) {
      throw ModerationRepositoryException('INVALID_TARGET', '신고 대상이 없어요.');
    }
    final trimmedDetail = detail?.trim();
    try {
      await _client.from('reports').insert(<String, dynamic>{
        'reporter_id': uid,
        'reported_user_id': ?reportedUserId,
        'reported_quote_id': ?reportedQuoteId,
        'reason': reason,
        if (trimmedDetail != null && trimmedDetail.isNotEmpty)
          'detail': trimmedDetail,
      });
    } on PostgrestException catch (e) {
      throw ModerationRepositoryException('REPORT_FAILED', e.message);
    }
  }

  /// 사용자 차단. upsert로 idempotent — 두 번 호출해도 안전. DB 트리거가 양방향
  /// follow를 정리한다.
  Future<void> block(String userId) async {
    final uid = _requireUid();
    if (uid == userId) {
      throw ModerationRepositoryException('SELF_BLOCK', '자기 자신은 차단할 수 없어요.');
    }
    try {
      await _client.from('blocks').upsert(<String, dynamic>{
        'blocker_id': uid,
        'blocked_id': userId,
      });
    } on PostgrestException catch (e) {
      throw ModerationRepositoryException('BLOCK_FAILED', e.message);
    }
  }

  /// 차단 해제. 없는 row를 지워도 무해(0 row deleted).
  Future<void> unblock(String userId) async {
    final uid = _requireUid();
    try {
      await _client
          .from('blocks')
          .delete()
          .eq('blocker_id', uid)
          .eq('blocked_id', userId);
    } on PostgrestException catch (e) {
      throw ModerationRepositoryException('UNBLOCK_FAILED', e.message);
    }
  }

  /// 내가 차단한 사용자 프로필 목록 (차단 목록 화면).
  ///
  /// 차단한 상대는 친구 RLS(`is_blocked_with`)가 profiles 조회를 0 row로 막으므로
  /// `list_blocked_profiles` SECURITY DEFINER RPC로 표시 정보를 가져온다.
  /// 미로그인이면 빈 리스트.
  Future<List<Profile>> listBlocked() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const <Profile>[];
    try {
      final rows = await _client.rpc('list_blocked_profiles');
      return (rows as List)
          .cast<Map<String, dynamic>>()
          .map(Profile.fromRow)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw ModerationRepositoryException('LIST_FAILED', e.message);
    }
  }
}

final moderationRepositoryProvider = Provider<ModerationRepository>((ref) {
  return ModerationRepository(supabase);
});
