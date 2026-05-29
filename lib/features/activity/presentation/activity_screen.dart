// 책귀 — "활동" 탭 (구 '추가' [+] 탭 대체).
//
// 흩어져 있던 소셜/발견 콘텐츠를 한 탭으로 모음:
//   1) 친구 빠른 진입 (내 친구 / 친구 찾기 / 독서량 순위) — 기존 /me/* 라우트
//   2) 친구 활동      (friendActivityProvider — 친구가 새로 보탠 인용구)
//   3) 친구가 읽은 책 (friendRecentBooksProvider — 신규 RPC)
//   4) 모두의 공개 후기 (recentPublicReviewsProvider — 기존 홈 row 데이터 재사용)
//
// 각 콘텐츠 섹션은 빈/로딩이면 자체 숨김. 셋 다 비면 빈상태 CTA. Pull-to-refresh로
// 세 provider invalidate. 미로그인이어도 provider가 빈 리스트라 크래시 없음.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../book/presentation/widgets/book_cover.dart';
import '../../book_review/data/book_review_repository.dart';
import '../../book_review/state/book_review_providers.dart';
import '../../follow/state/friend_activity_provider.dart';
import '../../follow/state/friend_recent_books_provider.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(friendActivityProvider).value ?? const [];
    final books = ref.watch(friendRecentBooksProvider).value ?? const [];
    final reviews = ref.watch(recentPublicReviewsProvider).value ?? const [];
    final hasContent =
        activity.isNotEmpty || books.isNotEmpty || reviews.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('활동'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: '친구 찾기',
            onPressed: () => context.push('/me/friend-search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(friendActivityProvider);
          ref.invalidate(friendRecentBooksProvider);
          ref.invalidate(recentPublicReviewsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: AppSpacing.s8),
          children: [
            const _FriendQuickRow(),
            const _FriendActivitySection(),
            const _FriendRecentBooksSection(),
            const _PublicReviewsSection(),
            if (!hasContent) const _ActivityEmptyHint(),
          ],
        ),
      ),
    );
  }
}

/// 친구 관련 화면으로의 빠른 진입 — 기존 /me/* 라우트 재사용. 항상 노출.
class _FriendQuickRow extends StatelessWidget {
  const _FriendQuickRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s3,
        AppSpacing.s4,
        AppSpacing.s1,
      ),
      child: Row(
        children: [
          _QuickChip(
            icon: Icons.group_outlined,
            label: '내 친구',
            onTap: () => context.push('/me/following'),
          ),
          const SizedBox(width: AppSpacing.s2),
          _QuickChip(
            icon: Icons.person_add_alt_1_outlined,
            label: '친구 찾기',
            onTap: () => context.push('/me/friend-search'),
          ),
          const SizedBox(width: AppSpacing.s2),
          _QuickChip(
            icon: Icons.emoji_events_outlined,
            label: '독서량 순위',
            onTap: () => context.push('/me/friends-ranking'),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.secondary100,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.secondary400),
            ),
            child: Column(
              children: [
                Icon(icon, size: 20, color: AppColors.accent700),
                const SizedBox(height: AppSpacing.s1),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: AppFontSize.xs,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 섹션 제목 한 줄 (아이콘 + 라벨).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent700),
          const SizedBox(width: AppSpacing.s2),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
              color: AppColors.accent700,
            ),
          ),
        ],
      ),
    );
  }
}

/// 친구 활동 — 친구가 새로 보탠 인용구. 0건이면 자체 숨김.
class _FriendActivitySection extends ConsumerWidget {
  const _FriendActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activities = ref.watch(friendActivityProvider).value;
    if (activities == null || activities.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.auto_awesome_rounded,
          label: '친구 활동',
        ),
        ...activities.map((a) => _FriendActivityTile(activity: a)),
      ],
    );
  }
}

class _FriendActivityTile extends ConsumerWidget {
  const _FriendActivityTile({required this.activity});
  final FriendActivity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = activity.displayName ?? '익명';
    final hasAvatar = activity.avatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return ListTile(
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.accent200,
        backgroundImage: hasAvatar ? NetworkImage(activity.avatarUrl!) : null,
        child: hasAvatar
            ? null
            : Text(
                initial,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary900,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w600,
          color: AppColors.primary800,
        ),
      ),
      subtitle: Text(
        '새 인용구 ${activity.count}개를 보탰어요',
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary500),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        size: 18,
        color: AppColors.accent700,
      ),
      onTap: () async {
        await markFriendActivitySeen();
        if (!context.mounted) return;
        ref.invalidate(friendActivityProvider);
        context.push('/u/${activity.userId}');
      },
    );
  }
}

/// 친구가 읽은 책 — 표지 가로 스크롤. 0건이면 자체 숨김.
class _FriendRecentBooksSection extends ConsumerWidget {
  const _FriendRecentBooksSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final books = ref.watch(friendRecentBooksProvider).value;
    if (books == null || books.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.menu_book_outlined,
          label: '친구가 읽은 책',
        ),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            itemCount: books.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
            itemBuilder: (_, i) => _FriendBookCard(book: books[i]),
          ),
        ),
      ],
    );
  }
}

class _FriendBookCard extends StatelessWidget {
  const _FriendBookCard({required this.book});
  final FriendRecentBook book;

  @override
  Widget build(BuildContext context) {
    final name = book.displayName ?? '익명';
    return SizedBox(
      width: 92,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => context.push('/book/${book.bookId}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              url: book.bookCoverUrl,
              title: book.bookTitle,
              width: 92,
              height: 132,
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.xs,
                fontWeight: FontWeight.w600,
                color: AppColors.primary600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 모두의 공개 후기 — 세로 카드. 0건이면 자체 숨김.
class _PublicReviewsSection extends ConsumerWidget {
  const _PublicReviewsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(recentPublicReviewsProvider).value;
    if (reviews == null || reviews.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: Icons.rate_review_outlined,
          label: '최근 독자 후기',
        ),
        ...reviews.map((r) => _ReviewCard(review: r)),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final RecentBookReview review;

  @override
  Widget build(BuildContext context) {
    final name = review.displayName ?? '(이름 없음)';
    final hasAvatar = review.avatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s1,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: Material(
        color: AppColors.secondary100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: () => context.push('/book/${review.bookId}'),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.secondary400),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BookCover(
                  url: review.bookCoverUrl,
                  title: review.bookTitle,
                  width: 50,
                  height: 75,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.accent200,
                            backgroundImage: hasAvatar
                                ? NetworkImage(review.avatarUrl!)
                                : null,
                            child: hasAvatar
                                ? null
                                : Text(
                                    initial,
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.primary900,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: AppSpacing.s1),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: AppFonts.ui,
                                fontSize: AppFontSize.xs,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.bookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.ui,
                          fontSize: AppFontSize.xs,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.quote,
                          fontSize: AppFontSize.sm,
                          height: 1.45,
                          color: AppColors.primary800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 친구도 후기도 없을 때 — 친구 찾기로 유도.
class _ActivityEmptyHint extends StatelessWidget {
  const _ActivityEmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s8,
        AppSpacing.s6,
        AppSpacing.s6,
      ),
      child: Column(
        children: [
          Icon(
            Icons.diversity_3_outlined,
            size: 44,
            color: AppColors.secondary700,
          ),
          const SizedBox(height: AppSpacing.s3),
          Text(
            '친구를 찾아 활동을 채워보세요',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w700,
              color: AppColors.primary700,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '친구를 팔로우하면 친구가 읽은 책과 남긴 후기가 여기에 모여요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary500),
          ),
          const SizedBox(height: AppSpacing.s4),
          FilledButton.icon(
            onPressed: () => context.push('/me/friend-search'),
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: const Text('친구 찾기'),
          ),
        ],
      ),
    );
  }
}
