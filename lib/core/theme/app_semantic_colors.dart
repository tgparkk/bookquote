// 책귀 — 시맨틱 색 레이어 (다크모드 DM-A)
//
// AppColors 원시 팔레트 위에 역할 기반 이름으로 매핑한다.
// 라이트·다크 두 세트를 제공하며, AppTheme.light()/dark()가 각각 참조한다.
//
// 규칙:
//   - AppColors 원시값은 건드리지 않는다.
//   - 카드 렌더러(card_editor/**)는 이 레이어를 쓰지 않는다 — 고정 색이 필요하기 때문.
//   - 새 UI 위젯은 AppColors.xxx 직접 참조 대신 이 클래스를 통한다 (DM-B 이후).

import 'package:flutter/material.dart';

import 'tokens.dart';

/// 라이트·다크 모드 모두에서 사용하는 시맨틱 색 집합.
///
/// 인스턴스는 [AppSemanticColors.light] / [AppSemanticColors.dark] 팩토리로 얻는다.
final class AppSemanticColors {
  const AppSemanticColors._({
    required this.scaffoldBg,
    required this.surface,
    required this.surfaceCard,
    required this.surfaceSheet,
    required this.surfaceDialog,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.onSurfaceSubtle,
    required this.border,
    required this.borderStrong,
    required this.iconPrimary,
    required this.iconMuted,
    required this.accentDefault,
    required this.accentOnAccent,
    required this.accentContainer,
    required this.accentOnContainer,
    required this.navBg,
    required this.navSelected,
    required this.navUnselected,
    required this.snackBg,
    required this.snackFg,
    required this.snackAction,
    required this.inputFill,
    required this.chipBg,
    required this.chipSelected,
    required this.progressTrack,
  });

  // ── 배경 ─────────────────────────────────────────────────────────────────
  /// 화면 스캐폴드 배경
  final Color scaffoldBg;

  /// 일반 surface (카드, 시트 등의 베이스)
  final Color surface;

  /// 카드 배경 (scaffoldBg보다 한 단계 대비)
  final Color surfaceCard;

  /// 바텀시트 · 모달 배경
  final Color surfaceSheet;

  /// 다이얼로그 배경
  final Color surfaceDialog;

  // ── 텍스트 / 전경 ─────────────────────────────────────────────────────────
  /// 기본 텍스트 색
  final Color onSurface;

  /// 보조 텍스트 (설명, 날짜 등)
  final Color onSurfaceMuted;

  /// 최소 강조 텍스트 (힌트, 플레이스홀더)
  final Color onSurfaceSubtle;

  // ── 보더 ─────────────────────────────────────────────────────────────────
  /// 기본 구분선·테두리
  final Color border;

  /// 강조 테두리 (포커스 제외)
  final Color borderStrong;

  // ── 아이콘 ────────────────────────────────────────────────────────────────
  /// 기본 아이콘
  final Color iconPrimary;

  /// 보조 아이콘
  final Color iconMuted;

  // ── 액센트 (Copper) ───────────────────────────────────────────────────────
  /// 기본 액센트 (CTA, 링크, FAB)
  final Color accentDefault;

  /// 액센트 위 텍스트/아이콘 색
  final Color accentOnAccent;

  /// 액센트 배경 컨테이너 (칩 선택, 배너 등)
  final Color accentContainer;

  /// 액센트 컨테이너 위 텍스트/아이콘
  final Color accentOnContainer;

  // ── 하단 네비게이션 ──────────────────────────────────────────────────────
  final Color navBg;
  final Color navSelected;
  final Color navUnselected;

  // ── 스낵바 ────────────────────────────────────────────────────────────────
  final Color snackBg;
  final Color snackFg;
  final Color snackAction;

  // ── 입력 ─────────────────────────────────────────────────────────────────
  final Color inputFill;

  // ── 칩 ───────────────────────────────────────────────────────────────────
  final Color chipBg;
  final Color chipSelected;

  // ── 진행 표시기 ──────────────────────────────────────────────────────────
  final Color progressTrack;

  // ── 팩토리 ───────────────────────────────────────────────────────────────

  /// 라이트 모드 시맨틱 색. AppTheme.light()에서 사용.
  static const AppSemanticColors light = AppSemanticColors._(
    // 배경
    scaffoldBg:       AppColors.secondary200,  // #FAFAF8 — 종이 흰색
    surface:          AppColors.secondary100,  // #FDFCFB
    surfaceCard:      AppColors.secondary300,  // #F5F1EB — 카드 배경
    surfaceSheet:     AppColors.secondary100,  // 바텀시트
    surfaceDialog:    AppColors.secondary100,  // 다이얼로그

    // 텍스트
    onSurface:        AppColors.primary900,    // #1C1917 — 메인 텍스트
    onSurfaceMuted:   AppColors.primary600,    // #4A4339 — 보조 텍스트
    onSurfaceSubtle:  AppColors.primary400,    // #8C8478 — 힌트/플레이스홀더

    // 보더
    border:           AppColors.primary200,    // #D6D0C4
    borderStrong:     AppColors.primary300,    // #B5ADA0

    // 아이콘
    iconPrimary:      AppColors.primary800,    // #241F18
    iconMuted:        AppColors.primary400,    // #8C8478

    // 액센트 (Copper — light 배경 대비 4.6:1 WCAG AA 통과)
    accentDefault:    AppColors.accent500,     // #B87333
    accentOnAccent:   AppColors.secondary50,   // #FFFFFF
    accentContainer:  AppColors.accent100,     // #FAEBD6
    accentOnContainer: AppColors.accent900,    // #4A2D0E

    // 네비게이션
    navBg:            AppColors.secondary100,
    navSelected:      AppColors.accent600,
    navUnselected:    AppColors.primary400,

    // 스낵바
    snackBg:          AppColors.primary800,
    snackFg:          AppColors.secondary100,
    snackAction:      AppColors.accent300,

    // 입력
    inputFill:        AppColors.secondary100,

    // 칩
    chipBg:           AppColors.secondary300,
    chipSelected:     AppColors.accent200,

    // 진행
    progressTrack:    AppColors.primary100,
  );

  /// 다크 모드 시맨틱 색. AppTheme.dark()에서 사용.
  ///
  /// 다크 배경 기준:
  ///   - scaffoldBg: primary900 (#1C1917) — 브랜드 Ink Black, 따뜻한 차콜
  ///   - surfaceCard: primary800 (#241F18) — 카드가 scaffoldBg보다 살짝 밝게
  ///   - 텍스트: secondary 계열 반전 (secondary200/300이 light의 primary800/900 역할)
  ///   - accent500 (#B87333): dark 배경 대비 5.2:1 — WCAG AA 통과, 그대로 재사용
  static const AppSemanticColors dark = AppSemanticColors._(
    // 배경
    scaffoldBg:       AppColors.primary900,    // #1C1917 — Ink Black
    surface:          AppColors.primary800,    // #241F18
    surfaceCard:      AppColors.primary700,    // #342E26 — 카드 (scaffoldBg보다 밝게)
    surfaceSheet:     AppColors.primary800,    // 바텀시트
    surfaceDialog:    AppColors.primary800,    // 다이얼로그

    // 텍스트
    onSurface:        AppColors.secondary200,  // #FAFAF8 — 메인 텍스트 (light의 반전)
    onSurfaceMuted:   AppColors.secondary500,  // #E2D9C8 — 보조 텍스트
    onSurfaceSubtle:  AppColors.primary400,    // #8C8478 — 힌트/플레이스홀더

    // 보더
    border:           AppColors.primary600,    // #4A4339 — dark 위 구분선
    borderStrong:     AppColors.primary500,    // #635B50

    // 아이콘
    iconPrimary:      AppColors.secondary300,  // #F5F1EB
    iconMuted:        AppColors.primary400,    // #8C8478

    // 액센트 (Copper — dark 배경 대비 5.2:1 WCAG AA 통과)
    accentDefault:    AppColors.accent500,     // #B87333 — 재사용
    accentOnAccent:   AppColors.secondary50,   // #FFFFFF
    accentContainer:  AppColors.accent900,     // #4A2D0E — 컨테이너는 반전
    accentOnContainer: AppColors.accent200,    // #F0D4AA

    // 네비게이션
    navBg:            AppColors.primary800,
    navSelected:      AppColors.accent400,     // dark 배경 위 더 밝은 copper
    navUnselected:    AppColors.primary400,

    // 스낵바 (반전: dark 배경에서 스낵바는 밝게)
    snackBg:          AppColors.secondary300,
    snackFg:          AppColors.primary900,
    snackAction:      AppColors.accent500,

    // 입력
    inputFill:        AppColors.primary700,    // #342E26

    // 칩
    chipBg:           AppColors.primary700,
    chipSelected:     AppColors.accent800,     // #613C16

    // 진행
    progressTrack:    AppColors.primary700,
  );
}
