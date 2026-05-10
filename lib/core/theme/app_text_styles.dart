// 책귀 — 텍스트 스타일
//
// Material `TextTheme` 슬롯에 매핑되는 UI 스타일과,
// 카드 안의 인용구 본문에 쓰이는 별도 스타일을 한곳에 모은다.
//
// 폰트 패밀리 상수(`AppFonts.ui`, `AppFonts.quote`)는 pubspec.yaml에
// 폰트 파일이 등록될 때까지 시스템 폰트로 폴백된다 (디자인 시스템 의도된 동작).

import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTextStyles {
  // ── Display / Headline (UI) ──────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: AppFonts.uiBold,
    fontSize: AppFontSize.xxl,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.tight,
    fontWeight: FontWeight.w700,
    color: AppColors.primary900,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: AppFonts.uiSemiBold,
    fontSize: AppFontSize.xl,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.tight,
    fontWeight: FontWeight.w600,
    color: AppColors.primary900,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: AppFonts.uiSemiBold,
    fontSize: AppFontSize.lg,
    height: AppLineHeight.tight,
    fontWeight: FontWeight.w600,
    color: AppColors.primary900,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: AppFonts.uiSemiBold,
    fontSize: AppFontSize.md,
    height: AppLineHeight.normal,
    fontWeight: FontWeight.w600,
    color: AppColors.primary900,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: AppFonts.uiMedium,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
    fontWeight: FontWeight.w500,
    color: AppColors.primary900,
  );

  // ── Title ────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: AppFonts.uiSemiBold,
    fontSize: AppFontSize.md,
    height: AppLineHeight.normal,
    fontWeight: FontWeight.w600,
    color: AppColors.primary900,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.uiMedium,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
    fontWeight: FontWeight.w500,
    color: AppColors.primary800,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: AppFonts.uiMedium,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.normal,
    fontWeight: FontWeight.w500,
    color: AppColors.primary700,
  );

  // ── Body ─────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
    color: AppColors.primary800,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.normal,
    color: AppColors.primary700,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppFontSize.xs,
    height: AppLineHeight.normal,
    color: AppColors.primary600,
  );

  // ── Label ────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.uiMedium,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wide,
    fontWeight: FontWeight.w500,
    color: AppColors.primary700,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: AppFonts.uiMedium,
    fontSize: AppFontSize.xs,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wide,
    fontWeight: FontWeight.w500,
    color: AppColors.primary600,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontSize: AppFontSize.xxs,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wider,
    color: AppColors.primary500,
  );

  // ── Quote (카드 본문 전용 — TextTheme 외) ────────
  /// 인용구 큰 (≤50자)
  static const TextStyle quoteLarge = TextStyle(
    fontFamily: AppFonts.quoteMedium,
    fontSize: AppFontSize.lg,
    height: AppLineHeight.spacious,
    color: AppColors.primary900,
  );

  /// 인용구 중 (200자 기준)
  static const TextStyle quoteBase = TextStyle(
    fontFamily: AppFonts.quote,
    fontSize: AppFontSize.base,
    height: AppLineHeight.loose,
    color: AppColors.primary900,
  );

  /// 인용구 소 (500자+)
  static const TextStyle quoteSmall = TextStyle(
    fontFamily: AppFonts.quote,
    fontSize: AppFontSize.xs,
    height: AppLineHeight.relaxed,
    color: AppColors.primary900,
  );

  /// T5 시(詩) 배치
  static const TextStyle quotePoetry = TextStyle(
    fontFamily: AppFonts.quote,
    fontSize: AppFontSize.lg,
    height: AppLineHeight.poetry,
    letterSpacing: AppLetterSpacing.wide,
    color: AppColors.primary900,
  );

  // ── 빌더: 인용구 길이 → TextStyle ─────────────────
  /// 글자 수에 따라 폰트 크기/행간을 자동 조절한 인용구 스타일을 만든다.
  /// 색은 [color]가 주어지면 사용, 없으면 토큰 기본값.
  static TextStyle quoteForLength(int charCount, {Color? color}) {
    final size = getQuoteFontSize(charCount);
    return TextStyle(
      fontFamily: AppFonts.quote,
      fontSize: size,
      height: getQuoteLineHeight(size),
      color: color ?? AppColors.primary900,
    );
  }
}

/// Material `TextTheme`에 주입할 매핑.
const TextTheme appTextTheme = TextTheme(
  displayLarge: AppTextStyles.displayLarge,
  displayMedium: AppTextStyles.displayMedium,
  headlineLarge: AppTextStyles.headlineLarge,
  headlineMedium: AppTextStyles.headlineMedium,
  headlineSmall: AppTextStyles.headlineSmall,
  titleLarge: AppTextStyles.titleLarge,
  titleMedium: AppTextStyles.titleMedium,
  titleSmall: AppTextStyles.titleSmall,
  bodyLarge: AppTextStyles.bodyLarge,
  bodyMedium: AppTextStyles.bodyMedium,
  bodySmall: AppTextStyles.bodySmall,
  labelLarge: AppTextStyles.labelLarge,
  labelMedium: AppTextStyles.labelMedium,
  labelSmall: AppTextStyles.labelSmall,
);
