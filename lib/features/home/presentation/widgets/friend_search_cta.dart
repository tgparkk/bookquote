// 홈 친구 찾기 CTA — 인용구 ≥1 + 친구 0명일 때만 노출 (PR18-B).
//
// 호출처(home_screen)가 feed.value?.isNotEmpty 1차 분기 후 이 위젯을 렌더.
// 이 위젯은 친구 0명 여부를 2차 분기. 둘 다 만족할 때만 카드 UI.
// 디자인 = RecallCard와 같은 톤(accent50 InkWell), 메모리에 박혀있는 차별화
// 후크 패턴 일관.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../follow/state/follow_providers.dart';

class FriendSearchCta extends ConsumerWidget {
  const FriendSearchCta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(myFollowingCountProvider);
    final count = countAsync.value;
    // 로딩 또는 에러 — 깜박임·중복 표시 회피 위해 미노출.
    if (count == null || count > 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s3,
        AppSpacing.s4,
        0,
      ),
      child: Material(
        color: AppColors.accent50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () => context.push('/me/friend-search'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s3,
              AppSpacing.s4,
              AppSpacing.s3,
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.people_outline,
                  size: 20,
                  color: AppColors.accent600,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: Text(
                    '친구를 찾아 서재를 구경해 보세요 →',
                    style: TextStyle(
                      fontFamily: AppFonts.ui,
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent700,
                    ),
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
