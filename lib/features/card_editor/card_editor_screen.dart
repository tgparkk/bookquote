import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class CardEditorScreen extends StatelessWidget {
  const CardEditorScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('카드 편집기')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('인용구 ID: $quoteId', style: textTheme.bodySmall),
            const SizedBox(height: AppSpacing.s4),
            Text('템플릿 5종 + 색·폰트 미세 조정 (Stage 3)',
                style: textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}
