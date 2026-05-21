// 책귀 — 로그인 화면 (PR21 OAuth 전용)
//
// V1 매직링크 제거 이후 진입점은 구글·카카오 두 OAuth. 환경 키가 없으면
// 해당 버튼은 disabled로 노출돼 본인 디버그 환경에서도 즉시 원인 파악 가능.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/theme/tokens.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading;

    Future<void> handle(Future<void> Function() action) async {
      await action();
      if (!context.mounted) return;
      final state = ref.read(authControllerProvider);
      state.when(
        data: (_) {},
        loading: () {},
        error: (e, _) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('책귀에 오신 걸 환영합니다', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.s2),
              Text(
                '구글 또는 카카오 계정으로 1초 만에 시작하세요.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.s8),
              _GoogleButton(
                enabled: Env.isGoogleConfigured && !isLoading,
                onTap: () => handle(
                  () => ref
                      .read(authControllerProvider.notifier)
                      .signInWithGoogle(),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
              _KakaoButton(
                enabled: Env.isKakaoConfigured && !isLoading,
                onTap: () => handle(
                  () => ref
                      .read(authControllerProvider.notifier)
                      .signInWithKakao(),
                ),
              ),
              if (isLoading) ...[
                const SizedBox(height: AppSpacing.s6),
                const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.accent500,
                    ),
                  ),
                ),
              ],
              if (!Env.isGoogleConfigured && !Env.isKakaoConfigured) ...[
                const SizedBox(height: AppSpacing.s6),
                Text(
                  '로그인 키가 설정되지 않았습니다.\n'
                  '`flutter run --dart-define-from-file=.env.json`로 실행해 주세요.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.primary500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.account_circle_outlined, size: 22),
        label: const Text('구글로 시작'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary800,
          side: const BorderSide(color: AppColors.primary200),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _KakaoButton extends StatelessWidget {
  const _KakaoButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  /// 카카오 브랜드 가이드라인 — 노란색 #FEE500 + 검정 텍스트.
  static const Color _kakaoYellow = Color(0xFFFEE500);
  static const Color _kakaoLabel = Color(0xFF000000);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        onPressed: enabled ? onTap : null,
        icon: const Icon(Icons.chat_bubble_rounded, size: 20),
        label: const Text('카카오로 시작'),
        style: FilledButton.styleFrom(
          backgroundColor: _kakaoYellow,
          foregroundColor: _kakaoLabel,
          disabledBackgroundColor: _kakaoYellow.withValues(alpha: 0.4),
          disabledForegroundColor: _kakaoLabel.withValues(alpha: 0.5),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
