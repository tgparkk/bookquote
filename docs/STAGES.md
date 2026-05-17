# Stage 진행 체크리스트

마스터 플랜(`docs/PLAN.md`)에서 추출한 단계별 작업과 현재 상태.
완료한 것은 `[x]`, 진행 중은 `[~]`, 폐기는 `[-]`로 표시한다.

총 14–21주 (3.5–5개월) 목표. 사용자의 모토는 **"서두르지 않고 고득하게"**.

---

## ▶ 다음 세션 시작점 (2026-05-17 기준 — PR14 시리즈 완료)

**상태**: Stage 0~1 완료 + 화면 설계 완료 + Stage 2 본 작업 종료(PR1~6 + 별점) + **Stage 3 전체 완료 — PR7~PR12(+PR10.5 1탭 공유, +인용구 편집 모드, +출시 약관 페이지)** + **PR13 출시 직전 P0 fix 2건(F1·B11)** + **PR14 출시 직전 P1 15건 6 sub-PR 완료**(A 아웃박스 안전성·B 인용구 입력 검증·C 카드 lifecycle·D UX·접근성·E Markdown XFile + draft 시점·F 매직링크 타임아웃 안내). 다음은 **Stage 5 본 작업**(스토어 등록·PostHog·인스타·커뮤니티 게시) + **B9 검증**. `flutter analyze` clean, `flutter test` 127개 통과. 마이그레이션 5개(`quotes`, `user_books.rating`, `my_quote_mood_counts`, **`cards`**, +Stage1 4개) 원격 적용 완료. main에 push됨. 실기기(SM F956N) PR10 검증 통과 — 카카오톡/인스타 공유 OK. **PR10 hotfix 2건**(2026-05-16): ① `main/AndroidManifest.xml` `INTERNET` 권한 누락(debug/profile에만 있어 release APK는 모든 네트워크 호출 SocketException) ② `card_renderer.dart`의 `boundary.debugNeedsPaint` 사용 — SDK 내부에서 assert로만 초기화되는 late bool 반환이라 release/profile에서 `LateInitializationError`. 둘 다 PR5/PR10 시점부터 잠재해 있던 release-only 버그. 향후 모든 release 빌드는 이 두 함정 인지하고 동작.

**지금 동작하는 플로우**: 로그인 → 홈(내 인용 피드: 무한스크롤·당겨새로고침·빈상태 CTA·카드 탭 펼침→[📤 바로 공유 ↗]/[카드 디자인]/[삭제] — 바로 공유는 draft 또는 추천 디자인으로 즉시 PNG 렌더 + 공유 시트) → ＋ → 인용구 입력(본문/클립보드 붙여넣기/책 연결/페이지/무드/draft/오프라인 큐잉) → 저장 → 홈 반영 / 서재 [책↔인용구] 세그먼트 — "인용구" 탭 무드별 다시보기 / **책 상세**(별점·"이 책에서 모은 N구절" 미니리스트·"이 책 인용구 추가" CTA·`isInLibrary`면 ✓칩 아니면 [서재에 담기]·⋮[서재에서 빼기]·설명 점진적 공개·`?from=share` deep link면 공유 배너 + "내 서재에 담기" 1급 CTA) / **내 정보**(프로필·인용/서재 count·Markdown 내보내기·약관/개인정보/문의 링크·로그아웃[아웃박스 경고]·회원 탈퇴 2단계) / 책 검색·로그인은 Stage 1. ("카드 만들기 →"는 카드 에디터 스텁으로 감 — Stage 3.) **deep link**: `://book/:id?from=share` → 핸들러가 GoRouter로 라우팅(콜드스타트는 스플래시가 보류 경로 소비, 워밍은 즉시 `router.go`, URI 1회 consume). 미로그인 "담기" 탭 → `/auth/login?from=` 경유 복귀(payload 보존).

**Designer + Planner walkthrough 산출** (2026-05-17, 6 페르소나 S1·S2·S6 designer + S3·S4·S5 planner 병렬 위임). **신규 발견 P1 9건**(designer W1·W2·W3·W4·W5·W7·W9 + planner 4건). **즉시 처리 1건 — PR14-G**(aa68d8e) QuickShareScreen `_openEditor`가 `context.go`로 quick_share 스택을 교체해 카드 에디터 뒤로가기 시 홈 직행 → S6 "디자인 편집 → 다시 공유" 시나리오 단절(④ 막다른 골목 금지 무력화). 1줄 `push` 전환으로 에디터 뒤로 = quick_share 복귀, `_autoSheetTriggered=true` 덕분에 자동 시트 재발 없음, 사용자가 [다시 공유] 트리거. **검증 3건 grep 확정 — 모두 미구현(V1.0.1 hotfix 백로그)**: ① book_search_sheet "최근 책 5권" 섹션 부재(F7·S3 5번 반복 검색 마찰) ② share_service PNG 캐시 윈도우 부재(S4 4단톡 매 사이클 1080×1920 재생성) ③ 홈 AppBar 검색 부재(S5 47개 컬렉션 "그 구절 어디" 불가). **나머지 6건 출시 후 hotfix 묶음**: W1 BookSearchSheet 키보드/포커스 충돌, W2 PasteBanner 엄지 도달 외, W4 카드 에디터 진입 컨텍스트 단절, W5 본문 수정 X-닫기 미저장 경고 부재 + 복귀 invalidate noise, W7 quick_share 미리보기 노출 200ms 딜레이, W9 카드 접힘 상태 공유 아이콘. **planner 권고 — 차별화 강화 hotfix 후보**: 저장 후 SnackBar action `[이 책에 한 줄 더]`(축적), share_sheet 첫 공유 후 "다른 방에도?" 카피(반복 closure), 홈 상단 "이번 주 회고" 1행(차별화 ④ 진입성), Markdown 내보낸 후 정보성 BottomSheet 1회(차별화 ③ 감정 모멘트).

**PR14 산출**(2026-05-17, P1 15건 6 sub-PR — 시나리오 워크 후속): **PR14-A**(outbox/b7b473a) `QuoteOutbox`에 static `_isFlushing` 가드(B1) + `QuoteRepository.createQuote`에 PostgrestException code '23503' → `'FK_VIOLATION'` 별도 코드, flush에서 discarded 분류(B2) + `OutboxBanner` ConsumerWidget 신규 + `pendingOutboxCountProvider` + 홈·인용목록 상단 배너(F13) + home `_flushOutbox`에 discarded 안내 SnackBar + `enqueue` 후 `ref.invalidate(quoteOutboxProvider)`. flush에 named optional `uid` 추가(테스트 가능성). test/features/quote/quote_outbox_test.dart 신규 4개. **PR14-B**(quote_input/0c76d1a) `_submit` 진입부에 `page <= 0` 차단 + SnackBar(B5) + `_pasteFromClipboard`에 2000자 runes 기준 truncate + 안내 SnackBar(B6). quote_input_screen_test에 widget test 2 + 클립보드 mock helper 추출. **PR14-C**(card-editor/518008e) `_onEditQuoteTap` 복귀 시 `_initialized=false` + `_skipDraftDialog=true` → `_initializeFromData`가 다이얼로그 없이 draft 적용 또는 새 추천(B3) + quick_share `_share` 진입부에 `_captureKey.currentContext.size.isEmpty` 가드 + endOfFrame 1회 재시도(B12). **PR14-D**(card-editor·a11y/0554c10) AppBar `FilledButton.icon "공유"` 제거 + `bottomNavigationBar` Full-width FilledButton(높이 52)(F4) + `CardEditorController.setTemplate`에 `fontStep:0` 명시 + `_Editor`에 `selectTemplate`/`cycleTemplate` wrap + 전환 직전 step ≠ 0이었으면 SnackBar(F8) + `mood_chips._MoodChip` + `quote_list_view._Chip` 양쪽에 `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15)`(F9) + 워터마크 토글 후 ScaffoldMessenger SnackBar "워터마크를 켰어요/껐어요"(F10) + `_RatioSegment.style.textStyle` override 제거(B16). card_editor_controller_test 3개(F8 회귀 가드). release APK 빌드 sanity 통과. **PR14-E**(me·quote/ed1e302) `quote_export.dart`를 `getTemporaryDirectory` + 임시 `.md` 파일 + `ShareParams(files: [XFile(mimeType: 'text/markdown')], text, subject)` 첨부 전환(B4 — Android Binder ~500KB 한도 회피, share_plus가 FileProvider 처리 → AndroidManifest 변경 불필요) + `QuoteDraftStore` 저장 포맷 v2 wrapper(`{input, savedAt: ISO8601}`) + 구 포맷(QuoteInput JSON 단독) 호환 + `quote_input_screen._maybeRestoreDraft` SnackBar에 `_relativeTime` "N분/시간/일/주 전"(F5). quote_draft_test 신규 5개. **PR14-F**(auth/6736b2e) `AuthCallbackScreen`에 `_timedOut` state — 10초 타임아웃 시 즉시 navigate 대신 사유 안내 + [로그인 화면으로] 버튼(B8). 사용자가 명시적으로 탭해야 /auth/login으로. `_LoadingNotice`/`_TimeoutNotice` 분리. **합산**: 6 commit, 146/146 테스트 통과(PR14 신규 14개), flutter analyze clean.

**바로 이어서 할 것** → **Stage 5 출시 준비 본 작업** + **B9 검증**. PR5 남긴 출시 블로커 2건 처리 완료(2026-05-16): ① `delete-account` Edge Function 운영 배포(project `ndbvptxwznogcuuumzzh`, version 1 ACTIVE, 인증 없는 POST → 401 게이트웨이 응답 확인) ② GitHub Pages 활성화(Source = `main /docs`, `https://tgparkk.github.io/bookquote/{terms,privacy}/` 둘 다 HTTP 200 + 컨텐츠 검증 OK — 스토어 등록 폼에 이 URL 그대로 사용). 남은 Stage 5: 앱스토어·플레이스토어 등록·심사, PostHog funnel(PII 미전송), 인스타 매일 1개 카드(W-4부터), 디스콰이엇·긱뉴스 게시. **B9 검증 대기**: 저사양 카드 에디터 OOM(release-only 의심) — Android 8/API 27 + 1.5GB RAM AVD 또는 친구 저사양 폰에서 카드 에디터 진입 + 템플릿 5회 전환 + PNG 캡처 + 공유 시나리오. 재현되면 P0 → `_MiniCard` 절대 1080 위젯을 56×96dp 경량 위젯으로 대체. 미재현이면 P1로 강등하고 백로그. **PR12 산출**: A=언두 ≥20 + `state.canUndo`+⤺ AppBar. B=`fontStep ±3` + [A−][A+] + 따뜻 카드 `ensureContrast` 대비 보강(어두운 표지 + lightenToBackground 후 가독성 회복). C=5스와치(`paletteSlotIndex` 0~4) + "다른 느낌 ↻"(기존 `cycleTemplate` 명시 노출) + `applyPaletteSlot` helper. D=auto-fit 경고(비율별 charCount 휴리스틱 feed=300/post=450/story=600, 추천 비율 1탭 적용). E=접근성(_Swatch hit area 28→48dp, 카드 미리보기·_MiniCard Semantics 라벨, IconButton tooltip 보장). 골든 12장(4종×3비율, T4 cover URL 의존이라 별도 fixture 시 추후). **PR7 산출**: `lib/features/card_editor/{domain,data,presentation/widgets}/*` — `sealed CardTemplate` ×5 + `supports/recommended/byId/all` + `QuoteCardData` + 5종 위젯(1080 절대 캔버스 — "미리보기=export") + `QuoteCard` 디스패처 + `CardWatermark` + `color_utils.{lightenToBackground,toMidTone}` + `splitIntoPoetryLines`(chunk별 강제 줄바꿈 보존)/`getTypographyFontSize`. **PR8 산출**: `color_utils`에 WCAG 2.1 4종(`relativeLuminance`/`contrastRatio`/`ensureContrast(4.5)`/`getTextColorForBackground` 임계 0.18). `palette_service.dart` — `LinkedHashMap` LRU(maxCacheSize 100, 타임아웃 3s) + `getPaletteWithFallback(coverUrl?, templateId)` + `PaletteGeneratorFactory` 주입. `palette_providers.dart` — `paletteServiceProvider`(앱 1 인스턴스) + `extractedPaletteProvider` family(키 = Dart record). screen `_PreviewBox`/`_MiniCard` → `ConsumerWidget` 전환, `.value ?? fallbackFor` + `AnimatedSwitcher` 200ms cross-fade. **PR9 산출**: `state/quote_card_data_provider.dart` — `quoteByIdProvider` + `bookByIdProvider` 합성(book 없으면 `manualBookText` 폴백) `AsyncValue<QuoteCardData?>`. `state/card_editor_controller.dart` — non-family `Notifier<CardEditorState>` + `attach(quoteId)` 1회 + 500ms 디버운스 `shared_preferences` 영속화(키 `card-editor-draft:{quoteId}`) + `setTemplate/setRatio/toggleWatermark/applyRecommended/cycleTemplate/readDraft/applyState/clearDraft`. `CardEditorState(templateId, ratio, watermarkEnabled)` JSON round-trip. screen = `ConsumerStatefulWidget` — mock 제거, `quoteCardDataProvider` watch, 진입 시 `readDraft` → "이어서 만들기 / 새로 시작" 다이얼로그 → 새로 시작은 `applyRecommended(charCount, hasCover)`. AppBar action에 워터마크 토글(`copyright_rounded` 아이콘) + 비율 세그먼트. quote 없음(`PGRST116`)·로드 실패 별도 view. **PR10 산출**: `data/card_renderer.dart` — `renderCardPng({GlobalKey boundaryKey, CardRatio ratio})` → `RenderRepaintBoundary.toImage(pixelRatio = ratio.size.width / boundary.size.width)` + 캡처 전 `endOfFrame` 2회(폰트 atlas + paint 안전망. 초기엔 `debugNeedsPaint`로 1회 재시도 분기였으나 release에서 LateInitializationError 던져서 hotfix로 제거) + `ui.Image.dispose()` + `path_provider` 임시파일. `data/share_service.dart` — `shareCardImage({XFile file, String? subject})` = `SharePlus.instance.share(ShareParams(files:[file]))` 단일 wrapper, `CardShareException` 메시지 래핑. `presentation/widgets/share_sheet.dart` — `showCardShareSheet(context, file, shareText)` `showModalBottomSheet(isScrollControlled:true)` + 드래그 핸들 + 4버튼(카카오 #FEE500 / 인스타·저장·다른앱 outlined) — V1은 모두 동일하게 `shareCardImage` 호출, 권한/SDK 분기는 V1.1. `card_editor_screen` AppBar에 accent500 FilledButton "공유"(`_isSharing` 토글 → CircularProgressIndicator), `_PreviewBox` 안 AspectRatio child를 `RepaintBoundary(key:_captureKey)` 래핑("미리보기=export" 그대로 캡처). `pubspec.yaml` `path_provider: ^2.1.5`. `android/app/src/main/AndroidManifest.xml`에 `<uses-permission android:name="android.permission.INTERNET" />` 추가(hotfix). **PR10.5 산출** (디자이너 권고 — 2026-05-16): `lib/features/card_editor/quick_share_screen.dart` 신규 — `/quote/:id/share` 풀스크린 route, 진입 즉시 `quoteCardDataProvider` 로드 + `card_editor_controller.readDraft` 분기(있으면 그대로, 없으면 `applyRecommended`) + `endOfFrame` 2회 → `renderCardPng` + `showCardShareSheet` 자동 호출. 시트 dismiss 후 화면 유지([다시 공유]/[디자인 편집] 출구, ④ 막다른 골목 금지). `quote_list_card.dart` 펼침 액션 위계 재조정: [📤 바로 공유] FilledButton accent500 / [✏ 카드 디자인] OutlinedButton primary200 / [삭제] TextButton semanticError, Wrap으로 좁은 폰 대비. home/library/book_detail 3곳 callsite에 `onShare` 배선. router에 `/quote/:id/share` 추가. **PR11 산출** (cards 테이블 + 비차단 INSERT — 2026-05-16): `supabase/migrations/20260516120000_cards.sql` 신규 — `cards` 테이블(user_id `on delete cascade auth.users` 탈퇴 정합, quote_id `on delete cascade quotes`, book_id `on delete set null books`, `design jsonb`(templateId/ratio/watermarkEnabled), `shared_at timestamptz`, RLS 본인만 select/insert, update/delete 정책 없음 — V1 immutable), 원격 push 완료. `lib/features/card_editor/data/card_repository.dart` 신규 — `recordShare({quoteId, bookId?, design})` fire-and-forget INSERT, Supabase 미초기화·미로그인 환경 no-op, 실패 silently swallow(공유는 이미 OS 시트로 끝남). `CardEditorState.toJson()`을 design jsonb로 그대로 INSERT(별도 도메인 모델 없이 controller state 재사용). `QuoteCardData`에 `bookId` 필드 추가. `card_editor_screen._onShareTap` + `quick_share_screen._share` 둘 다 `showCardShareSheet` 직전 `unawaited(recordShare(...))` 비차단 호출. **PR12 부분 산출** (골든 스냅샷 — 2026-05-16): `test/features/card_editor/golden_card_test.dart` 신규 — 5종 × 3비율 매트릭스에서 `supports` 게이트 통과 케이스만 자동 생성 = **12장**(T4 CoverExtract는 cover URL 의존이라 별도 fixture 필요 시 추후). `setUpAll`에서 `FontLoader`로 NotoSerifKR + Pretendard 명시 등록(flutter_test 기본 Ahem 폰트 회피). `setSurfaceSize` + `view.physicalSize = ratio.size`로 카드 위젯의 절대 1080×N 픽셀 그대로 캡처 — 실 export와 픽셀 동일. `matchesGoldenFile`로 회귀 단언. `--update-goldens`로 재생성 워크플로우. **테스트**: PR7 19개 + PR8 24개 + PR9 15개 + PR10 3개 + PR10.5 4개 + PR11 3개 + PR12-A 7개(undo) + 골든 12장 + PR13 5개(login 2 + submit_update 3). 총 132/132 통과. **PR13 산출**(2026-05-17, 매니저 모드 시나리오 워크 후 P0 fix): `docs/discovery/scenario-review-2026-05-17.md` — 14 시나리오 × 가상 팀(기획자·UI/UX·QA) 병렬 협의로 UX 마찰 17 + 엣지·실패 18 = 35건 발견. P0 후보 6건을 매니저 코드 대조로 재판정 → F1·B11만 P0 유지, B9는 검증 대기, 나머지는 P1/P2. **F1**: `lib/features/auth/login_screen.dart` `_SentNotice`에 `onResetEmail` 콜백 + [이메일이 다른가요? 다시 입력] TextButton 추가 → 부모가 `_linkSent=false` 토글해 Form 입력 화면 복귀(이메일 오타·도메인 오타 시 앱 재시작 외 탈출구 부재 해소). **B11**: `lib/features/quote/state/quote_providers.dart` `submitUpdate(clearBook=false)` 명시 파라미터 — 기존 `clearBook: input.bookId == null` 자동 추론 제거. `quote_repository.updateQuote`의 `?bookId` null-aware map literal이 bookId null이면 patch에서 키 제외하므로 `clearBook=false`면 책 연결 자연 유지. V1엔 책 해제 UI 없으므로 호출자가 명시하지 않으면 항상 false → prefill 실패(저속 회선·일시 미응답)에서 silent 데이터 손실 차단. V1.5 책 해제 액션 추가 시 명시 `clearBook: true` 전달.

**✅ PR5 남긴 출시 블로커 — 처리 완료 (2026-05-16)**:
- `delete-account` Edge Function 운영 배포 완료. project `ndbvptxwznogcuuumzzh`, version 1 ACTIVE. 인증 없는 POST → HTTP 401 `UNAUTHORIZED_NO_AUTH_HEADER`(Supabase 게이트웨이가 JWT 1차 검증). 로그인된 사용자 JWT로 호출 시 함수 내부 로직 진입 → `auth.admin.deleteUser` → cascade로 `quotes`/`user_books`/`profiles`/`cards` 삭제. Apple 5.1.1(v)/Google Play 요구 충족.
- 약관·개인정보처리방침 라이브. GitHub Pages 활성화(Source = `main /docs`), `https://tgparkk.github.io/bookquote/terms/` + `/privacy/` 둘 다 HTTP 200 + `<title>` 검증 OK. 스토어 등록 폼·앱 내 [이용약관]/[개인정보처리방침] 외부 링크에서 이 URL 그대로 사용.

**문서 지도** (2026-05-14 정리): `docs/app-scenarios.md`(현재 V1 동선 — `discovery/flows.md` 초안 대체) · `docs/db-schema.md`(현재 DB 설계서 — `discovery/api-design.md`·`architecture.md` 초안 대체) · `docs/design/screens/README.md`(화면 13개 인덱스 + 구현 상태 + 실제 파일 경로) · `docs/design/screens/*.md`(화면별 7섹션 명세). `discovery/`의 architecture·api-design·flows는 시점 고정 초안(상단 배너).

**작업 방식 메모**: 각 PR = main에 직접 commit+push(Stage 1 패턴), 매 PR마다 `flutter analyze` + `flutter test` 통과 + 위젯/유닛 테스트 추가, 마이그레이션은 작성 후 `npx supabase db push`(supabase 명령은 PATH에 없음 — `npx --yes supabase ...` 사용, `printf 'y\n' |`로 프롬프트 통과). 매니저 모드(가상 팀)는 설계 단계용 — 구현 PR은 설계 문서(`docs/design/screens/*.md`)가 충분히 상세해 직접 구현. **빌드 명령 표준** — `flutter run`·`flutter build apk`·`flutter build apk --release` 모두 항상 `--dart-define-from-file=.env.json` 동반(빠뜨리면 `Env.supabaseUrl/anonKey` 빈 문자열 → `initSupabase` 가 `_ready=false`로 silent skip → 로그인 버튼·DB 호출 전부 무반응으로 보임. 토스트도 안 뜸). 폰 install은 `flutter install` 대신 `adb install -r build/app/outputs/flutter-apk/app-release.apk`로 데이터 보존(adb는 `C:/Users/sttgp/AppData/Local/Android/Sdk/platform-tools/adb.exe`, `-s R3CXA0PANWX`로 폰 지정).

### 후속 작업 백로그 (Stage 2 마무리 전후 — 우선순위 낮음)
- 아웃박스 `connectivity_plus` 연결-회복 트리거(현재 포그라운드 복귀 시만) + 홈/인용목록에 "동기화 대기 N개" 배너
- 인용구 [수정] (= `/quote/new?quoteId=` 편집 모드) · 카드/목록의 인라인 [무드 변경]
- 인용 목록 정렬(책별 그룹 / 페이지순) · 인용구 텍스트 검색(서버 `ilike`) · 홈/책상세 무드 칩 탭 → `/library?tab=quotes&mood=` navigation
- 서재 책 카드: "이 책에서 모은 N구절" 배지 + 표지 dominant color 띠
- 삭제 시 undo SnackBar(현재는 확인 다이얼로그)
- Me: Markdown 내보내기를 텍스트 공유 대신 `.md` 파일 첨부(`XFile`) — 컬렉션 큰 경우 안드로이드 인텐트 한도 회피 / 다크모드 토글(`[시스템/라이트/다크]` + `darkTheme` 정의) = V1.5 / 섹션 사이 `Divider` 시각 구분 / 카운트 trailing 변경 후 `invalidate(myQuoteCountProvider)` 동선(인용구 추가/삭제 시)
- 그룹 3 역정리 문서의 나머지 개선: 로그인 매직링크 재전송 출구 + `?from=` 보존, 콜백 타임아웃 사유 안내, 책 검색 시트 검색-전 빈결과·ISBN 직접 등록·오프라인 캐시-우선, 스플래시 워드마크·안전망 시간 실측
- **릴리스 빌드 로그인 무반응 — 원인 확정(2026-05-13)**: `flutter build apk --release`에 `--dart-define-from-file=.env.json`을 빠뜨리면 `Env.supabaseUrl`/`anonKey`가 빈 문자열 → `initSupabase`가 `_ready=false`로 통과 → 로그인 화면 [이메일로 시작] 버튼이 silent fail(토스트도 안 뜸). Resend SMTP나 이메일 한도 문제 아님. 빌드 명령에 항상 dart-define 동반(작업 방식 메모 참조). **개선 백로그**: `kReleaseMode && !isSupabaseReady`면 스플래시/로그인 화면에 "환경 설정 누락" 진단 배너를 표시해 다음에 헷갈리지 않게.
- (개발 편의 메모) **폰 install 데이터 보존** — `android/app/build.gradle.kts`의 release config가 `signingConfigs.debug`를 그대로 사용해 release/debug 양쪽 서명 키가 같음(개인 빌드 한정). 따라서 빌드 타입 무관 `adb install -r`로 reinstall하면 데이터 유지. 단 다른 머신에서 빌드한 APK는 `debug.keystore`가 다르므로 서명 mismatch 가능 → fresh install되어 세션 날아감. 스토어 배포는 별도 release 키를 묶을 때 동일성 자동 보장.
- (2026-05-13 관찰) PR9 시각 검증 직전 한 번 `flutter_secure_storage` 세션이 날아간 사건 — 위 dart-define 누락 + `install -r` 자체는 성공했으나 Supabase 미초기화로 세션 read 자체 무의미. 재발 시 위 빌드 명령 표준 확인.

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

## Stage 3 — 카드 (3–4주, 가장 공들일 단계) — PR7~10 완료, PR11~12 대기

설계: `screens/card-editor.md` + `screens/card-share.md`. 텍스트 위치 앵커(상/중/하)는 V1.5(V1은 폰트 크기 ±·정렬만). 표지 없는 책에서 T4 = 비활성화. DECISIONS 2026-05-12.

- [x] **PR7** 5개 카드 템플릿 위젯 구현 (`sealed class CardTemplate` ×5, 위젯 트리 — CustomPaint 아님)
- [x] **PR8** 색 추출 (`palette_generator` → `ExtractedPalette`, `palette_service` 메모리 LRU 캐시, `ensureContrast` WCAG AA 4.5:1, 채도<10 폴백)
- [x] **PR9** 카드 편집기 MVP (controller + 실데이터 + "이어서" + 비율·워터마크 토글). 언두 ≥20·텍스트 ±는 PR12
- [x] **PR10** 이미지 export (`card_renderer` — `RenderRepaintBoundary.toImage`, `pixelRatio = ratio.size.width / boundary.size.width`, 폰트 로드 보장 endOfFrame, `ui.Image.dispose`. `pubspec`: `path_provider` 추가. `gal`은 V1.1)
- [x] **PR10** SNS 공유 시트 (`share_sheet.dart` 4버튼 + V1은 모두 `SharePlus.share(ShareParams(files:[XFile]))` OS 시트, 카카오 SDK 메시지 카드는 V1.1)
- [x] **PR10.5** 홈 카드 1탭 공유 (디자이너 권고 — 매번 에디터 강제 제거). `QuickShareScreen` 풀스크린 route + draft/추천 자동 적용 + 자동 시트. `QuoteListCard` 펼침 [📤 바로 공유]/[✏ 카드 디자인]/[삭제] 위계 재조정
- [x] **PR11** `cards` 테이블 (`design jsonb`, `on delete cascade auth.users` — 탈퇴 정합) + 공유 시점 비차단 INSERT (`card_repository.recordShare` fire-and-forget). 마이그레이션 원격 적용 완료
- [x] **PR12** 5하위 PR 분할 완료(2026-05-16): A=언두 ≥20(`_undoStack`+⤺ AppBar). B=폰트 ±(`fontStep` int±3, [A−][A+]) + 따뜻 카드 대비 보강(`ensureContrast`). C=5스와치(`paletteSlotIndex`+`applyPaletteSlot`) + "다른 느낌 ↻"(`cycleTemplate` 명시 노출). D=auto-fit 경고(비율별 charCount 휴리스틱 + 추천 비율 1탭). E=접근성(_Swatch hit area 48dp + 카드 미리보기/_MiniCard Semantics 라벨). 골든 12장은 별도 commit으로 사전 완료
- [~] deep link 받기 — `deep_link_handler` 일반화(`/book/:id` 라우팅 + payload 보존 + 1회 consume) **PR6에서 완료**. 책 상세 "내 서재 담기" 1탭도 PR6에 있음. 잔여: 미로그인 복귀 후 자동 담기(현재는 재탭) + 받은 인용구 카드 풀스펙(quoteId는 RLS상 받는 쪽이 못 읽어 V1.5 — sender 이름·인용구 복제) + (V1.5) Universal/App Link. 설계: `screens/deep-link-receive.md`

## Stage 4 — 소셜 레이어 (2–3주)

- [ ] ~~친구 검색 + follow~~ → V1.5 (V1 출시엔 안 함 — 솔로 도구 + 단톡 1탭 공유. DECISIONS 2026-05-12. Me의 "친구 찾기"는 V1엔 숨김)
- [ ] ~~친구 인용구 타임라인~~ → V1.5 (홈 피드에 합쳐 진화. `received_cards` 테이블도 V1.5)
- [ ] 단톡방 챌린지 메커닉 / spoiler 게이팅 → V1.5
- [ ] 본인 폰 한 달 dogfooding
- [ ] 친구 1–3명 베타

## Stage 5 — 출시 (1–2주)

- [x] **(출시 블로커) in-app 계정 삭제** — Edge Function `supabase/functions/delete-account/index.ts` 작성+운영 배포 완료(2026-05-16, project `ndbvptxwznogcuuumzzh`, version 1 ACTIVE). JWT로 호출자 확인 → service_role `auth.admin.deleteUser` → cascade로 `quotes`/`user_books`/`profiles`/`cards`(`cards`는 PR11에서 `on delete cascade auth.users` 챙김) 자동 삭제. Me 화면 2단계 확인 후 invoke. Apple Guideline 5.1.1(v) + Google Play 요구 충족. 향후 함수 코드 변경 시 `printf 'y\n' | npx --yes supabase functions deploy delete-account` 재배포.
- [x] **(출시 블로커) 개인정보처리방침·이용약관 페이지** — 정적 HTML `docs/terms/index.html` + `docs/privacy/index.html` + GitHub Pages 활성화 완료(2026-05-16, 저장소 Settings > Pages, Source = `main /docs`). 라이브 URL: `https://tgparkk.github.io/bookquote/terms/` + `/privacy/`, 둘 다 HTTP 200 + 컨텐츠 검증 OK. 스토어 등록 폼·앱 외부 링크에 이 URL 사용. 기존 `tgparkk.github.io` User Pages와 별개 Project Pages이므로 충돌 없음.
- [ ] 앱스토어·플레이스토어 등록
- [ ] PostHog 연동, 핵심 funnel 측정 setup (PII 미전송 — 인용구 텍스트·검색어 raw 안 보냄)
- [ ] 인스타 본인 인용구 카드 매일 1개 (W-4부터)
- [ ] 디스콰이엇·긱뉴스 한국 IT 커뮤니티 게시
