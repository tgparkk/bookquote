// PR29: 서재 [책] 탭의 리스트 view (기본 모드).
//
// 이전 _BookList/_BookRow의 행위를 그대로 추출 — view 모드 토글 추가에 따른 회귀 0.
// 변경 시점에 함께 정리될 만한 디테일도 의도적으로 보존(레이아웃 동일성 보장).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';

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

class _BookRow extends StatelessWidget {
  const _BookRow({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meta = [
      if (book.publisher?.isNotEmpty ?? false) book.publisher!,
      if (book.pubDate?.isNotEmpty ?? false) book.pubDate!,
    ].join(' · ');

    return InkWell(
      onTap: () => context.push('/book/${book.id}'),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
