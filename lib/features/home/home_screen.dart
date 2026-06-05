// 홈 화면 — "내 인용 피드".
//
// 내가 모은 인용구가 시간순으로 쌓이는 곳. cursor-after 무한스크롤, pull-to-refresh,
// 빈 상태 CTA. 친구 follow 타임라인은 V1.5에 여기 합류 — V1 홈은 내 인용구만, Realtime
// 없음 (DECISIONS 2026-05-12). '인용구' FAB로 작성 진입(구 BottomNav [＋] 대체).
// 앱이 포그라운드로 돌아올 때 오프라인 아웃박스를 best-effort flush.
//
// 설계: docs/design/screens/home.md

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../quote/data/quote_outbox.dart';
import '../quote/data/quote_repository.dart';
import '../quote/domain/quote.dart';
import '../follow/presentation/widgets/friend_activity_banner.dart';
import '../follow/state/friend_activity_provider.dart';
import '../quote/presentation/quote_search_delegate.dart';
import '../quote/presentation/widgets/change_moods_sheet.dart';
import '../quote/presentation/widgets/outbox_banner.dart';
import '../quote/presentation/widgets/quote_list_card.dart';
import '../quote/presentation/widgets/recall_card.dart';
import '../quote/state/quote_feed_provider.dart';
import '../quote/state/quote_providers.dart';
import 'presentation/widgets/friend_search_cta.dart';
import 'presentation/widgets/now_reading_row.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  String? _expandedId;

  /// PR8 — 연결-회복 시 outbox flush 트리거. AppLifecycle.resumed만으로는
  /// 앱이 열려 있는 동안 wifi가 끊겼다 돌아온 케이스를 못 잡는다.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushOutbox());
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // v6: list 형태. 모두 none이면 오프라인. 하나라도 wifi/mobile/ethernet/vpn이면 online.
    final isOffline = results.every((r) => r == ConnectivityResult.none);
    if (_wasOffline && !isOffline) {
      _flushOutbox(); // 오프라인 → 온라인 전환 시점에만 flush
    }
    _wasOffline = isOffline;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _flushOutbox();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(quoteFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _flushOutbox() async {
    try {
      final outbox = await ref.read(quoteOutboxProvider.future);
      if (outbox.pending().isEmpty) return;
      final result = await outbox.flush(ref.read(quoteRepositoryProvider));
      if (!mounted) return;
      if (result.sent > 0) ref.invalidate(quoteFeedProvider);
      if (result.sent > 0 || result.discarded > 0) {
        ref.invalidate(quoteOutboxProvider); // 배너 카운트 갱신
      }
      if (result.discarded > 0) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(
              '동기화하지 못한 인용구 ${result.discarded}개를 정리했어요.',
            ),
          ));
      }
    } catch (_) {/* best-effort */}
  }

  /// PR3 (2026-05-28): 인라인 무드 변경. 시트 결과 변경됐을 때만 invalidate.
  Future<void> _changeMoods(Quote quote) async {
    final result = await showChangeMoodsSheet(
      context: context,
      ref: ref,
      quote: quote,
    );
    if (result == null || !mounted) return;
    ref
      ..invalidate(quoteFeedProvider)
      ..invalidate(moodCountsProvider)
      ..invalidate(quoteByIdProvider(quote.id));
  }

  /// 낙관적 제거 + 5초 SnackBar [되돌리기] (PR1, 2026-05-28).
  /// 확인 다이얼로그 없이 즉시 사라지되 SnackBar가 닫힐 때 commit/restore 분기.
  Future<void> _deleteWithUndo(QuoteWithBook entry) async {
    final messenger = ScaffoldMessenger.of(context);
    final feed = ref.read(quoteFeedProvider.notifier);
    final feedSnapshot = ref.read(quoteFeedProvider).value;
    final originalIndex = feedSnapshot
            ?.indexWhere((e) => e.quote.id == entry.quote.id) ??
        -1;
    if (originalIndex < 0) return;

    feed.removeLocal(entry.quote.id);
    if (_expandedId == entry.quote.id) setState(() => _expandedId = null);

    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('인용구를 삭제했어요.'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: '되돌리기',
          onPressed: () {/* closed.reason=action으로 판정 */},
        ),
      ),
    );
    final reason = await controller.closed;
    if (reason == SnackBarClosedReason.action) {
      feed.insertAt(originalIndex, entry);
      return;
    }
    // dismiss / timeout / swipe / replaced — 실제 삭제 커밋
    try {
      await ref.read(quoteRepositoryProvider).deleteQuote(entry.quote.id);
      ref.invalidate(moodCountsProvider);
    } catch (_) {
      if (!mounted) return;
      ref.invalidate(quoteFeedProvider); // 삭제 실패 → 서버 기준으로 목록 복구
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해주세요.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(quoteFeedProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('책글귀'),
        actions: [
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
          const OutboxBanner(),
          // PR20-D — 친구가 새 인용구 추가했음을 인지할 유일한 다리 (V1엔 Realtime 없음).
          const FriendActivityBanner(),
          // (구 PR29-I "최근 독자 후기" row는 '활동' 탭으로 이전 — 홈 중복 제거.)
          // PR23 — "지금 읽고 있어요" 1행: 적기로 가는 retention ramp.
          const NowReadingRow(),
          const RecallCard(),
          // PR18-B: 인용구 ≥1이고 친구 0명일 때만 친구 찾기 CTA 노출
          // (인용구 0개일 땐 빈상태 CTA가 우선 — 진입점 마찰 해소, qa-tester 권고).
          if (feed.value?.isNotEmpty ?? false) const FriendSearchCta(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(friendActivityProvider);
                await ref.read(quoteFeedProvider.notifier).refresh();
              },
              child: feed.when(
                loading: () => Center(
                  child: CircularProgressIndicator(
                    color: context.colors.accentDefault,
                  ),
                ),
                error: (e, _) => _errorView(context),
                data: (entries) =>
                    entries.isEmpty ? _emptyView(context) : _feedList(entries),
              ),
            ),
          ),
        ],
      ),
      // 구버전 BottomNav 가운데 [+]가 '활동' 탭으로 교체되며, 핵심 인용구 작성 동선을
      // 홈 FAB로 보강 (PR23 retention 액션 보호).
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/quote/new'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('인용구'),
      ),
    );
  }

  Widget _feedList(List<QuoteWithBook> entries) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.s4),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, i) {
        final e = entries[i];
        return QuoteListCard(
          quote: e.quote,
          book: e.book,
          expanded: _expandedId == e.quote.id,
          onTap: () => setState(
            () => _expandedId = _expandedId == e.quote.id ? null : e.quote.id,
          ),
          onShare: () => context.push('/quote/${e.quote.id}/share'),
          onMakeCard: () => context.push('/quote/${e.quote.id}/card'),
          onEdit: () => context.push('/quote/new?quoteId=${e.quote.id}'),
          onChangeMoods: () => _changeMoods(e.quote),
          onMoodTap: (m) =>
              context.push('/library?tab=quotes&mood=${m.name}'),
          onDelete: () => _deleteWithUndo(e),
          onOpenBook:
              e.book == null ? null : () => context.push('/book/${e.book!.id}'),
        );
      },
    );
  }

  Widget _emptyView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        Icon(Icons.format_quote, size: 48, color: context.colors.iconMuted),
        const SizedBox(height: AppSpacing.s4),
        Text('아직 인용구가 없어요',
            textAlign: TextAlign.center, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.s2),
        Text('좋아하는 책의 한 줄을 저장해보세요.',
            textAlign: TextAlign.center, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.s6),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.accentDefault,
              foregroundColor: context.colors.accentOnAccent,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s3,
              ),
            ),
            onPressed: () => context.push('/quote/new'),
            child: const Text('＋ 인용구 추가'),
          ),
        ),
      ],
    );
  }

  Widget _errorView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
        Text('인용구를 불러오지 못했어요',
            textAlign: TextAlign.center, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.s3),
        Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(quoteFeedProvider),
            child: const Text('다시 시도'),
          ),
        ),
      ],
    );
  }
}
