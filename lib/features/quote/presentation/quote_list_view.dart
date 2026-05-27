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
import '../state/quote_providers.dart';
import 'widgets/mood_chips.dart';
import 'widgets/mood_hub_grid.dart';
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

  /// PR22 무드 hub. null = 아직 결정 안 됨, 종류 ≥3이면 hub 모드 진입(_mood가
  /// null인 동안). 단면 진입(_mood != null)은 스냅샷 유지하되 단면 데이터 별도 fetch.
  List<MoodHubSnapshot>? _snapshots;

  /// hub 진입 결정 + 시간순 fallback 선택은 무드 종류 ≥3 기준. 진입 화면 차이가
  /// 큰 변화이므로 외부에서 명확히 가늠하기 위해 게터로 노출.
  bool get _hubMode =>
      widget.initialMood == null &&
      _mood == null &&
      _snapshots != null &&
      _snapshots!.length >= 3;

  @override
  void initState() {
    super.initState();
    _mood = widget.initialMood;
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialMood != null) {
        // 단면 진입(딥링크 등) — hub 단계 건너뜀.
        _loadCounts();
        _reload();
      } else {
        _resolveEntryMode();
      }
    });
  }

  /// 무드 종류 ≥3면 hub 모드, 아니면 시간순 fallback. 호출 후 hub 모드일 땐
  /// `_snapshots` + `_counts`가 채워지고 `_items`는 비어 있다(필요 시 사용자가
  /// 무드 카드 탭으로 단면 fetch). fallback일 땐 `_snapshots=null` + 기존 시간순.
  Future<void> _resolveEntryMode() async {
    try {
      final snaps = await ref
          .read(quoteRepositoryProvider)
          .listMoodHubSnapshots();
      if (!mounted) return;
      if (snaps.length >= 3) {
        // hub 모드 — counts도 snapshots에서 도출(RPC 1회 절약).
        final byMood = <QuoteMood, int>{};
        var total = 0;
        for (final s in snaps) {
          byMood[s.mood] = s.count;
          total += s.count;
        }
        setState(() {
          _snapshots = snaps;
          _counts = (total: total, byMood: byMood);
          _loading = false;
          _error = null;
        });
      } else {
        // 시간순 fallback — 신규 D1~D7 또는 무드 종류 적은 사용자.
        setState(() => _snapshots = null);
        await _loadCounts();
        await _reload();
      }
    } catch (_) {
      // hub fetch 실패 → 시간순 fallback (운영 안전성).
      if (!mounted) return;
      setState(() => _snapshots = null);
      await _loadCounts();
      await _reload();
    }
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
    // hub 모드 복귀(_mood=null + 충분한 무드)는 items reload 불필요 — snapshots는
    // 살아있고 MoodHubGrid가 직접 그린다. 단면 진입·단면 간 전환만 _reload.
    if (_hubMode) return;
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
      ref
        ..invalidate(quoteFeedProvider) // 홈 피드도 갱신
        ..invalidate(moodCountsProvider); // RecallCard 카운트 갱신 (PR15-B)
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
    // 외부 invalidation 동기화 채널 — `_items`/`_snapshots`는 로컬 state라
    // `invalidate(quoteFeedProvider)` 같은 신호를 자체적으로 못 받는다(잠금 해제 후
    // 카드가 stale로 잠긴 표시 유지하던 버그의 직접 원인). quoteFeedProvider가 새
    // 데이터를 받으면 hub/단면 모드에 맞춰 재해결.
    ref.listen<AsyncValue<List<QuoteWithBook>>>(quoteFeedProvider, (prev, next) {
      if (next is AsyncData && prev != next) {
        if (widget.initialMood == null) {
          _resolveEntryMode();
        } else {
          _loadCounts();
          _reload();
        }
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OutboxBanner(),
        if (!_hubMode)
          _FilterChips(
            selected: _mood,
            counts: _counts,
            onSelect: _selectMood,
          ),
        Expanded(
          child: _hubMode
              ? RefreshIndicator(
                  onRefresh: _resolveEntryMode,
                  child: Column(
                    children: [
                      // hub 모드 진입 시 "무엇을 모은 묶음들인지" 첫 진입 신호.
                      // 필터 칩이 hub 모드에선 숨겨져 상단이 비어 보이는 문제도
                      // 함께 해소(PR29). 카운트는 사용자에게 *수집 진척* 신호.
                      _MoodHubHeader(snapshots: _snapshots!),
                      Expanded(
                        child: MoodHubGrid(
                          snapshots: _snapshots!,
                          onMoodTap: _selectMood,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // 단면 모드 → hub 복귀 affordance. 무드 종류 ≥3일 때만 의미가
                    // 있어 노출. "전체" 칩이 hub 복귀임을 사용자가 명시적으로 인지.
                    if (_mood != null &&
                        _snapshots != null &&
                        _snapshots!.length >= 3)
                      _HubBreadcrumb(onTap: () => _selectMood(null)),
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
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s6, AppSpacing.s8, AppSpacing.s6, AppSpacing.s8),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.06),
          // 홈 빈상태와 카피·아이콘 똑같이 차가운 빈 화면이 되지 않도록 따뜻한
          // 안내 카드로 감싼다. [인용구] 탭만의 가치(무드별 다시 보기)도 같이 예고.
          Container(
            padding: const EdgeInsets.all(AppSpacing.s6),
            decoration: BoxDecoration(
              color: AppColors.secondary300,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Column(
              children: [
                Icon(Icons.format_quote, size: 40, color: AppColors.accent500),
                const SizedBox(height: AppSpacing.s3),
                Text(
                  _mood == null
                      ? '첫 인용구를 기다리고 있어요'
                      : '이 무드의 인용구가 아직 없어요',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.primary800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_mood == null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  Text(
                    '책을 읽다가 마음에 닿는 문장을 만나면 저장해보세요.\n'
                    '무드를 3가지 이상 쌓으면 무드별로 모아볼 수 있어요.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary500,
                      height: 1.6,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.s4),
                _mood == null
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent500,
                          foregroundColor: AppColors.secondary50,
                        ),
                        onPressed: () => context.push('/quote/new'),
                        child: const Text('＋ 첫 인용구 저장하기'),
                      )
                    : TextButton(
                        onPressed: () => _selectMood(null),
                        child: const Text('전체 보기'),
                      ),
              ],
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.s4),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s4),
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

class _MoodHubHeader extends StatelessWidget {
  const _MoodHubHeader({required this.snapshots});
  final List<MoodHubSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final moodCount = snapshots.length;
    final totalQuotes =
        snapshots.fold<int>(0, (sum, s) => sum + s.count);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s3,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          Icon(
            Icons.collections_bookmark_outlined,
            size: 16,
            color: AppColors.accent700,
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.sm,
                  color: AppColors.primary700,
                ),
                children: [
                  TextSpan(
                    text: '무드별로 모아 봐요',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent700,
                    ),
                  ),
                  TextSpan(
                    text: '  ·  $moodCount개 무드 · $totalQuotes개 인용구',
                    style: TextStyle(
                      color: AppColors.primary500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubBreadcrumb extends StatelessWidget {
  const _HubBreadcrumb({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s2,
          ),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: AppColors.accent700,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                '무드 모아보기',
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent700,
                ),
              ),
            ],
          ),
        ),
      ),
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
