// PR29: 서재 [책] 탭의 리스트 view (기본 모드).
//
// PR30-D: 책 카드에 친구 평균 별점(N≥3) + 무드 top 2 mini chip 흡수 — 책 상세
// (PR30-C)와 같은 시그널을 목록에서도 조회 가능하게. 좁은 공간 고려해 무드는
// top 2(상세는 top 3), 친구 평균 라벨은 컴팩트("★4.2 친구 3").

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../../follow/state/follow_providers.dart';
import '../../../quote/domain/quote.dart';
import '../../../quote/domain/quote_mood.dart';
import '../../../quote/state/quote_providers.dart';
import 'book_quick_actions_sheet.dart';

class BookListView extends StatelessWidget {
  const BookListView({super.key, required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s16,
      ),
      itemCount: books.length,
      separatorBuilder: (_, _) => const Divider(height: AppSpacing.s8),
      itemBuilder: (context, i) => _BookRow(book: books[i]),
    );
  }
}

class _BookRow extends ConsumerWidget {
  const _BookRow({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final meta = [
      if (book.publisher?.isNotEmpty ?? false) book.publisher!,
      if (book.pubDate?.isNotEmpty ?? false) book.pubDate!,
    ].join(' · ');

    final avg = ref.watch(friendsAvgRatingProvider(book.id)).value;
    final quotes =
        ref.watch(bookQuotesProvider(book.id)).value ?? const <Quote>[];
    final moods = _topMoods(quotes, max: 2);
    final showAvg = avg != null && avg.n >= 3;
    final showSignal = showAvg || moods.isNotEmpty;

    return InkWell(
      onTap: () => context.push('/book/${book.id}'),
      onLongPress: () => showBookQuickActionsSheet(
        context: context,
        ref: ref,
        book: book,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(url: book.coverUrl, title: book.title),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  if (book.author?.isNotEmpty ?? false)
                    Text(book.author!, style: textTheme.bodySmall),
                  if (meta.isNotEmpty) Text(meta, style: textTheme.labelSmall),
                  if (showSignal) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (showAvg)
                          _MiniChip(
                            icon: Icons.star_rounded,
                            iconColor: AppColors.accent500,
                            text:
                                '${avg.avg.toStringAsFixed(1)} 친구 ${avg.n}',
                          ),
                        for (final m in moods)
                          _MiniChip(
                            icon: m.mood.icon,
                            iconColor: AppColors.primary600,
                            text: '${m.mood.label} ${m.count}',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// quotes의 moods 집계 top N. 좁은 list view라 호출 측에서 max=2 권장.
List<({QuoteMood mood, int count})> _topMoods(
  List<Quote> quotes, {
  required int max,
}) {
  final counts = <QuoteMood, int>{};
  for (final q in quotes) {
    for (final m in q.moods) {
      counts[m] = (counts[m] ?? 0) + 1;
    }
  }
  if (counts.isEmpty) return const [];
  final list = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return list
      .take(max)
      .map((e) => (mood: e.key, count: e.value))
      .toList(growable: false);
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.icon,
    required this.iconColor,
    required this.text,
  });
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.secondary100,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.primary700,
            ),
          ),
        ],
      ),
    );
  }
}
