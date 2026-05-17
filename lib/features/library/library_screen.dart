// 서재 화면 — "책 ↔ 인용구" 세그먼트.
//
// 책 탭: 내가 담은 책 목록 (탭 → 책 상세, FAB → 책 검색 시트 → addToLibrary).
// 인용구 탭: 내가 모은 인용구를 무드별로 — `QuoteListView` (차별화 ④).
// `?tab=quotes&mood=<name>` 쿼리로 진입 시 초기 탭·무드 필터 설정.
// 설계: docs/design/screens/library.md · quote-list.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../book/data/book_repository.dart';
import '../book/domain/book.dart';
import '../book/presentation/book_search_sheet.dart';
import '../book/presentation/widgets/book_cover.dart';
import '../book/state/book_providers.dart';
import '../quote/domain/quote_mood.dart';
import '../quote/presentation/quote_list_view.dart';
import 'presentation/calendar_segment.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _tab = 0; // 0 = 책, 1 = 인용구, 2 = 캘린더 (PR17-C)
  QuoteMood? _initialMood;
  bool _readQuery = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readQuery) return;
    _readQuery = true;
    final q = GoRouterState.of(context).uri.queryParameters;
    if (q['tab'] == 'quotes') _tab = 1;
    if (q['tab'] == 'calendar') _tab = 2;
    final moodName = q['mood'];
    if (moodName != null) _initialMood = QuoteMood.fromName(moodName);
  }

  Future<void> _onAddBook() async {
    final book = await showBookSearchSheet(context);
    if (book == null || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).addToLibrary(book.id);
      ref.invalidate(myLibraryProvider);
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('"${book.title}" 서재에 추가됐어요'),
            action: SnackBarAction(
              label: '열기',
              onPressed: () {
                if (mounted) context.push('/book/${book.id}');
              },
            ),
          ),
        );
    } on BookRepositoryException {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('서재에 추가하지 못했어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 서재')),
      body: Column(
        children: [
          _SegmentHeader(
            tab: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: switch (_tab) {
              0 => const _BookTab(),
              1 => QuoteListView(initialMood: _initialMood),
              _ => const CalendarSegment(),
            },
          ),
        ],
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: _onAddBook,
              icon: const Icon(Icons.add),
              label: const Text('책 추가'),
            )
          : null,
    );
  }
}

class _SegmentHeader extends StatelessWidget {
  const _SegmentHeader({required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 0, label: Text('책')),
          ButtonSegment(value: 1, label: Text('인용구')),
          ButtonSegment(value: 2, label: Text('캘린더')),
        ],
        selected: {tab},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

// ── 책 탭 ────────────────────────────────────────────────

class _BookTab extends ConsumerWidget {
  const _BookTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLibrary = ref.watch(myLibraryProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myLibraryProvider),
      child: asyncLibrary.when(
        data: (books) =>
            books.isEmpty ? const _EmptyView() : _BookList(books: books),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent500),
        ),
        error: (e, _) => _ErrorView(onRetry: () => ref.invalidate(myLibraryProvider)),
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
        Icon(Icons.menu_book_outlined, size: 48, color: AppColors.primary300),
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
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s8),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Text(
          '서재를 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s3),
        Center(child: OutlinedButton(onPressed: onRetry, child: const Text('다시 시도'))),
      ],
    );
  }
}
