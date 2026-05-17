// 서재 탭의 "인용구" 뷰 — 내가 모은 인용구를 무드별로 다시 본다.
//
// 상단 무드 필터 칩(전체 N · 무드별 개수) + cursor-after 무한스크롤 카드 목록 +
// pull-to-refresh. "사진은 찍는데 다시 안 봄" 페인의 답 = 테마 단위 다시 보기
// (차별화 ④). [수정]/[무드 변경] 인라인·정렬·검색은 후속.
//
// Scaffold 없음 — library_screen의 Scaffold/AppBar/FAB 안에 들어간다.
// 설계: docs/design/screens/quote-list.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../data/quote_repository.dart';
import '../domain/quote_mood.dart';
import '../state/quote_feed_provider.dart';
import 'widgets/mood_chips.dart';
import 'widgets/outbox_banner.dart';
import 'widgets/quote_list_card.dart';

class QuoteListView extends ConsumerStatefulWidget {
  const QuoteListView({super.key, this.initialMood});

  /// 진입 시 미리 선택할 무드 필터 (홈·책상세의 무드 칩에서 넘어올 때). null = 전체.
  final QuoteMood? initialMood;

  @override
  ConsumerState<QuoteListView> createState() => _QuoteListViewState();
}

class _QuoteListViewState extends ConsumerState<QuoteListView> {
  static const _pageSize = 15;

  final _scrollController = ScrollController();

  QuoteMood? _mood; // null = 전체
  MoodCounts _counts = (total: 0, byMood: const {});
  List<QuoteWithBook> _items = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    _mood = widget.initialMood;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCounts();
      _reload();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Set<QuoteMood>? get _moodFilter => _mood == null ? null : {_mood!};

  Future<void> _loadCounts() async {
    try {
      final c = await ref.read(quoteRepositoryProvider).getMoodCounts();
      if (mounted) setState(() => _counts = c);
    } catch (_) {/* 칩 카운트는 best-effort */}
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
    });
    try {
      final page = await ref
          .read(quoteRepositoryProvider)
          .listMyQuotesWithBook(moods: _moodFilter, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = page;
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _items.isEmpty) return;
    _loadingMore = true;
    try {
      final last = _items.last.quote;
      final page = await ref.read(quoteRepositoryProvider).listMyQuotesWithBook(
            moods: _moodFilter,
            after: (createdAt: last.createdAt, id: last.id),
            limit: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...page];
        _hasMore = page.length == _pageSize;
      });
    } catch (_) {/* 무시 — 현재 목록 유지 */} finally {
      _loadingMore = false;
    }
  }

  void _selectMood(QuoteMood? mood) {
    if (_mood == mood) return;
    setState(() {
      _mood = mood;
      _expandedId = null;
    });
    _reload();
  }

  Future<void> _confirmDelete(QuoteWithBook entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('인용구 삭제'),
        content: const Text('이 인용구를 삭제할까요? 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('삭제', style: TextStyle(color: AppColors.semanticError)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _items = _items.where((e) => e.quote.id != entry.quote.id).toList();
      if (_expandedId == entry.quote.id) _expandedId = null;
    });
    try {
      await ref.read(quoteRepositoryProvider).deleteQuote(entry.quote.id);
      ref.invalidate(quoteFeedProvider); // 홈 피드도 갱신
      if (mounted) _loadCounts();
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('인용구를 삭제했어요.')));
    } catch (_) {
      if (mounted) _reload(); // 삭제 실패 — 목록 복구
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해주세요.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OutboxBanner(),
        _FilterChips(
          selected: _mood,
          counts: _counts,
          onSelect: _selectMood,
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadCounts();
              await _reload();
            },
            child: _body(context),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent500),
      );
    }
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
          Text('인용구를 불러오지 못했어요',
              textAlign: TextAlign.center, style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.s3),
          Center(
            child: OutlinedButton(
              onPressed: _reload,
              child: const Text('다시 시도'),
            ),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
          Icon(Icons.format_quote, size: 44, color: AppColors.primary300),
          const SizedBox(height: AppSpacing.s4),
          Text(
            _mood == null ? '아직 인용구가 없어요' : '이 무드의 인용구가 아직 없어요',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.s4),
          Center(
            child: _mood == null
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent500,
                      foregroundColor: AppColors.secondary50,
                    ),
                    onPressed: () => context.push('/quote/new'),
                    child: const Text('＋ 인용구 추가'),
                  )
                : TextButton(
                    onPressed: () => _selectMood(null),
                    child: const Text('전체 보기'),
                  ),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.s4),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, i) {
        final e = _items[i];
        return QuoteListCard(
          quote: e.quote,
          book: e.book,
          expanded: _expandedId == e.quote.id,
          onTap: () => setState(
            () => _expandedId = _expandedId == e.quote.id ? null : e.quote.id,
          ),
          onShare: () => context.push('/quote/${e.quote.id}/share'),
          onMakeCard: () => context.push('/quote/${e.quote.id}/card'),
          onDelete: () => _confirmDelete(e),
        );
      },
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.counts,
    required this.onSelect,
  });

  final QuoteMood? selected;
  final MoodCounts counts;
  final ValueChanged<QuoteMood?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      child: Row(
        children: [
          _Chip(
            label: '전체${counts.total > 0 ? ' ${counts.total}' : ''}',
            selected: selected == null,
            colors: null,
            onTap: () => onSelect(null),
          ),
          for (final mood in QuoteMood.values) ...[
            const SizedBox(width: AppSpacing.s2),
            _Chip(
              label: counts.byMood[mood] != null
                  ? '${mood.label} ${counts.byMood[mood]}'
                  : mood.label,
              selected: selected == mood,
              colors: moodColorOf(mood),
              onTap: () => onSelect(mood),
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final ({Color light, Color dark})? colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.primary900
        : colors?.light ?? AppColors.secondary300;
    final fg = selected
        ? AppColors.secondary50
        : colors?.dark ?? AppColors.primary600;
    // F9 일관 가드 — 시스템 1.3x 시 필터 칩도 줄바꿈 마찰. mood_chips와 동일 정책.
    final clamped =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);
    return ChoiceChip(
      label: Text(label, textScaler: clamped),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: bg,
      selectedColor: AppColors.primary900,
      side: BorderSide(color: selected ? AppColors.primary900 : bg),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: AppFontSize.sm,
        fontWeight: FontWeight.w500,
        color: fg,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
