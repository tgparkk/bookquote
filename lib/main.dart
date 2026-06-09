import 'dart:async' show unawaited;
import 'dart:ui' show PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/deep_link_handler.dart';
import 'app/router.dart';
import 'core/config/env.dart';
import 'core/supabase/supabase_init.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
import 'app/auth_state_provider.dart';
import 'features/book/data/book_repository.dart';
import 'features/notifications/data/push_service.dart';
import 'features/quote/data/quote_repository.dart';
import 'features/widget/home_widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 웹에서 URL이 `localhost:8080/...`처럼 보이게 (#/ 해시 전략 X).
  usePathUrlStrategy();
  // Firebase Crashlytics — 출시 후 크래시 가시성. 웹은 Crashlytics 미지원이라
  // 모바일에서만 초기화. debug 빌드는 수집을 꺼 대시보드 노이즈를 막는다.
  if (!kIsWeb) {
    await Firebase.initializeApp();
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    // PR-PB: FCM 백그라운드/종료 상태 메시지 핸들러 등록(반드시 top-level 함수).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await initSupabase();
  // PR21: 카카오 SDK 초기화 — 네이티브 앱 키 없으면 건너뜀(빌드는 통과,
  // 카카오 버튼은 disabled 상태로 노출).
  if (Env.isKakaoConfigured) {
    KakaoSdk.init(nativeAppKey: Env.kakaoNativeAppKey);
  }
  // 인앱 deep link(`io.github.tgparkk.bookquote://book/:id`) 처리.
  // 웹은 SDK가 URL을 자동 감지하므로 핸들러는 no-op.
  await DeepLinkHandler().start();
  // DM-C: 저장된 테마 모드(시스템/라이트/다크)를 읽어 첫 프레임부터 적용 — 깜빡임 방지.
  final prefs = await SharedPreferences.getInstance();
  final initialThemeMode =
      themeModeFromString(prefs.getString(themeModePrefsKey));
  runApp(ProviderScope(
    overrides: [initialThemeModeProvider.overrideWithValue(initialThemeMode)],
    child: const BookquoteApp(),
  ));
}

class BookquoteApp extends ConsumerStatefulWidget {
  const BookquoteApp({super.key});

  @override
  ConsumerState<BookquoteApp> createState() => _BookquoteAppState();
}

class _BookquoteAppState extends ConsumerState<BookquoteApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final router = ref.read(routerProvider);
    // deep link 핸들러가 인앱 라우트(`://book/:id?from=share` 등)를 GoRouter로
    // 보낼 수 있게 연결한다. 콜드스타트 진입은 스플래시가 보류 경로를 소비.
    DeepLinkHandler().attachRouter(router);
    // HW-B: 위젯 탭 → GoRouter 라우팅 연결 + 진입 시 최신 데이터 푸시.
    HomeWidgetService.instance.initInteractivity(router);
    _refreshHomeWidget();
    // PR-PB: FCM — 라우터 연결 후 로그인 상태면 토큰 등록 시작(콜드스타트 로그인).
    // 이후 로그인/로그아웃 전환은 build의 ref.listen이 처리.
    PushService.instance.attachRouter(router);
    PushService.instance.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // HW-B: 포그라운드 복귀 시 위젯 갱신 — 일일 글귀 회전의 실효 트리거.
    if (state == AppLifecycleState.resumed) _refreshHomeWidget();
  }

  /// HW-B: 현재 읽는 책 + 그 책 글귀(잠금 제외)를 위젯에 푸시. 비로그인·미초기화·
  /// 플러그인 미지원은 조용히 무시.
  void _refreshHomeWidget() {
    if (!isSupabaseReady) return;
    try {
      unawaited(refreshHomeWidget(
        bookRepo: ref.read(bookRepositoryProvider),
        quoteRepo: ref.read(quoteRepositoryProvider),
      ));
    } catch (_) {
      // provider 구성 실패 등 — 위젯은 직전 데이터 유지.
    }
  }

  @override
  Widget build(BuildContext context) {
    // PR-PB: 로그인 시 FCM 토큰 등록 시작, 로그아웃 시 이 기기 토큰 삭제.
    ref.listen(currentUserIdProvider, (prev, next) {
      if (next != null) {
        PushService.instance.start();
      } else if (prev != null) {
        PushService.instance.stop();
      }
    });
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: '책글귀',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // DM-C: 앱 내 선택(시스템/라이트/다크) 영속값을 따른다. 설정 → 화면 테마.
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
