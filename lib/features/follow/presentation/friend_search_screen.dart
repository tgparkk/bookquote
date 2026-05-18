// 친구 찾기 화면 — `/me/friend-search` (PR18-B).
//
// `display_name` ilike 검색. RLS + 클라 단 `is_library_public=true` 이중 방어
// (DECISIONS 2026-05-18 P0)로 비공개 프로필·본인 자기는 결과 0 row. 검색 결과
// ListTile에 인라인 [팔로우]/[팔로잉] 토글. 친구 프로필 진입(`/u/:userId`)은
// PR18-C에서 본격 — 본 화면은 팔로우 토글까지만.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../profile/domain/profile.dart';
import '../data/follow_repository.dart';
import '../state/follow_providers.dart';

class FriendSearchScreen extends ConsumerStatefulWidget {
  const FriendSearchScreen({super.key});

  @override
  ConsumerState<FriendSearchScreen> createState() =>
      _FriendSearchScreenState();
}

class _FriendSearchScreenState extends ConsumerState<FriendSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('친구 찾기')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: TextField(
                controller: _controller,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  hintText: '이름으로 찾기',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.search,
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.isEmpty) return const _EmptyHint();
    final result = ref.watch(friendSearchProvider(_query));
    return result.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const _ErrorView(),
      data: (profiles) {
        if (profiles.isEmpty) return _ZeroResult(query: _query);
        return ListView.separated(
          itemCount: profiles.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _ResultTile(profile: profiles[i]),
        );
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.person_search_outlined,
              size: 56,
              color: AppColors.primary400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '이름으로 친구를 찾아보세요',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '카드를 받았다면 발신자 이름을 검색해보세요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZeroResult extends StatelessWidget {
  const _ZeroResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              size: 56,
              color: AppColors.primary400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '"$query"을 찾지 못했어요',
              style: AppTextStyles.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '이름이 정확한지 확인하거나,\n친구가 공개 설정을 켰는지 확인해주세요.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '검색 중 오류가 발생했어요.',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary500),
      ),
    );
  }
}

class _ResultTile extends ConsumerStatefulWidget {
  const _ResultTile({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_ResultTile> createState() => _ResultTileState();
}

class _ResultTileState extends ConsumerState<_ResultTile> {
  bool _busy = false;

  Future<void> _toggle(bool currentlyFollowing) async {
    if (_busy) return;
    setState(() => _busy = true);
    final repo = ref.read(followRepositoryProvider);
    try {
      if (currentlyFollowing) {
        await repo.unfollow(widget.profile.id);
      } else {
        await repo.follow(widget.profile.id);
      }
      ref.invalidate(isFollowingProvider(widget.profile.id));
    } on FollowRepositoryException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final followingAsync = ref.watch(isFollowingProvider(p.id));
    final isFollowing = followingAsync.value ?? false;
    final initial = (p.displayName?.isNotEmpty ?? false)
        ? String.fromCharCode(p.displayName!.runes.first)
        : '?';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.accent200,
        child: Text(
          initial,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.primary900,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Text(
        p.displayName ?? '(이름 없음)',
        style: AppTextStyles.bodyLarge,
      ),
      trailing: _busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isFollowing
              ? OutlinedButton.icon(
                  onPressed: () => _toggle(true),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('팔로잉'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary700,
                    visualDensity: VisualDensity.compact,
                  ),
                )
              : FilledButton.icon(
                  onPressed: () => _toggle(false),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('팔로우'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent500,
                    foregroundColor: AppColors.secondary50,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
    );
  }
}
