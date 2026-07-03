// 책 상세의 읽기 진행 strip("N일째 읽는 중" + 오늘 한 줄 CTA)과 무드 summary
// chips(PR30-C). 본체: `book_detail_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../quote/domain/quote.dart';
import '../../../quote/domain/quote_mood.dart';
import '../../../quote/state/quote_providers.dart';
import '../../state/book_providers.dart';

// ── PR30-C: 읽기 진행 strip ─────────────────────────────────────

/// `started_at`이 있고 `finished_at`이 없는 상태(=지금 읽는 중)에만 노출.
/// 경과일 + 미니 CTA로 매일 펼쳐보게 만든다. PM-B 권고(매일 열게 함).
class ReadingProgressStrip extends ConsumerWidget {
  const ReadingProgressStrip({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(readingDatesProvider(bookId)).value;
    if (dates == null) return const SizedBox.shrink();
    if (!dates.hasStarted || dates.hasFinished) {
      return const SizedBox.shrink();
    }
    final started = dates.startedAt!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(started).inDays + 1; // 시작 당일을 1일째로

    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: colors.accentContainer,               // accent50 → accentContainer
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.accentBorder), // accent200 → accentBorder
        ),
        child: Row(
          children: [
            Icon(
              Icons.menu_book_rounded,
              size: 16,
              color: colors.accentDefault,             // accent600 → accentDefault
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                '$days일째 읽는 중',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.accentOnContainer,     // accent800 → accentOnContainer
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colors.accentDefault, // accent600 → accentDefault
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => context.push('/quote/new?bookId=$bookId'),
              child: const Text('오늘 한 줄 ▸'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PR30-C: 무드 summary chips ────────────────────────────────

/// 이 책에서 내가 모은 인용구에 자주 붙인 무드 top 3. 인용구·무드가 비면 hide.
/// 신규 백엔드 없이 `bookQuotesProvider`만 사용 — V1.0 안전 범위.
class MoodSummaryChips extends ConsumerWidget {
  const MoodSummaryChips({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes =
        ref.watch(bookQuotesProvider(bookId)).value ?? const <Quote>[];
    if (quotes.isEmpty) return const SizedBox.shrink();
    final counts = <QuoteMood, int>{};
    for (final q in quotes) {
      for (final m in q.moods) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = top.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Wrap(
        spacing: AppSpacing.s2,
        runSpacing: 4,
        children: [
          for (final e in shown)
            // PR4 — 탭하면 서재 인용구 탭의 해당 무드 단면으로 navigation.
            InkWell(
              onTap: () => context.push(
                '/library?tab=quotes&mood=${e.key.name}',
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.colors.chipBg,              // secondary100 → chipBg
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: context.colors.border), // primary200 → border
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.key.icon, size: 14,
                        color: context.colors.iconPrimary), // primary600 → iconPrimary
                    const SizedBox(width: 4),
                    Text(
                      e.key.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: context.colors.onSurfaceMuted, // primary700 → onSurfaceMuted
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${e.value}',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: context.colors.onSurfaceSubtle), // primary500 → onSurfaceSubtle
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
