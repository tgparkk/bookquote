// 내 서재 한 권 — 책 + `user_books` 메타(담은 시각·읽기 날짜·상태·별점).
//
// 서재 [책] 탭의 상태 필터·정렬(2026-09-26)이 쓰는 단위. 홈 책 목록은 `book`만 쓴다.

import 'book.dart';
import 'reading_dates.dart';

typedef LibraryEntry = ({
  Book book,
  DateTime addedAt,
  DateTime? startedAt,
  DateTime? finishedAt,
  String readingStatus,
  int? rating,
});

/// 읽기 상태 판정. null = 미분류([전체]에만 보인다).
///
/// 날짜가 우선이다(완독일 → 완독, 시작일 → 읽는 중 — 홈 '지금 읽는 중'과 같은 기준).
/// 날짜가 없으면 담을 때 고른 `reading_status`를 쓴다. 단 컬럼 기본값이 'reading'이고
/// 2026-09-26 전엔 앱이 이 컬럼을 기록하지 않아서, 날짜 없는 'reading'은 실제 상태를
/// 알 수 없다 → 미분류.
ReadingStatus? libraryStatusOf(LibraryEntry e) {
  if (e.finishedAt != null) return ReadingStatus.finished;
  if (e.startedAt != null) return ReadingStatus.reading;
  return switch (e.readingStatus) {
    'finished' => ReadingStatus.finished,
    'wishlist' => ReadingStatus.wishlist,
    _ => null,
  };
}
