// PR29: 책 후기 상태 providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/book_review_repository.dart';
import '../domain/book_review.dart';

/// 이 책에 내가 쓴 후기(없으면 null). 책 상세에서 watch.
/// 작성/수정/삭제 후 `ref.invalidate(myBookReviewProvider(bookId))`.
final myBookReviewProvider =
    FutureProvider.autoDispose.family<BookReview?, String>((ref, bookId) async {
  final repo = ref.read(bookReviewRepositoryProvider);
  return repo.getMyReview(bookId);
});

/// PR29-F: 이 책의 공개 후기 목록 (본인 제외, 작성자 프로필 포함).
/// RLS가 is_library_public·차단 게이트 — 미로그인도 호출 가능.
final publicBookReviewsByBookProvider = FutureProvider.autoDispose
    .family<List<PublicBookReview>, String>((ref, bookId) async {
  final repo = ref.read(bookReviewRepositoryProvider);
  return repo.listPublicReviewsByBook(bookId);
});

/// PR29-I: 홈 "최근 독자 후기" row 데이터. 본인 외 최신 N개 + 책 정보.
final recentPublicReviewsProvider =
    FutureProvider.autoDispose<List<RecentBookReview>>((ref) async {
  final repo = ref.read(bookReviewRepositoryProvider);
  return repo.listRecentPublicReviews();
});
