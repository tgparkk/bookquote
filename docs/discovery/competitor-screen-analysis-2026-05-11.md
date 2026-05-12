# 경쟁앱 화면 해부 — 우리 화면 설계를 위한 레퍼런스

**작성일**: 2026-05-11
**작성자**: 매니저 모드 가상 팀 종합 (UI/UX ×2 · 기획 ×2 · Dart ×2 · QA ×2 → 매니저 종합)
**전제 문서**: `market-research-2026-05-10.md`, `competitor-evaluation.md`, `bookstagram-analysis.md`, `design-system.md`, `flows.md`, `error-handling.md`
**현재 단계**: Stage 1(기반) 완료 → Stage 2(인용구 입력)/Stage 3(카드) 화면 세부 설계 직전
**다음 산출물**: 이 문서를 입력으로 `docs/design/screens/*.md` (화면별 세부 설계) + `docs/design/mockups/screens.html`

---

## 0. 한 줄 결론

> **북모리·북적북적이 "독서 기록 다이어리"라면, 책귀는 "인용구 한 줄을 1분 만에 단톡방으로 쏘는 도구"다.** 경쟁앱들의 화면을 해부한 결과 우리가 화면 레벨에서 지켜야 할 4원칙: ① **막다른 골목 금지**(북모리의 OCR 광고 게이트 ↔ 우리는 어떤 실패에도 "직접 입력" 출구) ② **화면 = 공유 산출물**(북적북적의 책탑 캡처 → 우리는 디자인된 카드를 그 자리에서 1탭 공유) ③ **결정 끝난 5종 + 표지색 자동**(Tezza·Canva·Typorama의 옵션 과잉 ↔ 우리는 컬러피커조차 없음) ④ **데이터 안 잃음**(앱 죽어도 draft 복구, export 가능 — 북모리·북적북적 공통 약점 직격).

---

## 1. 방법론과 한계

- **데스크 리서치**: App Store/Play Store 페이지·스크린샷, 개발자 회고(brunch.co.kr/@drawhatha 등), 한국·글로벌 리뷰(Book Riot, longblack, 데일리팝, DC/클리앙), UX 크리틱(Pratt IXD), 공식 문서(Readwise Docs, Canva SDK), 유튜브 워크스루.
- **할 수 있는 것**: 화면 인벤토리·IA·레이아웃 패턴·인터랙션 문법·시장 평판·약점 파악, 우리 디자인 시스템과의 적합성 판단, 차별화 축 stress-test.
- **할 수 없는 것**(실물 사용 필요 — V1 출시 후 보완): 픽셀 단위 정확도, 인터랙션 마찰의 실제 깊이, retention/DAU 수치. 픽셀·세부 제스처는 본문에서 "추정" 표기.
- 본 문서는 **경쟁앱의 화면을 베끼는 카탈로그가 아니라**, "그들이 한 것 → 우리 디자인 시스템(Ink-Paper-Copper, 모던)으로 갈 때 따라할 점 / 차별화할 점"의 결정 근거다.

---

## 2. 앱별 화면 해부

### 2.1 북모리 (Bookmory) — 직접 경쟁 80%, Play 4.9★ / 76K+ 리뷰 / 1인 개발 / Flutter 추정

**IA**: 하단 탭 4개 (추정) — ① **Welcome/홈**(현재 읽는 책 진행률·타이머, 스크롤하면 캘린더·통계) ② **서재**(표지 그리드/리스트, 컬렉션·시리즈·태그) ③ **Memorize/기억하기**(인용구·노트 횡단 모음 — *이게 1급 탭인 게 핵심 IA 결정*) ④ **My Page/설정**. 책 추가 = 검색 / 바코드 / 직접입력 3분기, depth가 깊음(개발자 본인이 "depth 많다"고 자평).

**카드 = 독립 탭이 아니라 노트 상세의 sub-flow**: 책 상세 → 노트 작성 → 인용구 밑줄 → 배경 이미지 선택(고정 라이브러리) → 폰트/색/문단 간격 → 이미지 export. **표지색 자동 추출 없음.** OCR은 입력의 메인 도입 동선이지만 **무료는 보상형 광고 시청 후**.

**잘함**: ① "기억하기" 전용 탭(인용구를 책에 가두지 않음) ② 카드 옵션이 한 화면 + 즉시 미리보기(1인 개발 4.9의 핵심) ③ 하단 탭 즉시 전환 ④ 완독 시 캐릭터 축하(라이트 게이미피케이션).
**답답함**: ① 책 추가/상세 depth 과다 ② **광고가 흐름을 끊음**(특히 OCR마다) ③ 카드 배경 고정 라이브러리 → 책마다 색 안 따라옴, "앱이 만든 티" ④ **데이터 export 약함, 웹 없음** ⑤ 인용구 입력 시 페이지·태그가 부가 입력으로 묻힘.

### 2.2 북적북적 — 1M+ 다운로드, "시각화 retention"의 교과서

**IA**: 하단 탭 3~4개 (추정) — ① **홈(책탑)** 읽은 책이 두께·페이지 비례 블록으로 쌓인 시각화 + "N권·M cm" + 캐릭터, 날짜 셀렉터로 기간 전환, **리스트/캘린더 뷰 토글** ② **책 추가**(검색/바코드, 상태 4분류: 읽은/읽는/읽고싶은/중단) ③ **책 상세**(시작·종료일, 진행률 도넛, 기대지수, 한줄평·메모 ≤500자) ④ **마이페이지**(월별 통계, 캘린더, 캐릭터 60종 도감 + 옷장 꾸미기).

**카드/인용구 에디터 — 없음.** 인용구는 "책당 메모 1개" 수준, OCR 없음. **viral 산출물 = 홈 화면(책탑) 캡처**(#북적북적 8.6만 게시물). 즉 "화면 = 공유물" 등식에 화면 전체를 베팅.

**잘함**: ① 단일 메타포(책탑)에 화면 전체 베팅 → retention + viral 동시 ② 두께·페이지 비례 = "노력의 물리적 환산"("30cm 쌓았다") ③ 무료로 핵심 다 됨 + 첫 책 등록 즉시 aha ④ 상태 4분류가 독서가 멘탈 모델과 일치.
**답답함**: ① 귀여운 캐릭터 결 → 디자이너·책스타그래머 비타깃(우리 세그먼트가 정확히 빈자리) ② 인용구·문장 약함(우리 본진) ③ 결과물이 "앱 캡처 티"(UI 크롬·캐릭터가 같이 찍힘) ④ 유료 게이트가 캐릭터 꾸미기에 ⑤ export 약함, 웹 없음.

### 2.3 Readwise — 인용/하이라이트 관리의 글로벌 표준

**핵심 화면**: ① **Daily Review**(저장한 하이라이트를 spaced repetition으로 매일 N개 카드 스택으로 resurface — "찍고 안 봄"의 정통 해법) ② **하이라이트 라이브러리**(Kindle·Apple Books·Pocket + 종이책 OCR 동기화, 책별 Scroll Mode, 태그·노트, 필터 차원이 많음: 읽기상태/타입/태그/도메인/하이라이트색/위치) ③ **Reader**(별도 앱, 범위 밖) ④ **AI/Chat with Highlights**(2025 추가) ⑤ **Export**(Notion/Obsidian/Roam/Markdown 양방향 — 데이터 주권의 표준).

**디자인 철학이 우리와 동족**: 하이라이트 색이 **물리적 형광펜을 일부러 모사**(연노랑 `#FBDA83`, 코랄 `#E4938E`, 블루 `#8DBBFF` — "디지털 네온 오버레이가 아니라 종이 위 잉크"). 본문은 다크 배경 3단 위계, "읽기 표면은 사라져야 한다 — 30분 세션 동안 모든 픽셀이 잠재적 방해물". → **우리 Ink-Paper-Copper "오래된 잉크·종이" 철학과 같은 사고방식**. 자신 있게 밀어붙여도 됨.

**textshot(이미지 공유)**: 모바일은 `i` 아이콘 → Notebook 탭 → `...` → "Share as image" → 레이아웃 3종(Pretty/Clean/Classic) + 인스타용 정사각. **이게 사실상 우리 앱의 핵심 기능을 Readwise가 곁다리로 끼워 넣은 것 — 우리는 이걸 메인으로, 더 잘.**
**약점**: textshot 커스터마이즈 빈약(3 레이아웃, 표지색 활용 X, 폰트 자유도 X, 추정) / 한국어 타이포·한국 책 메타 X / 모바일 도달 경로 깊음 / 비싸다(연 ~$100) / "power reader"용이라 캐주얼엔 무겁다 / 게임화·푸시 압박 없음.

### 2.4 Fable — Gen Z 소셜 독서, ~3M, "닫힌 그룹 소셜"의 검증판

**핵심 화면**: ① **For You Feed**(커뮤니티 기반 알고리즘 피드 — 순수 친구 타임라인이 아니라 추천+클럽 활동) ② **북클럽**(셀럽·작가·BookTok 인플루언서 클럽 or 직접 개설, 미팅·영상 없음, "텍스팅처럼" 게시물·댓글 — **닫힌 그룹 단위 소셜이 핵심**) ③ **Read in Social Mode**(자체 ebook 리더에서 하이라이트·이모지 반응·코멘트 → 같은 책 읽는 클럽 멤버와 공유, 챕터별 spoiler-free "Let's discuss" 룸) ④ 트래킹·통계.

**시사**: 우리 차별화 ②(단톡방 동시 독서/공유)의 글로벌 검증판 = "같은 책 동시에 읽으며 닫힌 그룹 안에서 반응 공유"가 작동한다. 단 **클럽을 앱 안에 만드는 건 운영 비용 큼**(cold start, 모더레이션) → 1인 개발자는 **기존 단톡방을 그룹 인프라로 빌려 쓰는 것**이 유일하게 현실적.
**약점·경고**: ① **2025년 1월 AI 연말 요약이 인종차별적 문구 생성 → AI 전면 폐기 사건** (소셜+AI를 한 앱에 욕심내면 사고난다) ② 자체 ebook 리더에 갇힘(종이책 X) ③ 검색·카탈로그 부실 ④ 앱 렉·로딩 실패·빈 화면 버그.

### 2.5 카드 디자인 앱군 (Tezza / Canva 모바일 / Mojo / Unfold / Typorama / 인스타 스토리)

| 항목 | 시장 공통 패턴 | 우리 결정 (요약) |
|---|---|---|
| 템플릿 선택 | 카테고리 탭 + 가로 스크롤 썸네일, 탭 즉시 적용 (Tezza 150종+) | 카테고리 없이 **5개 가로 썸네일 한 줄**, 탭 즉시 캔버스 갱신 |
| 썸네일 내용 | Mojo는 **애니메이션 프리뷰**(고를 때 결과를 봄) | **사용자 실제 인용구·표지로 즉시 렌더된 미니 카드** (와이어프레임 X) |
| 텍스트 위치 | 인스타 표준 제스처(한손 드래그=이동, 핀치=크기, 비틀기=회전) + 정렬 버튼 | 같은 제스처 문법, 단 **상/중/하 3지점 스냅 앵커**로 자유도 제한 (템플릿 미관 보호) |
| 폰트 변경 | 100종+ 리스트, 셔플(Typorama 랜덤 생성, Canva Styles) | 폰트 사실상 1~2종 고정 → **폰트 피커 거의 불필요** |
| 색 변경 | 스와치 그리드 → 필요 시 컬러휠/HEX (Canva의 progressive disclosure) | **표지에서 추출한 5색 스와치 줄 = 그게 곧 컬러 UI 전부**. 컬러휠은 V2 |
| 셔플 | Typorama 랜덤, Canva Styles 셔플 | **"다른 느낌 보기" 버튼** — 다음 템플릿 + 팔레트 슬롯 재배정, 단 5종 안에서만 순환(품질 보장) |
| 비율 전환 | 정사각/9:16 토글 | 편집 기본 9:16, 상단 **1:1 ↔ 4:5 ↔ 9:16 세그먼트 토글** |
| 공유 버튼 | 우상단/우하단 고정, 항상 보임 | **편집 화면 우상단 고정 1탭** "공유" |
| 언두 | **Mojo가 없어서 욕먹음** | **언두 필수** (편집 화면 상단, 최소 20단계, 비율·템플릿 전환까지 포함) |
| 발견성 함정 | **Tezza/Unfold의 "더블탭 편집"이 발견성 약점** (신규 사용자 헤맴) | **금지** — 한 번 탭 = 인라인 핸들, 모든 액션 라벨 노출 |
| 워터마크 | Typorama 무료판 강한 워터마크 = 거부감 | 기존 결정 유지(우하단 30% opacity, 거의 안 보임), 텍스트 영역과 비겹침 보장 |
| 옵션 양 | Canva/Typorama = 무한(그라데이션·3D·100폰트) → 분석마비, "앱 만든 티" | **결정 끝난 5종 + 표지 팔레트** — 우리 정체성(그라데이션·3D 금지)이 곧 차별화 |

---

## 3. 화면 유형별 횡단 비교 + 우리 입장

| 화면 유형 | 북모리 | 북적북적 | Readwise | Fable | **책귀 V1 방향** |
|---|---|---|---|---|---|
| **홈/피드** | 현재 읽는 책 대시보드(진행률·타이머·캘린더) | 책탑 시각화 = 캡처 산출물, 친구 피드 없음 | Daily Review(spaced repetition 카드 스택) | For You(알고리즘+클럽 피드) | **"내 인용 피드 + 단톡으로 받은 카드 함"**. "친구 새 인용"이라는 *이름과 빈 화면*은 V1에서 안 씀(Goodreads 죽은 피드 = 안티패턴). follow 타임라인은 V1.5에 같은 피드에 합쳐 진화 |
| **서재** | 표지 그리드/리스트 + 컬렉션·시리즈·태그 | 책탑(시각화) + 리스트/캘린더 토글 + 상태 4분류 | 책별 하이라이트 Scroll Mode | 트래킹 화면 | **V1은 단순 리스트(현행 유지)**. 단 책 카드에 "이 책에서 모은 N구절" 배지 + 표지 dominant color 띠를 V1에 심어두면 V1.5 "인용 서가" 시각화로 저비용 확장. 본격 시각화 메커닉은 V1.5 |
| **책 상세** | 표지 헤더 + 메타 + 별점 + 날짜 + 노트 리스트 (세로 긴 폼) | 표지 + 메타 + 진행률 도넛 + 기대지수 + 한줄평 | 책별 하이라이트 모음 | 클럽 연결 | **현행 read-only 유지 + 보강**: 이 책에서 모은 인용구 리스트 + "이 책 인용구 추가" CTA + (deep link 진입 시) "내 서재 담기" 1탭. 메타는 점진적 공개(페이지·날짜 접힘) — 북모리 depth 과다 회피 |
| **인용 목록/상세** | "기억하기" 탭: 카드 리스트(인용+책+페이지+별), 메모 길이 제한 설정 | 사실상 없음 | 하이라이트 카드(표지+제목/저자+텍스트+노트+태그), 필터 다차원, 인라인 태깅 | 리더 내 하이라이트 | **Readwise 카드 문법 채택**: 표지 썸네일 + 인용 2~3줄 미리보기 + 책 제목/저자 + 무드 태그 칩(색 코딩) + 메모 1줄. 필터 3개로 충분(책별 / 무드별 / 최근순) + 상단 검색 |
| **인용 입력** | 타이핑 / 사진 OCR(*광고 게이트*) / 페이지·태그는 부가 입력으로 분리 | 책당 메모 1개 | (입력은 외부 앱에서) | (리더 내 하이라이트) | **OCR 결과 + 페이지 + 무드 태그 + 노트를 한 화면에서 편집**. OCR은 "편집 가능한 초안 채우기"로만(자동 확정 X), 원본 사진 대조 뷰. **OCR에 광고 절대 안 붙임** — 이게 북모리 이탈자 흡수의 핵심 약속. 모든 권한 거부·OCR 실패·검색 0건에 "직접 입력" 출구 상시 노출 |
| **카드 에디터** | 노트 상세의 sub-flow, 고정 배경 라이브러리, 표지색 X | 없음 | textshot 3 레이아웃(곁다리) | 없음 | **3단 고정 레이아웃**: 상단(뒤로 / 비율 세그먼트 / 언두 / 공유) · 가운데(라이브 프리뷰 ~55-60%, 인용구 박스 한 번 탭=인라인 핸들) · 하단(5종 템플릿 가로 한 줄 = 사용자 실제 인용구로 렌더된 미니 카드 + 보조행: 텍스트 / 색=표지팔레트 5스와치 / 위치 상중하 / 워터마크). 진입 시 "이 인용구에 어울리는" 템플릿이 추천 선택된 상태로 시작 |
| **카드 공유** | OS 공유 시트만 (양방향 0) | 사용자가 화면 캡처해서 인스타 (우연) | textshot → 인스타 정사각 | 없음 | **카카오톡(단톡방) 1탭 우선 → 인스타 스토리(9:16 자동) → 이미지 저장** 순서. 받는 사람이 카드 탭 → 앱 열림 → 책 정보 + "내 서재 담기" 1탭 (deep link로 의도 설계 — 북적북적의 "우연한 바이럴"을 메커닉화). V1은 `share_plus` OS 시트로 시작, 카카오 SDK 메시지 템플릿 공유는 V1.1 |

---

## 4. 차별화 5축 × "경쟁앱은 이렇게 / 우리는 이렇게" + V1 판정

| 축 | 경쟁앱은? | 우리는 어떻게 다르게 (화면 레벨) | V1 판정 |
|---|---|---|---|
| **① 표지색 자동 추출 → 카드 팔레트** | 북모리·북적북적·Readwise·Tezza **전부 안 함** (고정 배경/스와치만) | 카드 에디터 진입 = 표지에서 뽑은 5~7색이 이미 적용된 상태로 시작 → "색 변경 UI"를 따로 만들지 않고 그 5스와치 줄이 곧 컬러 패널. 흑백·단색 표지는 채도<10 폴백(secondary400/primary600). 사용자가 "이 색 책 표지에서 뽑힌 거구나" 느끼는 순간 = 바이럴 포인트 | **필수 (V1, Stage 3)** — 인프라 완비(`palette_generator`, `tokens.dart`의 `ExtractedPalette`/`fallbackPalettes`, `color-extraction.md` 명세) → "명세 받아쓰기" 수준. 단 `Color` 채널/직렬화는 `toARGB32()` 기준으로 갱신 필요 |
| **② 단톡방 1탭 공유 + 수신자 1탭 책담기** | 북모리=OS 시트만, 북적북적=우연한 캡처, Fable=클럽(앱 내부) | 공유 화면 1순위 = 카카오톡 단톡방. 받는 사람 deep link 탭 → 책 상세(비로그인이면 read-only 먼저) → "내 서재 담기" 1탭 → K-factor. `deep_link_handler.dart`가 현재 `/auth/callback`만 처리 → `/book/:id` deep link 라우팅 + 콜드스타트 미로그인 시 payload 보존 + 1회 consume을 화면 설계 명세에 못박아야 함 | **필수 (V1: 공유 + 책담기 1탭)** — deep link 인프라 일부 존재(`app_links`), 핸들러 일반화 필요(난이도 M). 카카오 SDK 메시지 카드 형태 공유는 V1.1(카카오 *공유*는 OAuth 불필요, 네이티브 키만 — 로그인 V1.5와 독립). 챌린지 메커닉·spoiler 게이팅은 V1.5 |
| **③ 데이터 주권 (Markdown export, Notion 연동)** | 북모리·북적북적 **약점**("export 안 됨", "폰 바꾸면 날아감"), Readwise는 강함(표준) | 설정/서재에 "내보내기(Markdown)" 버튼 V1부터. 클라우드 자동 동기화는 우리 기본값 → "당신 인용구는 항상 안전하고 언제든 가져갈 수 있다" 온보딩 카피. 단 디자이너·인스타 세그먼트엔 hygiene factor(핵심 가치 X) | **선택→V1에 Markdown export만**(비용 거의 0, 북모리 약점 직격). Notion 연동·웹 뷰어는 V1.5 |
| **④ 무드 태그 (위로/새벽3시/출퇴근/이별)로 재그룹화** | 북모리=커스텀 태그+"랜덤 노트"(라이트), StoryGraph mood 통계는 검증됨, 나머지 약함 | 인용 저장 직후 그 자리에서 1탭 무드 태그(Readwise 인라인 태깅처럼) — 저장 토스트에 "무드 추가?" 칩. 무드별 컬렉션 자동 생성 → "찍지만 다시 안 봄" 페인을 *테마 단위 다시 보기*로 해결. 색 코딩, 멀티 선택(최대 3개), 텍스트 라벨 필수(색맹 고려) | **필수 (V1: 태그 시스템 `text[]` + 카드 만들 때 무드 추천 1~2개)** — 비용 낮음. 자동 분류·무드 추천 AI는 V1.5. quotes 테이블 `moods text[]`, 앱이 `enum QuoteMood`로 화이트리스트 |
| **⑤ 인용 중심 AI (요약/유사 인용/같은 책 추천/번역)** | 한국 시장 **완전 빈자리**(플라이북·교보 등은 "책 추천" AI지 인용 AI 아님), Fable은 AI 사고 친 적 있음 | V1.5에 넣더라도 *입력·출력이 좁고 검수 가능한* 기능만("이 인용 영어 번역", "이 책 핵심 문장 3개"). 사용자가 결과를 항상 편집(OCR과 동일 원칙). "AI 친구" 같은 과한 약속 금지. 짧은 한국어 인용구는 AI 품질 빈약 → 페이지·앞뒤 문맥도 같이 전달 | **V1.5** (출시 메시지에 "곧" 명시할지는 viral 강화 vs "곧 출시" 부담 트레이드오프 — 미결) |

→ **종합: ①②④ = V1 필수, ③ = V1에 Markdown만, ⑤ = V1.5.** `market-research-2026-05-10.md` §8.1 권고와 일치. **"OCR + 카드"만으로는 북모리와 동일** → ①②④ 중 최소 2개를 V1 출시 메시지에 박아야 "북모리가 먼저 나왔고 동일"이라는 결론을 피한다.

---

## 5. 우리 화면 설계 권고 (Phase B 입력)

화면별 세부 설계 문서(`docs/design/screens/*.md`)에서 다음을 못박는다. 각 화면 문서는 7개 섹션(목적/진입·이탈 · 와이어프레임 · 상태(로딩·빈·에러·오프라인·권한거부) · 인터랙션 · 토큰 매핑 · 재사용 컴포넌트 · 엣지·접근성) 구조.

### 5.1 인용구 입력 화면 `/quote/new` — 그룹 1 (Stage 2, 최우선)
- **레이아웃**: 큰 멀티라인 TextField(`AppFonts.quote` 적용 — 카드 미리보기와 톤 일치) + "사진에서 가져오기" 버튼 + 클립보드 자동 감지 배너 + 책 선택 영역(`showBookSearchSheet` 재사용) + 페이지(숫자 키패드, 선택) + 무드 칩 행 + "카드 만들기 →" CTA(→ `/quote/$id/card`).
- **OCR 모드**: 사진 촬영/갤러리(`image_picker`, 최소 권한 — `camera` 패키지 안 씀) → ML Kit 한국어 온디바이스 추론 → **결과를 편집 가능한 TextField에 주입(자동 확정 X)** + 원본 사진 대조 뷰(2단·세로쓰기·노이즈 케이스 대응). 후처리(줄바꿈 합침/하이픈 제거/따옴표 정규화/페이지번호 라인 제거)는 별도 순수 함수 + 단위 테스트.
- **반드시 명세에 박을 상태 7가지** (QA-1): ① DRAFT(작성 중 로컬 영속화 → 재진입 시 "이어쓰기/폐기") ② OFFLINE_QUEUED(오프라인 저장 = 실패 아닌 큐 성공 + "동기화 대기" 뱃지) ③ OCR_MODEL_UNAVAILABLE(모델 다운로드 실패 → OCR만 막히고 직접 입력 살아있음 + 전환 버튼) ④ OCR_EMPTY_RESULT(0글자 → 에러 페이지 X, 빈 TextField + 다시촬영/직접입력) ⑤ PERMISSION 상태 머신(notDetermined/denied/permanentlyDenied/restricted/iOS-limited 각각 다르게, 영구거부는 설정 딥링크, 모든 분기에 대체 동선) ⑥ SAVING/SAVE_FAILED(저장 중 비차단+입력잠금, 실패 시 폼 100% 보존+재시도) ⑦ BOOK_UNRESOLVED(책 못 골라도 인용구 저장 가능, 사후 매핑 경로 + 시트에 [ISBN 직접 등록]/[직접 등록] 버튼 추가).
- **재사용**: `showBookSearchSheet`(단, `_onPick`의 "서재에 추가했어요" SnackBar 문구는 quote 진입 시 억제 — 옵션 파라미터), `bookByIdProvider`, `book_repository.upsertBook/getById`, `/quote/new?bookId=` 라우트(이미 배선됨), `tokens.dart`(`getQuoteFontSize`, `AppFonts.quote`, `AppColors.accent500`).
- **신규**: `supabase/migrations/..._quotes.sql`(`book_id` nullable `on delete set null`, `text` CHECK 1~2000, `source` text-enum `manual`/`ocr`/`clipboard`, `moods text[]`, RLS = `user_books` 패턴 복사, `set_updated_at()` 재사용), `quote_repository.dart` / `quote.dart`(@freezed) / `quote_providers.dart` / `createQuoteController`(낙관적 생성, `client-architecture.md` 7.B 패턴). **카드 디자인 상태는 quotes에 안 넣음** → Stage 3 `cards` 테이블.
- **결정 필요**: `flows.md` Flow B 4.3은 "OCR = 폰 기능(iOS Live Text)+클립보드"가 1차였음 → 앱 내장 OCR 추가는 그 결정을 뒤집는 것(북모리 대비 차별화 압력). 오프라인 입력 큐는 **V1.5로 이관 권장**(현재 코드에 인프라 0 — drift/sqflite/connectivity 전무. V1은 온라인 전제 + draft 1건만 `shared_preferences`로 복구).
- **웹/플랫폼 가드**: 이 프로젝트는 `flutter_web_plugins` 사용 → 웹 빌드 대상 가능. `google_mlkit_*`은 웹 미지원 → OCR 진입점은 `kIsWeb`/`Platform` 가드.

### 5.2 카드 에디터 `/quote/:id/card` — 그룹 1 (Stage 3)
- **3단 고정 레이아웃**(§3 참조). 렌더 방식 = **위젯 트리, CustomPaint 아님**(`flows.md`의 "CustomPaint 60fps" 폐기) — `sealed class CardTemplate` + 템플릿별 `Widget`(Stack 슬롯). 한글 텍스트 layout·blur(T4)·표지 이미지 재사용 때문. CustomPaint는 T1 1px 구분선 같은 장식에만.
- **팔레트는 비동기, 카드는 동기로 그린다**: 진입 즉시 `fallbackPalettes[templateId]`로 렌더 → `paletteProvider(coverUrl)` 완료 시 cross-fade 교체. 절대 팔레트 await로 화면 막지 않음. 캐시는 V1 = 메모리 LRU(+선택적 `shared_preferences`), **books 테이블에 컬럼 추가 안 함**.
- **PNG export 계약**: 픽셀 = `AppCardSize`(1080 기준), pixelRatio는 표시폭에서 역산(또는 `OverflowBox`로 1080 논리폭 강제 후 캡처). **폰트 로드 완료를 캡처 전에 보장**(Noto Serif KR은 앱 번들 asset 동봉, 캡처 직전 `WidgetsBinding.instance.endOfFrame` + 폰트 미로드 시 1회 재시도) — 안 그러면 첫 캡처가 두부(□□□)로 인스타에 박힌다. 워터마크는 별도 합성 아닌 캡처 트리 안 `Positioned`. `ui.Image.dispose()` 누락 금지. 신규 패키지: `share_plus`·`path_provider`(필수), `gal`(명시적 다운로드 버튼 붙일 때).
- **반드시 명세에 박을 상태 7가지** (QA-2): ① "공유는 되지만 저장은 안 됨" 동선(사진 쓰기 권한 거부 시 [저장]만 비활성, 카카오톡/인스타 공유는 끝까지 활성 — iOS add-only / Android 11+ scoped storage / Android 13 READ_MEDIA 혼동 분기) ② PNG 생성 실패 단계적 폴백 + 디자인 보존(OOM → toast + 옵션 유지 → 재시도 시 1080→720 → "메모리 부족" 안내) ③ 폰트 로드 완료를 캡처 전에 보장 ④ 긴 인용구 auto-fit 한계 — **잘린 채 export 절대 금지**(최소 폰트 도달 후 넘치면 비율 자동 추천 → 그래도 안 되면 명시적 경고) ⑤ 표지 색 대비 자동 보정(`ensureContrast` WCAG AA 4.5:1 + T4 그라데이션 overlay + 채도<10 폴백 — 깨지면 가독성 0, 스냅샷·대비 테스트 필수) ⑥ 편집 상태 영속화(templateId·팔레트 override·텍스트 상대좌표·비율·undo 스택 디버운스 저장 → 재진입 "이어 만들기") ⑦ 언두 = 비율·템플릿 전환까지 포함 최소 20단계(드래그는 onPanEnd당 1 push, 비율 전환 시 텍스트 위치 재매핑 = 상대좌표 0~1 + clamp).
- **결정 필요**: 텍스트 위치 앵커(상/중/하)를 V1에 넣을지 — 넣으면 템플릿 좌표 모델을 "고정 좌표"에서 "정렬 기반"으로 바꿔야 함(템플릿 명세 좌표표와 충돌). 디자인팀 합의 필요. / 표지 없는 책(`cover_url == null`)에서 T4(표지발췌)를 비활성화할지 단색 그라데이션으로 graceful degrade할지.

### 5.3 카드 공유/저장 시트 — 그룹 1 (Stage 3/4)
- **순서**: 카카오톡(단톡방) → 인스타 스토리(9:16 자동) → 이미지 저장. V1은 `share_plus` OS 시트 기본(카카오 SDK·OAuth 불필요, 셋업 0). "카카오톡으로 보내기" 메시지 카드 형태(deep link 버튼 포함)는 V1.1 — 그땐 Kakao Developers 앱 등록 + Android `<queries>` / iOS `LSApplicationQueriesSchemes` 추가가 묶여 옴.
- **상태**: 공유 시트 취소 = 에러 아님(toast 없음). 네트워크 끊겨도 공유 자체는 됨(PNG 로컬, OS 시트 로컬) — cards 히스토리 INSERT만 큐로 또는 skip, 사용자에겐 "성공". 카카오톡/인스타 미설치 = OS 시트엔 자동으로 안 뜸(전용 버튼이면 `canLaunchUrl` 체크 후 안내, 크래시 금지). 인스타 스토리 link sticker는 2024부터 전체 개방 — 시도하되 안 되면 텍스트 워터마크만.

### 5.4 받는 사람 deep link 진입 → 책 담기 — 그룹 1 (Stage 4, 바이럴 K-factor 핵심)
- **현재 갭**: `deep_link_handler.dart`가 `/auth/callback`만 처리, `/book/:id` deep link는 `return`으로 무시 중. → 핸들러를 "auth 전용"에서 "URI dispatcher"로 일반화(auth code면 `getSessionFromUrl`, 아니면 `router.go(path+query)`), GoRouter 포워딩 추가.
- **명세에 박을 것**: ① 앱 미설치 → 설치 후 deferred deep link 복원(Universal/App Link 필요 — 미설치 fallback 웹 뷰어는 V1.5, V1은 커스텀 스킴 한계 수용) ② **비로그인 진입** → 책 상세를 read-only로 먼저 보여줌 + "내 서재 담기" → 로그인 → 원래 책 상세 복귀, deep link payload를 로그인 동안 보존(현재 없음) ③ 그 책/인용 삭제됨 → "더 이상 볼 수 없어요" + 홈/검색 ④ 비공개·차단 인용은 책 정보만 표시 ⑤ deep link 1회 consume(무한 루프 금지, 라우터 redirect 최대 1홉) ⑥ 이미 서재에 있는 책 = `23505` → "이미 서재에 있어요" toast(에러 아닌 정보성) ⑦ "담기" 1탭 후 네트워크 끊김 → 낙관적 표시 후 실패 시 롤백.

### 5.5 홈 화면 `/` — 그룹 2
- **V1 = "내 인용 피드 + 단톡으로 받은 카드 함"**. 빈 상태("아직 인용구가 없어요. 좋아하는 책의 한 줄을 저장해보세요." + [+ 인용구 추가] 큰 버튼 1개 — `flows.md` Flow A 3.1 문구). 받은 카드함 0개면 섹션 숨김. 단톡 받은 카드 중복 = client-side dedupe(quote_id 기준). 오프라인 = stale-while-revalidate + 배너 + "동기화 대기" 뱃지. 매우 긴 피드 = `ListView.builder` 가상화, 카드 썸네일은 작게(풀 CustomPaint X). 피드 항목에서 [카드 만들기] → `/quote/:id/card`.
- **`flows.md`/코드 정리 필요**: 홈=`timelineProvider`(follow 의존) + `quotes` INSERT 시 `publish to followers` Realtime은 V1.5 스펙이 V1에 새어든 것 → V1 경로에서 제거. follow/타임라인 V1.5.

### 5.6 Me 화면 `/me` — 그룹 2
- 현행(이메일 표시 + 로그아웃) 유지 + 보강: ① 세션 로딩 vs 미로그인 구분 표시 ② 로그아웃 시 **동기화 대기 인용구 N개 있으면 경고 다이얼로그**("로그아웃하면 사라질 수 있어요") ③ "친구 찾기" 빈 onTap → "곧 추가될 기능" 안내 또는 숨김 ④ **계정 삭제/탈퇴**(Apple/Google 둘 다 in-app 계정 삭제 요구 — V1 출시 전 확인 필수) ⑤ 개인정보처리방침·약관·앱 버전·문의 링크(스토어 심사 필수) ⑥ 다크모드는 V1 시스템 따라가기 ⑦ "내보내기(Markdown)" 버튼(차별화 ③).

### 5.7 책 상세 `/book/:id` — 그룹 2
- 현행 read-only 유지 + ① 이 책에서 모은 인용구 리스트 ② "이 책 인용구 추가" CTA(→ `/quote/new?bookId=:id`) ③ deep link 진입 시 "내 서재 담기" 1탭(§5.4) ④ 메타 점진적 공개 ⑤ 표지 URL 깨짐 → `BookCover` placeholder fallback(이미 있음 — 북모리의 표지 로딩 실패 약점을 우아한 fallback으로 차별화).

### 5.8 그룹 3 (이미 구현 — 설계 문서로 역정리 + 개선점)
- 스플래시 `/splash`, 로그인 `/auth/login`, 콜백 `/auth/callback`+`/callback`, 서재 `/library`, 책 검색 시트(`book_search_sheet.dart`) — 현행 동작을 7섹션 구조로 문서화. 검색 시트 개선점(QA-1): 검색 전인데 "찾는 책이 없어요"가 뜨는 흠(검색어 비었을 때는 "최근 본 책"/안내 카피, "0건" 메시지는 검색 후에만), [ISBN 직접 입력]/[직접 등록] 정상 경로 버튼 추가, ISBN 패턴 감지 → `lookupByIsbn` 분기, 오프라인 시 캐시 카탈로그만 + "수동 책 이름 입력".

---

## 6. 모든 화면 공통 (각 화면 문서 "교차 관심사" 박스에 한 줄씩)

1. **오프라인 = 1급 상태** — 모든 입력 화면은 진입 시 `connectivity_plus`로 감지(현재 패키지 없음 → V1.5 본격 큐, V1은 감지+배너+draft만), 저장은 큐 경유로 성공시킴(Flow F).
2. **데이터 절대 유실 금지** — 인용 텍스트·책선택·페이지·무드·원본사진·카드 디자인 상태를 keystroke/선택마다 로컬 draft 영속화. 앱 kill·크래시·로그아웃·디스크풀 어떤 경우에도 복구 경로 존재(`error-handling.md` §1).
3. **PII 로그 금지** — 인용구 텍스트·검색어 raw·OCR 결과·사진 URL은 Sentry/PostHog에 안 들어감. 에러 코드·길이·screen 이름만(`error-handling.md` §7.3).
4. **막다른 골목 금지 (anti-북모리)** — 권한 거부·OCR 실패·검색 실패·rate limit·미설치 어디서든 "직접 입력"·"ISBN 직접 등록"·"이미지 저장 후 직접 올리기" 출구가 항상 화면에 노출. 광고 게이트 0.
5. **시트 왕복 시 입력 보존** — 책 검색 시트는 모달이므로 입력 화면 state 안 건드림. 회귀 테스트 대상으로 명문화.
6. **에러 표시 일관성** — `error-handling.md` §5: Inline(폼 검증) / Toast(일시적·정보성) / Modal(진행 불가, 세션 만료) / Empty(데이터 자체 없음). 모든 에러를 Toast로 폭탄 X.
7. **인증 가드** — `/quote/new`, `/quote/:id/card` 등 쓰기 화면은 go_router redirect로 비로그인 차단 + repository 레벨 `NOT_AUTHENTICATED` 2차 방어. `/book/:id`는 게스트 허용(deep link 진입용).
8. **"미리보기 = export" 보장** — 카드 미리보기도 export와 같은 위젯 트리를 스케일만 다르게 렌더. 스냅샷 테스트로 회귀 감지(`testing-strategy.md` §6 CardRenderer).

---

## 7. 미해결 결정사항 (사용자 확인 필요)

1. **앱 내장 OCR vs 폰 기능(iOS Live Text)+클립보드** — `flows.md` Flow B 4.3은 후자가 1차였음. 북모리 대비 차별화로 앱 내장 OCR을 V1에 넣을지? (Dart-1·기획-1 모두 "넣되 광고 0"을 차별점으로 봄)
2. **오프라인 입력 큐** — V1.5 이관 권장(현재 인프라 0). 동의?
3. **카드 텍스트 위치 앵커(상/중/하)** — V1에 넣을지(템플릿 좌표 모델 변경 수반) vs 템플릿별 고정 위치 유지.
4. **표지 없는 책에서 T4(표지발췌) 처리** — 비활성화 vs 단색 그라데이션 degrade.
5. **인용 AI(⑤) 출시 메시지 노출** — "곧 출시" 명시할지(viral 강화 vs 부담).
6. **Phase B 진행 순서** — 오늘 그룹 1(인용 입력·카드 에디터·공유·deep link)까지 설계할지, Phase A만 마무리하고 다음 세션에 그룹 1.

---

## 8. 출처

### 북모리
- 공식 https://bookmory.net/ · Play https://play.google.com/store/apps/details?id=net.tonysoft.bookmory · App Store(KR) https://apps.apple.com/kr/app/id1515533482
- 개발자 회고 https://brunch.co.kr/@drawhatha/1 · Book Riot 리뷰 https://bookriot.com/bookmory-review/ · MakeHeadway https://makeheadway.com/blog/bookmory-review/
- 데일리팝 https://www.dailypop.kr/news/articleView.html?idxno=57126 · 클리앙 https://www.clien.net/service/board/cm_iphonien/16261452 · DC https://m.dcinside.com/board/reading/652246

### 북적북적
- App Store(KR) https://apps.apple.com/kr/app/id1472538417 · Play https://play.google.com/store/apps/details?id=com.studiobustle.bookjuk
- 개발자 회고 https://brunch.co.kr/@drawhatha/2 · longblack https://www.longblack.co/note/1518 · OpenAds 수익화 https://www.openads.co.kr/content/contentDetail?contsId=14028

### Readwise / Fable / 횡단
- Readwise Docs https://docs.readwise.io/readwise/docs/faqs/reviewing-highlights · Reader Sharing https://docs.readwise.io/reader/docs/faqs/sharing · 인라인 태깅 https://blog.readwise.io/tag-your-highlights-while-you-read/ · Reader 디자인 분석 https://blakecrosley.com/guides/design/readwise-reader
- Fable https://fable.co/ · Book Riot 리뷰 https://bookriot.com/fable-book-club-app-review/ · AI 사건 https://lithub.com/fables-ai-generated-end-of-year-reading-summaries-veered-into-bigotry/
- StoryGraph Buddy Reads https://thestorygraph.freshdesk.com/support/solutions/articles/79000141943 · Goodreads 피드 설정 https://help.goodreads.com/s/article/How-do-I-edit-my-feed-settings · 비교 https://talesofbelle.com/2025/09/11/goodreads-vs-storygraph-vs-fable/

### 카드 디자인 앱
- Tezza 크리틱(Pratt IXD) https://ixd.prattsi.org/2020/09/design-critique-the-tezza-app-ios/ · Tezza App Store https://apps.apple.com/us/app/id1393061654
- Canva Help "Format text" https://www.canva.com/help/format-text/ · Canva SDK "color selectors" https://www.canva.dev/docs/apps/using-color-selectors/
- Mojo https://mojo-app.com/mojo-editor/ · 리뷰 https://productlondondesign.com/mojo-app-review/ · Unfold https://unfold.com/ · Typorama App Store https://apps.apple.com/us/app/id978659937
- 인스타 스토리 에디터 구현 분석(IMG.LY) https://img.ly/blog/how-to-build-instagrams-story-editor-in-a-day-23be9adff9b/

---

*작성: 책귀 매니저 모드 가상 팀(UI/UX ×2, 기획 ×2, Dart ×2, QA ×2) 병렬 협의 → 매니저 종합. 픽셀·세부 제스처 추정 항목은 V1 출시 후 실사용 데이터로 검증 권장(`bookstagram-analysis.md` 연기 결정과 같은 맥락).*
