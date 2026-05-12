# 화면 세부 설계 — 인덱스 & IA

**시작**: 2026-05-11 · **입력 근거**: `docs/discovery/competitor-screen-analysis-2026-05-11.md` (경쟁앱 해부 + 화면별 권고)
**산출물**: 화면당 1파일, 아래 7섹션 고정 구조. 시각 목업은 `docs/design/mockups/screens.html`.

> 이 문서들은 **구현 명세**다. `lib/app/router.dart`의 실제 라우트, `lib/core/theme/tokens.dart`의 토큰, `docs/design/templates/`의 카드 명세, `docs/discovery/error-handling.md`의 에러 분류, `docs/db-schema.md`의 스키마, `docs/app-scenarios.md`의 V1 동선을 단일 진실로 참조한다. 모순이 보이면 코드 쪽이 우선 — 문서를 고친다.

---

## 화면 인벤토리 & 구현 상태 (2026-05-14 — Stage 2 PR1~5 기준)

| 그룹 | 화면 | 라우트 | 구현 상태 | 실제 파일 | 설계 문서 |
|---|---|---|---|---|---|
| 2 | 홈 (내 인용 피드) | `/` | ✅ **구현** (PR3) | `lib/features/home/home_screen.dart` · `quote/state/quote_feed_provider.dart` · `quote/presentation/widgets/quote_list_card.dart` | [`home.md`](home.md) |
| 1 | 인용구 입력 | `/quote/new[?bookId=]` | ✅ **구현** (PR2) | `lib/features/quote/quote_input_screen.dart` · `data/quote_draft.dart` · `presentation/widgets/mood_chips.dart` | [`quote-input.md`](quote-input.md) |
| 1 | 인용구 목록 (서재 "인용구" 세그먼트) | `/library?tab=quotes[&mood=]` | ✅ **구현** (PR4) | `lib/features/quote/presentation/quote_list_view.dart` (서재 화면 내 탭) | [`quote-list.md`](quote-list.md) |
| 3 | 서재 (책↔인용구 세그먼트) | `/library` | ✅ **구현** (PR4) | `lib/features/library/library_screen.dart` | [`library.md`](library.md) |
| 2 | 내 정보 (프로필·내보내기·약관·탈퇴) | `/me` | ✅ **구현** (PR5) | `lib/features/me/{me_screen.dart, state/me_providers.dart, data/{markdown_exporter,quote_export}.dart}` · `lib/features/account/account_deletion.dart` · `supabase/functions/delete-account/` *(배포 미완)* | [`me.md`](me.md) |
| 2 | 책 상세 | `/book/:id` | 🟡 **부분** — read-only + 별점(`user_books.rating`). "이 책에서 모은 N구절"·"인용구 추가" CTA·설명 점진공개·`isInLibrary` = **PR6** | `lib/features/book/book_detail_screen.dart` · `presentation/widgets/star_rating.dart` | [`book-detail.md`](book-detail.md) |
| 1 | 받은 카드 → 책 담기 (deep link 진입) | `/book/:id?from=share` | 🟡 **부분** — `/book/:id` read-only만. `from=share` 분기 + `deep_link_handler` 일반화 = **PR6** | `lib/app/deep_link_handler.dart` (현재 `/auth/callback`만 처리) | [`deep-link-receive.md`](deep-link-receive.md) |
| 1 | 카드 에디터 | `/quote/:id/card` | ⏳ **스텁** — **Stage 3** | `lib/features/card_editor/card_editor_screen.dart` (스텁) | [`card-editor.md`](card-editor.md) |
| 1 | 카드 공유·저장 시트 | (모달, 카드 에디터에서) | ⏳ **없음** — **Stage 3** | — | [`card-share.md`](card-share.md) |
| 3 | 스플래시 | `/splash` | ✅ **구현** (Stage 1) | `lib/app/splash_screen.dart` | [`splash.md`](splash.md) |
| 3 | 로그인 | `/auth/login` | ✅ **구현** (Stage 1) | `lib/features/auth/login_screen.dart` · `auth_controller.dart` | [`login.md`](login.md) |
| 3 | 인증 콜백 | `/auth/callback` · `/callback` | ✅ **구현** (Stage 1) | `lib/features/auth/auth_callback_screen.dart` | [`auth-callback.md`](auth-callback.md) |
| 3 | 책 검색 시트 | (모달, 서재·인용입력에서) | ✅ **구현** (Stage 1) | `lib/features/book/presentation/book_search_sheet.dart` | [`book-search-sheet.md`](book-search-sheet.md) |

✅ 구현·동작 / 🟡 일부 구현(다음 PR에서 보강) / ⏳ 스텁·미구현(Stage 3). 라우트·구조 진실 = `lib/app/router.dart`. 동선 = `docs/app-scenarios.md`.

> 화면 설계 문서 13개 1차 작성 완료(2026-05-12). 그룹 3 역정리 문서들은 §7에 "현행 동작"(코드 기준) + "수정·보강 권고"를 분리해 담았는데, 그 권고 상당수는 Stage 2 PR1~5에서 함께 처리됨(raw `$e` 노출 제거, 잘못된 "서재 추가" 토스트 제거, `me_screen` 빈 `onTap`·긴 이메일 오버플로 등). 남은 권고·버그는 각 문서 §7 + `docs/STAGES.md` 백로그 + 세션 로그(`docs/sessions/2026-05-12-screen-design-b.md` ~ `2026-05-14-stage2-pr5.md`).

---

## IA 다이어그램 (텍스트)

```
/splash ──(세션 있음)──▶ ┌─────────── StatefulShellRoute (BottomNav 4슬롯) ──────────┐
        │ ✅             │  [0] /          홈 — 내 인용 피드  ✅                       │
        └─(없음)─┐       │  [1] /library   서재 — [책↔인용구] 세그먼트  ✅            │
                 │       │  [2] (＋ sentinel) ──push──▶ /quote/new  (풀스크린, 셸 밖)  │
   /auth/login ◀─┤ ✅    │  [3] /me        내 정보 — 프로필·내보내기·약관·탈퇴  ✅     │
        │ ✅      │       └────────────────────────────────────────────────────────────┘
   /auth/callback│       풀스크린 (rootNavigatorKey, 셸 밖):
   /callback  ✅ │         /quote/new[?bookId=]   인용구 입력 (직접 입력 / 클립보드 붙여넣기)  ✅
                 │           └─ "카드 만들기 →" ──push──▶ /quote/:id/card  카드 에디터  ⏳ 스텁(Stage 3)
   게스트 허용 ◀─┘                                          └─ "공유" ──▶ 공유·저장 시트(모달)  ⏳
   /book/:id[?from=]   ✅ read-only(보강 PR6)                            └─ 카카오톡 → 받는 사람  ⏳
        ▲
        └── 받는 사람 deep link: io.github.tgparkk.bookquote://book/:id?from=share   ⏳ deep_link_handler 일반화(PR6)
              ├─ 로그인됨   → 책 상세 + "내 서재 담기" 1탭
              └─ 미로그인   → 책 상세 read-only → "담기" → /auth/login → 복귀해서 담기

  모달 시트(어느 셸 탭에서도): showBookSearchSheet  (알라딘 검색 + 캐시 사전조회)  ✅
```

✅ 구현 / ⏳ 스텁·미구현(다음 PR 또는 Stage 3). 탭 구조·풀스크린 규칙·게스트 라우트는 `DECISIONS.md 2026-05-10 (go_router 구조)` + `lib/app/router.dart`가 진실. 홈 = "내 인용 피드"(`DECISIONS 2026-05-12` — "받은 카드 함"·follow 타임라인 합류는 V1.5). 서재 책 카드 "N구절 배지"·"표지색 띠"는 STAGES 백로그.

---

## 화면 문서 7섹션 구조 (모든 `*.md` 공통)

1. **목적 / 진입·이탈 / 라우트** — 이 화면이 왜 있나, 어디서 들어오고 어디로 나가나, 라우트·파라미터.
2. **레이아웃 와이어프레임 (ASCII)** — 영역 구성. 픽셀 아닌 구조. `screens.html`의 해당 목업과 1:1.
3. **상태** — 로딩 / 빈 / 에러 / 오프라인 / 권한거부. `error-handling.md`의 분류(Network/Auth/Validation/Business/External/Storage × Inline/Toast/Modal/Empty)로 기술. 각 상태에 심각도.
4. **인터랙션 명세** — 탭·스와이프·드래그·시트 동작·애니메이션·키보드. "한 번 탭 = 인라인 핸들"(더블탭 숨김 금지), 언두 정책 등.
5. **디자인 토큰 매핑** — `tokens.dart`의 색/간격/타이포/radius/shadow를 영역별로. 새 토큰 필요 시 명시.
6. **재사용 컴포넌트 / 신규** — 기존 위젯(`BookCover`, `showBookSearchSheet`, `_DragHandle` 등)과 provider, 신규로 만들 것.
7. **엣지 케이스 / 접근성** — `competitor-screen-analysis §6`의 공통 8원칙 적용 + 화면 고유 엣지 + 대비(WCAG AA 4.5:1) / 터치 타깃 48dp / 스크린리더 semantics / 색만으로 구분 금지.

---

## 모든 화면 공통 8원칙 (각 문서 §7 "교차 관심사" 박스에 한 줄씩 — `competitor-screen-analysis §6`)

1. 오프라인 = 1급 상태 (V1 경량 아웃박스, DECISIONS 2026-05-11)
2. 데이터 절대 유실 금지 (draft/아웃박스 로컬 영속화 — 앱 kill·크래시·로그아웃·디스크풀에도 복구)
3. PII 로그 금지 (인용구 텍스트·검색어 raw·붙여넣기 내용은 Sentry/PostHog 미전송 — 코드·길이·screen 이름만)
4. 막다른 골목 금지 (anti-북모리: 권한 거부·검색 0건·미설치 어디서든 "직접 입력"·"ISBN 직접 등록"·"이미지 저장 후 직접 올리기" 출구 노출, 광고 게이트 0)
5. 시트 왕복 시 입력 보존 (책 검색 시트는 모달 → 입력 화면 state 안 건드림, 회귀 테스트)
6. 에러 표시 일관성 (Inline=폼검증 / Toast=일시·정보 / Modal=진행불가·세션만료 / Empty=데이터 없음 — Toast 폭탄 X)
7. 인증 가드 (`/quote/new`·`/quote/:id/card` 등 쓰기 화면은 go_router redirect 차단 + repository `NOT_AUTHENTICATED` 2차 방어; `/book/:id`는 게스트 허용 — deep link용)
8. "미리보기 = export" 보장 (카드 미리보기 = export와 같은 위젯 트리, 스케일만 다름 — 스냅샷 테스트로 회귀 감지, `testing-strategy.md §6`)

---

## 진행 메모

- 화면 설계 13개 완료(2026-05-12) → **Stage 2 PR1~5 구현 완료**(2026-05-14): 인용구 데이터 레이어·입력 화면·홈 피드·서재 세그먼트·책 별점·내 정보 화면. 다음 = **PR6**(책 상세 보강 + `deep_link_handler` 일반화) → **Stage 3**(카드 에디터·공유·deep link 받기 — 가장 공들일 단계). 상세는 `docs/STAGES.md` "▶ 다음 세션 시작점" + 세션 로그.
- 미해결 결정 전부 해소(DECISIONS 2026-05-11·2026-05-12): ① OCR 내장 안 함(클립보드 붙여넣기) ② 오프라인 = 경량 아웃박스 V1 ③ 카드 텍스트 앵커 = V1.5(V1은 폰트 크기 ±·정렬만) ④ 표지 없는 책 T4 = 비활성화 ⑤ 인용 AI = "AI" 단어/곧 출시 약속 안 함 ⑥ 홈 받은 카드 함 = V1.5(V1 홈 = 내 인용 피드) ⑦ 인용구 목록 = 서재 탭 내 세그먼트 ⑧ `listMyQuotes` cursor 시그니처 확정 / 책 별점 = `user_books.rating` 정수 1~5.
- **출시 블로커 (STAGES Stage 5 / 출시 전 필수)**: ① in-app 계정 삭제 — Edge Function `supabase/functions/delete-account/` **작성 완료, 배포 미완**(`npx --yes supabase functions deploy delete-account`) ② 개인정보처리방침·이용약관 호스팅 페이지 — `me_screen.dart` 링크는 연결됐으나 URL placeholder ③ `cards` 등 V1.5 새 테이블에 `on delete cascade auth.users`(또는 `quotes`) 챙기기. (`quotes`/`user_books`/`profiles`는 이미 cascade — `docs/db-schema.md §4`.)
