import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/auth_state_provider.dart';
import '../../core/theme/tokens.dart';
import '../auth/auth_controller.dart';

class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final session = ref.watch(currentSessionProvider);
    final isSigningOut = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          Text('계정', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s2),
          Text(
            session?.user.email ?? '로그인 정보 없음',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('친구', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s2),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_search),
            title: const Text('친구 찾기'),
            onTap: () {}, // Stage 4
          ),
          const SizedBox(height: AppSpacing.s8),
          OutlinedButton.icon(
            onPressed: isSigningOut
                ? null
                : () => ref.read(authControllerProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            label: Text(isSigningOut ? '로그아웃 중…' : '로그아웃'),
          ),
        ],
      ),
    );
  }
}
