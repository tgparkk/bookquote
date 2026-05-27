// PR29: 책 상세에 노출되는 "내 후기" 섹션.
//
// 후기가 없으면 "후기를 남겨보세요 → 쓰기" CTA. 있으면 본문 + 수정/삭제 액션.
// 입력은 BottomSheet(book_review_input_sheet.dart)로 격리 — 책 상세 스크롤
// 마찰 없이 풀스크린 키보드 입력.
//
// 미로그인은 자체 렌더 안 함(로그인 게이트는 책 상세의 별점·서재 행과 같이
// 호출 측에서 분기).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../data/book_review_repository.dart';
import '../domain/book_review.dart';
import '../state/book_review_providers.dart';
import 'book_review_input_sheet.dart';

class BookReviewSection extends ConsumerWidget {
  const BookReviewSection({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReview = ref.watch(myBookReviewProvider(bookId));
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('내 후기', style: textTheme.titleMedium),
            const Spacer(),
            if (asyncReview.value != null)
              TextButton.icon(
                onPressed: () => _openSheet(context, ref, asyncReview.value),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('수정'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent700,
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.s3),
        asyncReview.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent500),
            ),
          ),
          error: (_, _) => Row(
            children: [
              Expanded(
                child: Text(
                  '후기를 불러오지 못했어요.',
                  style: textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.invalidate(myBookReviewProvider(bookId)),
                child: const Text('다시 시도'),
              ),
            ],
          ),
          data: (review) => review == null
              ? _EmptyState(onWrite: () => _openSheet(context, ref, null))
              : _ReviewBody(review: review, ref: ref, bookId: bookId),
        ),
      ],
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    BookReview? existing,
  ) async {
    final saved = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondary100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => BookReviewInputSheet(initialText: existing?.text ?? ''),
    );
    if (saved == null) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(bookReviewRepositoryProvider)
          .upsertMyReview(bookId: bookId, text: saved);
      ref.invalidate(myBookReviewProvider(bookId));
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(existing == null ? '후기를 남겼어요' : '후기를 수정했어요'),
          ),
        );
    } on BookReviewRepositoryException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onWrite});
  final VoidCallback onWrite;

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
      ),
    );
  }
}

class _ReviewBody extends StatelessWidget {
  const _ReviewBody({
    required this.review,
    required this.ref,
    required this.bookId,
  });
  final BookReview review;
  final WidgetRef ref;
  final String bookId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.secondary100,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.secondary500),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 본문 — 인용구처럼 serif로 감상의 무게를 살림.
          Text(
            review.text,
            style: TextStyle(
              fontFamily: AppFonts.quote,
              fontSize: AppFontSize.base,
              height: AppLineHeight.loose,
              color: AppColors.primary800,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Text(
                _formatDate(review.updatedAt),
                style: textTheme.labelSmall
                    ?.copyWith(color: AppColors.primary400),
              ),
              const Spacer(),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.semanticError,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _confirmDelete(context),
                child: const Text('삭제'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime t) {
    final local = t.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y.$m.$d 수정';
  }

  Future<void> _confirmDelete(BuildContext context) async {
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
