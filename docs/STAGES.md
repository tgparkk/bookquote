# Stage 진행 체크리스트

마스터 플랜(`docs/PLAN.md`)에서 추출한 단계별 작업과 현재 상태.
완료한 것은 `[x]`, 진행 중은 `[~]`, 폐기는 `[-]`로 표시한다.

총 14–21주 (3.5–5개월) 목표. 사용자의 모토는 **"서두르지 않고 고득하게"**.

---

## ▶ 다음 세션 시작점 (2026-05-13 기준)

**상태**: Stage 0~1 완료 + 화면 설계(Stage 0b 연장) 완료 + Stage 2 본 작업 종료(PR1~6 + 책 별점) + **Stage 3 진행 중 — PR7(5종 템플릿) + PR8(팔레트 서비스 + WCAG 대비 유틸 + Riverpod 통합) 완료. 다음은 PR9(에디터 MVP)**. `flutter analyze` clean, `flutter test` 83개 통과. 마이그레이션 4개(`quotes`, `user_books.rating`, `my_quote_mood_counts`, +Stage1 4개) 원격 적용 완료. main에 push됨. 릴리스 APK 빌드해 실기기(SM F956N) 설치 진행.

**지금 동작하는 플로우**: 로그인 → 홈(내 인용 피드: 무한스크롤·당겨새로고침·빈상태 CTA·카드 탭 펼침→[카드만들기]/[삭제]) → ＋ → 인용구 입력(본문/클립보드 붙여넣기/책 연결/페이지/무드/draft/오프라인 큐잉) → 저장 → 홈 반영 / 서재 [책↔인용구] 세그먼트 — "인용구" 탭 무드별 다시보기 / **책 상세**(별점·"이 책에서 모은 N구절" 미니리스트·"이 책 인용구 추가" CTA·`isInLibrary`면 ✓칩 아니면 [서재에 담기]·⋮[서재에서 빼기]·설명 점진적 공개·`?from=share` deep link면 공유 배너 + "내 서재에 담기" 1급 CTA) / **내 정보**(프로필·인용/서재 count·Markdown 내보내기·약관/개인정보/문의 링크·로그아웃[아웃박스 경고]·회원 탈퇴 2단계) / 책 검색·로그인은 Stage 1. ("카드 만들기 →"는 카드 에디터 스텁으로 감 — Stage 3.) **deep link**: `://book/:id?from=share` → 핸들러가 GoRouter로 라우팅(콜드스타트는 스플래시가 보류 경로 소비, 워밍은 즉시 `router.go`, URI 1회 consume). 미로그인 "담기" 탭 → `/auth/login?from=` 경유 복귀(payload 보존).

**바로 이어서 할 것** → **Stage 3 PR9 (에디터 MVP — controller + 실데이터 + 인터랙션)**. `NotifierProvider`로 `CardEditorController`(상태: `templateId`/`paletteOverride`/`textAnchor`/`fontStep`/`ratio`/`watermarkOn`/`undoStack`) + `shared_preferences` 영속화 + 재진입 시 "이어서 만들기" 다이얼로그. `quoteByIdProvider(quoteId)` + `bookByIdProvider`(필요시 신규) 합성으로 `QuoteCardData` 생성(mock 제거). 인터랙션: 비율 세그먼트(언두 1단위), 템플릿 줄 탭, 표지 5스와치(`palette` 슬롯 자동/사용자 override), "다른 느낌 ↻"(순환 + 슬롯 재배정), 인용구 길이별 auto-fit 경고. T5는 `charCount>50`이면 비활성. 뒤로/✕ = 확인 다이얼로그 없이 닫기(편집 상태는 영속화). PR9 후 → PR10(렌더+공유, `RepaintBoundary.toImage` + 폰트 로드 보장 + `share_plus`/`path_provider`) → PR11(`cards` 테이블 + `design jsonb` + 공유 성공 시 비차단 INSERT) → PR12(마감 — 언두 ≥20·텍스트 ±·워터마크 토글·접근성·골든). **PR7 산출**: `lib/features/card_editor/{domain,data,presentation/widgets}/*` — `sealed CardTemplate` ×5 + `supports/recommended/byId/all` + `QuoteCardData` + 5종 위젯(1080 절대 캔버스 — "미리보기=export") + `QuoteCard` switch 디스패처 + `CardWatermark` + `color_utils.{lightenToBackground,toMidTone}` + `splitIntoPoetryLines`(chunk별 강제 줄바꿈 보존)/`getTypographyFontSize`. **PR8 산출**: `data/color_utils.dart`에 WCAG 2.1 4종(`relativeLuminance`/`contrastRatio`/`ensureContrast(minRatio 기본 4.5)`/`getTextColorForBackground` — 임계값 0.18) 추가. `data/palette_service.dart` — `LinkedHashMap` LRU(maxCacheSize 100) + `extractPalette` 타임아웃 3s + `getPaletteWithFallback(coverUrl?, templateId)` + `PaletteGeneratorFactory` 주입(테스트). `state/palette_providers.dart` — `paletteServiceProvider`(앱 1 인스턴스) + `extractedPaletteProvider` FutureProvider.autoDispose.family(키 = `({coverUrl, templateId})` Dart record). `card_editor_screen`: `_PreviewBox`·`_MiniCard` → `ConsumerWidget`로 전환, `.value ?? fallbackFor`로 즉시 렌더 후 추출 도착 시 `AnimatedSwitcher` 200ms cross-fade. `share_plus`는 이미 pubspec, `path_provider`/`gal`은 PR10에서 추가. **테스트**: PR7 19개 + PR8 24개(WCAG 흑/백 21:1·대칭·`ensureContrast` 교체 보증·HSL 보조·LRU eviction·LRU touch·factory throw/timeout 폴백·null/empty URL·모르는 templateId).

**⚠️ PR5 남긴 출시 블로커 (Stage 5 전 처리 필수)**:
- `supabase/functions/delete-account/` — **함수 코드 작성 완료, 아직 배포 안 함**. `npx --yes supabase functions deploy delete-account` 필요(`SUPABASE_SERVICE_ROLE_KEY` 등은 Edge Function에 자동 주입 — 별도 시크릿 설정 불필요). 미배포 상태에선 회원 탈퇴 시 invoke 404 → "탈퇴 처리에 실패했어요" 토스트.
- 이용약관·개인정보처리방침 — `me_screen.dart`의 `_termsUrl`/`_privacyUrl`이 **placeholder URL**(`https://tgparkk.github.io/bookquote/{terms,privacy}`). 실제 정적 페이지 호스팅 + 상수 교체 + 스토어 등록 폼 필요.

**문서 지도** (2026-05-14 정리): `docs/app-scenarios.md`(현재 V1 동선 — `discovery/flows.md` 초안 대체) · `docs/db-schema.md`(현재 DB 설계서 — `discovery/api-design.md`·`architecture.md` 초안 대체) · `docs/design/screens/README.md`(화면 13개 인덱스 + 구현 상태 + 실제 파일 경로) · `docs/design/screens/*.md`(화면별 7섹션 명세). `discovery/`의 architecture·api-design·flows는 시점 고정 초안(상단 배너).

**작업 방식 메모**: 각 PR = main에 직접 commit+push(Stage 1 패턴), 매 PR마다 `flutter analyze` + `flutter test` 통과 + 위젯/유닛 테스트 추가, 마이그레이션은 작성 후 `npx supabase db push`(supabase 명령은 PATH에 없음 — `npx --yes supabase ...` 사용, `printf 'y\n' |`로 프롬프트 통과). 매니저 모드(가상 팀)는 설계 단계용 — 구현 PR은 설계 문서(`docs/design/screens/*.md`)가 충분히 상세해 직접 구현.

### 후속 작업 백로그 (Stage 2 마무리 전후 — 우선순위 낮음)
- 아웃박스 `connectivity_plus` 연결-회복 트리거(현재 포그라운드 복귀 시만) + 홈/인용목록에 "동기화 대기 N개" 배너
- 인용구 [수정] (= `/quote/new?quoteId=` 편집 모드) · 카드/목록의 인라인 [무드 변경]
- 인용 목록 정렬(책별 그룹 / 페이지순) · 인용구 텍스트 검색(서버 `ilike`) · 홈/책상세 무드 칩 탭 → `/library?tab=quotes&mood=` navigation
- 서재 책 카드: "이 책에서 모은 N구절" 배지 + 표지 dominant color 띠
- 삭제 시 undo SnackBar(현재는 확인 다이얼로그)
- Me: Markdown 내보내기를 텍스트 공유 대신 `.md` 파일 첨부(`XFile`) — 컬렉션 큰 경우 안드로이드 인텐트 한도 회피 / 다크모드 토글(`[시스템/라이트/다크]` + `darkTheme` 정의) = V1.5 / 섹션 사이 `Divider` 시각 구분 / 카운트 trailing 변경 후 `invalidate(myQuoteCountProvider)` 동선(인용구 추가/삭제 시)
- 그룹 3 역정리 문서의 나머지 개선: 로그인 매직링크 재전송 출구 + `?from=` 보존, 콜백 타임아웃 사유 안내, 책 검색 시트 검색-전 빈결과·ISBN 직접 등록·오프라인 캐시-우선, 스플래시 워드마크·안전망 시간 실측
- **릴리스 빌드 로그인 확인 + Resend SMTP 점검** — 2026-05-13 릴리스 APK에서 매직링크 발송이 "문제가 발생했어요"로 실패(디버그 빌드에선 정상). Supabase 기본 이메일 한도(≈4건/시간)에 걸렸을 가능성. Supabase Dashboard > Authentication > Emails(SMTP)에 Resend가 실제로 연결돼 있는지 확인(Stage 1에서 연결했다고 적혀 있으나 Auth 쪽 물림 여부 미확인). + `authErrorMessage`가 릴리스에서도 최소한의 단서(에러 타입/짧은 코드)를 남기게 개선 검토
- (개발 편의 메모) **폰 테스트는 한 가지 빌드 타입으로 통일** — 디버그↔릴리스는 서명 키가 달라 `flutter install` 시 완전 삭제 후 재설치 → 세션(`flutter_secure_storage`) 날아가 매직링크 재로그인 필요. 같은 빌드 타입이면 `adb install -r`로 데이터 유지 → 세션 유지. (스토어 배포 빌드는 항상 같은 키라 실 사용자엔 무관)

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

## Stage 2 — 인용구 입력 (2–3주) — 진행 중

구현 순서: `quotes` 테이블 마이그레이션 → `quote.dart`(@freezed)/`quote_repository`(`listMyQuotes` cursor 시그니처)/`quote_providers`/`createQuoteController`/`quote_outbox` → `quote_input_screen` 재작성 → `home_screen` 재작성("내 인용 피드") → `quote_list_view`(서재 탭 세그먼트) → `me_screen` 보강 → `book_detail_screen` 보강.

- [x] **PR1** 인용구 데이터 레이어 — `supabase/migrations/20260512120000_quotes.sql`(book_id nullable on delete set null, manual_book_text, text CHECK 1~2000, page CHECK >0, source manual/clipboard, moods text[], RLS 4정책, 인덱스 3개) **remote 적용 완료**. `features/quote/{domain,data,state}` — Quote/QuoteInput/QuoteSource/QuoteMood + QuoteMoodListConverter, QuoteRepository(create/update/delete/getById/listMyQuotes cursor-after + moods overlaps), QuoteOutbox(SharedPreferences, 사용자별 키), bookQuotesProvider/quoteByIdProvider/createQuoteControllerProvider. pubspec: shared_preferences·connectivity_plus. quote_model_test 7개
- [x] **PR2** 인용구 입력 화면 (`/quote/new[?bookId=]`) — 본문 멀티라인 + 글자수 카운터 + 클립보드 붙여넣기 감지 배너(Clipboard.hasStrings) + 책 연결(showBookSearchSheet 재사용 — `_onPick`의 잘못된 "서재 추가" 토스트 제거) + 페이지·무드 칩(최대 3개) + draft 자동저장/복원 + PopScope 폐기 확인 + "카드 만들기 →"(pushReplacement → /quote/:id/card) / "저장만 하기" + 오프라인 아웃박스 큐잉. `presentation/widgets/mood_chips.dart`(moodColors 단일 정의처), `data/quote_draft.dart`. quote_input_screen_test 3개
- [x] **PR3** 홈 화면 재작성 — "내 인용 피드": `quote_feed_provider`(`Notifier<AsyncValue<List<QuoteWithBook>>>` — cursor-after 무한스크롤 누적 + `removeLocal` 낙관적 삭제, NotifierProvider 비-autoDispose), `quote_repository.listMyQuotesWithBook`(`*, book:books(*)` 임베드 — N+1 회피, `QuoteWithBook` 레코드), `quote_list_card.dart`(홈·인용목록 공유 위젯 — 접힘/펼침, 무드 뱃지, [카드 만들기]/[삭제]), `home_screen.dart`(`ConsumerStatefulWidget` + 스크롤 무한로드 + RefreshIndicator + 빈 상태 CTA + 에러 재시도 + 카드 탭 펼침 + 삭제 확인 다이얼로그 + 포그라운드 복귀 시 아웃박스 best-effort flush), `quote_input_screen`은 저장 성공 시 `ref.invalidate(quoteFeedProvider)`. FAB 없음, Realtime 없음. home_screen_test 3개. — 설계: `screens/home.md`. (인용 목록 위젯 공유 / 무드 칩 navigation·"동기화 대기" 배너·undo는 PR4 또는 후속)
- [x] **PR4** 서재 "책 ↔ 인용구" 세그먼트 — `library_screen`(stub→`ConsumerStatefulWidget`): `SegmentedButton` [책]/[인용구], `?tab=quotes&mood=<name>` 쿼리로 초기 탭·무드 설정(`GoRouterState.of` in `didChangeDependencies`), `_ErrorView` raw `$error` 제거 + [다시 시도], 추가 실패 메시지 userMessage화. `quote_list_view.dart`(`ConsumerStatefulWidget`, Scaffold 없음): 무드 필터 칩(전체 N + 무드별 개수) + cursor-after 무한스크롤 카드 목록(`quote_list_card` 재사용) + pull-to-refresh + 빈 상태(전체="아직 인용구 없어요"+＋ / 무드="이 무드 없어요"+전체보기) + 삭제 확인 다이얼로그(→ `quoteFeedProvider` invalidate + 카운트 갱신). `my_quote_mood_counts()` RPC(마이그레이션 `20260512140000`, **remote 적용**) + `quote_repository.getMoodCounts/parseMoodCounts`. parseMoodCounts 테스트 2개. 무드별 컬렉션 = 차별화 ④. — 설계: `screens/quote-list.md`. (인라인 [수정]/[무드 변경]·정렬(책별/페이지순)·검색·홈→서재 무드 칩 navigation·구절수 배지·표지색 띠는 후속)
- [x] **PR5** Me 화면 보강 — `me_screen.dart` 재작성(섹션형 `ListView`): 프로필(이니셜 아바타+이메일+"로그인됨"/"로그인 정보 없음", 오버플로 처리) + 내 데이터(`quote_repository.countMyQuotes()`·`book_repository.countMyLibrary()` count 쿼리 → `me_providers`의 `myQuoteCountProvider`/`myBookCountProvider`, `/library?tab=quotes`·`/library` navigation, **Markdown 내보내기**=`markdown_exporter.dart`(순수, 책별 그룹+쪽수·무드 메타)+`quote_export.dart`(전체 페이지네이션 수집→`share_plus` 텍스트 공유)) + 설정(다크모드 "시스템 설정" 읽기전용 / 알림 "곧 추가될 기능" 비활성) + 정보(앱 버전 `package_info_plus` → `appVersionProvider`, 문의 `mailto:`, 이용약관·개인정보처리방침 외부 링크 `url_launcher`) + 계정(로그아웃 — `quote_outbox.pending()` 있으면 경고 다이얼로그 먼저; 회원 탈퇴 2단계=`account_deletion.dart`(영구삭제 경고+내보내기 권유 → "탈퇴합니다" 타이핑 → dim → `delete-account` invoke → `signOut`)). 친구 찾기 = 숨김(빈 `onTap` 제거). 다크모드 토글 = V1.5. `meSessionInfoProvider`(세션 요약 — 테스트 override용). pubspec: `url_launcher`·`package_info_plus`·`share_plus` 추가. AndroidManifest `<queries>`에 https·mailto intent 추가. Edge Function `supabase/functions/delete-account/index.ts` 작성(JWT로 호출자 확인 → service_role `auth.admin.deleteUser` → cascade) — **배포는 미완(Stage 5)**. markdown_exporter 5개 + me_screen 3개 테스트. — 설계: `screens/me.md`
- [x] **PR6** 책 상세 보강 — `book_detail_screen.dart` 재작성: `_BookBody`(헤더 표지·메타·ISBN guard·로그인 시 별점) + `_AddQuoteButton`("이 책 인용구 추가" → `/quote/new?bookId=`) + `_LibraryActionButton`(`isInLibraryProvider` EXISTS → 담겼으면 `_InLibraryChip` ✓, 아니면 [서재에 담기]; 미로그인이면 `/auth/login?from=` 경유 복귀 — payload 보존; deep link 진입 시 `prominent` "내 서재에 담기" 1급) + `_BookQuotesSection`(`bookQuotesProvider` 재사용 — 헤더 "이 책에서 모은 구절 N" + 최대 3개 `QuoteListCard`(book:null) + 초과 시 [전체 보기 ▸ → /library?tab=quotes], 부분 실패 격리) + `_SharedBanner`(`?from=share|kakao`) + `_DescriptionText`(LayoutBuilder+TextPainter로 6줄 초과 감지 → 클램프+fade+[더 보기]/[접기]) + `_NotFoundView`(책 없음 → [홈으로]/[내 서재]) + `_ErrorView`([다시 시도]) + `_OverflowMenu`(담긴 책이면 ⋮[서재에서 빼기] 확인 다이얼로그). raw `$e` 미노출. AppBar ← = `canPop ? pop : go('/')`. `book_repository.isInLibrary` + `isInLibraryProvider` 신규, `router.dart` `/book/:id` builder가 `?from=` 전달. `deep_link_handler` 일반화 — `_handle(uri, cold:)`: auth code면 `getSessionFromUrl`(기존), 아니면 `_routeFor`(`://book/:id?from=` → `/book/:id?from=`)로 매핑 → 워밍이면 `router.go`, 콜드면 `_pendingRoute` 보류 → 스플래시 `_resolve`가 `consumePendingRoute`로 소비. `_seen` set으로 URI 1회 consume. `BookquoteApp` → ConsumerStatefulWidget, initState서 `attachRouter`. book_detail_screen_test 7개. — 설계: `screens/book-detail.md` · `deep-link-receive.md`
- [x] **별점** 책 별점 — `user_books.rating smallint 1~5`(마이그레이션 `20260512130000`, **remote 적용**), `book_repository.setMyRating/getMyRating`, `myRatingProvider`, `StarRating` 위젯(읽기전용/인터랙티브, 재탭=지우기), `book_detail_screen` 헤더에 별점 행(로그인 시만) + raw `$e` 노출 제거. star_rating_test 4개. 반쪽 별은 V1.5 (DECISIONS 2026-05-13)
- [~] 아웃박스 flush 트리거 — 포그라운드 복귀 시 `QuoteOutbox.flush`는 PR3에서 배선됨. `connectivity_plus` 연결-회복 트리거 + "동기화 대기" 배너는 후속(백로그)

## Stage 3 — 카드 (3–4주, 가장 공들일 단계) — 설계 완료, 구현 대기

설계: `screens/card-editor.md` + `screens/card-share.md`. 텍스트 위치 앵커(상/중/하)는 V1.5(V1은 폰트 크기 ±·정렬만). 표지 없는 책에서 T4 = 비활성화. DECISIONS 2026-05-12.

- [ ] 5개 카드 템플릿 위젯 구현 (`sealed class CardTemplate` ×5, 위젯 트리 — CustomPaint 아님)
- [ ] 색 추출 (`palette_generator` → `ExtractedPalette`, `palette_service` 메모리 LRU 캐시, `ensureContrast` WCAG AA 4.5:1, 채도<10 폴백. `Color` 채널은 `toARGB32()` 기준)
- [ ] 카드 편집기 (3단 고정 레이아웃, 팔레트 비동기·카드 동기, 언두 최소 20단계 — 비율·템플릿 전환 포함)
- [ ] 이미지 export (`card_renderer` — `RepaintBoundary.toImage`, `AppCardSize` 1080 기준, 폰트 로드 완료를 캡처 전 보장, 워터마크 캡처 트리 안 Positioned. pubspec: `share_plus`·`path_provider`·`gal`)
- [ ] `cards` 테이블 (`design jsonb`, `on delete cascade auth.users` — 탈퇴 정합)
- [ ] SNS 공유 시트 (카카오톡 1순위, V1=`share_plus` OS 시트, 권한 거부해도 공유는 됨. 카카오 SDK 메시지 카드 공유는 V1.1)
- [~] deep link 받기 — `deep_link_handler` 일반화(`/book/:id` 라우팅 + payload 보존 + 1회 consume) **PR6에서 완료**. 책 상세 "내 서재 담기" 1탭도 PR6에 있음. 잔여: 미로그인 복귀 후 자동 담기(현재는 재탭) + 받은 인용구 카드 풀스펙(quoteId는 RLS상 받는 쪽이 못 읽어 V1.5 — sender 이름·인용구 복제) + (V1.5) Universal/App Link. 설계: `screens/deep-link-receive.md`

## Stage 4 — 소셜 레이어 (2–3주)

- [ ] ~~친구 검색 + follow~~ → V1.5 (V1 출시엔 안 함 — 솔로 도구 + 단톡 1탭 공유. DECISIONS 2026-05-12. Me의 "친구 찾기"는 V1엔 숨김)
- [ ] ~~친구 인용구 타임라인~~ → V1.5 (홈 피드에 합쳐 진화. `received_cards` 테이블도 V1.5)
- [ ] 단톡방 챌린지 메커닉 / spoiler 게이팅 → V1.5
- [ ] 본인 폰 한 달 dogfooding
- [ ] 친구 1–3명 베타

## Stage 5 — 출시 (1–2주)

- [~] **(출시 블로커) in-app 계정 삭제** — Edge Function `supabase/functions/delete-account/index.ts` **작성 완료**(PR5 — JWT로 호출자 확인 → service_role `auth.admin.deleteUser`, cascade로 `quotes`/`user_books`/`profiles` 자동 삭제; `cards`는 Stage 3에서 `on delete cascade` 챙길 것), Me 화면에서 2단계 확인 후 invoke. **남은 일: 배포** — `npx --yes supabase functions deploy delete-account` (Edge Function에 `SUPABASE_*` 자동 주입이라 시크릿 설정 불필요). Apple Guideline 5.1.1(v) + Google Play 둘 다 요구.
- [ ] **(출시 블로커) 개인정보처리방침·이용약관 페이지** — 호스팅(GitHub Pages/Notion 등). PR5에서 Me 화면 `url_launcher` 링크는 이미 연결돼 있으나 URL이 placeholder(`me_screen.dart` `_termsUrl`/`_privacyUrl`) — 실제 페이지 만들고 상수 교체 + 스토어 등록 폼
- [ ] 앱스토어·플레이스토어 등록
- [ ] PostHog 연동, 핵심 funnel 측정 setup (PII 미전송 — 인용구 텍스트·검색어 raw 안 보냄)
- [ ] 인스타 본인 인용구 카드 매일 1개 (W-4부터)
- [ ] 디스콰이엇·긱뉴스 한국 IT 커뮤니티 게시
