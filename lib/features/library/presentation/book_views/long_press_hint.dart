// 서재 책 표지에 표시하는 long-press discovery 힌트 (PR11 — 2026-05-28).
//
// 우상단에 작은 ⋮ 뱃지. 표지 자체 탭과 시각 충돌 최소화하려 alpha 0.6, 14x14
// 원형 + 12px 아이콘. 시트 호출이 가능하다는 시각 신호만 — 첫 진입 SnackBar와
// 함께 동선 인지(둘 다 옵션, 박태건 결정 2026-05-28).
//
// child(표지)를 그대로 감싸 Stack에 올린다 — 부모가 Material/InkWell이라
// hit-test는 child 영역 전체가 받음, 뱃지는 비-인터랙티브.

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class LongPressHintOverlay extends StatelessWidget {
  const LongPressHintOverlay({
    super.key,
    required this.child,
    this.padding = 4,
  });

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        Positioned(
          top: padding,
          right: padding,
          child: IgnorePointer(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary900.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.more_vert_rounded,
                size: 12,
                color: AppColors.secondary50,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
