# 책귀(BookQuote) — 개발 상세 보고서

**기준일**: 2026-05-17
**범위**: Stage 3까지 완료 + PR14 출시 직전 fix 완료
**출시 일정**: D-약 1개월 (E2EE PR16 포함)
**관련 문서**: [STAGES.md](STAGES.md) · [DECISIONS.md](DECISIONS.md) · [app-scenarios.md](app-scenarios.md) · [db-schema.md](db-schema.md) · [design/screens/README.md](design/screens/README.md)

---

## 1. 앱의 목적

> 한 줄: **"책의 좋은 구절을 모으고, 카드로 만들어 SNS·단톡방에 흘려보내는 1인용 인용구 도구."**

- **솔로 도구**: V1은 친구/팔로워/타임라인 없음. 본인이 모으고, 본인이 공유하고, 본인이 다시 본다.
- **차별화 4종**
  - ① 표지 색에서 자동 추출한 카드 팔레트 (T4 표지발췌·T2 따뜻)
  - ② 단톡방·인스타에 1탭 공유 (`/quote/:id/share` PR10.5)
  - ③ **데이터 주권**: Markdown 내보내기 + (PR16) 선택적 E2EE 잠금 인용구 — "운영자도 못 봄"을 *기술적으로* 진실화
  - ④ 무드별 다시보기 (위로/먹먹/새벽3시/통찰/설렘 5개 무드 × 최대 3개)
- **반(反) 패턴**: 광고 게이트 없음, OCR 미내장(폰 OS 기능 + 클립보드), AI 단어 일절 미사용(Fable AI 사고 반면교사)

---

## 2. 화면별 DB · 화면 설명

### 라우터 트리 (`lib/app/router.dart`)

```
/splash                              cold-start 세션 hydrate 대기
├─ /auth/login                      매직링크 전송
├─ /auth/callback · /callback       deep link 콜백 (10s 타임아웃 + 사유 안내)
├─ /book/:id?from=                  책 상세 (게스트 허용, deep link 수신)
├─ /quote/new[?bookId=][?quoteId=]  인용구 입력/편집 (풀스크린)
├─ /quote/:id/card                  카드 에디터 (풀스크린)
├─ /quote/:id/share                 1탭 바로 공유 (PR10.5)
└─ StatefulShellRoute (BottomNav 4슬롯: 홈 / 서재 / [＋] / 내 정보)
```

### 화면 ↔ DB 매핑

| 화면 | 파일 | 주 테이블 / 함수 | 핵심 동작 |
|---|---|---|---|
| **스플래시** | `lib/app/splash_screen.dart` | (auth 세션만) | hydrate + 보류 deep link 소비 |
| **로그인** | `features/auth/login_screen.dart` · `auth_controller.dart` | `auth.users` (Supabase) | 이메일 매직링크. PR13 F1: "이메일이 다른가요? 다시 입력" 출구. 카카오는 V1.5 |
| **콜백** | `features/auth/auth_callback_screen.dart` | `profiles` (트리거 자동 INSERT) | `getSessionFromUrl` → router redirect |
| **홈 — 내 인용 피드** | `features/home/home_screen.dart` · `quote/state/quote_feed_provider.dart` · `widgets/quote_list_card.dart` | `quotes` SELECT (+`books` 임베드) | cursor-after 무한스크롤, pull-to-refresh, 카드 펼침→[📤 바로 공유 ↗]/[카드 디자인]/[삭제], 포그라운드 복귀 시 outbox flush, 회고 카드 1행(PR15-B) |
| **인용구 입력/편집** | `features/quote/quote_input_screen.dart` · `quote_draft.dart` · `mood_chips.dart` | `quotes` INSERT/UPDATE, `books` 검색 | 본문 + 클립보드 붙여넣기 배너 + 책 검색 시트 + 페이지 + 무드 최대 3 + draft 자동저장 v2 (`{input, savedAt}`) + 오프라인 outbox 큐잉. PR14-B: page≤0 차단, 2000자 truncate |
| **서재 — 책 ↔ 인용구 세그먼트** | `features/library/library_screen.dart` · `quote/presentation/quote_list_view.dart` | `user_books` (책 탭), `quotes` + `my_quote_mood_counts()` RPC (인용구 탭) | SegmentedButton, 무드 필터 칩(전체 N + 무드별 개수), `?tab=quotes&mood=` 쿼리 진입 |
| **책 상세** | `features/book/book_detail_screen.dart` · `widgets/star_rating.dart` | `books`, `user_books` (별점·서재 EXISTS), `quotes` (이 책 N구절) | 표지·메타·별점(1~5, 재탭 지움)·"이 책에서 모은 N구절" 미니리스트·[서재에 담기]/✓칩·⋮[빼기]·설명 점진 공개·`?from=share` 배너 |
| **내 정보** | `features/me/me_screen.dart` · `state/me_providers.dart` · `data/{markdown_exporter, quote_export}.dart` · `account/account_deletion.dart` | `quotes`/`user_books` COUNT, Edge Function `delete-account` | 프로필·내보내기(PR14-E: `XFile .md` 첨부)·약관·문의·로그아웃(outbox 경고)·회원 탈퇴 2단계 |
| **카드 에디터** | `features/card_editor/card_editor_screen.dart` · `state/{card_editor_controller, quote_card_data_provider}.dart` · `domain/card_template.dart` (T1~T5) · `data/{palette_service, card_renderer, share_service, card_repository}.dart` | `quotes`/`books` SELECT, `cards` INSERT (공유 시), `shared_preferences` (draft) | 5템플릿×3비율, 색 추출(LRU 100, WCAG 4.5:1), 폰트 ±3, undo ≥20, 5스와치, auto-fit 경고, 워터마크, 1080 절대 캔버스 RepaintBoundary→PNG export |
| **1탭 바로 공유** | `features/card_editor/quick_share_screen.dart` | 위와 동일 | draft 또는 추천 디자인 자동 적용 → PNG → 공유 시트 자동. dismiss 후 [다시 공유]/[디자인 편집] 출구 |
| **공유 시트** | `card_editor/presentation/widgets/share_sheet.dart` | `share_plus` OS 시트 | 카카오톡/인스타/저장/다른 앱 4버튼 (V1은 모두 동일 OS 시트, 카카오 SDK 메시지카드는 V1.1) |
| **책 검색 시트** | `features/book/presentation/book_search_sheet.dart` · `state/book_search_controller.dart` | `books` `ilike` 캐시 → Edge Function `aladin-search` → `upsert_book(jsonb)` | 400ms debounce, 캐시 사전조회, 결과 선택 시 카탈로그 영속화 |

### DB 스키마 (단일 진실: `supabase/migrations/*.sql`)

```
auth.users
  ├─1:1─▶ profiles            (display_name, avatar_url)             [cascade]
  ├─1:N─▶ user_books          (book_id, added_at, status, rating 1~5)[cascade]
  ├─1:N─▶ quotes              (book_id?, manual_book_text?, text,
  │                            page?, source, moods text[])          [cascade]
  └─1:N─▶ cards               (quote_id, book_id?, design jsonb,
                               shared_at)                            [cascade]

books (글로벌 카탈로그)
  ├─1:N─▶ user_books          [on delete cascade]
  ├─1:N─▶ quotes              [on delete set null]
  └─1:N─▶ cards               [on delete set null]
```

**마이그레이션 8개 모두 원격 적용 완료**:

| 파일 | 내용 |
|---|---|
| `20260510120000_profiles.sql` | `profiles` + `set_updated_at()` + `handle_new_user()` 트리거 |
| `20260510120100_handle_new_user_oauth.sql` | OAuth 호환 (닉네임/아바타 여러 키 coalesce) |
| `20260510120200_books.sql` | `books` + `upsert_book(jsonb)` RPC |
| `20260510120300_user_books.sql` | `user_books` PK(user_id, book_id) |
| `20260512120000_quotes.sql` | `quotes` + 인덱스 3종 (시간/책/무드 GIN) |
| `20260512130000_user_books_rating.sql` | `rating smallint CHECK 1~5` |
| `20260512140000_quote_mood_counts.sql` | `my_quote_mood_counts()` RPC |
| `20260516120000_cards.sql` | PR11, immutable, on delete cascade auth.users (탈퇴 정합) |

권한 모델: **RLS-first**. 모든 사용자 데이터 테이블 `auth.uid() = user_id`로 본인만 select/insert/update/delete. `books`만 모두 SELECT + authenticated INSERT/UPDATE(공유 카탈로그).

---

## 3. 화면 간 연결성

### 핵심 동선

**A. 첫 사용 (Activation)**
`/splash` → 세션 없음 → `/auth/login` → 이메일 입력 → 매직링크 메일 탭 → deep link `://auth/callback?code=` → `/auth/callback`이 세션 교환 → `redirect`가 `?from=` 또는 `/` → 홈 빈상태 [＋ 인용구 추가] → `/quote/new`

**B. 인용구 추가 (매일 핵심)**
홈 BottomNav [＋] → `/quote/new` → 본문 + 클립보드 배너 + 책 검색 시트(모달, state 보존) + 페이지 + 무드 → 저장 → `ref.invalidate(quoteFeedProvider)` → 홈 즉시 반영 / 오프라인이면 outbox 큐잉 → 포그라운드 복귀 시 flush

**C. 다시 보기 → 공유**
홈 카드 탭 펼침 → [📤 바로 공유 ↗] → `/quote/:id/share`가 draft/추천 자동 적용 → endOfFrame 2회 → PNG → 공유 시트 자동 → 카카오톡 등 OS 시트 / 또는 [✏ 카드 디자인] → `/quote/:id/card`에서 템플릿/색/폰트 조정 → [공유] → 동일 시트
부가: `unawaited(card_repository.recordShare(...))` 비차단 INSERT (`cards` 테이블)

**D. 무드별 다시보기**
BottomNav [서재] → SegmentedButton [인용구] → 무드 칩(전체/위로/먹먹/...) → cursor-after 무한스크롤

**E. 책 검색 → 서재 담기**
BottomNav [서재] → [+ 책 추가] FAB → `showBookSearchSheet` → 알라딘 검색 → 선택 → `upsert_book` RPC → `user_books` INSERT → 서재 반영

**F. Deep Link 수신 (받는 쪽)**
카카오톡으로 받은 링크 `://book/:id?from=share` 탭 → `deep_link_handler._handle(uri, cold:)` → 콜드면 `_pendingRoute` 보류 + 스플래시 `consumePendingRoute`로 소비 / 워밍이면 즉시 `router.go('/book/:id?from=share')` → 책 상세 + 공유 배너 + "내 서재에 담기" 1급 CTA → 미로그인이면 `/auth/login?from=`로 payload 보존하며 우회

**G. 데이터 관리 / 탈퇴**
BottomNav [내 정보] → [Markdown 내보내기] → 전체 인용구 cursor 수집 → `.md` XFile 첨부 → OS 공유 / [로그아웃] (outbox 있으면 경고 먼저) / [회원 탈퇴] 2단계 → Edge Function `delete-account` JWT 확인 → service_role `auth.admin.deleteUser` → cascade로 quotes/user_books/profiles/cards 정리

### 라우터 가드 (`_redirect`)

- `/splash` — 무한 루프 방지
- `/auth/*`, `/callback` — 게스트 OK, 로그인되어 있으면 `?from=` 또는 `/`로
- `/book/:id` — 게스트 미리보기 허용 (deep link 수신 필수)
- 그 외 — `/auth/login?from=<현재URL>`

### Provider invalidation 체인 (Riverpod)

- 인용구 저장/삭제/수정 → `quoteFeedProvider` invalidate → 홈·인용목록 동시 반영
- 별점/서재 담기 → `myRatingProvider(bookId)` + `myLibraryProvider` + `isInLibraryProvider(bookId)` invalidate
- outbox 큐잉 → `quoteOutboxProvider` + `pendingOutboxCountProvider` invalidate → `OutboxBanner` 표시

---

## 4. 서버 비용 / 계정 관리

### 서버 인프라

| 서비스 | 용도 | 비용 |
|---|---|---|
| **Supabase** Postgres + Auth + Storage + Edge Functions | DB·로그인·외부 키 은닉·service_role 작업 | **무료 (Free Tier)** — DB 500MB, Auth MAU 50k, Edge Function 500k 호출/월, Egress 5GB |
| **알라딘 OpenAPI** | 책 검색 (Edge Function `aladin-search`가 프록시·JWT 강제·키 은닉) | **무료 / 일일 호출 제한** |
| **GitHub Pages** | 약관·개인정보처리방침 (`https://tgparkk.github.io/bookquote/{terms,privacy}/`) | **무료** (Source = `main /docs`, HTTP 200 확인) |
| **GitHub** | 소스코드 (public repo `tgparkk/bookquote`) | **무료** |
| **이메일 (Resend SMTP)** | 매직링크 발송 | Supabase 내장 → 한도 초과 시 별도 SMTP 연결 |
| **책 표지 CDN** | 알라딘 URL 직접 사용 (`cached_network_image`) | **무료** — Supabase Storage 미러링 안 함 (저작권·비용 회피) |
| **카드 PNG** | 클라이언트 로컬에서만 생성 (`RenderRepaintBoundary` → `path_provider` 임시파일) | **0원** — Storage 업로드 안 함 |
| **PostHog (Stage 5 예정)** | 핵심 funnel 측정 (PII 미전송) | 무료 티어 1M event/월 |

**예상 V1 월 비용: 0원**. Supabase Pro($25)는 MAU 5k 돌파 또는 DB 8GB 돌파 시점에 검토.

### 계정 관리

- **인증**: Supabase Auth 매직링크 단일 (`features/auth/`). 카카오는 V1.5 (Supabase GoTrue `account_email` scope 강제 vs 카카오 개인앱 비즈 인증 충돌 — DECISIONS 2026-05-10)
- **회원가입 트리거**: `auth.users` AFTER INSERT → `handle_new_user()` `security definer` → `profiles` 자동 생성. OAuth 호환 (display_name·avatar_url 여러 키 coalesce)
- **세션 보존**: `supabase_flutter` 내장 (앱 재시작 후 hydrate). cold-start는 `/splash`가 대기
- **회원 탈퇴 (출시 블로커 — 처리 완료 2026-05-16)**:
  - Edge Function `supabase/functions/delete-account/index.ts` 운영 배포 완료, project `ndbvptxwznogcuuumzzh`, version 1 ACTIVE
  - JWT로 호출자 확인 → service_role `auth.admin.deleteUser(user.id)` → cascade로 `quotes`/`user_books`/`profiles`/`cards` 일괄 삭제
  - **Apple Guideline 5.1.1(v) + Google Play 요구 충족**
- **데이터 주권**:
  - Markdown 내보내기 (PR5/PR14-E) — 전체 인용구 `.md` XFile 첨부
  - PR16 (예정) — 선택적 E2EE: 마스터키 K는 `flutter_secure_storage`에만, 서버는 `K_wrapped` envelope만 보관. 다기기는 잠금 비밀번호 PBKDF2-HMAC-SHA512 600k로 wrap
- **PII 정책**: 인용구 텍스트·검색어·붙여넣기 내용은 Sentry/PostHog 미전송 (length·screen·code만)

### 빌드/배포 운영 메모

- `flutter run`·`flutter build apk[--release]` 모두 **항상** `--dart-define-from-file=.env.json` 동반 — 빠뜨리면 Supabase 미초기화로 로그인 silent fail (토스트도 안 뜸)
- 폰 install은 `flutter install` 대신 `adb install -r` (데이터 보존, 같은 머신 한정)
- DB 운영 가이드 `docs/ops/` — 백업 3-2-1, 사고 대응, 정기 점검

### release-only 함정 (반드시 매 PR마다 release APK 검증)

1. **`AndroidManifest.xml` `INTERNET` 권한** — debug/profile에만 있어서 release APK에서만 SocketException
2. **`debugNeedsPaint`** — SDK 내부 assert로만 초기화되는 late bool → release에서 `LateInitializationError`

둘 다 debug install·`flutter test` 모두 통과해도 release APK에서만 깨짐. 매 PR 끝 release 빌드로 한 번 더 검증.

---

## 5. 남은 작업 (출시까지 약 1개월)

### A. Stage 4 — 인용구 E2EE (출시 한 달 미루며 V1.0에 포함, DECISIONS 2026-05-17)

| PR | 내용 | 상태 |
|---|---|---|
| **PR16-A** | 마이그레이션 2장 (`text_encrypted bytea` + `crypto_version` + `is_private` + `user_crypto_envelopes`) + `lib/core/crypto/{key_service, encryptor, envelope_service}.dart` (AES-256-GCM + PBKDF2-HMAC-SHA512 600k) | ⏳ |
| **PR16-B** | `Quote.isPrivate` 도메인 + `QuoteRepository` 자동 암복호화 + outbox 큐잉 직전 암호화 + `cards.design` 검증 | ⏳ |
| **PR16-C** | 입력 토글 + 첫 잠금 모달 (영구 손실 경고) + 공유 직전 확인 모달 ("이미지엔 평문") + 🔒 배지 | ⏳ |
| **PR16-D** | 잠금 비밀번호 화면 (설정/변경/QR 백업/가져오기) + `qr_flutter`·`mobile_scanner` | ⏳ |
| **PR16-E** | 골든 2장 + `delete-account` 흐름에 `KeyService.deleteAll()` + AndroidManifest `allowBackup="false"` (필수) + release APK 실기기 회귀 | ⏳ |

### B. Stage 5 — 출시 등록

- [ ] **앱스토어·플레이스토어 등록 / 심사** — Mac 없어 iOS는 추후
- [ ] **PostHog 연동** — 핵심 funnel (가입/첫 인용구/첫 공유) 측정, PII 미전송
- [ ] **인스타 매일 1개 카드** — W-4부터 본인 인용구 카드 마케팅
- [ ] **디스콰이엇·긱뉴스 한국 IT 커뮤니티 게시**

### C. B9 검증 대기 (P0/P1 갈림)

- [ ] **저사양 카드 에디터 OOM** — Android 8 / API 27 + 1.5GB RAM AVD 또는 친구 저사양 폰에서 카드 에디터 5회 전환 + 캡처 + 공유 시나리오 재현 시도. 재현되면 P0 → `_MiniCard` 절대 1080 위젯을 56×96dp 경량으로 교체

### D. V1.0.1 hotfix 백로그 (출시 직후)

**designer + planner walkthrough (2026-05-17) 발견 — 차별화 강화**

- [ ] `book_search_sheet` "최근 책 5권" 섹션 (F7·S3 5번 반복 검색 마찰)
- [ ] `share_service` PNG 캐시 윈도우 (S4 4단톡 매 사이클 1080×1920 재생성)
- [ ] 홈 AppBar 검색 (S5 47개 컬렉션 "그 구절 어디" 불가)
- [ ] W1~W9 잔여 6건 (BookSearchSheet 키보드/포커스, PasteBanner 엄지 도달, 카드 에디터 진입 컨텍스트 단절, 본문 수정 X-닫기 미저장 경고 등)
- [ ] planner 권고: SnackBar `[이 책에 한 줄 더]`, share_sheet "다른 방에도?" 카피, Markdown 내보낸 후 정보성 BottomSheet

### E. V1.5로 명시적 연기

친구 follow/타임라인, "받은 카드 함", 다크 모드 토글, 인용구 [수정] UI(편집 모드는 PR2~14에서 가능하나 수정 진입점은 아직), 인라인 [무드 변경], 인용 목록 정렬·검색, 무드 칩 탭→서재 navigation, 서재 책 카드 "N구절" 배지, 삭제 undo SnackBar, 반쪽 별점, 카카오 SDK 메시지카드, AI 기능, OCR 내장

---

## 결론 — 출시 D-약 1개월

- **코드 골격은 V1 출시 가능 상태** (`flutter analyze` clean, 146/146 테스트 통과, 마이그레이션 8개 원격 적용, Edge Function 2개 운영 배포, 약관 페이지 라이브)
- **출시 블로커 처리 완료**: in-app 계정 삭제 + 약관/개인정보처리방침 (2026-05-16)
- **남은 본 작업**: Stage 4 E2EE (PR16-A~E, 약 3~4주) + Stage 5 스토어 등록·마케팅 (1~2주)
- **운영 비용**: 출시 시점 월 0원 (Supabase Free + 알라딘 무료 + GitHub Pages)
- **리스크**: B9 저사양 OOM 검증 미완료, Resend SMTP 한도 (매직링크 발송), 카카오 OAuth는 V1.5로 연기
