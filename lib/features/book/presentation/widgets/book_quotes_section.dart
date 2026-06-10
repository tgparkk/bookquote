// 책 상세의 "이 책에서 모은 구절" 미니 리스트(+친구 N명도 담음 inline chip)와
// 설명 클램프 텍스트("더 보기"/"접기"). 본체: `book_detail_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../quote/presentation/widgets/quote_list_card.dart';
import '../../../quote/state/quote_providers.dart';
import 'friends_with_book.dart';

// ── "이 책에서 모은 구절" ──────────────────────────────────

class BookQuotesSection extends ConsumerStatefulWidget {
  const BookQuotesSection({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookQuotesSection> createState() => _BookQuotesSectionState();
}

class _BookQuotesSectionState extends ConsumerState<BookQuotesSection> {
  static const _maxShown = 3;
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final asyncQuotes = ref.watch(bookQuotesProvider(widget.bookId));

    return asyncQuotes.when(
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Center(
          child: CircularProgressIndicator(
              color: context.colors.accentDefault), // accent500 → accentDefault
        ),
      ),
      // 책 정보·표지·메타는 그대로 두고 인용 섹션만 인라인 실패 처리(부분 실패 격리).
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '이 책의 인용구를 못 불러왔어요.',
                style: textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(bookQuotesProvider(widget.bookId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (quotes) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('이 책에서 모은 구절', style: textTheme.titleMedium),
                if (quotes.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    '${quotes.length}',
                    style: textTheme.titleMedium?.copyWith(
                        color: context.colors.onSurfaceSubtle), // primary400 → onSurfaceSubtle
                  ),
                ],
                const Spacer(),
                // PR30-B: "친구 N명도 담음" inline chip — 기존 행이었던
                // _FriendsWithBookRow를 흡수. N≥1일 때만 자체 노출.
                FriendsWithBookChip(bookId: widget.bookId),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            if (quotes.isEmpty)
              Text(
                '아직 이 책에서 모은 구절이 없어요.',
                style: textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceMuted), // primary500 → onSurfaceMuted
              )
            else
              for (final q in quotes.take(_maxShown))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: QuoteListCard(
                    quote: q,
                    // 책 고정 — 표지·제목 중복 표시하지 않는다.
                    book: null,
                    expanded: _expandedId == q.id,
                    onTap: () => setState(
                      () => _expandedId = _expandedId == q.id ? null : q.id,
                    ),
                    onShare: () => context.push('/quote/${q.id}/share'),
                    onMakeCard: () => context.push('/quote/${q.id}/card'),
                  ),
                ),
            if (quotes.length > _maxShown)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/library?tab=quotes'),
                  child: const Text('전체 보기 ▸'),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── 설명 — 4줄+ 면 클램프 + "더 보기"/"접기" ─────────────────

class DescriptionText extends StatefulWidget {
  const DescriptionText({super.key, required this.text});

  final String text;

  @override
  State<DescriptionText> createState() => _DescriptionTextState();
}

class _DescriptionTextState extends State<DescriptionText> {
  static const _collapsedLines = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;
        final showFull = _expanded || !overflows;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: showFull ? null : _collapsedLines,
              overflow: showFull ? TextOverflow.clip : TextOverflow.fade,
            ),
            if (overflows)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: context.colors.accentDefault, // accent600 → accentDefault
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? '접기' : '더 보기'),
              ),
          ],
        );
      },
    );
  }
}
