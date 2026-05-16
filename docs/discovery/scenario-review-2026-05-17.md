# 출시 전 시나리오 기반 개선점 발굴

**기준일**: 2026-05-17 (Stage 3 완료, Stage 5 진입 직전)
**작성 방식**: 매니저(Claude) + 가상 팀(기획자·UI/UX·QA) 병렬 협의. P0 후보는 매니저가 실제 코드 대조로 재판정.
**참조**: `docs/app-scenarios.md` (V1 동선) · `docs/design/screens/*.md` · `lib/features/*` · `docs/STAGES.md`

---

## 0. Executive Summary

14개 페르소나/시나리오를 만들어 V1 동선을 mental walkthrough → **UX 마찰 17건 + 엣지/실패 18건 = 총 35건** 발견. P0 후보 6건은 코드 대조로 재판정.

| 분류 | 항목 수 | 권고 |
|---|---|---|
| **P0 — 출시 전 처리 강력 권고** | 2건 | F1·B11 — 데이터 손실·신규 가입 차단 위험 |
| **P0 검증 필요 (실기기 테스트)** | 1건 | B9 — 저사양 release APK에서 카드 에디터 OOM 의심 |
| **P1 — 출시 후 1~2주 내 처리** | 12건 | 흔한 사용 마찰·기능 실패 (데이터 손실은 없거나 복구 가능) |
| **P2 — V1.5+ 백로그** | 14건 | 드물거나 미래 가치 |
| **시나리오 set 자체** | 14개 | 베타·dogfooding의 회귀 체크리스트로 재활용 가능 |

---

## 1. 시나리오 set (14개, 기획자 산출)

### 일반 타겟층 (V1 주력) 6개
- **S1. 박지원 (28, 마케터, S23, 출근길 지하철)** — OCR → 클립보드 → ＋ → "노르웨이" → 페이지 87 → "먹먹"+"새벽3시" → 저장. 마찰: 한 손 + 검색 시트로 본문 가림 / 지하 캐시 미스 출구 모호.
- **S2. 김서연 (34, 디자이너, Z Fold5 펼침, 점심 카페)** — 시집 5행 직접 타이핑 → T5 9:16 → 인스타 스토리. 마찰: 폴드 펼침에서 1080 캔버스 좁게 lay out / 9:16에서 시 마지막 행 잘림.
- **S3. 이정훈 (41, 초등교사, A34, 주말 몰아서)** — *총·균·쇠* 한 책에서 5구절 연속 입력. 마찰: 같은 책 5번 재검색, 홈 피드 시간순이라 책 단위 묶음 없음.
- **S4. 최유진 (23, 대학원생, Pixel 7a, 새벽 침대)** — 카드 에디터 T2 ↔ T3 ↔ T2 + [A−] + 9:16 → 인스타 → 카톡 단톡 4개. 마찰: ↻ 후 T2 복귀 시 폰트 크기 시각 점프 / paper 배경 새벽 눈부심.
- **S5. 한도윤 (36, 개발자, S24 Ultra, 솔로 컬렉션)** — 6개월 47개 → /me Markdown → 본인 메일. 마찰: 텍스트 검색 없음 / Markdown 텍스트 인텐트 한도 위험.
- **S6. 윤하늘 (29, HR, A54, 단톡방만)** — T1 1:1 → 카톡 책 동호회 → [다시 공유] → 1:1방. 마찰: 단순 이미지 → 어떤 책인지 묻는 댓글 / 워터마크 ON/OFF 시각적 미세.

### 일반 보조 1개
- **S7. 강민호 (40, 자영업, S22, 만화 *송곳*)** — OCR 광고문 섞임 → 본문 안 수동 삭제 → 시리즈 5권 중 1권 선택 모호. 마찰: OCR 정제가 검색·붙여넣기보다 김 / 시리즈 권수 표지 비슷.

### 엣지 페르소나 7개
- **S8. 서은아 (31, 번역가, Note20, 한 달 만에 재진입)** — 한 달 전 draft 자동 복원(160자+책+무드). 마찰: draft 시점 단서 없음 / 무드 칩 5종 재학습.
- **S9. 정복희 (63, 은퇴 교사, A24, 시스템 글씨 1.3x, 시각 저시력)** — 매직링크 → 메일 왕복 → 큰 글씨 모드. 마찰: 매직링크가 어르신에게 비직관적 / 1.3x에서 무드 칩 줄바꿈 + ＋3 인디케이터 잘림.
- **S10. Linh Nguyen (27, 베트남 출신, A14, 한국어 비원어민)** — *어린 왕자* 한·베 자판 토글. 마찰: 무드 칩 한국어 정서 매핑 실패 / 약관·개인정보 한국어 전용.
- **S11. 김민재 (15, 중학생, J7 Prime 저사양 5.5인치 Android 8)** — 콜드 3.8s → 알라딘 4s → palette 타임아웃 → fallback. 마찰: 5.5인치에서 컨트롤이 화면 절반 / OOM 위험.
- **S12. 박재민 (38, 인천공항 라운지, captive portal/비행)** — 알라딘 실패 → 책 비운 채 저장 → 아웃박스 큐잉 → 비행 후 flush. 마찰: captive portal 200 응답이 "결과 0건"으로 잘못 표시 / 책 없이 저장한 인용구 사후 책 연결 단축 없음.
- **S13. 조다솜 (45, 워킹맘, S21 + Tab S8, 다기기)** — 태블릿 신규 설치 → 매직링크 → 폰의 5개 동기화. 마찰: 태블릿 10.5인치에서 1080 캔버스 가운데 작게 / 다기기 매직링크 발송 시 메일 앱 기기 vs 의도 기기 불일치.
- **S14. 이수정 (33, 신생아 엄마, A52, 데이터 한도 초과, 한 손)** — 한 손 엄지 타이핑 25자 → throttle 알라딘 6s. 마찰: 한 손으로 우상단 [저장] 도달 어려움 / 표지 throttle로 책 식별 어려움.

> 시나리오 본문 풀버전이 필요하면 본 세션의 planner 산출 그대로 복원 가능.

---

## 2. UX 마찰 (UI/UX 디자이너 산출, 17건)

severity·근거·제안은 designer 에이전트 산출 그대로. 매니저 검증 코멘트는 본 섹션 8에 정리.

| # | 제목 | severity | 출처 |
|---|---|---|---|
| F1 | 매직링크 갇힘 — 이메일 오타 시 탈출구 없음 | **P0** | S8, S9, S13 |
| F2 | 책 없이 저장한 인용구 사후 연결 경로 부재 | ~~P0~~ → **P1** | S12, S3, S7 |
| F3 | Captive portal 오탐 "결과 0건" | **P1** (← P0에서 강등 검토) | S12 |
| F4 | 한 손 엄지 도달 불가 — 공유 버튼 위치 | P1 | S1, S14 |
| F5 | Draft 복원 시점 단서 없음 | P1 | S8, S4 |
| F6 | 오프라인 시 캐시 책도 차단됨 | P1 | S1, S12, S14 |
| F7 | 동일 책 반복 검색 마찰 (최근 책 없음) | P1 | S3, S6, S8 |
| F8 | "다른 느낌 ↻" 후 T2 복귀 폰트 점프 | P1 | S4 |
| F9 | 무드 칩 글씨 확대 시 줄바꿈 + 버튼 밀림 | P1 | S9, S10 |
| F10 | 워터마크 토글 시각 피드백 미세 | P1 | S6 |
| F11 | 폴드·태블릿 캔버스 좌우 여백 과대 | P1 | S2, S13 |
| F12 | 저사양 소화면 카드 에디터 레이아웃 + OOM | P1 | S11 |
| F13 | 아웃박스 "동기화 대기" 배너 미구현 | P1 | S1, S12, S14 |
| F14 | 무드 칩 한국어 정서 장벽 (비원어민) | P2 | S10 |
| F15 | 책 검색 시트가 본문 가림 | P2 | S1, S2 |
| F16 | 홈 피드 시간순 — 책 맥락 재독 어려움 | P2 | S3, S5 |
| F17 | Markdown 내보내기 텍스트 인텐트 서식 깨짐 | P2 | S5 |

---

## 3. 엣지·실패 (QA 테스터 산출, 18건)

| # | 제목 | severity | 출처 |
|---|---|---|---|
| B1 | 아웃박스 동시 flush 시 동일 인용구 중복 INSERT | ~~P0~~ → **P1** | S12 |
| B2 | 책이 사라진 상태로 flush — FK 위반 → 영구 미전송 루프 | P1 | S12 |
| B3 | CardEditorController `_initialized` 잔존 — 본문 수정 후 미반영 가능 | P1 | S4, S13 |
| B4 | 대용량 Markdown — 안드로이드 인텐트 한도 → 크래시 가능 | P1 | S5 |
| B5 | page 입력값 0 — DB CHECK 위반 시 generic 에러 메시지 | P1 | S3, S10 |
| B6 | 클립보드 2000자 초과 — 어디서 잘라야 할지 불명 | P1 | S1, S7 |
| B7 | draft [지우기] 후 debounce timer 발동 race | P2 | S8 |
| B8 | 매직링크 콜백 10초 타임아웃 — captive portal에서 사유 안내 없음 | P1 | S9, S12 |
| B9 | PNG 캡처 OOM — 저사양 1080 절대 캔버스 + AnimatedSwitcher + _MiniCard | **P0 (검증 필요)** | S11 |
| B10 | paletteSlotIndex — 표지 없는 인용구에서 fallback 5색 시각 차이 없음 | P2 | S4, S8 |
| B11 | `submitUpdate` clearBook 로직 — 책 prefill 실패 시 책 연결 silent 해제 | **P0** | S4, S8 |
| B12 | `quick_share_screen` — 데이터 도착 전 PNG 캡처 시 zero-width 예외 | P1 | S4 |
| B13 | Markdown 내보내기 — manual_book_text 공백 차이로 별도 그룹 | P2 | S5, S10 |
| B14 | 카드 에디터 undo — `applyState` 후 첫 변경 전엔 undoStack 빈 상태 | P2 | S2, S4 |
| B15 | 알라딘 query URL 인코딩 — Edge Function 의존 (코드 미확인) | P2 | S3, S7 |
| B16 | 시스템 글씨 1.3x — SegmentedButton 고정 fontSize로 레이블 잘림 | P1 | S9 |
| B17 | `recordShare` fire-and-forget — 앱 강제 종료 시 cards 미기록 | P2 | S4, S6 |
| B18 | `_recommendRatio` — 모든 비율 초과 시 추천 null로 액션 버튼 사라짐 | P2 | S3, S4 |

---

## 4. P0 후보 6건 — 매니저 코드 검증 결과 (재판정)

QA·UX 산출에서 P0로 표시된 항목 중 데이터 손실·심사 reject·신규 가입 차단 위험으로 분류된 6건을 실제 코드에서 대조.

### ✅ P0 유지 — F1: 매직링크 _SentNotice 탈출구 없음
- 코드: `lib/features/auth/login_screen.dart:18` `_linkSent` 한 번 `true` 되면 다시 `false`로 되돌리는 코드 없음 (`grep`으로 재전송·다른 이메일 입구 미발견)
- 영향: 이메일 오타 시 앱 재시작이 유일 → 첫 가입 차단
- 출시 전 처리 가치 **높음** — 신규 사용자 funnel 첫 단계 보호

### ✅ P0 유지 — B11: 책 연결 silent 해제
- 코드 흐름 확정:
  1. `quote_input_screen.dart:127-132` 편집 모드 `_loadExistingQuote`에서 `getById(quote.bookId!)` 실패 시 `catch (_) {/* 책 prefill 실패 무시 */}` → `_book = null` 유지
  2. `quote_input_screen.dart:271-277` `_buildInput()` → `bookId: _book?.id` = null
  3. `quote_input_screen.dart:314` `submitUpdate(quoteId, _buildInput())`
  4. `quote_providers.dart:79` `clearBook: input.bookId == null` → 책 연결 영구 해제
- 영향: 사용자가 책은 안 건드리고 무드만 바꾸려 했는데, 책 prefill 네트워크 실패가 silent → update 시 책 연결이 사라짐 (복구 불가)
- 트리거: 저속 회선·book 데이터 일시 미응답·release에서 더 빈번
- 출시 전 처리 가치 **높음** — silent 데이터 손실은 사용자 신뢰 직접 손상

### ⚠️ P0 검증 필요 — B9: 저사양 카드 에디터 OOM (release-only 의심)
- 코드: `card_editor_screen.dart:800` `_MiniCard`가 `QuoteCard(...)` 빌드 — 미니카드도 절대 1080 사이즈 위젯 사실. `_TemplateStrip:358`에서 5개 미니카드 + 본 캔버스 + `AnimatedSwitcher:678`로 전환 시 이중 오프스크린 버퍼.
- 정적 분석으로는 메모리 압박 가능성 분명하나, 실제 OOM 발생 여부는 **실기기 검증 없이 단정 불가**. 메모리 메모(`feedback_release_only_traps.md`)에 따르면 debug·flutter test 통과해도 release에서만 깨지는 사례 2건 (INTERNET, debugNeedsPaint)이 이미 있었음 — 같은 패턴 가능성.
- 권고: 출시 전 **release APK를 J7 Prime급 또는 Android 8 저사양 에뮬레이터에서 카드 에디터 진입 + 템플릿 5회 전환 + PNG 캡처** 시나리오로 확인. OOM 재현되면 P0 → 즉시 fix. 미재현이면 P1로 강등.

### ⤵️ P0 → P1 강등 — F2: 책 없이 저장 → 영구 고아
- 검증: `quote_input_screen.dart:107` `_loadExistingQuote` 함수 존재 = `?quoteId=` 편집 모드 구현됨
- 편집 모드에서 `_onPick`(`book_search_sheet.dart:60-88`)을 통해 책 검색·연결 가능 → **영구 고아 아님**
- 실제 마찰은 "편집 모드 진입 단축 부재" 차원 (홈/서재 카드에 [✏ 편집] 액션이 무드·텍스트·책 연결 모두 한꺼번에 다루는 단일 진입점 — 책 연결만을 위한 1탭 단축 없음)
- 재판정: **P1** — 발견성 개선, 출시 후 1~2주 내

### ⤵️ P0 → P1 강등 — B1: 아웃박스 동시 flush race
- 검증: `quote_outbox.dart:64-79` `flush()`에 mutex 없음 (코드 사실 확인)
- 다만 트리거는 `home_screen` 포그라운드 복귀 1곳만 (`STAGES.md`상 "포그라운드 복귀 시 best-effort flush") → 사용자가 동시에 두 번 flush 트리거할 시나리오 매우 드물다
- 데이터 중복 발생해도 사용자가 홈 피드에서 발견·삭제 가능 (복구 가능)
- 재판정: **P1** — fix는 `bool _isFlushing` 진입 차단 1줄로 충분. 출시 후 처리해도 안전

### ⏬ P0 → P1 (designer가 이미 P1로 표기, 본 검증 부재) — F3: captive portal 오탐
- `book_repository.dart` `_invokeAladin`은 `FunctionException` catch 존재 (Supabase SDK가 비-2xx 시 던짐). 200+비-JSON 분기는 SDK 내부 처리에 의존
- 발생 환경: captive portal 자체가 드뭄. release에서 재현 어려움
- 재판정: **P1 유지** (이미 designer가 P1로 처리)

---

## 5. 우선순위 매트릭스 (severity × 구현 비용)

구현 비용 표기: S(반나절 이내) / M(1~2일) / L(3일+)

### 🔴 P0 — 출시 전 처리 강력 권고 (2건)
| # | 제목 | 비용 | 핵심 변경 위치 |
|---|---|---|---|
| F1 | 매직링크 _SentNotice — 다른 이메일 입구 추가 | **S** | `login_screen.dart` |
| B11 | submitUpdate clearBook — 책 prefill 실패 시 원본 bookId 보존 | **S** | `quote_input_screen.dart` + `quote_providers.dart` |

### 🟠 P0 검증 필요 (1건)
| # | 제목 | 비용(검증) | 비용(fix) |
|---|---|---|---|
| B9 | 저사양 카드 에디터 OOM | **S** (실기기 1회) | OOM 재현 시 **M** (미니카드 경량화) |

### 🟡 P1 — 출시 후 1~2주 내 (12건)
| # | 제목 | 비용 |
|---|---|---|
| F2 | 책 연결 1탭 단축 (편집 진입성) | M |
| F3 | Captive portal 오탐 분기 | M |
| F4 | 카드 에디터 [공유] 위치 — 하단으로 | S |
| F5 | Draft 시점 단서 (savedAt 표시) | S |
| F6 | 오프라인 시 캐시 책 노출 분리 | M |
| F7 | "최근 선택한 책" 시트 초기 섹션 | M |
| F8 | 템플릿 전환 시 fontStep 보존 | S |
| F9 | 무드 칩 1.3x 글씨 레이아웃 가드 | S |
| F10 | 워터마크 토글 상태 텍스트 명시 | S |
| F11 | 폴드·태블릿 600dp+ 2-column 또는 캔버스 fit 조정 | M |
| F12 | 저사양 소화면 컨트롤 압축 | M |
| F13 | "동기화 대기 N개" 배너 | S |
| B1 | 아웃박스 동시 flush 진입 차단 | S |
| B2 | flush FK 위반 분리 처리 | S |
| B3 | 편집 후 카드 에디터 복귀 시 `_initialized` 리셋 | S |
| B4 | Markdown 대용량 임계 가드 (또는 XFile 전환) | S |
| B5 | page 0 클라이언트 검증 | S |
| B6 | 클립보드 2000자 초과 truncate + 안내 | S |
| B8 | 매직링크 콜백 타임아웃 사유 안내 | S |
| B12 | quick_share_screen 데이터 도착 보장 | S |
| B16 | SegmentedButton 고정 fontSize → textTheme | S |

### 🟢 P2 — V1.5+ 백로그 (14건)
F14, F15, F16, F17, B7, B10, B13, B14, B15, B17, B18 — 본 문서에 등재만 하고 출시 후 사용자 반응에 따라 우선순위 재조정.

---

## 6. 권고 — Stage 5 진입 전 처리 옵션

매니저 권고는 **두 갈래 동시 처리**:

**갈래 A — 출시 블로커 즉시 fix (P0 2건 + 검증 1건)**
1. **F1 매직링크 탈출구**: `_SentNotice`에 [다른 이메일로 다시 보내기] TextButton 추가 (1줄 토글). 반나절.
2. **B11 책 연결 silent 해제**: `_loadExistingQuote`에서 `_originalBookId` 보존 → `_buildInput`에서 `_book == null && _originalBookId != null`이면 원본 bookId 유지. 반나절.
3. **B9 OOM 검증**: 보유 중인 폰(SM F956N)으로는 한계가 있으므로 Android Studio 에뮬레이터에서 Pixel 2 + Android 8.1 + 1.5GB RAM 프로파일로 카드 에디터 진입 + 템플릿 5회 전환 + PNG 캡처 + 공유까지 시도. release APK + dart-define 동반. 결과에 따라 P0/P1 확정.

이 3건 끝나면 **Stage 5 본 작업 진입**.

**갈래 B — Stage 5 본 작업 (스토어 등록·PostHog·인스타 카드·커뮤니티 게시)**

위 갈래 A를 별도 PR(예: PR13 — "출시 직전 P0 fix 2건 + OOM 검증")로 처리한 뒤, 기존 계획대로 Stage 5 본 작업으로 넘어간다. **P1 12건은 출시 후 첫 빠른 fix 묶음(V1.0.1 또는 hotfix 시리즈)으로 분류해 백로그에 등재**.

---

## 7. 후속 활용 — 시나리오 set의 재사용

14개 시나리오는 출시 후에도 가치 있음:
- **베타·dogfooding 회귀 체크리스트**: 새 PR마다 영향받는 시나리오만 manual walkthrough
- **PostHog funnel 정의 근거**: 시나리오별 핵심 이벤트(첫 인용구 저장·첫 카드 공유·다음 진입까지 일수)를 funnel 정의에 매핑
- **인스타·디스콰이엇 게시 narrative**: S4·S6·S3가 그대로 마케팅 카피의 인물 모델

---

## 8. 매니저 코멘트 — 본 워크에서 배운 점

- **자율 모드 + 4직무 분담**이 단독 검토보다 35건 발견을 가능하게 했다 (단독이면 핵심 5~10건만 봤을 가능성).
- **P0 후보는 코드 대조 필수**: 정적 분석 기반 P0 표기 6건 중 2건은 실제 P1로 강등됨 (F2 편집 모드 존재, B1 트리거 빈도 낮음). qa-tester가 코드를 잘 본 수준이라 신뢰도 높았지만, "영구 고아" 같은 강한 단정은 매니저 확인 후에야 P1로 정정됨.
- **release-only 함정 의심 항목(B9)을 단정 짓지 않고 검증 단계로 보존**: 메모리에 기록된 INTERNET·debugNeedsPaint 2건 hotfix와 동일한 패턴 위험이라 실기기 검증 비용을 들이는 것이 안전.
- 본 보고서의 모든 제안은 "사용자 결정 옵션" 형태 — 매니저가 임의로 ad-hoc fallback·workaround를 권고하지 않음. P1 12건은 출시 후 첫 hotfix 시리즈로 묶을지, 일부를 갈래 A에 합칠지는 사용자 선택.
