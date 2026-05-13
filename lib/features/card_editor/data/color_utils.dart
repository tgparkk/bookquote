import 'package:flutter/painting.dart';

import '../../../core/theme/tokens.dart';

/// T2 따뜻 배경용: dominant 색을 HSL L 0.94로 밝혀 카드 배경 종이톤으로 변환.
/// 채도 S<0.10이면 토큰 폴백(secondary400) 사용.
/// (`docs/design/color-extraction.md` §6.lightenToBackground)
Color lightenToBackground(Color dominant) {
  final hsl = HSLColor.fromColor(dominant);
  if (hsl.saturation < 0.10) return AppColors.secondary400;
  return hsl.withLightness(0.94).toColor();
}

/// T5 타이포 배경용: muted 색을 HSL L 0.40~0.55 범위 mid-tone으로 정렬.
/// 채도 S<0.10이면 토큰 폴백(primary600) 사용.
/// (`docs/design/color-extraction.md` §6.toMidTone)
Color toMidTone(Color muted) {
  final hsl = HSLColor.fromColor(muted);
  if (hsl.saturation < 0.10) return AppColors.primary600;
  final l = hsl.lightness.clamp(0.40, 0.55);
  return hsl.withLightness(l).toColor();
}
