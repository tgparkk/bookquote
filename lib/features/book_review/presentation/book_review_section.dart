// PR29-G: 책 상세의 통합 "이 책 후기" 섹션.
//
// 본인 + 타인 후기를 한 리스트로(book_reviews_by_book RPC가 본인 우선 정렬).
// 본인 카드만 "나" 라벨 + 수정/삭제. 타인 카드는 신고 메뉴.
// 본인이 안 쓴 상태면 리스트 상단 또는 빈 상태에 "후기 쓰기" CTA.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/auth_state_provider.dart';
import '../../../core/theme/tokens.dart';
import '../data/book_review_repository.dart';
import '../state/book_review_providers.dart';
import 'book_review_card.dart';
import 'book_review_input_sheet.dart';

class BookReviewSection extends ConsumerWidget {
  const BookReviewSection({super.key, required this.bookId});
  final String bookId;

  /// 책 상세에 보일 타인 후기 미리보기 cap. 넘으면 "전체 보기 ▸" 진입.
  static const _othersMaxShown = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReviews = ref.watch(publicBookReviewsByBookProvider(bookId));
    final myUid = ref.watch(currentUserIdProvider);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('이 책 후기', style: textTheme.titleMedium),
            const SizedBox(width: AppSpacing.s2),
            asyncReviews.maybeWhen(
              data: (rs) => Text(
                '${rs.length}',
                style: textTheme.titleMedium
                    ?.copyWith(color: AppColors.primary400),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        asyncReviews.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent500),
            ),
          ),
          error: (_, _) => Row(
            children: [
              Expanded(
                child: Text('후기를 불러오지 못했어요.', style: textTheme.bodySmall),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(publicBookReviewsByBookProvider(bookId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
          data: (reviews) {
            final mine =
                myUid == null ? null : _findMine(reviews, myUid);
            final others =
                myUid == null ? reviews : reviews.where((r) => r.userId != myUid).toList();
            // 본인 미작성 + 타인 0 → empty
            if (mine == null && others.isEmpty) {
              return _EmptyState(
                onWrite: myUid == null
                    ? null
                    : () => _openSheet(context, ref, ''),
              );
            }
            final shownOthers = others.take(_othersMaxShown).toList();
            final hasMore = others.length > _othersMaxShown;
            return Column(
              children: [
                // 본인 미작성 + 타인은 있음 → 상단 CTA 카드
                if (mine == null && myUid != null) ...[
                  _WriteCta(onTap: () => _openSheet(context, ref, '')),
                  const SizedBox(height: AppSpacing.s3),
                ],
                if (mine != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                    child: BookReviewCard(
                      review: mine,
                      isMine: true,
                      onEdit: () => _openSheet(context, ref, mine.text),
                      onDelete: () => _confirmDelete(context, ref),
                    ),
                  ),
                for (final r in shownOthers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                    child: BookReviewCard(review: r, isMine: false),
                  ),
                if (hasMore)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          context.push('/book/$bookId/reviews'),
                      child: Text('전체 보기 (${others.length}) ▸'),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  PublicBookReview? _findMine(List<PublicBookReview> reviews, String myUid) {
    for (final r in reviews) {
      if (r.userId == myUid) return r;
    }
    return null;
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    String initialText,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondary100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => BookReviewInputSheet(initialText: initialText),
    );
    if (saved == null) return;
    try {
      await ref
          .read(bookReviewRepositoryProvider)
          .upsertMyReview(bookId: bookId, text: saved);
      ref.invalidate(publicBookReviewsByBookProvider(bookId));
      ref.invalidate(myBookReviewProvider(bookId));
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(initialText.isEmpty ? '후기를 남겼어요' : '후기를 수정했어요'),
          ),
        );
    } on BookReviewRepositoryException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('후기 삭제'),
        content: const Text('이 책의 후기를 삭제할까요? 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              '삭제',
              style: TextStyle(color: AppColors.semanticError),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(bookReviewRepositoryProvider).deleteMyReview(bookId);
      ref.invalidate(publicBookReviewsByBookProvider(bookId));
      ref.invalidate(myBookReviewProvider(bookId));
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('후기를 삭제했어요.')));
    } on BookReviewRepositoryException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _WriteCta extends StatelessWidget {
  const _WriteCta({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(
          color: AppColors.accent50,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.accent200),
        ),
        child: Row(
          children: [
            Icon(Icons.edit_outlined, size: 18, color: AppColors.accent700),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                '이 책 후기 쓰기',
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent800,
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: AppColors.accent700),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onWrite});
  final VoidCallback? onWrite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.secondary300,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.secondary500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 책을 어떻게 읽었나요?',
            style: textTheme.bodyLarge?.copyWith(
              color: AppColors.primary800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            '다 읽고 남는 감상을 1~5문단 자유롭게 적어보세요.',
            style: textTheme.bodySmall
                ?.copyWith(color: AppColors.primary500),
          ),
          if (onWrite != null) ...[
            const SizedBox(height: AppSpacing.s3),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent500,
                  foregroundColor: AppColors.secondary50,
                ),
                onPressed: onWrite,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('후기 쓰기'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

