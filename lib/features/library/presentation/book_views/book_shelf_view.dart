// PR29: 서재 [책] 탭의 "책장" view.
//
// 책 spine을 가로로 꽂아 책장을 만든다. spine width = page_count × 0.09mm × 2.5.
// 정렬은 제목 가나다순(_BookTab이 넘겨주는 순서) — 실제 책장 메타포.
// 페이지 수 미수집 책은 본문에서 제외되어 하단 "두께 미수집" 섹션에.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '_spine.dart';
import 'book_quick_actions_sheet.dart';

const double _kSpineHeight = 180;

class BookShelfView extends StatelessWidget {
  const BookShelfView({super.key, required this.books});
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
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s6,
            AppSpacing.s4,
            AppSpacing.s4,
          ),
          sliver: SliverToBoxAdapter(
            child: withThickness.isEmpty
                ? const _ShelfEmptyHint()
                : _Shelf(books: withThickness),
          ),
        ),
        SliverToBoxAdapter(child: PendingThicknessSection(books: pending)),
      ],
    );
  }
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 나무 책장 베이스라인 — spine 들이 위에 서고 하단 1px 어두운 라인이
      // 받침대 역할. AppShadows.card는 카드용 모양값이라 spine 행에는
      // 살짝 약한 그림자가 어울려서 inline 정의.
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary500.withValues(alpha: 0.35),
            width: 2,
          ),
        ),
      ),
      padding: const EdgeInsets.only(bottom: AppSpacing.s1),
      child: Wrap(
        spacing: 0, // spine은 서로 붙어 있어야 책장 느낌
        runSpacing: AppSpacing.s4, // 줄바꿈 시 행간만 띄움
        children: [for (final b in books) _Spine(book: b)],
      ),
    );
  }
}

class _Spine extends ConsumerWidget {
  const _Spine({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = shelfWidthForPages(book.pageCount!);
    final color = spineColorOf(book.id);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/book/${book.id}'),
        onLongPress: () => showBookQuickActionsSheet(
          context: context,
          ref: ref,
          book: book,
        ),
        child: Container(
          width: width,
          height: _kSpineHeight,
          decoration: BoxDecoration(
            color: color,
            border: Border(
              left: BorderSide(color: Colors.black.withValues(alpha: 0.18)),
              right: BorderSide(color: Colors.black.withValues(alpha: 0.18)),
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
          // 제목을 spine 위 세로로(시계 방향 90°) — 실제 책장처럼 옆에서 읽기.
          child: RotatedBox(
            quarterTurns: 3,
            child: Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.xs,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary50,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShelfEmptyHint extends StatelessWidget {
  const _ShelfEmptyHint();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
      child: Column(
        children: [
          Icon(
            Icons.shelves,
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
            '쪽수가 채워진 책부터 책장에 꽂혀요.\n'
            '아래 책들의 쪽수를 입력하면 바로 꽂힙니다.',
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
