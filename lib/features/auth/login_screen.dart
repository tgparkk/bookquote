// 책귀 — 로그인 화면 (PR21 OAuth)
//
// V1 매직링크 제거 이후 진입점은 OAuth. V1.0은 구글 단독 출시 — 카카오는
// 이메일 동의항목 검수(앱스토어 URL 필요 → 출시 후 가능)를 마친 뒤 V1.0.x에서
// 재노출한다. `_kakaoLoginEnabled`만 true로 되돌리면 버튼이 다시 나온다.
// 카카오 OAuth 코드·콘솔 설정·키는 그대로 유지된다.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/env.dart';
import '../../core/theme/tokens.dart';
import 'auth_controller.dart';

/// V1.0 카카오 보류 게이트 — `true`로 되돌리면 카카오 버튼이 다시 노출된다.
/// (V1.0.x: 카카오 이메일 동의항목 검수 완료 후 재활성화 예정.)
final bool _kakaoLoginEnabled = false;

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
              Text('책글귀에 오신 걸 환영합니다', style: textTheme.headlineMedium),
              const SizedBox(height: AppSpacing.s2),
              Text(
                _kakaoLoginEnabled
                    ? '구글 또는 카카오 계정으로 1초 만에 시작하세요.'
                    : '구글 계정으로 1초 만에 시작하세요.',
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
              if (_kakaoLoginEnabled) ...[
                const SizedBox(height: AppSpacing.s3),
                _KakaoButton(
                  enabled: Env.isKakaoConfigured && !isLoading,
                  onTap: () => handle(
                    () => ref
                        .read(authControllerProvider.notifier)
                        .signInWithKakao(),
                  ),
                ),
              ],
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
              if (!Env.isGoogleConfigured &&
                  (!_kakaoLoginEnabled || !Env.isKakaoConfigured)) ...[
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
