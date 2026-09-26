// 서재 [책] 상태 판정·필터·정렬 (2026-09-26).

import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/book/domain/library_entry.dart';
import 'package:bookquote/features/book/domain/reading_dates.dart';
import 'package:bookquote/features/library/state/library_sort.dart';
import 'package:flutter_test/flutter_test.dart';

LibraryEntry _e(
  String id, {
  String title = '제목',
  String? author,
  int addedDay = 1,
  DateTime? startedAt,
  DateTime? finishedAt,
  String readingStatus = 'reading',
  int? rating,
}) =>
    (
      book: Book(id: id, isbn13: '', title: title, author: author),
      addedAt: DateTime(2026, 9, addedDay),
      startedAt: startedAt,
      finishedAt: finishedAt,
      readingStatus: readingStatus,
      rating: rating,
    );

List<String> _ids(List<LibraryEntry> list) => [for (final e in list) e.book.id];

void main() {
  group('libraryStatusOf — 날짜 우선, 기록 없으면 미분류', () {
    test('완독일 있으면 완독(시작일·상태 무관)', () {
      expect(
        libraryStatusOf(_e('a',
            startedAt: DateTime(2026, 1, 1),
            finishedAt: DateTime(2026, 2, 1),
            readingStatus: 'wishlist')),
        ReadingStatus.finished,
      );
    });

    test('시작일만 있으면 읽는 중', () {
      expect(
        libraryStatusOf(_e('a', startedAt: DateTime(2026, 1, 1))),
        ReadingStatus.reading,
      );
    });

    test('날짜 없으면 담을 때 고른 상태(finished/wishlist)', () {
      expect(libraryStatusOf(_e('a', readingStatus: 'finished')),
          ReadingStatus.finished);
      expect(libraryStatusOf(_e('a', readingStatus: 'wishlist')),
          ReadingStatus.wishlist);
    });

    test('날짜 없고 기본값 reading → 미분류(null)', () {
      expect(libraryStatusOf(_e('a')), isNull);
    });
  });

  test('filterLibrary — null은 전체, 미분류 책은 상태 필터에서 빠짐', () {
    final all = [
      _e('reading', startedAt: DateTime(2026, 1, 1)),
      _e('wish', readingStatus: 'wishlist'),
      _e('unknown'),
    ];
    expect(_ids(filterLibrary(all, null)), ['reading', 'wish', 'unknown']);
    expect(_ids(filterLibrary(all, ReadingStatus.reading)), ['reading']);
    expect(_ids(filterLibrary(all, ReadingStatus.wishlist)), ['wish']);
    expect(filterLibrary(all, ReadingStatus.finished), isEmpty);
  });

  group('sortLibrary', () {
    test('최근 담은 순 — 원래 순서(repo가 added_at desc로 줌) 유지', () {
      final list = [_e('b', addedDay: 2), _e('a', addedDay: 1)];
      expect(_ids(sortLibrary(list, LibrarySort.recentlyAdded)), ['b', 'a']);
    });

    test('제목순 — 가나다', () {
      final list = [
        _e('3', title: '하늘'),
        _e('1', title: '가을'),
        _e('2', title: '나무'),
      ];
      expect(_ids(sortLibrary(list, LibrarySort.title)), ['1', '2', '3']);
    });

    test('저자순 — 저자 없는 책은 뒤로', () {
      final list = [
        _e('none'),
        _e('kim', author: '김작가'),
        _e('ahn', author: '안작가'),
      ];
      expect(_ids(sortLibrary(list, LibrarySort.author)),
          ['kim', 'ahn', 'none']);
    });

    test('별점 높은 순 — 미평가는 뒤로, 동률은 최근 담은 순', () {
      final list = [
        _e('none', addedDay: 9),
        _e('three-old', rating: 3, addedDay: 1),
        _e('five', rating: 5, addedDay: 2),
        _e('three-new', rating: 3, addedDay: 5),
      ];
      expect(_ids(sortLibrary(list, LibrarySort.rating)),
          ['five', 'three-new', 'three-old', 'none']);
    });

    test('인용 많은 순 — 카운트 없는 책은 0', () {
      final list = [_e('a', addedDay: 3), _e('b', addedDay: 2), _e('c')];
      expect(
        _ids(sortLibrary(list, LibrarySort.quoteCount,
            quoteCounts: const {'b': 4, 'c': 1})),
        ['b', 'c', 'a'],
      );
    });
  });
}
