// PR29-I: 홈 "최근 독자 후기" 가로 스크롤 row.
//
// 친구 follow 무관, 공개 프로필 사용자의 후기를 시간순 N개. 탭 → 책 상세.
// 0건이면 자체적으로 SizedBox.shrink (홈 화면 길이 영향 0).
// 카드 = 책 표지(좌측) + 작성자 아바타·닉네임·후기 본문 2줄(우측).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../book/presentation/widgets/book_cover.dart';
import '../data/book_review_repository.dart';
import '../state/book_review_providers.dart';

class RecentPublicReviewsRow extends ConsumerWidget {
  const RecentPublicReviewsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncReviews = ref.watch(recentPublicReviewsProvider);
    final reviews = asyncReviews.value;
    // loading/error 시엔 자체 숨김 — 홈은 본 흐름 안 끊는 게 우선.
    if (reviews == null || reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s2,
              AppSpacing.s4,
              AppSpacing.s2,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 16,
                  color: AppColors.accent700,
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  '최근 독자 후기',
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
              itemBuilder: (_, i) => _ReviewMiniCard(review: reviews[i]),
            ),
          ),
        ],
      ),
    );
  }
}

/// 한 카드 = 표지(좌) + 작성자·본문(우). 탭하면 책 상세 진입.
class _ReviewMiniCard extends StatelessWidget {
  const _ReviewMiniCard({required this.review});
  final RecentBookReview review;

  @override
  Widget build(BuildContext context) {
    final name = review.displayName ?? '(이름 없음)';
    final hasAvatar = review.avatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return Material(
      color: AppColors.secondary100,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      elevation: 0,
      child: InkWell(
        onTap: () => context.push('/book/${review.bookId}'),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(AppSpacing.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.secondary400),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BookCover(
                url: review.bookCoverUrl,
                title: review.bookTitle,
                width: 50,
                height: 75,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.accent200,
                          backgroundImage:
                              hasAvatar ? NetworkImage(review.avatarUrl!) : null,
                          child: hasAvatar
                              ? null
                              : Text(
                                  initial,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary900,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                        const SizedBox(width: AppSpacing.s1),
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: AppFonts.ui,
                              fontSize: AppFontSize.xs,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.bookTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: AppFontSize.xs,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        review.text,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.quote,
                          fontSize: AppFontSize.sm,
                          height: 1.45,
                          color: AppColors.primary800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
