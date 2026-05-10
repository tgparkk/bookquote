// 책귀 — Auth callback
//
// 매직링크 클릭으로 도달하는 화면. 웹에선 Supabase SDK가 URL의 `?code=`를
// 자동으로 감지·교환해 SIGNED_IN 이벤트를 발화하고, 라우터의 redirect가
// 그 즉시 `/`로 보내준다. 이 화면은 그 짧은 사이 로딩 인디케이터만 그린다.
//
// 안전망: 10초 안에 세션이 안 올라오면 로그인 화면으로 되돌린다.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_init.dart';
import '../../core/theme/tokens.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() =>
      _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  Timer? _timeout;

  @override
  void initState() {
    super.initState();
    if (!isSupabaseReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/auth/login');
      });
      return;
    }
    _timeout = Timer(const Duration(seconds: 10), () {
      if (mounted) context.go('/auth/login');
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.accent500),
            SizedBox(height: AppSpacing.s4),
            Text('로그인 중…'),
          ],
        ),
      ),
    );
  }
}
