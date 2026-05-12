// 책귀 — 스플래시
//
// 콜드 스타트 시 Supabase SDK가 SecureStorage에서 세션을 hydrate하는 동안
// (수십~수백 ms) `redirect`가 null session을 봐서 의도치 않게 `/auth/login`으로
// 보내는 경합을 피하기 위해, 세션이 결정될 때까지 여기서 잠깐 대기한다.
//
// 동작:
// - Supabase 미초기화면 다음 프레임에 곧장 `/auth/login`으로 이동 (테스트·키 미주입 빌드)
// - 초기화돼 있으면 `authStateProvider` 첫 이벤트 또는 500ms 안전망 중 빠른 쪽

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/supabase/supabase_init.dart';
import '../core/theme/tokens.dart';
import 'auth_state_provider.dart';
import 'deep_link_handler.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _safetyTimer;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    if (!isSupabaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
      return;
    }
    _safetyTimer = Timer(const Duration(milliseconds: 500), _resolve);
  }

  void _resolve() {
    if (_resolved || !mounted) return;
    _resolved = true;
    // deep link로 부팅됐다면(공유 카드 → `://book/:id?from=share` 등) 그 경로로 바로.
    // 미로그인이어도 `/book/:id`는 게스트 허용이라 read-only로 열린다.
    final pending = DeepLinkHandler().consumePendingRoute();
    if (pending != null) {
      context.go(pending);
      return;
    }
    final loggedIn =
        isSupabaseReady && supabase.auth.currentSession != null;
    context.go(loggedIn ? '/' : '/auth/login');
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // auth 이벤트가 안전망 타이머보다 먼저 도착하면 즉시 진행
    ref.listen(authStateProvider, (_, next) {
      next.whenData((_) => _resolve());
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.accent500),
      ),
    );
  }
}
