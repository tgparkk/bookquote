import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('친구의 새 인용구', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.s2),
            Text('아직 비어 있습니다.', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
