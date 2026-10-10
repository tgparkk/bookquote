// 서재 화면 — "책 ↔ 인용구 ↔ 캘린더" 세그먼트.
//
// 책 탭: 내가 담은 책 목록 (탭 → 책 상세, FAB → 책 검색 시트 → addToLibrary).
//        view 모드 4종 — 리스트/그리드/스택/책장. 모드는 SharedPreferences에 영속화.
//        상단 상태 필터 칩(전체·읽는 중·완독·읽고 싶은) + 정렬(최근·제목·저자·별점·
//        인용 수, 저장됨) — 2026-09-26.
// 인용구 탭: 내가 모은 인용구를 무드별로 — `QuoteListView` (차별화 ④).
// `?tab=quotes&mood=<name>` 쿼리로 진입 시 초기 탭·무드 필터 설정.
// 설계: docs/design/screens/library.md · quote-list.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/app_snackbar.dart';
import '../book/data/book_repository.dart';
import '../book/domain/library_entry.dart';
import '../book/domain/reading_dates.dart';
import '../book/presentation/book_search_sheet.dart';
import '../book/presentation/widgets/add_book_status_sheet.dart';
import '../book/state/book_providers.dart';
import '../quote/domain/quote_mood.dart';
import '../quote/presentation/quote_list_view.dart';
import '../quote/presentation/quote_search_delegate.dart';
import '../quote/state/quote_providers.dart';
import 'presentation/book_views/book_grid_view.dart';
import 'presentation/book_views/book_list_view.dart';
import 'presentation/book_views/book_shelf_view.dart';
import 'presentation/book_views/book_stack_view.dart';
import 'presentation/calendar_segment.dart';
import 'state/library_sort.dart';
import 'state/library_view_mode.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _tab = 0; // 0 = 책, 1 = 인용구, 2 = 캘린더 (PR17-C)
  QuoteMood? _initialMood;
  bool _readQuery = false;
  bool _longPressHintChecked = false;

  /// PR11 — long-press 디스커버리 SnackBar 1회 노출 플래그.
  static const String _kLongPressHintShownKey = 'library_long_press_hint_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowLongPressHint());
  }

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

  /// 책 탭 + 라이브러리 ≥1권 + 첫 진입(prefs flag 미설정)인 경우에만
  /// "표지를 길게 누르면 빠른 액션이 떨어요" SnackBar 한 번. 동선 인지가 목적이라
  /// `[알겠어요]` action으로 명시적 dismiss, SnackBar 자체는 8초 노출.
  Future<void> _maybeShowLongPressHint() async {
    if (_longPressHintChecked || !mounted) return;
    _longPressHintChecked = true;
    if (_tab != 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kLongPressHintShownKey) ?? false) return;
      final books = await ref.read(myLibraryProvider.future);
      if (books.isEmpty || !mounted) return;
      await prefs.setBool(_kLongPressHintShownKey, true);
      if (!mounted) return;
      showAppSnackBar(
        context,
        '💡 표지를 길게 누르면 빠른 액션 시트가 떠요.',
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: '알겠어요',
          onPressed: () {/* dismiss로 충분 */},
        ),
      );
    } catch (_) {/* hint 실패는 침묵 — 본 화면 동작에 영향 없음 */}
  }

  Future<void> _onAddBook() async {
    final book = await showBookSearchSheet(context);
    if (book == null || !mounted) return;

    final status = await showAddBookStatusSheet(context, book: book);
    if (status == null || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(bookRepositoryProvider);
    try {
      await repo.addToLibrary(book.id, status: status);
      if (status == ReadingStatus.reading) {
        await repo.setReadingDate(
          bookId: book.id,
          kind: ReadingDateKind.started,
          date: DateTime.now(),
        );
      }
      ref.invalidate(myLibraryProvider);
      if (status == ReadingStatus.reading) {
        ref.invalidate(currentlyReadingProvider);
        ref.invalidate(readingDatesProvider(book.id));
      }
      if (!mounted) return;
      final snackText = switch (status) {
        ReadingStatus.wishlist => '"${book.title}" 읽고 싶은 책으로 담았어요',
        ReadingStatus.reading => '"${book.title}" 읽기 시작했어요',
        ReadingStatus.finished => '"${book.title}" 읽은 책으로 담았어요',
      };
      showAppSnackBarOn(
        messenger,
        snackText,
        action: SnackBarAction(
          label: '열기',
          onPressed: () {
            if (mounted) context.push('/book/${book.id}');
          },
        ),
      );
    } on BookRepositoryException {
      if (!mounted) return;
      showAppSnackBarOn(messenger, '서재에 추가하지 못했어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 서재'),
        actions: [
          IconButton(
            icon: const Icon(Icons.library_add_outlined),
            tooltip: '책 검색',
            onPressed: _onAddBook,
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: '인용구 검색',
            onPressed: () =>
                showSearch(context: context, delegate: QuoteSearchDelegate()),
          ),
        ],
      ),
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
      // [책]·[캘린더] 탭은 [+ 책 추가] FAB, [인용구] 탭은 [+ 인용구] FAB.
      // (구버전 BottomNav 가운데 [+]가 '활동' 탭으로 교체되며 인용구 추가 진입점
      //  보강 — 인용구 탭에서도 바로 작성 가능하게 FAB 복원.)
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/quote/new'),
              icon: const Icon(Icons.add),
              label: const Text('인용구 추가'),
            )
          : FloatingActionButton.extended(
              onPressed: _onAddBook,
              icon: const Icon(Icons.add),
              label: const Text('책 추가'),
            ),
    );
  }
}

class _SegmentHeader extends ConsumerWidget {
  const _SegmentHeader({required this.tab, required this.onChanged});
  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // view 모드 토글은 [책] 탭에서만 의미가 있어 그때만 노출.
    final showViewToggle = tab == 0;
    final asyncMode = ref.watch(libraryViewModeProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          Expanded(
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
          ),
          if (showViewToggle) ...[
            const SizedBox(width: AppSpacing.s2),
            IconButton(
              tooltip: '보기 방식 변경',
              icon: Icon(
                asyncMode.value?.icon ?? Icons.view_list_outlined,
              ),
              onPressed: () => _pickViewMode(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickViewMode(BuildContext context, WidgetRef ref) async {
    final current = ref.read(libraryViewModeProvider).value ?? LibraryViewMode.list;
    final picked = await showModalBottomSheet<LibraryViewMode>(
      context: context,
      backgroundColor: context.colors.surfaceSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.s4),
            Text(
              '보기 방식',
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            for (final m in LibraryViewMode.values)
              ListTile(
                leading: Icon(m.icon),
                title: Text(m.label),
                subtitle: Text(m.description),
                trailing: m == current
                    ? Icon(Icons.check, color: context.colors.accentDefault)
                    : null,
                onTap: () => Navigator.of(ctx).pop(m),
              ),
            const SizedBox(height: AppSpacing.s2),
          ],
        ),
      ),
    );
    if (picked != null && picked != current) {
      await ref.read(libraryViewModeProvider.notifier).set(picked);
    }
  }
}

// ── 책 탭 ────────────────────────────────────────────────

/// 책 탭 — 상단 상태 필터 칩 + 정렬 버튼(2026-09-26), 아래 보기 방식별 목록.
class _BookTab extends ConsumerStatefulWidget {
  const _BookTab();

  @override
  ConsumerState<_BookTab> createState() => _BookTabState();
}

class _BookTabState extends ConsumerState<_BookTab> {
  /// null = 전체. 세션 상태(저장 안 함).
  ReadingStatus? _filter;

  Future<void> _refresh() async {
    ref
      ..invalidate(myLibraryProvider)
      ..invalidate(myQuoteCountsByBookProvider);
    await ref.read(myLibraryProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final asyncLibrary = ref.watch(myLibraryProvider);
    final mode = ref.watch(libraryViewModeProvider).value ?? LibraryViewMode.list;
    final sort =
        ref.watch(librarySortProvider).value ?? LibrarySort.recentlyAdded;
    // 인용 수는 "인용 많은 순"일 때만 조회.
    final quoteCounts = sort == LibrarySort.quoteCount
        ? ref.watch(myQuoteCountsByBookProvider).value ?? const <String, int>{}
        : const <String, int>{};

    return asyncLibrary.when(
      data: (entries) {
        if (entries.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: const _EmptyView(),
          );
        }
        final shown = sortLibrary(
          filterLibrary(entries, _filter),
          sort,
          quoteCounts: quoteCounts,
        );
        final books = [for (final e in shown) e.book];
        return Column(
          children: [
            _BookToolbar(
              entries: entries,
              filter: _filter,
              sort: sort,
              onFilter: (f) => setState(() => _filter = f),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: books.isEmpty
                    ? _FilteredEmptyView(filter: _filter!)
                    : switch (mode) {
                        LibraryViewMode.list => BookListView(books: books),
                        LibraryViewMode.grid => BookGridView(books: books),
                        LibraryViewMode.stack => BookStackView(books: books),
                        LibraryViewMode.shelf => BookShelfView(books: books),
                      },
              ),
            ),
          ],
        );
      },
      loading: () => Center(
        child: CircularProgressIndicator(color: context.colors.accentDefault),
      ),
      error: (e, _) => RefreshIndicator(
        onRefresh: _refresh,
        child: _ErrorView(onRetry: () => ref.invalidate(myLibraryProvider)),
      ),
    );
  }
}

String _filterLabel(ReadingStatus s) => switch (s) {
      ReadingStatus.reading => '읽는 중',
      ReadingStatus.finished => '완독',
      ReadingStatus.wishlist => '읽고 싶은',
    };

/// [전체 · 읽는 중 · 완독 · 읽고 싶은] 칩(권수 포함, 가로 스크롤) + 정렬 버튼.
class _BookToolbar extends ConsumerWidget {
  const _BookToolbar({
    required this.entries,
    required this.filter,
    required this.sort,
    required this.onFilter,
  });

  final List<LibraryEntry> entries;
  final ReadingStatus? filter;
  final LibrarySort sort;
  final ValueChanged<ReadingStatus?> onFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = <ReadingStatus, int>{};
    for (final e in entries) {
      final s = libraryStatusOf(e);
      if (s != null) counts[s] = (counts[s] ?? 0) + 1;
    }
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              0,
              AppSpacing.s2,
              AppSpacing.s1,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: '전체 ${entries.length}',
                  selected: filter == null,
                  onTap: () => onFilter(null),
                ),
                for (final s in const [
                  ReadingStatus.reading,
                  ReadingStatus.finished,
                  ReadingStatus.wishlist,
                ]) ...[
                  const SizedBox(width: AppSpacing.s2),
                  _FilterChip(
                    label: '${_filterLabel(s)} ${counts[s] ?? 0}',
                    selected: filter == s,
                    onTap: () => onFilter(s),
                  ),
                ],
              ],
            ),
          ),
        ),
        TextButton.icon(
          onPressed: () => _pickSort(context, ref),
          icon: const Icon(Icons.swap_vert_rounded, size: 18),
          label: Text(sort.shortLabel),
          style: TextButton.styleFrom(
            foregroundColor: context.colors.onSurfaceMuted,
            visualDensity: VisualDensity.compact,
            textStyle: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
      ],
    );
  }

  Future<void> _pickSort(BuildContext context, WidgetRef ref) async {
    final picked = await showModalBottomSheet<LibrarySort>(
      context: context,
      backgroundColor: context.colors.surfaceSheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.s4),
            Text(
              '정렬',
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.md,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            for (final s in LibrarySort.values)
              ListTile(
                title: Text(s.label),
                trailing: s == sort
                    ? Icon(Icons.check, color: context.colors.accentDefault)
                    : null,
                onTap: () => Navigator.of(ctx).pop(s),
              ),
            const SizedBox(height: AppSpacing.s2),
          ],
        ),
      ),
    );
    if (picked != null && picked != sort) {
      await ref.read(librarySortProvider.notifier).set(picked);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 인용구 탭 무드 필터 칩과 같은 톤(chipBg / chipSelected). 시스템 1.3x 글꼴에서
    // 줄바꿈 마찰 없게 1.15x로 제한 — mood_chips와 동일 정책.
    final clamped =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);
    return ChoiceChip(
      label: Text(label, textScaler: clamped),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: colors.chipBg,
      selectedColor: colors.chipSelected,
      side: BorderSide(color: selected ? colors.chipSelected : colors.chipBg),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: AppFontSize.sm,
        fontWeight: FontWeight.w500,
        color: selected ? colors.onSurface : colors.onSurfaceMuted,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// 상태 필터 결과가 비었을 때 — 그 상태로 옮기는 방법(길게 누르기 액션)을 안내.
class _FilteredEmptyView extends StatelessWidget {
  const _FilteredEmptyView({required this.filter});
  final ReadingStatus filter;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (title, hint) = switch (filter) {
      ReadingStatus.reading => ('읽는 중인 책이 없어요', '표지를 길게 눌러 [읽기 시작]을 고를 수 있어요.'),
      ReadingStatus.finished => ('완독한 책이 없어요', '표지를 길게 눌러 [다 읽음]을 고를 수 있어요.'),
      ReadingStatus.wishlist => (
          '읽고 싶은 책이 없어요',
          '표지를 길게 눌러 [읽고 싶은 책으로]를 고를 수 있어요.'
        ),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s16,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      children: [
        Text(title, textAlign: TextAlign.center, style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.s2),
        Text(hint, textAlign: TextAlign.center, style: textTheme.bodyMedium),
      ],
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
        Icon(Icons.menu_book_outlined, size: 48, color: context.colors.iconMuted),
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
