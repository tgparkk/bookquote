# 2026-05-11 — 화면 세부 설계 착수: 경쟁앱 화면 해부 (매니저 모드)

오늘 목표: "각 앱 화면마다 세부 설계." 사용자 결정 — **경쟁앱 화면 분석부터** 시작 → 그 결과를 우리 화면 설계 입력으로. 산출물 = 마크다운 + HTML 목업. 진행 = 매니저 모드(가상 팀 협의).

## 한 일

1. `git pull` — `docs/discovery/market-research-2026-05-10.md` 등 최신 반영.
2. Explore ×2로 코드/문서 현황 파악: 화면 10개(스플래시·로그인·콜백 ✅ / 홈 스텁 / 서재 ✅ / Me 반쯤 / 책상세 ✅ / 인용입력 스텁 / 카드에디터 스텁 / 책검색시트 ✅), 디자인 시스템·5종 템플릿·6개 플로우는 있으나 **화면별 세부 설계 부재**.
3. **매니저 모드 가상 팀 8명 병렬 투입** (각자 WebSearch + 해당 docs 읽기):
   - UI/UX-1 — 북모리·북적북적 화면 레이아웃·IA 해부
   - UI/UX-2 — 카드앱군(Tezza/Canva/Mojo/Unfold/Typorama/인스타 스토리)·Readwise 에디터·인용 목록 인터랙션
   - 기획-1 — 북모리 기능·플로우 심층 + 차별화 5축 검증
   - 기획-2 — 북적북적·Readwise·Fable + Goodreads/StoryGraph 소셜 레이어 비교
   - Dart-1 — 인용 입력·OCR(ML Kit) 구현 난이도·재사용·리스크
   - Dart-2 — 카드 에디터·표지색 추출·PNG export·deep link 공유 구현
   - QA-1 — 인용 입력·OCR·책 검색·서재 화면 상태/엣지/권한 전수
   - QA-2 — 카드 에디터·공유·deep link 책담기·홈·Me 화면 상태/엣지/권한
4. 매니저 종합 → 산출:
   - **`docs/discovery/competitor-screen-analysis-2026-05-11.md`** — 앱별 화면 해부 + 화면 유형별 횡단 비교 + 차별화 5축 × "경쟁앱은/우리는" + Phase B 화면 설계 권고(화면별) + 모든 화면 공통 8원칙 + 미해결 결정 6개 + 출처
   - **`docs/discovery/mockups/competitor-references.html`** — 정적 레퍼런스 목업(경쟁앱 패턴 vs 책귀 V1 권고, 화면 6종 + 차별화 5축 표). 디자인 토큰(Ink-Paper-Copper) 사용.

## 핵심 결론 (화면 설계 4원칙)

1. **막다른 골목 금지 (anti-북모리)** — 북모리는 OCR마다 보상형 광고 게이트가 이탈 주범. 우리는 권한 거부·OCR 실패·검색 0건·미설치 어디서든 "직접 입력"·"ISBN 직접 등록"·"이미지 저장 후 직접 올리기" 출구를 항상 노출. 광고 게이트 0.
2. **화면 = 공유 산출물** — 북적북적이 1M+ 유저를 만든 건 "홈 화면(책탑)을 캡처해 인스타에 올린다"는 등식. 우리 등식 = "홈에서 본 인용구 카드를 그대로 9:16로 단톡방·인스타에 1탭 공유" — UI 크롬·워터마크 최소화로 "앱 캡처 티" 제거.
3. **결정 끝난 5종 + 표지색 자동** — Tezza·Canva·Typorama의 옵션 과잉(그라데이션·3D·100폰트→분석마비, "앱 만든 티")을 안 따라감. "색 변경 UI"를 따로 만들지 않고 표지에서 뽑은 5스와치 줄이 곧 컬러 패널.
4. **데이터 안 잃음** — 북모리·북적북적 공통 약점(export 안 됨, 폰 바꾸면 날아감) 직격. 앱 죽어도 draft 복구, Markdown export V1.

## 화면 설계에 박을 것 (요약)

- **홈** = "친구 새 인용"(빈 화면 = Goodreads 죽은 피드) ❌ → "내 인용 피드 + 단톡으로 받은 카드 함" ✅. follow 타임라인 V1.5. `flows.md`/코드의 `timelineProvider`·`publish to followers`는 V1.5 스펙이 V1에 새어든 것 → V1 경로에서 제거.
- **서재** = V1 단순 리스트 유지 + 표지 dominant color 띠 + "이 책에서 모은 N구절" 배지(V1.5 인용 서가 시각화로 저비용 확장).
- **인용 입력** = OCR 결과 + 페이지 + 무드 태그 + 노트를 한 화면에서. OCR은 "편집 가능한 초안"으로만(자동 확정 X), 원본 사진 대조 뷰, 광고 0. QA가 박은 7가지 상태(DRAFT / OFFLINE_QUEUED / OCR_MODEL_UNAVAILABLE / OCR_EMPTY_RESULT / PERMISSION 상태머신 / SAVING·SAVE_FAILED / BOOK_UNRESOLVED).
- **카드 에디터** = 3단 고정(상단 비율 토글·언두·공유 / 가운데 라이브 프리뷰 / 하단 5종 한 줄 + 보조행). 렌더=위젯 트리(CustomPaint 아님). 팔레트는 비동기·카드는 동기(fallback 즉시 렌더→cross-fade). 언두 필수(최소 20단계, 비율·템플릿 전환 포함). 더블탭 숨김 금지. 폰트 로드 완료를 PNG 캡처 전에 보장(안 그러면 □□□).
- **카드 공유** = 카카오톡(단톡방) 1순위 → 인스타 스토리(9:16) → 이미지 저장. 받는 사람 deep link → 책 상세(비로그인 read-only 먼저) → "내 서재 담기" 1탭 = K-factor. `deep_link_handler.dart`는 현재 `/auth/callback`만 처리 → `/book/:id` deep link 라우팅 + 콜드스타트 미로그인 payload 보존 + 1회 consume 갭. V1은 `share_plus` OS 시트, 카카오 SDK 메시지 카드 형태 공유는 V1.1(카카오 *공유*는 OAuth와 독립).
- **인용 목록/상세** = Readwise 카드 문법(표지+제목/저자+텍스트+노트+태그) + 무드 태그 인라인(저장 토스트의 "무드 추가?" 칩). 필터 3개(책별/무드별/최근순)+검색. 별도 탭 vs 서재 내 뷰 토글은 화면 설계 문서에서 결정.

## 미해결 (사용자 확인 필요 — competitor-screen-analysis §7)

1. 앱 내장 OCR vs 폰 기능(iOS Live Text)+클립보드 — `flows.md` Flow B 4.3은 후자가 1차였음. 북모리 대비 차별화로 앱 내장 OCR을 V1에?
2. 오프라인 입력 큐 — V1.5 이관 권장(현재 인프라 0: drift/sqflite/connectivity 전무)?
3. 카드 텍스트 위치 앵커(상/중/하) — V1에? (템플릿 좌표 모델 변경 수반)
4. 표지 없는 책에서 T4(표지발췌) — 비활성화 vs 단색 그라데이션 degrade?
5. 인용 AI(⑤) 출시 메시지에 "곧 출시" 노출? (viral 강화 vs 부담)
6. Phase B 진행 순서 — 다음 세션에 그룹 1(인용 입력·카드 에디터·공유·deep link) 화면 설계 착수?

## 다음 세션 (Phase B)

`competitor-screen-analysis-2026-05-11.md` §5를 입력으로 `docs/design/screens/*.md`(화면당 1파일, 7섹션 구조: 목적/진입·이탈 · 와이어프레임 · 상태 · 인터랙션 · 토큰 매핑 · 재사용 컴포넌트 · 엣지·접근성) + `docs/design/screens/README.md`(IA 다이어그램) + `docs/design/mockups/screens.html` 생성. 그룹 1(Stage 2~3 핵심) → 그룹 2(홈·Me·책상세) → 그룹 3(이미 구현된 화면 역정리). 그룹별로 매니저 모드 반복.

## 이어서 — 사용자 결정 + Phase B 그룹 1 착수 (같은 세션)

사용자 결정:
- **앱 내장 OCR 안 함** — 폰 기능(iOS Live Text·구글렌즈) + 클립보드 붙여넣기로. `DECISIONS.md 2026-05-11` 기록, `STAGES.md` Stage 2에서 "ML Kit OCR" 삭제 → "클립보드 붙여넣기 자동 감지 배너". `flows.md` Flow B 4.3이 원래 이 방식이라 그 명세가 다시 유효.
- **오프라인 입력 = 경량 로컬 아웃박스까지만** (완전 동기화 엔진 Flow F는 V1.5) — `DECISIONS.md 2026-05-11`. `quotes.book_id` nullable + `manual_book_text` 필드를 V1에 넣어 V1.5 큐 붙일 때 마이그레이션 회피. 일정 빠듯하면 아웃박스를 2.1로 미루고 V1은 "draft 1건 복구만".
- "우선 진행하죠" → Phase B 그룹 1 착수.

Phase B 그룹 1 산출 (`docs/design/screens/`):
- `README.md` — 화면 인벤토리 + IA 다이어그램(텍스트) + 7섹션 구조 정의 + 공통 8원칙
- `quote-input.md` — 인용구 입력 `/quote/new` (직접 입력 / 클립보드 붙여넣기, 책 연결, 페이지·무드, draft·아웃박스, quotes 스키마)
- `card-editor.md` — 카드 에디터 `/quote/:id/card` (3단 고정 레이아웃, 5종 템플릿 + 표지 팔레트, 언두, 위젯 트리 렌더, PNG export 계약, 미결 2건: 텍스트 앵커·표지 없는 책 T4)
- `card-share.md` — 공유·저장 시트 (카카오톡 1순위, V1=share_plus OS 시트, 권한 거부해도 공유는 됨)
- `deep-link-receive.md` — 받은 카드 → 책 담기 `/book/:id?from=share` (deep_link_handler 일반화, 미로그인 read-only→로그인→복귀, 콜드스타트 pending 소비, K-factor)
- `quote-list.md` — 인용구 목록·상세 (서재 탭 내 "인용구" 뷰 전제 — 별도 탭 vs 서재 내 뷰 결정 대기, Readwise 카드 문법 + 무드 필터)
- `docs/design/mockups/screens.html` — V1 그룹 1 화면 와이어프레임 (5화면 + 인터랙션·상태 노트, Ink-Paper-Copper 토큰)

남은 결정 (사용자):
- 카드 텍스트 위치 앵커(상/중/하) V1 여부 — 권고: V1은 폰트 크기 ±·정렬만, 앵커 V1.5
- 표지 없는 책에서 T4(표지발췌) — 권고: 비활성화
- 인용구 목록 위치 — 별도 탭 vs 서재 내 뷰 — 권고: 서재 내 뷰(4탭 유지)
- 인용 AI(차별화 ⑤) 출시 메시지에 "곧 출시" 노출 여부

다음 세션: 그룹 2(`home.md` / `me.md` / `book-detail.md`) → 그룹 3(`splash/login/auth-callback/library/book-search-sheet` 역정리 + 개선점). 그룹별로 필요 시 매니저 모드 보강. 그 후 Stage 2 구현 착수.

---

**산출 파일**: `docs/discovery/competitor-screen-analysis-2026-05-11.md`, `docs/discovery/mockups/competitor-references.html`, `docs/design/screens/{README,quote-input,card-editor,card-share,deep-link-receive,quote-list}.md`, `docs/design/mockups/screens.html`, `docs/sessions/2026-05-11-screen-design.md`
**문서 갱신**: `docs/DECISIONS.md`(내장 OCR 안 함 / 경량 아웃박스), `docs/STAGES.md`(Stage 2)
**코드 변경**: 없음 (설계 문서/목업만)
