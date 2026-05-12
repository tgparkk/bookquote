# Stage 진행 체크리스트

마스터 플랜(`docs/PLAN.md`)에서 추출한 단계별 작업과 현재 상태.
완료한 것은 `[x]`, 진행 중은 `[~]`, 폐기는 `[-]`로 표시한다.

총 14–21주 (3.5–5개월) 목표. 사용자의 모토는 **"서두르지 않고 고득하게"**.

---

## Stage 0a — Validation (2–3주, 진행 중)

코드 한 줄 쓰기 전에 시장 검증. 신호 미달 시 컨셉 피벗 또는 폐기 가능해야 함.

- [x] 가상 페르소나 5명 인터뷰 (Claude 자율, `docs/discovery/virtual-interviews-2026-05-09.md`)
- [x] 경쟁사 평가 프레임워크 (`docs/discovery/competitor-evaluation.md`)
- [x] 실제 인터뷰 가이드 v2 (`docs/discovery/real-interview-guide.md`)
- [x] 사전등록 랜딩 페이지 작성 (`docs/discovery/landing-page/index.html`)
- [ ] 랜딩 페이지 폼 백엔드 연결 + 배포
- [ ] 실제 사용자 인터뷰 5명 (지인 대상)
- [ ] 경쟁 제품 직접 사용 (Goodreads / Readwise / 북적북적 / Letterboxd, 각 1주씩)
- [ ] 인스타 #책스타그램 카드 30개 분석
- [ ] (선택) Wizard of Oz — 본인이 손으로 카드 만들어 친구 단톡방 공유

**Gate**: 5명 중 3명 이상이 비슷한 행동을 이미 하고 있고, 2명 이상이 베타 자발적 요청

## Stage 0b — UX & Design (1–2주, 부분 완료)

- [x] 디자인 시스템 Ink-Paper-Copper (`docs/design/design-system.md`)
- [x] 디자인 토큰 명세 + 코드 (`docs/design/tokens.md`, `docs/design/tokens.ts`, `lib/core/theme/tokens.dart`)
- [x] 색 추출 알고리즘 명세 (`docs/design/color-extraction.md`)
- [x] 카드 템플릿 5종 정밀 디자인 (`docs/design/templates/01~05-*.md`)
- [x] 비교 mockup HTML (`docs/design/mockups/all-templates.html`)
- [ ] T2 따뜻 1:1 외 비주얼 디테일 검수 (브라우저 mockup 본 후 추가 피드백)
- [ ] 화면 흐름도 7–10장 (로그인·홈·서재·책 상세·인용구 입력·카드 편집기·미리보기·친구 검색)
- [ ] 와이어프레임 (Figma 또는 종이)

**Gate**: 카드 5개를 인스타에 올렸을 때 본인이 부끄럽지 않은 수준

## Stage 1 — 기반 (3–4주, **완료** — 세션 로그: [`sessions/2026-05-10-stage1.md`](sessions/2026-05-10-stage1.md))

- [x] Flutter 프로젝트 초기화 (`C:\GIT\bookquote`, Bundle ID `io.github.tgparkk.bookquote`)
- [x] 의존성 설치 (Riverpod / Supabase / freezed / build_runner / palette_generator / go_router)
- [x] 디자인 토큰 이식 (`lib/core/theme/tokens.dart`)
- [x] `ProviderScope` + placeholder 화면, Chrome 빌드 sanity check
- [x] git init + 첫 커밋 (https://github.com/tgparkk/bookquote, public)
- [x] `AppTheme` (ThemeData·TextTheme) 본격 구성 (`lib/core/theme/app_theme.dart`, `app_text_styles.dart`)
- [x] 폰트 번들링 — Pretendard 정적(R/M/SB) + NotoSerifKR 가변 단일 파일 (`assets/fonts/`, pubspec.yaml fonts 섹션)
- [x] go_router 셋업 (`lib/app/router.dart`) — `StatefulShellRoute` 4탭 + auth gate(`refreshListenable`) + `/splash` cold-start, placeholder 화면 7개. 위젯 테스트는 cold boot → /auth/login 자동 이동 검증
- [x] `cached_network_image` 도입 — `lib/features/book/presentation/widgets/book_cover.dart` 일원화 wrapper
- [x] 알라딘 API Supabase Edge Function 프록시 — `supabase/functions/aladin-search/`, JWT 강제, 통일 에러 envelope
- [x] 알라딘 OpenAPI 키 발급 — `.env.json` (gitignored)에 저장, `lib/core/config/env.dart`로 로드. 빌드 시 `--dart-define-from-file=.env.json` 필요
- [x] Supabase 프로젝트 생성 (Northeast Asia / Seoul, 프로젝트 ID `ndbvptxwznogcuuumzzh`). 초기 스키마는 별도 작업
- [x] `supabase_flutter` 초기화 (`lib/core/supabase/supabase_init.dart`, `main()`에서 호출, 키 누락 시 graceful skip)
- [x] Auth — 이메일 매직링크 (`lib/features/auth/`, `supabase/migrations/*profiles*` + `*handle_new_user_oauth*`). 카카오는 V1.5로 미룸 — Supabase GoTrue가 `account_email` scope를 강제 요청하는데 카카오 개인 앱은 비즈 인증 없이 받을 수 없음 (DECISIONS 2026-05-10 항목)
- [x] 책 검색 화면 (알라딘 API) — `BookSearchSheet`(BottomSheet), 캐시 사전조회 + Edge Function, 400ms debounce, 자동 ISBN 분기 토대
- [x] 책 상세 화면 — `bookByIdProvider`로 실제 데이터 fetch, BookCover 위젯
- [x] 내 서재 추가/조회 — `user_books` 테이블 + RLS, `LibraryScreen`이 책 카드 리스트 + pull-to-refresh + FAB → 검색 시트 → addToLibrary + SnackBar 피드백 + invalidate
- [x] 모바일 native 셋업 — Android `AndroidManifest.xml` deep-link intent filter (`io.github.tgparkk.bookquote://auth/callback`) + iOS `Info.plist` URL Types + `app_links` + `lib/app/deep_link_handler.dart`. 첫 debug APK 빌드 검증
- [x] Supabase CLI 배포 파이프라인 — `supabase init` + `link` + `db push` + `secrets set ALADIN_TTB_KEY` + `functions deploy aladin-search` 모두 통과. 마이그레이션은 `YYYYMMDDHHMMSS` 14자리 timestamp로 표준 명명

## 화면 세부 설계 (Stage 0b 연장 — 2026-05-12 완료)

- [x] 경쟁앱 화면 해부 (`docs/discovery/competitor-screen-analysis-2026-05-11.md` + `competitor-references.html`)
- [x] 화면별 설계 문서 13개 (`docs/design/screens/*.md` — 그룹 1: 인용입력·인용목록·카드에디터·카드공유·deep link받기 / 그룹 2: 홈·Me·책상세 / 그룹 3 역정리: 스플래시·로그인·콜백·서재·책검색시트). 7섹션 구조(목적·와이어프레임·상태·인터랙션·토큰·재사용·엣지/접근성)
- [x] `docs/design/mockups/screens.html` — 전 13화면 와이어프레임 (그룹 1·2·3)
- [x] (구현 전 정합) `flows.md`·`client-architecture.md` 상단에 V1.5 범위 정정 배너 — follow `timelineProvider`/`follows`/`useTimelineRealtime`/`publish to followers`는 V1.5(코드엔 0), V1 홈 = `myQuotesProvider` 기반·Realtime 없음, Flow C는 V1.5(deep link 받는 쪽 1탭 담기만 V1), OCR은 폰 기능+클립보드
- (참고) 무드 태그 셋 작업 가정값: 위로 / 먹먹 / 새벽3시 / 통찰 / 설렘 — `quotes.moods text[]` + 앱 `enum QuoteMood`. 구현 전 최종 확정 가능

## Stage 2 — 인용구 입력 (2–3주) — 설계 완료, 구현 대기

구현 순서: `quotes` 테이블 마이그레이션(`book_id` nullable `on delete set null`, `manual_book_text`, `text` CHECK 1~2000, `source` manual/clipboard, `moods text[]`, RLS = user_books 패턴, `set_updated_at()` 재사용) → `quote.dart`(@freezed)/`quote_repository`(`listMyQuotes` cursor 시그니처 — DECISIONS 2026-05-12)/`quote_providers`/`createQuoteController`(낙관적)/`quote_outbox`(`shared_preferences`) → `quote_input_screen` 재작성 → `home_screen` 재작성("내 인용 피드") → `quote_list_view`(서재 탭 세그먼트). pubspec: `shared_preferences`·`connectivity_plus` 추가.

- [ ] 직접 입력 폼 → 저장 → 책 매핑 (`showBookSearchSheet` 재사용, `suppressAddedToast` 옵션 추가) — 설계: `screens/quote-input.md`
- [ ] 클립보드 붙여넣기 자동 감지 배너 (앱 내장 OCR 안 함 — OS 기능으로 복사 → 붙여넣기. DECISIONS 2026-05-11)
- [ ] 무드 태그 (`quotes.moods text[]` + 앱 `enum QuoteMood` 화이트리스트 + `tokens.dart`의 `moodColors` 맵, 차별화 ④)
- [ ] 인용구 목록 — 서재 탭 내 "책 ↔ 인용구" 세그먼트 (`/library?tab=quotes`, 무드/책/최근순 필터 + 검색) — 설계: `screens/quote-list.md`
- [ ] 홈 화면 재작성 — "내 인용 피드"(시간순, cursor-after 페이지네이션, FAB 없음, Realtime 없음) — 설계: `screens/home.md`
- [ ] 경량 오프라인 아웃박스 (`quote_outbox` — best-effort flush, 동기화 대기 뱃지). 일정 빠듯하면 2.1로(V1은 draft 1건 복구만). 완전 동기화 엔진(Flow F)은 V1.5. DECISIONS 2026-05-11
- [ ] Me 화면 보강 — 프로필 + 내 데이터(인용/서재 count, Markdown 내보내기) + 약관·개인정보·버전·문의 + 회원 탈퇴 2단계. 친구 찾기 = 숨김. 다크모드 토글 = V1.5. pubspec: `url_launcher`·`package_info_plus`. 설계: `screens/me.md`
- [ ] 책 상세 보강 — "내가 이 책에서 모은 N구절" 섹션 + "인용구 추가" CTA + `?from=share` deep link 분기 + 설명 점진적 공개 + raw `$e` 노출 제거. 설계: `screens/book-detail.md`

## Stage 3 — 카드 (3–4주, 가장 공들일 단계) — 설계 완료, 구현 대기

설계: `screens/card-editor.md` + `screens/card-share.md`. 텍스트 위치 앵커(상/중/하)는 V1.5(V1은 폰트 크기 ±·정렬만). 표지 없는 책에서 T4 = 비활성화. DECISIONS 2026-05-12.

- [ ] 5개 카드 템플릿 위젯 구현 (`sealed class CardTemplate` ×5, 위젯 트리 — CustomPaint 아님)
- [ ] 색 추출 (`palette_generator` → `ExtractedPalette`, `palette_service` 메모리 LRU 캐시, `ensureContrast` WCAG AA 4.5:1, 채도<10 폴백. `Color` 채널은 `toARGB32()` 기준)
- [ ] 카드 편집기 (3단 고정 레이아웃, 팔레트 비동기·카드 동기, 언두 최소 20단계 — 비율·템플릿 전환 포함)
- [ ] 이미지 export (`card_renderer` — `RepaintBoundary.toImage`, `AppCardSize` 1080 기준, 폰트 로드 완료를 캡처 전 보장, 워터마크 캡처 트리 안 Positioned. pubspec: `share_plus`·`path_provider`·`gal`)
- [ ] `cards` 테이블 (`design jsonb`, `on delete cascade auth.users` — 탈퇴 정합)
- [ ] SNS 공유 시트 (카카오톡 1순위, V1=`share_plus` OS 시트, 권한 거부해도 공유는 됨. 카카오 SDK 메시지 카드 공유는 V1.1)
- [ ] deep link 받기 — `deep_link_handler` 일반화(`/book/:id` 라우팅 + payload 보존 + 1회 consume) + 책 상세 "내 서재 담기" 1탭. 설계: `screens/deep-link-receive.md`

## Stage 4 — 소셜 레이어 (2–3주)

- [ ] ~~친구 검색 + follow~~ → V1.5 (V1 출시엔 안 함 — 솔로 도구 + 단톡 1탭 공유. DECISIONS 2026-05-12. Me의 "친구 찾기"는 V1엔 숨김)
- [ ] ~~친구 인용구 타임라인~~ → V1.5 (홈 피드에 합쳐 진화. `received_cards` 테이블도 V1.5)
- [ ] 단톡방 챌린지 메커닉 / spoiler 게이팅 → V1.5
- [ ] 본인 폰 한 달 dogfooding
- [ ] 친구 1–3명 베타

## Stage 5 — 출시 (1–2주)

- [ ] **(출시 블로커) in-app 계정 삭제** — Edge Function `delete-account`(JWT 검증 → `auth.admin.deleteUser`). Apple Guideline 5.1.1(v) + Google Play 둘 다 요구. cascade로 `quotes`/`user_books`/`cards`/`profiles` 자동 삭제
- [ ] **(출시 블로커) 개인정보처리방침·이용약관 페이지** — 호스팅(GitHub Pages/Notion 등) + Me 화면 `url_launcher` 링크 + 스토어 등록 폼
- [ ] 앱스토어·플레이스토어 등록
- [ ] PostHog 연동, 핵심 funnel 측정 setup (PII 미전송 — 인용구 텍스트·검색어 raw 안 보냄)
- [ ] 인스타 본인 인용구 카드 매일 1개 (W-4부터)
- [ ] 디스콰이엇·긱뉴스 한국 IT 커뮤니티 게시
