// 친구 프로필 AppBar의 신고·차단 오버플로 메뉴.
// 본체: `friend_profile_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../moderation/data/moderation_repository.dart';
import '../../../moderation/presentation/report_dialog.dart';

// ─── 신고·차단 메뉴 (PR25) ──────────────────────────────────

class ProfileOverflowMenu extends ConsumerWidget {
  const ProfileOverflowMenu({
    super.key,
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String? displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = (displayName == null || displayName!.isEmpty)
        ? '이 사용자'
        : displayName!;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (v) {
        switch (v) {
          case 'report':
            showReportDialog(
              context,
              reportedUserId: userId,
              targetLabel: '$name님',
            );
          case 'block':
            _confirmAndBlock(context, ref, name);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'report', child: Text('신고하기')),
        PopupMenuItem(value: 'block', child: Text('차단하기')),
      ],
    );
  }

  Future<void> _confirmAndBlock(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name님을 차단할까요?'),
        content: const Text(
          '서로의 인용구와 프로필이 더 이상 보이지 않고, 맺어진 팔로우도 해제돼요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '차단',
              style: TextStyle(color: AppColors.semanticError),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(moderationRepositoryProvider).block(userId);
      if (!context.mounted) return;
      // 차단한 사용자는 RLS상 더 이상 조회 불가 — 화면을 닫는다.
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/');
      }
      showAppSnackBarOn(messenger, '$name님을 차단했어요.');
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBarOn(messenger, '차단하지 못했어요. 잠시 후 다시 시도해주세요.');
    }
  }
}
