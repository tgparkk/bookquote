// 인용구 입력 화면의 "책 연결" 필드 — 미연결이면 [+ 책 연결], 연결이면
// 표지+제목+저자 + [변경 ▸]. 본체: `quote_input_screen.dart`.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/book_cover.dart';

class QuoteBookField extends StatelessWidget {
  const QuoteBookField({super.key, required this.book, required this.onTap});

  final Book? book;
  final VoidCallback? onTap;

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
        onTap: onTap,
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
                    Text('변경 ▸',
                        style: textTheme.labelMedium
                            ?.copyWith(color: colors.accentDefault)),
                  ],
                ),
        ),
      ),
    );
  }
}
