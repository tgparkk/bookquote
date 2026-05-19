// 홈 "최근 친구 활동" 1줄 배너 (PR20-D — UX#4 K-factor 다리).
//
// `friendActivityProvider` watch. 결과 0건이면 자체 숨김 (빈상태 회피).
// 1건 이상이면 "지윤 외 N명이 새 인용구를 보탰어요" → 탭 = 첫 친구 프로필.
// 탭 시 `markFriendActivitySeen()`으로 last_seen 갱신 → 다음 invalidate 때 0건.
//
// V1엔 Realtime·push 없음 → 사용자가 앱 켤 때 fetch가 유일한 신호. Pull-to-refresh
// (home_screen)에서도 `ref.invalidate(friendActivityProvider)` 호출.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../state/friend_activity_provider.dart';

class FriendActivityBanner extends ConsumerWidget {
  const FriendActivityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendActivityProvider);
    final activities = async.value;
    if (activities == null || activities.isEmpty) {
      return const SizedBox.shrink();
    }
    final first = activities.first;
    final firstName = first.displayName ?? '익명';
    final extras = activities.length - 1;
    final text = extras > 0
        ? '$firstName 외 $extras명이 새 인용구를 보탰어요'
        : '$firstName님이 새 인용구 ${first.count}개를 보탰어요';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s1,
      ),
      child: Material(
        color: AppColors.accent50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () async {
            await markFriendActivitySeen();
            if (!context.mounted) return;
            ref.invalidate(friendActivityProvider);
            context.push('/u/${first.userId}');
          },
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s2,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.accent200),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.accent700,
                ),
                const SizedBox(width: AppSpacing.s2),
                Expanded(
                  child: Text(
                    text,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accent800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.accent700,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
