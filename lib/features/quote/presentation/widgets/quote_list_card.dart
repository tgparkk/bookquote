// 인용구 카드 — 홈 피드와 인용 목록(서재 탭) 공유 위젯.
//
// 접힘: 표지 썸네일 + 인용구 2~3줄 + 책/저자/페이지 + 무드 칩.
// 펼침([expanded]): 전체 텍스트 + 메모 + 액션([바로 공유 ↗]/[카드 디자인]/[삭제]).
// PR10.5: 디자이너 권고로 공유를 1급 액션으로 승격 — 매번 에디터를 거치지 않게.
// [수정]·[무드 변경] 인라인은 PR4(서재 인용 뷰)에서.

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../domain/quote.dart';
import '../../domain/quote_mood.dart';
import 'mood_chips.dart';

class QuoteListCard extends StatelessWidget {
  const QuoteListCard({
    super.key,
    required this.quote,
    this.book,
    this.expanded = false,
    this.onTap,
    this.onShare,
    this.onMakeCard,
    this.onDelete,
    this.readOnly = false,
    this.onOpenBook,
  });

  final Quote quote;
  final Book? book;
  final bool expanded;
  final VoidCallback? onTap;
  /// PR10.5 — [바로 공유 ↗] 1급 액션. 카드 에디터 거치지 않고 즉시 공유 시트.
  final VoidCallback? onShare;
  final VoidCallback? onMakeCard;
  final VoidCallback? onDelete;

  /// PR18-C 친구 프로필 인용구 카드 — 액션 전부 숨김(공유·카드 디자인·삭제·수정).
  /// 펼침 시 [📕 책 보기 ▸]만(`onOpenBook` 있을 때).
  final bool readOnly;

  /// PR18-C — 친구 인용구 펼침 시 책 상세로 이동. `book_id`가 null이면 null 전달
  /// (호출자가 disabled 분기).
  final VoidCallback? onOpenBook;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final coverUrl = book?.coverUrl;
    final author = book?.author;
    final bookLabel = book?.title ?? quote.manualBookText;
    final meta = [
      if (bookLabel != null && bookLabel.isNotEmpty) bookLabel,
      if (author != null && author.isNotEmpty) author,
      if (quote.page != null) 'p.${quote.page}',
    ].join(' · ');
    // PR16-C-2: 잠금 인용구는 🔒 라인 + 키 없음(text 비어있음)이면 placeholder.
    final isPrivate = quote.isPrivate;
    final hasReadableText = quote.text != null && quote.text!.isNotEmpty;
    final displayText = hasReadableText
        ? quote.text!
        : (isPrivate ? '이 기기에서 잠겼어요' : '');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverUrl != null || (bookLabel != null && bookLabel.isNotEmpty)) ...[
                BookCover(url: coverUrl, title: bookLabel ?? '', width: 34, height: 50),
                const SizedBox(width: AppSpacing.s3),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPrivate)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s1),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const <Widget>[
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 12,
                              color: AppColors.accent600,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '잠금',
                              style: TextStyle(
                                fontFamily: AppFonts.ui,
                                fontSize: AppFontSize.xxs,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      displayText,
                      maxLines: expanded ? null : 3,
                      overflow: expanded ? null : TextOverflow.ellipsis,
                      // 산세리프(스캔용) — 세리프 NotoSerifKR은 공유 카드(감상용) 전용.
                      // 키 없는 잠금 인용구는 placeholder 톤(italic + 회색).
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: AppFontSize.base,
                        fontWeight: FontWeight.w500,
                        height: AppLineHeight.relaxed,
                        color: hasReadableText
                            ? AppColors.primary800
                            : AppColors.primary400,
                        fontStyle: hasReadableText
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.s2),
                        child: Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall
                              ?.copyWith(color: AppColors.primary400),
                        ),
                      ),
                    if (quote.moods.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [for (final m in quote.moods) _MoodBadge(m)],
                        ),
                      ),
                    if (expanded && readOnly && onOpenBook != null) ...[
                      const SizedBox(height: AppSpacing.s3),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onOpenBook,
                          icon: const Icon(
                            Icons.menu_book_outlined,
                            size: 16,
                          ),
                          label: const Text('책 보기'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.accent700,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                    if (expanded &&
                        !readOnly &&
                        (onShare != null ||
                            onMakeCard != null ||
                            onDelete != null)) ...[
                      const SizedBox(height: AppSpacing.s3),
                      Wrap(
                        spacing: AppSpacing.s2,
                        runSpacing: AppSpacing.s2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (onShare != null)
                            FilledButton.icon(
                              onPressed: onShare,
                              icon: const Icon(
                                Icons.ios_share_rounded,
                                size: 16,
                              ),
                              label: const Text('바로 공유'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent500,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s3,
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: AppFonts.ui,
                                  fontWeight: FontWeight.w600,
                                  fontSize: AppFontSize.sm,
                                ),
                              ),
                            ),
                          if (onMakeCard != null)
                            OutlinedButton.icon(
                              onPressed: onMakeCard,
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                              ),
                              label: const Text('카드 디자인'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary700,
                                side: const BorderSide(
                                  color: AppColors.primary200,
                                  width: 1.5,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s3,
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: AppFonts.ui,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppFontSize.sm,
                                ),
                              ),
                            ),
                          if (onDelete != null)
                            TextButton(
                              onPressed: onDelete,
                              child: Text(
                                '삭제',
                                style: TextStyle(
                                  color: AppColors.semanticError,
                                ),
                              ),
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
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge(this.mood);
  final QuoteMood mood;

  @override
  Widget build(BuildContext context) {
    final c = moodColorOf(mood);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.light,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: c.light),
      ),
      child: Text(
        mood.label,
        style: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: AppFontSize.xxs,
          fontWeight: FontWeight.w500,
          color: c.dark,
        ),
      ),
    );
  }
}
