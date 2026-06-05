// 책 검색 후 "어떻게 담을까요?" 분류 선택 시트.
//
// `showBookSearchSheet` 직후 호출자(library FAB)가 띄운다. 반환은
// [ReadingStatus]? (취소·바깥 탭은 null). 호출자가 그 값을 보고:
//   wishlist → addToLibrary만
//   reading  → addToLibrary + setReadingDate(started_at=today)
//   finished → addToLibrary만 (날짜는 사용자가 책 상세에서 직접 입력)
// 로 분기한다. finished 선택 시 dates를 채우지 않는 건 캘린더가 가짜 데이터로
// 더럽혀지지 않게 하기 위해서다.

import 'package:flutter/material.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../domain/book.dart';

enum ReadingStatus { wishlist, reading, finished }

extension ReadingStatusUi on ReadingStatus {
  String get emoji => switch (this) {
        ReadingStatus.wishlist => '🔖',
        ReadingStatus.reading => '📖',
        ReadingStatus.finished => '✅',
      };

  String get label => switch (this) {
        ReadingStatus.wishlist => '읽고 싶어요',
        ReadingStatus.reading => '읽고 있어요',
        ReadingStatus.finished => '읽었어요',
      };

  String get hint => switch (this) {
        ReadingStatus.wishlist => '나중에 읽으려고 담아둬요',
        ReadingStatus.reading => '오늘부터 읽기 시작해요',
        ReadingStatus.finished => '날짜는 책 상세에서 입력할 수 있어요',
      };
}

Future<ReadingStatus?> showAddBookStatusSheet(
  BuildContext context, {
  required Book book,
}) {
  return showModalBottomSheet<ReadingStatus>(
    context: context,
    backgroundColor: context.colors.surfaceSheet, // secondary100 → surfaceSheet
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => SafeArea(child: _AddBookStatusBody(book: book)),
  );
}

class _AddBookStatusBody extends StatelessWidget {
  const _AddBookStatusBody({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppSpacing.s3),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.border, // primary200 → border
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Column(
            children: [
              Text('어떻게 담을까요?', style: textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: context.colors.onSurfaceSubtle, // primary500 → onSurfaceSubtle
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        for (final s in ReadingStatus.values)
          _StatusTile(status: s, onTap: () => Navigator.of(context).pop(s)),
        const SizedBox(height: AppSpacing.s2),
      ],
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.status, required this.onTap});

  final ReadingStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          children: [
            Text(status.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(status.label, style: textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    status.hint,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceSubtle, // primary500 → onSurfaceSubtle
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.iconMuted, // primary400 → iconMuted
            ),
          ],
        ),
      ),
    );
  }
}
