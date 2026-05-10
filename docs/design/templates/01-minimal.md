# T1 — 미니멀 (Minimal) 템플릿 명세

**핵심 결**: 흰 배경, 인용구가 주인공, 충분한 여백, 아무것도 더하지 않는다
**영감**: iA Writer, Bear, Notion — 읽기에 집중한 앱들
**페르소나 적합도**: 민지(마케터) ★★★ — "자연스럽다, 과하지 않아서 올리기 편하다"

---

## 1. 시각 원칙

- **여백이 디자인이다.** 인용구 주변 여백이 크면 클수록 인용구가 더 중요해 보인다.
- **색은 절제한다.** 배경 거의 흰색, 텍스트 거의 검정. 색이 나타나는 순간은 책 표지에서 뽑은 accent 딱 하나.
- **폰트 하나.** Noto Serif KR 하나로만. 굵기(weight)로 위계를 만든다.

---

## 2. 색 토큰 매핑

| 영역 | 토큰 | 값 | 근거 |
|------|------|-----|------|
| 카드 배경 | `colors.secondary[200]` | `#FAFAF8` | 종이의 흰색. 순백보다 따뜻함 |
| 인용구 텍스트 | `colors.primary[800]` | `#241F18` | 잉크. 순검정보다 부드러움 |
| 저자·책 제목 | `colors.primary[500]` | `#635B50` | 보조 위계. 인용구보다 한 단계 흐림 |
| 구분선 | palette.vibrant (30% opacity) | — | 표지에서 추출한 색 미묘하게 반영 |
| 책 제목 강조 | palette.darkVibrant | — | 표지의 색으로 책 제목만 살짝 채색 |
| 워터마크 | `colors.primary[900]` 30% opacity | `#1C1917` | 거의 안 보임 |

**팔레트 연동 방식**:
- 표지에서 추출한 `vibrant` 색을 구분선에만 사용 (매우 미묘)
- 나머지는 고정 토큰. 표지 색이 배경을 물들이지 않음
- 이유: 미니멀의 핵심은 "책 표지 색에 흔들리지 않는 일관성"

---

## 3. 영역 구성 — 9:16 기준 (1080×1920px)

```
┌─────────────────────┐  ← 1080px
│                     │
│   [상단 여백]        │  ← 192px (spacing[12] × 4)
│                     │
│   ┌─────────────┐   │
│   │             │   │  ← quoteArea: 양쪽 패딩 96px
│   │  인용구     │   │
│   │  (Noto      │   │
│   │  Serif KR)  │   │
│   │             │   │
│   └─────────────┘   │
│                     │
│   ─────────────     │  ← 구분선 1px (vibrant 30%)
│                     │  ← 구분선 상하 여백 48px
│   ┌─────────────┐   │
│   │ 책 표지     │   │  ← bookArea: 표지 60×84px
│   │ 책 제목     │   │
│   │ 저자명      │   │
│   └─────────────┘   │
│                     │
│   [하단 여백]        │  ← 144px
│              [책귀] │  ← 워터마크 우하단
└─────────────────────┘
```

### 영역 좌표 (9:16, 1080×1920px)

| 영역 | x | y | width | height | 비고 |
|------|---|---|-------|--------|------|
| quoteArea | 96 | 192 | 888 | 가변 | 인용구 길이에 따라 높이 자동 |
| divider | 96 | quoteArea.bottom + 96 | 888 | 1 | 구분선 |
| bookArea | 96 | divider.y + 48 | 888 | 200 | 표지+텍스트 가로 배치 |
| watermark | 1080-96 | 1920-80 | auto | 24 | 우하단 고정 |

### quoteArea 내부 상세

| 요소 | 폰트 | 크기 | 행간 | 비고 |
|------|------|------|------|------|
| 인용구 텍스트 | NotoSerifKR-Medium | getQuoteFontSize(n) | getQuoteLineHeight(size) | 길이 자동 조정 |
| 여는 따옴표 " | NotoSerifKR-Regular | fontSize × 1.5 | — | 인용구 텍스트 시작 전 |

### bookArea 내부 상세

| 요소 | 폰트 | 크기 | 색 |
|------|------|------|-----|
| 책 표지 썸네일 | — | 60×84px | — |
| 책 제목 | NotoSerifKR-Medium | 15px | palette.darkVibrant |
| 저자명 | Pretendard-Regular | 13px | colors.primary[500] |
| 출판사 (선택) | Pretendard-Regular | 11px | colors.primary[400] |

---

## 4. 비율 변형 (Variants)

### 1:1 (1080×1080px)

- 변경점: 상하 여백 96px로 줄임 (9:16의 절반)
- bookArea를 하단 고정 (y = 880)
- 인용구 최대 길이 권장: 150자 (1:1은 세로 공간이 제한됨)
- 150자 초과 시: 인용구 말줄임표(`…`) 처리 + "더 보기" 힌트

### 4:5 (1080×1350px)

- 변경점: 상하 여백 144px
- 나머지는 9:16과 동일 구조
- 9:16에서 4:5로 전환 시 quoteArea 높이만 재계산

---

## 5. 인용구 길이별 자동 조정

| 글자 수 | 폰트 크기 | 행간 | 최대 줄 수 (9:16) | 처리 |
|---------|---------|------|-----------------|------|
| ≤ 50자 | 22px | 1.8 | 6줄 | 정상 |
| 51–200자 | 보간 22→15px | 보간 1.8→1.7 | 12줄 | 정상 |
| 201–500자 | 보간 15→11px | 보간 1.7→1.6 | 25줄 | 정상 |
| > 500자 | 11px | 1.6 | 제한 | 말줄임 처리 |

**T5 타이포 템플릿 비활성화**: 이 템플릿은 전범위 인용구 지원. 50자 초과 시 T5를 비활성화하는 로직은 T5 명세에서 처리.

---

## 6. Dart 클래스 명세

```dart
import 'package:flutter/painting.dart';
import '../tokens.dart';

class MinimalTemplate {
  static const String id          = 'minimal';
  static const String name        = '미니멀';
  static const String description = '흰 배경, 여백, 인용구 하나. 아무것도 더하지 않는다.';
  static const String thumbnail   = 'template-minimal-thumb.png';

  static const _MinimalLayout layout = _MinimalLayout(
    quoteArea: _QuoteAreaSpec(
      paddingHorizontal: 96,   // 1080px 기준
      paddingTop: 192,
      fontFamily: AppFonts.quoteMedium,
      color: AppColors.primary800,
      openingQuoteScale: 1.5,  // fontSize 배수
    ),
    divider: _DividerSpec(
      marginTop: 96,
      marginBottom: 48,
      height: 1,
      opacity: 0.30,
      // color는 colorMapping에서 주입
    ),
    bookArea: _BookAreaSpec(
      paddingHorizontal: 96,
      coverWidth: 60,
      coverHeight: 84,
      coverBorderRadius: AppRadius.sm,
      titleFontFamily: AppFonts.quoteMedium,
      titleFontSize: AppFontSize.base,
      authorFontFamily: AppFonts.ui,
      authorFontSize: AppFontSize.sm,
      publisherFontSize: AppFontSize.xs,
      gap: AppSpacing.s2,        // 표지와 텍스트 간격
      textGap: AppSpacing.s1,    // 제목-저자 간격
    ),
    watermarkArea: _WatermarkAreaSpec(
      position: WatermarkPosition.bottomRight,
      marginRight: 96,
      marginBottom: 80,
      fontSize: AppFontSize.xxs,
      opacity: 0.30,
      fontFamily: AppFonts.ui,
    ),
  );

  /// 팔레트를 받아 색 매핑 반환
  /// [palette] palette_generator 또는 fallbackPalettes['minimal']
  static _MinimalColors colorMapping(ExtractedPalette palette) =>
      _MinimalColors(
        background:     AppColors.secondary200,    // 고정 — 표지에 흔들리지 않음
        quoteText:      AppColors.primary800,      // 고정
        bookTitleText:  palette.darkVibrant,       // 표지에서 추출한 색으로 책 제목만
        authorText:     AppColors.primary500,      // 고정
        publisherText:  AppColors.primary400,      // 고정
        dividerColor:   palette.vibrant,           // 표지 vibrant 색 미묘하게
        watermarkText:  AppColors.primary900,      // 고정
      );

  static const Map<String, _RatioVariant> variants = {
    '9:16': _RatioVariant(
      canvasWidth:       1080,
      canvasHeight:      1920,
      paddingTop:        192,
      paddingBottom:     144,
      paddingHorizontal: 96,
    ),
    '1:1': _RatioVariant(
      canvasWidth:       1080,
      canvasHeight:      1080,
      paddingTop:        96,
      paddingBottom:     80,
      paddingHorizontal: 96,
      maxQuoteChars:     150,   // 초과 시 말줄임
    ),
    '4:5': _RatioVariant(
      canvasWidth:       1080,
      canvasHeight:      1350,
      paddingTop:        144,
      paddingBottom:     112,
      paddingHorizontal: 96,
    ),
  };
}

// ── 보조 데이터 클래스 (freezed 또는 수동 구현) ──────────────

final class _QuoteAreaSpec {
  const _QuoteAreaSpec({
    required this.paddingHorizontal,
    required this.paddingTop,
    required this.fontFamily,
    required this.color,
    required this.openingQuoteScale,
  });
  final double paddingHorizontal;
  final double paddingTop;
  final String fontFamily;
  final Color  color;
  final double openingQuoteScale;
}

final class _DividerSpec {
  const _DividerSpec({
    required this.marginTop,
    required this.marginBottom,
    required this.height,
    required this.opacity,
  });
  final double marginTop;
  final double marginBottom;
  final double height;
  final double opacity;
}

final class _BookAreaSpec {
  const _BookAreaSpec({
    required this.paddingHorizontal,
    required this.coverWidth,
    required this.coverHeight,
    required this.coverBorderRadius,
    required this.titleFontFamily,
    required this.titleFontSize,
    required this.authorFontFamily,
    required this.authorFontSize,
    required this.publisherFontSize,
    required this.gap,
    required this.textGap,
  });
  final double paddingHorizontal;
  final double coverWidth;
  final double coverHeight;
  final double coverBorderRadius;
  final String titleFontFamily;
  final double titleFontSize;
  final String authorFontFamily;
  final double authorFontSize;
  final double publisherFontSize;
  final double gap;
  final double textGap;
}

final class _WatermarkAreaSpec {
  const _WatermarkAreaSpec({
    required this.position,
    required this.marginRight,
    required this.marginBottom,
    required this.fontSize,
    required this.opacity,
    required this.fontFamily,
  });
  final WatermarkPosition position;
  final double marginRight;
  final double marginBottom;
  final double fontSize;
  final double opacity;
  final String fontFamily;
}

final class _MinimalLayout {
  const _MinimalLayout({
    required this.quoteArea,
    required this.divider,
    required this.bookArea,
    required this.watermarkArea,
  });
  final _QuoteAreaSpec    quoteArea;
  final _DividerSpec      divider;
  final _BookAreaSpec     bookArea;
  final _WatermarkAreaSpec watermarkArea;
}

final class _MinimalColors {
  const _MinimalColors({
    required this.background,
    required this.quoteText,
    required this.bookTitleText,
    required this.authorText,
    required this.publisherText,
    required this.dividerColor,
    required this.watermarkText,
  });
  final Color background;
  final Color quoteText;
  final Color bookTitleText;
  final Color authorText;
  final Color publisherText;
  final Color dividerColor;
  final Color watermarkText;
}

final class _RatioVariant {
  const _RatioVariant({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingHorizontal,
    this.maxQuoteChars,
  });
  final double canvasWidth;
  final double canvasHeight;
  final double paddingTop;
  final double paddingBottom;
  final double paddingHorizontal;
  final int?   maxQuoteChars;
}
```

---

## 7. ASCII 레이아웃 미리보기 (9:16)

```
╔══════════════════════════╗
║                          ║  ← 배경: #FAFAF8
║                          ║
║                          ║
║   "우리는 누군가의        ║
║    가장 좋은 시절을       ║
║    잘 모르는 채로도,      ║
║    그 사람을 사랑할       ║
║    수 있다."              ║
║                          ║  ← Noto Serif KR Medium, 22px
║                          ║
║   ─────────────────      ║  ← 1px vibrant 30%
║                          ║
║   [표지] 작별하지 않는다  ║
║          한강            ║  ← 책 정보
║          문학동네         ║
║                          ║
║                    [책귀]║  ← 워터마크 xxs 30%
╚══════════════════════════╝
```
