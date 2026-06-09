// 책 후기 데이터 레이어 (PR29).
//
// `book_reviews` 테이블 CRUD. RLS가 본인 row만 자동 게이트. 친구 read 정책은
// 깔려 있으나 V1.0 클라이언트는 미사용(V1.1에서 친구 프로필에 후기 노출 시 활용).
//
// 1책당 1개라 upsert로 모든 변경(생성·수정)을 처리한다. 명시적 update/insert 분리는
// 호출자 부담만 키우고 race 위험 — `onConflict: 'user_id,book_id'`로 단일 메서드.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/book_review.dart';

class BookReviewRepositoryException implements Exception {
  BookReviewRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'BookReviewRepositoryException($code): $message';
}

/// PR29-F: 책별 공개 후기 한 줄 — 작성자 프로필 join. RPC `book_reviews_by_book`
/// 응답의 도메인 표현. [id]는 review_likes 좋아요 타깃(PR-LC).
typedef PublicBookReview = ({
  String id,
  String userId,
  String? displayName,
  String? avatarUrl,
  String text,
  DateTime createdAt,
  DateTime updatedAt,
});

/// PR29-I: 홈 "최근 독자 후기" row 한 줄 — 작성자 프로필 + 책 정보(title/cover_url) join.
/// 본인 후기 제외(발견 목적). 탭하면 `/book/:bookId` 진입. [id]는 좋아요 타깃(PR-LC).
typedef RecentBookReview = ({
  String id,
  String userId,
  String? displayName,
  String? avatarUrl,
  String bookId,
  String bookTitle,
  String? bookCoverUrl,
  String text,
  DateTime updatedAt,
});

class BookReviewRepository {
  BookReviewRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'book_reviews';

  /// 내가 이 책에 쓴 후기. 없거나 비로그인이면 null.
  Future<BookReview?> getMyReview(String bookId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('user_id', uid)
          .eq('book_id', bookId)
          .maybeSingle();
      if (row == null) return null;
      return BookReview.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      throw BookReviewRepositoryException('FETCH_FAILED', e.message);
    }
  }

  /// 후기를 작성/수정한다. DB CHECK가 1~3000자(btrim 후)를 강제하므로
  /// 호출자는 [BookReviewLimits.validate]로 사전 검증해 사용자에게 즉시 피드백.
  /// `created_at`은 처음 insert 때만 채워지고 update 시 보존(`onConflict`).
  Future<BookReview> upsertMyReview({
    required String bookId,
    required String text,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw BookReviewRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    final trimmed = text.trim();
    try {
      final row = await _client
          .from(_table)
          .upsert(
            <String, dynamic>{
              'user_id': uid,
              'book_id': bookId,
              'text': trimmed,
            },
            onConflict: 'user_id,book_id',
          )
          .select()
          .single();
      return BookReview.fromJson(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      // CHECK constraint(길이) 위반
      if (e.code == '23514') {
        throw BookReviewRepositoryException(
          'VAL_LENGTH',
          '후기 길이는 1~3000자 사이여야 해요.',
        );
      }
      throw BookReviewRepositoryException('UPSERT_FAILED', e.message);
    }
  }

  /// PR29-F: 이 책의 공개 후기 목록 (본인 제외). 작성자 프로필 join.
  /// RLS·RPC가 비공개 프로필·차단된 사용자 자동 제외. anon 호출 가능.
  Future<List<PublicBookReview>> listPublicReviewsByBook(String bookId) async {
    try {
      final rows = await _client.rpc(
        'book_reviews_by_book',
        params: {'p_book_id': bookId},
      ) as List<dynamic>;
      return rows.cast<Map<String, dynamic>>().map((r) {
        return (
          id: r['id'] as String,
          userId: r['user_id'] as String,
          displayName: r['display_name'] as String?,
          avatarUrl: r['avatar_url'] as String?,
          text: r['text'] as String,
          createdAt: DateTime.parse(r['created_at'] as String),
          updatedAt: DateTime.parse(r['updated_at'] as String),
        );
      }).toList(growable: false);
    } on PostgrestException catch (e) {
      throw BookReviewRepositoryException('LIST_FAILED', e.message);
    }
  }

  /// PR29-I: 홈 "최근 독자 후기" row용. 본인 외 공개 후기 + 책 정보 최신순.
  /// 미로그인 호출 가능 (anon grant). 0건이면 빈 리스트.
  Future<List<RecentBookReview>> listRecentPublicReviews({int limit = 10}) async {
    try {
      final rows = await _client.rpc(
        'recent_public_book_reviews',
        params: {'p_limit': limit},
      ) as List<dynamic>;
      return rows.cast<Map<String, dynamic>>().map((r) {
        return (
          id: r['id'] as String,
          userId: r['user_id'] as String,
          displayName: r['display_name'] as String?,
          avatarUrl: r['avatar_url'] as String?,
          bookId: r['book_id'] as String,
          bookTitle: r['book_title'] as String,
          bookCoverUrl: r['book_cover_url'] as String?,
          text: r['text'] as String,
          updatedAt: DateTime.parse(r['updated_at'] as String),
        );
      }).toList(growable: false);
    } on PostgrestException catch (e) {
      throw BookReviewRepositoryException('LIST_RECENT_FAILED', e.message);
    }
  }

  /// 후기 삭제. 없으면 무해(0 row deleted).
  Future<void> deleteMyReview(String bookId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client
          .from(_table)
          .delete()
          .eq('user_id', uid)
          .eq('book_id', bookId);
    } on PostgrestException catch (e) {
      throw BookReviewRepositoryException('DELETE_FAILED', e.message);
    }
  }
}

final bookReviewRepositoryProvider = Provider<BookReviewRepository>((ref) {
  return BookReviewRepository(supabase);
});
