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

## Stage 2 — 인용구 입력 (2–3주)

- [ ] 직접 입력 폼 → 저장 → 책 매핑
- [ ] 사진 촬영 → ML Kit OCR → 결과 편집 UI
- [ ] 인용구 목록·검색 (책별 / 태그별)

## Stage 3 — 카드 (3–4주, 가장 공들일 단계)

- [ ] 5개 카드 템플릿 위젯 구현 (T1~T5)
- [ ] 색 추출 (`palette_generator` → `ExtractedPalette`)
- [ ] 카드 편집기 (폰트·색·여백 미세 조정)
- [ ] 이미지 export (1080×1080 / 1080×1350 / 1080×1920)
- [ ] SNS 공유 (인스타 스토리·카톡·다운로드)

## Stage 4 — 소셜 레이어 (2–3주)

- [ ] 친구 검색 + follow
- [ ] 친구 인용구 타임라인
- [ ] 본인 폰 한 달 dogfooding
- [ ] 친구 1–3명 베타

## Stage 5 — 출시 (1–2주)

- [ ] 앱스토어·플레이스토어 등록
- [ ] PostHog 연동, 핵심 funnel 측정 setup
- [ ] 인스타 본인 인용구 카드 매일 1개 (W-4부터)
- [ ] 디스콰이엇·긱뉴스 한국 IT 커뮤니티 게시
