// 서재 [캘린더] 세그먼트 (PR17-C).
//
// `table_calendar` 위에 두 색 분리 마커(시작=accent200 outline, 완독=accent500
// 채움). 셀 탭 = 그 날 책 리스트 펼침. 점 색만으로 의미 전달 X — 셀 탭으로 항상
// 펼침 + 책 카드 부 텍스트 "읽기 시작"/"다 읽음" 명시(접근성).
//
// 캘린더는 *읽기 전용* — 입력·수정은 책 상세의 `ReadingDatesRow`에서.
// 설계: docs/design/screens/library-calendar.md.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/theme/tokens.dart';
import '../../book/domain/user_book_on_day.dart';
import '../../book/presentation/widgets/book_cover.dart';
import '../state/calendar_providers.dart';

class CalendarSegment extends ConsumerStatefulWidget {
  const CalendarSegment({super.key});

  @override
  ConsumerState<CalendarSegment> createState() => _CalendarSegmentState();
}

class _CalendarSegmentState extends ConsumerState<CalendarSegment> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final asyncMarkers = ref.watch(
      userBooksCalendarProvider(
        (year: _focusedDay.year, month: _focusedDay.month),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TableCalendar<UserBookOnDay>(
          firstDay: DateTime(2010, 1, 1),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: _focusedDay,
          selectedDayPredicate: (d) => _sameDay(d, _selectedDay),
          startingDayOfWeek: StartingDayOfWeek.sunday,
          availableGestures: AvailableGestures.horizontalSwipe,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = DateTime(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focused) => setState(() => _focusedDay = focused),
          eventLoader: (day) {
            final markers = asyncMarkers.value;
            if (markers == null) return const [];
            return markers[DateTime(day.year, day.month, day.day)] ??
                const [];
          },
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accent500, width: 1.5),
            ),
            todayTextStyle: const TextStyle(
              fontFamily: AppFonts.ui,
              fontWeight: FontWeight.w600,
              color: AppColors.accent700,
            ),
            selectedDecoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent50,
              border: Border.all(color: AppColors.accent500, width: 1.5),
            ),
            selectedTextStyle: const TextStyle(
              fontFamily: AppFonts.ui,
              fontWeight: FontWeight.w600,
              color: AppColors.primary900,
            ),
            outsideTextStyle: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              color: AppColors.primary300,
            ),
            defaultTextStyle: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              color: AppColors.primary700,
            ),
            weekendTextStyle: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              color: AppColors.primary700,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontFamily: AppFonts.ui,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.base,
              color: AppColors.primary900,
            ),
          ),
          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              fontFamily: AppFonts.ui,
              fontWeight: FontWeight.w500,
              fontSize: AppFontSize.xs,
              color: AppColors.primary500,
            ),
            weekendStyle: TextStyle(
              fontFamily: AppFonts.ui,
              fontWeight: FontWeight.w500,
              fontSize: AppFontSize.xs,
              color: AppColors.primary500,
            ),
          ),
          calendarBuilders: CalendarBuilders<UserBookOnDay>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;
              return Positioned(
                bottom: 4,
                child: _Markers(events: events),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _DetailList(
            selectedDate: _selectedDay,
            markers: asyncMarkers,
          ),
        ),
      ],
    );
  }
}

class _Markers extends StatelessWidget {
  const _Markers({required this.events});
  final List<UserBookOnDay> events;

  @override
  Widget build(BuildContext context) {
    final shown = events.take(3).toList();
    final extra = events.length - shown.length;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final e in shown) ...[
          _Dot(kind: e.kind),
          const SizedBox(width: 2),
        ],
        if (extra > 0)
          const Text(
            '⋯',
            style: TextStyle(fontSize: 10, color: AppColors.primary400),
          ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.kind});
  final ReadingMarkKind kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      ReadingMarkKind.started => Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent200),
          ),
        ),
      ReadingMarkKind.finished => Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent500,
          ),
        ),
      ReadingMarkKind.both => Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent500,
            border: Border.all(color: AppColors.accent700, width: 1),
          ),
        ),
    };
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.selectedDate, required this.markers});

  final DateTime selectedDate;
  final AsyncValue<Map<DateTime, List<UserBookOnDay>>> markers;

  @override
  Widget build(BuildContext context) {
    return markers.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accent500),
      ),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Text(
            '캘린더를 불러오지 못했어요',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
      data: (map) {
        final key = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
        );
        final entries = map[key] ?? const <UserBookOnDay>[];
        final textTheme = Theme.of(context).textTheme;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s8,
          ),
          children: [
            Text(
              '${selectedDate.month}월 ${selectedDate.day}일',
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s3),
            if (entries.isEmpty)
              Text(
                '이 날 시작·완독한 책이 없어요',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.primary500),
              )
            else
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                  child: _BookRow(entry: entry),
                ),
          ],
        );
      },
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.entry});
  final UserBookOnDay entry;

  String get _kindLabel => switch (entry.kind) {
        ReadingMarkKind.started => '읽기 시작',
        ReadingMarkKind.finished => '다 읽음 ✓',
        ReadingMarkKind.both => '시작 · 다 읽음 ✓',
      };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final rating = entry.rating;
    return InkWell(
      onTap: () => context.push('/book/${entry.book.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(url: entry.book.coverUrl, title: entry.book.title),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _kindLabel,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.accent700,
                        ),
                      ),
                      if (rating != null) ...[
                        const SizedBox(width: AppSpacing.s2),
                        Text(
                          '★' * rating,
                          style: const TextStyle(
                            color: AppColors.accent500,
                            fontSize: AppFontSize.sm,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
