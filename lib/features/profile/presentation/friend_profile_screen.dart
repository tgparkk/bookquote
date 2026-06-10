// 친구 프로필 `/u/:userId` — PR18-C 친구 서재 탐험의 유일한 풀스크린.
//
// 헤더(아바타 + display_name + 팔로워/팔로잉 카운트 + 팔로우 버튼) +
// [책 ↔ 인용구] 세그먼트. 본인 진입(`auth.uid() == :userId`)은 라우터 `_redirect`
// 단계에서 `/me`로 redirect되므로 여기는 *남의 서재* 흐름만.
//
// 보안 핵심:
// - 잠금 인용구는 RLS가 거름(`quotes_friends_read`의 `is_private=false` 게이트)
// - 비공개 프로필은 `is_library_public=false` → 본인이 아니면 profile fetch 자체 0 row
// - 비팔로워는 RLS의 follow subquery로 books·quotes 0 row → "잠긴 서재" 빈상태
// - 닉네임 미설정/이메일 local-part 의심 패턴은 진입 즉시 `NicknameGateView` 풀스크린

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_status_view.dart';
import '../../follow/state/follow_providers.dart';
import '../../quote/data/quote_repository.dart';
import '../domain/profile.dart';
import '../state/friend_providers.dart';
import 'widgets/profile_books_sliver.dart';
import 'widgets/profile_error_view.dart';
import 'widgets/profile_gate_views.dart';
import 'widgets/profile_header.dart';
import 'widgets/profile_overflow_menu.dart';
import 'widgets/profile_quotes_sliver.dart';

class FriendProfileScreen extends ConsumerStatefulWidget {
  const FriendProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<FriendProfileScreen> createState() =>
      _FriendProfileScreenState();
}

class _FriendProfileScreenState extends ConsumerState<FriendProfileScreen> {
  static const _pageSize = 15;

  int _tab = 0; // 0=책, 1=인용구
  final _scrollController = ScrollController();

  // 인용구 cursor 페이지네이션 (screen state — quote_list_view 패턴)
  List<QuoteWithBook> _quotes = const [];
  bool _quotesLoading = true;
  bool _quotesLoadingMore = false;
  bool _quotesHasMore = true;
  Object? _quotesError;
  String? _expandedQuoteId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadQuotes();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_tab != 1) return;
    if (!_quotesHasMore || _quotesLoadingMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreQuotes();
    }
  }

  Future<void> _reloadQuotes() async {
    setState(() {
      _quotesLoading = true;
      _quotesError = null;
      _quotesHasMore = true;
    });
    try {
      final page = await ref
          .read(quoteRepositoryProvider)
          .listFriendQuotesWithBook(widget.userId, limit: _pageSize);
      if (!mounted) return;
      setState(() {
        _quotes = page;
        _quotesHasMore = page.length == _pageSize;
        _quotesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quotesError = e;
        _quotesLoading = false;
      });
    }
  }

  Future<void> _loadMoreQuotes() async {
    if (_quotesLoadingMore || !_quotesHasMore || _quotes.isEmpty) return;
    _quotesLoadingMore = true;
    try {
      final last = _quotes.last.quote;
      final page =
          await ref.read(quoteRepositoryProvider).listFriendQuotesWithBook(
                widget.userId,
                after: (createdAt: last.createdAt, id: last.id),
                limit: _pageSize,
              );
      if (!mounted) return;
      setState(() {
        _quotes = [..._quotes, ...page];
        _quotesHasMore = page.length == _pageSize;
      });
    } catch (_) {
      // 무시 — 다시 스크롤 시 재시도
    } finally {
      _quotesLoadingMore = false;
    }
  }

  Future<void> _refreshAll() async {
    ref.invalidate(friendProfileProvider(widget.userId));
    ref.invalidate(friendBooksProvider(widget.userId));
    ref.invalidate(friendFollowCountsProvider(widget.userId));
    ref.invalidate(isFollowingProvider(widget.userId));
    ref.invalidate(friendProfileAggregateProvider(widget.userId));
    await _reloadQuotes();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(friendProfileProvider(widget.userId));
    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      appBar: AppBar(
        title: profileAsync.when(
          data: (p) => Text(p?.displayName ?? ''),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        actions: [
          // PR25 — 프로필이 로드된 경우에만 신고·차단 메뉴 노출.
          profileAsync.maybeWhen(
            data: (p) => p == null
                ? const SizedBox.shrink()
                : ProfileOverflowMenu(
                    userId: widget.userId,
                    displayName: p.displayName,
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: context.colors.accentDefault)),
        error: (_, _) => ProfileErrorView(onRetry: () => ref.invalidate(friendProfileProvider(widget.userId))),
        data: (profile) {
          if (profile == null) return const _NotFoundView();
          if (_isSuspiciousNickname(profile.displayName)) {
            return NicknameGateView(profile: profile);
          }
          return _Body(
            userId: widget.userId,
            profile: profile,
            tab: _tab,
            onTabChanged: (i) => setState(() => _tab = i),
            scrollController: _scrollController,
            quotes: _quotes,
            quotesLoading: _quotesLoading,
            quotesLoadingMore: _quotesLoadingMore,
            quotesError: _quotesError,
            expandedQuoteId: _expandedQuoteId,
            onToggleExpanded: (id) => setState(
              () => _expandedQuoteId = _expandedQuoteId == id ? null : id,
            ),
            onRefreshAll: _refreshAll,
            onReloadQuotes: _reloadQuotes,
          );
        },
      ),
    );
  }
}

/// `display_name` null/빈값 또는 `.`·`_` 포함(이메일 local-part 패턴)이면 본 화면
/// 진입 봉쇄. friend-profile.md §7 ⑤ "닉네임 본명 노출" 가드.
bool _isSuspiciousNickname(String? name) {
  if (name == null || name.isEmpty) return true;
  return name.contains('.') || name.contains('_');
}

// ─── Body ───────────────────────────────────────────────────

class _Body extends ConsumerWidget {
  const _Body({
    required this.userId,
    required this.profile,
    required this.tab,
    required this.onTabChanged,
    required this.scrollController,
    required this.quotes,
    required this.quotesLoading,
    required this.quotesLoadingMore,
    required this.quotesError,
    required this.expandedQuoteId,
    required this.onToggleExpanded,
    required this.onRefreshAll,
    required this.onReloadQuotes,
  });

  final String userId;
  final Profile profile;
  final int tab;
  final ValueChanged<int> onTabChanged;
  final ScrollController scrollController;
  final List<QuoteWithBook> quotes;
  final bool quotesLoading;
  final bool quotesLoadingMore;
  final Object? quotesError;
  final String? expandedQuoteId;
  final ValueChanged<String> onToggleExpanded;
  final Future<void> Function() onRefreshAll;
  final Future<void> Function() onReloadQuotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPublic = profile.isLibraryPublic;
    return RefreshIndicator(
      onRefresh: onRefreshAll,
      child: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: ProfileHeader(userId: userId, profile: profile),
          ),
          if (!isPublic)
            SliverFillRemaining(
              hasScrollBody: false,
              child: LockedLibraryView(userId: userId),
            )
          else ...[
            SliverToBoxAdapter(
              child: ProfileSegmentHeader(
                userId: userId,
                tab: tab,
                onChanged: onTabChanged,
              ),
            ),
            if (tab == 0)
              ProfileBooksSliver(userId: userId)
            else
              ProfileQuotesSliver(
                userId: userId,
                items: quotes,
                loading: quotesLoading,
                loadingMore: quotesLoadingMore,
                error: quotesError,
                expandedId: expandedQuoteId,
                onToggleExpanded: onToggleExpanded,
                onRetry: onReloadQuotes,
              ),
          ],
        ],
      ),
    );
  }
}

// ─── 에러 / 빈상태 ─────────────────────────────────────────

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return AppStatusView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
      icon: Icons.person_off_outlined,
      iconColor: context.colors.iconMuted,
      title: '사용자를 찾을 수 없어요',
      titleStyle: AppTextStyles.headlineSmall,
      actions: [
        OutlinedButton(
          onPressed: () => context.go('/'),
          child: const Text('홈으로'),
        ),
      ],
    );
  }
}
