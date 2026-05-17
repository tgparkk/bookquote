// 책귀 — Auth callback
//
// 매직링크 클릭으로 도달하는 화면. 웹에선 Supabase SDK가 URL의 `?code=`를
// 자동으로 감지·교환해 SIGNED_IN 이벤트를 발화하고, 라우터의 redirect가
// 그 즉시 `/`로 보내준다. 이 화면은 그 짧은 사이 로딩 인디케이터만 그린다.
//
// 안전망: 10초 안에 세션이 안 올라오면 사유 안내 + [다시 시도] 버튼으로 분기
// (PR14-F B8). 자동 navigate는 captive portal·만료 링크·지연 환경에서 사용자가
// "왜 다시 로그인 화면으로 갔는지" 모르게 만들어 신뢰 손상 → 명시적 안내 후
// 사용자가 직접 /auth/login으로 돌아가게 한다.

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
  bool _timedOut = false;

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
      if (mounted) setState(() => _timedOut = true);
    });
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: _timedOut ? _TimeoutNotice() : const _LoadingNotice(),
        ),
      ),
    );
  }
}

class _LoadingNotice extends StatelessWidget {
  const _LoadingNotice();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        CircularProgressIndicator(color: AppColors.accent500),
        SizedBox(height: AppSpacing.s4),
        Text('로그인 중…'),
      ],
    );
  }
}

class _TimeoutNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Icon(
          Icons.signal_wifi_statusbar_connected_no_internet_4_rounded,
          size: 56,
          color: AppColors.primary400,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '로그인 처리가 길어지고 있어요',
          textAlign: TextAlign.center,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '네트워크가 불안정하거나(공항 Wi-Fi 등) 링크가 만료됐을 수 있어요.\n'
          '다시 로그인을 시도해주세요.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.primary500),
        ),
        const SizedBox(height: AppSpacing.s6),
        FilledButton(
          onPressed: () => context.go('/auth/login'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent500,
            foregroundColor: Colors.white,
          ),
          child: const Text('로그인 화면으로'),
        ),
      ],
    );
  }
}
