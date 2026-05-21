import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'app/deep_link_handler.dart';
import 'app/router.dart';
import 'core/config/env.dart';
import 'core/supabase/supabase_init.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 웹에서 URL이 `localhost:8080/...`처럼 보이게 (#/ 해시 전략 X).
  usePathUrlStrategy();
  await initSupabase();
  // PR21: 카카오 SDK 초기화 — 네이티브 앱 키 없으면 건너뜀(빌드는 통과,
  // 카카오 버튼은 disabled 상태로 노출).
  if (Env.isKakaoConfigured) {
    KakaoSdk.init(nativeAppKey: Env.kakaoNativeAppKey);
  }
  // 인앱 deep link(`io.github.tgparkk.bookquote://book/:id`) 처리.
  // 웹은 SDK가 URL을 자동 감지하므로 핸들러는 no-op.
  await DeepLinkHandler().start();
  runApp(const ProviderScope(child: BookquoteApp()));
}

class BookquoteApp extends ConsumerStatefulWidget {
  const BookquoteApp({super.key});

  @override
  ConsumerState<BookquoteApp> createState() => _BookquoteAppState();
}

class _BookquoteAppState extends ConsumerState<BookquoteApp> {
  @override
  void initState() {
    super.initState();
    // deep link 핸들러가 인앱 라우트(`://book/:id?from=share` 등)를 GoRouter로
    // 보낼 수 있게 연결한다. 콜드스타트 진입은 스플래시가 보류 경로를 소비.
    DeepLinkHandler().attachRouter(ref.read(routerProvider));
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '책귀',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
