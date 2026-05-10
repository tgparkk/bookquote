# 책귀 디자인 토큰 명세

**버전**: 1.1.0 (2026-05-09 Flutter 스택 전환)
**용도**: Flutter 환경에서 직접 import 가능한 토큰 정의
**실제 코드**: `tokens.dart` 참조 (`tokens.ts`는 참조용 보존)

---

## 1. 색 토큰 (Color Tokens)

### 1.1 Primary — Ink 계열 (따뜻한 검정)

책의 활자. 오래된 잉크. 순검정보다 갈색 기운.

| 토큰 | Hex | 용도 |
|------|-----|------|
| `colors.primary[50]` | `#FAF8F5` | 극히 연한 잉크 워시 (hover 배경 등) |
| `colors.primary[100]` | `#F0EDE6` | 연한 잉크 (구분선, 비활성 배경) |
| `colors.primary[200]` | `#D6D0C4` | 보조 텍스트 플레이스홀더 |
| `colors.primary[300]` | `#B5ADA0` | 비활성 텍스트 |
| `colors.primary[400]` | `#8C8478` | 서브 레이블 |
| `colors.primary[500]` | `#635B50` | 보조 텍스트 |
| `colors.primary[600]` | `#4A4339` | 본문 텍스트 (보조) |
| `colors.primary[700]` | `#342E26` | 본문 텍스트 (기본) |
| `colors.primary[800]` | `#241F18` | 제목 텍스트 |
| `colors.primary[900]` | `#1C1917` | 최대 강도 (모노 템플릿 배경, 최고 강조) |

**결정 근거**: 900이 브랜드 Ink Black. 50~200은 종이 느낌 배경으로도 활용.

---

### 1.2 Secondary — Paper 계열 (따뜻한 흰색)

종이의 흰색. 임상적 순백이 아닌 책 페이지의 온기.

| 토큰 | Hex | 용도 |
|------|-----|------|
| `colors.secondary[50]` | `#FFFFFF` | 순백 (사용 최소화) |
| `colors.secondary[100]` | `#FDFCFB` | 앱 기본 배경 |
| `colors.secondary[200]` | `#FAFAF8` | T1 미니멀 카드 배경 ★ |
| `colors.secondary[300]` | `#F5F1EB` | 약간 크림화 |
| `colors.secondary[400]` | `#EDE5D8` | T2 따뜻 배경 베이스 |
| `colors.secondary[500]` | `#E2D9C8` | 따뜻 배경 중간 |
| `colors.secondary[600]` | `#D4C9B3` | 크림 배경 강조 |
| `colors.secondary[700]` | `#C2B49A` | 구분선·테두리 |
| `colors.secondary[800]` | `#A89880` | 진한 베이지 |
| `colors.secondary[900]` | `#8B7D65` | 짙은 크림 (텍스트 위계 보조) |

**결정 근거**: 200이 T1 미니멀 배경 핵심값. 400은 T2 따뜻 배경.

---

### 1.3 Accent — Copper 계열

구리의 따뜻함과 금속성 정밀함. 브랜드 강조.

| 토큰 | Hex | 용도 |
|------|-----|------|
| `colors.accent[50]` | `#FDF6ED` | 액센트 극히 연한 배경 |
| `colors.accent[100]` | `#FAEBD6` | 액센트 연한 배경 |
| `colors.accent[200]` | `#F0D4AA` | 액센트 연함 |
| `colors.accent[300]` | `#E0B87A` | 액센트 보조 |
| `colors.accent[400]` | `#CC9A4E` | 액센트 중간 |
| `colors.accent[500]` | `#B87333` | Copper 기본값 ★ (브랜드 액센트) |
| `colors.accent[600]` | `#9A5F28` | 액센트 어두움 |
| `colors.accent[700]` | `#7D4D1E` | 액센트 진함 |
| `colors.accent[800]` | `#613C16` | 액센트 극진함 |
| `colors.accent[900]` | `#4A2D0E` | 액센트 최고 강도 |

**결정 근거**: 500이 `#FAFAF8` 배경 위 대비비 4.6:1 (WCAG AA 통과). 링크·CTA·강조 텍스트에 사용.

---

### 1.4 Neutral — 순수 회색 계열

배경·UI 요소용. 온도 없는 회색.

| 토큰 | Hex | 용도 |
|------|-----|------|
| `colors.neutral[50]` | `#F9F9F9` | |
| `colors.neutral[100]` | `#F3F3F3` | |
| `colors.neutral[200]` | `#E5E5E5` | 구분선 |
| `colors.neutral[300]` | `#D4D4D4` | 테두리 |
| `colors.neutral[400]` | `#A3A3A3` | 비활성 아이콘 |
| `colors.neutral[500]` | `#737373` | 보조 텍스트 |
| `colors.neutral[600]` | `#525252` | |
| `colors.neutral[700]` | `#404040` | |
| `colors.neutral[800]` | `#262626` | |
| `colors.neutral[900]` | `#171717` | |

---

### 1.5 Semantic 색

| 토큰 | Hex | 용도 |
|------|-----|------|
| `colors.semantic.success` | `#4A7C59` | 성공 (저장됨, 공유 완료) |
| `colors.semantic.successLight` | `#EAF2EC` | 성공 배경 |
| `colors.semantic.error` | `#C0392B` | 에러 |
| `colors.semantic.errorLight` | `#FDECEA` | 에러 배경 |
| `colors.semantic.warning` | `#C87F0A` | 경고 |
| `colors.semantic.warningLight` | `#FEF3E2` | 경고 배경 |
| `colors.semantic.info` | `#2563EB` | 정보 |
| `colors.semantic.infoLight` | `#EFF6FF` | 정보 배경 |

---

## 2. 폰트 시스템 (Typography Tokens)

### 2.1 폰트 패밀리

| 토큰 | 값 | 용도 |
|------|-----|------|
| `fonts.quote` | `'NotoSerifKR-Regular'` | 인용구 기본 |
| `fonts.quoteMedium` | `'NotoSerifKR-Medium'` | 인용구 중간 강조 |
| `fonts.quoteBold` | `'NotoSerifKR-Bold'` | 인용구 강조 |
| `fonts.ui` | `'Pretendard-Regular'` | UI 레이블·버튼 |
| `fonts.uiMedium` | `'Pretendard-Medium'` | UI 중간 강조 |
| `fonts.uiSemiBold` | `'Pretendard-SemiBold'` | UI 제목·탭 |
| `fonts.uiBold` | `'Pretendard-Bold'` | UI 강조 |
| `fonts.enSerif` | `'LibreBaskerville-Regular'` | 영문 인용구 |
| `fonts.enSerifItalic` | `'LibreBaskerville-Italic'` | 영문 인용구 이탤릭 |

**Flutter 폰트 로드 방식**:
- Noto Serif KR: `google_fonts` 패키지 또는 `assets/fonts/` 직접 번들 + `pubspec.yaml` fonts 섹션 등록
- Pretendard: `assets/fonts/` 폴더에 직접 번들, `pubspec.yaml` fonts 섹션에 weight별 등록
- Libre Baskerville: `google_fonts` 패키지로 로드

```yaml
# pubspec.yaml 예시
flutter:
  fonts:
    - family: Pretendard
      fonts:
        - asset: assets/fonts/Pretendard-Regular.otf
        - asset: assets/fonts/Pretendard-Medium.otf
          weight: 500
        - asset: assets/fonts/Pretendard-SemiBold.otf
          weight: 600
        - asset: assets/fonts/Pretendard-Bold.otf
          weight: 700
    - family: NotoSerifKR
      fonts:
        - asset: assets/fonts/NotoSerifKR-Regular.otf
        - asset: assets/fonts/NotoSerifKR-Medium.otf
          weight: 500
        - asset: assets/fonts/NotoSerifKR-Bold.otf
          weight: 700
```

### 2.2 Type Scale

| 토큰 | 값(px) | 용도 |
|------|--------|------|
| `fontSize.xxs` | `9` | 워터마크, 법적 표기 |
| `fontSize.xs` | `11` | 인용구 최소 (500자+), 책 출판사·ISBN |
| `fontSize.sm` | `13` | 보조 레이블, 책 저자명 |
| `fontSize.base` | `15` | 인용구 중간 (200자 기준), 본문 UI |
| `fontSize.md` | `17` | 책 제목 (카드 내), 섹션 헤더 |
| `fontSize.lg` | `22` | 인용구 큰 (50자 이하), 화면 제목 |
| `fontSize.xl` | `28` | T5 타이포 템플릿 메인 텍스트 |
| `fontSize.xxl` | `36` | T5 타이포 템플릿 임팩트 텍스트 |

### 2.3 Line Height (행간)

| 토큰 | 값 | 용도 |
|------|-----|------|
| `lineHeight.tight` | `1.3` | 제목, 한 줄 레이블 |
| `lineHeight.normal` | `1.5` | UI 본문 |
| `lineHeight.relaxed` | `1.6` | 인용구 소 (11px) |
| `lineHeight.loose` | `1.7` | 인용구 중 (15px) |
| `lineHeight.spacious` | `1.8` | 인용구 대 (22px) |
| `lineHeight.poetry` | `2.2` | T5 타이포 템플릿 시(詩) 배치 |

### 2.4 Letter Spacing (자간)

| 토큰 | 값(em) | 용도 |
|------|--------|------|
| `letterSpacing.tight` | `-0.02` | 큰 제목, 임팩트 텍스트 |
| `letterSpacing.normal` | `0` | 기본 |
| `letterSpacing.wide` | `0.05` | 책 저자명, 작은 레이블 |
| `letterSpacing.wider` | `0.1` | 워터마크, T3 모노 캡션 |

---

## 3. 여백 시스템 (Spacing Tokens)

4px 기반 그리드. 모든 여백은 이 배수.

| 토큰 | 값(px) | 용도 |
|------|--------|------|
| `spacing[0]` | `0` | |
| `spacing[1]` | `4` | 아이콘 내부 여백 |
| `spacing[2]` | `8` | 인라인 요소 간격 |
| `spacing[3]` | `12` | 컴팩트 레이블 패딩 |
| `spacing[4]` | `16` | 기본 카드 내부 여백 (bookArea) |
| `spacing[6]` | `24` | 섹션 간격 |
| `spacing[8]` | `32` | 카드 인용구 영역 패딩 (quoteArea) |
| `spacing[12]` | `48` | 템플릿 상하 패딩 |
| `spacing[16]` | `64` | 큰 섹션 구분 |

**카드 내부 여백 결정 근거**:
- quoteArea padding = `spacing[8]` (32px): 인용구가 공간을 충분히 쉬어야 함
- bookArea padding = `spacing[4]` (16px): 책 정보는 보조이므로 더 압축
- 1080px 기준이지만 화면 배율로 나누어 사용 (예: 1080/3 = 360pt 기준)

---

## 4. 그림자 토큰 (Shadow Tokens)

Flutter의 `BoxShadow`는 단일 모델로 iOS/Android 분기 없이 동일하게 렌더링됨.
Skia 엔진이 플랫폼 관계없이 처리하므로 플랫폼 분기 코드 불필요.

| 토큰 | offset | blurRadius | color (opacity) | 용도 |
|------|--------|------------|-----------------|------|
| `AppShadows.card` | (0, 2) | 8 | `#1C1917` @ 8% | 카드 컴포넌트 |
| `AppShadows.modal` | (0, 8) | 24 | `#1C1917` @ 16% | 바텀시트·모달 |
| `AppShadows.floating` | (0, 4) | 16 | `#1C1917` @ 12% | FAB·플로팅 버튼 |

```dart
// 사용 예
Container(
  decoration: BoxDecoration(
    boxShadow: [AppShadows.card],
  ),
)
```

---

## 5. 둥근 모서리 토큰 (Border Radius Tokens)

| 토큰 | 값(px) | 용도 |
|------|--------|------|
| `radius.xs` | `2` | 태그·뱃지 |
| `radius.sm` | `4` | 버튼·입력창 |
| `radius.md` | `8` | 카드 내부 요소 |
| `radius.lg` | `12` | 카드·시트 |
| `radius.xl` | `16` | 바텀시트·대형 카드 |
| `radius.full` | `9999` | 완전한 원·알약 모양 |

---

## 6. 카드 크기 상수

| 상수 | 값 | 용도 |
|------|-----|------|
| `cardSize['9:16'].width` | `1080` | 인스타 스토리 |
| `cardSize['9:16'].height` | `1920` | |
| `cardSize['1:1'].width` | `1080` | 인스타 피드 |
| `cardSize['1:1'].height` | `1080` | |
| `cardSize['4:5'].width` | `1080` | 인스타 포스트 |
| `cardSize['4:5'].height` | `1350` | |
