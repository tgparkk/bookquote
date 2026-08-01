// 인용구 입력 화면의 "책 연결" 필드 — 미연결이면 [+ 책 연결], 연결이면
// 표지+제목+저자(탭 시 책 상세) + [변경 ▸](탭 시 검색 시트).
// 본체: `quote_input_screen.dart`.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';

class QuoteBookField extends StatelessWidget {
  const QuoteBookField({
    super.key,
    required this.book,
    required this.onTap,
    this.onBookTap,
  });

  final Book? book;

  /// 책 연결/변경 — 미연결 시 필드 전체, 연결 시 [변경 ▸] 탭.
  final VoidCallback? onTap;

  /// 연결된 책 영역 탭 — 책 상세 이동. null이면 연결 시에도 onTap으로 동작.
  final VoidCallback? onBookTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final book = this.book;
    final author = book?.author;
    return Material(
      // 책 연결 필드 배경: surface 토큰(라이트=secondary100, 다크=primary800)
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: book == null ? onTap : (onBookTap ?? onTap),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: book == null
              ? Row(
                  children: [
                    Icon(Icons.add, size: 20, color: colors.accentDefault),
                    const SizedBox(width: AppSpacing.s2),
                    Text('책 연결',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: colors.accentOnContainer)),
                  ],
                )
              : Row(
                  children: [
                    BookCover(url: book.coverUrl, title: book.title),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleSmall),
                          if (author != null && author.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(author, style: textTheme.bodySmall),
                            ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s2,
                          vertical: AppSpacing.s2,
                        ),
                        child: Text('변경 ▸',
                            style: textTheme.labelMedium
                                ?.copyWith(color: colors.accentDefault)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
