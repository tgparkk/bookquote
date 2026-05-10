// 책귀 — Material 3 ThemeData
//
// 디자인 토큰(`tokens.dart`)과 텍스트 스타일(`app_text_styles.dart`)을
// Material 3 `ThemeData`로 묶는다. UI 화면은 모두 이 테마를 통해 색·타이포에
// 접근하고, 카드 렌더러만 토큰을 직접 참조한다.

import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = _lightColorScheme;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.secondary200,
      canvasColor: AppColors.secondary200,
      textTheme: appTextTheme,
      primaryTextTheme: appTextTheme,
      fontFamily: AppFonts.ui,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.secondary200,
        foregroundColor: AppColors.primary900,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.primary800, size: 22),
      ),

      cardTheme: CardThemeData(
        color: AppColors.secondary100,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent500,
          foregroundColor: AppColors.secondary50,
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
            color: AppColors.secondary50,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary800,
          side: const BorderSide(color: AppColors.primary300),
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
          foregroundColor: AppColors.primary800,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondary100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        hintStyle: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.primary400,
        ),
        labelStyle: AppTextStyles.labelLarge,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.primary200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.accent500, width: 1.5),
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

      dividerTheme: const DividerThemeData(
        color: AppColors.primary200,
        thickness: 1,
        space: 1,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.secondary100,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: AppColors.secondary100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.secondary100,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTextStyles.headlineMedium,
        contentTextStyle: AppTextStyles.bodyLarge,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primary800,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.secondary100,
        ),
        actionTextColor: AppColors.accent300,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondary100,
        selectedItemColor: AppColors.accent600,
        unselectedItemColor: AppColors.primary400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary300,
        selectedColor: AppColors.accent200,
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

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent500,
        linearTrackColor: AppColors.primary100,
        circularTrackColor: AppColors.primary100,
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
