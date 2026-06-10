// 책 상세 `/book/:id` — 일반 진입(서재·검색) + deep link 진입(`?from=share`) 두 모드.
//
// 구성: (deep link면 상단에 "공유받은 책" 배너 + "내 서재에 담기" 1급 CTA) →
// 표지·메타 헤더(+로그인 시 별점) → "이 책에서 모은 N구절" 미니 리스트 +
// "이 책 인용구 추가" CTA(+안 담겼으면 보조 [서재에 담기], 담겼으면 ✓ 칩) →
// 설명(4줄+ 클램프 + "더 보기"/"접기"). 책 없음/에러는 출구(홈·서재·재시도) 제공.
// raw `$e`는 화면에 노출하지 않는다(error-handling §9).
//
// 설계: docs/design/screens/book-detail.md · deep-link-receive.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/auth_state_provider.dart';
import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/tokens.dart';
import '../../core/ui/app_status_view.dart';
import '../book_review/presentation/book_review_section.dart';
import 'domain/book.dart';
import 'presentation/widgets/book_header.dart';
import 'presentation/widgets/book_overflow_menu.dart';
import 'presentation/widgets/book_quotes_section.dart';
import 'presentation/widgets/library_actions.dart';
import 'presentation/widgets/quote_hero_card.dart';
import 'presentation/widgets/reading_dates_row.dart';
import 'presentation/widgets/reading_progress_strip.dart';
import 'state/book_providers.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({
    super.key,
    required this.bookId,
    this.from,
    this.sender,
  });

  final String bookId;

  /// deep link 진입 출처. `'share'` / `'kakao'`면 "공유받은 책" 모드.
  final String? from;

  /// 공유 카드 deep link의 발신자 uid (PR20-C). 공개 프로필이면 "[이 사람 서재 ▸]"
  /// 칩 노출. 본인이거나 비공개 프로필이면 칩 숨김 (RLS 0 row → friendProfileProvider null).
  final String? sender;

  bool get _fromShare => from == 'share' || from == 'kakao';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBook = ref.watch(bookByIdProvider(bookId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        title: const Text('책 상세'),
        actions: [
          if (asyncBook.value != null) OverflowMenu(bookId: bookId),
        ],
      ),
      body: asyncBook.when(
        data: (book) => book == null
            ? const _NotFoundView()
            : _BookBody(book: book, fromShare: _fromShare, sender: sender),
        loading: () => Center(
          child: CircularProgressIndicator(
              color: context.colors.accentDefault), // accent500 → accentDefault
        ),
        error: (_, _) => _ErrorView(
          onRetry: () => ref.invalidate(bookByIdProvider(bookId)),
        ),
      ),
    );
  }
}

// ── 본문 ──────────────────────────────────────────────────

class _BookBody extends ConsumerWidget {
  const _BookBody({
    required this.book,
    required this.fromShare,
    required this.sender,
  });

  final Book book;
  final bool fromShare;
  final String? sender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loggedIn = ref.watch(currentSessionProvider) != null;
    final textTheme = Theme.of(context).textTheme;
    final description = book.description?.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s4,
        AppSpacing.s6,
        AppSpacing.s16,
      ),
      children: [
        if (fromShare) ...[
          SharedBanner(sender: sender),
          const SizedBox(height: AppSpacing.s4),
          LibraryActionButton(bookId: book.id, prominent: true),
          const SizedBox(height: AppSpacing.s6),
        ],
        // PR30-A 헤더 — 큰 중앙 표지 + 메타 + (로그인) 큰 별점
        BookHeader(book: book, loggedIn: loggedIn),
        if (loggedIn) ...[
          const SizedBox(height: AppSpacing.s4),
          ReadingDatesRow(bookId: book.id),
        ],
        // PR30-C 진행 strip — 자체 가드(hasStarted && !hasFinished)로 노출.
        // 미로그인이면 readingDatesProvider가 빈 결과라 자연 hide.
        ReadingProgressStrip(bookId: book.id),
        const SizedBox(height: AppSpacing.s6),
        // PR30-A 인용구 hero 카드 — 내 인용 / 알라딘 첫 줄 / 빈 상태 CTA
        QuoteHeroCard(book: book),
        // PR30-C 무드 chips — 이 책 인용에 자주 붙인 무드 top 3 (인용구 없으면 hide).
        MoodSummaryChips(bookId: book.id),
        const SizedBox(height: AppSpacing.s4),
        // PR30-B 액션 행 — 인용구 추가(주) + 서재 담기(보조) 1줄 Row
        if (!fromShare) PrimaryActionRow(bookId: book.id),
        if (fromShare) AddQuoteButton(bookId: book.id),
        const SizedBox(height: AppSpacing.s8),
        // "이 책에서 모은 구절" — 헤더에 "친구 N명도 담음" inline chip (PR30-B)
        BookQuotesSection(bookId: book.id),
        // "이 책 후기" — 본인 + 타인 통합. 미로그인도 타인 후기 조회 가능(공개
        // 프로필 사용자만 노출, RLS 자연 게이트). 본인 카드만 "나" 라벨 + 수정/삭제.
        const SizedBox(height: AppSpacing.s8),
        BookReviewSection(bookId: book.id),
        // PR30-B 기본정보 그리드 — 페이지/출간/카테고리/ISBN 2×2.
        // 페이지 칸은 미수집 시 입력 BottomSheet로 열림.
        const SizedBox(height: AppSpacing.s8),
        BookInfoGrid(book: book),
        // PR10 (2026-05-28): ISBN 있을 때만 구매처 chip 2종. 직접 입력 책은 미노출.
        if (book.isbn13.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s3),
          PurchaseLinksRow(isbn13: book.isbn13),
        ],
        // 설명 — 점진적 공개
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s6),
          Text('설명', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s2),
          DescriptionText(text: description),
        ],
      ],
    );
  }
}

// ── 책 없음 / 에러 ─────────────────────────────────────────

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    return AppStatusView(
      topHeightFraction: 0.18,
      icon: Icons.menu_book_outlined,
      iconColor: context.colors.onSurfaceSubtle, // primary300 → onSurfaceSubtle
      title: '이 책을 더 이상 볼 수 없어요',
      subtitle: '삭제됐거나 잘못된 링크일 수 있어요.',
      gapBeforeActions: AppSpacing.s6,
      actions: [
        OutlinedButton(
          onPressed: () => context.go('/'),
          child: const Text('홈으로'),
        ),
        OutlinedButton(
          onPressed: () => context.go('/library'),
          child: const Text('내 서재'),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppStatusView(
      topHeightFraction: 0.22,
      subtitle: '책 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
      gapBeforeActions: AppSpacing.s3,
      actions: [
        OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    );
  }
}
