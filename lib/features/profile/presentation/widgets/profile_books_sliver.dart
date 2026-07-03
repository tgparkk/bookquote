// 친구 프로필 [책 ↔ 인용구] 세그먼트 헤더 + [책] 탭 Sliver(책 행·빈상태).
// 본체: `friend_profile_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../../follow/state/follow_providers.dart';
import '../../state/friend_providers.dart';
import 'profile_error_view.dart';

// ─── Segment ────────────────────────────────────────────────

class ProfileSegmentHeader extends ConsumerWidget {
  const ProfileSegmentHeader({
    super.key,
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

class ProfileBooksSliver extends ConsumerWidget {
  const ProfileBooksSliver({super.key, required this.userId});

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
        child: ProfileErrorView(
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
