// ============================================================
// 책귀 디자인 토큰 — Flutter/Dart
// ============================================================
// 원본: C:\GIT\quotes-app-discovery\design\tokens.dart (2026-05-09 디자인 세션 산출물)
// 이식일: 2026-05-09
//
// 사용 예:
//   import 'package:bookquote/core/theme/tokens.dart';
//   Container(color: AppColors.secondary200, ...)
//   Text('...', style: TextStyle(fontSize: AppFontSize.base))
// ============================================================

import 'package:flutter/painting.dart';

// ─────────────────────────────────────────────
// 색 팔레트
// ─────────────────────────────────────────────

/// Primary — Ink (따뜻한 검정)
/// 책의 활자, 오래된 잉크. 900이 브랜드 잉크블랙.
abstract final class AppColors {
  // ── Primary (Ink) ──────────────────────────
  static const Color primary50  = Color(0xFFFAF8F5);
  static const Color primary100 = Color(0xFFF0EDE6);
  static const Color primary200 = Color(0xFFD6D0C4);
  static const Color primary300 = Color(0xFFB5ADA0);
  static const Color primary400 = Color(0xFF8C8478);
  static const Color primary500 = Color(0xFF635B50);
  static const Color primary600 = Color(0xFF4A4339);
  static const Color primary700 = Color(0xFF342E26);
  static const Color primary800 = Color(0xFF241F18);
  /// 브랜드 Ink Black — 모노 템플릿 배경, 최고 강조
  static const Color primary900 = Color(0xFF1C1917);

  // ── Secondary (Paper) ──────────────────────
  /// 종이의 흰색. 200이 미니멀 카드 배경, 400이 따뜻 카드 배경.
  static const Color secondary50  = Color(0xFFFFFFFF);
  static const Color secondary100 = Color(0xFFFDFCFB);
  /// T1 미니멀 카드 배경
  static const Color secondary200 = Color(0xFFFAFAF8);
  static const Color secondary300 = Color(0xFFF5F1EB);
  /// T2 따뜻 배경 베이스
  static const Color secondary400 = Color(0xFFEDE5D8);
  static const Color secondary500 = Color(0xFFE2D9C8);
  static const Color secondary600 = Color(0xFFD4C9B3);
  static const Color secondary700 = Color(0xFFC2B49A);
  static const Color secondary800 = Color(0xFFA89880);
  static const Color secondary900 = Color(0xFF8B7D65);

  // ── Accent (Copper) ────────────────────────
  /// 따뜻함과 금속성 정밀함. 500이 기본 브랜드 액센트.
  /// #FAFAF8 배경 위 대비비: 4.6:1 (WCAG AA 통과)
  /// #1C1917 배경 위 대비비: 5.2:1 (WCAG AA 통과)
  static const Color accent50  = Color(0xFFFDF6ED);
  static const Color accent100 = Color(0xFFFAEBD6);
  static const Color accent200 = Color(0xFFF0D4AA);
  static const Color accent300 = Color(0xFFE0B87A);
  static const Color accent400 = Color(0xFFCC9A4E);
  /// 브랜드 Copper — CTA, 링크, 강조
  static const Color accent500 = Color(0xFFB87333);
  static const Color accent600 = Color(0xFF9A5F28);
  static const Color accent700 = Color(0xFF7D4D1E);
  static const Color accent800 = Color(0xFF613C16);
  static const Color accent900 = Color(0xFF4A2D0E);

  // ── Neutral (순수 회색) ────────────────────
  /// 온도 없는 회색. UI 구조 요소용.
  static const Color neutral50  = Color(0xFFF9F9F9);
  static const Color neutral100 = Color(0xFFF3F3F3);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral300 = Color(0xFFD4D4D4);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral700 = Color(0xFF404040);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral900 = Color(0xFF171717);

  // ── Semantic ───────────────────────────────
  /// 상태 표현용 시맨틱 색
  static const Color semanticSuccess      = Color(0xFF4A7C59);
  static const Color semanticSuccessLight = Color(0xFFEAF2EC);
  static const Color semanticError        = Color(0xFFC0392B);
  static const Color semanticErrorLight   = Color(0xFFFDECEA);
  static const Color semanticWarning      = Color(0xFFC87F0A);
  static const Color semanticWarningLight = Color(0xFFFEF3E2);
  static const Color semanticInfo         = Color(0xFF2563EB);
  static const Color semanticInfoLight    = Color(0xFFEFF6FF);

  // ── 템플릿 고정 배경 ─────────────────────────
  /// T3 모노 배경 — 차콜 (순검정보다 따뜻함)
  static const Color monoBackground = Color(0xFF0F0F0F);
}

// ─────────────────────────────────────────────
// 폰트 패밀리
// ─────────────────────────────────────────────

/// 폰트 패밀리 이름 상수.
///
/// pubspec.yaml의 fonts 섹션과 1:1 매칭. 굵기는 family에 박지 않고
/// `TextStyle.fontWeight`로 지정한다 — NotoSerifKR은 가변 폰트 단일 파일,
/// Pretendard는 weight별 정적 파일 3종이 family 하나에 묶여 있다.
///
/// V1 번들 weight:
/// - NotoSerifKR: w400 / w500 / w700 (가변 axis로 보간)
/// - Pretendard: w400 / w500 / w600 (정적 파일)
/// - Libre Baskerville: 보류 (V1 사용 경로 없음)
abstract final class AppFonts {
  /// Noto Serif KR — 인용구 본문. 라이선스: OFL.
  static const String quote = 'NotoSerifKR';

  /// Pretendard — UI 전반. 라이선스: OFL.
  static const String ui = 'Pretendard';
}

// ─────────────────────────────────────────────
// 타입 스케일
// ─────────────────────────────────────────────

/// 폰트 크기 토큰 (논리 픽셀 기준)
abstract final class AppFontSize {
  /// 워터마크, 법적 표기
  static const double xxs  = 9.0;
  /// 인용구 최소 (500자+), 출판사·ISBN
  static const double xs   = 11.0;
  /// 보조 레이블, 저자명
  static const double sm   = 13.0;
  /// 인용구 중간 (200자 기준), 본문 UI
  static const double base = 15.0;
  /// 책 제목 (카드 내), 섹션 헤더
  static const double md   = 17.0;
  /// 인용구 큰 (50자 이하), 화면 제목
  static const double lg   = 22.0;
  /// T5 타이포 메인 텍스트
  static const double xl   = 28.0;
  /// T5 타이포 임팩트 텍스트
  static const double xxl  = 36.0;
}

// ─────────────────────────────────────────────
// 행간 (Line Height)
// ─────────────────────────────────────────────

/// Flutter TextStyle.height = fontSize * lineHeight 배율
abstract final class AppLineHeight {
  /// 제목, 한 줄 레이블
  static const double tight    = 1.3;
  /// UI 본문
  static const double normal   = 1.5;
  /// 인용구 소 (11px)
  static const double relaxed  = 1.6;
  /// 인용구 중 (15px)
  static const double loose    = 1.7;
  /// 인용구 대 (22px)
  static const double spacious = 1.8;
  /// T5 타이포 시(詩) 배치
  static const double poetry   = 2.2;
}

// ─────────────────────────────────────────────
// 자간 (Letter Spacing)
// ─────────────────────────────────────────────

/// Flutter TextStyle.letterSpacing — 픽셀 단위 (em 아님 주의)
/// em 기반 값을 사용할 경우: letterSpacing = em값 * fontSize
abstract final class AppLetterSpacing {
  /// 큰 제목, 임팩트 텍스트 (-0.02em 기준)
  static const double tight  = -0.02;
  /// 기본
  static const double normal = 0.0;
  /// 저자명, 작은 레이블 (0.05em 기준)
  static const double wide   = 0.05;
  /// 워터마크, T3 모노 캡션 (0.1em 기준)
  static const double wider  = 0.1;
}

// ─────────────────────────────────────────────
// 여백 시스템 (4px 기반)
// ─────────────────────────────────────────────

/// 4px 기반 그리드. 모든 여백은 이 배수.
abstract final class AppSpacing {
  static const double s0  = 0.0;
  /// 아이콘 내부 여백
  static const double s1  = 4.0;
  /// 인라인 요소 간격
  static const double s2  = 8.0;
  /// 컴팩트 레이블 패딩
  static const double s3  = 12.0;
  /// 카드 bookArea 패딩
  static const double s4  = 16.0;
  /// 섹션 간격
  static const double s6  = 24.0;
  /// 카드 quoteArea 패딩
  static const double s8  = 32.0;
  /// 템플릿 상하 패딩
  static const double s12 = 48.0;
  /// 큰 섹션 구분
  static const double s16 = 64.0;
}

// ─────────────────────────────────────────────
// 그림자 토큰
// ─────────────────────────────────────────────

/// Flutter BoxShadow 단일 모델 (iOS/Android 분기 없음)
/// Flutter 엔진이 플랫폼 관계없이 동일하게 렌더링함
abstract final class AppShadows {
  /// 카드 컴포넌트 그림자
  static const BoxShadow card = BoxShadow(
    color: Color(0x141C1917), // #1C1917 @ 8% opacity (0x14 = 20 ≈ 0.08*255)
    offset: Offset(0, 2),
    blurRadius: 8,
  );

  /// 바텀시트·모달 그림자
  static const BoxShadow modal = BoxShadow(
    color: Color(0x291C1917), // #1C1917 @ 16% opacity (0x29 = 41 ≈ 0.16*255)
    offset: Offset(0, 8),
    blurRadius: 24,
  );

  /// FAB·플로팅 버튼 그림자
  static const BoxShadow floating = BoxShadow(
    color: Color(0x1F1C1917), // #1C1917 @ 12% opacity (0x1F = 31 ≈ 0.12*255)
    offset: Offset(0, 4),
    blurRadius: 16,
  );
}

// ─────────────────────────────────────────────
// 둥근 모서리
// ─────────────────────────────────────────────

abstract final class AppRadius {
  /// 태그·뱃지
  static const double xs   = 2.0;
  /// 버튼·입력창
  static const double sm   = 4.0;
  /// 카드 내부 요소
  static const double md   = 8.0;
  /// 카드·시트
  static const double lg   = 12.0;
  /// 바텀시트·대형 카드
  static const double xl   = 16.0;
  /// 완전한 원·알약 모양
  static const double full = 9999.0;
}

// ─────────────────────────────────────────────
// 카드 출력 크기 상수
// ─────────────────────────────────────────────

/// 카드 비율별 픽셀 크기 (PNG 출력 기준)
abstract final class AppCardSize {
  /// 인스타 스토리 (9:16)
  static const Size story    = Size(1080, 1920);
  /// 인스타 피드 (1:1)
  static const Size feed     = Size(1080, 1080);
  /// 인스타 포스트 (4:5)
  static const Size post     = Size(1080, 1350);
}

/// 카드 비율 열거형
enum CardRatio {
  /// 9:16 — 인스타 스토리
  story,
  /// 1:1 — 인스타 피드
  feed,
  /// 4:5 — 인스타 포스트
  post;

  Size get size => switch (this) {
    CardRatio.story => AppCardSize.story,
    CardRatio.feed  => AppCardSize.feed,
    CardRatio.post  => AppCardSize.post,
  };

  String get label => switch (this) {
    CardRatio.story => '9:16',
    CardRatio.feed  => '1:1',
    CardRatio.post  => '4:5',
  };
}

// ─────────────────────────────────────────────
// 인용구 길이별 자동 폰트 크기 보간 함수
// ─────────────────────────────────────────────

/// 인용구 글자 수에 따라 폰트 크기를 자동으로 결정한다.
/// 세 기준점 선형 보간:
///   ≤50자  → 22px
///   200자  → 15px
///   ≥500자 → 11px
///
/// [charCount] - 인용구 글자 수 (공백 포함)
/// returns 권장 폰트 크기 (논리 픽셀, 소수점 가능 — round 해서 사용)
double getQuoteFontSize(int charCount) {
  if (charCount <= 50) return 22.0;
  if (charCount >= 500) return 11.0;
  if (charCount <= 200) {
    // 50 → 200자 구간: 22px → 15px 선형 보간
    return 22.0 - ((charCount - 50) / 150.0) * 7.0;
  } else {
    // 200 → 500자 구간: 15px → 11px 선형 보간
    return 15.0 - ((charCount - 200) / 300.0) * 4.0;
  }
}

/// 사용자가 [A−]/[A+]로 미세조정한 step을 반영한 최종 인용구 폰트 크기.
/// step 1당 2px 가감. 보간 범위 안에 clamp(9~36px). PR12-B.
double getEffectiveQuoteFontSize(int charCount, int fontStep) {
  final base = getQuoteFontSize(charCount);
  return (base + fontStep * 2).clamp(9.0, 36.0);
}

/// 인용구 폰트 크기에 따라 최적 행간을 반환한다.
/// Flutter TextStyle.height 값 (fontSize 배율)
///
/// [quoteFontSize] - getQuoteFontSize() 반환값
/// returns 행간 비율 (lineHeight multiplier)
double getQuoteLineHeight(double quoteFontSize) {
  // 11px→1.6, 22px→1.8 선형 보간
  return 1.6 + ((quoteFontSize - 11.0) / (22.0 - 11.0)) * 0.2;
}

// ─────────────────────────────────────────────
// 워터마크 설정
// ─────────────────────────────────────────────

/// 워터마크 모드 설정
abstract final class AppWatermark {
  /// 기본 모드: 거의 안 보임
  static const WatermarkConfig minimal = WatermarkConfig(
    text: '책귀',
    fontSize: AppFontSize.xxs,   // 9px
    opacity: 0.30,
    position: WatermarkPosition.bottomRight,
    fontFamily: AppFonts.ui,
    showIcon: false,
  );

  /// 강조 모드 (사용자 토글 ON)
  static const WatermarkConfig branded = WatermarkConfig(
    text: '책귀',
    fontSize: AppFontSize.xs,    // 11px
    opacity: 0.70,
    position: WatermarkPosition.bottomCenter,
    fontFamily: AppFonts.ui,
    showIcon: true,
  );
}

enum WatermarkPosition { bottomRight, bottomCenter }

final class WatermarkConfig {
  const WatermarkConfig({
    required this.text,
    required this.fontSize,
    required this.opacity,
    required this.position,
    required this.fontFamily,
    required this.showIcon,
  });

  final String text;
  final double fontSize;
  final double opacity;
  final WatermarkPosition position;
  final String fontFamily;
  final bool showIcon;
}

// ─────────────────────────────────────────────
// 표지 팔레트 추출 결과 클래스
// ─────────────────────────────────────────────

/// 책 표지에서 추출한 5색 팔레트 + 텍스트 색 (WCAG AA 보장)
final class ExtractedPalette {
  const ExtractedPalette({
    required this.dominant,
    required this.secondary,
    required this.vibrant,
    required this.darkVibrant,
    required this.muted,
    required this.textOnBackground,
    required this.subtextOnBackground,
  });

  /// 표지 가장 지배적인 색 — 배경용
  final Color dominant;
  /// 두 번째 지배적인 색
  final Color secondary;
  /// 밝은 진동 색 (accent 역할)
  final Color vibrant;
  /// 어두운 진동 색
  final Color darkVibrant;
  /// 무채색 계열 뮤트
  final Color muted;
  /// WCAG AA를 보장하는 배경색 위 텍스트 색 (자동 계산)
  final Color textOnBackground;
  /// WCAG AA를 보장하는 배경색 위 보조 텍스트 색 (자동 계산)
  final Color subtextOnBackground;
}

// ─────────────────────────────────────────────
// 폴백 팔레트 (템플릿별 기본값)
// ─────────────────────────────────────────────

/// 팔레트 추출 실패 시 사용하는 폴백 팔레트 (템플릿 ID → ExtractedPalette)
const Map<String, ExtractedPalette> fallbackPalettes = {
  'minimal': ExtractedPalette(
    dominant:            AppColors.secondary200,
    secondary:           AppColors.secondary400,
    vibrant:             AppColors.accent500,
    darkVibrant:         AppColors.accent700,
    muted:               AppColors.primary300,
    textOnBackground:    AppColors.primary900,
    subtextOnBackground: AppColors.primary600,
  ),
  'warm': ExtractedPalette(
    dominant:            AppColors.secondary400,
    secondary:           AppColors.secondary600,
    vibrant:             AppColors.accent400,
    darkVibrant:         AppColors.accent600,
    muted:               AppColors.primary400,
    textOnBackground:    AppColors.primary800,
    subtextOnBackground: AppColors.primary600,
  ),
  'mono': ExtractedPalette(
    dominant:            AppColors.primary900,
    secondary:           AppColors.primary700,
    vibrant:             AppColors.accent400,
    darkVibrant:         AppColors.accent600,
    muted:               AppColors.primary500,
    textOnBackground:    AppColors.secondary200,
    subtextOnBackground: AppColors.primary300,
  ),
  'coverExtract': ExtractedPalette(
    dominant:            Color(0xFF3D2817),
    secondary:           Color(0xFF6B4423),
    vibrant:             Color(0xFFC9A876),
    darkVibrant:         Color(0xFF8B5A3C),
    muted:               Color(0xFFA08060),
    textOnBackground:    Color(0xFFF5EDD8),
    subtextOnBackground: Color(0xFFD4C0A0),
  ),
  'typography': ExtractedPalette(
    dominant:            AppColors.primary600,
    secondary:           AppColors.primary800,
    vibrant:             AppColors.accent300,
    darkVibrant:         AppColors.accent600,
    muted:               AppColors.primary400,
    textOnBackground:    AppColors.secondary200,
    subtextOnBackground: AppColors.primary500,
  ),
};
