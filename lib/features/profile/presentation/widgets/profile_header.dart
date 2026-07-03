// 친구 프로필 헤더 — 아바타 + display_name + 팔로워/팔로잉 카운트 + 팔로우
// 버튼. 본체: `friend_profile_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/profile.dart';
import '../../state/friend_providers.dart';
import 'follow_button.dart';
import 'followers_sheet.dart';

// ─── Header ─────────────────────────────────────────────────

class ProfileHeader extends ConsumerWidget {
  const ProfileHeader({super.key, required this.userId, required this.profile});

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
                FollowButton(userId: userId),
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
              openFollowSheet(context, userId, FollowListKind.followers),
        ),
        const SizedBox(width: AppSpacing.s3),
        _CountTap(
          label: '팔로잉',
          count: following,
          onTap: () =>
              openFollowSheet(context, userId, FollowListKind.following),
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
