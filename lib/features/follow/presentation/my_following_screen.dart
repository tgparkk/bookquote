// 내 팔로잉 명단 — `/me/following` (V1.0).
//
// 내가 팔로우한 사람들의 로스터. PR18-B/C로 팔로우 자체는 가능했지만 "내가
// 팔로우한 사람"을 다시 모아 볼 화면이 없어 매번 이름을 재검색해야 했다
// (2026-05-21 디자이너·기획 매니저 회의에서 식별한 핵심 미완성 1건).
// 진입: 내정보 "친구" 섹션 → "내 친구 N명" 타일. 항목 탭 → `/u/:userId`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../profile/domain/profile.dart';
import '../state/follow_providers.dart';

class MyFollowingScreen extends ConsumerWidget {
  const MyFollowingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myFollowingProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('내 친구')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myFollowingProvider),
          child: async.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.accent500),
            ),
            error: (_, _) => _ErrorView(
              onRetry: () => ref.invalidate(myFollowingProvider),
            ),
            data: (profiles) => profiles.isEmpty
                ? const _EmptyView()
                : _FollowingList(profiles: profiles),
          ),
        ),
      ),
    );
  }
}

class _FollowingList extends StatelessWidget {
  const _FollowingList({required this.profiles});

  final List<Profile> profiles;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
      itemCount: profiles.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _FollowingTile(profile: profiles[i]),
    );
  }
}

class _FollowingTile extends StatelessWidget {
  const _FollowingTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName ?? '(이름 없음)';
    final hasAvatar = profile.avatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return ListTile(
      onTap: () => context.push('/u/${profile.id}'),
      leading: CircleAvatar(
        backgroundColor: AppColors.accent200,
        backgroundImage: hasAvatar ? NetworkImage(profile.avatarUrl!) : null,
        child: hasAvatar
            ? null
            : Text(
                initial,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary900,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      title: Text(name, style: AppTextStyles.bodyLarge),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.primary300,
        size: 20,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator 아래라 스크롤 가능해야 pull 동작 — ListView로 감싼다.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s16,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      children: [
        const Icon(
          Icons.group_outlined,
          size: 48,
          color: AppColors.primary300,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '아직 팔로우한 사람이 없어요',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '친구를 찾아 서재를 구경해 보세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary500),
        ),
        const SizedBox(height: AppSpacing.s6),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/me/friend-search'),
            icon: const Icon(Icons.person_search_outlined, size: 18),
            label: const Text('친구 찾기'),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s8),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Text(
          '목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s3),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ),
      ],
    );
  }
}
