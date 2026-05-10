import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app/router.dart';
import 'core/supabase/supabase_init.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 웹에서 URL이 `localhost:8080/auth/callback`처럼 보이게 (#/ 해시 전략 X).
  // 매직링크 redirect URL과 정확히 일치해야 SDK·라우터 둘 다 안 깨진다.
  usePathUrlStrategy();
  await initSupabase();
  runApp(const ProviderScope(child: BookquoteApp()));
}

class BookquoteApp extends ConsumerWidget {
  const BookquoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: '책귀',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
