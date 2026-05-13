import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

/// 5종 템플릿이 공유하는 워터마크 텍스트.
/// `WatermarkConfig`(`AppWatermark.minimal` 기본)의 폰트·크기·opacity를 따른다.
/// 텍스트 색은 카드 배경에 맞춰 호출자가 전달(어두운 카드=흰색 계열, 밝은 카드=잉크).
class CardWatermark extends StatelessWidget {
  const CardWatermark({
    super.key,
    required this.config,
    required this.color,
  });

  final WatermarkConfig config;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      config.text,
      style: TextStyle(
        fontFamily: config.fontFamily,
        fontWeight: FontWeight.w400,
        fontSize: config.fontSize,
        color: color.withValues(alpha: config.opacity),
        letterSpacing: config.fontSize * AppLetterSpacing.wide,
      ),
    );
  }
}
