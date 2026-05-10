import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('내 정보')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s6),
        children: [
          Text('계정', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s2),
          Text('Stage 1 후속 작업에서 표시 예정', style: textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.s8),
          Text('친구', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.s2),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_search),
            title: const Text('친구 찾기'),
            onTap: () {}, // Stage 4
          ),
        ],
      ),
    );
  }
}
