// PR29-H: 책 한 권의 모든 후기 전체 보기 화면 — `/book/:id/reviews`.
//
// 책 상세에서 미리보기 5개를 넘으면 "전체 보기"로 진입. RPC가 50개까지 반환
// (V1.0). 권수 더 늘면 cursor-after 무한 스크롤은 V1.0.x. 본인 후기 수정/삭제는
// 책 상세에서만 가능하게 두고(이 화면은 *읽기 위주*), 신고는 그대로.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/auth_state_provider.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../state/book_review_providers.dart';
import 'book_review_card.dart';

class BookReviewsScreen extends ConsumerWidget {
  const BookReviewsScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReviews = ref.watch(publicBookReviewsByBookProvider(bookId));
    final myUid = ref.watch(currentUserIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('이 책 후기')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(publicBookReviewsByBookProvider(bookId)),
          child: asyncReviews.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                color: context.colors.accentDefault,
              ),
            ),
            error: (_, _) => _ErrorView(
              onRetry: () =>
                  ref.invalidate(publicBookReviewsByBookProvider(bookId)),
            ),
            data: (reviews) => reviews.isEmpty
                ? const _EmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    itemCount: reviews.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s3),
                    itemBuilder: (_, i) {
                      final r = reviews[i];
                      return BookReviewCard(
                        review: r,
                        isMine: myUid != null && r.userId == myUid,
                        // 수정/삭제는 책 상세에서만 — 이 화면은 읽기 위주.
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors; // 시맨틱 색
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s16,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      children: [
        Icon(
          Icons.rate_review_outlined,
          size: 48,
          color: colors.onSurfaceSubtle, // primary300 → onSurfaceSubtle
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '아직 후기가 없어요',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall,
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
          '후기를 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
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
