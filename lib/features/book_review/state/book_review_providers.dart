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
