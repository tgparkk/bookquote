// 팔로워/팔로잉 목록 BottomSheet — 헤더의 카운트 탭에서 진입, 행을 탭하면
// 해당 프로필로 이동. 본체: `friend_profile_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/profile.dart';
import '../../state/friend_providers.dart';

Future<void> openFollowSheet(
  BuildContext context,
  String userId,
  FollowListKind kind,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FollowersSheet(userId: userId, kind: kind),
  );
}

class _FollowersSheet extends ConsumerWidget {
  const _FollowersSheet({required this.userId, required this.kind});

  final String userId;
  final FollowListKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(
      friendFollowListProvider((userId: userId, kind: kind)),
    );
    final title = kind == FollowListKind.followers ? '팔로워' : '팔로잉';
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: AppSpacing.s2),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Text(title, style: AppTextStyles.headlineMedium),
          ),
          Expanded(
            child: async.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: context.colors.accentDefault),
              ),
              error: (_, _) => Center(
                child: Text(
                  '목록을 불러오지 못했어요.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: context.colors.onSurfaceSubtle),
                ),
              ),
              data: (profiles) {
                if (profiles.isEmpty) {
                  return Center(
                    child: Text(
                      kind == FollowListKind.followers
                          ? '아직 팔로워가 없어요'
                          : '팔로우 중인 사람이 없어요',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: context.colors.onSurfaceSubtle),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  itemCount: profiles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) => _FollowSheetTile(profile: profiles[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowSheetTile extends StatelessWidget {
  const _FollowSheetTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName ?? '(이름 없음)';
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.colors.accentContainer,
        backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false)
            ? NetworkImage(profile.avatarUrl!)
            : null,
        child: (profile.avatarUrl?.isNotEmpty ?? false)
            ? null
            : Text(
                initial,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.colors.accentOnContainer,
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
