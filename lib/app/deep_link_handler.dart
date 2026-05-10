// 모바일 deep link 처리.
//
// 매직링크 / OAuth 콜백이 `io.github.tgparkk.bookquote://auth/callback?code=...`
// 형태로 OS를 거쳐 우리 앱으로 들어온다. app_links 패키지가 그 URI 스트림을
// 노출하면 Supabase SDK의 `getSessionFromUrl`로 넘겨 PKCE 코드를 교환한다.
//
// 웹은 `Supabase.initialize` 시점의 `detectSessionInUri`가 자동 처리하므로
// 이 핸들러는 mobile/desktop 전용. `kIsWeb`이면 no-op.

import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

import '../core/supabase/supabase_init.dart';

class DeepLinkHandler {
  DeepLinkHandler._();

  static final _instance = DeepLinkHandler._();
  factory DeepLinkHandler() => _instance;

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _subscription;

  /// 한 번만 호출 (예: `main()`의 `runApp` 직전).
  Future<void> start() async {
    if (kIsWeb) return;
    if (!isSupabaseReady) return;
    if (_appLinks != null) return; // 중복 시작 방지

    _appLinks = AppLinks();

    // 콜드 스타트 시 앱이 deep link로 부팅된 케이스
    final initial = await _appLinks!.getInitialLink();
    if (initial != null) await _handle(initial);

    // 워밍 상태에서 들어오는 후속 link
    _subscription = _appLinks!.uriLinkStream.listen(
      _handle,
      onError: (e) => debugPrint('[deep-link] stream error: $e'),
    );
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    _appLinks = null;
  }

  Future<void> _handle(Uri uri) async {
    if (!isSupabaseReady) return;
    // 콜백이 아닌 deep link는 무시 (라우팅이 처리)
    if (!uri.path.startsWith('/auth/callback') &&
        uri.host != 'auth' &&
        !uri.toString().contains('code=')) {
      return;
    }
    try {
      await supabase.auth.getSessionFromUrl(uri);
    } catch (e) {
      debugPrint('[deep-link] getSessionFromUrl failed: $e');
    }
  }
}
