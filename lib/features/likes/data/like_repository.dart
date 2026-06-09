// 좋아요 데이터 레이어 (PR-LB).
//
// quote_likes / review_likes 두 테이블을 한 레포로 다룬다(대상 종류만 다르고 모양은
// 동일). RLS가 게이트를 전담하므로 클라엔 별도 가시성/차단 필터 0(DB가 막음 = 신뢰
// 단일 출처). 마이그레이션: `20260609111229_likes.sql`.
//
// 핵심:
// ① 토글은 멱등 — 좋아요는 `on conflict do nothing`(upsert ignoreDuplicates), 취소는
//    delete. 더블탭·오프라인 재전송이 무해.
// ② 카운트는 `*_like_counts` RPC(INVOKER)로 id 배열을 한 번에 집계(N+1 회피).
//    liker_id는 반환되지 않음 — "누가 눌렀나" 목록은 앱에 노출 안 함(프라이버시 A안).
// ③ self-like는 DB INSERT 정책(`user_id <> liker_id`)이 막음 → 본인 콘텐츠엔 애초에
//    버튼을 안 띄우지만, 우회 호출도 42501로 거부.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';

class LikeRepositoryException implements Exception {
  LikeRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'LikeRepositoryException($code): $message';
}

/// 좋아요 대상 종류. 테이블·id 컬럼·카운트 RPC 이름을 함께 들고 다녀 분기 0.
enum LikeTargetKind {
  quote(table: 'quote_likes', idColumn: 'quote_id', countsRpc: 'quote_like_counts'),
  review(table: 'review_likes', idColumn: 'review_id', countsRpc: 'review_like_counts');

  const LikeTargetKind({
    required this.table,
    required this.idColumn,
    required this.countsRpc,
  });

  final String table;
  final String idColumn;
  final String countsRpc;
}

/// 한 대상의 좋아요 집계 — 총 수 + 본인이 눌렀는지. (liker 목록은 미노출)
typedef LikeCount = ({int n, bool likedByMe});

/// 좋아요 0건·미조회 기본값.
const LikeCount kEmptyLikeCount = (n: 0, likedByMe: false);

extension LikeCountX on LikeCount {
  /// 낙관적 토글 — 네트워크 응답 전 UI에 즉시 반영할 다음 상태.
  /// 누름→취소면 -1(0 미만 방지), 안누름→누름이면 +1. 위젯·테스트 공용.
  LikeCount get toggled => likedByMe
      ? (n: n > 0 ? n - 1 : 0, likedByMe: false)
      : (n: n + 1, likedByMe: true);
}

class LikeRepository {
  LikeRepository(this._client);

  final SupabaseClient _client;

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw LikeRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    return uid;
  }

  /// 좋아요 설정/해제. [liked]=true면 멱등 insert(on conflict do nothing),
  /// false면 delete(없어도 무해). 본인 콘텐츠/비가시 대상은 DB 정책이 42501로 거부.
  Future<void> setLiked({
    required LikeTargetKind kind,
    required String targetId,
    required bool liked,
  }) async {
    final uid = _requireUid();
    try {
      if (liked) {
        await _client.from(kind.table).upsert(
          <String, dynamic>{kind.idColumn: targetId, 'liker_id': uid},
          onConflict: '${kind.idColumn},liker_id',
          ignoreDuplicates: true,
        );
      } else {
        await _client
            .from(kind.table)
            .delete()
            .eq(kind.idColumn, targetId)
            .eq('liker_id', uid);
      }
    } on PostgrestException catch (e) {
      throw LikeRepositoryException('TOGGLE_FAILED', e.message);
    }
  }

  /// 대상 id 배열별 좋아요 집계. 한 화면(피드·목록)의 가시 id를 한 RPC로 모아 받아
  /// N+1 회피. 안 보이는(비가시·차단) 대상은 결과에서 빠지므로 호출자가
  /// [kEmptyLikeCount]로 폴백. 빈 입력이면 빈 맵.
  Future<Map<String, LikeCount>> counts({
    required LikeTargetKind kind,
    required List<String> targetIds,
  }) async {
    if (targetIds.isEmpty) return const {};
    try {
      final rows = await _client.rpc(
        kind.countsRpc,
        params: {'p_ids': targetIds},
      ) as List<dynamic>;
      final out = <String, LikeCount>{};
      for (final r in rows.cast<Map<String, dynamic>>()) {
        final id = r[kind.idColumn] as String;
        out[id] = (
          n: (r['n'] as num).toInt(),
          likedByMe: (r['liked_by_me'] as bool?) ?? false,
        );
      }
      return out;
    } on PostgrestException catch (e) {
      throw LikeRepositoryException('COUNTS_FAILED', e.message);
    }
  }
}

final likeRepositoryProvider = Provider<LikeRepository>((ref) {
  return LikeRepository(supabase);
});
