// 홈 "📖 지금 읽고 있어요" 1행 (PR23).
//
// 사용자 시나리오 D7~D30에서 가장 강한 retention ramp — *적기로 가는 다리*.
// 책 표지 탭 = 그 책에 인용구 한 줄 더 적기 직진 (마찰 0). 빈 상태는 신규
// D1~D7의 첫 책 등록 진입점.
//
// 데이터: `currentlyReadingProvider` (started_at IS NOT NULL · finished_at IS NULL,
// limit 7). 시작/완독 변경 시 호출자가 `ref.invalidate(currentlyReadingProvider)`.
// 빈 상태는 [+ 시작한 책 알려주기] 버튼 = 책 검색 시트 → 선택 후 자동
// `setReadingDate(started_at=today)`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/data/book_repository.dart';
import '../../../book/domain/reading_dates.dart';
import '../../../book/presentation/book_search_sheet.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../../book/state/book_providers.dart';

class NowReadingRow extends ConsumerWidget {
  const NowReadingRow({super.key});

  static const double _coverWidth = 64;
  static const double _coverHeight = 96;
  static const double _rowHeight = 142;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(currentlyReadingProvider);
    return async.when(
      // 로딩·에러는 조용히 — 홈 첫 페인트를 흔들지 않게.
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s2,
          AppSpacing.s4,
          AppSpacing.s2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s1),
              child: Row(
                children: [
                  Icon(
                    Icons.menu_book_rounded,
                    size: 18,
                    color: AppColors.primary600,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    '지금 읽고 있어요',
                    style: TextStyle(
                      fontFamily: AppFonts.ui,
                      fontSize: AppFontSize.sm,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            SizedBox(
              height: _rowHeight,
              child: items.isEmpty ? const _EmptyState() : _BookList(items: items),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookList extends ConsumerWidget {
  const _BookList({required this.items});

  final List<CurrentlyReading> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length + 1, // 끝에 [+] 1개.
      separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
      itemBuilder: (context, i) {
        if (i == items.length) {
          return const _AddCard();
        }
        final it = items[i];
        return _BookTile(reading: it);
      },
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.reading});

  final CurrentlyReading reading;

  @override
  Widget build(BuildContext context) {
    final book = reading.book;
    return SizedBox(
      width: NowReadingRow._coverWidth,
      child: InkWell(
        // 탭 = 그 책에 인용구 한 줄 더 적기 직진 (PR23 핵심 ramp).
        onTap: () => context.push('/quote/new?bookId=${book.id}'),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              url: book.coverUrl,
              title: book.title,
              width: NowReadingRow._coverWidth,
              height: NowReadingRow._coverHeight,
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.xs,
                fontWeight: FontWeight.w500,
                color: AppColors.primary800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCard extends ConsumerWidget {
  const _AddCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: NowReadingRow._coverWidth,
      child: InkWell(
        onTap: () => _onAddTap(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Column(
          children: [
            Container(
              width: NowReadingRow._coverWidth,
              height: NowReadingRow._coverHeight,
              decoration: BoxDecoration(
                color: AppColors.secondary100,
                border: Border.all(
                  color: AppColors.primary200,
                  width: 1.2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 28,
                color: AppColors.primary500,
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              '시작한 책',
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontSize: AppFontSize.xs,
                color: AppColors.primary500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.secondary100,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary100),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: () => _onAddTap(context, ref),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            children: [
              Icon(
                Icons.book_outlined,
                size: 28,
                color: AppColors.primary400,
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '지금 읽는 책이 없어요',
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '＋ 시작한 책 알려주기',
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: AppFontSize.xs,
                        color: AppColors.accent600,
                        fontWeight: FontWeight.w600,
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

/// [+] 카드 / 빈 상태 카드 공통 액션 — 책 검색 시트 → 선택 시 today를 시작일로
/// 자동 등록 후 NowReadingRow 갱신. 사용자 흐름의 "지금 읽기 시작했어요" 한 탭.
Future<void> _onAddTap(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final book = await showBookSearchSheet(context);
  if (book == null || !context.mounted) return;
  try {
    await ref.read(bookRepositoryProvider).setReadingDate(
          bookId: book.id,
          kind: ReadingDateKind.started,
          date: DateTime.now(),
        );
    ref.invalidate(currentlyReadingProvider);
    if (!context.mounted) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('"${book.title}" 오늘부터 읽고 있어요'),
          action: SnackBarAction(
            label: '한 줄 적기',
            onPressed: () {
              if (context.mounted) context.push('/quote/new?bookId=${book.id}');
            },
          ),
        ),
      );
  } on BookRepositoryException {
    if (!context.mounted) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('시작일 저장에 실패했어요.')));
  }
}
