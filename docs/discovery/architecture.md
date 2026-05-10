# 시스템 아키텍처 — 책 인용구 공유 앱 (V1)

**버전**: 0.2 (2026-05-09 — 클라이언트 스택 Flutter로 변경)
**근거**: 플랜 `parallel-sleeping-meadow.md` + 데이터 아키텍처 메모리
**스택 변경 이력**: 0.1 RN+Expo+Skia → 0.2 Flutter (Skia 엔진 내장, 전 화면 픽셀 통제)

---

## 1. Birds-eye View (한 장 요약)

```
┌─────────────────────────────────────────────────────────────────┐
│                     Flutter App (iOS / Android)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │ UI (Screens) │  │ Domain Logic │  │ Local Cache  │         │
│  │  go_router   │  │   Riverpod   │  │ shared_prefs │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│           │                │                  │                  │
│           └────────────────┴──────────────────┘                  │
│                            │ supabase_flutter                    │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                       HTTPS │ WSS (Realtime)
                             │
┌────────────────────────────┼─────────────────────────────────────┐
│                          Supabase                                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐       │
│  │   Auth   │  │ Postgres │  │ Storage  │  │ Realtime │       │
│  │ Kakao·이메일│  │  + RLS   │  │ (사진 첨부)│  │ Pub/Sub  │       │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘       │
│        Edge Functions (V1.5+ 선택)                               │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ↓
┌────────────────────────────┴─────────────────────────────────────┐
│                       External Services                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │ 알라딘 OpenAPI │  │ 네이버 책 API  │  │ Aladin Image CDN    │  │
│  │ (책 검색·메타)  │  │ (백업 검색)    │  │ (표지 이미지 직접 로딩)│  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│  ┌──────────────┐                                                │
│  │ Kakao OAuth  │                                                │
│  └──────────────┘                                                │
└──────────────────────────────────────────────────────────────────┘
```

**핵심 포인트**:
- 자체 백엔드 서버 없음 — Supabase가 백엔드 역할
- 책 검색은 클라이언트가 알라딘 API 직접 호출 (또는 Edge Function 경유)
- 이미지(표지)는 알라딘 CDN에서 직접 로딩 — 우리 서버 안 거침
- 권한은 RLS로 DB 레벨에서 처리

---

## 2. 컴포넌트 책임 분리

| 컴포넌트 | 책임 | Why |
|---|---|---|
| **Flutter App / UI** | 화면 렌더링, 사용자 입력 처리 | 모바일 사용자 접점 |
| **Flutter App / Domain Logic** | 비즈니스 룰 (카드 디자인 합성, OCR 결과 정리, 인용구 검증) | 클라이언트에서 처리 가능한 모든 로직 |
| **Flutter App / Local Cache** | 오프라인 인용구 임시 저장, 동기화 큐, 책 메타데이터 캐시 | 오프라인 작성·조회 지원 |
| **Supabase Auth** | 로그인·세션·OAuth | 직접 구현 부담 회피 |
| **Supabase Postgres** | 모든 데이터 저장, RLS 권한 | 단일 진실 소스 |
| **Supabase Storage** | 사용자 첨부 사진 (선택) | 이미지 호스팅 |
| **Supabase Realtime** | timeline 실시간 업데이트, 친구 활동 알림 | 푸시 없이도 즉시성 확보 |
| **Edge Functions (V1.5+)** | 외부 API proxy, 비밀 키 처리, 무거운 변환 | 클라이언트가 못 하는 일만 |
| **알라딘 OpenAPI** | 한국 도서 메타데이터·검색 | 한국 시장 표준 |
| **네이버 책 API** | 알라딘 누락 도서 보완 | 검색 정확도 보강 |
| **Kakao OAuth** | 한국 사용자 가장 자연스러운 로그인 | 카톡 연락처 친구 매칭 가능 |

---

## 3. 인증 플로우 (카카오 로그인)

```
[User Tap "카카오로 시작"]
        │
        ↓
[Flutter App] — open Kakao OAuth (flutter_web_auth_2 / url_launcher)
        │
        ↓
[Kakao] ← user authorizes
        │
        ↓ (redirect with code)
[Flutter App] receives auth code
        │
        ↓ POST /auth/v1/token (Supabase Auth)
[Supabase Auth]
  ├─ verify code with Kakao
  ├─ create/find user in auth.users
  ├─ insert/update profile in public.profiles
  └─ return JWT (access + refresh)
        │
        ↓
[Flutter App] stores JWT in flutter_secure_storage
        │
        ↓
[All subsequent requests] include JWT
[Supabase RLS] uses auth.uid() from JWT
```

**Why Supabase Auth Provider for Kakao**:
- Supabase가 Kakao OAuth provider 지원 (`auth.signInWithOAuth({ provider: 'kakao' })`)
- 토큰 갱신·유저 매칭을 알아서 처리
- 직접 Kakao SDK 통합보다 코드량·복잡도 1/3

---

## 4. 핵심 데이터 플로우

### A. 인용구 저장 (Write Path)

```
[User] 입력 + "저장" 탭
    │
    ↓
[App / Domain Logic]
  ├─ 인용구 텍스트 검증 (길이·금칙어)
  ├─ 책 ID 매칭 확인
  └─ visibility 결정
    │
    ↓ (Online 정상)
[supabase_flutter] insert into quotes
    │
    ↓
[Supabase Postgres]
  ├─ RLS 검증: user_id = auth.uid() ✓
  ├─ row 생성
  └─ Realtime publish to followers
    │
    ↓
[App / Local Cache] update timeline cache
[Friends' Apps] receive Realtime event → update timeline
```

### A'. 인용구 저장 (Offline)

```
[User] 입력 + "저장" 탭
    │
    ↓ (Offline 감지)
[App / Local Cache] insert into local pending_quotes
    │
    ↓ (네트워크 복구)
[App / Sync Worker]
  └─ for each pending: insert to Supabase + remove local pending
```

### B. Timeline 조회 (Read Path)

```
[User] 홈 화면 진입
    │
    ↓
[App / Domain Logic]
    │
    ↓ select * from quotes WHERE visibility AND following
[Supabase Postgres]
  └─ RLS 자동 필터링 (visibility 정책)
    │
    ↓ rows + book metadata (JOIN)
[App] render quote cards
    │
    ↓ for each card: CachedNetworkImage(imageUrl: book.cover_url)
[Aladin CDN] image bytes (cache-hit on second view)
    │
    ↓
[App / cached_network_image] disk cache (flutter_cache_manager)
```

### C. 책 검색

```
[User] "책 검색" 입력
    │
    ↓
[App / Domain Logic]
    │
    ↓ debounced query (300ms)
[Aladin OpenAPI] /search?Query=...
    │
    ↓ JSON results (title, author, isbn, cover_url)
[App] render search results
    │
    ↓ User taps a book
[App] insert into books (UPSERT by ISBN), insert into user_books
[Supabase Postgres] both rows committed
```

**Why call Aladin from client (not via Edge Function)**:
- 알라딘 API 키는 사실상 공개 가능 (rate limit이 있을 뿐 비밀 X)
- 한 단계 줄이면 latency 빠름
- 불필요한 Edge Function 비용 회피

**언제 Edge Function 경유로 바꿀까**:
- 호출 횟수 캐싱 필요 (같은 검색을 여러 사용자가 할 때)
- 결과 변환·필터링이 무거워질 때
- 키가 진짜 비밀이어야 할 때 (현재는 아님)

### D. 카드 생성·공유

```
[User] 인용구 카드 편집기
    │
    ↓
[App / Domain Logic]
  ├─ 책 표지 이미지 다운로드 (cached_network_image)
  ├─ 표지에서 dominant color 추출 (palette_generator)
  └─ 카드 디자인 적용 (template + 추출 팔레트)
    │
    ↓ User taps "공유하기"
[App / RepaintBoundary + toImage]
  └─ 카드 Widget tree → PNG 바이트 (1080×1920 또는 1080×1080)
    │
    ↓
[share_plus] OS Share Sheet — 인스타 스토리·카톡·다운로드
    │
    ↓ (병렬) Supabase에 카드 row 저장 (히스토리)
```

**카드 PNG는 우리 서버에 안 올라감** — 사용자 디바이스에서 즉시 OS share로 전달.

---

## 5. Realtime 구독 모델

```
[App on launch]
    │
    ↓
[supabase.channel('timeline')]
  .on('postgres_changes', {
    event: 'INSERT',
    table: 'quotes',
    filter: `user_id=in.(${myFollowingIds})`
  }, handleNewQuote)
  .subscribe()
```

**관리 포인트**:
- 채널은 화면 마운트 시 구독, 언마운트 시 해제
- following 목록이 바뀌면 channel 재구독
- 백그라운드 진입 시 일시 중단 (Supabase 자동 처리)

**한계**:
- WebSocket이라 모바일 백그라운드에서는 끊김 → 푸시 알림과 별도 (V2)
- 무료 티어 200 동시 접속 → DAU ~5,000까지 OK

---

## 6. 클라이언트-Supabase 경계 정의

| 항목 | 클라이언트에서 | Supabase에서 |
|---|---|---|
| 인용구 텍스트 검증 | 길이·UX-level 체크 | 진짜 검증 (CHECK 제약, RLS) |
| 권한 | UI 노출 여부만 | **실제 권한 결정 (RLS)** |
| 책 메타데이터 | 캐시·표시 | 단일 진실 (books 테이블) |
| 카드 렌더링 | 100% 클라이언트 | 저장만 (jsonb) |
| 알림·통계 집계 | X | DB 트리거 (V2) |

**원칙**: 클라이언트는 신뢰할 수 없다. 진짜 정합성·권한은 Postgres에서.

---

## 7. Edge Function 전략 (V1.5+)

V1에서는 Edge Function 안 씀. 다음 시점부터 도입 검토:

| 케이스 | 무엇 | 시점 |
|---|---|---|
| 알라딘 결과 캐싱 | 인기 검색어 결과를 Postgres에 캐시 | 호출 한도 임박 시 |
| 책 표지 색 추출 | 클라이언트 부담 줄이려 백엔드에서 미리 계산 | V1.5 |
| 비밀 키 처리 (예: 푸시) | FCM·APNs 키 보호 | 푸시 알림 도입 시 (V2) |
| 데이터 export | 사용자 요청 시 ZIP 생성 | GDPR 대응 (V1.5) |

**Why 미루는가**: 함수 = 디버깅 어려움 + 배포 1단계 추가. RLS·DB 트리거로 처리할 수 있는 건 거기서.

---

## 8. 외부 의존성에 대한 입장

V1은 외부 서비스에 적극 의존한다. 솔로 개발자에게 자체 운영의 복잡도·비용이 의존의 위험보다 훨씬 크기 때문.

- **알라딘 OpenAPI** — 한국 책 95%+ 커버. 단일 검색 소스로 출발. 누락 도서는 사용자가 ISBN 직접 등록할 수 있는 UX로 처리 (등록 자체가 안 되는 책이 있다는 사실을 디자인이 받아들임)
- **알라딘 CDN (이미지)** — `cached_network_image`(`flutter_cache_manager` 기반) 디스크 캐시가 사용자 디바이스에서 안정성 보장. 캐시에 없는 새 책은 placeholder가 그대로 노출됨 (이게 실패 상태가 아니라 정상 상태)
- **Kakao OAuth + 이메일 로그인** — 둘 다 1급 옵션. 사용자가 시작 화면에서 선택. 어느 한쪽이 더 우선인 것 아님
- **Supabase** — 99.9% SLA 받아들임. 별도 우회 경로 두지 않음. 이게 죽으면 앱 전체 기능 정지가 받아들이는 위험

---

## 9. 폴더·모듈 구조 (V1 코드 시작 시점)

```
quotes_app/
├── lib/
│   ├── main.dart                       # 앱 엔트리, ProviderScope
│   ├── app/
│   │   ├── router.dart                 # go_router 설정 (라우팅 = URL 구조)
│   │   ├── theme.dart                  # ThemeData (tokens.dart 기반)
│   │   └── auth_gate.dart              # 세션 redirect logic
│   │
│   ├── design/
│   │   └── tokens.dart                 # 디자인 토큰 (색·폰트·여백·그림자)
│   │
│   ├── features/                       # 기능 단위 (DDD-lite)
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── auth_repository.dart    # supabase_flutter calls
│   │   │   ├── domain/
│   │   │   │   └── session.dart            # 모델
│   │   │   ├── application/
│   │   │   │   └── auth_providers.dart     # Riverpod (sessionProvider)
│   │   │   └── presentation/
│   │   │       ├── login_screen.dart
│   │   │       └── widgets/
│   │   │           └── kakao_button.dart
│   │   │
│   │   ├── books/
│   │   │   ├── data/
│   │   │   │   ├── books_repository.dart   # 알라딘 + Supabase
│   │   │   │   └── aladin_client.dart      # API client
│   │   │   ├── domain/
│   │   │   │   └── book.dart
│   │   │   ├── application/
│   │   │   │   └── books_providers.dart    # bookSearchProvider 등
│   │   │   └── presentation/
│   │   │       ├── book_detail_screen.dart
│   │   │       ├── book_search_sheet.dart
│   │   │       └── library_views/          # 격자·쌓기·책장·회전
│   │   │           ├── grid_view.dart
│   │   │           ├── stack_view.dart
│   │   │           ├── shelf_view.dart
│   │   │           └── rotating_view.dart
│   │   │
│   │   ├── quotes/
│   │   │   ├── data/
│   │   │   │   └── quotes_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── quote.dart
│   │   │   ├── application/
│   │   │   │   ├── timeline_provider.dart      # StreamProvider (Realtime)
│   │   │   │   └── quote_form_controller.dart  # NotifierProvider
│   │   │   └── presentation/
│   │   │       ├── timeline_screen.dart
│   │   │       ├── quote_form_screen.dart
│   │   │       └── widgets/
│   │   │           └── quote_card.dart
│   │   │
│   │   ├── cards/
│   │   │   ├── data/
│   │   │   │   ├── color_extractor.dart        # palette_generator
│   │   │   │   └── card_repository.dart
│   │   │   ├── domain/
│   │   │   │   ├── extracted_palette.dart
│   │   │   │   └── card_design.dart
│   │   │   ├── application/
│   │   │   │   └── card_editor_controller.dart # NotifierProvider
│   │   │   └── presentation/
│   │   │       ├── card_editor_screen.dart
│   │   │       ├── card_renderer.dart          # RepaintBoundary + Canvas
│   │   │       └── templates/                  # 5개 템플릿
│   │   │           ├── minimal_template.dart
│   │   │           ├── warm_template.dart
│   │   │           ├── mono_template.dart
│   │   │           ├── cover_extract_template.dart
│   │   │           └── typography_template.dart
│   │   │
│   │   └── friends/
│   │       ├── data/
│   │       ├── domain/
│   │       ├── application/
│   │       └── presentation/
│   │
│   ├── core/                           # 인프라 어댑터 (도메인 무관)
│   │   ├── supabase_client.dart        # 클라이언트 init + DI provider
│   │   ├── secure_storage.dart         # flutter_secure_storage 어댑터
│   │   ├── prefs_storage.dart          # shared_preferences 어댑터
│   │   ├── connectivity.dart           # connectivity_plus 어댑터
│   │   ├── analytics.dart              # PostHog
│   │   └── share.dart                  # share_plus 래퍼
│   │
│   └── shared/                         # 도메인 무관 공용 위젯·유틸
│       ├── widgets/
│       │   ├── book_cover.dart         # CachedNetworkImage 래퍼
│       │   ├── avatar.dart
│       │   ├── app_button.dart
│       │   └── app_input.dart
│       └── utils/
│           ├── debouncer.dart
│           └── contrast.dart           # WCAG AA 대비 계산
│
├── assets/
│   ├── fonts/                          # Pretendard, Noto Serif KR
│   └── images/
│
├── supabase/
│   └── migrations/                     # SQL 스키마
│
├── test/
├── pubspec.yaml                        # 의존성 + assets 선언
└── analysis_options.yaml               # Dart linter 룰
```

**왜 features/ 별 분리**: 백엔드 출신이시므로 도메인 단위 분리에 친숙. 라우팅·UI(`presentation/`)와 비즈니스(`application/`·`domain/`)·인프라(`data/`·`core/`) 명확히 구분. 각 feature 안에서 layered architecture(data·domain·application·presentation) 작은 사이즈로 적용.

**Flutter 컨벤션 노트**:
- 파일·디렉터리 이름은 `snake_case` (Dart 표준)
- `lib/` 폴더가 Flutter 코드의 루트 (RN의 `src/`에 해당)
- `pubspec.yaml`이 `package.json`+`app.json` 통합 역할
- `main.dart` 한 파일이 앱 엔트리

---

## 10. V2+ 마이그레이션 경로 (지금 결정 X, 의식만)

| V1 결정 | V2 잠재 변경 | 트리거 |
|---|---|---|
| Supabase 직접 호출 | 자체 NestJS/FastAPI 백엔드 | 비즈니스 로직 복잡, 외부 통합 다양해짐 |
| 알라딘 CDN 직접 | Cloudflare Images proxy | 이미지 변환·최적화 필요, DAU 1만+ |
| RLS 전부 | 일부는 백엔드 권한 | 복잡한 권한·감사 로그 필요 |
| Realtime WebSocket | + FCM/APNs 푸시 | 백그라운드 알림 필요 |
| 단일 Region | 멀티 Region | 글로벌 진출 시 |

---

## 11. 결정 일지 (Decision Log)

| 결정 | 대안 | 왜 이걸로 |
|---|---|---|
| **Flutter** (2026-05-09 변경) | React Native + Expo + Skia | Skia가 엔진 내장 → 카드뿐 아니라 모든 화면 일관 픽셀 통제. 페르소나(특히 한지영) 시각 임계점 대응. 백엔드 폴리글랏에게 Dart 학습 비용 미미 |
| Supabase | Firebase, 자체 백엔드 | RLS·Postgres 친숙, 솔로 개발 부담 최소 |
| `supabase_flutter` (커뮤니티 SDK) | 자체 REST 호출 | Flutter 결정 결과. 90% 기능 OK, 엣지 케이스는 직접 해결 가능 |
| Riverpod (상태 관리) | Provider, BLoC, GetX | code-gen 옵션 풍부, async 처리 표준, Flutter 커뮤니티 모멘텀 |
| go_router (라우팅) | Navigator 2.0 raw, auto_route | Flutter 팀 공식, deep link·typed routes 지원 |
| `palette_generator` (색 추출) | 자체 K-means | Google 공식, Material 색 카테고리 자동 분류 |
| 알라딘 OpenAPI | 교보 (X), 네이버 단독 | 한국 시장 표준, 가장 풍부한 메타 |
| Kakao OAuth | 이메일·구글만 | 한국 사용자 등록 마찰 최소 |
| Edge Function 미사용 | 적극 사용 | 디버깅·배포 부담, 클라이언트로 충분 |
| 자체 이미지 호스팅 X | Cloudflare Images | 비용 0원 유지, 알라딘 안정성 충분 |
| 카드 jsonb 저장 | 정규화 | 디자인 옵션 변경 빈번 예상 |
| RLS-first | 백엔드 권한 검사 | DB 레벨이 더 안전·코드 적음 |

---

## 다음 단계 (이 문서 이후)

이 시스템 아키텍처를 기반으로 다음을 차례대로 정리:
- **B+C. 클라이언트 구조·상태 관리** (Riverpod 슬라이스 설계, 어디에 무엇 둘지)
- **D. API·서버 함수 설계** (RPC 정의, Edge Function 후보)
- **E. 핵심 사용자 플로우 시퀀스** (위 4번 섹션 더 정밀화)
- **F. 에러 처리 철학** (네트워크·권한·동기화 충돌)
- **G. 테스트 전략** (unit·integration·e2e 범위)
