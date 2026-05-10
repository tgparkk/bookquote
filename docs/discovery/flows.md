# 핵심 사용자 플로우 시퀀스 (V1)

**버전**: 0.2 (2026-05-09 — Flutter 스택 반영)
**연계**: `architecture.md` · `client-architecture.md` · `api-design.md`
**스택 변경 이력**: 0.1 RN+Expo+TS → 0.2 Flutter+Dart (라이브러리 표기 일괄 교체)

이 문서는 코딩 시점에 "이 플로우가 어떻게 작동해야 하는가"를 step-by-step으로 답하기 위함. 각 플로우는 화면·API·캐시·UI 상태를 동시에 추적.

---

## 1. 다룰 6개 플로우와 우선순위

| # | 플로우 | 빈도 | 중요도 |
|---|---|---|---|
| **A** | 신규 가입 → 첫 인용구 저장 | 1회/사용자 | ★★★ Activation 핵심 |
| **B** | 인용구 추가 → 카드 → 공유 | 매일 | ★★★ 핵심 가치 |
| **C** | Timeline 진입 → 친구 카드 → 책 추가 | 매일 | ★★ 바이럴 메커닉 |
| **D** | 책 검색 → 서재 추가 | 주 1–2회 | ★★ |
| **E** | 친구 추가 (검색·카톡 매칭) | 가입 후 1주 집중 | ★ |
| **F** | 오프라인 인용구 작성 → 동기화 | 지하철 등 | ★★ 모바일 특수 |

---

## 2. Notation

```
[User]      = 사용자 행동
[App]       = 클라이언트 앱
[API]       = features/<X>/api.ts 함수
[Supabase]  = 백엔드
[External]  = 알라딘·Kakao 등 외부

목표 latency: 사용자 체감 기준
  - <100ms: 즉각
  - <300ms: 부드러움
  - <1s: 허용 가능
  - >1s: loading indicator 필수
```

---

## 3. Flow A — 신규 가입 → 첫 인용구 저장

**목표**: 다운로드 → 가입 → "이 앱 좀 쓸 만하네" 순간까지 5분 안에 도달.

**성공 지표 (Activation)**: 가입 후 7일 내 인용구 3개 이상 저장 (목표 40%)

### 3.1 Step-by-step

```
[User] 앱 다운로드 후 첫 실행
  └─ App 시작
       └─ [App] 세션 확인 (sessionNotifierProvider)
            └─ session 없음 → go_router redirect → /auth/login

[User] login 화면 본다
  └─ [App] 표시: "책귀" 로고 + 책 표지 hero + 카카오/이메일 버튼

[User] "카카오로 시작" 탭
  └─ [Repository] authRepository.signInWithKakao()
       └─ [App] flutter_web_auth_2.authenticate(kakaoAuthUrl)
       └─ [Kakao] 사용자 인증·동의
       └─ [App] redirect URL로 돌아옴 (quotesapp://auth/callback?code=...)
       └─ [Supabase Auth] 세션 발급
       └─ [App] sessionNotifier 자동 업데이트 (onAuthStateChange 스트림)
       └─ [Supabase Trigger] auth.users INSERT → public.profiles row 자동 생성
            (display_name = Kakao 닉네임, avatar_url = Kakao 프로필)

[User] go_router redirect → / 진입 (timeline 비어있음)
  └─ [App] 표시: empty state
       "아직 인용구가 없어요. 좋아하는 책의 한 줄을 저장해보세요."
       [+ 인용구 추가] 큰 버튼 1개

[User] [+ 인용구 추가] 탭 → /quote/new로 이동
[Flow B로 분기]
```

### 3.2 Sequence

```
User → App: 첫 실행
App → SecureStorage: 세션 조회 (Supabase 자동)
App → GoRouter: redirect → /auth/login

User → LoginScreen: "카카오로 시작" 탭
LoginScreen → flutter_web_auth_2: Kakao OAuth URL 오픈
flutter_web_auth_2 → User: 카카오 동의
flutter_web_auth_2 → LoginScreen: callback URL
LoginScreen → SupabaseAuth: exchangeCodeForSession
SupabaseAuth → Postgres: insert auth.users
Postgres → Trigger: insert public.profiles
SupabaseAuth → AuthStateStream: emit AuthState
AuthStateStream → SessionNotifier: state = session
SessionNotifier → GoRouter: redirect → /
GoRouter → TimelineScreen: render
TimelineScreen → timelineProvider: empty
TimelineScreen → User: empty state + CTA
```

### 3.3 핵심 UX 결정

- **온보딩 튜토리얼 없음**: empty state CTA 한 개로 학습. 튜토리얼은 첫 가치 도달 전에 마찰.
- **첫 화면이 timeline (비어있어도)**: 앱의 정체성("친구의 인용구를 보는 곳")을 즉시 전달.
- **Kakao 우선·이메일 보조 동등**: 한국 시장은 Kakao 클릭 비율 70%+ 예상.

### 3.4 Edge cases

- Kakao 인증 거부 → login 화면으로 복귀, 에러 toast "로그인이 취소되었어요"
- 네트워크 끊김 → "연결을 확인해주세요" + 재시도 버튼
- profiles trigger 실패 (드물게) → 클라이언트가 첫 진입 시 detect, "프로필 생성 중" 화면 노출

### 3.5 Latency targets

- 앱 시작 → login 화면 표시: <500ms
- "카카오로 시작" → WebBrowser 오픈: <300ms
- WebBrowser 닫힘 → timeline 진입: <1s

---

## 4. Flow B — 인용구 추가 → 카드 → 공유 (핵심 가치)

**목표**: 사용자가 가장 자주 하는 행동. **3분 안에 끝나야 함**. 단톡방 공유까지.

### 4.1 Step-by-step

```
[User] (책을 읽다 좋은 구절 발견. 폰 카메라로 페이지 사진 찍음. iOS Live Text로 텍스트 복사)
  └─ 우리 앱 진입

[User] tab bar의 가운데 [+] 탭
  └─ context.go('/quote/new')

[User] /quote/new 화면
  └─ [App] QuoteFormScreen
       ├─ 텍스트 영역 (자동 포커스, TextEditingController)
       ├─ 책 선택 영역 (비어있음)
       └─ 페이지 입력 (선택)

[User] 텍스트 영역에 클립보드 텍스트 붙여넣기
  └─ [App] TextEditingController가 quoteFormController state 갱신

[User] "책 선택" 탭
  └─ showModalBottomSheet → BookSearchSheet
  └─ [App] BookSearchSheet
       ├─ 검색바 (자동 포커스)
       └─ 최근 본 책 (이전 검색 결과 캐시)

[User] 책 제목 입력 ("작별하지...")
  └─ [App] Debouncer(milliseconds: 300)
  └─ [Repository] booksRepository.searchAladin(debouncedQuery)
       └─ [External Aladin] HTTPS GET ItemSearch.aspx
       └─ 결과 20개 반환 (title, author, cover_url, isbn)
  └─ [App] ListView.builder로 결과 렌더 (각 row: 표지 + 제목 + 저자)

[User] 검색 결과에서 "작별하지 않는다" 탭
  └─ [Repository] booksRepository.upsertFromAladin(selectedBook)
       └─ [Supabase] books UPSERT by ISBN → row id 반환
  └─ [Repository] booksRepository.addToLibrary(bookId, status='reading')
       └─ [Supabase] user_books INSERT (RLS 검증 자동)
  └─ [App] Navigator.pop으로 sheet 닫고 QuoteFormScreen으로 돌아옴
       └─ 책 선택 영역에 "📕 작별하지 않는다 · 한강" 표시

[User] 페이지 입력 "142"
[User] [카드 만들기 →] 탭
  └─ [Controller] createQuoteController.create({ bookId, text, page, visibility: 'public' })
       └─ [Supabase] quotes INSERT
       └─ [Supabase Realtime] publish to followers
  └─ [App] context.go('/card/${quote.id}')
  └─ [Riverpod] ref.invalidate(timelineProvider), userLibraryProvider, bookQuotesProvider(bookId)

[User] /card/:quoteId 진입
  └─ [App] CardEditorScreen
       ├─ 표지 이미지 prefetch (CachedNetworkImage / precacheImage)
       ├─ [paletteProvider(coverUrl)] palette_generator로 dominant 5색 추출
       └─ 첫 템플릿 'minimal' + 추출 색으로 카드 미리보기 렌더 (CustomPaint)

[User] 카드 미리보기 보면서 템플릿·색·폰트 조정
  └─ [App] cardEditorController.updateDesign(...)
       └─ Riverpod이 의존 위젯 rebuild → CustomPaint 60fps 유지

[User] 만족스러운 결과에서 [공유하기] 탭
  └─ [App] RepaintBoundary.toImage(pixelRatio: ...) → ByteData → PNG 파일 (1080×1920 또는 1080×1080)
  └─ [App] share_plus.shareXFiles([XFile(localPngPath)])
  └─ [OS] 시스템 share sheet
       ├─ 인스타 스토리
       ├─ 카카오톡
       ├─ 다운로드
       └─ 기타 앱

[User] 인스타 스토리 선택 → 인스타 앱 열림 → 자동으로 카드 이미지 첨부됨
  └─ (병렬) [Repository] cardRepository.save(quoteId, design) → cards 테이블 저장 (히스토리)
```

### 4.2 Sequence

```
User → QuoteForm: 텍스트 붙여넣기
User → QuoteForm: "책 선택" 탭
QuoteForm → BookSearchSheet: open
User → BookSearchSheet: 검색어 입력
BookSearchSheet → AladinClient: search(query)
AladinClient → AladinAPI: GET ItemSearch.aspx
AladinAPI → AladinClient: 20 results
BookSearchSheet → User: 결과 리스트
User → BookSearchSheet: 책 선택
BookSearchSheet → API.upsertBook: book data
API → Supabase: books UPSERT
Supabase → API: book row
BookSearchSheet → API.addToLibrary: bookId
API → Supabase: user_books INSERT
BookSearchSheet → QuoteForm: dismiss with selected book
User → QuoteForm: [카드 만들기 →]
QuoteForm → API.createQuote: input
API → Supabase: quotes INSERT
Supabase → Realtime: publish
Supabase → API: quote with book
QuoteForm → Router: /card/{quoteId}
Router → CardEditor: render
CardEditor → CachedNetworkImage: prefetch cover
CardEditor → ColorExtractor: extract palette
ColorExtractor → CardEditor: 5 colors
CardEditor → CustomPaint: render preview
User → CardEditor: 디자인 조정
User → CardEditor: [공유하기]
CardEditor → RepaintBoundary.toImage: capture PNG bytes
RepaintBoundary → CardEditor: localFilePath
CardEditor → share_plus: shareXFiles([XFile])
share_plus → OS: share sheet
User → OS: 인스타 스토리 선택
OS → InstagramApp: open with image
CardEditor → API.saveCard: design
API → Supabase: cards INSERT (병렬)
```

### 4.3 핵심 UX 결정

- **OCR은 폰 자체 기능 사용**: 우리는 텍스트 입력만 받음. 클립보드 붙여넣기가 1차 흐름.
- **책 선택을 sheet로**: 풀스크린 이동보다 컨텍스트 유지. 돌아왔을 때 인용구 텍스트 그대로.
- **카드 편집을 별도 화면**: 인용구 저장과 카드 만들기를 분리. 카드 만들기 안 하고도 인용구만 저장 가능.
- **공유 시 자동 워터마크 ON (default)**: 바이럴 메커닉. 사용자가 OFF 가능.
- **카드 PNG 서버에 업로드 X**: 디바이스에서 즉시 OS share. 우리 비용·복잡도 0.

### 4.4 Edge cases

- 알라딘 검색 결과 0개 → "찾는 책이 없나요? ISBN 직접 입력" 옵션
- 사용자가 카드 만들기 안 하고 뒤로 가기 → 인용구는 이미 저장됨, 나중에 책 상세에서 카드 만들기 가능
- 이미지 캡처 실패 (메모리 부족) → "다시 시도" toast, 디자인 옵션 유지
- 표지 이미지 로드 실패 → 카드는 placeholder 디자인으로 렌더 (베이지 + 텍스트)

### 4.5 Latency targets

- 책 검색 (debounced): <500ms (알라딘 응답)
- 책 선택 → quotes INSERT: <300ms
- 카드 편집기 진입: <500ms
- 디자인 변경 → 미리보기: <16ms (60fps)
- 공유하기 탭 → 시스템 share sheet: <500ms

---

## 5. Flow C — Timeline → 친구 카드 → 책 추가 (바이럴)

**목표**: 친구가 인스타에 올린 카드 → 우리 앱 설치 → 그 책 본인 서재에 추가까지의 흐름.

### 5.1 외부 진입 (Deep link from 인스타 스토리)

```
[User-A] 인스타 스토리에 "책귀" 카드 + 워터마크 본다
  └─ 워터마크 영역에 "책귀에서 만들었어요" 텍스트
  └─ (스토리 링크 sticker가 있다면) 책귀 앱 deep link

[User-A] 앱이 없으면 → App Store/Play Store
  └─ 설치 후 deep link 보존 (Universal Link / App Link, `app_links` 또는 `uni_links` 패키지)

[User-A] 첫 실행 → Flow A (가입)
  └─ 가입 완료 후 deep link 처리
       └─ /book/[id]?from=story 로 이동

[User-A] 책 상세 페이지
  └─ [App] BookDetailScreen
       ├─ 책 표지 hero
       ├─ 제목·저자·출판사
       ├─ "💾 내 서재에 추가" 큰 버튼
       └─ 다른 사용자가 모은 인용구 (visibility=public만, V1.5)

[User-A] [내 서재에 추가] 탭
  └─ [API] addBookToLibrary(bookId, 'want_to_read')
  └─ [App] toast "내 서재에 추가됐어요" + tab bar의 서재로 jump
```

### 5.2 내부 진입 (앱 안에서 timeline)

```
[User-A] 홈 timeline 진입
  └─ [API] fetchTimeline()
       └─ [Supabase] SELECT * FROM quotes WHERE user_id IN following ORDER BY created_at DESC
            └─ RLS 자동 필터 (visibility 정책)
       └─ JOIN books, profiles
       └─ 20개 반환
  └─ [App] ListView.builder 렌더 (Flutter 기본 가상화 — 각 카드: 친구 + 인용구 + 책 정보)
  └─ (병렬) [App] useTimelineRealtime 활성

[User-A] 친구 "수연"의 인용구 카드 본다
  └─ 카드 하단의 책 표지 + 제목 탭
       └─ Router → /book/[bookId]
       └─ [Flow continues with 5.1's BookDetailScreen]

[User-A] 카드의 ❤️ 탭 (V1.5에서)
  └─ [API] toggleQuoteLike(quoteId)
```

### 5.3 핵심 UX 결정

- **Deep link는 V1부터 필수**: 바이럴의 핵심. Universal Link / App Link 셋업 (`app_links` 패키지 + Info.plist / AndroidManifest.xml 설정).
- **External 진입 시 책 상세를 먼저 보여줌**: 가입은 그 다음. "이 책에 관심이 있어서 왔다"는 맥락 유지.
- **"내 서재에 추가" CTA가 책 상세의 main**: 인용구 보기는 보조.
- **Realtime invalidation**: 친구가 새 인용구 올리면 timeline 즉시 업데이트.

### 5.4 Edge cases

- 비공개(private) 인용구의 카드를 외부에서 받아옴 → 책 상세는 보여주되 그 인용구는 표시 X
- 차단된 사용자의 카드 → 책 정보만 표시
- 삭제된 책의 deep link → "이 책은 더 이상 표시할 수 없어요" 화면

### 5.5 Latency targets

- Timeline 첫 페이지 로드: <800ms
- 무한 스크롤 다음 페이지: <500ms
- Deep link → 책 상세 표시: <1s (Cold start) / <300ms (Warm)

---

## 6. Flow D — 책 검색 → 서재 추가 (보조)

Flow B의 4.1에서 이미 다룸. 단독 진입은 다음:

```
[User] tab bar의 [📚 서재] 탭
  └─ [App] LibraryScreen
       ├─ 뷰 모드 토글 (격자/쌓기/책장/회전)
       └─ FAB "📕 책 추가"

[User] [책 추가] 탭
  └─ Router → /book/search (Flow B의 4.1.5+ 와 동일)

(이후 책 선택 → addBookToLibrary → 서재로 돌아옴)
```

---

## 7. Flow E — 친구 추가

```
[User] tab bar의 [👥 친구] 탭
  └─ [App] FriendsScreen
       ├─ 검색바
       ├─ "📒 카톡 친구 중 사용자" 섹션 (V1.5)
       └─ "✨ 추천" 섹션 (V2)

[User] 검색바에 이름 입력
  └─ [API] searchUsers(query)
       └─ [Supabase] SELECT FROM profiles WHERE username/display_name ILIKE
  └─ [App] 결과 리스트 (각 row: 아바타·이름·통계·팔로우 버튼)

[User] [팔로우] 버튼 탭
  └─ [API] followUser(targetUserId)
       └─ [Supabase] follows INSERT
  └─ [App] 버튼이 [팔로잉]으로 변경 (낙관적 업데이트)
  └─ [Riverpod] ref.invalidate(followsProvider(myUserId)), ref.invalidate(timelineProvider)
```

### 7.1 카톡 매칭 (V1.5)

```
[User] "📒 카톡 친구 찾기" 탭
  └─ [App] Kakao Friends API 권한 요청
       └─ 사용자 동의
  └─ Kakao Friends 목록 받음 (id 만)
  └─ [API] matchKakaoFriends(kakaoIds)
       └─ [Supabase] SELECT FROM profiles WHERE kakao_id IN (...)
  └─ [App] 매칭된 친구 표시
```

V1에서는 username 검색만. 카톡 매칭은 V1.5.

---

## 8. Flow F — 오프라인 인용구 작성 → 동기화

**시나리오**: 지하철에서 책 읽다 인용구 입력 → 신호 약함 → 나중에 자동 동기화.

### 8.1 Step-by-step

```
[User] 지하철에서 [+] 탭 → /quote/new
  └─ [App] 오프라인 감지: Connectivity().checkConnectivity() == ConnectivityResult.none

[User] 텍스트 입력·책 선택
  └─ 책 선택 시 [Repository] booksRepository.searchAladin → 네트워크 에러
       └─ [App] "오프라인 상태. 아래에 저장해서 나중에 매칭" 옵션 표시
       └─ 책 입력을 임시 텍스트로 (수동 입력 모드)

[User] [저장] 탭
  └─ [App] syncQueueNotifier.addPending({
       text, manualBookText, page, createdAt: DateTime.now()
     })
       └─ shared_preferences (또는 hive)에 영속화
  └─ [App] SnackBar "오프라인이에요. 연결되면 자동으로 저장돼요"
  └─ [App] timeline에 임시 표시 ("동기화 대기 중" 뱃지)

(시간 경과)

[User] 지상으로 나옴 → 네트워크 복구
  └─ [App] connectivity_plus stream listener: hasConnection
  └─ [App] syncQueueNotifier.processPending()
       └─ for each pending:
            ├─ [Repository] booksRepository.searchAladin(manualBookText) — 자동 매칭 시도
            ├─ 매칭 성공 → upsertBook + addToLibrary + createQuote
            └─ 매칭 실패 → 사용자에게 알림 "이 인용구는 책 정보가 필요해요"
  └─ [App] 동기화 완료된 row는 syncQueue에서 제거
  └─ [Riverpod] ref.invalidate(timelineProvider), ref.invalidate(userLibraryProvider)
```

### 8.2 핵심 UX 결정

- **오프라인 작성을 V1에 포함**: 사용자의 핵심 사용 환경(지하철)을 무시할 수 없음.
- **간단한 큐 모델**: V1은 `shared_preferences` (또는 `hive`) + 수동 sync 함수. PowerSync는 V2.
- **"동기화 대기 중" 뱃지**: 사용자가 자기 데이터의 상태를 알 수 있어야.

### 8.3 Edge cases

- 책 자동 매칭 실패 → 사용자에게 매칭 책임 이전 (notification + UI)
- 동기화 중 다시 오프라인 → 처리한 것까지만 commit, 나머지는 다음 기회
- 같은 인용구 중복 동기화 → client-side dedupe (created_at + text 해시)

---

## 9. Latency · Performance Budget

플로우별 목표:

| Action | Target | Budget |
|---|---|---|
| 앱 cold start → 첫 화면 | <2s | 1.5s 코드 + 0.5s API |
| Timeline 첫 페이지 | <800ms | 200ms 라우팅 + 600ms API |
| 책 검색 (debounced) | <500ms | 알라딘 API |
| 인용구 저장 | <300ms | Supabase INSERT |
| 카드 미리보기 렌더 | <16ms | Flutter Canvas 60fps |
| 카드 PNG export | <300ms | RepaintBoundary.toImage |
| 시스템 share sheet | <500ms | OS |

---

## 10. KPI · 플로우 매핑

`parallel-sleeping-meadow.md`의 GTM 섹션 KPI를 플로우와 연결:

| KPI | 플로우 | 측정 지점 |
|---|---|---|
| **Activation** (D7 인용구 3+) | A → B 반복 | quote 생성 이벤트 카운트 |
| **D1 Retention** | A 다음날 timeline 진입 | session 시작 이벤트 |
| **D7/D30 Retention** | B 반복 | 마지막 quote 생성 시점 |
| **Viral K-factor** | C (외부 진입 → 가입) | deep link 설치 attribution |
| **Card share rate** | B의 공유 단계 | RepaintBoundary capture → share_plus 호출 |
| **Avg quotes/WAU** | B 빈도 | quotes 테이블 집계 |

PostHog에서 추적할 이벤트:
- `auth_signed_in` (provider)
- `quote_created` (book_id, has_photo)
- `card_shared` (template, target: 'instagram'|'kakao'|'download')
- `book_added` (source: 'search'|'deep_link'|'friend_quote')
- `friend_followed` (source: 'search'|'kakao_match'|'recommendation')

---

## 11. 다음 단계

다음 차례:
- **F. 에러 처리 철학** — 본 문서의 edge case들을 체계화 (네트워크·권한·동기화 충돌)
- **G. 테스트 전략** — 플로우별 어디까지 자동 테스트
