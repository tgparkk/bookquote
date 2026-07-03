// 친구 프로필 화면 공용 에러 뷰 — 상단 정렬 Column이라 sliver 내부에서도,
// Scaffold body에서도 동일하게 쓰인다 (Center 기반 AppStatusView와 구분).

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';

class ProfileErrorView extends StatelessWidget {
  const ProfileErrorView({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Column(
        children: [
          Text(
            '불러오지 못했어요. 잠시 후 다시 시도해주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
