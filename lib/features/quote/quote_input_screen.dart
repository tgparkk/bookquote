import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class QuoteInputScreen extends StatelessWidget {
  const QuoteInputScreen({super.key, this.bookId});

  final String? bookId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('인용구 추가')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (bookId != null) ...[
              Text('대상 책 ID: $bookId', style: textTheme.bodySmall),
              const SizedBox(height: AppSpacing.s4),
            ],
            Text('직접 입력 / 사진 OCR (Stage 2)', style: textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
