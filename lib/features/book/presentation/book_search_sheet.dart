// 책 검색 시트.
//
// `showBookSearchSheet(context)`로 모달 시트를 띄운다. 결과 항목 탭 시 시트가
// 닫히고 선택된 책의 ID가 호출자에게 반환된다 (Navigator.pop(book)). 호출자는
// 책 ID로 `/book/:id`로 이동하거나 quote 입력 화면에 책을 prefill 한다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../data/aladin_dto.dart';
import '../data/book_repository.dart';
import '../domain/book.dart';
import '../state/book_search_controller.dart';
import 'widgets/book_cover.dart';

/// 책 검색 시트를 띄우고 사용자가 고른 책을 반환한다. 취소 시 null.
Future<Book?> showBookSearchSheet(BuildContext context) {
  return showModalBottomSheet<Book>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.secondary100,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => const _SheetBody(),
  );
}

class _SheetBody extends ConsumerStatefulWidget {
  const _SheetBody();

  @override
  ConsumerState<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends ConsumerState<_SheetBody> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(bookSearchQueryProvider.notifier).update(value);
    });
  }

  Future<void> _onPick(BuildContext sheetCtx, _PickInput input) async {
    final repo = ref.read(bookRepositoryProvider);
    Book? book;
    try {
      if (input.cached != null) {
        book = input.cached;
      } else if (input.fresh != null) {
        book = await repo.upsertBook(input.fresh!);
      }
    } on BookRepositoryException catch (e) {
      if (!sheetCtx.mounted) return;
      ScaffoldMessenger.of(sheetCtx)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('책 저장 실패: ${e.message}')));
      return;
    }

    if (!sheetCtx.mounted) return;
    Navigator.of(sheetCtx).pop(book);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final result = ref.watch(bookSearchProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.9,
        child: Column(
          children: [
            const _DragHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.s4,
                0,
                AppSpacing.s4,
                AppSpacing.s3,
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '책 제목, 저자, ISBN',
                  prefixIcon: Icon(Icons.search),
                ),
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
              ),
            ),
            Expanded(
              child: result.when(
                data: (data) =>
                    _Results(result: data, onPick: (i) => _onPick(context, i)),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorView(error: e),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.primary200,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _PickInput {
  const _PickInput.cached(Book this.cached) : fresh = null;
  const _PickInput.fresh(AladinBookDto this.fresh) : cached = null;

  final Book? cached;
  final AladinBookDto? fresh;
}

class _Results extends StatelessWidget {
  const _Results({required this.result, required this.onPick});

  final BookSearchResult result;
  final void Function(_PickInput) onPick;

  @override
  Widget build(BuildContext context) {
    if (result.isEmpty) return const _EmptyState();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        0,
        AppSpacing.s4,
        AppSpacing.s8,
      ),
      children: [
        if (result.cached.isNotEmpty) ...[
          const _SectionLabel('내 서재 카탈로그'),
          for (final b in result.cached)
            _CachedRow(book: b, onTap: () => onPick(_PickInput.cached(b))),
        ],
        if (result.fresh.isNotEmpty) ...[
          const _SectionLabel('알라딘 검색 결과'),
          for (final dto in result.fresh)
            _FreshRow(dto: dto, onTap: () => onPick(_PickInput.fresh(dto))),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium),
    );
  }
}

class _CachedRow extends StatelessWidget {
  const _CachedRow({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Row(
      coverUrl: book.coverUrl,
      title: book.title,
      author: book.author,
      publisher: book.publisher,
      pubDate: book.pubDate,
      onTap: onTap,
    );
  }
}

class _FreshRow extends StatelessWidget {
  const _FreshRow({required this.dto, required this.onTap});
  final AladinBookDto dto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Row(
      coverUrl: dto.coverUrl,
      title: dto.title,
      author: dto.author,
      publisher: dto.publisher,
      pubDate: dto.pubDate,
      onTap: onTap,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.coverUrl,
    required this.title,
    required this.author,
    required this.publisher,
    required this.pubDate,
    required this.onTap,
  });

  final String? coverUrl;
  final String title;
  final String? author;
  final String? publisher;
  final String? pubDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final meta = [
      if (publisher != null && publisher!.isNotEmpty) publisher!,
      if (pubDate != null && pubDate!.isNotEmpty) pubDate!,
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(url: coverUrl, title: title),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  if (author != null && author!.isNotEmpty)
                    Text(author!, style: textTheme.bodySmall),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 36, color: AppColors.primary300),
            const SizedBox(height: AppSpacing.s3),
            Text('찾는 책이 없어요',
                style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '제목 일부만 다시 시도하거나, 책 뒤표지 ISBN(13자리)을 그대로 붙여넣어 보세요.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isRateLimit =
        error is BookRepositoryException && (error as BookRepositoryException).code == 'RATE_LIMIT';
    final message = isRateLimit
        ? '오늘 책 검색이 일시적으로 제한됐어요. 잠시 후 다시 시도해주세요.'
        : '검색에 실패했어요. 네트워크 상태를 확인해주세요.';

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Center(
        child: Text(message, textAlign: TextAlign.center, style: textTheme.bodyMedium),
      ),
    );
  }
}
