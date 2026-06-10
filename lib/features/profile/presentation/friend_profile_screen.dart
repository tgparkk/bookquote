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
// - 닉네임 미설정/이메일 local-part 의심 패턴은 진입 즉시 `_NicknameGateView` 풀스크린

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_status_view.dart';
import '../../book/domain/book.dart';
import '../../book/presentation/widgets/book_cover.dart';
import '../../follow/data/follow_repository.dart';
import '../../follow/state/follow_providers.dart';
import '../../likes/data/like_repository.dart';
import '../../likes/presentation/like_button.dart';
import '../../moderation/data/moderation_repository.dart';
import '../../moderation/presentation/report_dialog.dart';
import '../../quote/data/quote_repository.dart';
import '../../quote/presentation/widgets/quote_list_card.dart';
import '../domain/profile.dart';
import '../state/friend_providers.dart';

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
                : _ProfileOverflowMenu(
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
        error: (_, _) => _ErrorView(onRetry: () => ref.invalidate(friendProfileProvider(widget.userId))),
        data: (profile) {
          if (profile == null) return const _NotFoundView();
          if (_isSuspiciousNickname(profile.displayName)) {
            return _NicknameGateView(profile: profile);
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
            child: _Header(userId: userId, profile: profile),
          ),
          if (!isPublic)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _LockedLibraryView(userId: userId),
            )
          else ...[
            SliverToBoxAdapter(
              child: _SegmentHeader(
                userId: userId,
                tab: tab,
                onChanged: onTabChanged,
              ),
            ),
            if (tab == 0)
              _BooksSliver(userId: userId)
            else
              _QuotesSliver(
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

// ─── Header ─────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  const _Header({required this.userId, required this.profile});

  final String userId;
  final Profile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(friendFollowCountsProvider(userId));
    final name = profile.displayName ?? '(이름 없음)';
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            label: '$name 프로필 사진',
            child: CircleAvatar(
              radius: 32,
              backgroundColor: context.colors.accentContainer,
              backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false)
                  ? NetworkImage(profile.avatarUrl!)
                  : null,
              child: (profile.avatarUrl?.isNotEmpty ?? false)
                  ? null
                  : Text(
                      initial,
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontWeight: FontWeight.w600,
                        fontSize: AppFontSize.xl,
                        color: context.colors.accentOnContainer,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.headlineLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s1),
                _FollowCountsRow(userId: userId, counts: countsAsync),
                const SizedBox(height: AppSpacing.s2),
                _FollowButton(userId: userId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowCountsRow extends StatelessWidget {
  const _FollowCountsRow({required this.userId, required this.counts});

  final String userId;
  final AsyncValue<FollowCounts> counts;

  @override
  Widget build(BuildContext context) {
    final followers = counts.value?.followers ?? 0;
    final following = counts.value?.following ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CountTap(
          label: '팔로워',
          count: followers,
          onTap: () =>
              _openFollowSheet(context, userId, FollowListKind.followers),
        ),
        const SizedBox(width: AppSpacing.s3),
        _CountTap(
          label: '팔로잉',
          count: following,
          onTap: () =>
              _openFollowSheet(context, userId, FollowListKind.following),
        ),
      ],
    );
  }
}

class _CountTap extends StatelessWidget {
  const _CountTap({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label $count명',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s2,
            vertical: AppSpacing.s1,
          ),
          child: Text(
            '$label $count',
            style: AppTextStyles.bodySmall.copyWith(
              color: context.colors.onSurfaceMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({required this.userId});

  final String userId;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _busy = false;
  // 낙관 토글: AsyncValue를 기다리지 않고 즉시 반영. 실패 시 rollback.
  bool? _optimistic;

  Future<void> _toggle() async {
    if (_busy) return;
    final current = _optimistic ??
        (ref.read(isFollowingProvider(widget.userId)).value ?? false);
    setState(() {
      _busy = true;
      _optimistic = !current;
    });
    final repo = ref.read(followRepositoryProvider);
    final wasFollowing = current;
    try {
      if (wasFollowing) {
        final ok = await _confirmUnfollow();
        if (!ok) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _optimistic = wasFollowing;
          });
          return;
        }
        await repo.unfollow(widget.userId);
      } else {
        await repo.follow(widget.userId);
      }
      ref.invalidate(isFollowingProvider(widget.userId));
      ref.invalidate(friendFollowCountsProvider(widget.userId));
      // me_screen "내 친구 N명" / `/me/following` 목록 즉시 갱신.
      // me 화면이 마운트된 채 push → 토글 → pop 흐름에선 autoDispose가 걸리지
      // 않아 stale 카운트가 남는다(2026-05-23 버그).
      ref.invalidate(myFollowingCountProvider);
      ref.invalidate(myFollowingProvider);
      // 팔로우 토글로 친구 책·인용구 RLS 통과 여부가 바뀜 → 컨텐츠 즉시 invalidate.
      ref.invalidate(friendBooksProvider(widget.userId));
      // segment 라벨도 갱신 (팔로우 전엔 0, 팔로우 직후 정확한 카운트).
      ref.invalidate(friendProfileAggregateProvider(widget.userId));
      // (인용구는 screen state 기반이라 다음 reload 때 갱신)
    } on FollowRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _optimistic = wasFollowing); // rollback
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmUnfollow() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('팔로우를 끊을까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('언팔로우'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(isFollowingProvider(widget.userId));
    final isFollowing = _optimistic ?? (async.value ?? false);
    if (_busy) {
      return const SizedBox(
        width: 110,
        height: 36,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (isFollowing) {
      return OutlinedButton.icon(
        onPressed: _toggle,
        icon: const Icon(Icons.check_rounded, size: 16),
        label: const Text('팔로잉'),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colors.onSurfaceMuted,
          side: BorderSide(color: context.colors.border, width: 1.5),
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: _toggle,
      icon: const Icon(Icons.add_rounded, size: 16),
      label: const Text('팔로우'),
      style: FilledButton.styleFrom(
        backgroundColor: context.colors.accentDefault,
        foregroundColor: context.colors.accentOnAccent,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// ─── Segment ────────────────────────────────────────────────

class _SegmentHeader extends ConsumerWidget {
  const _SegmentHeader({
    required this.userId,
    required this.tab,
    required this.onChanged,
  });

  final String userId;
  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agg = ref.watch(friendProfileAggregateProvider(userId)).value;
    final booksLabel = agg == null ? '책' : '책 ${agg.books}';
    final quotesLabel = agg == null ? '인용구' : '인용구 ${agg.quotes}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: SegmentedButton<int>(
        segments: [
          ButtonSegment(value: 0, label: Text(booksLabel)),
          ButtonSegment(value: 1, label: Text(quotesLabel)),
        ],
        selected: {tab},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChanged(s.first),
      ),
    );
  }
}

// ─── 책 탭 ─────────────────────────────────────────────────

class _BooksSliver extends ConsumerWidget {
  const _BooksSliver({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendBooksProvider(userId));
    return async.when(
      loading: () => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Center(child: CircularProgressIndicator(color: context.colors.accentDefault)),
        ),
      ),
      error: (_, _) => SliverToBoxAdapter(
        child: _ErrorView(
          onRetry: () => ref.invalidate(friendBooksProvider(userId)),
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return SliverToBoxAdapter(child: _EmptyBooksView(userId: userId));
        }
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s2,
            AppSpacing.s4,
            AppSpacing.s16,
          ),
          sliver: SliverList.separated(
            itemCount: books.length,
            separatorBuilder: (_, _) => const Divider(height: AppSpacing.s8),
            itemBuilder: (_, i) => _BookRow(book: books[i]),
          ),
        );
      },
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

class _EmptyBooksView extends ConsumerWidget {
  const _EmptyBooksView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 공개 프로필이라도 비팔로워는 RLS상 책이 0 row — "공개한 책이 없어요"는
    // 오해를 부른다. 팔로우 여부로 카피를 분기(2026-05-21 매니저 회의).
    final isFollowing = ref.watch(isFollowingProvider(userId)).value ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s12,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 48,
            color: context.colors.iconMuted,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            isFollowing ? '아직 공개한 책이 없어요' : '팔로우하면 책을 볼 수 있어요',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall,
          ),
        ],
      ),
    );
  }
}

// ─── 인용구 탭 ─────────────────────────────────────────────

class _QuotesSliver extends StatelessWidget {
  const _QuotesSliver({
    required this.userId,
    required this.items,
    required this.loading,
    required this.loadingMore,
    required this.error,
    required this.expandedId,
    required this.onToggleExpanded,
    required this.onRetry,
  });

  final String userId;
  final List<QuoteWithBook> items;
  final bool loading;
  final bool loadingMore;
  final Object? error;
  final String? expandedId;
  final ValueChanged<String> onToggleExpanded;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Center(
            child: CircularProgressIndicator(color: context.colors.accentDefault),
          ),
        ),
      );
    }
    if (error != null) {
      return SliverToBoxAdapter(
        child: _ErrorView(onRetry: onRetry),
      );
    }
    if (items.isEmpty) {
      return SliverToBoxAdapter(child: _EmptyQuotesView(userId: userId));
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s16,
      ),
      sliver: SliverList.separated(
        itemCount: items.length + (loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(AppSpacing.s4),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final item = items[i];
          final id = item.quote.id;
          final bookId = item.quote.bookId;
          return QuoteListCard(
            quote: item.quote,
            book: item.book,
            expanded: expandedId == id,
            readOnly: true,
            onTap: () => onToggleExpanded(id),
            onOpenBook: bookId == null
                ? null
                : () => context.push('/book/$bookId'),
            // PR25 — 펼친 상태에서만 [신고] 노출(접힌 목록은 그대로 깨끗).
            onReport: () => showReportDialog(
              context,
              reportedQuoteId: id,
              targetLabel: '이 인용구',
            ),
            // PR-LC — 친구 인용구라 좋아요 가능(내 인용구엔 미주입).
            likeButton: LikeButton(
              target: (kind: LikeTargetKind.quote, id: id),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyQuotesView extends ConsumerWidget {
  const _EmptyQuotesView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowing = ref.watch(isFollowingProvider(userId)).value ?? false;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s12,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_outlined,
            size: 48,
            color: context.colors.iconMuted,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            isFollowing ? '공개된 인용구가 없어요' : '팔로우하면 인용구를 볼 수 있어요',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall,
          ),
        ],
      ),
    );
  }
}

// ─── 잠긴 서재 ─────────────────────────────────────────────

class _LockedLibraryView extends ConsumerWidget {
  const _LockedLibraryView({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 팔로잉 중인지에 따라 카피 분기 (friend-profile.md §3).
    final followingAsync = ref.watch(isFollowingProvider(userId));
    final isFollowing = followingAsync.value ?? false;
    final subtitle = isFollowing
        ? '팔로우 중이에요. 서재가 공개되면 여기서 볼 수 있어요.'
        : '공개 설정을 켜면 보여요.';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s6,
        vertical: AppSpacing.s12,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 48,
            color: context.colors.iconMuted,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            '이 서재는 비공개예요',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: context.colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: context.colors.onSurfaceSubtle,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 닉네임 게이트 ─────────────────────────────────────────

class _NicknameGateView extends StatelessWidget {
  const _NicknameGateView({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.badge_outlined,
              size: 48,
              color: context.colors.iconMuted,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '먼저 내 닉네임을 설정해주세요',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '본명이 친구에게 노출되지 않도록\n공개 닉네임을 먼저 정해주세요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.colors.onSurfaceSubtle,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            FilledButton(
              onPressed: () => context.go('/me'),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.accentDefault,
                foregroundColor: context.colors.accentOnAccent,
              ),
              child: const Text('내 정보로 이동'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 시트 / 에러 / 빈상태 공용 ─────────────────────────────

Future<void> _openFollowSheet(
  BuildContext context,
  String userId,
  FollowListKind kind,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FollowersSheet(userId: userId, kind: kind),
  );
}

class _FollowersSheet extends ConsumerWidget {
  const _FollowersSheet({required this.userId, required this.kind});

  final String userId;
  final FollowListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      friendFollowListProvider((userId: userId, kind: kind)),
    );
    final title = kind == FollowListKind.followers ? '팔로워' : '팔로잉';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: AppSpacing.s2),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Text(title, style: AppTextStyles.headlineMedium),
          ),
          Expanded(
            child: async.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: context.colors.accentDefault),
              ),
              error: (_, _) => Center(
                child: Text(
                  '목록을 불러오지 못했어요.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.colors.onSurfaceSubtle),
                ),
              ),
              data: (profiles) {
                if (profiles.isEmpty) {
                  return Center(
                    child: Text(
                      kind == FollowListKind.followers
                          ? '아직 팔로워가 없어요'
                          : '팔로우 중인 사람이 없어요',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.colors.onSurfaceSubtle),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  itemCount: profiles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _FollowSheetTile(profile: profiles[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowSheetTile extends StatelessWidget {
  const _FollowSheetTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName ?? '(이름 없음)';
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colors.accentContainer,
        backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false)
            ? NetworkImage(profile.avatarUrl!)
            : null,
        child: (profile.avatarUrl?.isNotEmpty ?? false)
            ? null
            : Text(
                initial,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colors.accentOnContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      title: Text(name, style: AppTextStyles.bodyLarge),
      onTap: () {
        Navigator.of(context).pop();
        context.push('/u/${profile.id}');
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Column(
        children: [
          Text(
            '불러오지 못했어요. 잠시 후 다시 시도해주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}

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

// ─── 신고·차단 메뉴 (PR25) ──────────────────────────────────

class _ProfileOverflowMenu extends ConsumerWidget {
  const _ProfileOverflowMenu({required this.userId, required this.displayName});

  final String userId;
  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (displayName == null || displayName!.isEmpty)
        ? '이 사용자'
        : displayName!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        switch (v) {
          case 'report':
            showReportDialog(
              context,
              reportedUserId: userId,
              targetLabel: '$name님',
            );
          case 'block':
            _confirmAndBlock(context, ref, name);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'report', child: Text('신고하기')),
        PopupMenuItem(value: 'block', child: Text('차단하기')),
      ],
    );
  }

  Future<void> _confirmAndBlock(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name님을 차단할까요?'),
        content: const Text(
          '서로의 인용구와 프로필이 더 이상 보이지 않고, 맺어진 팔로우도 해제돼요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '차단',
              style: TextStyle(color: AppColors.semanticError),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(moderationRepositoryProvider).block(userId);
      if (!context.mounted) return;
      // 차단한 사용자는 RLS상 더 이상 조회 불가 — 화면을 닫는다.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$name님을 차단했어요.')));
    } catch (_) {
      if (!context.mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('차단하지 못했어요. 잠시 후 다시 시도해주세요.')),
        );
    }
  }
}
