import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent500,
          surface: AppColors.secondary200,
        ),
        scaffoldBackgroundColor: AppColors.secondary200,
        useMaterial3: true,
      ),
      home: const _PlaceholderHome(),
    );
  }
}

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '책귀',
              style: TextStyle(
                fontSize: AppFontSize.xxl,
                color: AppColors.primary900,
                letterSpacing: AppLetterSpacing.tight,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: AppSpacing.s4),
            Text(
              'Stage 1 setup complete',
              style: TextStyle(
                fontSize: AppFontSize.sm,
                color: AppColors.primary500,
                letterSpacing: AppLetterSpacing.wide,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
