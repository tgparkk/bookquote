// PR29: 서재 [책] 탭의 "쌓아 보기" view.
//
// 책을 세로로 쌓는다. 각 책의 두께는 page_count × 0.09mm × 4(가시화 배율).
// 사용자가 먼저 담은 책이 아래에 쌓여 있다(_BookTab에서 added_at asc로 정렬해
// 넘겨받는다). 페이지 수가 미수집인 책은 위 영역에서 제외되어 하단
// "두께 미수집" 섹션에 모인다 — 임의 기본 두께를 박지 않음.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';
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

    return CustomScrollView(
      slivers: [
        if (withThickness.isEmpty)
          const SliverToBoxAdapter(child: _StackEmptyHint())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
            ),
            sliver: SliverList.builder(
              itemCount: withThickness.length,
              itemBuilder: (context, i) =>
                  _StackedBook(book: withThickness[i]),
            ),
          ),
        SliverToBoxAdapter(child: PendingThicknessSection(books: pending)),
      ],
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

class _StackedBook extends StatelessWidget {
  const _StackedBook({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    final pages = book.pageCount!;
    final height = stackHeightForPages(pages);
    final color = spineColorOf(book.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/book/${book.id}'),
        child: Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xs),
            border: Border(
              top: BorderSide(color: Colors.black.withValues(alpha: 0.18)),
              bottom: BorderSide(color: Colors.black.withValues(alpha: 0.18)),
            ),
            boxShadow: const [AppShadows.card],
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s2,
          ),
          child: Row(
            children: [
              // 책 옆면 메타포 — 작은 표지 thumbnail이 책의 "뒷쪽" 가장자리
              // 살짝 돌출된 듯한 느낌. 표지 없는 책도 BookCover placeholder.
              BookCover(
                url: book.coverUrl,
                title: book.title,
                width: 28,
                height: height - AppSpacing.s4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(width: AppSpacing.s3),
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
                        color: AppColors.secondary50,
                      ),
                    ),
                    if (book.author?.isNotEmpty ?? false)
                      Text(
                        book.author!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.ui,
                          fontSize: AppFontSize.xs,
                          color: AppColors.secondary50.withValues(alpha: 0.75),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                '$pages쪽',
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.xs,
                  fontWeight: FontWeight.w500,
                  color: AppColors.secondary50.withValues(alpha: 0.70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
