// 캘린더 마커용 도메인 (PR17-C).
//
// `user_books`의 `started_at`/`finished_at` raw row + book join을 받아 날짜별로
// grouping. 같은 책이 같은 날 시작+완독이면 ReadingMarkKind.both, 다른 날이면 두
// 항목으로 분리. 다른 달의 마커는 결과에서 제외.

import 'book.dart';

enum ReadingMarkKind { started, finished, both }

class UserBookReadingRow {
  const UserBookReadingRow({
    required this.book,
    this.startedAt,
    this.finishedAt,
    this.rating,
  });

  final Book book;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? rating;
}

class UserBookOnDay {
  const UserBookOnDay({
    required this.book,
    required this.kind,
    this.rating,
  });

  final Book book;
  final ReadingMarkKind kind;
  final int? rating;
}

/// 그 달의 시작·완독 마커를 날짜별로 분류. 같은 책이 같은 날 시작+완독이면 both,
/// 다른 날이면 두 항목. 다른 달의 마커는 결과에서 제외.
Map<DateTime, List<UserBookOnDay>> buildCalendarMarkers(
  List<UserBookReadingRow> rows,
  int year,
  int month,
) {
  final result = <DateTime, List<UserBookOnDay>>{};
  final firstDay = DateTime(year, month, 1);
  final nextMonth = DateTime(year, month + 1, 1);

  bool inMonth(DateTime? d) =>
      d != null && !d.isBefore(firstDay) && d.isBefore(nextMonth);

  void addEntry(DateTime date, UserBookOnDay entry) {
    final key = DateTime(date.year, date.month, date.day);
    (result[key] ??= []).add(entry);
  }

  for (final row in rows) {
    final s = inMonth(row.startedAt) ? row.startedAt : null;
    final f = inMonth(row.finishedAt) ? row.finishedAt : null;
    if (s != null && f != null && _sameDay(s, f)) {
      addEntry(
        s,
        UserBookOnDay(
          book: row.book,
          kind: ReadingMarkKind.both,
          rating: row.rating,
        ),
      );
    } else {
      if (s != null) {
        addEntry(
          s,
          UserBookOnDay(
            book: row.book,
            kind: ReadingMarkKind.started,
            rating: row.rating,
          ),
        );
      }
      if (f != null) {
        addEntry(
          f,
          UserBookOnDay(
            book: row.book,
            kind: ReadingMarkKind.finished,
            rating: row.rating,
          ),
        );
      }
    }
  }
  return result;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
