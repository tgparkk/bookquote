// 친구 프로필 게이트 뷰 — 비공개 서재 잠금 + 닉네임 미설정 풀스크린 가드.
// 본체: `friend_profile_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../follow/state/follow_providers.dart';
import '../../domain/profile.dart';

// ─── 잠긴 서재 ─────────────────────────────────────────────

class LockedLibraryView extends ConsumerWidget {
  const LockedLibraryView({super.key, required this.userId});

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

class NicknameGateView extends StatelessWidget {
  const NicknameGateView({super.key, required this.profile});

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
