// 책귀 — 텍스트 스타일
//
// Material `TextTheme` 슬롯에 매핑되는 UI 스타일과,
// 카드 안의 인용구 본문에 쓰이는 별도 스타일을 한곳에 모은다.
//
// 색 정책(DM-C 다크모드): **UI 스타일(display~label)은 색을 박지 않는다.**
// 라이트/다크 색은 [appTextThemeLight]/[appTextThemeDark]가 슬롯별로 입혀 Material
// TextTheme로 주입하고, `style: AppTextStyles.X`처럼 직접 쓰는 경우엔 ListTile/테마의
// onSurface를 상속해 다크에서도 보이게 한다(색을 박으면 다크에서 검정으로 묻힌다).
// 카드 본문(quote*)만 색을 고정한다 — 카드 PNG는 수신자 테마와 무관해야 하므로.
//
// 폰트는 family 한 개에 weight axis(NotoSerifKR 가변) 또는 weight별 정적 파일
// (Pretendard)을 묶어 pubspec.yaml에 등록했다. TextStyle은 항상
// `fontFamily: AppFonts.{ui|quote}` + `fontWeight: FontWeight.wXXX` 조합을 쓴다.

import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class AppTextStyles {
  // ── Display / Headline (UI) — 색은 TextTheme이 입힌다 ──
  static const TextStyle displayLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.xxl,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.tight,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.xl,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.tight,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.lg,
    height: AppLineHeight.tight,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.md,
    height: AppLineHeight.normal,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
  );

  // ── Title ────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w600,
    fontSize: AppFontSize.md,
    height: AppLineHeight.normal,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.normal,
  );

  // ── Body ─────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.base,
    height: AppLineHeight.normal,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.normal,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.xs,
    height: AppLineHeight.normal,
  );

  // ── Label ────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.sm,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wide,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w500,
    fontSize: AppFontSize.xs,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wide,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.ui,
    fontWeight: FontWeight.w400,
    fontSize: AppFontSize.xxs,
    height: AppLineHeight.tight,
    letterSpacing: AppLetterSpacing.wider,
  );

  // ── Quote (카드 본문 전용 — 색 고정, 테마 무관) ────────
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

// ─────────────────────────────────────────────
// Material TextTheme — 색 없는 UI 스타일에 슬롯별 색을 입힌다.
// 라이트는 기존 위계(primary900~500) 유지, 다크는 onSurface 스케일로 반전(시인성).
// ─────────────────────────────────────────────

/// 라이트 TextTheme. AppTheme.light()에서 사용.
final TextTheme appTextThemeLight = TextTheme(
  displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.primary900),
  displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.primary900),
  headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary900),
  headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary900),
  headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary900),
  titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.primary900),
  titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.primary800),
  titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.primary700),
  bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary800),
  bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary700),
  bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.primary600),
  labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.primary700),
  labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.primary600),
  labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.primary500),
);

/// 다크 TextTheme. AppTheme.dark()에서 사용 — 메인 텍스트 secondary200,
/// 보조 secondary500, 최약 primary300 (대비 보강 반영).
final TextTheme appTextThemeDark = TextTheme(
  displayLarge: AppTextStyles.displayLarge.copyWith(color: AppColors.secondary200),
  displayMedium: AppTextStyles.displayMedium.copyWith(color: AppColors.secondary200),
  headlineLarge: AppTextStyles.headlineLarge.copyWith(color: AppColors.secondary200),
  headlineMedium: AppTextStyles.headlineMedium.copyWith(color: AppColors.secondary200),
  headlineSmall: AppTextStyles.headlineSmall.copyWith(color: AppColors.secondary200),
  titleLarge: AppTextStyles.titleLarge.copyWith(color: AppColors.secondary200),
  titleMedium: AppTextStyles.titleMedium.copyWith(color: AppColors.secondary200),
  titleSmall: AppTextStyles.titleSmall.copyWith(color: AppColors.secondary500),
  bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.secondary200),
  bodyMedium: AppTextStyles.bodyMedium.copyWith(color: AppColors.secondary500),
  bodySmall: AppTextStyles.bodySmall.copyWith(color: AppColors.secondary500),
  labelLarge: AppTextStyles.labelLarge.copyWith(color: AppColors.secondary500),
  labelMedium: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary500),
  labelSmall: AppTextStyles.labelSmall.copyWith(color: AppColors.primary300),
);
