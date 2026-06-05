// 인용구 카드 — 홈 피드와 인용 목록(서재 탭) 공유 위젯.
//
// 접힘: 표지 썸네일 + 인용구 2~3줄 + 책/저자/페이지 + 무드 칩.
// 펼침([expanded]): 전체 텍스트 + 메모 + 액션([바로 공유 ↗]/[카드 디자인]/[삭제]).
// PR10.5: 디자이너 권고로 공유를 1급 액션으로 승격 — 매번 에디터를 거치지 않게.
// [수정]·[무드 변경] 인라인은 PR4(서재 인용 뷰)에서.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
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
    this.onEdit,
    this.onChangeMoods,
    this.onMoodTap,
    this.readOnly = false,
    this.onOpenBook,
    this.onReport,
  });

  final Quote quote;
  final Book? book;
  final bool expanded;
  final VoidCallback? onTap;
  /// PR10.5 — [바로 공유 ↗] 1급 액션. 카드 에디터 거치지 않고 즉시 공유 시트.
  final VoidCallback? onShare;
  final VoidCallback? onMakeCard;
  final VoidCallback? onDelete;

  /// PR3 — 펼침 상태에서 [수정] → /quote/new?quoteId= 편집 모드.
  final VoidCallback? onEdit;

  /// PR3 — 펼침 상태에서 [무드 변경] → bottom sheet에서 무드 칩 토글.
  final VoidCallback? onChangeMoods;

  /// PR4 — 카드 위 무드 뱃지 탭 → 그 무드 단면(`/library?tab=quotes&mood=`)으로
  /// 이동. null이면 뱃지는 비-인터랙티브(readOnly·친구 인용구).
  final ValueChanged<QuoteMood>? onMoodTap;

  /// PR18-C 친구 프로필 인용구 카드 — 액션 전부 숨김(공유·카드 디자인·삭제·수정).
  /// 펼침 시 [📕 책 보기 ▸]만(`onOpenBook` 있을 때).
  final bool readOnly;

  /// PR18-C — 친구 인용구 펼침 시 책 상세로 이동. `book_id`가 null이면 null 전달
  /// (호출자가 disabled 분기).
  final VoidCallback? onOpenBook;

  /// PR25 — 친구 인용구 펼침 시 [신고] 액션. 읽기 전용(`readOnly`) 카드 전용 —
  /// null이면 미노출(내 인용구엔 안 뜸). 접힌 카드엔 표시 안 함(목록 시인성).
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        // border: 라이트=primary100, 다크=primary600(border 토큰)
        side: BorderSide(color: colors.border, width: 1),
      ),
      // 카드 배경: 라이트=secondary100, 다크=primary700(surfaceCard 토큰)
      color: colors.surfaceCard,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (coverUrl != null || (bookLabel != null && bookLabel.isNotEmpty)) ...[
                // 표지 탭 → 책 상세 (onOpenBook이 있을 때만 — bookId 없으면 호출자가 null).
                // 카드 전체 InkWell(onTap)과 nest 충돌 회피 위해 GestureDetector.
                GestureDetector(
                  onTap: onOpenBook,
                  child: BookCover(
                    url: coverUrl,
                    title: bookLabel ?? '',
                    width: 34,
                    height: 50,
                  ),
                ),
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
                          // const 제거: Icon·Text가 런타임 colors.accentDefault 참조
                          children: <Widget>[
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 12,
                              color: colors.accentDefault,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '잠금',
                              style: TextStyle(
                                fontFamily: AppFonts.ui,
                                fontSize: AppFontSize.xxs,
                                fontWeight: FontWeight.w600,
                                color: colors.accentDefault,
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
                            ? colors.onSurface
                            : colors.onSurfaceSubtle,
                        fontStyle: hasReadableText
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                    if (meta.isNotEmpty)
                      // 책 메타 라인(제목·저자·페이지)도 탭하면 책 상세.
                      // HitTestBehavior.opaque로 padding 영역까지 hit.
                      GestureDetector(
                        onTap: onOpenBook,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.s2),
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall
                                ?.copyWith(color: colors.onSurfaceSubtle),
                          ),
                        ),
                      ),
                    if (quote.moods.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final m in quote.moods)
                              _MoodBadge(
                                m,
                                onTap: onMoodTap == null
                                    ? null
                                    : () => onMoodTap!(m),
                              ),
                          ],
                        ),
                      ),
                    if (expanded &&
                        readOnly &&
                        (onOpenBook != null || onReport != null)) ...[
                      const SizedBox(height: AppSpacing.s3),
                      Row(
                        children: [
                          if (onOpenBook != null)
                            TextButton.icon(
                              onPressed: onOpenBook,
                              icon: const Icon(
                                Icons.menu_book_outlined,
                                size: 16,
                              ),
                              label: const Text('책 보기'),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.accentOnContainer,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          const Spacer(),
                          if (onReport != null)
                            TextButton.icon(
                              onPressed: onReport,
                              icon: const Icon(
                                Icons.flag_outlined,
                                size: 15,
                              ),
                              label: const Text('신고'),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.onSurfaceSubtle,
                                visualDensity: VisualDensity.compact,
                                // const 제거: TextStyle이 런타임 colors 없는 불변 값이지만
                                // styleFrom 자체가 런타임이라 const 불필요
                                textStyle: const TextStyle(
                                  fontFamily: AppFonts.ui,
                                  fontSize: AppFontSize.sm,
                                ),
                              ),
                            ),
                        ],
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
                                backgroundColor: colors.accentDefault,
                                foregroundColor: colors.accentOnAccent,
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
                                foregroundColor: colors.onSurfaceMuted,
                                side: BorderSide(
                                  color: colors.border,
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
                          if (onEdit != null)
                            TextButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 14),
                              label: const Text('수정'),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.onSurfaceMuted,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s2,
                                ),
                                textStyle: const TextStyle(
                                  fontFamily: AppFonts.ui,
                                  fontWeight: FontWeight.w500,
                                  fontSize: AppFontSize.sm,
                                ),
                              ),
                            ),
                          if (onChangeMoods != null)
                            TextButton.icon(
                              onPressed: onChangeMoods,
                              icon: const Icon(
                                Icons.emoji_emotions_outlined,
                                size: 14,
                              ),
                              label: const Text('무드'),
                              style: TextButton.styleFrom(
                                foregroundColor: colors.onSurfaceMuted,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.s2,
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
                                  // semanticError — 상태색이라 변환 안 함
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
  const _MoodBadge(this.mood, {this.onTap});
  final QuoteMood mood;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = moodColorOf(mood);
    final pill = Container(
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
    if (onTap == null) return pill;
    // 카드 전체 InkWell(onTap=펼침 토글)과 nest 충돌 회피 → GestureDetector로
    // hit을 흡수해 부모 InkWell까지 전파되지 않게.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: pill,
    );
  }
}
