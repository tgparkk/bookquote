// PR29: 서재 [책] 탭의 리스트 view (기본 모드). 홈 "내 책 목록"도 이 위젯(2026-09-26).
//
// 책 행 시그널: 인용 수 + 친구 평균 별점(N≥3) + 무드 top 2 mini chip.
// PR30-D: 책 카드에 친구 평균 별점(N≥3) + 무드 top 2 mini chip 흡수 — 책 상세
// (PR30-C)와 같은 시그널을 목록에서도 조회 가능하게. 좁은 공간 고려해 무드는
// top 2(상세는 top 3), 친구 평균 라벨은 컴팩트("★4.2 친구 3").

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../../follow/state/follow_providers.dart';
import '../../../quote/domain/quote.dart';
import '../../../quote/domain/quote_mood.dart';
import '../../../quote/state/quote_providers.dart';
import '_spine.dart';
import 'book_quick_actions_sheet.dart';
import 'long_press_hint.dart';

class BookListView extends StatelessWidget {
  const BookListView({
    super.key,
    required this.books,
    this.header,
    this.readingBookIds = const {},
  });
  final List<Book> books;

  /// 목록 위에 함께 스크롤되는 위젯(홈의 회고 카드 등). 전체 폭.
  final Widget? header;

  /// 읽는 중인 책 id — "지금 읽는 중 · N권" 묶음으로 맨 위에 모으고, 표지 경계에
  /// 가름끈 리본 + 행 우측 [✎] 바로 인용구 적기. 묶음 안 순서는 [books] 그대로.
  /// 홈 전용(2026-09-26).
  final Set<String> readingBookIds;

  @override
  Widget build(BuildContext context) {
    final readingPart = [
      for (final b in books)
        if (readingBookIds.contains(b.id)) b,
    ];
    final restPart = [
      for (final b in books)
        if (!readingBookIds.contains(b.id)) b,
    ];
    return CustomScrollView(
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        if (readingPart.isNotEmpty) ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s2,
            ),
            sliver: SliverToBoxAdapter(
              child: ReadingGroupHeader(count: readingPart.length),
            ),
          ),
          _rows(readingPart, reading: true, top: AppSpacing.s2),
          if (restPart.isNotEmpty)
            const SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s4,
                vertical: AppSpacing.s4,
              ),
              sliver: SliverToBoxAdapter(child: ReadingGroupDivider()),
            ),
        ],
        _rows(
          restPart,
          reading: false,
          top: readingPart.isEmpty ? AppSpacing.s4 : 0,
          bottom: AppSpacing.s16,
        ),
      ],
    );
  }

  Widget _rows(
    List<Book> part, {
    required bool reading,
    double top = 0,
    double bottom = 0,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(AppSpacing.s4, top, AppSpacing.s4, bottom),
      sliver: SliverList.separated(
        itemCount: part.length,
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.s8),
        itemBuilder: (context, i) => _BookRow(book: part[i], reading: reading),
      ),
    );
  }
}

class _BookRow extends ConsumerWidget {
  const _BookRow({required this.book, required this.reading});
  final Book book;
  final bool reading;

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
    final showSignal = quotes.isNotEmpty || showAvg;

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
            Stack(
              clipBehavior: Clip.none,
              children: [
                LongPressHintOverlay(
                  padding: 2,
                  child: BookCover(url: book.coverUrl, title: book.title),
                ),
                // 읽는 중 — 표지 오른쪽 모서리 경계 윗변에 걸친 가름끈.
                if (reading)
                  const Positioned(
                    top: 0,
                    right: -4,
                    child: ReadingRibbon(width: 6, height: 20),
                  ),
              ],
            ),
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
                        if (quotes.isNotEmpty)
                          _MiniChip(
                            icon: Icons.format_quote_rounded,
                            iconColor: context.colors.accentDefault,
                            text: quoteCountLabel(quotes.length),
                          ),
                        if (showAvg)
                          _MiniChip(
                            icon: Icons.star_rounded,
                            iconColor: context.colors.accentDefault,
                            text:
                                '${avg.avg.toStringAsFixed(1)} 친구 ${avg.n}',
                          ),
                        for (final m in moods)
                          _MiniChip(
                            icon: m.mood.icon,
                            iconColor: context.colors.iconPrimary,
                            text: '${m.mood.label} ${m.count}',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // 읽는 중 → 그 책 인용구 적기 직진(구 '지금 읽고 있어요' ramp 유지).
            if (reading)
              IconButton(
                tooltip: '이 책 인용구 적기',
                onPressed: () => context.push('/quote/new?bookId=${book.id}'),
                icon: Icon(
                  Icons.edit_outlined,
                  color: context.colors.accentDefault,
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
        color: context.colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: context.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
