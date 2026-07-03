// 책 상세의 "이 책을 담은 친구 N명" inline chip(PR18-D → PR30-B)과 탭 시 열리는
// 친구 미니리스트 BottomSheet. 본체: `book_detail_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../follow/state/follow_providers.dart';
import '../../../profile/domain/profile.dart';

// ── PR18-D → PR30-B: "이 책을 담은 친구 N명" inline chip ──────────────

/// "이 책에서 모은 구절" 섹션 헤더의 오른쪽 inline chip. N≥1일 때만 자체 렌더.
/// 탭하면 시트 미니리스트로 친구 프로필을 보여준다 (시트는 동일 — `_FriendsWithBookSheet`).
class FriendsWithBookChip extends ConsumerWidget {
  const FriendsWithBookChip({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCount = ref.watch(friendsWithBookCountProvider(bookId));
    final n = asyncCount.value ?? 0;
    if (n <= 0) return const SizedBox.shrink();
    final colors = context.colors;
    return InkWell(
      onTap: () => _openFriendsWithBookSheet(context, bookId),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colors.chipBg,                         // secondary100 → chipBg
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: colors.border),    // primary200 → border
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              size: 14,
              color: colors.iconPrimary,               // primary600 → iconPrimary
            ),
            const SizedBox(width: 4),
            Text(
              '친구 $n명도 담음',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.onSurfaceMuted,          // primary700 → onSurfaceMuted
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: colors.onSurfaceSubtle,           // primary500 → onSurfaceSubtle
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openFriendsWithBookSheet(BuildContext context, String bookId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FriendsWithBookSheet(bookId: bookId),
  );
}

class _FriendsWithBookSheet extends ConsumerWidget {
  const _FriendsWithBookSheet({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendsWithBookProvider(bookId));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: AppSpacing.s2),
          Builder(
            builder: (context) => Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.borderStrong, // primary300 → borderStrong
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Text('이 책을 담은 친구', style: AppTextStyles.headlineMedium),
          ),
          Expanded(
            child: async.when(
              loading: () => Center(
                child: CircularProgressIndicator(
                    color: context.colors.accentDefault), // accent500 → accentDefault
              ),
              error: (_, _) => Center(
                child: Text(
                  '목록을 불러오지 못했어요.',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: context.colors.onSurfaceMuted), // primary500 → onSurfaceMuted
                ),
              ),
              data: (profiles) {
                if (profiles.isEmpty) {
                  return Center(
                    child: Text(
                      '아직 이 책을 담은 친구가 없어요',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: context.colors.onSurfaceMuted), // primary500 → onSurfaceMuted
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  itemCount: profiles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _FriendsWithBookTile(profile: profiles[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsWithBookTile extends StatelessWidget {
  const _FriendsWithBookTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName ?? '(이름 없음)';
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    final colors = context.colors;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colors.accentContainer,       // accent200 → accentContainer
        backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false)
            ? NetworkImage(profile.avatarUrl!)
            : null,
        child: (profile.avatarUrl?.isNotEmpty ?? false)
            ? null
            : Text(
                initial,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.onSurface,             // primary900 → onSurface
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      title: Text(name, style: AppTextStyles.bodyLarge),
      onTap: () {
        Navigator.of(context).pop();
        context.push('/u/${profile.id}');
      },
    );
  }
}
