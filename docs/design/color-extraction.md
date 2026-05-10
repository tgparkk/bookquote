# 표지 → 팔레트 추출 알고리즘 명세

**목적**: 알라딘 CDN 표지 이미지 URL을 입력받아 5색 팔레트를 출력한다.
이 팔레트는 T2(따뜻), T4(표지발췌) 템플릿의 배경·텍스트 색으로 직접 사용된다.

---

## 1. 입출력 명세

### 입력

```dart
class ColorExtractionInput {
  const ColorExtractionInput({
    required this.imageUrl,
    this.quality = 5,
  });

  /// 알라딘 CDN URL
  /// 예: "https://image.aladin.co.kr/product/32803/95/cover500/k232939267_1.jpg"
  final String imageUrl;

  /// 추출 품질 (1=빠름/저품질, 10=느림/고품질). 기본값: 5
  final int quality;
}
```

### 출력

```dart
// tokens.dart의 ExtractedPalette 클래스 사용
// Color(0xFFRRGGBB) 형식

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

  final Color dominant;            // 가장 지배적인 색 (배경용)
  final Color secondary;           // 두 번째 지배적인 색
  final Color vibrant;             // 밝은 진동 색 (accent)
  final Color darkVibrant;         // 어두운 진동 색
  final Color muted;               // 무채색 계열 뮤트
  final Color textOnBackground;    // WCAG AA 보장 텍스트 색 (자동 계산)
  final Color subtextOnBackground; // WCAG AA 보장 보조 텍스트 색 (자동 계산)
}
```

---

## 2. 라이브러리 비교

### 추천: `palette_generator` (Google 공식)

```yaml
# pubspec.yaml
dependencies:
  palette_generator: ^0.3.3
```

| 항목 | 평가 |
|------|------|
| Flutter 지원 | 공식 Google 패키지 (flutter/packages 레포) |
| 알고리즘 | K-means 기반 색 양자화 |
| 출력 | PaletteColor 목록 — dominant / vibrant / muted / lightVibrant / darkVibrant / lightMuted / darkMuted |
| Dart-only | 네이티브 브릿지 불필요 — 플랫폼 채널 없음 |
| 성능 | Isolate 사용 권장 (메인 스레드 블로킹 방지) |
| pub.dev | https://pub.dev/packages/palette_generator |

**장점**: Flutter 전 플랫폼(iOS/Android/Web/Desktop) 동일 동작. 플랫폼 분기 불필요.
**단점**: JS/네이티브 대비 순수 Dart 구현이라 초대형 이미지는 약간 느림 → 전처리로 해결.

---

### 비교 옵션 B: `image` 패키지 + 직접 K-means

```yaml
dependencies:
  image: ^4.1.7
```

| 항목 | 평가 |
|------|------|
| 용도 | 저수준 픽셀 접근, 직접 K-means 구현 시 |
| 장점 | 완전한 커스텀 제어 |
| 단점 | 추출 로직 직접 구현 필요 — 개발 비용 높음 |
| 추천 여부 | palette_generator로 충분하면 불필요 |

---

### 비교 옵션 C: `flutter_image_compress` (전처리용)

```yaml
dependencies:
  flutter_image_compress: ^2.1.0
```

| 항목 | 평가 |
|------|------|
| 용도 | 팔레트 추출 전 이미지 축소 (성능 최적화) |
| 권장 | 고해상도 원본 이미지 처리 시 조합 사용 |
| 방식 | 추출 전 100×100px으로 리사이즈 → palette_generator 입력 |

---

### 최종 추천: `palette_generator` + `cached_network_image`

**이유**:
1. Google 공식 패키지 — Flutter 생태계 표준
2. 플랫폼 분기 없음 — iOS/Android 동일 코드
3. Flutter의 Skia 렌더링과 동일 파이프라인에서 색 추출
4. `cached_network_image`와 조합 시 네트워크 요청 중복 없음

---

## 3. 전체 알고리즘 흐름 (의사코드 — Dart)

```dart
Future<ExtractedPalette> extractPalette(String imageUrl) async {
  // 1. 이미지 로드 (캐시 우선)
  //    실패 시: return fallbackPalettes['coverExtract']!
  //    타임아웃: 3초 → 실패로 처리
  final imageProvider = CachedNetworkImageProvider(imageUrl);

  // 2. palette_generator로 팔레트 추출
  //    Isolate에서 실행 권장 (메인 스레드 보호)
  PaletteGenerator generator;
  try {
    generator = await PaletteGenerator.fromImageProvider(
      imageProvider,
      size: const Size(100, 100),   // 성능 최적화 — 작게 리사이즈 후 추출
      maximumColorCount: 16,
    );
  } catch (_) {
    return fallbackPalettes['coverExtract']!;
  }

  // 3. palette_generator 결과 → ExtractedPalette 매핑
  //    null 슬롯은 fallback 팔레트 해당 키 값으로 대체
  final fallback = fallbackPalettes['coverExtract']!;

  final dominant    = generator.dominantColor?.color      ?? fallback.dominant;
  final secondary   = generator.lightMutedColor?.color    ?? fallback.secondary;
  final vibrant     = generator.vibrantColor?.color
                   ?? generator.lightVibrantColor?.color  ?? fallback.vibrant;
  final darkVibrant = generator.darkVibrantColor?.color   ?? fallback.darkVibrant;
  final muted       = generator.mutedColor?.color
                   ?? generator.darkMutedColor?.color     ?? fallback.muted;

  // 4. WCAG AA 대비 보장 텍스트 색 계산
  final textOnBg = ensureContrast(
    background:  dominant,
    foreground:  _pickBestCandidate(dominant, [
      AppColors.primary900,
      AppColors.secondary200,
    ]),
    minRatio: 4.5,
  );

  final subtextOnBg = ensureContrast(
    background:  dominant,
    foreground:  _pickBestCandidate(dominant, [
      AppColors.primary700,
      AppColors.primary400,
      AppColors.secondary400,
    ]),
    minRatio: 3.0,   // 보조 텍스트는 AA Large 기준 (3:1)
  );

  return ExtractedPalette(
    dominant:            dominant,
    secondary:           secondary,
    vibrant:             vibrant,
    darkVibrant:         darkVibrant,
    muted:               muted,
    textOnBackground:    textOnBg,
    subtextOnBackground: subtextOnBg,
  );
}
```

---

## 4. WCAG AA 대비 보장 함수 명세

```dart
/// 배경색 위에서 WCAG AA 기준을 만족하는 텍스트 색을 반환한다.
/// foreground가 minRatio를 만족하면 그대로 반환.
/// 미달 시: AppColors.primary900(#1C1917) 또는 AppColors.secondary200(#FAFAF8) 중
/// 대비비가 더 높은 쪽 반환.
///
/// [background]  배경 Color
/// [foreground]  텍스트 Color 후보
/// [minRatio]    최소 대비비 (본문: 4.5, 보조: 3.0, 큰 텍스트: 3.0)
Color ensureContrast(
  Color background,
  Color foreground, {
  double minRatio = 4.5,
}) {
  final ratio = contrastRatio(background, foreground);
  if (ratio >= minRatio) return foreground;

  // 폴백: 흰색 계열 vs 검정 계열 중 더 높은 대비 쪽
  final darkRatio  = contrastRatio(background, AppColors.primary900);
  final lightRatio = contrastRatio(background, AppColors.secondary200);
  return darkRatio >= lightRatio ? AppColors.primary900 : AppColors.secondary200;
}
```

### 대비비 계산 (WCAG 2.1)

```dart
/// WCAG 2.1 기준 상대 휘도 계산
double relativeLuminance(Color color) {
  double linearize(double channel) {
    final c = channel / 255.0;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055).pow(2.4);
  }
  return 0.2126 * linearize(color.red.toDouble())
       + 0.7152 * linearize(color.green.toDouble())
       + 0.0722 * linearize(color.blue.toDouble());
}

/// WCAG 2.1 기준 대비비 계산
double contrastRatio(Color color1, Color color2) {
  final l1 = relativeLuminance(color1);
  final l2 = relativeLuminance(color2);
  final lighter = l1 > l2 ? l1 : l2;
  final darker  = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}
```

**WCAG 기준 요약**:
- AA 본문 (14px 이하): 대비비 4.5:1 이상
- AA Large (18px 이상 또는 14px bold): 대비비 3.0:1 이상
- AAA 본문: 7.0:1 이상 (인용구 권장 목표)

---

## 5. 배경색 밝기 판단 → 텍스트 색 자동 결정

```dart
/// 배경이 밝은지 어두운지 판단해 기본 텍스트 색을 반환.
/// ensureContrast()로 최종 검증.
Color getTextColorForBackground(Color background) {
  final luminance = relativeLuminance(background);
  // 0.18 기준 (지각 기반 — 0.5 기준보다 정확)
  return luminance > 0.18
      ? AppColors.primary900    // #1C1917 — 어두운 텍스트
      : AppColors.secondary200; // #FAFAF8 — 밝은 텍스트
}
```

---

## 6. 유틸 함수 — 배경 조명·mid-tone 조정

```dart
/// T2 따뜻 템플릿 배경용: dominant를 HSL L 92–96으로 밝힘
/// S < 10이면 AppColors.secondary400 폴백
Color lightenToBackground(Color dominant) {
  final hsl = HSLColor.fromColor(dominant);
  if (hsl.saturation < 0.10) return AppColors.secondary400;
  return hsl.withLightness(0.94).toColor();
}

/// T5 타이포 템플릿 배경용: muted를 HSL L 40–55으로 조정
/// S < 10이면 AppColors.primary600 폴백
Color toMidTone(Color muted) {
  final hsl = HSLColor.fromColor(muted);
  if (hsl.saturation < 0.10) return AppColors.primary600;
  final clampedL = hsl.lightness.clamp(0.40, 0.55);
  return hsl.withLightness(clampedL).toColor();
}
```

---

## 7. 템플릿별 팔레트 슬롯 활용 방식

| 팔레트 슬롯 | T1 미니멀 | T2 따뜻 | T3 모노 | T4 표지발췌 | T5 타이포 |
|------------|---------|--------|--------|----------|---------|
| `dominant` | 미사용 (고정 `#FAFAF8`) | lightenToBackground() 기준 | 미사용 (고정 `#0F0F0F`) | 전체 배경 overlay | toMidTone()의 muted 기준 |
| `vibrant` | 1px 구분선 색 | 짧은 구분선 색 | accent 라인 | 그라데이션 overlay stop | 없음 |
| `darkVibrant` | 책 제목 텍스트 색 | 책 제목 텍스트 색 | 없음 | 그라데이션 어두운 쪽 | 배경 보조 |
| `textOnBackground` | 인용구 텍스트 | 인용구 텍스트 | 고정 `#FAFAF8` | 인용구 텍스트 | 인용구 텍스트 |
| `subtextOnBackground` | 저자·제목 | 저자·제목 | `AppColors.primary300` | 저자·제목 | 없음 |

---

## 8. 표지 이미지 캐시 전략

알라딘 CDN URL은 동일 책이면 동일 URL → 팔레트 추출 결과를 캐시해도 안전.

```dart
// 권장 캐시 키 전략
final cacheKey = 'palette:$imageUrl';

// 옵션 A: flutter_cache_manager 활용
//   cached_network_image와 통합 시 자동 캐시
//   TTL: 30일 (책 표지는 거의 변경되지 않음)
//   패키지: cached_network_image: ^3.3.1

// 옵션 B: shared_preferences 또는 hive에 직렬화 저장
//   ExtractedPalette → Map<String, int> (Color.value 저장)
//   최대 캐시 항목: 500개 (LRU 직접 구현 또는 hive eviction)

// 색 직렬화 예시
Map<String, int> serializePalette(ExtractedPalette p) => {
  'dominant':            p.dominant.value,
  'secondary':           p.secondary.value,
  'vibrant':             p.vibrant.value,
  'darkVibrant':         p.darkVibrant.value,
  'muted':               p.muted.value,
  'textOnBackground':    p.textOnBackground.value,
  'subtextOnBackground': p.subtextOnBackground.value,
};

ExtractedPalette deserializePalette(Map<String, int> m) => ExtractedPalette(
  dominant:            Color(m['dominant']!),
  secondary:           Color(m['secondary']!),
  vibrant:             Color(m['vibrant']!),
  darkVibrant:         Color(m['darkVibrant']!),
  muted:               Color(m['muted']!),
  textOnBackground:    Color(m['textOnBackground']!),
  subtextOnBackground: Color(m['subtextOnBackground']!),
);
```

---

## 9. 추출 실패·이미지 없음 시 폴백 처리

```dart
/// 폴백 포함 팔레트 획득
/// [imageUrl] null이면 즉시 폴백 반환
/// [templateId] fallbackPalettes 키 ('minimal' | 'warm' | 'mono' | 'coverExtract' | 'typography')
Future<ExtractedPalette> getPaletteWithFallback(
  String? imageUrl,
  String templateId,
) async {
  if (imageUrl == null) {
    return fallbackPalettes[templateId] ?? fallbackPalettes['coverExtract']!;
  }

  try {
    return await extractPalette(imageUrl);
  } catch (_) {
    return fallbackPalettes[templateId] ?? fallbackPalettes['coverExtract']!;
  }
}
```

**각 템플릿 폴백 팔레트 근거**:
- `minimal`: Paper White 계열 — 아무 책이나 어울리는 중립 배경
- `warm`: Cream 계열 — 따뜻 템플릿 기본 감성 유지
- `mono`: Ink Black — 모노는 고정 배경이므로 팔레트 추출 미사용
- `coverExtract`: `Color(0xFF3D2817)` 기반 갈색 계열 — 한국 문학 표지 평균 톤
- `typography`: 어두운 잉크 계열 — 시(詩) 배치 시 진지한 분위기 유지

---

## 10. 전체 Dart 함수 시그니처 요약

```dart
// 표지 팔레트 추출 메인 함수
Future<ExtractedPalette> extractPalette(String imageUrl)

// WCAG 대비 보장 유틸
Color ensureContrast(Color background, Color foreground, {double minRatio = 4.5})

// 상대 휘도 계산 (WCAG 2.1)
double relativeLuminance(Color color)

// 대비비 계산
double contrastRatio(Color color1, Color color2)

// 배경 밝기 기반 텍스트 색 자동 선택
Color getTextColorForBackground(Color background)

// 폴백 포함 팔레트 획득
Future<ExtractedPalette> getPaletteWithFallback(String? imageUrl, String templateId)

// T2 따뜻 배경용: dominant → L 92–96으로 밝힘
Color lightenToBackground(Color dominant)

// T5 타이포 배경용: muted → L 40–55으로 mid-tone 조정
Color toMidTone(Color muted)
```
