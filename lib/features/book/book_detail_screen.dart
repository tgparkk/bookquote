import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('책 상세')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('책 ID: $bookId', style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.s4),
            Text('제목 (Stage 1 후속)', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.s2),
            Text('저자 · 출판사', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
