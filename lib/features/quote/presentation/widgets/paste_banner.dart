// 인용구 입력 화면의 클립보드 붙여넣기 제안 배너.
// 본체: `quote_input_screen.dart`.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';

class PasteBanner extends StatelessWidget {
  const PasteBanner({super.key, required this.onPaste, required this.onDismiss});

  final VoidCallback onPaste;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return Material(
      // 붙여넣기 배너 배경: surfaceCard 토큰(라이트=secondary300, 다크=primary700)
      color: colors.surfaceCard,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s3, AppSpacing.s2, AppSpacing.s2, AppSpacing.s2),
        child: Row(
          children: [
            Icon(Icons.content_paste, size: 18, color: colors.iconMuted),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                '클립보드에 텍스트가 있어요',
                style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
              ),
            ),
            TextButton(onPressed: onPaste, child: const Text('붙여넣기')),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: '닫기',
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
