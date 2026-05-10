import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('로그인')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('책귀에 오신 걸 환영합니다', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.s2),
            Text('이메일 또는 카카오로 1초 만에 시작하기', style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.s8),
            ElevatedButton(
              onPressed: null,
              child: const Text('로그인 (Stage 1 후속 작업)'),
            ),
          ],
        ),
      ),
    );
  }
}
