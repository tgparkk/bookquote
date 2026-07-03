// 책 상세의 헤더 영역 — 큰 중앙 표지 + 메타 + 별점(PR30-A), 기본정보 2×2
// 그리드 + 구매처 chip 행(PR30-B). 본체: `book_detail_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../../card_editor/presentation/widgets/share_sheet.dart'
    show buildAladinSearchUrl, buildBookPurchaseUrl;
import '../../domain/book.dart';
import 'book_cover.dart';
import 'book_rating_block.dart';
import 'page_count_input_sheet.dart';

// ── PR30-A: 헤더 (큰 표지 + 중앙 메타 + 큰 별점) ────────────────

/// 큰 중앙 표지(140×200) + 제목·저자·출판사·연도·ISBN + (로그인 시) 큰 별점.
/// 읽기 시작/완독일은 별도 행으로 빠져 헤더 밖에 배치된다.
class BookHeader extends StatelessWidget {
  const BookHeader({super.key, required this.book, required this.loggedIn});

  final Book book;
  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final author = book.author?.trim();
    final publisher = book.publisher?.trim();
    final pubDate = book.pubDate?.trim();
    final metaLine = [
      if (publisher != null && publisher.isNotEmpty) publisher,
      if (pubDate != null && pubDate.isNotEmpty) pubDate,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BookCover(
          url: book.coverUrl,
          title: book.title,
          width: 140,
          height: 200,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          book.title,
          style: textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        if (author != null && author.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            author,
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
        if (metaLine.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            metaLine,
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        if (loggedIn) ...[
          const SizedBox(height: AppSpacing.s4),
          BookRatingBlock(bookId: book.id),
        ],
        // PR30-C 친구 평균 별점 칩 — N≥3일 때만 자체 노출.
        FriendsAvgRatingChip(bookId: book.id),
      ],
    );
  }
}

// ── PR30-B: 기본정보 그리드 (페이지/출간/카테고리/ISBN 2×2) ────────────

/// 책 메타데이터를 2×2 그리드로 정돈. 알라딘이 채워주지 않은 빈 칸은 "—"
/// 표시(클릭 불가), 단 페이지 칸은 미수집 시 입력 BottomSheet를 띄우는 액션으로.
class BookInfoGrid extends ConsumerWidget {
  const BookInfoGrid({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final pubYear = _firstFour(book.pubDate);
    final category = book.categoryName?.trim();
    final isbn = book.isbn13.trim();
    final pageCount = book.pageCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('기본 정보', style: textTheme.titleMedium),
        const SizedBox(height: AppSpacing.s3),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: '쪽수',
                value: pageCount != null ? '$pageCount쪽' : '입력하기 ▸',
                emphasized: pageCount == null,
                onTap: pageCount == null
                    ? () => openPageCountInputSheet(
                          context: context,
                          ref: ref,
                          book: book,
                        )
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: _InfoTile(
                label: '출간',
                value: pubYear ?? '—',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s2),
        Row(
          children: [
            Expanded(
              child: _InfoTile(
                label: '분류',
                value: (category != null && category.isNotEmpty) ? category : '—',
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: _InfoTile(
                label: 'ISBN',
                value: isbn.isNotEmpty ? isbn : '—',
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String? _firstFour(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    if (t.length < 4) return t.isEmpty ? null : t;
    final yearLike = t.substring(0, 4);
    return RegExp(r'^\d{4}$').hasMatch(yearLike) ? yearLike : t;
  }
}

/// PR10: 책 상세 구매처 chip 행 — 교보문고 + 알라딘 ISBN 검색 URL로 외부 브라우저.
/// V1.0에선 제휴 ID/UTM 없이 plain 검색 링크. 출시 후 가입해 파라미터만 덧붙이는
/// 비차단 항목 (백로그). 직접 입력 책(isbn13 없음)은 호출자가 미노출 가드.
class PurchaseLinksRow extends StatelessWidget {
  const PurchaseLinksRow({super.key, required this.isbn13});

  final String isbn13;

  Future<void> _open(BuildContext context, String? url, String name) async {
    if (url == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      showAppSnackBarOn(messenger, '$name 페이지를 열 수 없어요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyobo = buildBookPurchaseUrl(isbn13);
    final aladin = buildAladinSearchUrl(isbn13);
    final colors = context.colors;
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _open(context, kyobo, '교보문고'),
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: const Text('교보문고'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurfaceMuted,              // primary700 → onSurfaceMuted
              side: BorderSide(color: colors.border, width: 1.5), // primary200 → border, const 제거
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _open(context, aladin, '알라딘'),
            icon: const Icon(Icons.shopping_bag_outlined, size: 16),
            label: const Text('알라딘'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.onSurfaceMuted,              // primary700 → onSurfaceMuted
              side: BorderSide(color: colors.border, width: 1.5), // primary200 → border, const 제거
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.onTap,
  });

  final String label;
  final String value;

  /// `value` 텍스트를 accent 컬러로 — 액션 상태("입력하기 ▸") 강조용.
  final bool emphasized;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    final tile = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceCard,               // secondary100 → surfaceCard
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceMuted), // primary500 → onSurfaceMuted
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              // accent600 → accentDefault, primary800 → onSurface
              color: emphasized ? colors.accentDefault : colors.onSurface,
              fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: tile,
    );
  }
}
