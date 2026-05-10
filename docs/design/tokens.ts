/**
 * @deprecated 2026-05-09 — Flutter 스택으로 변경. tokens.dart를 사용하세요.
 * 이 파일은 참조용으로 보존됩니다.
 */

/**
 * 책귀 디자인 토큰
 * React Native + Expo 환경에서 직접 import 가능
 *
 * 사용 예:
 *   import { colors, fontSize, spacing } from '@/design/tokens';
 *   style={{ backgroundColor: colors.secondary[200], fontSize: fontSize.base }}
 */

// ─────────────────────────────────────────────
// 색 팔레트
// ─────────────────────────────────────────────

export const colors = {
  /**
   * Primary — Ink (따뜻한 검정)
   * 책의 활자, 오래된 잉크. 900이 브랜드 잉크블랙.
   */
  primary: {
    50: '#FAF8F5',
    100: '#F0EDE6',
    200: '#D6D0C4',
    300: '#B5ADA0',
    400: '#8C8478',
    500: '#635B50',
    600: '#4A4339',
    700: '#342E26',
    800: '#241F18',
    900: '#1C1917', // 브랜드 Ink Black — 모노 템플릿 배경, 최고 강조
  },

  /**
   * Secondary — Paper (따뜻한 흰색)
   * 종이의 흰색. 200이 미니멀 카드 배경, 400이 따뜻 카드 배경.
   */
  secondary: {
    50: '#FFFFFF',
    100: '#FDFCFB',
    200: '#FAFAF8', // T1 미니멀 카드 배경
    300: '#F5F1EB',
    400: '#EDE5D8', // T2 따뜻 배경 베이스
    500: '#E2D9C8',
    600: '#D4C9B3',
    700: '#C2B49A',
    800: '#A89880',
    900: '#8B7D65',
  },

  /**
   * Accent — Copper (구리)
   * 따뜻함과 금속성 정밀함. 500이 기본 브랜드 액센트.
   * #FAFAF8 배경 위 대비비: 4.6:1 (WCAG AA 통과)
   * #1C1917 배경 위 대비비: 5.2:1 (WCAG AA 통과)
   */
  accent: {
    50: '#FDF6ED',
    100: '#FAEBD6',
    200: '#F0D4AA',
    300: '#E0B87A',
    400: '#CC9A4E',
    500: '#B87333', // 브랜드 Copper — CTA, 링크, 강조
    600: '#9A5F28',
    700: '#7D4D1E',
    800: '#613C16',
    900: '#4A2D0E',
  },

  /**
   * Neutral — 순수 회색
   * 온도 없는 회색. UI 구조 요소용.
   */
  neutral: {
    50: '#F9F9F9',
    100: '#F3F3F3',
    200: '#E5E5E5',
    300: '#D4D4D4',
    400: '#A3A3A3',
    500: '#737373',
    600: '#525252',
    700: '#404040',
    800: '#262626',
    900: '#171717',
  },

  /**
   * Semantic 색 — 상태 표현
   */
  semantic: {
    success: '#4A7C59',
    successLight: '#EAF2EC',
    error: '#C0392B',
    errorLight: '#FDECEA',
    warning: '#C87F0A',
    warningLight: '#FEF3E2',
    info: '#2563EB',
    infoLight: '#EFF6FF',
  },
} as const;

// ─────────────────────────────────────────────
// 폰트 패밀리
// ─────────────────────────────────────────────

export const fonts = {
  /**
   * Noto Serif KR — 인용구 전용
   * @expo-google-fonts/noto-serif-kr 패키지 사용
   * 라이선스: OFL (상업용 무료)
   */
  quote: 'NotoSerifKR-Regular',
  quoteMedium: 'NotoSerifKR-Medium',
  quoteBold: 'NotoSerifKR-Bold',

  /**
   * Pretendard — UI 전용
   * assets/fonts/ 폴더에 직접 넣고 useFonts 훅 사용
   * 라이선스: OFL (상업용 무료)
   */
  ui: 'Pretendard-Regular',
  uiMedium: 'Pretendard-Medium',
  uiSemiBold: 'Pretendard-SemiBold',
  uiBold: 'Pretendard-Bold',

  /**
   * Libre Baskerville — 영문 인용구 보조
   * @expo-google-fonts/libre-baskerville 패키지 사용
   * 라이선스: OFL (상업용 무료)
   */
  enSerif: 'LibreBaskerville-Regular',
  enSerifItalic: 'LibreBaskerville-Italic',
  enSerifBold: 'LibreBaskerville-Bold',
} as const;

// ─────────────────────────────────────────────
// 타입 스케일
// ─────────────────────────────────────────────

export const fontSize = {
  xxs: 9,   // 워터마크, 법적 표기
  xs: 11,   // 인용구 최소 (500자+), 출판사·ISBN
  sm: 13,   // 보조 레이블, 저자명
  base: 15, // 인용구 중간 (200자 기준), 본문 UI
  md: 17,   // 책 제목 (카드 내), 섹션 헤더
  lg: 22,   // 인용구 큰 (50자 이하), 화면 제목
  xl: 28,   // T5 타이포 메인 텍스트
  xxl: 36,  // T5 타이포 임팩트 텍스트
} as const;

// ─────────────────────────────────────────────
// 행간 (Line Height)
// ─────────────────────────────────────────────

export const lineHeight = {
  tight: 1.3,    // 제목, 한 줄 레이블
  normal: 1.5,   // UI 본문
  relaxed: 1.6,  // 인용구 소 (11px)
  loose: 1.7,    // 인용구 중 (15px)
  spacious: 1.8, // 인용구 대 (22px)
  poetry: 2.2,   // T5 타이포 시(詩) 배치
} as const;

// ─────────────────────────────────────────────
// 자간 (Letter Spacing)
// ─────────────────────────────────────────────

export const letterSpacing = {
  tight: -0.02,  // 큰 제목, 임팩트 텍스트
  normal: 0,     // 기본
  wide: 0.05,    // 저자명, 작은 레이블
  wider: 0.1,    // 워터마크, T3 모노 캡션
} as const;

// ─────────────────────────────────────────────
// 여백 시스템 (4px 기반)
// ─────────────────────────────────────────────

export const spacing = {
  0: 0,
  1: 4,   // 아이콘 내부 여백
  2: 8,   // 인라인 요소 간격
  3: 12,  // 컴팩트 레이블 패딩
  4: 16,  // 카드 bookArea 패딩
  6: 24,  // 섹션 간격
  8: 32,  // 카드 quoteArea 패딩
  12: 48, // 템플릿 상하 패딩
  16: 64, // 큰 섹션 구분
} as const;

// ─────────────────────────────────────────────
// 그림자 토큰
// ─────────────────────────────────────────────

/**
 * React Native shadow는 플랫폼별 처리 필요.
 * iOS: shadowOffset, shadowRadius, shadowOpacity, shadowColor
 * Android: elevation
 * 권장: react-native-shadow-2 또는 직접 스타일 분기
 */
export const shadows = {
  card: {
    ios: {
      shadowColor: '#1C1917',
      shadowOffset: { width: 0, height: 2 },
      shadowRadius: 8,
      shadowOpacity: 0.08,
    },
    android: { elevation: 3 },
  },
  modal: {
    ios: {
      shadowColor: '#1C1917',
      shadowOffset: { width: 0, height: 8 },
      shadowRadius: 24,
      shadowOpacity: 0.16,
    },
    android: { elevation: 12 },
  },
  floating: {
    ios: {
      shadowColor: '#1C1917',
      shadowOffset: { width: 0, height: 4 },
      shadowRadius: 16,
      shadowOpacity: 0.12,
    },
    android: { elevation: 8 },
  },
} as const;

// ─────────────────────────────────────────────
// 둥근 모서리
// ─────────────────────────────────────────────

export const radius = {
  xs: 2,      // 태그·뱃지
  sm: 4,      // 버튼·입력창
  md: 8,      // 카드 내부 요소
  lg: 12,     // 카드·시트
  xl: 16,     // 바텀시트·대형 카드
  full: 9999, // 원·알약 모양
} as const;

// ─────────────────────────────────────────────
// 카드 출력 크기 상수
// ─────────────────────────────────────────────

export const cardSize = {
  '9:16': { width: 1080, height: 1920 }, // 인스타 스토리
  '1:1': { width: 1080, height: 1080 },  // 인스타 피드
  '4:5': { width: 1080, height: 1350 },  // 인스타 포스트
} as const;

export type CardRatio = keyof typeof cardSize;

// ─────────────────────────────────────────────
// 인용구 길이별 자동 폰트 크기 보간 함수
// ─────────────────────────────────────────────

/**
 * 인용구 글자 수에 따라 폰트 크기를 자동으로 결정한다.
 * 세 기준점 선형 보간:
 *   ≤50자  → 22px
 *   200자  → 15px
 *   ≥500자 → 11px
 *
 * @param charCount - 인용구 글자 수 (공백 포함)
 * @returns 권장 폰트 크기 (px, 소수점 가능 — Math.round 해서 사용)
 */
export function getQuoteFontSize(charCount: number): number {
  if (charCount <= 50) return 22;
  if (charCount >= 500) return 11;
  if (charCount <= 200) {
    // 50 → 200자: 22px → 15px 선형 보간
    return 22 - ((charCount - 50) / 150) * 7;
  } else {
    // 200 → 500자: 15px → 11px 선형 보간
    return 15 - ((charCount - 200) / 300) * 4;
  }
}

/**
 * 인용구 폰트 크기에 따라 최적 행간을 반환한다.
 *
 * @param quoteFontSize - getQuoteFontSize() 반환값
 * @returns 행간 비율 (lineHeight multiplier)
 */
export function getQuoteLineHeight(quoteFontSize: number): number {
  // 11px→1.6, 22px→1.8 선형 보간
  return 1.6 + ((quoteFontSize - 11) / (22 - 11)) * 0.2;
}

// ─────────────────────────────────────────────
// 워터마크 설정
// ─────────────────────────────────────────────

export const watermark = {
  /** 기본 모드: 거의 안 보임 */
  minimal: {
    text: '책귀',
    fontSize: fontSize.xxs, // 9px
    opacity: 0.30,
    position: 'bottomRight' as const,
    fontFamily: fonts.ui,
  },
  /** 강조 모드 (사용자 토글 ON) */
  branded: {
    text: '책귀',
    fontSize: fontSize.xs, // 11px
    opacity: 0.70,
    position: 'bottomCenter' as const,
    fontFamily: fonts.uiMedium,
    showIcon: true,
  },
} as const;

// ─────────────────────────────────────────────
// 표지 팔레트 추출 결과 타입
// ─────────────────────────────────────────────

export interface ExtractedPalette {
  /** 표지 가장 지배적인 색 — 배경용 */
  dominant: string;
  /** 두 번째 지배적인 색 */
  secondary: string;
  /** 밝은 진동 색 (accent 역할) */
  vibrant: string;
  /** 어두운 진동 색 */
  darkVibrant: string;
  /** 무채색 계열 뮤트 */
  muted: string;
  /** WCAG AA를 보장하는 배경색 위 텍스트 색 (자동 계산) */
  textOnBackground: string;
  /** WCAG AA를 보장하는 배경색 위 보조 텍스트 색 (자동 계산) */
  subtextOnBackground: string;
}

/** 팔레트 추출 실패 시 사용하는 폴백 팔레트 (템플릿별 기본값) */
export const fallbackPalettes: Record<string, ExtractedPalette> = {
  minimal: {
    dominant: colors.secondary[200],
    secondary: colors.secondary[400],
    vibrant: colors.accent[500],
    darkVibrant: colors.accent[700],
    muted: colors.primary[300],
    textOnBackground: colors.primary[900],
    subtextOnBackground: colors.primary[600],
  },
  warm: {
    dominant: colors.secondary[400],
    secondary: colors.secondary[600],
    vibrant: colors.accent[400],
    darkVibrant: colors.accent[600],
    muted: colors.primary[400],
    textOnBackground: colors.primary[800],
    subtextOnBackground: colors.primary[600],
  },
  mono: {
    dominant: colors.primary[900],
    secondary: colors.primary[700],
    vibrant: colors.accent[400],
    darkVibrant: colors.accent[600],
    muted: colors.primary[500],
    textOnBackground: colors.secondary[200],
    subtextOnBackground: colors.primary[300],
  },
  coverExtract: {
    dominant: '#3D2817',
    secondary: '#6B4423',
    vibrant: '#C9A876',
    darkVibrant: '#8B5A3C',
    muted: '#A08060',
    textOnBackground: '#F5EDD8',
    subtextOnBackground: '#D4C0A0',
  },
  typography: {
    dominant: colors.primary[600],
    secondary: colors.primary[800],
    vibrant: colors.accent[300],
    darkVibrant: colors.accent[600],
    muted: colors.primary[400],
    textOnBackground: colors.secondary[200],
    subtextOnBackground: colors.secondary[500],
  },
};
