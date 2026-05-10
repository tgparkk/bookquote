# 디자이너 세션 브리프 — 카드 템플릿 5개 + 디자인 시스템

> **사용 방법**: 새 Claude Code 세션을 `C:\GIT` 디렉터리에서 열고, 본 문서 전체를 첫 프롬프트로 붙여넣으세요. (또는 짧게 "이 브리프대로 진행해줘 + 본 파일 경로" 만 줘도 OK — 본 세션이 파일을 읽음)
>
> 가능하면 `oh-my-claudecode:designer` 서브에이전트 활용을 요청하세요. 예: "Agent tool로 designer 서브에이전트 호출해서 진행해줘".

---

## 1. 당신의 역할

당신은 **이 책 인용구 공유 앱의 카드 템플릿·디자인 시스템 담당 디자이너**입니다.

본 프로젝트의 메인 작업자(폴리글랏 백엔드 엔지니어)가 다른 세션에서 코딩을 진행합니다. 당신은 **시각 디자인·디자인 시스템에 집중**하고, 결과물을 메인 세션이 React Native Skia로 구현할 수 있는 형태로 전달합니다.

---

## 2. 프로젝트 컨텍스트

**제품**: 책의 좋은 문장을 사진 한 장으로 저장하고, 예쁜 카드로 만들어 친구·SNS에 공유하는 모바일 앱 (가칭 "책귀")

**목표 사용자**: 연 5–20권 읽는 일반 독서가 (20–30대 여성 우선)

**핵심 메커니즘**: 사용자가 만든 카드가 인스타 스토리·단톡방으로 공유 → 친구 호기심 → 앱 설치 (바이럴)

**차별화 축**: 모바일 퍼스트 + **인스타그래머블한 카드 디자인** (이게 이 앱의 핵심 차별화. 카드 디자인 품질이 곧 앱의 성패)

**관련 문서** (모두 `C:\GIT\quotes-app-discovery\`):
- `architecture.md` — 시스템 아키텍처
- `client-architecture.md` — 클라이언트 구조
- `flows.md` — 사용자 플로우 (특히 4번 Flow B의 카드 편집기)
- `landing-page/app-screens.html` — 화면 모형 (열어서 봐주세요)
- `landing-page/index.html` — 랜딩 페이지

**원본 플랜**: `C:\Users\sttgp\.claude\plans\parallel-sleeping-meadow.md`

---

## 3. 페르소나

**민지, 28세, 마케터, 서울**
- 출퇴근 1시간 동안 종이책 읽음 (자기계발·에세이 위주)
- 인스타 일평균 30분 (피드보다 스토리)
- 좋은 구절 만나면 사진 찍지만 갤러리에 묻힘 → 이게 페인
- 친구 4–5명과 단톡방에서 책 추천 주고받음
- 인스타 스토리에 책 사진 가끔 — "잘난 척 부담"이 정서적 장벽
- 비싼 구독은 부담, 월 4,900원 정도는 OK
- **디자인이 별로면 안 씀** — 인스타 스토리에 올렸을 때 "이거 어떤 앱으로 만든 거다" 티 나면 거부감

**부페르소나: 한지영, 31세, 프리랜서 디자이너**
- 본인이 #책스타그래머 (팔로워 1.5만)
- 직접 카드 만듦 (Adobe Illustrator로 30분~1시간)
- 디자인 품질 임계점 매우 높음
- **결정적 요청: "책 표지 컬러 자동 추출 → 팔레트 생성"** ← V1 핵심 차별화

가상 인터뷰 자세한 내용: `virtual-interviews-2026-05-09.md`

---

## 4. 브랜드 톤·무드

**키워드** (5–8개로 좁히되 시작점):
- 따뜻한 (warm)
- 차분한 (calm)
- 지적인 (intellectual)
- 미니멀한 (minimal)
- 한국적인 (Korean sensibility)
- 정제된 (refined)
- 진솔한 (sincere)

**피해야 할 것**:
- 자극적·시끄러운
- 과한 그라데이션·네온
- 폰트 여러 개 섞기
- 정보 과밀
- 명백한 "앱 생성물" 티

**경쟁/영감 소스**:
- ✅ Letterboxd (영화 리뷰 SNS) — 카드 결, 친구 timeline
- ✅ Co-Star (운세) — 텍스트 디자인, 푸시 카피
- ✅ Notion / Bear (메모) — 미니멀 일관성
- ✅ 인스타 #책스타그램 인기 게시물 30개 — 메인 작업자가 별도로 분석 예정 (아직 안 했음)
- ❌ Goodreads — 디자인 구식, 이걸 닮으면 안 됨

---

## 5. 의뢰 범위 (Scope)

### A. 카드 템플릿 5개 (★ 가장 공들일 부분)

각 템플릿은 명확히 다른 결을 가져야 함. 5개 모두 미니멀이면 의미 없음.

추천 5종 (시작점 — 더 좋은 안 있으면 자유롭게 변경 제안):

1. **미니멀** — 흰 배경, 큰 인용구(serif), 책 표지 작게, 충분한 여백
2. **따뜻** — 베이지/크림 배경, 세리프, 책 정보 크게, 종이 텍스처 느낌
3. **모노** — 검정 배경, 흰 글씨, 강한 대비, 라인 강조
4. **표지 발췌** — 책 표지에서 추출한 색을 그라데이션 배경으로, 표지가 분위기 결정
5. **일러스트** — 추상적 일러스트 + 인용구 (어렵지만 차별화 큼)

각 템플릿마다 다음 명세:
- 비율: 9:16 (인스타 스토리), 1:1 (피드), 4:5 (포스트) — 3가지 모두
- 영역 구성: 인용구 영역, 책 정보 영역, 워터마크 영역
- 폰트 (한글·영문)
- 색 토큰
- 여백·간격 토큰
- 책 표지 자동 추출 팔레트와의 연동 방식
- 인용구 길이별 자동 조정 규칙 (50자 / 200자 / 500자)

### B. 디자인 시스템

- **색 팔레트**: primary, secondary, accent, neutral 5종, semantic (success/error/warning)
- **폰트 시스템**:
  - 한글: Pretendard (이미 결정), Noto Serif KR (인용구용)
  - 영문: 보조용 sans + serif
  - Type scale: 9px / 11px / 13px / 15px / 17px / 22px / 28px / 36px
- **여백 시스템**: 4px base (4·8·12·16·24·32·48·64)
- **그림자 토큰**: 카드용·모달용·플로팅 액션용
- **둥근 모서리**: 2px / 4px / 8px / 12px / 16px

### C. 책 표지 → 팔레트 추출 알고리즘 명세

이 앱의 핵심 차별화. 알고리즘 명세 + 의사 코드:
- 입력: 책 표지 이미지 URL
- 출력: 5개 색 (primary background, secondary, text dark, text light, accent)
- 사용 라이브러리 후보: `node-vibrant`의 RN 포팅 또는 `react-native-image-colors`
- Extractor가 만들어야 하는 보장: 인용구 텍스트가 추출 색 위에 항상 충분한 대비 (WCAG AA 이상)

### D. 핵심 화면 7개 비주얼 디자인 (선택, 시간 되면)

`landing-page/app-screens.html`의 와이어프레임을 정밀 비주얼로:
1. 홈 (timeline)
2. 내 서재 (4가지 뷰 — 격자·쌓기·책장·회전)
3. 책 상세
4. 인용구 추가
5. 카드 편집기 ★ (가장 공들임)
6. 카드 미리보기·공유
7. 친구·로그인

**우선순위**: A > B > C >> D. A가 빛나면 D는 V1 이후로 미뤄도 OK.

---

## 6. 기술 제약

- 구현 환경: **Flutter (Dart)** ← 2026-05-09 변경 (이전: React Native + Expo + react-native-skia)
- 카드 렌더링: Flutter Canvas + CustomPainter / RepaintBoundary로 합성 → PNG export → SNS 공유
- Skia는 Flutter 엔진에 내장 (별도 라이브러리 불필요)
- 사용자가 디바이스에서 조정 가능: 색·폰트·여백 (토큰화 필수)
- 한글 가독성 절대 우선: 폰트 라이선스·한글 디자인 quirks 고려
- 표지 이미지 출처: 알라딘 CDN (`image.aladin.co.kr/...`)
- 카드 PNG 해상도: 1080×1920 (스토리), 1080×1080 (피드), 1080×1350 (4:5)
- 색 추출: `palette_generator` (Google 공식 패키지)
- 백엔드: Supabase (커뮤니티 SDK `supabase_flutter`)

---

## 7. 결과물 형식

**가장 중요**: 메인 세션이 코드로 구현할 수 있는 형태로 전달.

### 7.1 디자인 토큰 (Dart)

```dart
// lib/design/tokens.dart
abstract final class AppColors {
  static const primary = _PrimaryScale();
  static const secondary = _SecondaryScale();
  static const accent = _AccentScale();
  // ...
}

abstract final class AppFontSize {
  static const double xs = 11;
  static const double sm = 13;
  static const double base = 15;
  static const double lg = 17;
  static const double xl = 22;
}

abstract final class AppSpacing {
  static const double s4 = 4;
  static const double s8 = 8;
  // ...
}

abstract final class AppRadius {
  static const double sm = 2;
  static const double md = 4;
  static const double lg = 8;
}

abstract final class AppShadow {
  static const card = BoxShadow(...);
  static const modal = BoxShadow(...);
}
```

### 7.2 카드 템플릿 명세 (각 5개)

각 템플릿마다 한 파일:
- `lib/features/cards/presentation/templates/minimal_template.dart`
- `lib/features/cards/presentation/templates/warm_template.dart`
- ...

```dart
class MinimalTemplate {
  static const String id = 'minimal';
  static const String name = '미니멀';

  static const TemplateLayout layout = TemplateLayout(
    quoteArea: QuoteAreaSpec(padding: 32, fontSize: 18, lineHeight: 1.7, fontFamily: 'NotoSerifKR-Medium'),
    bookArea: BookAreaSpec(padding: 16, fontSize: 11),
    watermarkArea: WatermarkSpec(...),
  );

  static TemplateColors colorMapping(ExtractedPalette palette) => TemplateColors(
    background: palette.dominant,
    quoteText: ensureContrast(palette.dominant, palette.textOnBackground),
    bookText: palette.subtextOnBackground,
  );

  static const Map<String, RatioVariant> variants = {
    '9:16': RatioVariant(...),
    '1:1': RatioVariant(...),
    '4:5': RatioVariant(...),
  };
}
```

### 7.3 Flutter Widget 컴포넌트 (옵션, 가능하면)

Flutter는 Skia가 엔진이라 별도 캔버스 라이브러리 없음. CustomPainter 또는 일반 Widget 합성으로 카드 렌더링.

```dart
// lib/features/cards/presentation/templates/minimal_template_widget.dart
class MinimalTemplateWidget extends StatelessWidget {
  final Quote quote;
  final Book book;
  final TemplateDesign design;

  const MinimalTemplateWidget({
    super.key,
    required this.quote,
    required this.book,
    required this.design,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary( // PNG export 시 boundary 캡처
      child: CustomPaint(
        size: Size(design.width, design.height),
        painter: MinimalCardPainter(quote: quote, book: book, design: design),
      ),
    );
  }
}
```

### 7.4 최종 산출물 위치 (제안)

```
C:\GIT\quotes-app-discovery\design\
├── tokens.md              # 디자인 토큰 명세
├── tokens.dart            # 실제 import 가능한 Dart 토큰
├── templates\
│   ├── 01-minimal.md      # 명세 + 시각 미리보기 (HTML mockup)
│   ├── 02-warm.md
│   ├── 03-mono.md
│   ├── 04-cover-extract.md
│   └── 05-typography.md   # (브리프 5번 일러스트 → 타이포 교체됨)
├── color-extraction.md    # 표지 → 팔레트 알고리즘 (palette_generator 기반)
├── design-system.md       # 전체 시스템 종합
└── mockups\
    └── all-templates.html # 5개 템플릿 시각 비교
```

또는 코드로 바로 가능하면 `lib/features/cards/presentation/templates/` 아래.

---

## 8. 작업 방식 제안

1. **탐색** (10–20분): 영감 소스 보기. `landing-page/app-screens.html` 카드 편집기 화면 확인. #책스타그램 인기 게시물 검색 (가능하면).
2. **방향 제안 3개**: 5개 템플릿의 결을 미리 보여주고 메인 작업자에게 선호 방향 묻기 (이 세션에서 사용자가 메인 작업자 역할).
3. **선택된 방향으로 정밀 디자인**: 각 템플릿 명세 + HTML mockup으로 미리보기.
4. **디자인 토큰 정리**.
5. **표지 → 팔레트 추출 알고리즘 명세**.
6. **(시간 되면) Skia 컴포넌트 코드 초안**.

---

## 9. 의사소통

- 한국어로 응답
- 결정 시 근거 명확히 (왜 이 색·왜 이 폰트)
- 모호한 요구는 다시 물어보기 (가정해서 진행 X)
- 결과물은 markdown + 가능하면 HTML mockup으로 시각 확인 가능하게

---

## 10. 명시적으로 하지 말 것

- 카드 템플릿 외 영역 코딩 (백엔드·라우팅·API)
- 메인 세션이 결정한 기술 스택 변경 제안
- 페르소나·시나리오 다시 만들기 (이미 정해짐)

---

## 11. 첫 응답으로 해주실 것

1. 본 브리프 잘 받았는지 확인
2. `landing-page/app-screens.html` 보고 첫인상·이슈 언급
3. 5개 템플릿의 방향성 초안 (각 1–2 문장씩)
4. 작업 시작 전 추가로 물을 것 있으면 질문

본 세션을 메인 세션과 다른 컨텍스트로 분리해서 시각 디자인에 집중해주세요.
