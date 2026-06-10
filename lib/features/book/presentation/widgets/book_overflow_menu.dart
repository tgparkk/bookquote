// 책 상세의 deep link "공유받은 책" 배너와 AppBar ⋮ 메뉴(서재에서 빼기).
// 본체: `book_detail_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/auth_state_provider.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../profile/state/friend_providers.dart';
import '../../data/book_repository.dart';
import '../../state/book_providers.dart';

// ── "공유받은 책" 배너 (deep link 진입 시) ─────────────────────

class SharedBanner extends ConsumerWidget {
  const SharedBanner({super.key, required this.sender});

  /// 카드 deep link sender uid. 공개 프로필이면 발신자 이름 + "[이 사람 서재 ▸]"
  /// 버튼 노출(PR20-C). 본인이거나 비공개 프로필이면 익명 카피만.
  final String? sender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 본인 uid는 redirect로 막혔어야 하지만 deep link 위변조 대비 — 본인이면 익명 카피.
    final myUid = ref.watch(currentUserIdProvider);
    final senderUid = (sender == null || sender == myUid) ? null : sender;
    // RLS상 공개 프로필 OR 본인이면 row → 비공개면 null 자연 fallback.
    final senderProfile = senderUid == null
        ? null
        : ref.watch(friendProfileProvider(senderUid)).value;
    final senderName = senderProfile?.displayName;
    final text = senderName != null && senderName.isNotEmpty
        ? '$senderName님이 이 책의 한 줄을 보냈어요.'
        : '누군가 이 책의 한 줄을 보냈어요. 마음에 들면 서재에 담아보세요.';
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: colors.accentContainer,           // accent50 → accentContainer
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.accentBorder), // accent200 → accentBorder
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💬', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle( // const 제거 — 런타임 색
                    fontFamily: AppFonts.ui,
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w600,
                    height: AppLineHeight.normal,
                    color: colors.accentOnContainer, // accent800 → accentOnContainer
                  ),
                ),
              ),
            ],
          ),
          if (senderProfile != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/u/$senderUid'),
                icon: const Icon(Icons.chevron_right_rounded, size: 16),
                label: const Text('이 사람 서재 보기'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.accentDefault, // accent700 → accentDefault
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── AppBar ⋮ — 담긴 책이면 "서재에서 빼기" ────────────────────

class OverflowMenu extends ConsumerWidget {
  const OverflowMenu({super.key, required this.bookId});

  final String bookId;

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('서재에서 빼기'),
        content: const Text('이 책을 서재에서 뺄까요? 이 책에서 모은 인용구는 그대로 남아요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('빼기'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).removeFromLibrary(bookId);
      if (!context.mounted) return;
      ref.invalidate(isInLibraryProvider(bookId));
      ref.invalidate(myLibraryProvider);
      ref.invalidate(myRatingProvider(bookId));
      showAppSnackBarOn(messenger, '서재에서 뺐어요.');
    } catch (_) {
      if (!context.mounted) return;
      showAppSnackBarOn(messenger, '빼지 못했어요. 다시 시도해주세요.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inLibrary = ref.watch(isInLibraryProvider(bookId)).value ?? false;
    if (!inLibrary) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'remove') _confirmRemove(context, ref);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'remove', child: Text('서재에서 빼기')),
      ],
    );
  }
}
