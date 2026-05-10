import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String _redirectUrl() {
    if (kIsWeb) return '${Uri.base.origin}/auth/callback';
    return 'io.github.tgparkk.bookquote://auth/callback';
  }

  Future<void> _sendLink() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final email = _emailController.text.trim();

    await ref.read(authControllerProvider.notifier).sendMagicLink(
          email: email,
          redirectTo: _redirectUrl(),
        );

    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    state.when(
      data: (_) {
        setState(() => _linkSent = true);
      },
      loading: () {},
      error: (e, _) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
      },
    );
  }

  Future<void> _signInKakao() async {
    await ref.read(authControllerProvider.notifier).signInWithKakao(
          redirectTo: _redirectUrl(),
        );

    final state = ref.read(authControllerProvider);
    if (!mounted) return;
    state.whenOrNull(
      error: (e, _) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(authErrorMessage(e))));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: _linkSent
              ? _SentNotice(email: _emailController.text.trim())
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('책귀에 오신 걸 환영합니다',
                          style: textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        '이메일을 입력하면 로그인 링크를 보내드려요. 비밀번호 없이 한 번에.',
                        style: textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: '이메일',
                          hintText: 'you@example.com',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.go,
                        enabled: !isLoading,
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          if (value.isEmpty) return '이메일을 입력해주세요.';
                          if (!value.contains('@') || !value.contains('.')) {
                            return '올바른 이메일 주소를 입력해주세요.';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _sendLink(),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      ElevatedButton.icon(
                        onPressed: isLoading ? null : _sendLink,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondary50,
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: Text(isLoading ? '전송 중…' : '이메일로 시작'),
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.s3),
                            child: Text('또는'),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      OutlinedButton.icon(
                        onPressed: isLoading ? null : _signInKakao,
                        icon: const Icon(Icons.chat_bubble),
                        label: const Text('카카오로 시작'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _SentNotice extends StatelessWidget {
  const _SentNotice({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 48, color: AppColors.accent500),
        const SizedBox(height: AppSpacing.s4),
        Text('이메일을 보냈어요', style: textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '$email로 보낸 링크를 클릭해 로그인하세요.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '메일이 안 보이면 스팸함도 확인해주세요. 몇 분 안에 도착해요.',
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
