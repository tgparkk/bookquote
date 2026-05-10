# T5 — 타이포 (Typography) 템플릿 명세

**핵심 결**: 텍스트만. 시(詩)처럼 배치. 한 줄 2–4자, 행간 크게. 문장이 조각이 된다.
**영감**: 한국 현대시 시집 편집, 타이포그래피 포스터, Emigre 매거진 레이아웃
**페르소나 적합도**: 이수연(대학생) ★★★ — 시 감성 인용구에 최적
**중요 제약**: 단문 전용 (≤50자). 51자 이상 시 비활성화 또는 대체 알림.

---

## 1. 시각 원칙

- **텍스트가 조각(sculpture)이다.** 문장을 단어 단위로 줄바꿈해 시각적 형태를 만든다.
- **행간이 숨이다.** lineHeight 2.2로 텍스트 사이에 공기가 흐른다.
- **색은 mid-tone 하나.** 너무 밝지도 어둡지도 않은 중간 톤 배경 — 표지 팔레트의 중간 지점.
- **책 정보는 최소화.** 이 템플릿에서 책 정보는 아주 작게, 아래 구석에.
- **폰트 크기가 임팩트.** 28–36px 대형 세리프로 각 단어가 무게를 가진다.

---

## 2. 단문 전용 제약 처리

### 50자 초과 시 동작

```dart
// 카드 편집기에서 템플릿 선택 시
if (quote.text.length > TypographyTemplate.maxCharCount) {
  // T5 템플릿 카드에 오버레이 표시
  showTemplateDisabledOverlay(
    message: '타이포 템플릿은 50자 이하 짧은 문장에 어울려요',
    suggestion: '이 문장엔 미니멀이나 모노 템플릿을 추천해요',
    alternativeTemplates: ['minimal', 'mono'],
  );
}
```

### 이상적 인용구 예시 (T5 적합)

```
"그래도 살아있다."          (7자)  ← 완벽
"살아있다는 것이 슬프다."   (13자) ← 좋음
"우리는 모두 각자의 별에서  (40자) ← 가능
온 어린왕자다."
"우리는 누군가의 가장 좋은  (50자) ← 한계
시절을 잘 모르는 채로도,
그 사람을 사랑할 수 있다."
```

---

## 3. 시(詩) 배치 알고리즘

```
입력: "우리는 누군가의 가장 좋은 시절을"

목표: 각 줄 2–4단어 (한자어·고유명사는 함께)

단계 1: 형태소 분석 없이 단순 규칙 적용
  - 조사·어미는 앞 단어에 붙임
  - 쉼표(,) 직후 강제 줄바꿈
  - 마침표·느낌표·물음표 직후 강제 줄바꿈

단계 2: 줄당 글자 수 목표 (폰트 크기별)
  - 28px: 줄당 4–6자 목표
  - 36px: 줄당 3–4자 목표

단계 3: 시각적 균형 조정
  - 마지막 줄이 너무 짧으면 (1–2자) 앞 줄에서 단어 내림
  - 가장 긴 줄이 카드 너비 초과 시 폰트 축소

출력 예시 (36px):
  우리는
  누군가의
  가장 좋은
  시절을
```

---

## 4. 색 토큰 매핑

| 영역 | 소스 | 근거 |
|------|------|------|
| 카드 배경 | `palette.muted` (HSL L 조정 40–55) | 표지 mid-tone — 너무 밝거나 어둡지 않은 중간 |
| 인용구 텍스트 | `palette.textOnBackground` | WCAG AA 자동 보장 |
| 책 제목·저자 | `palette.subtextOnBackground` 70% opacity | 아주 흐리게 — 텍스트가 주인공 |
| 배경 보조 그라데이션 | `palette.darkVibrant` 15% → 0% | 상단에서 아래로 아주 미묘하게 |
| 워터마크 | `palette.textOnBackground` 20% opacity | 거의 안 보임 |

**mid-tone 배경 계산 방식**:
```
HSL 변환 후:
  L(밝기) > 65 이면: L을 45–55 범위로 내림
  L(밝기) < 25 이면: L을 35–45 범위로 올림
  25 ≤ L ≤ 65 이면: 그대로 사용 (이미 mid-tone)
채도(S) < 10이면: colors.primary[600] 폴백
```

---

## 5. 영역 구성 — 9:16 기준 (1080×1920px)

```
┌─────────────────────────┐
│                         │
│                         │
│                         │
│   우리는                │
│                         │
│   누군가의               │
│                         │  ← 행간 2.2 — 줄 사이에 공기
│   가장 좋은              │
│                         │
│   시절을                │
│                         │
│                         │
│                         │
│           작별하지 않는다│  ← 책 정보 (아주 작게, 우하단)
│                한강 [책귀│
└─────────────────────────┘
  배경: palette.muted mid-tone
```

### 영역 좌표 (9:16, 1080×1920px)

| 영역 | x | y | width | height | 비고 |
|------|---|---|-------|--------|------|
| quoteArea | 96 | 세로중앙 - quoteHeight/2 | 888 | 가변 | 수직 중앙 정렬 |
| bookArea | 1080-96 | 1920-120 | auto | auto | 우하단 오른쪽 정렬 |
| watermark | bookArea.x | bookArea.y + 24 | auto | 24 | 책 정보 바로 아래 |

**수직 중앙 정렬 이유**: T5는 텍스트가 조각처럼 공중에 떠 있는 느낌이어야 함. 상단 고정이 아닌 수직 중앙.

### quoteArea 내부 — 시 배치

| 요소 | 폰트 | 크기 | 행간 | 정렬 |
|------|------|------|------|------|
| 인용구 각 줄 | NotoSerifKR-Bold | 28–36px | 2.2 | 좌측 정렬 |
| 좌측 들여쓰기 | — | — | — | 0 (들여쓰기 없음) |

**폰트 크기 결정 규칙** (T5 전용, 일반 getQuoteFontSize() 미사용):
```dart
double getTypographyFontSize(int charCount) {
  if (charCount <= 15) return 36.0;   // 아주 짧음 → 임팩트 최대
  if (charCount <= 30) return 28.0;   // 적당히 짧음
  return 22.0;                         // 50자 접근 → 조금 줄임
  // 50자 초과는 이 템플릿 비활성화이므로 도달 안 함
}
```

---

## 6. 비율 변형 (Variants)

### 1:1 (1080×1080px)

- quoteArea 수직 중앙 (전체 높이의 40–50% 위치)
- bookArea: 우하단 (x: 1080-80, y: 1080-80)
- 최대 인용구: 30자 권장 (1:1은 공간이 좁아 36px로 30자면 꽉 참)

### 4:5 (1080×1350px)

- 9:16과 거의 동일
- quoteArea 수직 중앙 (y: 약 350 기준)

---

## 7. Dart 클래스 명세

```dart
import 'package:flutter/painting.dart';
import '../tokens.dart';

/// T5 전용 폰트 크기 계산 (일반 getQuoteFontSize() 미사용)
double getTypographyFontSize(int charCount) {
  if (charCount <= 15) return 36.0;   // 아주 짧음 → 임팩트 최대
  if (charCount <= 30) return 28.0;   // 적당히 짧음
  return 22.0;                         // 50자 접근 → 조금 줄임
  // 50자 초과는 이 템플릿 비활성화이므로 도달 안 함
}

/// 인용구 텍스트를 시(詩) 배치용으로 줄 분리
/// [text] 원본 인용구
/// [maxCharsPerLine] 줄당 최대 글자 수 (36px 기준 6자)
List<String> splitIntoPoetryLines(String text, int maxCharsPerLine) {
  // 쉼표·마침표·느낌표·물음표 직후 강제 줄바꿈
  final forcedBreaks = text.replaceAllMapped(
    RegExp(r'([,，.。!！?？])\s*'),
    (m) => '${m[1]}\n',
  );
  final words = forcedBreaks.split(RegExp(r'[\s\n]+'));
  final lines = <String>[];
  var current = '';

  for (final word in words) {
    if ((current + word).length > maxCharsPerLine && current.isNotEmpty) {
      lines.add(current.trim());
      current = '$word ';
    } else {
      current += '$word ';
    }
  }
  if (current.trim().isNotEmpty) lines.add(current.trim());

  return lines;
}

class TypographyTemplate {
  static const String id          = 'typography';
  static const String name        = '타이포';
  static const String description = '문장이 시가 된다. 단문 전용. 텍스트가 조각처럼 공중에 뜬다.';
  static const String thumbnail   = 'template-typography-thumb.png';

  /// 이 템플릿을 사용할 수 있는 최대 글자 수
  static const int maxCharCount = 50;

  static const _TypoLayout layout = _TypoLayout(
    quoteArea: _TypoQuoteAreaSpec(
      paddingHorizontal: 96,
      verticalAlign: VerticalAlign.center,   // 수직 중앙 정렬
      fontFamily: AppFonts.quoteBold,
      lineHeight: AppLineHeight.poetry,      // 2.2
      maxCharsPerLine: 6,                    // 36px 기준 줄당 최대
    ),
    bookArea: _TypoBookAreaSpec(
      position: WatermarkPosition.bottomRight,
      marginRight: 96,
      marginBottom: 96,
      titleFontFamily: AppFonts.ui,
      titleFontSize: AppFontSize.xs,         // 11px — 아주 작게
      authorFontFamily: AppFonts.ui,
      authorFontSize: AppFontSize.xs,
      opacity: 0.60,
    ),
    watermarkArea: _TypoWatermarkSpec(
      position: WatermarkPosition.bottomRight,
      marginRight: 96,
      marginBottom: 72,
      fontSize: AppFontSize.xxs,
      opacity: 0.20,
    ),
  );

  /// 팔레트를 받아 색 매핑 반환
  /// background는 palette.muted를 toMidTone()으로 중간 밝기로 조정
  static _TypoColors colorMapping(ExtractedPalette palette) => _TypoColors(
    background:    toMidTone(palette.muted),
    quoteText:     palette.textOnBackground,
    bookText:      palette.subtextOnBackground,
    watermarkText: palette.textOnBackground,
  );

  static const Map<String, _TypoRatioVariant> variants = {
    '9:16': _TypoRatioVariant(
      canvasWidth:    1080,
      canvasHeight:   1920,
      maxCharsPerLine: 6,
    ),
    '1:1': _TypoRatioVariant(
      canvasWidth:          1080,
      canvasHeight:         1080,
      maxCharsPerLine:      5,
      recommendedMaxChars:  30,
    ),
    '4:5': _TypoRatioVariant(
      canvasWidth:    1080,
      canvasHeight:   1350,
      maxCharsPerLine: 6,
    ),
  };
}

/// 수직 정렬 모드
enum VerticalAlign { top, center, bottom }

// ── 보조 데이터 클래스 ────────────────────────────────────────

final class _TypoQuoteAreaSpec {
  const _TypoQuoteAreaSpec({
    required this.paddingHorizontal,
    required this.verticalAlign,
    required this.fontFamily,
    required this.lineHeight,
    required this.maxCharsPerLine,
  });
  final double        paddingHorizontal;
  final VerticalAlign verticalAlign;
  final String        fontFamily;
  final double        lineHeight;
  final int           maxCharsPerLine;
}

final class _TypoBookAreaSpec {
  const _TypoBookAreaSpec({
    required this.position,
    required this.marginRight,
    required this.marginBottom,
    required this.titleFontFamily,
    required this.titleFontSize,
    required this.authorFontFamily,
    required this.authorFontSize,
    required this.opacity,
  });
  final WatermarkPosition position;
  final double marginRight;
  final double marginBottom;
  final String titleFontFamily;
  final double titleFontSize;
  final String authorFontFamily;
  final double authorFontSize;
  final double opacity;
}

final class _TypoWatermarkSpec {
  const _TypoWatermarkSpec({
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

final class _TypoLayout {
  const _TypoLayout({
    required this.quoteArea,
    required this.bookArea,
    required this.watermarkArea,
  });
  final _TypoQuoteAreaSpec quoteArea;
  final _TypoBookAreaSpec  bookArea;
  final _TypoWatermarkSpec watermarkArea;
}

final class _TypoColors {
  const _TypoColors({
    required this.background,
    required this.quoteText,
    required this.bookText,
    required this.watermarkText,
  });
  final Color background;
  final Color quoteText;
  final Color bookText;
  final Color watermarkText;
}

final class _TypoRatioVariant {
  const _TypoRatioVariant({
    required this.canvasWidth,
    required this.canvasHeight,
    required this.maxCharsPerLine,
    this.recommendedMaxChars,
  });
  final double canvasWidth;
  final double canvasHeight;
  final int    maxCharsPerLine;
  final int?   recommendedMaxChars;
}

// 유틸 함수 (color_extraction.dart에서 구현)
// palette.muted를 HSL L 40–55 범위로 조정해 mid-tone 배경색 반환
// S < 10이면 AppColors.primary600 폴백
Color toMidTone(Color muted) => throw UnimplementedError(
  'color_extraction.dart의 toMidTone()을 구현하세요',
);
```

---

## 8. ASCII 레이아웃 미리보기 (9:16, "우리는 누군가의 가장 좋은 시절을" 예시)

```
╔══════════════════════════╗
║                          ║  ← 배경: palette.muted mid-tone
║                          ║
║                          ║
║                          ║
║   우리는                 ║
║                          ║  ← 행간 2.2 (공기)
║   누군가의               ║
║                          ║
║   가장 좋은              ║  ← NotoSerifKR-Bold, 28px
║                          ║
║   시절을                 ║
║                          ║
║                          ║
║                          ║
║                          ║
║        작별하지 않는다   ║  ← 11px, opacity 60%
║               한강 [책귀]║  ← 우하단 정렬
╚══════════════════════════╝
```

---

## 9. 비활성화 UI 가이드

51자 이상 인용구에서 T5 카드 미리보기에 표시할 오버레이:

```
┌─────────────────────────┐
│  (흐릿한 미리보기)        │
│                          │
│  ┌──────────────────┐   │
│  │ 이 문장은 타이포  │   │
│  │ 템플릿에 길어요.  │   │
│  │                  │   │
│  │ 미니멀 또는      │   │
│  │ 모노를 추천해요  │   │
│  │                  │   │
│  │ [미니멀로 보기]  │   │
│  └──────────────────┘   │
└─────────────────────────┘
```
