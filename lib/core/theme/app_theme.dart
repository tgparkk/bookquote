// 책귀 — Material 3 ThemeData
//
// 디자인 토큰(`tokens.dart`)과 텍스트 스타일(`app_text_styles.dart`)을
// Material 3 `ThemeData`로 묶는다. UI 화면은 모두 이 테마를 통해 색·타이포에
// 접근하고, 카드 렌더러만 토큰을 직접 참조한다.
//
// DM-A (다크모드 토대):
//   - AppTheme.dark()가 추가됐다. 구조는 light()와 동일하며 dark ColorScheme +
//     AppSemanticColors.dark를 사용한다.
//   - 카드 렌더러(card_editor/**)는 이 테마를 쓰지 않는다 — 변경 없음.

import 'package:flutter/material.dart';

import 'app_semantic_colors.dart';
import 'app_text_styles.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = _lightColorScheme;
    const s = AppSemanticColors.light;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: s.scaffoldBg,
      canvasColor: s.scaffoldBg,
      textTheme: appTextThemeLight,
      primaryTextTheme: appTextThemeLight,
      fontFamily: AppFonts.ui,

      appBarTheme: AppBarTheme(
        backgroundColor: s.scaffoldBg,
        foregroundColor: s.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: IconThemeData(color: s.iconPrimary, size: 22),
      ),

      // 카드 배경은 화면 배경(secondary200 #FAFAF8)보다 *한 톤 어둡게* 둔다.
      // 라이트 테마라 화면이 거의 흰색 — 카드를 더 밝게 만들 여지가 없어,
      // 어둡게 해서 경계 대비를 확보한다(2026-05-21 디자이너 매니저 회의 결정).
      // 그림자(AppShadows.card)·테두리는 안 씀 — 그림자는 V1.5 다크모드 때.
      cardTheme: CardThemeData(
        color: s.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.accentDefault,
          foregroundColor: s.accentOnAccent,
          disabledBackgroundColor: AppColors.primary200,
          disabledForegroundColor: AppColors.primary500,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: s.accentOnAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.iconPrimary,
          side: BorderSide(color: s.borderStrong),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent600,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: AppSpacing.s2,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: AppColors.accent600,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: s.iconPrimary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: s.onSurfaceSubtle,
        ),
        labelStyle: AppTextStyles.labelLarge,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: s.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: s.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: s.accentDefault, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.semanticError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.semanticError, width: 1.5),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: s.border,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surfaceSheet,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: s.surfaceSheet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceDialog,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTextStyles.headlineMedium,
        contentTextStyle: AppTextStyles.bodyLarge,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.snackBg,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: s.snackFg,
        ),
        actionTextColor: s.snackAction,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: s.navBg,
        selectedItemColor: s.navSelected,
        unselectedItemColor: s.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: s.chipBg,
        selectedColor: s.chipSelected,
        disabledColor: AppColors.primary100,
        labelStyle: AppTextStyles.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        side: BorderSide.none,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.accentDefault,
        linearTrackColor: s.progressTrack,
        circularTrackColor: s.progressTrack,
      ),

      splashFactory: InkRipple.splashFactory,
    );
  }

  static ThemeData dark() {
    final colorScheme = _darkColorScheme;
    const s = AppSemanticColors.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: s.scaffoldBg,
      canvasColor: s.scaffoldBg,
      textTheme: appTextThemeDark,
      primaryTextTheme: appTextThemeDark,
      fontFamily: AppFonts.ui,

      appBarTheme: AppBarTheme(
        backgroundColor: s.scaffoldBg,
        foregroundColor: s.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(
          color: s.onSurface,
        ),
        iconTheme: IconThemeData(color: s.iconPrimary, size: 22),
      ),

      // 다크 카드: scaffoldBg(primary900 #1C1917)보다 한 단계 밝은 primary700로
      // 경계 대비를 확보한다. 라이트와 동일 로직의 반전.
      cardTheme: CardThemeData(
        color: s.surfaceCard,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: s.accentDefault,
          foregroundColor: s.accentOnAccent,
          disabledBackgroundColor: AppColors.primary700,
          disabledForegroundColor: AppColors.primary500,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: s.accentOnAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.onSurface,
          side: BorderSide(color: s.borderStrong),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s6,
            vertical: AppSpacing.s3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: s.onSurface,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.accentDefault,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s3,
            vertical: AppSpacing.s2,
          ),
          textStyle: AppTextStyles.labelLarge.copyWith(
            color: s.accentDefault,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: s.iconPrimary,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: s.onSurfaceSubtle,
        ),
        labelStyle: AppTextStyles.labelLarge.copyWith(
          color: s.onSurfaceMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: s.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: s.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: s.accentDefault, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.semanticError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.semanticError, width: 1.5),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: s.border,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surfaceSheet,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: s.surfaceSheet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: s.surfaceDialog,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTextStyles.headlineMedium.copyWith(
          color: s.onSurface,
        ),
        contentTextStyle: AppTextStyles.bodyLarge.copyWith(
          color: s.onSurfaceMuted,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.snackBg,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: s.snackFg,
        ),
        actionTextColor: s.snackAction,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: s.navBg,
        selectedItemColor: s.navSelected,
        unselectedItemColor: s.navUnselected,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: s.chipBg,
        selectedColor: s.chipSelected,
        disabledColor: AppColors.primary700,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          color: s.onSurfaceMuted,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s1,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        side: BorderSide.none,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.accentDefault,
        linearTrackColor: s.progressTrack,
        circularTrackColor: s.progressTrack,
      ),

      splashFactory: InkRipple.splashFactory,
    );
  }
}

const ColorScheme _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.accent500,
  onPrimary: AppColors.secondary50,
  primaryContainer: AppColors.accent100,
  onPrimaryContainer: AppColors.accent900,
  secondary: AppColors.primary700,
  onSecondary: AppColors.secondary50,
  secondaryContainer: AppColors.secondary300,
  onSecondaryContainer: AppColors.primary900,
  tertiary: AppColors.secondary800,
  onTertiary: AppColors.secondary50,
  tertiaryContainer: AppColors.secondary500,
  onTertiaryContainer: AppColors.primary900,
  error: AppColors.semanticError,
  onError: AppColors.secondary50,
  errorContainer: AppColors.semanticErrorLight,
  onErrorContainer: AppColors.semanticError,
  surface: AppColors.secondary200,
  onSurface: AppColors.primary900,
  onSurfaceVariant: AppColors.primary600,
  surfaceContainerLowest: AppColors.secondary50,
  surfaceContainerLow: AppColors.secondary100,
  surfaceContainer: AppColors.secondary200,
  surfaceContainerHigh: AppColors.secondary300,
  surfaceContainerHighest: AppColors.secondary400,
  outline: AppColors.primary300,
  outlineVariant: AppColors.primary200,
  shadow: AppColors.primary900,
  scrim: AppColors.primary900,
  inverseSurface: AppColors.primary900,
  onInverseSurface: AppColors.secondary100,
  inversePrimary: AppColors.accent300,
);

// 다크 ColorScheme — DM-A
// primary900(#1C1917) 기반 차콜 배경, secondary 계열 텍스트 반전.
// accent500(Copper #B87333)은 dark 배경 대비 5.2:1 — 그대로 재사용.
const ColorScheme _darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: AppColors.accent500,        // Copper — dark 위 5.2:1
  onPrimary: AppColors.secondary50,
  primaryContainer: AppColors.accent900,
  onPrimaryContainer: AppColors.accent200,
  secondary: AppColors.secondary400,   // 따뜻한 크림
  onSecondary: AppColors.primary900,
  secondaryContainer: AppColors.primary700,
  onSecondaryContainer: AppColors.secondary300,
  tertiary: AppColors.secondary600,
  onTertiary: AppColors.primary900,
  tertiaryContainer: AppColors.primary600,
  onTertiaryContainer: AppColors.secondary300,
  error: AppColors.semanticError,
  onError: AppColors.secondary50,
  errorContainer: Color(0xFF4D1A17),   // semanticError 다크 컨테이너
  onErrorContainer: Color(0xFFFFB4AB),
  surface: AppColors.primary900,       // #1C1917 — Ink Black
  onSurface: AppColors.secondary200,   // #FAFAF8 — 메인 텍스트
  onSurfaceVariant: AppColors.secondary500,
  surfaceContainerLowest: AppColors.primary900,
  surfaceContainerLow: AppColors.primary800,
  surfaceContainer: AppColors.primary700,
  surfaceContainerHigh: AppColors.primary600,
  surfaceContainerHighest: AppColors.primary500,
  outline: AppColors.primary500,
  outlineVariant: AppColors.primary600,
  shadow: AppColors.primary900,
  scrim: AppColors.primary900,
  inverseSurface: AppColors.secondary200,
  onInverseSurface: AppColors.primary900,
  inversePrimary: AppColors.accent700,
);
