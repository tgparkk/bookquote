// PR29: 친구 독서량 순위 화면 — `/me/friends-ranking`.
//
// 내가 팔로우한 친구들 + 본인의 읽은 책 권수를 순위표로 보여준다. 비공개 프로필
// 또는 비공개 서재 친구는 RLS에 의해 자동 제외(친구 본인은 보임). 진입: 내 팔로잉
// 화면 우상단 액션.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../data/follow_repository.dart';
import '../state/follow_providers.dart';

class FriendsReadingRankingScreen extends ConsumerWidget {
  const FriendsReadingRankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendsReadingRankingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('친구 독서량 순위')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(friendsReadingRankingProvider),
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent500),
            ),
            error: (_, _) => _ErrorView(
              onRetry: () => ref.invalidate(friendsReadingRankingProvider),
            ),
            data: (entries) => entries.isEmpty
                ? const _EmptyView()
                : _RankingList(entries: entries),
          ),
        ),
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({required this.entries});
  final List<FriendReadingRankEntry> entries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _RankRow(rank: i + 1, entry: entries[i]),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank, required this.entry});
  final int rank;
  final FriendReadingRankEntry entry;

  @override
  Widget build(BuildContext context) {
    final name = entry.displayName ?? '(이름 없음)';
    final hasAvatar = entry.avatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return ListTile(
      onTap: entry.isMe ? null : () => context.push('/u/${entry.userId}'),
      leading: SizedBox(
        width: 52,
        child: Row(
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: AppSpacing.s2),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.accent200,
              backgroundImage:
                  hasAvatar ? NetworkImage(entry.avatarUrl!) : null,
              child: hasAvatar
                  ? null
                  : Text(
                      initial,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge,
            ),
          ),
          if (entry.isMe) ...[
            const SizedBox(width: AppSpacing.s2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent100,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '나',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        '${entry.bookCount}권',
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.primary800,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 1·2·3위는 메달 컬러, 나머지는 회색 숫자.
class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (rank) {
      1 => (const Color(0xFFFFD54F), AppColors.primary900),
      2 => (const Color(0xFFCFD8DC), AppColors.primary900),
      3 => (const Color(0xFFE0B084), AppColors.primary900),
      _ => (AppColors.secondary300, AppColors.primary600),
    };
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: AppFontSize.sm,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s16,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      children: [
        const Icon(
          Icons.emoji_events_outlined,
          size: 48,
          color: AppColors.primary300,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '아직 비교할 친구가 없어요',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '서재를 공개로 설정한 친구를 팔로우하면 함께 권수를 비교할 수 있어요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary500),
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s8),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Text(
          '순위를 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s3),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ),
      ],
    );
  }
}
