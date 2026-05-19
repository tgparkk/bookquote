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
import '../../core/supabase/supabase_init.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/tokens.dart';
import '../follow/state/follow_providers.dart';
import '../profile/domain/profile.dart';
import '../profile/state/friend_providers.dart';
import '../quote/presentation/widgets/quote_list_card.dart';
import '../quote/state/quote_providers.dart';
import 'data/book_repository.dart';
import 'domain/book.dart';
import 'presentation/widgets/book_cover.dart';
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
    final author = book.author?.trim();
    final publisher = book.publisher?.trim();
    final pubDate = book.pubDate?.trim();
    final isbn = book.isbn13.trim();
    final description = book.description?.trim();
    final metaLine = [
      if (publisher != null && publisher.isNotEmpty) publisher,
      if (pubDate != null && pubDate.isNotEmpty) pubDate,
    ].join(' · ');

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
        // 헤더 — 표지 + 제목/저자/출판사·연도/ISBN (+로그인 시 별점)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BookCover(
              url: book.coverUrl,
              title: book.title,
              width: 96,
              height: 140,
            ),
            const SizedBox(width: AppSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title, style: textTheme.headlineMedium),
                  const SizedBox(height: AppSpacing.s2),
                  if (author != null && author.isNotEmpty)
                    Text(author, style: textTheme.bodyMedium),
                  if (metaLine.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(metaLine, style: textTheme.bodySmall),
                    ),
                  if (isbn.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s2),
                      child: Text('ISBN $isbn', style: textTheme.labelSmall),
                    ),
                  if (loggedIn) ...[
                    const SizedBox(height: AppSpacing.s3),
                    Text('내 별점', style: textTheme.labelMedium),
                    _BookRatingRow(bookId: book.id),
                    ReadingDatesRow(bookId: book.id),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s6),
        // "이 책 인용구 추가" — 이 화면의 주 행동
        _AddQuoteButton(bookId: book.id),
        if (!fromShare) ...[
          const SizedBox(height: AppSpacing.s2),
          _LibraryActionButton(bookId: book.id, prominent: false),
        ],
        // PR18-D — "이 책을 담은 친구 N명" — N≥1일 때만 자체 렌더(빈상태 회피)
        _FriendsWithBookRow(bookId: book.id),
        const SizedBox(height: AppSpacing.s8),
        // "이 책에서 모은 구절"
        _BookQuotesSection(bookId: book.id),
        // 설명 — 점진적 공개
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s8),
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
    final myUid = isSupabaseReady ? supabase.auth.currentUser?.id : null;
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

/// 책 상세 헤더의 별점 행. `myRatingProvider`를 watch하고 탭 시 `setMyRating` →
/// invalidate. 이 책의 다른 화면(서재 등)도 갱신되게 `myLibraryProvider`도 invalidate.
class _BookRatingRow extends ConsumerStatefulWidget {
  const _BookRatingRow({required this.bookId});

  final String bookId;

  @override
  ConsumerState<_BookRatingRow> createState() => _BookRatingRowState();
}

class _BookRatingRowState extends ConsumerState<_BookRatingRow> {
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
    return StarRating(
      rating: rating,
      size: 24,
      onRated: _busy ? null : _rate,
    );
  }
}

// ── PR18-D — "이 책을 담은 친구 N명" ───────────────────────────

/// 헤더 행 — N≥1일 때만 자체 렌더(빈상태 회피). 탭 = 시트 미니리스트.
class _FriendsWithBookRow extends ConsumerWidget {
  const _FriendsWithBookRow({required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCount = ref.watch(friendsWithBookCountProvider(bookId));
    final n = asyncCount.value ?? 0;
    if (n <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s6),
      child: InkWell(
        onTap: () => _openFriendsWithBookSheet(context, bookId),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.s2,
            horizontal: AppSpacing.s1,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.group_outlined,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  '이 책을 담은 친구 $n명',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.primary400,
              ),
            ],
          ),
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
