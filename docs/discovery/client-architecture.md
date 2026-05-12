# 클라이언트 구조 · 상태 관리 (V1)

**버전**: 0.2 (2026-05-09 — Flutter 스택으로 재작성)
**연계**: `architecture.md` (시스템 전체) · 본 문서는 Flutter 앱 내부 설계
**스택 변경 이력**: 0.1 (RN+Expo+TS+Zustand+TanStack Query) → 0.2 (Flutter+Dart+Riverpod+go_router)

> **⚠️ V1 범위 정정 (DECISIONS 2026-05-12 — 화면 설계 Phase B 반영).** 이 문서 0.2(2026-05-09)는 follow/타임라인/Realtime을 V1처럼 적었으나 V1에는 들어가지 않는다:
> - **`features/quotes/.../timeline_provider.dart`·`timeline_realtime.dart`·`timelineProvider`·`watchTimeline()`·`features/friends/...`(followers_provider·follow_controller·follow_button)·"서버 상태 프로바이더 (StreamProvider + Realtime)" §A·"Realtime invalidation" = 전부 V1.5.** V1 코드에 넣지 말 것.
> - **V1 홈** = "내 인용 피드"(`screens/home.md`) — `myQuotesProvider` 기반(`FutureProvider`/`Notifier<AsyncValue<List<Quote>>>` + cursor-after 페이지네이션, **Realtime 없음**). follow 타임라인은 V1.5에 같은 피드에 합류. Realtime 상시 구독은 V2(DECISIONS 2026-05-10).
> - **V1 동기화 상태(5종 중 "동기화")** = 경량 로컬 아웃박스(`shared_preferences` JSON 리스트, best-effort flush — DECISIONS 2026-05-11). 완전 동기화 엔진은 V1.5.
> - 화면 단위 세부 설계(데이터 모델 포함)는 `docs/design/screens/*.md` + `docs/design/screens/README.md`가 갱신본. `quotes` 테이블 스키마는 `screens/quote-input.md §6`.

---

## 1. 핵심 결정 요약

| 결정 | 선택 | 이유 |
|---|---|---|
| 언어 | **Dart** | Flutter 강제 — 폴리글랏에게 학습 비용 며칠 |
| 상태 분류 체계 | 5종 분리 (서버·인증·UI·폼·동기화) | 각 종류는 도구가 다름 |
| 상태 관리 | **Riverpod** (`flutter_riverpod` + `riverpod_generator`) | code-gen으로 보일러플레이트 최소, async/family 지원, 컴파일 타임 안전 |
| 서버 상태 | Riverpod `FutureProvider`/`StreamProvider` (+ `riverpod_cache_manager` 또는 직접 캐싱) | 캐시·재요청·낙관적 업데이트는 NotifierProvider로 패턴화 |
| 라우팅 | **go_router** | Flutter 팀 공식, deep link·typed routes·redirect 지원 |
| 폼 상태 | `TextEditingController` + Riverpod NotifierProvider (간단한 폼) / `reactive_forms` (복잡한 폼) | 카드 편집기는 NotifierProvider 직접, 인용구 입력은 컨트롤러로 충분 |
| 모듈 구조 | features-first + layered (data·domain·application·presentation) | 백엔드 DDD 결, feature 안에서 작은 layered |
| 코드 생성 | `freezed` + `json_serializable` + `riverpod_generator` | 모델·직렬화·프로바이더 자동 생성, build_runner 1회 명령 |
| 린터 | `analysis_options.yaml` + `very_good_analysis` 또는 `flutter_lints` | 강한 정적 분석으로 안전망 |

---

## 2. 상태 5종 분류

| 종류 | 예시 | 도구 | 어디에 |
|---|---|---|---|
| **서버 상태** | 인용구·책·친구·내 서재 | Riverpod `FutureProvider`/`StreamProvider` | `features/<X>/application/*_providers.dart` |
| **인증 세션** | JWT, currentUser | Riverpod `NotifierProvider` + `flutter_secure_storage` | `features/auth/application/auth_providers.dart` |
| **전역 UI 상태** | 테마, 언어, 마지막 본 화면 | Riverpod `NotifierProvider` + `shared_preferences` | `app/ui_providers.dart` |
| **로컬 UI 상태** | 모달 열림, 선택 중인 카드 템플릿 | `setState` (StatefulWidget) | 위젯 내부 |
| **폼 상태** | 인용구 입력, 카드 편집 옵션 | `TextEditingController` 또는 NotifierProvider | 화면 내부 또는 `features/<X>/application/` |

**원칙**: 서버에서 오는 데이터는 절대 NotifierProvider에 복제하지 않는다. `FutureProvider`가 단일 진실 소스. 낙관적 업데이트는 별도 패턴(아래 7장).

---

## 3. 라이브러리 선택 근거

### Riverpod (상태 관리·DI)

**대안**: Provider, BLoC, GetX, MobX
**선택 이유**:
- 컴파일 타임 안전성 (`@riverpod` 어노테이션 + code-gen)
- async 처리가 1급 (FutureProvider·StreamProvider·AsyncValue)
- `family` 매개변수화 (예: `bookProvider(bookId)`)
- `ref.invalidate()`로 캐시 무효화 — Realtime 결합 자연스러움
- 단일 패키지로 server cache + global state + DI 모두 해결

**BLoC를 선택하지 않는 이유**: 보일러플레이트가 우리 규모에 과함. event/state 명시적 정의가 단순한 CRUD에선 노이즈.

### go_router (라우팅)

**대안**: Navigator 2.0 raw, auto_route
**선택 이유**:
- Flutter 팀 공식 패키지 (장기 안정성)
- typed routes (`go_router_builder`)
- deep link·web URL 지원 (V2 웹 진출 대비)
- `redirect` 콜백으로 auth gate 한 곳에 집중

### supabase_flutter (백엔드 SDK)

**대안**: 자체 REST 호출, postgrest 직접
**선택 이유**:
- Realtime·Auth·Storage·Postgrest 통합 클라이언트
- 커뮤니티 SDK이지만 Supabase 팀이 지원 (tier 2)
- RLS·session 자동 관리

**알아둘 점**: 일부 엣지 케이스(특히 Realtime reconnect, OAuth deep link 처리)는 직접 핸들링 필요. 이슈 발생 시 issue tracker 또는 직접 fix가 답.

### freezed + json_serializable (모델·직렬화)

- immutable data class를 한 줄로
- `copyWith`, `==`, `hashCode`, JSON 변환 자동
- Riverpod 모델·도메인 객체 표준 형태

### reactive_forms (선택, 복잡한 폼만)

V1에서는 `TextEditingController` + NotifierProvider로 충분. 카드 편집기처럼 필드가 많아지면 `reactive_forms` 도입 검토.

### 안 쓰는 것

- **GetX** — 매직 의존성 주입·라우팅이 디버깅 어려움
- **MobX** — observable 패턴 학습 곡선 + 코드 생성 충돌 위험
- **Provider 단독** — Riverpod이 Provider의 상위호환

---

## 4. 폴더 구조 (정밀화)

```
quotes_app/
├── lib/
│   ├── main.dart                       # ProviderScope, runApp
│   ├── app/
│   │   ├── router.dart                 # go_router 설정 (라우팅 = URL 구조)
│   │   ├── theme.dart                  # ThemeData (tokens.dart 기반)
│   │   ├── auth_gate.dart              # go_router redirect logic
│   │   └── ui_providers.dart           # 전역 UI Riverpod (theme, libraryViewMode)
│   │
│   ├── design/
│   │   └── tokens.dart                 # 디자인 토큰 (색·폰트·여백·그림자·radius)
│   │
│   ├── features/                       # 도메인 단위 (기능별 응집)
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   └── auth_repository.dart
│   │   │   ├── domain/
│   │   │   │   └── session.dart        # @freezed
│   │   │   ├── application/
│   │   │   │   └── auth_providers.dart # @riverpod sessionNotifier
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
│   │   │   │   └── book.dart           # @freezed
│   │   │   ├── application/
│   │   │   │   ├── book_search_provider.dart  # @riverpod (debounced)
│   │   │   │   ├── book_provider.dart
│   │   │   │   └── user_library_provider.dart
│   │   │   └── presentation/
│   │   │       ├── book_detail_screen.dart
│   │   │       ├── book_search_sheet.dart
│   │   │       ├── library_screen.dart
│   │   │       └── library_views/
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
│   │   │   │   ├── timeline_provider.dart           # @riverpod (Stream + Realtime)
│   │   │   │   ├── timeline_realtime.dart           # 채널 lifecycle
│   │   │   │   ├── create_quote_controller.dart    # NotifierProvider (낙관적 업데이트)
│   │   │   │   └── book_quotes_provider.dart
│   │   │   └── presentation/
│   │   │       ├── timeline_screen.dart
│   │   │       ├── quote_form_screen.dart
│   │   │       └── widgets/
│   │   │           └── quote_card.dart
│   │   │
│   │   ├── cards/
│   │   │   ├── data/
│   │   │   │   ├── card_repository.dart
│   │   │   │   └── color_extractor.dart # palette_generator 래퍼
│   │   │   ├── domain/
│   │   │   │   ├── card_design.dart
│   │   │   │   └── extracted_palette.dart
│   │   │   ├── application/
│   │   │   │   ├── card_editor_controller.dart # NotifierProvider (디자인 상태)
│   │   │   │   └── palette_provider.dart       # FutureProvider.family(coverUrl)
│   │   │   └── presentation/
│   │   │       ├── card_editor_screen.dart
│   │   │       ├── card_renderer.dart           # RepaintBoundary + Canvas
│   │   │       └── templates/                   # 5개
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
│   │       │   ├── followers_provider.dart
│   │       │   └── follow_controller.dart
│   │       └── presentation/
│   │           ├── friends_screen.dart
│   │           └── widgets/
│   │               └── follow_button.dart
│   │
│   ├── core/                           # 외부 시스템 어댑터 (도메인 무관)
│   │   ├── supabase_client.dart        # 클라이언트 init + Riverpod provider
│   │   ├── secure_storage.dart         # flutter_secure_storage
│   │   ├── prefs_storage.dart          # shared_preferences
│   │   ├── connectivity.dart           # connectivity_plus
│   │   ├── analytics.dart              # PostHog
│   │   └── share.dart                  # share_plus 래퍼
│   │
│   └── shared/                         # 도메인 무관 공용 위젯
│       ├── widgets/
│       │   ├── book_cover.dart         # CachedNetworkImage 래퍼
│       │   ├── avatar.dart
│       │   ├── app_button.dart
│       │   ├── app_input.dart
│       │   └── app_sheet.dart
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
└── analysis_options.yaml
```

---

## 5. 의존 방향 (가장 중요한 규칙)

```
presentation/  ──→  application/  ──→  data/  ──→  core/
        ↘                              ↗
              shared/  design/
```

**규칙**:
- `presentation/` 위젯은 같은 feature의 `application/` provider만 watch
- `application/`은 같은 feature의 `data/` 호출 가능, 다른 feature의 application은 안 됨
- `data/`는 `core/` 어댑터 호출 (Supabase, HTTP 등)
- features끼리 import 금지 (`books`가 `quotes`를 직접 부르면 안 됨) — 합치는 일은 application 레이어 위에 새 application provider로
- `core/`는 외부 라이브러리·Dart sdk만 사용 (도메인 모름)
- 이 방향이 깨지면 lint 룰로 막음 (`custom_lint` + 자체 룰 또는 `import_lint`)

**왜 이 규칙**: 백엔드의 layered architecture와 같은 원리. 한 feature 코드 읽을 때 의존성이 한 방향으로만 가서 추적 부담 적음. Riverpod provider 그래프도 자연스럽게 이 방향.

---

## 6. 상태 위치 매트릭스 (어디에 무엇)

| 상태 | 종류 | 어디에 | Provider 또는 변수 |
|---|---|---|---|
| 로그인 세션 (JWT) | 인증 | `features/auth/application` (persisted to `flutter_secure_storage`) | `sessionNotifier` |
| 현재 사용자 프로필 | 서버 | `features/auth/application` | `profileProvider(userId)` |
| Timeline 인용구 | 서버 (Stream) | `features/quotes/application` | `timelineProvider` |
| 내 서재 책 목록 | 서버 | `features/books/application` | `userLibraryProvider(userId)` |
| 책 검색 결과 (알라딘) | 서버 | `features/books/application` | `bookSearchProvider(query)` (debounced family) |
| 특정 책 인용구 | 서버 | `features/quotes/application` | `bookQuotesProvider(bookId)` |
| 친구 목록 | 서버 | `features/friends/application` | `followsProvider(userId)` |
| 카드 편집 중인 디자인 | 폼 | `features/cards/application` | `cardEditorController` (라우트 수명) |
| 인용구 입력 폼 | 폼 | 화면 내부 | `TextEditingController` |
| 모달 열림 여부 | UI 로컬 | 위젯 내부 | `setState` |
| 현재 뷰 모드 (격자/쌓기/책장/회전) | UI 전역 | `app/ui_providers.dart` | `libraryViewModeProvider` |
| 테마 (light/dark/auto) | UI 전역 | `app/ui_providers.dart` | `themeProvider` |
| 오프라인 동기화 큐 | 동기화 | `core/sync` | `syncQueueNotifier` (persisted to `shared_preferences` 또는 `hive`) |

---

## 7. 패턴 예시

### A. 서버 상태 프로바이더 (StreamProvider + Realtime)

```dart
// lib/features/quotes/application/timeline_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/quotes_repository.dart';
import '../domain/quote.dart';

part 'timeline_provider.g.dart';

@riverpod
Stream<List<Quote>> timeline(TimelineRef ref) {
  final repo = ref.watch(quotesRepositoryProvider);
  return repo.watchTimeline(); // Supabase Realtime stream
}
```

### B. 낙관적 생성 (NotifierProvider)

```dart
// lib/features/quotes/application/create_quote_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/quotes_repository.dart';
import '../domain/quote.dart';

part 'create_quote_controller.g.dart';

@riverpod
class CreateQuoteController extends _$CreateQuoteController {
  @override
  AsyncValue<Quote?> build() => const AsyncData(null);

  Future<Quote> create(CreateQuoteInput input) async {
    state = const AsyncLoading();
    try {
      final quote = await ref.read(quotesRepositoryProvider).create(input);
      // 캐시 무효화 — Realtime stream도 곧 갱신됨
      ref.invalidate(bookQuotesProvider(input.bookId));
      ref.invalidate(userLibraryProvider);
      state = AsyncData(quote);
      return quote;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
```

### C. 인증 세션 (NotifierProvider + secure storage)

```dart
// lib/features/auth/application/auth_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
class SessionNotifier extends _$SessionNotifier {
  @override
  Session? build() {
    final client = ref.watch(supabaseClientProvider);
    // Supabase가 secure storage 자동 관리 (gotrue_dart)
    ref.listen(authStateProvider, (_, asyncValue) {
      asyncValue.whenData((authState) => state = authState.session);
    });
    return client.auth.currentSession;
  }

  Future<void> signOut() async {
    await ref.read(supabaseClientProvider).auth.signOut();
    state = null;
  }
}

@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
}
```

### D. 화면 위젯 (Timeline)

```dart
// lib/features/quotes/presentation/timeline_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/timeline_provider.dart';
import 'widgets/quote_card.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineProvider);

    return Scaffold(
      body: timelineAsync.when(
        data: (quotes) => ListView.builder(
          itemCount: quotes.length,
          itemBuilder: (_, i) => QuoteCard(quote: quotes[i]),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }
}
```

### E. 카드 편집기 (NotifierProvider로 폼 상태)

```dart
// lib/features/cards/application/card_editor_controller.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/card_design.dart';
import '../domain/extracted_palette.dart';
import 'palette_provider.dart';

part 'card_editor_controller.freezed.dart';
part 'card_editor_controller.g.dart';

@freezed
class CardEditorState with _$CardEditorState {
  const factory CardEditorState({
    required String templateId,
    required CardDesign design,
    required AsyncValue<ExtractedPalette> palette,
  }) = _CardEditorState;
}

@riverpod
class CardEditorController extends _$CardEditorController {
  @override
  CardEditorState build(String quoteId) {
    final paletteAsync = ref.watch(paletteProvider(quoteId));
    return CardEditorState(
      templateId: 'minimal',
      design: CardDesign.defaults(),
      palette: paletteAsync,
    );
  }

  void selectTemplate(String id) => state = state.copyWith(templateId: id);
  void updateDesign(CardDesign Function(CardDesign) fn) =>
      state = state.copyWith(design: fn(state.design));
}
```

**왜 NotifierProvider로 카드 디자인 상태**: 카드 편집은 한 라우트에서만 일어남. 라우트 벗어나면 자동 dispose. 전역 상태가 아님. `keepAlive: false`(기본)로 둠.

---

## 8. App 시작·Provider 구성 (`main.dart`)

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'app/ui_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: QuotesApp()));
}

class QuotesApp extends ConsumerWidget {
  const QuotesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: '책귀',
      theme: theme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

**Provider 단 하나의 layer**: `ProviderScope` 한 개. 그 외 의존성은 모두 Riverpod이 hook으로 직접 접근.

---

## 9. Auth gate 패턴 (`app/router.dart`)

```dart
// lib/app/router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../features/auth/application/auth_providers.dart';

part 'router.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(sessionNotifierProvider);
      final loggedIn = session != null;
      final loggingIn = state.matchedLocation.startsWith('/auth');

      if (!loggedIn && !loggingIn) return '/auth/login';
      if (loggedIn && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const TimelineScreen()),
      GoRoute(path: '/auth/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/library', builder: (_, __) => const LibraryScreen()),
      GoRoute(path: '/friends', builder: (_, __) => const FriendsScreen()),
      GoRoute(path: '/book/:id', builder: (ctx, st) =>
          BookDetailScreen(bookId: st.pathParameters['id']!)),
      GoRoute(path: '/quote/new', builder: (_, __) => const QuoteFormScreen()),
      GoRoute(path: '/card/:quoteId', builder: (ctx, st) =>
          CardEditorScreen(quoteId: st.pathParameters['quoteId']!)),
    ],
  );
}
```

세션 없으면 `/auth/login`으로, 있으면 `/`로. 단일 진입 게이트.

---

## 10. 안티패턴 (피할 것)

| 안티패턴 | 왜 나쁜가 | 대신 |
|---|---|---|
| 서버 데이터를 NotifierProvider에 복제 | 동기화 버그·기억하기 어려움 | `FutureProvider`/`StreamProvider` 단일 소스, NotifierProvider는 액션·낙관적 업데이트 |
| `InheritedWidget` 직접 만들기 | Riverpod이 더 강력 | `Provider` 또는 `NotifierProvider` |
| BLoC + Riverpod 혼용 | 두 멘탈 모델 충돌 | Riverpod 하나로 통일 |
| 한 위젯 500줄 넘음 | 책임 과다 | `presentation/widgets/` 분리 |
| `dynamic` 타입 | 타입 안전성 무력화 | `Object?` + 타입 가드 |
| Repository 없이 화면에서 직접 supabase_flutter 호출 | 비즈니스 로직 화면에 섞임 | `data/<X>_repository.dart` 통해서만 |
| 여러 features에서 같은 supabase 호출 중복 | 유지보수 부담 | `data/<X>_repository.dart` 한곳 |
| `presentation/` 안에 도메인 로직 | UI와 비즈니스가 섞임 | application 레이어로 |
| `setState`로 서버 데이터 관리 | 캐시·재요청·에러 처리 다 직접 짜야 함 | Riverpod provider |
| build_runner 안 돌리고 손으로 `.g.dart` 작성 | 동기화 깨짐 | `dart run build_runner watch` 항상 실행 |

---

## 11. 테스트할 것의 위치 (G에서 다룰 예정)

미리 의식: 테스트가 잘 쓰이려면 코드가 테스트 가능한 구조여야 함.

- **단위 테스트 대상**: `features/<X>/data/*_repository.dart`, `core/*` 어댑터, 순수 유틸 — `test/` 아래 동일 구조
- **위젯 테스트**: `features/<X>/presentation/widgets/*`, `shared/widgets/*` — Flutter test framework + `ProviderScope.overrides`로 provider mock
- **Riverpod 통합 테스트**: NotifierProvider state 전이 테스트
- **통합/E2E**: 핵심 플로우 (인용구 추가 → 카드 → 공유) — `integration_test` 패키지 또는 `patrol`

이 폴더 구조가 테스트 분리에도 유리.

---

## 12. 다음 단계

이 클라이언트 설계를 바탕으로:
- **D. API·서버 함수 설계** — Supabase 직접 쿼리 vs RPC 정의, 어떤 쿼리 패턴
- **E. 핵심 사용자 플로우 시퀀스 정밀화** — "인용구 추가 → 카드 → 공유"의 step-by-step (이미 `flows.md`에 0.2 반영됨)
- **F. 에러 처리 철학** — 네트워크 끊김·권한 거절·동기화 충돌
- **G. 테스트 전략**

## 13. 마이그레이션 노트 (RN→Flutter)

| 이전(RN+Expo) | 현재(Flutter) | 비고 |
|---|---|---|
| TanStack Query | Riverpod FutureProvider/StreamProvider | invalidateQueries → ref.invalidate |
| Zustand | Riverpod NotifierProvider | persist → flutter_secure_storage / shared_preferences 직접 |
| React Hook Form | TextEditingController + NotifierProvider | 복잡한 폼은 reactive_forms |
| Expo Router | go_router | 파일 기반 → 코드 기반 (라우트 typed) |
| supabase-js | supabase_flutter | API 거의 동일, deep link 콜백만 다름 |
| expo-image | cached_network_image | 캐시 정책 자동 |
| react-native-skia | Flutter Canvas / CustomPainter | 별도 라이브러리 X |
| view-shot | RepaintBoundary + toImage | 1080×N 해상도 직접 지정 |
| AsyncStorage | shared_preferences (또는 hive) | KV 스토리지 |
| SecureStore | flutter_secure_storage | 동일 개념 |
| NetInfo | connectivity_plus | API 동일 |
| FlashList | ListView.builder | Flutter는 기본 ListView가 가상화 |
| WebBrowser.openAuthSession | flutter_web_auth_2 / url_launcher | OAuth 콜백 처리 |
| Share API | share_plus | OS share sheet 호출 |
