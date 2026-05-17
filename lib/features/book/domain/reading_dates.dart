// 독서 시작·완독일 도메인 모델 (PR17-A).
//
// `user_books`의 `started_at`/`finished_at` date 컬럼 한 쌍을 캡슐화.
// 둘 다 null과 한쪽만 null도 허용 — 시작만 입력하고 아직 안 다 읽은 케이스가 V1 핵심.
// 직렬화 헬퍼는 top-level — 단위 테스트하기 쉽게 분리.

class ReadingDates {
  const ReadingDates({this.startedAt, this.finishedAt});

  final DateTime? startedAt;
  final DateTime? finishedAt;

  bool get isEmpty => startedAt == null && finishedAt == null;
  bool get hasStarted => startedAt != null;
  bool get hasFinished => finishedAt != null;

  factory ReadingDates.fromRow(Map<String, dynamic> row) => ReadingDates(
        startedAt: parseReadingDate(row['started_at'] as String?),
        finishedAt: parseReadingDate(row['finished_at'] as String?),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingDates &&
          other.startedAt == startedAt &&
          other.finishedAt == finishedAt);

  @override
  int get hashCode => Object.hash(startedAt, finishedAt);

  @override
  String toString() =>
      'ReadingDates(startedAt: $startedAt, finishedAt: $finishedAt)';
}

/// `book_repository.setReadingDate({kind: ...})` 의 두 축.
enum ReadingDateKind { started, finished }

/// postgres `date` 컬럼은 시각 없는 'YYYY-MM-DD' 문자열로 주고받는다.
/// `DateTime.toIso8601String()`은 시각이 붙어 시간대 혼란을 일으키므로 직접 포맷.
String formatReadingDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime? parseReadingDate(String? s) {
  if (s == null || s.isEmpty) return null;
  return DateTime.parse(s);
}
