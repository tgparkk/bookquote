// PR29: 서재 [책] 탭의 "쌓아 보기" view.
//
// 책 한 권 = 한 줄 캡슐. 두께(pageCount × 0.09mm)는 캡슐 *높이*로 표현 — 한
// 권씩 위로 쌓이는 시각. 먼저 담은 책이 아래(added_at asc는 _BookTab에서 처리).
// 상단에 "N권 · X.X cm" 누적 헤더 — "내가 얼마나 쌓았는지" 한눈 확인.
// 페이지 수 미수집 책은 본문에서 제외, 하단 "두께 미수집" 섹션으로.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../../card_editor/state/palette_providers.dart';
import '_spine.dart';

class BookStackView extends StatelessWidget {
  const BookStackView({super.key, required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    final withThickness = <Book>[];
    final pending = <Book>[];
    for (final b in books) {
      if (b.pageCount != null && b.pageCount! > 0) {
        withThickness.add(b);
      } else {
        pending.add(b);
      }
    }
    final totalCm = withThickness.fold<double>(
          0,
          (sum, b) => sum + (b.pageCount! * 0.09),
        ) /
        10;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _StackHeader(count: withThickness.length, totalCm: totalCm),
        ),
        if (withThickness.isEmpty)
          const SliverToBoxAdapter(child: _StackEmptyHint())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s6,
              AppSpacing.s2,
              AppSpacing.s6,
              AppSpacing.s4,
            ),
            sliver: SliverList.builder(
              itemCount: withThickness.length,
              itemBuilder: (context, i) =>
                  _StackedCapsule(book: withThickness[i]),
            ),
          ),
        SliverToBoxAdapter(child: PendingThicknessSection(books: pending)),
      ],
    );
  }
}

class _StackHeader extends StatelessWidget {
  const _StackHeader({required this.count, required this.totalCm});
  final int count;
  final double totalCm;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox(height: AppSpacing.s4);
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
            color: AppColors.accent500,
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '$count권 쌓았어요',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w700,
              color: AppColors.primary900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '총 ${totalCm.toStringAsFixed(1)} cm',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w600,
              color: AppColors.accent700,
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
/// 1px 간격으로 살짝 겹친 "쌓인 책 더미" 느낌.
class _StackedCapsule extends ConsumerWidget {
  const _StackedCapsule({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final height = stackHeightForPages(book.pageCount!);
    final asyncPalette = ref.watch(extractedPaletteProvider(
      (coverUrl: book.coverUrl, templateId: 'minimal'),
    ));
    final palette = asyncPalette.value;
    final spineColor = palette?.dominant ?? AppColors.accent500;
    final textColor = palette?.textOnBackground ?? AppColors.secondary50;
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
          borderRadius: radius,
          child: ClipRRect(
            borderRadius: radius,
            child: SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 좌측: 책 정면 표지. 2:3 비율이라 height가 클수록 width도 커져
                  // 두꺼운 책은 표지도 커보임 — 책 메타포 강화.
                  AspectRatio(
                    aspectRatio: 2 / 3,
                    child: BookCover(
                      url: book.coverUrl,
                      title: book.title,
                      width: height * (2 / 3),
                      height: height,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  // 우측: spine — dominant 색 + 좌측 정렬 제목. 책 옆면이
                  // 책장에 꽂혀 있을 때의 라벨 위치.
                  Expanded(
                    child: Container(
                      color: spineColor,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s3,
                      ),
                      child: Text(
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
            color: AppColors.primary300,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            '아직 두께가 수집된 책이 없어요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.base,
              fontWeight: FontWeight.w600,
              color: AppColors.primary700,
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
              color: AppColors.primary500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
