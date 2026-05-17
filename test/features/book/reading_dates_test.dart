// PR17-A: ReadingDates 도메인 + 직렬화 헬퍼 단위 테스트.

import 'package:bookquote/features/book/domain/reading_dates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatReadingDate', () {
    test('formats date as YYYY-MM-DD (zero-padded)', () {
      expect(formatReadingDate(DateTime(2026, 5, 17)), '2026-05-17');
      expect(formatReadingDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(formatReadingDate(DateTime(1999, 12, 31)), '1999-12-31');
    });

    test('ignores time component', () {
      expect(
        formatReadingDate(DateTime(2026, 5, 17, 23, 59, 59)),
        '2026-05-17',
      );
    });
  });

  group('parseReadingDate', () {
    test('parses YYYY-MM-DD strings', () {
      expect(parseReadingDate('2026-05-17'), DateTime(2026, 5, 17));
    });

    test('returns null for null or empty', () {
      expect(parseReadingDate(null), isNull);
      expect(parseReadingDate(''), isNull);
    });
  });

  group('ReadingDates', () {
    test('isEmpty when both null', () {
      expect(const ReadingDates().isEmpty, isTrue);
      expect(
        ReadingDates(startedAt: DateTime(2026, 5, 17)).isEmpty,
        isFalse,
      );
    });

    test('hasStarted / hasFinished flags', () {
      const empty = ReadingDates();
      expect(empty.hasStarted, isFalse);
      expect(empty.hasFinished, isFalse);

      final started = ReadingDates(startedAt: DateTime(2026, 5, 10));
      expect(started.hasStarted, isTrue);
      expect(started.hasFinished, isFalse);

      final finished = ReadingDates(
        startedAt: DateTime(2026, 5, 10),
        finishedAt: DateTime(2026, 5, 17),
      );
      expect(finished.hasStarted, isTrue);
      expect(finished.hasFinished, isTrue);
    });

    test('value equality', () {
      expect(
        ReadingDates(startedAt: DateTime(2026, 5, 17)),
        ReadingDates(startedAt: DateTime(2026, 5, 17)),
      );
      expect(
        ReadingDates(startedAt: DateTime(2026, 5, 17)),
        isNot(ReadingDates(startedAt: DateTime(2026, 5, 18))),
      );
    });

    test('fromRow parses both columns', () {
      final dates = ReadingDates.fromRow({
        'started_at': '2026-05-10',
        'finished_at': '2026-05-17',
      });
      expect(dates.startedAt, DateTime(2026, 5, 10));
      expect(dates.finishedAt, DateTime(2026, 5, 17));
    });

    test('fromRow handles null columns', () {
      final dates = ReadingDates.fromRow({
        'started_at': null,
        'finished_at': null,
      });
      expect(dates.isEmpty, isTrue);
    });

    test('fromRow handles started-only', () {
      final dates = ReadingDates.fromRow({
        'started_at': '2026-05-10',
        'finished_at': null,
      });
      expect(dates.hasStarted, isTrue);
      expect(dates.hasFinished, isFalse);
    });
  });
}
