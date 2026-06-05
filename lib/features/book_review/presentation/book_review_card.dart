// PR29-H: 후기 카드 단일 위젯 — 책 상세 미리보기 + 별도 전체 보기 화면 공유.
//
// 본인 후기는 "나" 라벨 + 다른 배경/테두리 + 수정/삭제 메뉴(콜백 있을 때만).
// 타인 후기는 작성자 아바타·닉네임(탭 → 친구 프로필) + 신고 메뉴.
// callback 정책으로 컨테이너 위젯이 본인 식별·액션 wiring을 결정.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../moderation/presentation/report_dialog.dart';
import '../data/book_review_repository.dart';

class BookReviewCard extends StatelessWidget {
  const BookReviewCard({
    super.key,
    required this.review,
    required this.isMine,
    this.onEdit,
    this.onDelete,
  });

  final PublicBookReview review;
  final bool isMine;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors; // 시맨틱 색
    final name = review.displayName ?? '(이름 없음)';
    final hasAvatar = review.avatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    final avatar = CircleAvatar(
      radius: 14,
      // 아바타 배경: accentBorder(accent200 계열)로 매핑
      backgroundColor: colors.accentBorder,
      backgroundImage: hasAvatar ? NetworkImage(review.avatarUrl!) : null,
      child: hasAvatar
          ? null
          : Text(
              initial,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
    final nameLabel = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: AppFontSize.sm,
        fontWeight: FontWeight.w600,
        color: colors.onSurface,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        // 본인: surface(secondary100), 타인: surfaceCard(secondary300/dark:primary700)
        color: isMine ? colors.surface : colors.surfaceCard,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          // 본인: accentBorder, 타인: border
          color: isMine ? colors.accentBorder : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isMine)
                avatar
              else
                InkWell(
                  onTap: () => context.push('/u/${review.userId}'),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  child: avatar,
                ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: isMine
                    ? nameLabel
                    : InkWell(
                        onTap: () => context.push('/u/${review.userId}'),
                        child: nameLabel,
                      ),
              ),
              if (isMine) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentContainer,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '나',
                    style: TextStyle(
                      fontFamily: AppFonts.ui,
                      fontSize: AppFontSize.xs,
                      fontWeight: FontWeight.w600,
                      color: colors.accentOnContainer,
                    ),
                  ),
                ),
                if (onEdit != null || onDelete != null)
                  PopupMenuButton<String>(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') onEdit?.call();
                      if (v == 'delete') onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      if (onEdit != null)
                        const PopupMenuItem(value: 'edit', child: Text('수정')),
                      if (onDelete != null)
                        const PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                  ),
              ] else
                PopupMenuButton<String>(
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                  onSelected: (v) async {
                    if (v == 'report') {
                      await showReportDialog(
                        context,
                        reportedUserId: review.userId,
                        targetLabel: '$name님의 후기',
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'report', child: Text('신고하기')),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            review.text,
            style: TextStyle(
              fontFamily: AppFonts.quote,
              fontSize: AppFontSize.sm,
              height: AppLineHeight.loose,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            _formatDate(review.updatedAt),
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.onSurfaceSubtle,
            ),
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
    return '$y.$m.$d';
  }
}
