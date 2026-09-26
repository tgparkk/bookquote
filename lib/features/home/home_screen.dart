// 홈 화면 — "내 책 목록".
//
// 내가 담은 책이 최근 담은 순으로 쌓이는 곳. 기본 보기는 "쌓아 보기"(서재 [책] 탭과
// 같은 `BookStackView`), AppBar 토글로 리스트(`BookListView`)와 오간다 — 선택은
// 서재와 독립 저장(`homeViewModeProvider`). 읽는 중인 책은 맨 위에 "읽는 중" +
// [✎](바로 인용구 적기)로 고정. 회고 카드 등 상단 위젯은 목록과 함께 스크롤.
// 책 탭 → 책 상세, 표지 long-press → 빠른 액션 시트. pull-to-refresh, 빈 상태 CTA.
// (2026-09-26: 구 "내 인용 피드"에서 전환 — 인용구 시간순 목록은 서재 [인용구] 탭의
// "전체 보기"가 맡는다.) '인용구' FAB로 작성 진입(구 BottomNav [＋] 대체).
// 앱이 포그라운드로 돌아올 때 오프라인 아웃박스를 best-effort flush.
//
// 설계: docs/design/screens/home.md

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics/app_analytics.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/app_snackbar.dart';
import '../ads/ad_ids.dart';
import '../ads/app_banner_ad.dart';
import '../book/domain/book.dart';
import '../book/presentation/book_search_sheet.dart';
import '../book/state/book_providers.dart';
import '../follow/presentation/widgets/friend_activity_banner.dart';
import '../follow/state/friend_activity_provider.dart';
import '../library/presentation/book_views/book_list_view.dart';
import '../library/presentation/book_views/book_stack_view.dart';
import '../library/state/library_view_mode.dart';
import '../quote/data/quote_outbox.dart';
import '../quote/data/quote_repository.dart';
import '../quote/presentation/widgets/outbox_banner.dart';
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
  /// PR8 — 연결-회복 시 outbox flush 트리거. AppLifecycle.resumed만으로는
  /// 앱이 열려 있는 동안 wifi가 끊겼다 돌아온 케이스를 못 잡는다.
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOffline = false;

  /// home_empty_view 계측 — 화면 인스턴스당 1회만 (rebuild 중복 방지).
  bool _loggedEmptyView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushOutbox());
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
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

  Future<void> _flushOutbox() async {
    try {
      final outbox = await ref.read(quoteOutboxProvider.future);
      if (outbox.pending().isEmpty) return;
      final result = await outbox.flush(ref.read(quoteRepositoryProvider));
      if (!mounted) return;
      if (result.sent > 0) {
        // 인용구 저장은 그 책을 서재에 자동으로 담는다(_ensureBookInLibrary) —
        // 홈 책 목록도 함께 갱신.
        ref
          ..invalidate(quoteFeedProvider)
          ..invalidate(myLibraryProvider);
      }
      if (result.sent > 0 || result.discarded > 0) {
        ref.invalidate(quoteOutboxProvider); // 배너 카운트 갱신
      }
      if (result.discarded > 0) {
        showAppSnackBar(
          context,
          '동기화하지 못한 인용구 ${result.discarded}개를 정리했어요.',
        );
      }
    } catch (_) {/* best-effort */}
  }

  /// 홈 검색 = 책 검색. 시트에서 고른 책의 상세로 이동한다 (인용구 검색은
  /// 서재 [인용구] 탭 동선으로 이관 — 홈 AppBar 단일 진입점은 책 탐색).
  Future<void> _searchBooks() async {
    final book = await showBookSearchSheet(context);
    if (book == null || !mounted) return;
    context.push('/book/${book.id}');
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(myLibraryProvider);
    final hasBooks = library.value?.isNotEmpty ?? false;
    final stacked = (ref.watch(homeViewModeProvider).value ??
            LibraryViewMode.stack) ==
        LibraryViewMode.stack;
    // 읽는 중인 책(started_at 최근순) — 목록 맨 위에 "읽는 중"으로 고정.
    final readingIds = <String>[
      for (final r in ref.watch(currentlyReadingProvider).value ?? const [])
        r.book.id,
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('책글귀'),
        actions: [
          if (hasBooks)
            IconButton(
              // 누르면 바뀔 모드의 아이콘.
              icon: Icon(stacked
                  ? LibraryViewMode.list.icon
                  : LibraryViewMode.stack.icon),
              tooltip: stacked ? '리스트로 보기' : '쌓아 보기',
              onPressed: () => ref.read(homeViewModeProvider.notifier).set(
                    stacked ? LibraryViewMode.list : LibraryViewMode.stack,
                  ),
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: '책 검색',
            onPressed: _searchBooks,
          ),
        ],
      ),
      body: Column(
        children: [
          // 일시적인 알림 배너 2종만 상단 고정 — 나머지 상단 위젯은 목록과 함께
          // 스크롤된다(_scrollHeader, 커버 화면에서 목록이 좁아지던 문제).
          const OutboxBanner(),
          // PR20-D — 친구가 새 인용구 추가했음을 인지할 유일한 다리 (V1엔 Realtime 없음).
          const FriendActivityBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref
                  ..invalidate(friendActivityProvider)
                  ..invalidate(currentlyReadingProvider)
                  ..invalidate(moodCountsProvider)
                  ..invalidate(myLibraryProvider);
                await ref.read(myLibraryProvider.future);
              },
              child: library.when(
                loading: () => ListView(
                  children: [
                    _scrollHeader(),
                    const SizedBox(height: AppSpacing.s12),
                    Center(
                      child: CircularProgressIndicator(
                        color: context.colors.accentDefault,
                      ),
                    ),
                  ],
                ),
                error: (e, _) => _errorView(context),
                data: (entries) {
                  if (entries.isEmpty) return _emptyView(context);
                  final books = [for (final e in entries) e.book];
                  final header = _scrollHeader(friendCta: true);
                  final ordered = _readingFirst(books, readingIds);
                  final readingSet = readingIds.toSet();
                  return stacked
                      ? BookStackView(
                          books: ordered,
                          inlinePending: true,
                          compactHeader: true,
                          header: header,
                          readingBookIds: readingSet,
                        )
                      : BookListView(
                          books: ordered,
                          header: header,
                          readingBookIds: readingSet,
                        );
                },
              ),
            ),
          ),
        ],
      ),
      // 홈 하단 고정 배너 — 이 Scaffold는 셸 안쪽이라 배너가 목록과 BottomNav
      // 사이에 앉고, FAB는 Scaffold가 배너 위로 자동 오프셋한다(우발 클릭 방지).
      // 책 0권(빈 홈)에선 미노출 — 신규 유저 첫 화면이 "빈 목록 + 광고"가
      // 되는 걸 막는다(2026-08-01 출시 1개월 진단). 노출 축소라 AdMob 정책 무관.
      bottomNavigationBar:
          hasBooks ? AppBannerAd(adUnitId: homeBannerAdUnitId) : null,
      // 구버전 BottomNav 가운데 [+]가 '활동' 탭으로 교체되며, 핵심 인용구 작성 동선을
      // 홈 FAB로 보강 (PR23 retention 액션 보호).
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/quote/new'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('인용구'),
      ),
    );
  }

  /// 책 목록 위에 함께 스크롤되는 상단 위젯 묶음.
  ///
  /// PR23 "지금 읽고 있어요" 줄은 책 0권(빈 홈)에서만 — 그 빈 상태의 [시작한 책
  /// 알려주기]가 첫 책 등록 진입점이라. 책이 있으면 읽는 중인 책은 목록 맨 위
  /// "읽는 중" + [✎]로 흡수(같은 책이 줄·목록에 두 번 보이던 중복 제거, 2026-09-26).
  Widget _scrollHeader({bool nowReading = false, bool friendCta = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // (구 PR29-I "최근 독자 후기" row는 '활동' 탭으로 이전 — 홈 중복 제거.)
        if (nowReading) const NowReadingRow(),
        const RecallCard(),
        // PR18-B: 책 ≥1권이고 친구 0명일 때만 친구 찾기 CTA 노출
        // (책 0권일 땐 빈상태 CTA가 우선 — 진입점 마찰 해소, qa-tester 권고).
        if (friendCta) const FriendSearchCta(),
      ],
    );
  }

  /// 읽는 중인 책을 [readingIds] 순서로 맨 위에, 나머지는 원래 순서(최근 담은 순).
  static List<Book> _readingFirst(List<Book> books, List<String> readingIds) {
    if (readingIds.isEmpty) return books;
    final byId = {for (final b in books) b.id: b};
    final pinned = [
      for (final id in readingIds)
        if (byId[id] != null) byId[id]!,
    ];
    final pinnedIds = {for (final b in pinned) b.id};
    return [...pinned, ...books.where((b) => !pinnedIds.contains(b.id))];
  }

  Widget _emptyView(BuildContext context) {
    if (!_loggedEmptyView) {
      _loggedEmptyView = true;
      appAnalytics.logHomeEmptyView();
    }
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      children: [
        _scrollHeader(nowReading: true),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s6,
            AppSpacing.s12,
            AppSpacing.s6,
            AppSpacing.s6,
          ),
          child: Column(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 48, color: context.colors.iconMuted),
              const SizedBox(height: AppSpacing.s4),
              Text('아직 담은 책이 없어요',
                  textAlign: TextAlign.center, style: textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.s2),
              Text('좋아하는 책의 한 줄을 저장하면 그 책이 여기 쌓여요.',
                  textAlign: TextAlign.center, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.s6),
              ElevatedButton(
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      children: [
        _scrollHeader(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s6,
            AppSpacing.s12,
            AppSpacing.s6,
            AppSpacing.s6,
          ),
          child: Column(
            children: [
              Text('책 목록을 불러오지 못했어요',
                  textAlign: TextAlign.center, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.s3),
              OutlinedButton(
                onPressed: () => ref.invalidate(myLibraryProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
