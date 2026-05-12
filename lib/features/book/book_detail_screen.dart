import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/auth_state_provider.dart';
import '../../core/theme/tokens.dart';
import 'data/book_repository.dart';
import 'presentation/widgets/book_cover.dart';
import 'presentation/widgets/star_rating.dart';
import 'state/book_providers.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBook = ref.watch(bookByIdProvider(bookId));
    final loggedIn = ref.watch(currentSessionProvider) != null;
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
          final author = book.author;
          final publisher = book.publisher;
          final description = book.description;
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
                        if (author != null && author.isNotEmpty)
                          Text(author, style: textTheme.bodyMedium),
                        if (publisher != null && publisher.isNotEmpty)
                          Text(
                            [
                              publisher,
                              if (book.pubDate != null && book.pubDate!.isNotEmpty)
                                book.pubDate!,
                            ].join(' · '),
                            style: textTheme.bodySmall,
                          ),
                        const SizedBox(height: AppSpacing.s2),
                        Text('ISBN ${book.isbn13}', style: textTheme.labelSmall),
                        if (loggedIn) ...[
                          const SizedBox(height: AppSpacing.s3),
                          Text('내 별점', style: textTheme.labelMedium),
                          _BookRatingRow(bookId: bookId),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s8),
                Text('설명', style: textTheme.titleMedium),
                const SizedBox(height: AppSpacing.s2),
                Text(description, style: textTheme.bodyMedium),
              ],
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent500),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s6),
            child: Text(
              '책 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}

/// 책 상세 헤더의 별점 행. `myRatingProvider`를 watch하고 탭 시 `setMyRating` →
/// invalidate. 이 책의 다른 화면(서재 등)도 갱신되게 `myLibraryProvider`도 invalidate.
class _BookRatingRow extends ConsumerStatefulWidget {
  const _BookRatingRow({required this.bookId});

  final String bookId;

  @override
  ConsumerState<_BookRatingRow> createState() => _BookRatingRowState();
}

class _BookRatingRowState extends ConsumerState<_BookRatingRow> {
  bool _busy = false;

  Future<void> _rate(int? value) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).setMyRating(widget.bookId, value);
      if (!mounted) return;
      ref.invalidate(myRatingProvider(widget.bookId));
      ref.invalidate(myLibraryProvider);
    } on BookRepositoryException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'NOT_AUTHENTICATED'
                  ? '로그인이 필요해요.'
                  : '별점을 저장하지 못했어요.',
            ),
          ),
        );
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('별점을 저장하지 못했어요. 다시 시도해주세요.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(myRatingProvider(widget.bookId)).value;
    return StarRating(
      rating: rating,
      size: 24,
      onRated: _busy ? null : _rate,
    );
  }
}
