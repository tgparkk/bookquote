// 책귀 — 텍스트 스타일
//
// Material `TextTheme` 슬롯에 매핑되는 UI 스타일과,
// 카드 안의 인용구 본문에 쓰이는 별도 스타일을 한곳에 모은다.
//
// 폰트는 family 한 개에 weight axis(NotoSerifKR 가변) 또는 weight별 정적 파일
// (Pretendard)을 묶어 pubspec.yaml에 등록했다. TextStyle은 항상
// `fontFamily: AppFonts.{ui|quote}` + `fontWeight: FontWeight.wXXX` 조합을 쓴다.
//
// V1 미번들 weight (사용 시 시스템 폰트로 폴백):
//   - Pretendard w700 (Bold)  → displayLarge는 w600(SemiBold)으로 대체
//   - Libre Baskerville 전체    → V1엔 영문 보조 스타일 정의 안 함

import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTextStyles {
  // ── Display / Headline (UI) ──────────────────
  static const TextStyle displayLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.xxl,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.tight,
    color: AppColors.primary900,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.xl,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.tight,
    color: AppColors.primary900,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.lg,
    height: AppLineHeight.tight,
    color: AppColors.primary900,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.md,
    height: AppLineHeight.normal,
    color: AppColors.primary900,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
    color: AppColors.primary900,
  );

  // ── Title ────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.md,
    height: AppLineHeight.normal,
    color: AppColors.primary900,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
    color: AppColors.primary800,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.normal,
    color: AppColors.primary700,
  );

  // ── Body ─────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
    color: AppColors.primary800,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.normal,
    color: AppColors.primary700,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.xs,
    height: AppLineHeight.normal,
    color: AppColors.primary600,
  );

  // ── Label ────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wide,
    color: AppColors.primary700,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.xs,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wide,
    color: AppColors.primary600,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.xxs,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wider,
    color: AppColors.primary500,
  );

  // ── Quote (카드 본문 전용 — TextTheme 외) ────────
  /// 인용구 큰 (≤50자)
  static const TextStyle quoteLarge = TextStyle(
    fontFamily: AppFonts.quote,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.lg,
    height: AppLineHeight.spacious,
    color: AppColors.primary900,
  );

  /// 인용구 중 (200자 기준)
  static const TextStyle quoteBase = TextStyle(
    fontFamily: AppFonts.quote,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.base,
    height: AppLineHeight.loose,
    color: AppColors.primary900,
  );

  /// 인용구 소 (500자+)
  static const TextStyle quoteSmall = TextStyle(
    fontFamily: AppFonts.quote,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.xs,
    height: AppLineHeight.relaxed,
    color: AppColors.primary900,
  );

  /// T5 시(詩) 배치
  static const TextStyle quotePoetry = TextStyle(
    fontFamily: AppFonts.quote,
    fontWeight: FontWeight.w400,
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
      fontWeight: FontWeight.w400,
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
