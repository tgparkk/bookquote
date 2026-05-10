# T4 — 표지 발췌 (Cover Extract) 템플릿 명세

**핵심 결**: 표지가 세상이다. 표지 blur 전체 배경 + 선명 표지 우하단 + 팔레트 전면 활용.
**영감**: Spotify 앨범 플레이어 배경, Apple Music Now Playing, Letterboxd 영화 배경
**페르소나 적합도**: 한지영(디자이너) ★★★ — "이게 진짜. 책 컬러로 자동 팔레트 — 내가 원하던 것"

---

## 1. 시각 원칙

- **표지가 모든 색을 결정한다.** 이 템플릿에서 디자이너가 사전에 정한 고정 색은 없다.
- **blur가 분위기를 만든다.** 표지를 전체 배경에 깔고 Gaussian blur → 마치 표지 안으로 들어온 느낌.
- **선명한 표지가 우하단에 앵커.** blur 배경 + 선명 표지의 대비가 핵심 시각 트릭.
- **그라데이션이 텍스트 가독성을 보장한다.** 인용구 영역 아래 어두운 그라데이션 overlay.

---

## 2. 색 토큰 매핑

| 영역 | 소스 | 근거 |
|------|------|------|
| 배경 이미지 | 표지 원본 (blur 30–40px) | 표지가 배경이 됨 |
| 배경 overlay | `palette.dominant` 60% opacity | blur만으론 색이 옅어짐 → overlay로 보강 |
| 그라데이션 overlay | transparent → `palette.dominant` 80% | 인용구 영역 가독성 |
| 인용구 텍스트 | `palette.textOnBackground` | WCAG AA 자동 보장 (대부분 흰색 계열) |
| 저자·책 제목 | `palette.subtextOnBackground` | |
| 선명 표지 테두리 | `palette.vibrant` 40% opacity | 표지 주변 미묘한 glow |
| 워터마크 | `colors.secondary[200]` 35% opacity | |

**팔레트 전면 활용 — 이 템플릿만의 특징**:
- dominant: 배경 overlay의 주색
- vibrant: 표지 테두리 glow + 강조 accent
- darkVibrant: 그라데이션 어두운 쪽
- textOnBackground / subtextOnBackground: 텍스트 전체
- 추출 실패 시: `fallbackPalettes.coverExtract` — 갈색 계열 `#3D2817`

---

## 3. 레이어 구조 (z-index 개념)

```
Layer 5 (top):  워터마크
Layer 4:        텍스트 (인용구 + 책 정보)
Layer 3:        그라데이션 overlay (가독성 보장)
Layer 2:        선명 표지 이미지 (우하단)
Layer 1:        dominant color overlay (60%)
Layer 0 (base): 표지 이미지 (blur 35px)
```

---

## 4. 영역 구성 — 9:16 기준 (1080×1920px)

```
┌──────────────────────────┐
│  [표지 blur 전체 배경]    │
│  + dominant overlay      │
│                          │
│                          │
│  "우리는 누군가의          │
│   가장 좋은 시절을         │
│   잘 모르는 채로도,        │
│   그 사람을 사랑할         │
│   수 있다."               │
│                          │
│  ██████████████████████  │  ← 그라데이션 시작 (transparent)
│  ████████████████████    │
│  ██████████████          │  ← darkVibrant 80%
│           ┌──────────┐   │
│           │  선명     │   │  ← 표지 이미지 (blur 없음)
│           │  표지     │   │    우하단 배치
│  작별하지  │          │   │
│  않는다   │          │   │
│  한강     └──────────┘   │
│                    [책귀]│
└──────────────────────────┘
```

### 영역 좌표 (9:16, 1080×1920px)

| 영역 | x | y | width | height | 비고 |
|------|---|---|-------|--------|------|
| backgroundImage | 0 | 0 | 1080 | 1920 | blur 35px, scale-fill |
| dominantOverlay | 0 | 0 | 1080 | 1920 | dominant 60% |
| gradientOverlay | 0 | 960 | 1080 | 960 | transparent → darkVibrant 80% |
| quoteArea | 80 | 200 | 920 | 가변 | 텍스트 레이어 |
| coverImageSharp | 640 | 1480 | 360 | 504 | 선명 표지 (우하단) |
| bookArea | 80 | 1700 | 540 | auto | 선명 표지 왼쪽 |
| watermark | 1080-80 | 1880 | auto | 24 | |

### 선명 표지 이미지 상세

- 크기: 360×504px (9:16 비율 유지)
- 위치: 우하단 (x: 1080-360-80=640, y: 1920-504-80=1336... 조정 필요)
- 실제 y: 1480 (bookArea와 겹치지 않도록)
- 둥근 모서리: `radius.lg` (12px)
- 그림자: `shadows.card` (어두운 배경 위이므로 더 강하게)
- 테두리: `palette.vibrant` 40% opacity, 1px

### 그라데이션 overlay 상세

```
LinearGradient:
  direction: top → bottom
  stops:
    0%:   transparent (rgba(dominant, 0))
    40%:  rgba(dominant, 0.3)
    100%: rgba(darkVibrant, 0.85)
```

---

## 5. 비율 변형 (Variants)

### 1:1 (1080×1080px)

- 선명 표지: 240×336px, 우하단 (x: 760, y: 680)
- bookArea: 좌하단 (x: 80, y: 720)
- gradeintOverlay: y=400 시작
- 인용구 최대 길이: 150자 권장

### 4:5 (1080×1350px)

- 선명 표지: 300×420px, 우하단 (x: 700, y: 880)
- 나머지 9:16 비율 조정

---

## 6. 인용구 길이별 자동 조정

T4는 배경이 어두운 경우가 많아 가독성 우선:

| 글자 수 | 폰트 크기 | 폰트 weight | 비고 |
|---------|---------|-----------|------|
| ≤ 50자 | 22px | NotoSerifKR-Bold | 큰 텍스트, 더 굵게 |
| 51–200자 | 보간 22→17px | NotoSerifKR-Medium | |
| > 200자 | 15–17px | NotoSerifKR-Medium | 최소 17px 권장 (어두운 배경) |

**T4만의 규칙**: 어두운 배경에서 작은 폰트는 가독성이 급격히 떨어지므로 최소 폰트 15px (다른 템플릿 11px보다 큼).

---

## 7. Dart 클래스 명세

```dart
import 'package:flutter/painting.dart';
import '../tokens.dart';

class CoverExtractTemplate {
  static const String id          = 'coverExtract';
  static const String name        = '표지 발췌';
  static const String description = '표지 안으로 들어온다. 책의 색과 감정이 카드 전체를 채운다.';
  static const String thumbnail   = 'template-cover-extract-thumb.png';

  static const _CoverExtractLayout layout = _CoverExtractLayout(
    backgroundImage: _BackgroundImageSpec(
      blurRadius: 35,
      scaleMode: ImageScaleMode.fill,
    ),
    dominantOverlay: _OverlaySpec(opacity: 0.60),
    gradientOverlay: _GradientSpec(
      startY: 0.50,     // 카드 높이의 50% 지점부터
      endOpacity: 0.85,
    ),
    quoteArea: _CoverQuoteAreaSpec(
      paddingHorizontal: 80,
      paddingTop: 200,
      fontFamily: AppFonts.quoteBold,    // T4는 Bold 사용
      minFontSize: 15,                   // 어두운 배경 가독성 — 최소 15px
    ),
    coverImageSharp: _SharpCoverSpec(
      widthRatio: 0.333,                 // 전체 너비의 1/3
      position: WatermarkPosition.bottomRight,
      marginRight: 80,
      marginBottom: 200,
      borderRadius: AppRadius.lg,
      borderWidth: 1,
      borderOpacity: 0.40,
      shadow: AppShadows.card,
    ),
    bookArea: _CoverBookAreaSpec(
      paddingHorizontal: 80,
      fromBottom: 120,
      maxWidth: 540,                     // 선명 표지와 겹치지 않도록
      titleFontFamily: AppFonts.quoteMedium,
      titleFontSize: AppFontSize.md,
      authorFontFamily: AppFonts.ui,
      authorFontSize: AppFontSize.sm,
    ),
    watermarkArea: _CoverWatermarkSpec(
      position: WatermarkPosition.bottomRight,
      marginRight: 80,
      fromBottom: 60,
      fontSize: AppFontSize.xxs,
      opacity: 0.35,
    ),
  );

  /// 팔레트를 받아 색 매핑 반환 — 이 템플릿은 팔레트 슬롯을 전면 활용
  static _CoverExtractColors colorMapping(ExtractedPalette palette) =>
      _CoverExtractColors(
        backgroundOverlay:        palette.dominant,
        backgroundOverlayOpacity: 0.60,
        gradientStartColor:       const Color(0x00000000), // transparent
        gradientEndColor:         palette.darkVibrant,
        gradientEndOpacity:       0.85,
        quoteText:                palette.textOnBackground,
        bookTitleText:            palette.subtextOnBackground,
        authorText:               palette.subtextOnBackground,
        coverBorderColor:         palette.vibrant,
        watermarkText:            AppColors.secondary200,
      );

  static const Map<String, _CoverExtractVariant> variants = {
    '9:16': _CoverExtractVariant(
      canvasWidth:    1080,
      canvasHeight:   1920,
      coverSharpW:    360,
      coverSharpH:    504,
      coverSharpX:    640,
      coverSharpY:    1480,
      gradientStartY: 960,
    ),
    '1:1': _CoverExtractVariant(
      canvasWidth:    1080,
      canvasHeight:   1080,
      coverSharpW:    240,
      coverSharpH:    336,
      coverSharpX:    760,
      coverSharpY:    680,
      gradientStartY: 400,
      maxQuoteChars:  150,
    ),
    '4:5': _CoverExtractVariant(
      canvasWidth:    1080,
      canvasHeight:   1350,
      coverSharpW:    300,
      coverSharpH:    420,
      coverSharpX:    700,
      coverSharpY:    880,
      gradientStartY: 600,
    ),
  };
}

/// 배경 이미지 스케일 모드
enum ImageScaleMode { fill, fit, cover }

// ── 보조 데이터 클래스 ────────────────────────────────────────

final class _BackgroundImageSpec {
  const _BackgroundImageSpec({
    required this.blurRadius,
    required this.scaleMode,
  });
  final double         blurRadius;
  final ImageScaleMode scaleMode;
}

final class _OverlaySpec {
  const _OverlaySpec({required this.opacity});
  final double opacity;
}

final class _GradientSpec {
  const _GradientSpec({required this.startY, required this.endOpacity});
  /// 카드 높이 비율 (0.0~1.0)
  final double startY;
  final double endOpacity;
}

final class _CoverQuoteAreaSpec {
  const _CoverQuoteAreaSpec({
    required this.paddingHorizontal,
    required this.paddingTop,
    required this.fontFamily,
    required this.minFontSize,
  });
  final double paddingHorizontal;
  final double paddingTop;
  final String fontFamily;
  /// getQuoteFontSize() 결과값의 하한 (어두운 배경 가독성)
  final double minFontSize;
}

final class _SharpCoverSpec {
  const _SharpCoverSpec({
    required this.widthRatio,
    required this.position,
    required this.marginRight,
    required this.marginBottom,
    required this.borderRadius,
    required this.borderWidth,
    required this.borderOpacity,
    required this.shadow,
  });
  final double              widthRatio;
  final WatermarkPosition   position;
  final double              marginRight;
  final double              marginBottom;
  final double              borderRadius;
  final double              borderWidth;
  final double              borderOpacity;
  final BoxShadow           shadow;
}

final class _CoverBookAreaSpec {
  const _CoverBookAreaSpec({
    required this.paddingHorizontal,
    required this.fromBottom,
    required this.maxWidth,
    required this.titleFontFamily,
    required this.titleFontSize,
    required this.authorFontFamily,
    required this.authorFontSize,
  });
  final double paddingHorizontal;
  final double fromBottom;
  final double maxWidth;
  final String titleFontFamily;
  final double titleFontSize;
  final String authorFontFamily;
  final double authorFontSize;
}

final class _CoverWatermarkSpec {
  const _CoverWatermarkSpec({
    required this.position,
    required this.marginRight,
    required this.fromBottom,
    required this.fontSize,
    required this.opacity,
  });
  final WatermarkPosition position;
  final double marginRight;
  final double fromBottom;
  final double fontSize;
  final double opacity;
}

final class _CoverExtractLayout {
  const _CoverExtractLayout({
    required this.backgroundImage,
    required this.dominantOverlay,
    required this.gradientOverlay,
    required this.quoteArea,
    required this.coverImageSharp,
    required this.bookArea,
    required this.watermarkArea,
  });
  final _BackgroundImageSpec  backgroundImage;
  final _OverlaySpec          dominantOverlay;
  final _GradientSpec         gradientOverlay;
  final _CoverQuoteAreaSpec   quoteArea;
  final _SharpCoverSpec       coverImageSharp;
  final _CoverBookAreaSpec    bookArea;
  final _CoverWatermarkSpec   watermarkArea;
}

final class _CoverExtractColors {
  const _CoverExtractColors({
    required this.backgroundOverlay,
    required this.backgroundOverlayOpacity,
    required this.gradientStartColor,
    required this.gradientEndColor,
    required this.gradientEndOpacity,
    required this.quoteText,
    required this.bookTitleText,
    required this.authorText,
    required this.coverBorderColor,
    required this.watermarkText,
  });
  final Color  backgroundOverlay;
  final double backgroundOverlayOpacity;
  final Color  gradientStartColor;
  final Color  gradientEndColor;
  final double gradientEndOpacity;
  final Color  quoteText;
  final Color  bookTitleText;
  final Color  authorText;
  final Color  coverBorderColor;
  final Color  watermarkText;
}

final class _CoverExtractVariant {
  const _CoverExtractVariant({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.coverSharpW,
    required this.coverSharpH,
    required this.coverSharpX,
    required this.coverSharpY,
    required this.gradientStartY,
    this.maxQuoteChars,
  });
  final double canvasWidth;
  final double canvasHeight;
  final double coverSharpW;
  final double coverSharpH;
  final double coverSharpX;
  final double coverSharpY;
  final double gradientStartY;
  final int?   maxQuoteChars;
}
```

---

## 8. ASCII 레이아웃 미리보기 (9:16)

```
╔══════════════════════════╗
║ ░░░░[표지blur배경]░░░░░ ║  ← Layer 0: 표지 blur 35px
║ ▓▓▓▓[dominant overlay]▓ ║  ← Layer 1: dominant 60%
║                          ║
║   "우리는 누군가의        ║
║    가장 좋은 시절을       ║  ← 인용구 (textOnBackground)
║    잘 모르는 채로도,      ║    NotoSerifKR-Bold, 22px
║    그 사람을 사랑할       ║
║    수 있다."              ║
║                          ║
║▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒║  ← 그라데이션 시작
║████████████████████████║
║███████████  ┌─────────┐║  ← 선명 표지 (우하단)
║ 작별하지    │         │║
║ 않는다      │  표지   │║  ← bookArea (좌하단)
║ 한강        │         │║
║        [책귀└─────────┘║  ← 워터마크
╚══════════════════════════╝
```
