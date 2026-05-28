// 모바일 인앱 deep link 처리.
//
// V1에서 처리하는 link 한 종류:
//   - 인앱 라우트 — `io.github.tgparkk.bookquote://book/<id>?from=share`
//     (공유 카드 → 책 상세, K-factor). GoRouter로 라우팅한다.
//     콜드스타트 진입은 라우터가 아직 없으므로 보류했다가 스플래시가 소비한다
//     (`splash_screen.dart`의 `_resolve` → `consumePendingRoute`).
//
// OAuth(구글·카카오)는 각 SDK가 자체 채널(ASWebAuthenticationSession,
// Android Custom Tabs)로 처리하므로 여기서 가로채지 않는다. PR21 이전엔
// 매직링크 PKCE 코드 교환도 처리했으나 매직링크 자체가 제거되어 분기 삭제.
//
// 웹은 브라우저 URL이 직접 처리하므로 이 핸들러는 mobile/desktop 전용.
// `kIsWeb`이면 no-op.
//
// 같은 URI를 (단톡방을 스크롤하며 여러 번 탭하는 등) 재처리하지 않도록 세션 동안
// 본 URI를 기억한다 — deep link 무한 루프 / 중복 이동 방지.

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_init.dart';

class DeepLinkHandler {
  DeepLinkHandler._();

  static final _instance = DeepLinkHandler._();
  factory DeepLinkHandler() => _instance;

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;
  GoRouter? _router;

  /// 콜드스타트로 받았지만 라우터가 아직 없는 인앱 경로 — 스플래시가 소비.
  String? _pendingRoute;

  /// 이미 처리한 URI (무한 루프 / 중복 이동 방지).
  final Set<String> _seen = {};

  /// 한 번만 호출 (예: `main()`의 `runApp` 직전).
  Future<void> start() async {
    if (kIsWeb) return;
    if (!isSupabaseReady) return;
    if (_appLinks != null) return; // 중복 시작 방지

    _appLinks = AppLinks();

    // 콜드 스타트 — 앱이 deep link로 부팅된 케이스
    final initial = await _appLinks!.getInitialLink();
    if (initial != null) await _handle(initial, cold: true);

    // 워밍 상태에서 들어오는 후속 link
    _subscription = _appLinks!.uriLinkStream.listen(
      (uri) => _handle(uri, cold: false),
      onError: (e) => debugPrint('[deep-link] stream error: $e'),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _appLinks = null;
  }

  /// 라우터가 만들어진 직후 연결한다(`BookquoteApp`). 워밍 상태 인앱 링크를 여기로 보낸다.
  /// 콜드스타트 보류 경로는 스플래시가 [consumePendingRoute]로 가져가므로 여기서 flush하지 않는다.
  void attachRouter(GoRouter router) {
    _router = router;
  }

  /// 콜드스타트 직후 스플래시가 보류 경로를 가져갈 때 사용. 한 번 가져가면 클리어된다.
  String? consumePendingRoute() {
    final p = _pendingRoute;
    _pendingRoute = null;
    return p;
  }

  Future<void> _handle(Uri uri, {required bool cold}) async {
    if (!isSupabaseReady) return;
    if (!_seen.add(uri.toString())) return; // 이미 처리한 URI

    final route = _routeFor(uri);
    if (route == null) return; // 알 수 없는 deep link — 무시 (크래시 금지)

    final router = _router;
    if (router != null && !cold) {
      router.go(route);
    } else {
      // 콜드스타트(또는 라우터 미연결) — 보류했다가 스플래시가 소비.
      _pendingRoute = route;
    }
  }

  /// 인앱 라우트로 매핑. `io.github.tgparkk.bookquote://book/:id?from=share`는
  /// Dart URI 파서가 `host='book'`, `path='/:id'`로 쪼갠다 → `/book/:id?from=share`.
  /// 지원: `book/:id` · `u/:userId`(PR13 — 프로필 공유 invite 링크). 그 외 null.
  /// 자기 자신 프로필 진입은 router `_redirect`가 `/me`로 보냄.
  String? _routeFor(Uri uri) {
    final segs = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments.where((s) => s.isNotEmpty),
    ];
    if (segs.length < 2) return null;
    if (segs.first != 'book' && segs.first != 'u') return null;
    final path = '/${segs.join('/')}';
    return uri.hasQuery ? '$path?${uri.query}' : path;
  }
}
