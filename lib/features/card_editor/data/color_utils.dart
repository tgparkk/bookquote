import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../../core/theme/tokens.dart';

// ─────────────────────────────────────────────
// 배경 조정 — 추출 팔레트의 dominant/muted를 템플릿 배경에 쓸 수 있는 톤으로 정렬
// ─────────────────────────────────────────────

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

// ─────────────────────────────────────────────
// WCAG 2.1 대비 유틸 — 추출 팔레트의 textOnBackground/subtextOnBackground 계산에 사용
// ─────────────────────────────────────────────

/// WCAG 2.1 기준 상대 휘도(0.0~1.0).
/// Color의 r/g/b는 이미 0~1 정규화 값(Flutter 3.27+ API).
/// (`docs/design/color-extraction.md` §4.relativeLuminance)
double relativeLuminance(Color color) {
  double linearize(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linearize(color.r) +
      0.7152 * linearize(color.g) +
      0.0722 * linearize(color.b);
}

/// WCAG 2.1 기준 두 색의 대비비. 항상 ≥1.0(흑백 조합이면 ≈21).
double contrastRatio(Color a, Color b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// 배경 위에서 [foreground]가 [minRatio] 대비를 만족하면 그대로, 미달이면
/// `primary900`/`secondary200` 중 대비가 더 높은 쪽으로 교체.
///
/// minRatio 기본 4.5(WCAG AA 본문). 큰 텍스트/보조 텍스트는 3.0 권장.
/// (`docs/design/color-extraction.md` §4.ensureContrast)
Color ensureContrast(
  Color background,
  Color foreground, {
  double minRatio = 4.5,
}) {
  if (contrastRatio(background, foreground) >= minRatio) return foreground;
  final dark = contrastRatio(background, AppColors.primary900);
  final light = contrastRatio(background, AppColors.secondary200);
  return dark >= light ? AppColors.primary900 : AppColors.secondary200;
}

/// 배경 밝기로 기본 텍스트 색 결정(검정 vs 흰색 계열).
/// 임계값 0.18은 지각 기반(0.5보다 정확).
/// (`docs/design/color-extraction.md` §5)
Color getTextColorForBackground(Color background) {
  return relativeLuminance(background) > 0.18
      ? AppColors.primary900
      : AppColors.secondary200;
}
