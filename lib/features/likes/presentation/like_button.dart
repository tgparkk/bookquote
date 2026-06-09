// 좋아요 버튼 (PR-LC) — 인용구·후기 공용.
//
// 자체 Consumer로 [likeCountProvider]를 watch해 카운트·본인누름을 그린다. 탭하면
// 낙관적으로 즉시 토글(_override)하고 네트워크 호출 → 성공 시 provider refresh로
// 권위 값 재동기화, 실패 시 롤백 + SnackBar.
//
// [canLike]=false면 카운트만(본인 콘텐츠). 그때 카운트 0이면 노이즈 제거 위해 숨김.
// 브랜드 정합: 누른 하트는 accentDefault(copper), 안 누름은 onSurfaceSubtle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/tokens.dart';
import '../data/like_repository.dart';
import '../state/like_providers.dart';

class LikeButton extends ConsumerStatefulWidget {
  const LikeButton({super.key, required this.target, this.canLike = true});

  final LikeTarget target;

  /// false면 탭 불가 + 카운트만 표시(본인 콘텐츠·비로그인). 카운트 0이면 숨김.
  final bool canLike;

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  /// 낙관적 표시값 — 네트워크 응답/재동기화 전까지 우선.
  LikeCount? _override;
  bool _busy = false;

  Future<void> _toggle(LikeCount current) async {
    if (_busy) return;
    final next = current.toggled;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _override = next;
      _busy = true;
    });
    try {
      await ref.read(likeRepositoryProvider).setLiked(
            kind: widget.target.kind,
            targetId: widget.target.id,
            liked: next.likedByMe,
          );
      // 권위 값으로 재동기화 — 낙관 override를 실제 값으로 대체(깜빡임 없음).
      final synced = await ref.refresh(likeCountProvider(widget.target).future);
      if (mounted) setState(() => _override = synced);
    } catch (_) {
      if (mounted) {
        setState(() => _override = null); // 롤백
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('좋아요를 처리하지 못했어요. 잠시 후 다시 시도해주세요.')),
          );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shown =
        _override ?? ref.watch(likeCountProvider(widget.target)).value ?? kEmptyLikeCount;

    // 본인 콘텐츠 등 비활성 + 0건이면 표시 안 함(노이즈 제거).
    if (!widget.canLike && shown.n == 0) return const SizedBox.shrink();

    final liked = shown.likedByMe;
    final color = liked ? colors.accentDefault : colors.onSurfaceSubtle;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          shown.n > 0 ? '${shown.n}' : '좋아요',
          style: TextStyle(
            fontFamily: AppFonts.ui,
            fontSize: AppFontSize.xs,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );

    if (!widget.canLike) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: content,
      );
    }
    return InkWell(
      onTap: _busy ? null : () => _toggle(shown),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: 4,
        ),
        child: content,
      ),
    );
  }
}
