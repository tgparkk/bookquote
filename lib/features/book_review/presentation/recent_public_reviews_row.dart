// [보류 — 2026-05-29] 홈 "최근 독자 후기" 가로 row.
//
// '활동' 탭(activity_screen.dart)으로 콘텐츠가 이전되며 홈에서 제거됨. 데이터
// provider(recentPublicReviewsProvider)는 활동 탭이 계속 사용하므로 살아있고,
// 이 위젯만 미사용. 삭제 대신 주석 보존 — 추후 홈 재배치/재사용 가능성 대비.
// 되살리려면 아래 블록 주석을 풀고 home_screen.dart에 import + `const
// RecentPublicReviewsRow()` 재배치하면 됨.

/*
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_semantic_colors.dart';
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
                  color: context.colors.accentOnContainer,
                ),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  '최근 독자 후기',
                  style: TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w700,
                    color: context.colors.accentOnContainer,
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
    final colors = context.colors; // 시맨틱 색
    final name = review.displayName ?? '(이름 없음)';
    final hasAvatar = review.avatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return Material(
      color: colors.surface,
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
            border: Border.all(color: colors.border),
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
                          backgroundColor: colors.accentBorder,
                          backgroundImage:
                              hasAvatar ? NetworkImage(review.avatarUrl!) : null,
                          child: hasAvatar
                              ? null
                              : Text(
                                  initial,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colors.onSurface,
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
                              color: colors.onSurfaceMuted,
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
                        color: colors.onSurfaceMuted,
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
                          color: colors.onSurface,
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
*/
