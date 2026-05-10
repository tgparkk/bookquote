import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import 'presentation/widgets/book_cover.dart';
import 'state/book_providers.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBook = ref.watch(bookByIdProvider(bookId));
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('책 상세')),
      body: asyncBook.when(
        data: (book) {
          if (book == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: Text(
                  '책을 찾지 못했어요. 검색 결과에서 다시 선택해주세요.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s6),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BookCover(
                    url: book.coverUrl,
                    title: book.title,
                    width: 96,
                    height: 140,
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book.title, style: textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.s2),
                        if (book.author != null)
                          Text(book.author!, style: textTheme.bodyMedium),
                        if (book.publisher != null)
                          Text(
                            [book.publisher!, if (book.pubDate != null) book.pubDate!].join(' · '),
                            style: textTheme.bodySmall,
                          ),
                        const SizedBox(height: AppSpacing.s2),
                        Text('ISBN ${book.isbn13}', style: textTheme.labelSmall),
                      ],
                    ),
                  ),
                ],
              ),
              if (book.description != null && book.description!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Text('설명', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.s2),
                Text(book.description!, style: textTheme.bodyMedium),
              ],
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.accent500)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Text(
              '책을 불러오지 못했어요: $e',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
