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
import 'package:url_launcher/url_launcher.dart';

import '../../app/auth_state_provider.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/tokens.dart';
import '../book_review/presentation/book_review_section.dart';
import '../card_editor/presentation/widgets/share_sheet.dart'
    show buildAladinSearchUrl, buildBookPurchaseUrl;
import '../follow/state/follow_providers.dart';
import '../profile/domain/profile.dart';
import '../profile/state/friend_providers.dart';
import '../quote/domain/quote.dart';
import '../quote/domain/quote_mood.dart';
import '../quote/presentation/widgets/quote_list_card.dart';
import '../quote/state/quote_providers.dart';
import 'data/book_repository.dart';
import 'domain/book.dart';
import 'presentation/widgets/book_cover.dart';
import 'presentation/widgets/page_count_input_sheet.dart';
import 'presentation/widgets/reading_dates_row.dart';
import 'presentation/widgets/star_rating.dart';
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
          if (asyncBook.value != null) _OverflowMenu(bookId: bookId),
        ],
      ),
      body: asyncBook.when(
        data: (book) => book == null
            ? const _NotFoundView()
            : _BookBody(book: book, fromShare: _fromShare, sender: sender),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent500),
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
          _SharedBanner(sender: sender),
          const SizedBox(height: AppSpacing.s4),
          _LibraryActionButton(bookId: book.id, prominent: true),
          const SizedBox(height: AppSpacing.s6),
        ],
        // PR30-A 헤더 — 큰 중앙 표지 + 메타 + (로그인) 큰 별점
        _BookHeader(book: book, loggedIn: loggedIn),
        if (loggedIn) ...[
          const SizedBox(height: AppSpacing.s4),
          ReadingDatesRow(bookId: book.id),
        ],
        // PR30-C 진행 strip — 자체 가드(hasStarted && !hasFinished)로 노출.
        // 미로그인이면 readingDatesProvider가 빈 결과라 자연 hide.
        _ReadingProgressStrip(bookId: book.id),
        const SizedBox(height: AppSpacing.s6),
        // PR30-A 인용구 hero 카드 — 내 인용 / 알라딘 첫 줄 / 빈 상태 CTA
        _QuoteHeroCard(book: book),
        // PR30-C 무드 chips — 이 책 인용에 자주 붙인 무드 top 3 (인용구 없으면 hide).
        _MoodSummaryChips(bookId: book.id),
        const SizedBox(height: AppSpacing.s4),
        // PR30-B 액션 행 — 인용구 추가(주) + 서재 담기(보조) 1줄 Row
        if (!fromShare) _PrimaryActionRow(bookId: book.id),
        if (fromShare) _AddQuoteButton(bookId: book.id),
        const SizedBox(height: AppSpacing.s8),
        // "이 책에서 모은 구절" — 헤더에 "친구 N명도 담음" inline chip (PR30-B)
        _BookQuotesSection(bookId: book.id),
        // "이 책 후기" — 본인 + 타인 통합. 미로그인도 타인 후기 조회 가능(공개
        // 프로필 사용자만 노출, RLS 자연 게이트). 본인 카드만 "나" 라벨 + 수정/삭제.
        const SizedBox(height: AppSpacing.s8),
        BookReviewSection(bookId: book.id),
        // PR30-B 기본정보 그리드 — 페이지/출간/카테고리/ISBN 2×2.
        // 페이지 칸은 미수집 시 입력 BottomSheet로 열림.
        const SizedBox(height: AppSpacing.s8),
        _BookInfoGrid(book: book),
        // PR10 (2026-05-28): ISBN 있을 때만 구매처 chip 2종. 직접 입력 책은 미노출.
        if (book.isbn13.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s3),
          _PurchaseLinksRow(isbn13: book.isbn13),
        ],
        // 설명 — 점진적 공개
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s6),
          Text('설명', style: textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s2),
          _DescriptionText(text: description),
        ],
      ],
    );
  }
}

// ── "공유받은 책" 배너 (deep link 진입 시) ─────────────────────

class _SharedBanner extends ConsumerWidget {
  const _SharedBanner({required this.sender});

  /// 카드 deep link sender uid. 공개 프로필이면 발신자 이름 + "[이 사람 서재 ▸]"
  /// 버튼 노출(PR20-C). 본인이거나 비공개 프로필이면 익명 카피만.
  final String? sender;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 본인 uid는 redirect로 막혔어야 하지만 deep link 위변조 대비 — 본인이면 익명 카피.
    final myUid = ref.watch(currentUserIdProvider);
    final senderUid = (sender == null || sender == myUid) ? null : sender;
    // RLS상 공개 프로필 OR 본인이면 row → 비공개면 null 자연 fallback.
    final senderProfile = senderUid == null
        ? null
        : ref.watch(friendProfileProvider(senderUid)).value;
    final senderName = senderProfile?.displayName;
    final text = senderName != null && senderName.isNotEmpty
        ? '$senderName님이 이 책의 한 줄을 보냈어요.'
        : '누군가 이 책의 한 줄을 보냈어요. 마음에 들면 서재에 담아보세요.';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(
        color: AppColors.accent50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.accent200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💬', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontFamily: AppFonts.ui,
                    fontSize: AppFontSize.sm,
                    fontWeight: FontWeight.w600,
                    height: AppLineHeight.normal,
                    color: AppColors.accent800,
                  ),
                ),
              ),
            ],
          ),
          if (senderProfile != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/u/$senderUid'),
                icon: const Icon(Icons.chevron_right_rounded, size: 16),
                label: const Text('이 사람 서재 보기'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accent700,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── "이 책 인용구 추가" CTA ────────────────────────────────

class _AddQuoteButton extends StatelessWidget {
  const _AddQuoteButton({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    // `/quote/new`는 인증 가드라 미로그인이면 라우터가 로그인으로 보냈다 복귀시킨다.
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent500,
        foregroundColor: AppColors.secondary50,
        minimumSize: const Size(double.infinity, 48),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontWeight: FontWeight.w600,
          fontSize: AppFontSize.base,
        ),
      ),
      icon: const Icon(Icons.add),
      label: const Text('이 책 인용구 추가'),
      onPressed: () => context.push('/quote/new?bookId=$bookId'),
    );
  }
}

// ── "서재에 담기" / "✓ 서재에 있음" ────────────────────────

class _LibraryActionButton extends ConsumerStatefulWidget {
  const _LibraryActionButton({required this.bookId, required this.prominent});

  final String bookId;

  /// true면 큰 ElevatedButton(deep link 진입 시), false면 보조 OutlinedButton.
  final bool prominent;

  @override
  ConsumerState<_LibraryActionButton> createState() =>
      _LibraryActionButtonState();
}

class _LibraryActionButtonState extends ConsumerState<_LibraryActionButton> {
  bool _busy = false;

  Future<void> _add() async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).addToLibrary(widget.bookId);
      if (!mounted) return;
      ref.invalidate(isInLibraryProvider(widget.bookId));
      ref.invalidate(myLibraryProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('서재에 담았어요'),
            action: SnackBarAction(
              label: '서재 보기',
              onPressed: () {
                if (mounted) context.go('/library');
              },
            ),
          ),
        );
    } on BookRepositoryException catch (e) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'NOT_AUTHENTICATED'
                  ? '로그인이 필요해요.'
                  : '서재에 담지 못했어요. 다시 시도해주세요.',
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('서재에 담지 못했어요. 다시 시도해주세요.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPressed() {
    final loggedIn = ref.read(currentSessionProvider) != null;
    if (!loggedIn) {
      // 로그인 후 이 화면(공유 진입이면 ?from=share까지)으로 복귀 — payload 보존.
      final back = Uri.encodeComponent(
        '/book/${widget.bookId}${widget.prominent ? '?from=share' : ''}',
      );
      context.push('/auth/login?from=$back');
      return;
    }
    _add();
  }

  @override
  Widget build(BuildContext context) {
    final inLibrary =
        ref.watch(isInLibraryProvider(widget.bookId)).value ?? false;

    if (inLibrary) {
      final chip = _InLibraryChip(
        label: widget.prominent ? '이미 서재에 있어요' : '서재에 있음',
      );
      return Align(
        alignment: widget.prominent ? Alignment.center : Alignment.centerLeft,
        child: chip,
      );
    }

    final onPressed = _busy ? null : _onPressed;
    final spinner = SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: widget.prominent ? AppColors.secondary50 : AppColors.accent600,
      ),
    );

    if (widget.prominent) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent500,
          foregroundColor: AppColors.secondary50,
          minimumSize: const Size(double.infinity, 52),
          textStyle: const TextStyle(
            fontFamily: AppFonts.ui,
            fontWeight: FontWeight.w600,
            fontSize: AppFontSize.base,
          ),
        ),
        icon: _busy ? spinner : const Icon(Icons.library_add),
        label: const Text('내 서재에 담기'),
        onPressed: onPressed,
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accent600,
        side: const BorderSide(color: AppColors.accent500),
        minimumSize: const Size(double.infinity, 44),
      ),
      icon: _busy ? spinner : const Icon(Icons.library_add_outlined, size: 18),
      label: const Text('서재에 담기'),
      onPressed: onPressed,
    );
  }
}

class _InLibraryChip extends StatelessWidget {
  const _InLibraryChip({this.label = '서재에 있음'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.semanticSuccessLight,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, size: 16, color: AppColors.semanticSuccess),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w500,
              color: AppColors.semanticSuccess,
            ),
          ),
        ],
      ),
    );
  }
}

// ── "이 책에서 모은 구절" ──────────────────────────────────

class _BookQuotesSection extends ConsumerStatefulWidget {
  const _BookQuotesSection({required this.bookId});

  final String bookId;

  @override
  ConsumerState<_BookQuotesSection> createState() => _BookQuotesSectionState();
}

class _BookQuotesSectionState extends ConsumerState<_BookQuotesSection> {
  static const _maxShown = 3;
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final asyncQuotes = ref.watch(bookQuotesProvider(widget.bookId));

    return asyncQuotes.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.accent500),
        ),
      ),
      // 책 정보·표지·메타는 그대로 두고 인용 섹션만 인라인 실패 처리(부분 실패 격리).
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '이 책의 인용구를 못 불러왔어요.',
                style: textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(bookQuotesProvider(widget.bookId)),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (quotes) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('이 책에서 모은 구절', style: textTheme.titleMedium),
                if (quotes.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    '${quotes.length}',
                    style: textTheme.titleMedium
                        ?.copyWith(color: AppColors.primary400),
                  ),
                ],
                const Spacer(),
                // PR30-B: "친구 N명도 담음" inline chip — 기존 행이었던
                // _FriendsWithBookRow를 흡수. N≥1일 때만 자체 노출.
                _FriendsWithBookChip(bookId: widget.bookId),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            if (quotes.isEmpty)
              Text(
                '아직 이 책에서 모은 구절이 없어요.',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.primary500),
              )
            else
              for (final q in quotes.take(_maxShown))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                  child: QuoteListCard(
                    quote: q,
                    // 책 고정 — 표지·제목 중복 표시하지 않는다.
                    book: null,
                    expanded: _expandedId == q.id,
                    onTap: () => setState(
                      () => _expandedId = _expandedId == q.id ? null : q.id,
                    ),
                    onShare: () => context.push('/quote/${q.id}/share'),
                    onMakeCard: () => context.push('/quote/${q.id}/card'),
                  ),
                ),
            if (quotes.length > _maxShown)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/library?tab=quotes'),
                  child: const Text('전체 보기 ▸'),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── 설명 — 4줄+ 면 클램프 + "더 보기"/"접기" ─────────────────

class _DescriptionText extends StatefulWidget {
  const _DescriptionText({required this.text});

  final String text;

  @override
  State<_DescriptionText> createState() => _DescriptionTextState();
}

class _DescriptionTextState extends State<_DescriptionText> {
  static const _collapsedLines = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: _collapsedLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = tp.didExceedMaxLines;
        final showFull = _expanded || !overflows;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: showFull ? null : _collapsedLines,
              overflow: showFull ? TextOverflow.clip : TextOverflow.fade,
            ),
            if (overflows)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.accent600,
                ),
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? '접기' : '더 보기'),
              ),
          ],
        );
      },
    );
  }
}

// ── 책 없음 / 에러 ─────────────────────────────────────────

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s8),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.18),
        Icon(Icons.menu_book_outlined, size: 48, color: AppColors.primary300),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '이 책을 더 이상 볼 수 없어요',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '삭제됐거나 잘못된 링크일 수 있어요.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton(
              onPressed: () => context.go('/'),
              child: const Text('홈으로'),
            ),
            const SizedBox(width: AppSpacing.s3),
            OutlinedButton(
              onPressed: () => context.go('/library'),
              child: const Text('내 서재'),
            ),
          ],
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
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s8),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
        Text(
          '책 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s3),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ),
      ],
    );
  }
}

// ── AppBar ⋮ — 담긴 책이면 "서재에서 빼기" ────────────────────

class _OverflowMenu extends ConsumerWidget {
  const _OverflowMenu({required this.bookId});

  final String bookId;

  Future<void> _confirmRemove(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('서재에서 빼기'),
        content: const Text('이 책을 서재에서 뺄까요? 이 책에서 모은 인용구는 그대로 남아요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('빼기'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).removeFromLibrary(bookId);
      if (!context.mounted) return;
      ref.invalidate(isInLibraryProvider(bookId));
      ref.invalidate(myLibraryProvider);
      ref.invalidate(myRatingProvider(bookId));
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('서재에서 뺐어요.')));
    } catch (_) {
      if (!context.mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('빼지 못했어요. 다시 시도해주세요.')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inLibrary = ref.watch(isInLibraryProvider(bookId)).value ?? false;
    if (!inLibrary) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'remove') _confirmRemove(context, ref);
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'remove', child: Text('서재에서 빼기')),
      ],
    );
  }
}

// ── PR30-A: 헤더 (큰 표지 + 중앙 메타 + 큰 별점) ────────────────

/// 큰 중앙 표지(140×200) + 제목·저자·출판사·연도·ISBN + (로그인 시) 큰 별점.
/// 읽기 시작/완독일은 별도 행으로 빠져 헤더 밖에 배치된다.
class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.book, required this.loggedIn});

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
          _BookRatingBlock(bookId: book.id),
        ],
        // PR30-C 친구 평균 별점 칩 — N≥3일 때만 자체 노출.
        _FriendsAvgRatingChip(bookId: book.id),
      ],
    );
  }
}

/// 헤더 중앙의 별점 블록 — "내 별점" 라벨 + 큰 별 5개(32pt) + "N / 5" 텍스트.
/// `myRatingProvider`를 watch하고 탭 시 `setMyRating` → invalidate. 이 책의 다른
/// 화면(서재 등)도 갱신되게 `myLibraryProvider`도 invalidate.
class _BookRatingBlock extends ConsumerStatefulWidget {
  const _BookRatingBlock({required this.bookId});

  final String bookId;

  @override
  ConsumerState<_BookRatingBlock> createState() => _BookRatingBlockState();
}

class _BookRatingBlockState extends ConsumerState<_BookRatingBlock> {
  bool _busy = false;

  Future<void> _rate(int? value) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(bookRepositoryProvider).setMyRating(widget.bookId, value);
      if (!mounted) return;
      ref.invalidate(myRatingProvider(widget.bookId));
      ref.invalidate(myLibraryProvider);
      ref.invalidate(isInLibraryProvider(widget.bookId));
    } on BookRepositoryException catch (e) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'NOT_AUTHENTICATED'
                  ? '로그인이 필요해요.'
                  : '별점을 저장하지 못했어요.',
            ),
          ),
        );
    } catch (_) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('별점을 저장하지 못했어요. 다시 시도해주세요.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(myRatingProvider(widget.bookId)).value;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('내 별점', style: textTheme.labelMedium),
        const SizedBox(height: 4),
        StarRating(
          rating: rating,
          size: 32,
          onRated: _busy ? null : _rate,
        ),
        if (rating != null) ...[
          const SizedBox(height: 2),
          Text(
            '$rating / 5',
            style: textTheme.bodySmall?.copyWith(color: AppColors.primary500),
          ),
        ],
      ],
    );
  }
}

// ── PR30-A: 인용구 hero 카드 (3-state) ─────────────────────────

/// 책 상세 헤더 직하의 큰 인용 카드. 우선순위:
/// (1) 내가 이 책에서 모은 인용구 중 최신 = 큰 따옴표 카드. 잠긴 인용(text==null)은
///     건너뛴다.
/// (2) 알라딘 description의 첫 문단 = 출판사 소개 미리보기 카드(아래 "설명" 섹션과
///     의도된 중복 — UX-B 권고).
/// (3) 둘 다 없으면 "이 책의 첫 인용구를 남겨주세요" CTA 카드.
class _QuoteHeroCard extends ConsumerWidget {
  const _QuoteHeroCard({required this.book});

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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.accent50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.accent200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '“',
            style: TextStyle(
              fontFamily: AppFonts.quote,
              fontSize: 36,
              height: 1,
              color: AppColors.accent400,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: AppFonts.quote,
              fontSize: AppFontSize.base,
              height: AppLineHeight.relaxed,
              color: AppColors.accent800,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (page != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'p.$page',
                style: textTheme.labelSmall
                    ?.copyWith(color: AppColors.accent700),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.secondary50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primary200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '출판사 소개',
            style: textTheme.labelSmall
                ?.copyWith(color: AppColors.primary500),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              height: AppLineHeight.relaxed,
              color: AppColors.primary800,
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
          color: AppColors.accent50,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.accent200,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.format_quote_rounded,
              color: AppColors.accent500,
              size: 28,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이 책의 첫 인용구를 남겨주세요',
                    style: textTheme.titleSmall
                        ?.copyWith(color: AppColors.accent800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    loggedIn ? '읽다 마음에 든 한 줄을 한 손에 모아둘 수 있어요.' : '로그인하면 한 줄을 모을 수 있어요.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.primary600),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accent500,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ── PR30-B: 액션 행 (인용구 추가 + 서재 담기 1줄) ─────────────────────

/// "이 책 인용구 추가"(주) + "서재에 담기"(보조)를 1줄 Row로 묶는다. 미로그인이나
/// 이미 서재에 있는 책이면 보조 측 위젯이 알아서 자체 렌더(`_LibraryActionButton`이
/// 칩 형태로 자동 전환). deep link 진입(fromShare=true)이면 상단 큰 CTA로
/// 이미 노출되므로 보조 버튼은 표시하지 않는다(이 위젯 자체를 부르지 않는다).
class _PrimaryActionRow extends StatelessWidget {
  const _PrimaryActionRow({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _AddQuoteButton(bookId: bookId),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          flex: 2,
          child: _LibraryActionButton(bookId: bookId, prominent: false),
        ),
      ],
    );
  }
}

// ── PR30-B: 기본정보 그리드 (페이지/출간/카테고리/ISBN 2×2) ────────────

/// 책 메타데이터를 2×2 그리드로 정돈. 알라딘이 채워주지 않은 빈 칸은 "—"
/// 표시(클릭 불가), 단 페이지 칸은 미수집 시 입력 BottomSheet를 띄우는 액션으로.
class _BookInfoGrid extends ConsumerWidget {
  const _BookInfoGrid({required this.book});

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
class _PurchaseLinksRow extends StatelessWidget {
  const _PurchaseLinksRow({required this.isbn13});

  final String isbn13;

  Future<void> _open(BuildContext context, String? url, String name) async {
    if (url == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$name 페이지를 열 수 없어요.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kyobo = buildBookPurchaseUrl(isbn13);
    final aladin = buildAladinSearchUrl(isbn13);
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _open(context, kyobo, '교보문고'),
            icon: const Icon(Icons.menu_book_outlined, size: 16),
            label: const Text('교보문고'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary700,
              side: const BorderSide(color: AppColors.primary200, width: 1.5),
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
              foregroundColor: AppColors.primary700,
              side: const BorderSide(color: AppColors.primary200, width: 1.5),
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
    final tile = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: AppColors.secondary100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(color: AppColors.primary500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: emphasized ? AppColors.accent600 : AppColors.primary800,
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

// ── PR30-C: 친구 평균 별점 칩 ─────────────────────────────────

/// 헤더 별점 블록 아래에 "친구만의 평균 ★4.2 (N=5)" 노출. N≥3 가드로 표본
/// 부족 오해 회피. 라벨에 "친구만의"를 명시해 왓챠 평균 같은 대중 평점과 혼동
/// 되지 않게 한다(매니저 모드 합의).
class _FriendsAvgRatingChip extends ConsumerWidget {
  const _FriendsAvgRatingChip({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendsAvgRatingProvider(bookId));
    final data = async.value;
    if (data == null || data.n < 3) return const SizedBox.shrink();
    final avg = data.avg.toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondary100,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.primary200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 16,
              color: AppColors.accent500,
            ),
            const SizedBox(width: 4),
            Text(
              '친구만의 평균 $avg',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(N=${data.n})',
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.primary500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PR30-C: 읽기 진행 strip ─────────────────────────────────────

/// `started_at`이 있고 `finished_at`이 없는 상태(=지금 읽는 중)에만 노출.
/// 경과일 + 미니 CTA로 매일 펼쳐보게 만든다. PM-B 권고(매일 열게 함).
class _ReadingProgressStrip extends ConsumerWidget {
  const _ReadingProgressStrip({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(readingDatesProvider(bookId)).value;
    if (dates == null) return const SizedBox.shrink();
    if (!dates.hasStarted || dates.hasFinished) {
      return const SizedBox.shrink();
    }
    final started = dates.startedAt!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = today.difference(started).inDays + 1; // 시작 당일을 1일째로

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.accent200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.menu_book_rounded,
              size: 16,
              color: AppColors.accent600,
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                '$days일째 읽는 중',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent600,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => context.push('/quote/new?bookId=$bookId'),
              child: const Text('오늘 한 줄 ▸'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PR30-C: 무드 summary chips ────────────────────────────────

/// 이 책에서 내가 모은 인용구에 자주 붙인 무드 top 3. 인용구·무드가 비면 hide.
/// 신규 백엔드 없이 `bookQuotesProvider`만 사용 — V1.0 안전 범위.
class _MoodSummaryChips extends ConsumerWidget {
  const _MoodSummaryChips({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quotes =
        ref.watch(bookQuotesProvider(bookId)).value ?? const <Quote>[];
    if (quotes.isEmpty) return const SizedBox.shrink();
    final counts = <QuoteMood, int>{};
    for (final q in quotes) {
      for (final m in q.moods) {
        counts[m] = (counts[m] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return const SizedBox.shrink();
    final top = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final shown = top.take(3).toList();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s3),
      child: Wrap(
        spacing: AppSpacing.s2,
        runSpacing: 4,
        children: [
          for (final e in shown)
            // PR4 — 탭하면 서재 인용구 탭의 해당 무드 단면으로 navigation.
            InkWell(
              onTap: () => context.push(
                '/library?tab=quotes&mood=${e.key.name}',
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s2,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary100,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(color: AppColors.primary200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(e.key.icon, size: 14, color: AppColors.primary600),
                    const SizedBox(width: 4),
                    Text(
                      e.key.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${e.value}',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary500),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── PR18-D → PR30-B: "이 책을 담은 친구 N명" inline chip ──────────────

/// "이 책에서 모은 구절" 섹션 헤더의 오른쪽 inline chip. N≥1일 때만 자체 렌더.
/// 탭하면 시트 미니리스트로 친구 프로필을 보여준다 (시트는 동일 — `_FriendsWithBookSheet`).
class _FriendsWithBookChip extends ConsumerWidget {
  const _FriendsWithBookChip({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCount = ref.watch(friendsWithBookCountProvider(bookId));
    final n = asyncCount.value ?? 0;
    if (n <= 0) return const SizedBox.shrink();
    return InkWell(
      onTap: () => _openFriendsWithBookSheet(context, bookId),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s2,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.secondary100,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: AppColors.primary200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.group_outlined,
              size: 14,
              color: AppColors.primary600,
            ),
            const SizedBox(width: 4),
            Text(
              '친구 $n명도 담음',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              size: 14,
              color: AppColors.primary500,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openFriendsWithBookSheet(BuildContext context, String bookId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _FriendsWithBookSheet(bookId: bookId),
  );
}

class _FriendsWithBookSheet extends ConsumerWidget {
  const _FriendsWithBookSheet({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(friendsWithBookProvider(bookId));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Column(
        children: [
          const SizedBox(height: AppSpacing.s2),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.primary300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: Text('이 책을 담은 친구', style: AppTextStyles.headlineMedium),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.accent500),
              ),
              error: (_, _) => Center(
                child: Text(
                  '목록을 불러오지 못했어요.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.primary500),
                ),
              ),
              data: (profiles) {
                if (profiles.isEmpty) {
                  return Center(
                    child: Text(
                      '아직 이 책을 담은 친구가 없어요',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.primary500),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  itemCount: profiles.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      _FriendsWithBookTile(profile: profiles[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendsWithBookTile extends StatelessWidget {
  const _FriendsWithBookTile({required this.profile});

  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName ?? '(이름 없음)';
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.accent200,
        backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false)
            ? NetworkImage(profile.avatarUrl!)
            : null,
        child: (profile.avatarUrl?.isNotEmpty ?? false)
            ? null
            : Text(
                initial,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary900,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      title: Text(name, style: AppTextStyles.bodyLarge),
      onTap: () {
        Navigator.of(context).pop();
        context.push('/u/${profile.id}');
      },
    );
  }
}
