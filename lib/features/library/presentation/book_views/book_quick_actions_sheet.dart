// 서재 책 카드 long-press 액션시트 (PR6 — 2026-05-28).
//
// Letterboxd 패턴: 표지 길게 누르면 책 상세로 가지 않고 바로 액션시트가 떠
// 인용구 추가·읽기 시작·다 읽음·공유 4개 동선을 1탭으로 처리.
// 서재 4뷰(shelf/grid/list/stack)에서 공통 호출.
//
// 시각 정렬: ListTile 아이콘 + 라벨 + (필요 시) subtitle. dense·zero padding로
// 시트 높이 절약.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/data/book_repository.dart';
import '../../../book/domain/book.dart';
import '../../../book/domain/reading_dates.dart';
import '../../../book/state/book_providers.dart';
import '../../../card_editor/presentation/widgets/share_sheet.dart'
    show buildBookPurchaseUrl;

Future<void> showBookQuickActionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Book book,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.secondary100,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) => _BookQuickActionsSheet(book: book),
  );
}

class _BookQuickActionsSheet extends ConsumerWidget {
  const _BookQuickActionsSheet({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          0,
          AppSpacing.s4,
          AppSpacing.s2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s2,
                vertical: AppSpacing.s2,
              ),
              child: Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
            ),
            _ActionTile(
              icon: Icons.format_quote_rounded,
              label: '인용구 추가',
              onTap: () {
                Navigator.of(context).pop();
                context.push('/quote/new?bookId=${book.id}');
              },
            ),
            _ActionTile(
              icon: Icons.play_arrow_rounded,
              label: '읽기 시작',
              onTap: () =>
                  _setReadingDate(context, ref, ReadingDateKind.started),
            ),
            _ActionTile(
              icon: Icons.check_circle_outline_rounded,
              label: '다 읽음',
              onTap: () =>
                  _setReadingDate(context, ref, ReadingDateKind.finished),
            ),
            _ActionTile(
              icon: Icons.ios_share_rounded,
              label: '공유',
              onTap: () => _share(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setReadingDate(
    BuildContext context,
    WidgetRef ref,
    ReadingDateKind kind,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(bookRepositoryProvider).setReadingDate(
            bookId: book.id,
            kind: kind,
            date: DateTime.now(),
          );
      // 홈 NowReadingRow + 서재 책 목록 즉시 반영.
      ref
        ..invalidate(currentlyReadingProvider)
        ..invalidate(myLibraryProvider);
      navigator.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text(
            kind == ReadingDateKind.started ? '읽기 시작에 표시했어요.' : '다 읽음으로 표시했어요.',
          ),
        ));
    } catch (_) {
      navigator.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('표시하지 못했어요. 다시 시도해 주세요.')),
        );
    }
  }

  Future<void> _share(BuildContext context) async {
    final navigator = Navigator.of(context);
    final author = book.author;
    final pageCount = book.pageCount;
    final url = buildBookPurchaseUrl(book.isbn13);
    // PR12 (2026-05-28): 책 정보 라인에 페이지 수 함께 (있을 때).
    // "책 제목 · 김저자 · 423쪽" 한 줄로 묶고, 다음 줄에 구매 URL.
    final headerParts = <String>[
      book.title,
      if (author != null && author.isNotEmpty) author,
      if (pageCount != null) '$pageCount쪽',
    ];
    final lines = <String>[
      headerParts.join(' · '),
      ?url,
    ];
    final text = lines.join('\n');
    navigator.pop();
    try {
      await SharePlus.instance.share(
        ShareParams(text: text, subject: book.title),
      );
    } catch (_) {/* 공유 취소·실패는 침묵 */}
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary600),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: AppFonts.ui,
          fontSize: AppFontSize.base,
          fontWeight: FontWeight.w500,
          color: AppColors.primary700,
        ),
      ),
      onTap: onTap,
      visualDensity: VisualDensity.compact,
    );
  }
}
