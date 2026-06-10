// 팔로우/팔로잉 토글 버튼 — 낙관 토글 + 언팔로우 확인 다이얼로그.
// 본체: `friend_profile_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../follow/data/follow_repository.dart';
import '../../../follow/state/follow_providers.dart';
import '../../state/friend_providers.dart';

class FollowButton extends ConsumerStatefulWidget {
  const FollowButton({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<FollowButton> {
  bool _busy = false;
  // 낙관 토글: AsyncValue를 기다리지 않고 즉시 반영. 실패 시 rollback.
  bool? _optimistic;

  Future<void> _toggle() async {
    if (_busy) return;
    final current = _optimistic ??
        (ref.read(isFollowingProvider(widget.userId)).value ?? false);
    setState(() {
      _busy = true;
      _optimistic = !current;
    });
    final repo = ref.read(followRepositoryProvider);
    final wasFollowing = current;
    try {
      if (wasFollowing) {
        final ok = await _confirmUnfollow();
        if (!ok) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _optimistic = wasFollowing;
          });
          return;
        }
        await repo.unfollow(widget.userId);
      } else {
        await repo.follow(widget.userId);
      }
      ref.invalidate(isFollowingProvider(widget.userId));
      ref.invalidate(friendFollowCountsProvider(widget.userId));
      // me_screen "내 친구 N명" / `/me/following` 목록 즉시 갱신.
      // me 화면이 마운트된 채 push → 토글 → pop 흐름에선 autoDispose가 걸리지
      // 않아 stale 카운트가 남는다(2026-05-23 버그).
      ref.invalidate(myFollowingCountProvider);
      ref.invalidate(myFollowingProvider);
      // 팔로우 토글로 친구 책·인용구 RLS 통과 여부가 바뀜 → 컨텐츠 즉시 invalidate.
      ref.invalidate(friendBooksProvider(widget.userId));
      // segment 라벨도 갱신 (팔로우 전엔 0, 팔로우 직후 정확한 카운트).
      ref.invalidate(friendProfileAggregateProvider(widget.userId));
      // (인용구는 screen state 기반이라 다음 reload 때 갱신)
    } on FollowRepositoryException catch (e) {
      if (!mounted) return;
      setState(() => _optimistic = wasFollowing); // rollback
      showAppSnackBar(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmUnfollow() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: const Text('팔로우를 끊을까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('언팔로우'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(isFollowingProvider(widget.userId));
    final isFollowing = _optimistic ?? (async.value ?? false);
    if (_busy) {
      return const SizedBox(
        width: 110,
        height: 36,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (isFollowing) {
      return OutlinedButton.icon(
        onPressed: _toggle,
        icon: const Icon(Icons.check_rounded, size: 16),
        label: const Text('팔로잉'),
        style: OutlinedButton.styleFrom(
          foregroundColor: context.colors.onSurfaceMuted,
          side: BorderSide(color: context.colors.border, width: 1.5),
          visualDensity: VisualDensity.compact,
        ),
      );
    }
    return FilledButton.icon(
      onPressed: _toggle,
      icon: const Icon(Icons.add_rounded, size: 16),
      label: const Text('팔로우'),
      style: FilledButton.styleFrom(
        backgroundColor: context.colors.accentDefault,
        foregroundColor: context.colors.accentOnAccent,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
