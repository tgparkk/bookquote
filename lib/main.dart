import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';

void main() {
  runApp(const ProviderScope(child: BookquoteApp()));
}

class BookquoteApp extends StatelessWidget {
  const BookquoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '책귀',
      theme: AppTheme.light(),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('책귀'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stage 1 setup complete', style: textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'AppTheme · TextTheme · ColorScheme 적용 확인',
              style: textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s8),
            Wrap(
              spacing: AppSpacing.s3,
              runSpacing: AppSpacing.s3,
              children: [
                ElevatedButton(onPressed: () {}, child: const Text('Primary')),
                OutlinedButton(onPressed: () {}, child: const Text('Outline')),
                TextButton(onPressed: () {}, child: const Text('Text')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
