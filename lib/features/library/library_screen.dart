import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('내 서재')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('내가 읽고 있는 책', style: textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.s2),
            Text('아직 책이 없습니다. 책을 추가해 인용구를 모아보세요.',
                style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
