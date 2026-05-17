// PR17-C: buildCalendarMarkers 단위 테스트 — 시작·완독 마커를 날짜별로 grouping.

import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/book/domain/user_book_on_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const book1 = Book(id: 'b1', isbn13: '9791111111111', title: '미드나잇 라이브러리');
  const book2 = Book(id: 'b2', isbn13: '9792222222222', title: '데미안');

  group('buildCalendarMarkers', () {
    test('빈 입력 → 빈 맵', () {
      expect(buildCalendarMarkers(const [], 2026, 5), isEmpty);
    });

    test('시작일만 그 달 안 → started 1건', () {
      final markers = buildCalendarMarkers([
        UserBookReadingRow(book: book1, startedAt: DateTime(2026, 5, 10)),
      ], 2026, 5);

      expect(markers, hasLength(1));
      expect(
        markers[DateTime(2026, 5, 10)]!.first.kind,
        ReadingMarkKind.started,
      );
    });

    test('완독일만 그 달 안 → finished 1건', () {
      final markers = buildCalendarMarkers([
        UserBookReadingRow(book: book1, finishedAt: DateTime(2026, 5, 17)),
      ], 2026, 5);

      expect(
        markers[DateTime(2026, 5, 17)]!.first.kind,
        ReadingMarkKind.finished,
      );
    });

    test('같은 날 시작+완독 → both 1건', () {
      final markers = buildCalendarMarkers([
        UserBookReadingRow(
          book: book1,
          startedAt: DateTime(2026, 5, 15),
          finishedAt: DateTime(2026, 5, 15),
        ),
      ], 2026, 5);

      expect(markers, hasLength(1));
      expect(
        markers[DateTime(2026, 5, 15)]!.first.kind,
        ReadingMarkKind.both,
      );
    });

    test('다른 날 시작·완독 → 두 entry', () {
      final markers = buildCalendarMarkers([
        UserBookReadingRow(
          book: book1,
          startedAt: DateTime(2026, 5, 10),
          finishedAt: DateTime(2026, 5, 17),
        ),
      ], 2026, 5);

      expect(markers, hasLength(2));
      expect(
        markers[DateTime(2026, 5, 10)]!.first.kind,
        ReadingMarkKind.started,
      );
      expect(
        markers[DateTime(2026, 5, 17)]!.first.kind,
        ReadingMarkKind.finished,
      );
    });

    test('다른 달의 마커는 무시 (시작은 이전 달, 완독은 이 달)', () {
      final markers = buildCalendarMarkers([
        UserBookReadingRow(
          book: book1,
          startedAt: DateTime(2026, 4, 28),
          finishedAt: DateTime(2026, 5, 5),
        ),
      ], 2026, 5);

      expect(markers, hasLength(1));
      expect(
        markers[DateTime(2026, 5, 5)]!.first.kind,
        ReadingMarkKind.finished,
      );
      expect(markers[DateTime(2026, 4, 28)], isNull);
    });

    test('한 날에 여러 책 → 리스트로 누적', () {
      final markers = buildCalendarMarkers([
        UserBookReadingRow(book: book1, finishedAt: DateTime(2026, 5, 17)),
        UserBookReadingRow(book: book2, finishedAt: DateTime(2026, 5, 17)),
      ], 2026, 5);

      expect(markers[DateTime(2026, 5, 17)]!.length, 2);
    });

    test('rating 포함', () {
      final markers = buildCalendarMarkers([
        UserBookReadingRow(
          book: book1,
          finishedAt: DateTime(2026, 5, 17),
          rating: 4,
        ),
      ], 2026, 5);

      expect(markers[DateTime(2026, 5, 17)]!.first.rating, 4);
    });

    test('월 경계 — 5월 1일 / 5월 31일은 5월에 포함', () {
      final markers = buildCalendarMarkers([
        UserBookReadingRow(book: book1, startedAt: DateTime(2026, 5, 1)),
        UserBookReadingRow(book: book2, finishedAt: DateTime(2026, 5, 31)),
      ], 2026, 5);

      expect(markers[DateTime(2026, 5, 1)], isNotNull);
      expect(markers[DateTime(2026, 5, 31)], isNotNull);
    });
  });
}
