// 책 단건 조회용 providers.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/book_repository.dart';
import '../domain/book.dart';
import '../domain/reading_dates.dart';

/// `/book/:id` 라우트의 :id로 단건 조회. 캐시는 Riverpod 기본(autoDispose).
final bookByIdProvider =
    FutureProvider.autoDispose.family<Book?, String>((ref, id) async {
  final repo = ref.read(bookRepositoryProvider);
  return repo.getById(id);
});

/// ISBN13으로 단건 조회. AladinBookDto upsert 결과 캐싱 등에 사용.
final bookByIsbnProvider =
    FutureProvider.autoDispose.family<Book?, String>((ref, isbn13) async {
  final repo = ref.read(bookRepositoryProvider);
  return repo.getByIsbn(isbn13);
});

/// 내 서재 책 목록 (added_at desc). `ref.invalidate(myLibraryProvider)`로
/// 추가/삭제 후 갱신.
final myLibraryProvider = FutureProvider.autoDispose<List<Book>>((ref) async {
  final repo = ref.read(bookRepositoryProvider);
  return repo.listMyLibrary();
});

/// 이 책에 내가 매긴 별점 (1~5, 미평가/비로그인이면 null). 별점 변경 후
/// `ref.invalidate(myRatingProvider(bookId))`로 갱신.
final myRatingProvider =
    FutureProvider.autoDispose.family<int?, String>((ref, bookId) async {
  final repo = ref.read(bookRepositoryProvider);
  return repo.getMyRating(bookId);
});

/// 이 책이 내 서재에 담겨 있는지 (EXISTS). 담기/빼기 후
/// `ref.invalidate(isInLibraryProvider(bookId))`로 갱신.
final isInLibraryProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, bookId) async {
  return ref.read(bookRepositoryProvider).isInLibrary(bookId);
});

/// 이 책의 내 독서 시작/완독일 (PR17-A). 비로그인 또는 서재에 없으면 빈 ReadingDates.
/// 시작/완독 set/unset 후 `ref.invalidate(readingDatesProvider(bookId))`로 갱신.
final readingDatesProvider =
    FutureProvider.autoDispose.family<ReadingDates, String>((ref, bookId) async {
  return ref.read(bookRepositoryProvider).getReadingDates(bookId);
});

/// PR23: 지금 읽고 있는 책 (홈 NowReadingRow). 시작/완독 변경 시
/// `ref.invalidate(currentlyReadingProvider)`. 홈은 BottomNav 첫 슬롯이라
/// 캐시 유지가 자연(autoDispose 안 둠).
final currentlyReadingProvider =
    FutureProvider<List<CurrentlyReading>>((ref) async {
  return ref.read(bookRepositoryProvider).listCurrentlyReading();
});
