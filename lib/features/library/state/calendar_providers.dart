// 서재 [캘린더] 세그먼트의 상태 provider (PR17-C).
//
// 그 달의 캘린더 마커는 user_books에서 `started_at`/`finished_at`이 그 달 안인 row를
// 한꺼번에 fetch한 뒤 `buildCalendarMarkers`로 날짜별 grouping. 책 상세에서 날짜
// 수정·삭제 후 pop하면 `ref.invalidate(userBooksCalendarProvider(...))`로 갱신.
// 선택된 날짜는 caller(`calendar_segment`)의 위젯 state로 두고 provider 없음
// (transient — Riverpod 3.x StateProvider는 legacy로 분리됐고 위젯 state가 더 자연).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../book/data/book_repository.dart';
import '../../book/domain/user_book_on_day.dart';

typedef CalendarKey = ({int year, int month});

/// `(year, month)` 키로 그 달의 캘린더 마커.
final userBooksCalendarProvider = FutureProvider.autoDispose
    .family<Map<DateTime, List<UserBookOnDay>>, CalendarKey>(
        (ref, key) async {
  final rows = await ref
      .read(bookRepositoryProvider)
      .listCalendarMarkers(year: key.year, month: key.month);
  return buildCalendarMarkers(rows, key.year, key.month);
});
