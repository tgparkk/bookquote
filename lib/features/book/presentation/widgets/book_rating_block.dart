// 책 상세 헤더의 별점 블록 — "내 별점" 라벨 + 큰 별 5개 + "N / 5"(PR30-A),
// 친구 평균 별점 칩(PR30-C). 본체: `book_detail_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../follow/state/follow_providers.dart';
import '../../data/book_repository.dart';
import '../../state/book_providers.dart';
import 'star_rating.dart';

/// 헤더 중앙의 별점 블록 — "내 별점" 라벨 + 큰 별 5개(32pt) + "N / 5" 텍스트.
/// `myRatingProvider`를 watch하고 탭 시 `setMyRating` → invalidate. 이 책의 다른
/// 화면(서재 등)도 갱신되게 `myLibraryProvider`도 invalidate.
class BookRatingBlock extends ConsumerStatefulWidget {
  const BookRatingBlock({super.key, required this.bookId});

  final String bookId;

  @override
  ConsumerState<BookRatingBlock> createState() => _BookRatingBlockState();
}

class _BookRatingBlockState extends ConsumerState<BookRatingBlock> {
  bool _busy = false;

  Future<void> _rate(int? value) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).setMyRating(widget.bookId, value);
      if (!mounted) return;
      ref.invalidate(myRatingProvider(widget.bookId));
      ref.invalidate(myLibraryProvider);
      ref.invalidate(isInLibraryProvider(widget.bookId));
    } on BookRepositoryException catch (e) {
      showAppSnackBarOn(
        messenger,
        e.code == 'NOT_AUTHENTICATED' ? '로그인이 필요해요.' : '별점을 저장하지 못했어요.',
      );
    } catch (_) {
      showAppSnackBarOn(messenger, '별점을 저장하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(myRatingProvider(widget.bookId)).value;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('내 별점', style: textTheme.labelMedium),
        const SizedBox(height: 4),
        StarRating(
          rating: rating,
          size: 32,
          onRated: _busy ? null : _rate,
        ),
        if (rating != null) ...[
          const SizedBox(height: 2),
          Text(
            '$rating / 5',
            style: textTheme.bodySmall?.copyWith(
                color: context.colors.onSurfaceMuted), // primary500 → onSurfaceMuted
          ),
        ],
      ],
    );
  }
}

// ── PR30-C: 친구 평균 별점 칩 ─────────────────────────────────

/// 헤더 별점 블록 아래에 "친구만의 평균 ★4.2 (N=5)" 노출. N≥3 가드로 표본
/// 부족 오해 회피. 라벨에 "친구만의"를 명시해 왓챠 평균 같은 대중 평점과 혼동
/// 되지 않게 한다(매니저 모드 합의).
class FriendsAvgRatingChip extends ConsumerWidget {
  const FriendsAvgRatingChip({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendsAvgRatingProvider(bookId));
    final data = async.value;
    if (data == null || data.n < 3) return const SizedBox.shrink();
    final avg = data.avg.toStringAsFixed(1);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceCard,                    // secondary100 → surfaceCard
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: colors.border),    // primary200 → border
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: 16,
              color: colors.accentDefault,              // accent500 → accentDefault
            ),
            const SizedBox(width: 4),
            Text(
              '친구만의 평균 $avg',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.onSurfaceMuted,           // primary700 → onSurfaceMuted
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(N=${data.n})',
              style: AppTextStyles.labelSmall.copyWith(
                  color: colors.onSurfaceSubtle),       // primary500 → onSurfaceSubtle
            ),
          ],
        ),
      ),
    );
  }
}
