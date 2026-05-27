// PR29: 서재 [책] 탭의 표지 그리드 view.
//
// 3열 GridView, 표지만(제목·저자 캡션 없음). dense한 "표지 모자이크" 시각 —
// 한눈에 서재의 책 라인업을 훑기 위함. 표지 누락 책은 BookCover의 placeholder가
// 책 제목 첫 글자를 표시하므로 식별 가능. 메타 정보가 필요하면 list 모드로.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';

class BookGridView extends StatelessWidget {
  const BookGridView({super.key, required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s16,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: AppSpacing.s3,
        crossAxisSpacing: AppSpacing.s3,
        // 책 표지 표준 비율 2:3 = 0.6667. 표지 외 캡션 없음 → 비율 정확.
        childAspectRatio: 2 / 3,
      ),
      itemCount: books.length,
      itemBuilder: (context, i) => _CoverCell(book: books[i]),
    );
  }
}

class _CoverCell extends StatelessWidget {
  const _CoverCell({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: book.title,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => context.push('/book/${book.id}'),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return BookCover(
              url: book.coverUrl,
              title: book.title,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            );
          },
        ),
      ),
    );
  }
}
