import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../book/data/book_repository.dart';
import '../book/domain/book.dart';
import '../book/presentation/book_search_sheet.dart';
import '../book/presentation/widgets/book_cover.dart';
import '../book/state/book_providers.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _onAddBook(BuildContext context, WidgetRef ref) async {
    final book = await showBookSearchSheet(context);
    if (book == null || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).addToLibrary(book.id);
      ref.invalidate(myLibraryProvider);
      if (!context.mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('"${book.title}" 서재에 추가됐어요'),
            action: SnackBarAction(
              label: '열기',
              onPressed: () {
                if (context.mounted) context.push('/book/${book.id}');
              },
            ),
          ),
        );
    } on BookRepositoryException catch (e) {
      if (!context.mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('서재 추가 실패: ${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLibrary = ref.watch(myLibraryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 서재')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myLibraryProvider),
        child: asyncLibrary.when(
          data: (books) =>
              books.isEmpty ? const _EmptyView() : _BookList(books: books),
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.accent500)),
          error: (e, _) => _ErrorView(error: e),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddBook(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('책 추가'),
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.books});
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
                  if (meta.isNotEmpty)
                    Text(meta, style: textTheme.labelSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s16,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      children: [
        Icon(Icons.menu_book_outlined,
            size: 48, color: AppColors.primary300),
        const SizedBox(height: AppSpacing.s4),
        Text('아직 책이 없어요',
            textAlign: TextAlign.center, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '오른쪽 아래 "책 추가" 버튼으로 첫 책을 담아보세요.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Center(
        child: Text(
          '서재를 불러오지 못했어요. 잠시 후 다시 시도해주세요.\n($error)',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
      ),
    );
  }
}
