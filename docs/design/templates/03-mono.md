# T3 — 모노 (Mono) 템플릿 명세

**핵심 결**: 차콜 배경, 흰 세리프, 상하 1px 라인. 문장의 무게를 느끼게.
**영감**: Co-Star 앱의 텍스트 카드, 뉴욕 타임스 Opinion 섹션, 인디 밴드 포스터
**페르소나 적합도**: 이수연(대학생) ★★★, 한지영(디자이너) ★★★ — "요즘 감성"

---

## 1. 시각 원칙

- **어둠이 텍스트를 빛나게 한다.** `#0F0F0F` 차콜은 순검정보다 덜 무겁고, 더 세련됐다.
- **라인 두 줄이 전부다.** 상단과 하단 각 1px 라인이 카드의 경계를 만든다. 그 외 장식 없음.
- **표지 색은 accent로만.** 라인 색 또는 책 제목 하이라이트에만 표지 추출색 사용.

---

## 2. 색 토큰 매핑

| 영역 | 토큰/소스 | 값 | 근거 |
|------|---------|-----|------|
| 카드 배경 | 고정 | `#0F0F0F` | 차콜. 순검정(`#000000`)보다 따뜻하고 덜 딱딱함 |
| 인용구 텍스트 | `colors.secondary[200]` | `#FAFAF8` | 종이 흰색 — 차갑지 않은 흰색 |
| 저자·책 제목 | `colors.primary[300]` | `#B5ADA0` | 배경 대비 낮은 흐린 색 (보조) |
| 상단 라인 | `palette.vibrant` | — | 표지 accent 포인트 |
| 하단 라인 | `palette.vibrant` | — | 상단과 대칭 |
| 책 제목 하이라이트 | `palette.vibrant` 20% opacity | — | 제목에 표지 색 글로우 |
| 워터마크 | `colors.secondary[200]` 25% opacity | — | 거의 안 보임 |

**팔레트 연동 방식**:
- `palette.vibrant`를 라인·책 제목 하이라이트에만 사용
- 배경은 항상 `#0F0F0F` 고정 — 어떤 표지가 와도 배경은 바뀌지 않음
- 이유: 모노의 정체성은 "어둠 속 빛나는 텍스트". 배경이 흔들리면 정체성 깨짐

---

## 3. 영역 구성 — 9:16 기준 (1080×1920px)

```
┌─────────────────────────┐
│ ─────────────────────── │  ← 상단 라인 1px (vibrant)
│                         │  ← 라인 상하 여백 각 120px
│                         │
│   "우리는 누군가의        │
│    가장 좋은 시절을       │
│    잘 모르는 채로도,      │
│    그 사람을 사랑할       │
│    수 있다."              │  ← Noto Serif KR Medium, #FAFAF8
│                         │
│                         │
│   작별하지 않는다         │  ← 책 제목 (primary[300])
│   한강 · 문학동네         │  ← 저자·출판사 (primary[400])
│                         │
│                    [책귀]│  ← 워터마크
│ ─────────────────────── │  ← 하단 라인 1px (vibrant)
└─────────────────────────┘
```

### 영역 좌표 (9:16, 1080×1920px)

| 영역 | x | y | width | height | 비고 |
|------|---|---|-------|--------|------|
| topLine | 80 | 120 | 920 | 1 | 상단 라인 |
| quoteArea | 80 | 300 | 920 | 가변 | 인용구 |
| bookArea | 80 | 1600 | 920 | auto | 하단 고정 위치 |
| watermark | 1080-80 | 1800 | auto | 24 | |
| bottomLine | 80 | 1860 | 920 | 1 | 하단 라인 |

**bookArea 하단 고정 이유**: 인용구 길이와 관계없이 책 정보는 항상 하단에. 인용구가 길면 bookArea와 겹치지 않도록 quoteArea 최대 높이 제한.

### quoteArea 최대 높이 계산
```
maxQuoteHeight = bookArea.y - topLine.y - spacing[12]
              = 1600 - 300 - 48 = 1252px
```
이 높이를 초과하면 폰트 크기 추가 축소 또는 말줄임 처리.

---

## 4. 비율 변형 (Variants)

### 1:1 (1080×1080px)

- 상단 라인 y: 80
- quoteArea y: 200
- bookArea y: 860
- 하단 라인 y: 980
- 최대 인용구 길이 권장: 120자

### 4:5 (1080×1350px)

- 상단 라인 y: 100
- quoteArea y: 240
- bookArea y: 1120
- 하단 라인 y: 1240

---

## 5. 인용구 길이별 자동 조정

모노는 긴 인용구에서도 강렬함을 유지해야 함.

| 글자 수 | 폰트 크기 | 자간 | 비고 |
|---------|---------|------|------|
| ≤ 50자 | 22px | `-0.02em` | 넓은 자간은 모노 결에 안 맞음 |
| 51–200자 | 보간 22→15px | `0` | |
| > 200자 | 11–15px | `0` | bookArea 위 여백 최소 80px 보장 |

**모노만의 특이 규칙**:
- 인용구 텍스트 좌측 정렬 (T1 미니멀과 동일)
- 인용구 첫 줄 앞 여는 따옴표(" ") 없음 — 모노는 따옴표 없이 담백하게
- 대신 책 제목 앞 em dash(—) 사용: `— 작별하지 않는다`

---

## 6. Dart 클래스 명세

```dart
import 'package:flutter/painting.dart';
import '../tokens.dart';

class MonoTemplate {
  static const String id          = 'mono';
  static const String name        = '모노';
  static const String description = '어둠 속에서 문장 하나가 빛난다. 강렬하고 절제된 결.';
  static const String thumbnail   = 'template-mono-thumb.png';

  /// 배경색 고정 — 어떤 표지가 와도 변경 불가
  static const Color fixedBackground = AppColors.monoBackground; // 0xFF0F0F0F

  static const _MonoLayout layout = _MonoLayout(
    topLine: _LineSpec(
      marginHorizontal: 80,
      y: 120,
      height: 1,
      // color는 colorMapping에서 주입
    ),
    bottomLine: _LineSpec(
      marginHorizontal: 80,
      fromBottom: 60,  // 카드 하단에서 60px
      height: 1,
    ),
    quoteArea: _MonoQuoteAreaSpec(
      paddingHorizontal: 80,
      paddingTop: 300,
      fontFamily: AppFonts.quoteMedium,
      // letterSpacing은 em 기반 → 실제 값은 fontSize * AppLetterSpacing.tight
      letterSpacingEm: AppLetterSpacing.tight,
      noOpeningQuote: true,   // 여는 따옴표 없음
    ),
    bookArea: _MonoBookAreaSpec(
      paddingHorizontal: 80,
      fromBottom: 120,        // 하단 라인에서 위로 120px
      titlePrefix: '— ',      // em dash prefix
      titleFontFamily: AppFonts.ui,
      titleFontSize: AppFontSize.sm,
      authorFontFamily: AppFonts.ui,
      authorFontSize: AppFontSize.xs,
      separator: ' · ',       // 저자·출판사 구분자
      letterSpacingEm: AppLetterSpacing.wider,
    ),
    watermarkArea: _MonoWatermarkSpec(
      position: WatermarkPosition.bottomRight,
      marginRight: 80,
      fromBottom: 80,
      fontSize: AppFontSize.xxs,
      opacity: 0.25,
    ),
  );

  /// 팔레트를 받아 색 매핑 반환
  /// background는 항상 fixedBackground — 팔레트와 무관하게 고정
  static _MonoColors colorMapping(ExtractedPalette palette) => _MonoColors(
    background:         AppColors.monoBackground,   // 고정
    quoteText:          AppColors.secondary200,     // 고정
    bookTitleText:      AppColors.primary300,       // 고정
    authorText:         AppColors.primary400,       // 고정
    lineColor:          palette.vibrant,            // 표지 accent 포인트
    bookTitleHighlight: palette.vibrant,            // 책 제목 배경 글로우 (opacity 0.2)
    watermarkText:      AppColors.secondary200,     // 고정
  );

  static const Map<String, _MonoRatioVariant> variants = {
    '9:16': _MonoRatioVariant(
      canvasWidth:         1080,
      canvasHeight:        1920,
      topLineY:            120,
      bottomLineFromBottom: 60,
      quoteAreaTop:        300,
      bookAreaFromBottom:  120,
    ),
    '1:1': _MonoRatioVariant(
      canvasWidth:         1080,
      canvasHeight:        1080,
      topLineY:            80,
      bottomLineFromBottom: 40,
      quoteAreaTop:        200,
      bookAreaFromBottom:  80,
      maxQuoteChars:       120,
    ),
    '4:5': _MonoRatioVariant(
      canvasWidth:         1080,
      canvasHeight:        1350,
      topLineY:            100,
      bottomLineFromBottom: 50,
      quoteAreaTop:        240,
      bookAreaFromBottom:  100,
    ),
  };
}

// ── 보조 데이터 클래스 ────────────────────────────────────────

final class _LineSpec {
  const _LineSpec({
    required this.marginHorizontal,
    this.y,
    this.fromBottom,
    required this.height,
  });
  final double  marginHorizontal;
  final double? y;            // topLine에서 사용
  final double? fromBottom;   // bottomLine에서 사용
  final double  height;
}

final class _MonoQuoteAreaSpec {
  const _MonoQuoteAreaSpec({
    required this.paddingHorizontal,
    required this.paddingTop,
    required this.fontFamily,
    required this.letterSpacingEm,
    required this.noOpeningQuote,
  });
  final double paddingHorizontal;
  final double paddingTop;
  final String fontFamily;
  final double letterSpacingEm;
  final bool   noOpeningQuote;
}

final class _MonoBookAreaSpec {
  const _MonoBookAreaSpec({
    required this.paddingHorizontal,
    required this.fromBottom,
    required this.titlePrefix,
    required this.titleFontFamily,
    required this.titleFontSize,
    required this.authorFontFamily,
    required this.authorFontSize,
    required this.separator,
    required this.letterSpacingEm,
  });
  final double paddingHorizontal;
  final double fromBottom;
  final String titlePrefix;
  final String titleFontFamily;
  final double titleFontSize;
  final String authorFontFamily;
  final double authorFontSize;
  final String separator;
  final double letterSpacingEm;
}

final class _MonoWatermarkSpec {
  const _MonoWatermarkSpec({
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

final class _MonoLayout {
  const _MonoLayout({
    required this.topLine,
    required this.bottomLine,
    required this.quoteArea,
    required this.bookArea,
    required this.watermarkArea,
  });
  final _LineSpec           topLine;
  final _LineSpec           bottomLine;
  final _MonoQuoteAreaSpec  quoteArea;
  final _MonoBookAreaSpec   bookArea;
  final _MonoWatermarkSpec  watermarkArea;
}

final class _MonoColors {
  const _MonoColors({
    required this.background,
    required this.quoteText,
    required this.bookTitleText,
    required this.authorText,
    required this.lineColor,
    required this.bookTitleHighlight,
    required this.watermarkText,
  });
  final Color background;
  final Color quoteText;
  final Color bookTitleText;
  final Color authorText;
  final Color lineColor;
  final Color bookTitleHighlight;
  final Color watermarkText;
}

final class _MonoRatioVariant {
  const _MonoRatioVariant({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.topLineY,
    required this.bottomLineFromBottom,
    required this.quoteAreaTop,
    required this.bookAreaFromBottom,
    this.maxQuoteChars,
  });
  final double canvasWidth;
  final double canvasHeight;
  final double topLineY;
  final double bottomLineFromBottom;
  final double quoteAreaTop;
  final double bookAreaFromBottom;
  final int?   maxQuoteChars;
}
```

---

## 7. ASCII 레이아웃 미리보기 (9:16)

```
╔══════════════════════════╗
║ ────────────────────── ║  ← 상단 1px 라인 (vibrant 컬러)
║                          ║
║                          ║
║   우리는 누군가의          ║
║   가장 좋은 시절을         ║
║   잘 모르는 채로도,        ║  ← Noto Serif KR Medium
║   그 사람을 사랑할         ║    #FAFAF8, 22px
║   수 있다.                ║    (따옴표 없음)
║                          ║
║                          ║
║                          ║
║                          ║
║   — 작별하지 않는다        ║  ← em dash + 책 제목
║   한강 · 문학동네           ║  ← primary[300], letter-spacing wide
║                          ║
║                    [책귀]║
║ ────────────────────── ║  ← 하단 1px 라인 (vibrant 컬러)
╚══════════════════════════╝
   배경: #0F0F0F
```
