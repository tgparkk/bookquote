// 오프라인 아웃박스 "동기화 대기 N개" 배너.
//
// 홈·인용목록 상단에 비차단으로 표시. pending 0이면 SizedBox.shrink로 사라짐.
// AnimatedSize로 부드럽게 접힘. 탭 액션은 V1엔 없음 — 단순 상태 표시(V1.5에서 상세).
// 설계 근거: scenario-review-2026-05-17.md F13.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../data/quote_outbox.dart';

class OutboxBanner extends ConsumerWidget {
  const OutboxBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(pendingOutboxCountProvider);
    final count = countAsync.maybeWhen(data: (n) => n, orElse: () => 0);
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: count == 0
          ? const SizedBox.shrink()
          : Semantics(
              container: true,
              liveRegion: true,
              label: '동기화 대기 중 $count개',
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s4,
                  vertical: AppSpacing.s2,
                ),
                color: AppColors.semanticWarningLight,
                child: Row(
                  children: [
                    Icon(
                      Icons.sync_rounded,
                      size: 18,
                      color: AppColors.semanticWarning,
                    ),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(
                      child: Text(
                        '동기화 대기 중 · $count개',
                        style: TextStyle(
                          fontFamily: AppFonts.ui,
                          fontSize: AppFontSize.sm,
                          color: AppColors.semanticWarning,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
