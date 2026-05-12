# 2026-05-12 — 화면 설계 Phase B 그룹 1·2·3 완료 + 미해결 결정 일괄 (매니저 모드)

사용자: "전부 맡길게요, 직원들과 논의해서 진행하세요." → 매니저 모드 가상 팀(UI/UX·기획·Dart·QA 각 1) 병렬 협의 → ① 미해결 결정 4건 + 신규 2건 결정 ② 그룹 2 화면(홈·Me·책상세) 설계 ③ 그룹 3(이미 구현된 화면) 역정리.

## 가상 팀 협의

| 직무 | 임무 | 핵심 산출 |
|---|---|---|
| 기획 | 미해결 결정 4건 비준/반박 + 그룹 2 기능 범위 + 그룹 3 짚을 점 | 4건 전부 비준(권고대로) + "in-app 계정 삭제는 출시 블로커" + "홈은 단일 시간순 피드, 받은 카드 별도 섹션 X" + "안 되는 버튼은 V1에서 숨겨라" |
| UI/UX | 그룹 2 레이아웃·인터랙션·토큰 + 그룹 3 UX 흠 | 홈/Me/책상세 와이어프레임 + "빈 상태=단일 명확 CTA" + "점진적 공개로 첫 화면 가볍게" + `moodColors` 단일 정의처 + 그룹 3 흠 20여 건 |
| Dart | 그룹 2 구현(재사용/신규/난이도) + 그룹 3 코드 기준 사실 | "follow timeline·Realtime은 코드에 0 — 제거가 아니라 문서 마킹" + "받은 카드 함은 V1에서 빼라(저장소 없음)" + "`listMyQuotes` cursor 시그니처를 지금 박아라" + "회원 탈퇴는 Edge Function 필수" + 코드 기준 사실 + 버그 목록 |
| QA | 그룹 2 상태·엣지 전수 + 그룹 3 알려진 이슈 | 홈 9상태/Me 8상태/책상세 7상태 + 그룹 3 화면별 이슈 + "부분 실패 격리"·"raw $e 노출 0"·"막다른 골목 0" 7원칙 |

## 결정 (DECISIONS.md 2026-05-12 기록)

1. **카드 텍스트 위치 앵커(상/중/하): V1엔 안 넣음. V1.5.** V1 미세 조정 = 폰트 크기 ±·정렬만. (`templates/*.md`가 고정 좌표 모델이라 앵커는 5종 명세 재작성 + 디자인 재합의 필요.) 단 `card_editor_controller`의 텍스트 위치는 지금부터 상대좌표(0~1)로 직렬화.
2. **표지 없는 책에서 T4(표지발췌): 비활성화.** 썸네일 회색 + "표지가 필요해요" + 나머지 4종 정상 + "표지 추가하기" 인라인. (T4 정체성이 "이 색이 표지에서 나왔다"라 단색 degrade는 약속 거짓 + T1/T3와 구분 안 됨.)
3. **인용구 목록 위치: 별도 탭 X. 서재 탭 안 "책 ↔ 인용구" 세그먼트** (`/library?tab=quotes`). 4탭 유지.
4. **인용 중심 AI(차별화 ⑤): V1 출시 메시지·앱 내 어디에도 "AI" 단어/"곧 출시" 약속 안 함.** (Fable AI 인종차별 사건 — 1인 개발자가 "곧" 약속 깔면 사고 책임. 짧은 한국어 인용구는 AI 품질 빈약.) V1.5에 넣을 때도 입출력 좁고 사용자가 항상 편집하는 기능만.
5. **(신규) 홈 `/`의 "받은 카드 함": V1엔 안 넣음. V1 홈 = 순수 "내 인용 피드".** V1.5에 `received_cards` 테이블 + deep link 핸들러 INSERT로 추가. V1 deep link 수신 = "책 상세 + 서재 담기"이지 "카드 복제"가 아님. follow 타임라인도 V1.5에 같은 피드에 합류. `flows.md`/`client-architecture.md`의 `timelineProvider`·`publish to followers` Realtime은 코드에 0 — 문서를 "V1.5"로 마킹하는 게 작업. Realtime은 V2(DECISIONS 2026-05-10).
6. **(신규) `quote_repository.listMyQuotes` cursor 시그니처 확정** — `listMyQuotes({String? bookId, Set<QuoteMood>? moods, ({DateTime createdAt, String id})? after, int limit = 15})`, cursor-after, offset 금지. 누적 상태는 `Notifier<AsyncValue<List<Quote>>>` + `_isLoadingMore` 가드. (`bookSearchPagedProvider`는 README 주석에만 있고 코드 없음 — 참고 구현 없음.)

→ `competitor-screen-analysis §7` 미해결 5건 + 신규 모두 해소.

## 산출물

화면 설계 문서 13개 (`docs/design/screens/`):
- 그룹 1: `quote-input.md` · `quote-list.md` · `card-editor.md` · `card-share.md` · `deep-link-receive.md` (2026-05-11 작성, 이번에 미결 해소 반영)
- 그룹 2: `home.md`(내 인용 피드 — 받은 카드 함 V1 제외, FAB 없음, cursor-after) · `me.md`(섹션형 — 내데이터/설정/정보 + Markdown export + 회원 탈퇴 2단계, 친구찾기 숨김, 다크모드 V1.5) · `book-detail.md`(`deep-link-receive.md`와 같은 컴포넌트의 두 진입 모드 — read-only 보강 + 인용구 섹션 + `?from=` 분기 + raw `$e` 제거)
- 그룹 3 역정리(현행 동작 코드 기준 + 수정·보강 권고를 §7에 분리): `splash.md`(개선 3건) · `login.md`(개선 5건) · `auth-callback.md`(개선 4건) · `library.md`(개선/보강 8건) · `book-search-sheet.md`(개선/보강 9건)
- `README.md` 갱신(인벤토리 ✅ 표시, 미해결 결정 전부 해소, 출시 블로커 정리)

문서 갱신: `DECISIONS.md`(2026-05-12 결정 묶음), `STAGES.md`(화면 설계 Stage 0b 연장 + Stage 2~5 재정리 — 출시 블로커, 친구찾기 V1.5, 구현 순서), `card-editor.md §7`/`quote-list.md §1`(미결 → 해소).

코드 변경 없음 (설계 문서만). `screens.html`은 그룹 1만 — 그룹 2·3 와이어프레임 추가는 다음 단계.

## 발견한 코드 레벨 버그 (구현 시 "수정 항목" — 각 화면 문서 §7에 박힘)

- `book_detail_screen.dart` — `'책을 불러오지 못했어요: $e'` raw 에러 노출
- `library_screen.dart` — `_ErrorView`가 `'($error)'` raw 노출 + [다시 시도] 버튼 없음; `'서재 추가 실패: ${e.message}'` raw 노출
- `me_screen.dart` — 긴 이메일 시 `Text` 오버플로 미처리; "친구 찾기" 빈 `onTap: () {}`(무반응 = 버그처럼 보임)
- `book_search_sheet.dart` — 검색 전(query empty)인데 `_EmptyState`("찾는 책이 없어요") 노출 위험; ISBN 직접 등록 정상 경로 부재; ISBN 패턴 감지 안 함; `connectivity_plus`·`suppressAddedToast`·`PopScope`(`_saving` 중 닫기 차단) 미연동; `_onPick` 토스트 카피 부정확(실제론 `public.books` upsert); `code == 'RATE_LIMIT'`가 실제 도달하는 코드와 일치하는지 검증 필요; 로딩 중 캐시 결과 못 봄(`when(loading:)`이 화면 전체 덮음)
- `splash_screen.dart` — 500ms 안전망이 느린 기기에서 로그인 화면 깜빡임 유발 가능; deep link cold start payload 보존 경로 없음
- `login_screen.dart` / `auth_callback_screen.dart` — 매직링크 흐름에서 `?from=` 미보존(원래 화면 복귀 실패); 매직링크 [다시 보내기] UI 부재; 콜백 10s 타임아웃 후 사유 안내 없음; PKCE 교환 실패가 `debugPrint`로만
- `deep_link_handler.dart` — `/auth/callback` 외 URI 무시 → `book/...` deep link 미동작, "URI dispatcher"로 일반화 필요(받는 사람 흐름의 갭)

## 다음

1. `screens.html`에 그룹 2·3 와이어프레임 추가
2. (정합) `flows.md`/`client-architecture.md`의 follow `timelineProvider`·Realtime 절을 "V1.5"로 마킹 — 코드엔 0
3. **Stage 2 구현 착수** — `quotes` 테이블 → `quote_repository`/`quote_providers`/`createQuoteController`/`quote_outbox` → `quote_input_screen` 재작성 → `home_screen` 재작성 → `quote_list_view` → `me_screen` 보강 → `book_detail_screen` 보강. pubspec: `shared_preferences`·`connectivity_plus`·`url_launcher`·`package_info_plus`
4. **출시 블로커 준비** (Stage 5로 묶었지만 일찍): in-app 계정 삭제 Edge Function, 개인정보처리방침·이용약관 페이지 호스팅

---

**산출 파일**: `docs/design/screens/{home,me,book-detail,splash,login,auth-callback,library,book-search-sheet}.md`(신규 8), `docs/design/screens/README.md`·`card-editor.md`·`quote-list.md`(갱신), `docs/DECISIONS.md`·`docs/STAGES.md`(갱신), `docs/sessions/2026-05-12-screen-design-b.md`
**코드 변경**: 없음
