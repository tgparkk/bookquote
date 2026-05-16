// 책귀 — 라우터 (go_router 17)
//
// 구조:
//   /splash                       cold-start 세션 hydrate 대기
//   /auth/login, /auth/callback   비로그인 허용
//   /book/:id                     게스트 미리보기 OK (top-level)
//   /quote/new                    풀스크린 (BottomNav 외부)
//   /quote/:id/card               풀스크린 카드 편집기
//   StatefulShellRoute            BottomNav 4 슬롯 (홈/서재/[+]/내정보)
//
// Auth gate: `redirect` + `GoRouterRefreshStream(supabase.auth.onAuthStateChange)`.
// `refreshListenable` 없이 `ref.read`만 쓰면 로그아웃 후에도 화면이 안 바뀌는
// 함정에 빠진다 — QA 권고에 따라 cookbook 패턴 채택.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_init.dart';
import '../features/auth/auth_callback_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/book/book_detail_screen.dart';
import '../features/card_editor/card_editor_screen.dart';
import '../features/card_editor/quick_share_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/me/me_screen.dart';
import '../features/quote/quote_input_screen.dart';
import 'auth_state_provider.dart';
import 'go_router_refresh_stream.dart';
import 'root_scaffold.dart';
import 'splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // `authStreamProvider`는 Stream 객체 자체를 노출(Provider). watch로 묶어두면
  // 이 Provider가 invalidate(예: 테스트 override)됐을 때만 라우터가 새로 만들어지고,
  // auth 이벤트가 흘러도 라우터가 리빌드되진 않는다 — 그건 refresh가 처리.
  final authStream = ref.watch(authStreamProvider);
  final refresh = GoRouterRefreshStream(authStream);

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    debugLogDiagnostics: true,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/callback',
        builder: (_, _) => const AuthCallbackScreen(),
      ),
      // 모바일 deep link `io.github.tgparkk.bookquote://auth/callback?code=...`는
      // Dart URI 파서가 host=auth, path=/callback으로 쪼갠다 → 별도 매핑.
      GoRoute(
        path: '/callback',
        builder: (_, _) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/book/:id',
        builder: (_, state) => BookDetailScreen(
          bookId: state.pathParameters['id']!,
          // 공유 카드 deep link(`?from=share`)로 들어오면 "내 서재에 담기"가 1급.
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: '/quote/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => QuoteInputScreen(
          bookId: state.uri.queryParameters['bookId'],
          // `?quoteId=...` 있으면 편집 모드(기존 quote prefill + update).
          quoteId: state.uri.queryParameters['quoteId'],
        ),
      ),
      GoRoute(
        path: '/quote/:id/card',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            CardEditorScreen(quoteId: state.pathParameters['id']!),
      ),
      // PR10.5 — 바로 공유. 홈 카드 [📤 바로 공유 ↗] 진입점.
      GoRoute(
        path: '/quote/:id/share',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            QuickShareScreen(quoteId: state.pathParameters['id']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            RootScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/library',
              builder: (_, _) => const LibraryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/me', builder: (_, _) => const MeScreen()),
          ]),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

String? _redirect(BuildContext context, GoRouterState state) {
  // splash는 자체 라우팅. 무한 루프 방지.
  final loc = state.matchedLocation;
  if (loc == '/splash') return null;

  final session = isSupabaseReady ? supabase.auth.currentSession : null;
  final loggedIn = session != null;

  // 게스트 허용: 인증 화면 + 모바일 callback path + 책 상세 미리보기
  final isAuthPath = loc.startsWith('/auth') || loc == '/callback';
  if (isAuthPath) {
    if (loggedIn) return state.uri.queryParameters['from'] ?? '/';
    return null;
  }
  if (loc.startsWith('/book/')) return null;

  // 그 외는 로그인 필수
  if (!loggedIn) {
    return '/auth/login?from=${Uri.encodeComponent(loc)}';
  }
  return null;
}
