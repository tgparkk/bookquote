// 친구 프로필 [인용구] 탭 Sliver — cursor 페이지네이션 목록 + 빈상태.
// 본체: `friend_profile_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../follow/state/follow_providers.dart';
import '../../../likes/data/like_repository.dart';
import '../../../likes/presentation/like_button.dart';
import '../../../moderation/presentation/report_dialog.dart';
import '../../../quote/data/quote_repository.dart';
import '../../../quote/presentation/widgets/quote_list_card.dart';
import 'profile_error_view.dart';

// ─── 인용구 탭 ─────────────────────────────────────────────

class ProfileQuotesSliver extends StatelessWidget {
  const ProfileQuotesSliver({
    super.key,
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
        child: ProfileErrorView(onRetry: onRetry),
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
