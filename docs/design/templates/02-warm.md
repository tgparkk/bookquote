# T2 — 따뜻 (Warm) 템플릿 명세

**핵심 결**: 책 표지가 왼쪽에, 크림 배경이 오른쪽에. 책과 텍스트가 함께 숨 쉰다.
**영감**: 독립 서점 뉴스레터, 일본 문예지 레이아웃, 빈티지 문고본 표지
**페르소나 적합도**: 민지(마케터) ★★★ — "따뜻해 보인다, 인스타 스토리에 올리기 좋을 것 같다"

---

## 1. 시각 원칙

- **표지가 감정을 설정한다.** 왼쪽 표지 영역이 전체 카드의 분위기를 리드한다.
- **배경은 표지에서 가장 연한 색에서 온다.** 표지 lightest 색으로 배경 계산 → 자연스러운 조화.
- **텍스트 블록은 오른쪽에, 세로로 중앙 정렬.** 책을 펼쳐놓은 느낌.

---

## 2. 색 토큰 매핑

| 영역 | 소스 | 근거 |
|------|------|------|
| 카드 배경 | `lightenToBackground(palette.dominant)` | 표지 dominant를 L\*95 이상으로 밝힘 |
| 좌측 표지 영역 배경 | `palette.dominant` 20% opacity overlay | 표지 색이 배경에 살짝 번짐 |
| 인용구 텍스트 | `palette.textOnBackground` | WCAG AA 보장 자동 계산 |
| 책 제목 | `palette.darkVibrant` | 표지 진한 색 |
| 저자명 | `palette.subtextOnBackground` | 보조 텍스트 |
| 우측 텍스트 블록 배경 | `palette.secondary` 8% opacity | 미묘한 구분 |
| 구분선 없음 | — | 따뜻은 선 대신 여백으로 구분 |

**lightenToBackground 함수 설명**:
```
dominant 색을 HSL로 변환 → L(밝기)를 92–96 범위로 올림 → hex 반환
너무 채도가 낮으면 (S < 10) colors.secondary[400] 폴백 사용
```

---

## 3. 영역 구성 — 9:16 기준 (1080×1920px)

```
┌──────────┬──────────────────┐
│          │                  │
│          │  [상단 여백]      │
│          │                  │
│  책 표지  │  "우리는 누군가의 │
│  (세로    │   가장 좋은 시절  │
│   전체)  │   을 잘 모르는    │
│          │   채로도, 그 사람 │
│          │   을 사랑할 수    │
│          │   있다."         │
│  blur    │                  │
│  overlay │  ─────────       │
│          │                  │
│          │  작별하지 않는다  │
│          │  한강             │
│          │  문학동네         │
│          │                  │
│          │              [책귀]
└──────────┴──────────────────┘
  ← 380px →← 700px →
```

### 영역 좌표 (9:16, 1080×1920px)

| 영역 | x | y | width | height | 비고 |
|------|---|---|-------|--------|------|
| coverPanel | 0 | 0 | 380 | 1920 | 전체 높이 |
| coverImage | 40 | 세로중앙 | 300 | 420 | 표지 이미지 중앙 배치 |
| textPanel | 380 | 0 | 700 | 1920 | 배경 lightened |
| quoteArea | 428 | 240 | 604 | 가변 | 텍스트 패널 내부 |
| divider | 428 | quoteArea.bottom + 64 | 200 | 1 | 짧은 구분선 (왼쪽 정렬) |
| bookArea | 428 | divider.y + 32 | 604 | auto | 제목·저자 |
| watermark | 1080-64 | 1920-80 | auto | 24 | 우하단 |

### coverPanel 상세

- 배경: `palette.dominant` (진한 원색)
- 표지 이미지: 세로 중앙 정렬, 둥근 모서리 `radius.md` (8px)
- 표지 아래 은은한 그림자: `shadows.card`
- 좌측 패널 우측 경계: 그라데이션 페이드 (dominant → transparent, 40px)

### textPanel 상세

- 배경: `lightenToBackground(palette.dominant)`
- 좌측 경계: 그라데이션 (dominant 10% → transparent, 40px) — coverPanel 이어지는 느낌
- 내부 여백: 좌 48px, 우 48px

---

## 4. 비율 변형 (Variants)

### 1:1 (1080×1080px)

- 구조 변경: 좌/우 분할 → **상/하 분할**
- 상단 (360px): 표지 이미지 가로 전체 (blur 배경 + 표지 중앙)
- 하단 (720px): 크림 배경 + 인용구 + 책 정보
- 이유: 1:1은 세로가 짧아 좌우 분할 시 텍스트 공간 부족

### 4:5 (1080×1350px)

- 9:16과 동일 좌/우 분할 구조
- 표지 패널 폭: 360px (조금 더 좁게)
- 텍스트 패널 폭: 720px
- 상하 여백 조정: paddingTop 192 → 160

---

## 5. 인용구 길이별 자동 조정

T1 미니멀과 동일 보간 함수 적용.
단, textPanel 폭이 604px이므로 줄바꿈 기준이 다름:

| 글자 수 | 폰트 크기 | 1줄 평균 글자 (15px) | 비고 |
|---------|---------|-------------------|------|
| ≤ 50자 | 22px | 약 14자/줄 | textPanel 너비 기준 |
| 51–200자 | 보간 | 약 20자/줄 | |
| > 200자 | 11–15px | 약 30자/줄 | |

---

## 6. Dart 클래스 명세

```dart
import 'package:flutter/painting.dart';
import '../tokens.dart';

/// T2 따뜻 템플릿
/// 1:1 비율은 Spotify 스타일 — 상단 360px 표지 가로 전체 + 하단 인용구
class WarmTemplate {
  static const String id          = 'warm';
  static const String name        = '따뜻';
  static const String description = '책 표지 옆에서 인용구가 숨 쉰다. 책을 펼쳐놓은 온기.';
  static const String thumbnail   = 'template-warm-thumb.png';

  static const _WarmLayout layout = _WarmLayout(
    coverPanel: _CoverPanelSpec(
      widthRatio: 0.352,       // 전체 너비의 35.2% (9:16 기준 380/1080)
      paddingHorizontal: 40,
      coverWidth: 300,
      coverHeight: 420,
      coverBorderRadius: AppRadius.md,
      fadeEdgeWidth: 40,       // 우측 그라데이션 페이드 너비
    ),
    textPanel: _TextPanelSpec(
      paddingHorizontal: 48,
      paddingTop: 240,
      paddingBottom: 120,
    ),
    divider: _WarmDividerSpec(
      marginTop: 64,
      marginBottom: 32,
      width: 200,              // 짧은 구분선 (좌측 정렬)
      height: 1,
      opacity: 0.40,
    ),
    bookArea: _WarmBookAreaSpec(
      titleFontFamily: AppFonts.quoteMedium,
      titleFontSize: AppFontSize.md,
      authorFontFamily: AppFonts.ui,
      authorFontSize: AppFontSize.sm,
      gap: AppSpacing.s1,
    ),
    watermarkArea: _WarmWatermarkSpec(
      position: WatermarkPosition.bottomRight,
      marginRight: 64,
      marginBottom: 80,
      fontSize: AppFontSize.xxs,
      opacity: 0.30,
    ),
  );

  /// 팔레트를 받아 색 매핑 반환
  /// background는 palette.dominant를 lightenToBackground()로 밝힌 값
  static _WarmColors colorMapping(ExtractedPalette palette) => _WarmColors(
    background:          lightenToBackground(palette.dominant),
    coverPanelBackground: palette.dominant,
    quoteText:           palette.textOnBackground,
    bookTitleText:       palette.darkVibrant,
    authorText:          palette.subtextOnBackground,
    dividerColor:        palette.vibrant,
    watermarkText:       palette.textOnBackground,
  );

  static const Map<String, _WarmRatioVariant> variants = {
    '9:16': _WarmRatioVariant(
      canvasWidth:    1080,
      canvasHeight:   1920,
      layout:         WarmLayout.sideBySide,   // 좌우 분할
      coverPanelSize: 380,
    ),
    // Spotify 스타일: 표지 가로 전체(상단 360px) + 인용구(하단)
    '1:1': _WarmRatioVariant(
      canvasWidth:    1080,
      canvasHeight:   1080,
      layout:         WarmLayout.topBottom,    // 상하 분할
      coverPanelSize: 360,
    ),
    '4:5': _WarmRatioVariant(
      canvasWidth:    1080,
      canvasHeight:   1350,
      layout:         WarmLayout.sideBySide,
      coverPanelSize: 360,
    ),
  };
}

/// T2 레이아웃 모드
enum WarmLayout {
  /// 9:16, 4:5 — 표지 패널 왼쪽, 텍스트 패널 오른쪽
  sideBySide,
  /// 1:1 — Spotify 스타일: 표지 상단 가로 전체 (360px), 인용구 하단
  topBottom,
}

// ── 보조 데이터 클래스 ────────────────────────────────────────

final class _CoverPanelSpec {
  const _CoverPanelSpec({
    required this.widthRatio,
    required this.paddingHorizontal,
    required this.coverWidth,
    required this.coverHeight,
    required this.coverBorderRadius,
    required this.fadeEdgeWidth,
  });
  final double widthRatio;
  final double paddingHorizontal;
  final double coverWidth;
  final double coverHeight;
  final double coverBorderRadius;
  final double fadeEdgeWidth;
}

final class _TextPanelSpec {
  const _TextPanelSpec({
    required this.paddingHorizontal,
    required this.paddingTop,
    required this.paddingBottom,
  });
  final double paddingHorizontal;
  final double paddingTop;
  final double paddingBottom;
}

final class _WarmDividerSpec {
  const _WarmDividerSpec({
    required this.marginTop,
    required this.marginBottom,
    required this.width,
    required this.height,
    required this.opacity,
  });
  final double marginTop;
  final double marginBottom;
  final double width;
  final double height;
  final double opacity;
}

final class _WarmBookAreaSpec {
  const _WarmBookAreaSpec({
    required this.titleFontFamily,
    required this.titleFontSize,
    required this.authorFontFamily,
    required this.authorFontSize,
    required this.gap,
  });
  final String titleFontFamily;
  final double titleFontSize;
  final String authorFontFamily;
  final double authorFontSize;
  final double gap;
}

final class _WarmWatermarkSpec {
  const _WarmWatermarkSpec({
    required this.position,
    required this.marginRight,
    required this.marginBottom,
    required this.fontSize,
    required this.opacity,
  });
  final WatermarkPosition position;
  final double marginRight;
  final double marginBottom;
  final double fontSize;
  final double opacity;
}

final class _WarmLayout {
  const _WarmLayout({
    required this.coverPanel,
    required this.textPanel,
    required this.divider,
    required this.bookArea,
    required this.watermarkArea,
  });
  final _CoverPanelSpec    coverPanel;
  final _TextPanelSpec     textPanel;
  final _WarmDividerSpec   divider;
  final _WarmBookAreaSpec  bookArea;
  final _WarmWatermarkSpec watermarkArea;
}

final class _WarmColors {
  const _WarmColors({
    required this.background,
    required this.coverPanelBackground,
    required this.quoteText,
    required this.bookTitleText,
    required this.authorText,
    required this.dividerColor,
    required this.watermarkText,
  });
  final Color background;
  final Color coverPanelBackground;
  final Color quoteText;
  final Color bookTitleText;
  final Color authorText;
  final Color dividerColor;
  final Color watermarkText;
}

final class _WarmRatioVariant {
  const _WarmRatioVariant({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.layout,
    required this.coverPanelSize,
  });
  final double     canvasWidth;
  final double     canvasHeight;
  final WarmLayout layout;
  /// sideBySide: 좌측 패널 너비 / topBottom: 상단 패널 높이
  final double     coverPanelSize;
}

// 유틸 함수 (color_extraction.dart에서 구현)
// dominant 색을 HSL L 92–96 범위로 밝혀 배경색 반환
// S < 10이면 AppColors.secondary400 폴백
Color lightenToBackground(Color dominant) => throw UnimplementedError(
  'color_extraction.dart의 lightenToBackground()를 구현하세요',
);
```

---

## 7. ASCII 레이아웃 미리보기 (9:16)

```
╔═══════════╦═════════════════╗
║           ║                 ║
║           ║                 ║
║           ║  "우리는 누군가의║
║  [표지]   ║   가장 좋은 시절 ║
║           ║   을 잘 모르는  ║
║  표지배경  ║   채로도, 그    ║  ← Noto Serif KR 22px
║  blur +   ║   사람을 사랑할 ║
║  dominant ║   수 있다."     ║
║           ║                 ║
║  ←380→   ║  ──────         ║  ← 짧은 구분선
║           ║                 ║
║           ║  작별하지 않는다 ║  ← 책 제목 (darkVibrant)
║           ║  한강            ║  ← 저자 (subtextOnBg)
║           ║                 ║
║           ║           [책귀]║
╚═══════════╩═════════════════╝
  크림 lighten 배경 ↑
```
