// PR29: 서재 [책] 탭의 "쌓아 보기" view. 홈 "내 책 목록"의 기본 보기이기도 하다
// (2026-09-26 — 홈은 [inlinePending]·[compactHeader] 켬).
//
// 책 한 권 = 한 줄 캡슐. 두께(pageCount × 0.09mm)는 캡슐 *높이*로 표현 — 한
// 권씩 위로 쌓이는 시각. 최근 담은 책이 맨 위(added_at desc는 호출자가 처리).
// 상단에 "N권 · X.X cm" 누적 헤더 — "내가 얼마나 쌓았는지" 한눈 확인.
// 캡슐 우측에 "인용 N" (인용구 있는 책만).
// 페이지 수 미수집 책은 기본적으로 본문에서 제외, 하단 "두께 미수집" 섹션으로.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../../card_editor/state/palette_providers.dart';
import '../../../quote/domain/quote.dart';
import '../../../quote/state/quote_providers.dart';
import '_spine.dart';
import 'book_quick_actions_sheet.dart';
import 'long_press_hint.dart';

/// 쪽수 없는 책 캡슐의 높이([BookStackView.inlinePending]일 때). 제목 + "두께 정보
/// 없음" 두 줄이 들어가는 최소 높이.
const double _unknownThicknessHeight = 48;

/// 읽는 중 캡슐의 최소 높이 — 가름끈 리본이 보이고 [✎] 탭 영역이 들어가게.
const double _readingMinHeight = 44;

class BookStackView extends StatelessWidget {
  const BookStackView({
    super.key,
    required this.books,
    this.inlinePending = false,
    this.compactHeader = false,
    this.header,
    this.readingBookIds = const {},
  });
  final List<Book> books;

  /// 누적 헤더 위에 함께 스크롤되는 위젯(홈의 회고 카드 등).
  final Widget? header;

  /// 읽는 중인 책 id — "지금 읽는 중 · N권" 묶음으로 맨 위에 모으고, 표지·책등
  /// 경계에 가름끈 리본 + 캡슐 우측 [✎] 바로 인용구 적기. 묶음 안 순서는 [books]
  /// 그대로. 홈 전용(구 '지금 읽고 있어요' 줄 흡수, 2026-09-26).
  final Set<String> readingBookIds;

  /// true면 쪽수 없는 책도 하단 "두께 미수집" 섹션으로 빼지 않고 최근순 그대로
  /// 캡슐로 쌓는다("두께 정보 없음" 라벨 + 기본 높이). 홈 — 방금 담은 책이 목록
  /// 아래로 사라져 보이지 않게(2026-09-26 디자이너 협의).
  final bool inlinePending;

  /// true면 누적 헤더를 한 줄로 — 홈은 상단 위젯이 많아 세로 공간이 부족하다.
  final bool compactHeader;

  static bool _hasThickness(Book b) => b.pageCount != null && b.pageCount! > 0;

  Widget _capsules(
    List<Book> part, {
    required bool reading,
    double top = 0,
    double bottom = 0,
  }) {
    return SliverPadding(
      padding:
          EdgeInsets.fromLTRB(AppSpacing.s6, top, AppSpacing.s6, bottom),
      sliver: SliverList.builder(
        itemCount: part.length,
        itemBuilder: (context, i) =>
            _StackedCapsule(book: part[i], reading: reading),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final withThickness = books.where(_hasThickness).toList();
    final pending = books.where((b) => !_hasThickness(b)).toList();
    final stacked = inlinePending ? books : withThickness;
    final readingPart = [
      for (final b in stacked)
        if (readingBookIds.contains(b.id)) b,
    ];
    final restPart = [
      for (final b in stacked)
        if (!readingBookIds.contains(b.id)) b,
    ];
    final totalCm = withThickness.fold<double>(
          0,
          (sum, b) => sum + (b.pageCount! * 0.09),
        ) /
        10;

    return CustomScrollView(
      slivers: [
        if (header != null) SliverToBoxAdapter(child: header),
        SliverToBoxAdapter(
          child: _StackHeader(
            count: stacked.length,
            totalCm: totalCm,
            compact: compactHeader,
          ),
        ),
        if (stacked.isEmpty)
          const SliverToBoxAdapter(child: _StackEmptyHint())
        else ...[
          // 읽는 중 묶음(제목 + 캡슐) → 굵은 구분선 → 나머지. 순서는 [books] 그대로.
          if (readingPart.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s6,
                  AppSpacing.s3,
                  AppSpacing.s6,
                  AppSpacing.s2,
                ),
                child: ReadingGroupHeader(count: readingPart.length),
              ),
            ),
            _capsules(readingPart, reading: true),
            if (restPart.isNotEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.s6,
                  vertical: AppSpacing.s4,
                ),
                sliver: SliverToBoxAdapter(child: ReadingGroupDivider()),
              ),
          ],
          _capsules(
            restPart,
            reading: false,
            top: readingPart.isEmpty ? AppSpacing.s2 : 0,
            bottom: AppSpacing.s4,
          ),
        ],
        if (!inlinePending)
          SliverToBoxAdapter(child: PendingThicknessSection(books: pending)),
        // 마지막 캡슐이 FAB에 가리지 않게.
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s16)),
      ],
    );
  }
}

class _StackHeader extends StatelessWidget {
  const _StackHeader({
    required this.count,
    required this.totalCm,
    required this.compact,
  });
  final int count;
  final double totalCm;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox(height: AppSpacing.s4);
    if (compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s6,
          AppSpacing.s3,
          AppSpacing.s6,
          AppSpacing.s1,
        ),
        child: Row(
          children: [
            Icon(
              Icons.auto_stories,
              size: 18,
              color: context.colors.accentDefault,
            ),
            const SizedBox(width: AppSpacing.s2),
            Text(
              '$count권 쌓았어요',
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.base,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Text(
              '총 ${totalCm.toStringAsFixed(1)} cm',
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.sm,
                fontWeight: FontWeight.w600,
                color: context.colors.accentDefault,
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s6,
        AppSpacing.s6,
        AppSpacing.s4,
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories,
            size: 28,
            color: context.colors.accentDefault,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '$count권 쌓았어요',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '총 ${totalCm.toStringAsFixed(1)} cm',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w600,
              color: context.colors.accentDefault,
            ),
          ),
        ],
      ),
    );
  }
}

/// 한 권 = 좌측 표지 + 우측 spine. 표지는 책 정면(2:3 비율 AspectRatio), spine은
/// palette dominant 색 + 좌측 정렬 제목. 두께 = 전체 height(stackHeightForPages).
/// 표지가 없으면 BookCover placeholder(베이지 + 제목 첫 글자)가 좌측 strip 역할.
/// 1px 간격으로 살짝 겹친 "쌓인 책 더미" 느낌. 쪽수 없는 책(inlinePending)은
/// 기본 높이 + 제목 아래 "두께 정보 없음". 읽는 중이면 표지·책등 경계에 가름끈
/// 리본 + 우측 [✎].
class _StackedCapsule extends ConsumerWidget {
  const _StackedCapsule({required this.book, required this.reading});
  final Book book;
  final bool reading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pages = book.pageCount;
    final hasThickness = pages != null && pages > 0;
    var height =
        hasThickness ? stackHeightForPages(pages) : _unknownThicknessHeight;
    if (reading && height < _readingMinHeight) height = _readingMinHeight;
    final asyncPalette = ref.watch(extractedPaletteProvider(
      (coverUrl: book.coverUrl, templateId: 'minimal'),
    ));
    final palette = asyncPalette.value;
    final spineColor = palette?.dominant ?? AppColors.accent500;
    final textColor = palette?.textOnBackground ?? AppColors.secondary50;
    final quotes =
        ref.watch(bookQuotesProvider(book.id)).value ?? const <Quote>[];
    final radius = BorderRadius.circular(AppRadius.xs);

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        elevation: 1,
        shadowColor: AppColors.primary900.withValues(alpha: 0.15),
        child: InkWell(
          onTap: () => context.push('/book/${book.id}'),
          onLongPress: () => showBookQuickActionsSheet(
            context: context,
            ref: ref,
            book: book,
          ),
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 좌측: 책 정면 표지. 2:3 비율이라 height가 클수록 width도 커져
                      // 두꺼운 책은 표지도 커보임 — 책 메타포 강화.
                      AspectRatio(
                        aspectRatio: 2 / 3,
                        child: LongPressHintOverlay(
                          padding: 2,
                          child: BookCover(
                            url: book.coverUrl,
                            title: book.title,
                            width: height * (2 / 3),
                            height: height,
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      ),
                      // 우측: spine — dominant 색 + 좌측 정렬 제목. 책 옆면이
                      // 책장에 꽂혀 있을 때의 라벨 위치. 인용구 있으면 우측 "인용 N".
                      Expanded(
                        child: Container(
                          color: spineColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.s3,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: AppFonts.ui,
                                        fontSize: AppFontSize.sm,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                    ),
                                    if (!hasThickness)
                                      Text(
                                        '두께 정보 없음',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: AppFonts.ui,
                                          fontSize: AppFontSize.xxs,
                                          color: textColor.withValues(alpha: 0.75),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (quotes.isNotEmpty) ...[
                                const SizedBox(width: AppSpacing.s2),
                                _QuoteCountPill(
                                  label: quoteCountLabel(quotes.length),
                                  color: textColor,
                                ),
                              ],
                              // 읽는 중 → 그 책 인용구 적기 직진(구 '지금 읽고 있어요'
                              // 표지 탭의 retention ramp 유지).
                              if (reading)
                                IconButton(
                                  tooltip: '이 책 인용구 적기',
                                  onPressed: () => context
                                      .push('/quote/new?bookId=${book.id}'),
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: textColor,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // 읽는 중 — 표지·책등 경계 윗변에 걸친 가름끈(표지엔 2px만).
                  if (reading)
                    Positioned(
                      top: 0,
                      left: height * (2 / 3) - 2,
                      child: ReadingRibbon(
                        width: (height * 0.1).clamp(6.0, 9.0),
                        height: (height * 0.45).clamp(18.0, 44.0),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// spine 위 "인용 N" — spine 글자색(표지 추출 대비색) 테두리 pill.
class _QuoteCountPill extends StatelessWidget {
  const _QuoteCountPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_quote_rounded, size: 11, color: color),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.xxs,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _StackEmptyHint extends StatelessWidget {
  const _StackEmptyHint();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s12,
        AppSpacing.s6,
        AppSpacing.s4,
      ),
      child: Column(
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 40,
            color: context.colors.iconMuted,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            '아직 두께가 수집된 책이 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.base,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '새 책을 담으면 자동으로 두께를 수집해요.\n'
            '아래 "두께 미수집" 책은 탭해서 쪽수를 직접 넣을 수 있어요.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              color: context.colors.onSurfaceMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
