// 책 상세 헤더 직하의 인용구 hero 카드(PR30-A) — 내 인용 / 알라딘 첫 줄 /
// 빈 상태 CTA 3-state. 본체: `book_detail_screen.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/auth_state_provider.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../quote/domain/quote.dart';
import '../../../quote/state/quote_providers.dart';
import '../../domain/book.dart';

// ── PR30-A: 인용구 hero 카드 (3-state) ─────────────────────────

/// 책 상세 헤더 직하의 큰 인용 카드. 우선순위:
/// (1) 내가 이 책에서 모은 인용구 중 최신 = 큰 따옴표 카드. 잠긴 인용(text==null)은
///     건너뛴다.
/// (2) 알라딘 description의 첫 문단 = 출판사 소개 미리보기 카드(아래 "설명" 섹션과
///     의도된 중복 — UX-B 권고).
/// (3) 둘 다 없으면 "이 책의 첫 인용구를 남겨주세요" CTA 카드.
class QuoteHeroCard extends ConsumerWidget {
  const QuoteHeroCard({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuotes = ref.watch(bookQuotesProvider(book.id));
    final loggedIn = ref.watch(currentSessionProvider) != null;
    final quotes = asyncQuotes.value ?? const <Quote>[];
    final visible =
        quotes.where((q) => (q.text ?? '').trim().isNotEmpty).toList();

    if (visible.isNotEmpty) {
      return _HeroQuoteFromUser(quote: visible.first);
    }
    final description = book.description?.trim();
    final descPreview = _firstParagraph(description);
    if (descPreview != null) {
      return _HeroQuoteFromDescription(text: descPreview);
    }
    return _HeroQuoteEmpty(bookId: book.id, loggedIn: loggedIn);
  }

  /// description의 첫 줄·문단 추출. 빈 줄로 끊긴 부분 또는 첫 줄까지.
  static String? _firstParagraph(String? text) {
    if (text == null || text.isEmpty) return null;
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isNotEmpty) return t;
    }
    return null;
  }
}

class _HeroQuoteFromUser extends StatelessWidget {
  const _HeroQuoteFromUser({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final text = (quote.text ?? '').trim();
    final page = quote.page;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: colors.accentContainer,           // accent50 → accentContainer
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.accentBorder), // accent200 → accentBorder
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '”',
            style: TextStyle( // const 제거 — 런타임 색
              fontFamily: AppFonts.quote,
              fontSize: 36,
              height: 1,
              color: colors.accentDefault,       // accent400 → accentDefault
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle( // const 제거 — 런타임 색
              fontFamily: AppFonts.quote,
              fontSize: AppFontSize.base,
              height: AppLineHeight.relaxed,
              color: colors.accentOnContainer,   // accent800 → accentOnContainer
              fontWeight: FontWeight.w500,
            ),
          ),
          if (page != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'p.$page',
                style: textTheme.labelSmall?.copyWith(
                    color: colors.accentOnContainer), // accent700 → accentOnContainer
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroQuoteFromDescription extends StatelessWidget {
  const _HeroQuoteFromDescription({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: colors.surface,                        // secondary50 → surface
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.border),    // primary200 → border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '출판사 소개',
            style: textTheme.labelSmall?.copyWith(
                color: colors.onSurfaceMuted), // primary500 → onSurfaceMuted
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              height: AppLineHeight.relaxed,
              color: colors.onSurface, // primary800 → onSurface
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroQuoteEmpty extends StatelessWidget {
  const _HeroQuoteEmpty({required this.bookId, required this.loggedIn});

  final String bookId;
  final bool loggedIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => context.push('/quote/new?bookId=$bookId'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s4),
        decoration: BoxDecoration(
          color: context.colors.accentContainer,       // accent50 → accentContainer
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: context.colors.accentBorder,        // accent200 → accentBorder
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.format_quote_rounded,
              color: context.colors.accentDefault,     // accent500 → accentDefault
              size: 28,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이 책의 첫 인용구를 남겨주세요',
                    style: textTheme.titleSmall?.copyWith(
                        color: context.colors.accentOnContainer), // accent800 → accentOnContainer
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loggedIn ? '읽다 마음에 든 한 줄을 한 손에 모아둘 수 있어요.' : '로그인하면 한 줄을 모을 수 있어요.',
                    style: textTheme.bodySmall?.copyWith(
                        color: context.colors.onSurfaceMuted), // primary600 → onSurfaceMuted
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.accentDefault,     // accent500 → accentDefault
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
