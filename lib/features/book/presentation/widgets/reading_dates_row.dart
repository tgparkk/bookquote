// 책 상세의 읽기 시작·완독일 행 (PR17-B).
//
// 별점 행 아래 2행 — "읽기 시작" / "다 읽음". 데이터 없으면 [오늘][어제][직접]
// 칩 3개, 입력된 후엔 〔M월 D일〕 칩 + [지우기]. StarRating의 "재탭=해제" 원칙과
// 일관(DECISIONS 2026-05-17 채택 UX ②). `started_at` 없이 "다 읽음 / 오늘"을
// 누르면 둘 다 today로 저장 + SnackBar (StoryGraph 자동 기입 패턴).
//
// 로그인 가드는 caller(`book_detail_screen`) 책임.
// 설계: docs/design/screens/book-detail.md · docs/DECISIONS.md 2026-05-17.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../library/state/calendar_providers.dart';
import '../../data/book_repository.dart';
import '../../domain/reading_dates.dart';
import '../../state/book_providers.dart';

class ReadingDatesRow extends ConsumerStatefulWidget {
  const ReadingDatesRow({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<ReadingDatesRow> createState() => _ReadingDatesRowState();
}

class _ReadingDatesRowState extends ConsumerState<ReadingDatesRow> {
  bool _busy = false;

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _yesterday => _today.subtract(const Duration(days: 1));

  Future<void> _set(ReadingDateKind kind, DateTime? date) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(bookRepositoryProvider);
    final before = ref.read(readingDatesProvider(widget.bookId)).value ??
        const ReadingDates();
    // started_at 없이 finished를 set → 둘 다 today로 자동 보정.
    final shouldAutoStart = kind == ReadingDateKind.finished &&
        date != null &&
        before.startedAt == null;

    try {
      await repo.setReadingDate(
        bookId: widget.bookId,
        kind: kind,
        date: date,
      );
      if (shouldAutoStart) {
        await repo.setReadingDate(
          bookId: widget.bookId,
          kind: ReadingDateKind.started,
          date: date,
        );
      }
      if (!mounted) return;
      ref.invalidate(readingDatesProvider(widget.bookId));
      ref.invalidate(myLibraryProvider);
      ref.invalidate(isInLibraryProvider(widget.bookId));
      ref.invalidate(currentlyReadingProvider); // PR23 홈 "지금 읽고 있어요" 갱신
      ref.invalidate(userBooksCalendarProvider); // 서재 [캘린더] 마커 갱신
      if (shouldAutoStart) {
        showAppSnackBarOn(messenger, '함께 시작일도 오늘로 저장했어요');
      }
    } on BookRepositoryException catch (e) {
      if (!mounted) return;
      showAppSnackBarOn(messenger, _userMessage(e));
    } catch (_) {
      if (!mounted) return;
      showAppSnackBarOn(messenger, '저장하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _userMessage(BookRepositoryException e) => switch (e.code) {
        'NOT_AUTHENTICATED' => '로그인이 필요해요.',
        'VAL_DATE_RANGE' => '완독일은 시작일 이후여야 해요.',
        _ => '저장하지 못했어요.',
      };

  Future<void> _pickDate(ReadingDateKind kind) async {
    final dates = ref.read(readingDatesProvider(widget.bookId)).value ??
        const ReadingDates();
    final today = _today;
    final initial = kind == ReadingDateKind.started
        ? (dates.startedAt ?? today)
        : (dates.finishedAt ?? today);
    // 년도 헤더가 항상 활성화되도록 범위를 넓힌다. 시작·완독 cross-check은
    // picker에서 막지 않고 서버 검증(VAL_DATE_RANGE)으로 위임 — picker 범위가
    // 좁아 년도 선택이 불가능해지는 문제를 우선한다.
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: today,
    );
    if (picked == null || !mounted) return;
    await _set(kind, DateTime(picked.year, picked.month, picked.day));
  }

  @override
  Widget build(BuildContext context) {
    final dates = ref.watch(readingDatesProvider(widget.bookId)).value ??
        const ReadingDates();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateLine(
            label: '읽기 시작',
            date: dates.startedAt,
            busy: _busy,
            onToday: () => _set(ReadingDateKind.started, _today),
            onYesterday: () => _set(ReadingDateKind.started, _yesterday),
            onPickDate: () => _pickDate(ReadingDateKind.started),
            onClear: () => _set(ReadingDateKind.started, null),
          ),
          const SizedBox(height: AppSpacing.s2),
          _DateLine(
            label: '다 읽음',
            date: dates.finishedAt,
            busy: _busy,
            onToday: () => _set(ReadingDateKind.finished, _today),
            onYesterday: () => _set(ReadingDateKind.finished, _yesterday),
            onPickDate: () => _pickDate(ReadingDateKind.finished),
            onClear: () => _set(ReadingDateKind.finished, null),
          ),
        ],
      ),
    );
  }
}

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.label,
    required this.date,
    required this.busy,
    required this.onToday,
    required this.onYesterday,
    required this.onPickDate,
    required this.onClear,
  });

  final String label;
  final DateTime? date;
  final bool busy;
  final VoidCallback onToday;
  final VoidCallback onYesterday;
  final VoidCallback onPickDate;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: textTheme.labelMedium),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: date == null
              ? Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _ChipButton(label: '오늘', onPressed: busy ? null : onToday),
                    _ChipButton(label: '어제', onPressed: busy ? null : onYesterday),
                    _ChipButton(label: '직접', onPressed: busy ? null : onPickDate),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DateChip(
                      date: date!,
                      onTap: busy ? null : onPickDate,
                    ),
                    const SizedBox(width: 4),
                    TextButton(
                      onPressed: busy ? null : onClear,
                      style: TextButton.styleFrom(
                        // primary500 → onSurfaceSubtle
                        foregroundColor: context.colors.onSurfaceSubtle,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('지우기'),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        // accent600 → accentDefault, accent200 → accentBorder
        foregroundColor: colors.accentDefault,
        side: BorderSide(color: colors.accentBorder), // const 제거 — 런타임 색
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, this.onTap});
  final DateTime date;

  /// 칩 탭 시 호출. null이면 비활성(저장 중) — `busy` 상태에서.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.full);
    final colors = context.colors;
    final body = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.accentContainer,   // accent50 → accentContainer
        borderRadius: radius,
        border: Border.all(color: colors.accentBorder), // accent200 → accentBorder
      ),
      child: Text(
        '${date.month}월 ${date.day}일',
        style: TextStyle( // const 제거 — 런타임 색
          fontFamily: AppFonts.ui,
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w500,
          color: colors.accentOnContainer, // accent800 → accentOnContainer
        ),
      ),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: body,
    );
  }
}
