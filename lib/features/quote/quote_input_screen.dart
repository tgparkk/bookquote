// 인용구 입력 화면 (`/quote/new[?bookId=]`).
//
// 직접 타이핑 또는 OS 기능(iOS Live Text·구글렌즈)으로 복사한 텍스트 붙여넣기로
// 한 구절을 책귀에 넣는다. 책 연결(검색 시트 재사용)·페이지·무드는 선택. 저장 후
// 곧장 카드 만들기로 이어진다. 앱 내장 OCR은 안 쓴다 (DECISIONS 2026-05-11).
//
// 설계: docs/design/screens/quote-input.md

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../book/data/book_repository.dart';
import '../book/domain/book.dart';
import '../book/presentation/book_search_sheet.dart';
import '../book/presentation/widgets/book_cover.dart';
import 'data/quote_draft.dart';
import 'data/quote_repository.dart';
import 'domain/quote.dart';
import 'domain/quote_mood.dart';
import 'presentation/widgets/mood_chips.dart';
import 'state/quote_feed_provider.dart';
import 'state/quote_providers.dart';

class QuoteInputScreen extends ConsumerStatefulWidget {
  const QuoteInputScreen({super.key, this.bookId, this.quoteId});

  /// 진입 시 미리 연결할 책의 ID (책 상세/서재의 "이 책 인용구 추가").
  final String? bookId;

  /// 편집 모드 — 이 값이 있으면 기존 quote를 prefill하고 저장 시 update 호출.
  /// 신규 작성에선 null. (백로그: docs/STAGES.md "인용구 [수정]")
  final String? quoteId;

  @override
  ConsumerState<QuoteInputScreen> createState() => _QuoteInputScreenState();
}

class _QuoteInputScreenState extends ConsumerState<QuoteInputScreen>
    with WidgetsBindingObserver {
  static const _maxLen = 2000;
  static const _warnLen = 1800;

  final _textController = TextEditingController();
  final _pageController = TextEditingController();

  Book? _book;
  final _moods = <QuoteMood>{};
  QuoteSource _source = QuoteSource.manual;

  bool _showPasteBanner = false;
  bool _restoredDraft = false;
  Timer? _draftDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _draftDebounce?.cancel();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  bool get _isEditMode => widget.quoteId != null;

  // ── 초기화 ──────────────────────────────────────────────

  Future<void> _bootstrap() async {
    if (_isEditMode) {
      // 편집 모드: draft 무시(편집용 draft는 V1.x 백로그) + 기존 quote prefill.
      await _loadExistingQuote();
      return;
    }
    await _maybeRestoreDraft();
    if (mounted && widget.bookId != null && _book == null) {
      try {
        final book =
            await ref.read(bookRepositoryProvider).getById(widget.bookId!);
        if (mounted && book != null) setState(() => _book = book);
      } catch (_) {
        // 책 prefill 실패는 조용히 — 사용자가 다시 연결할 수 있다
      }
    }
    await _checkClipboard();
  }

  /// 편집 모드 — `widget.quoteId`로 기존 인용구를 가져와 입력 필드를 채운다.
  /// 책도 연결돼 있으면 함께 prefill. 실패 시 SnackBar로 알리고 화면 닫음.
  Future<void> _loadExistingQuote() async {
    try {
      final quote =
          await ref.read(quoteByIdProvider(widget.quoteId!).future);
      if (!mounted) return;
      if (quote == null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('이 인용구를 찾지 못했어요.')));
        Navigator.of(context).maybePop();
        return;
      }
      _textController.text = quote.text;
      _textController.selection =
          TextSelection.collapsed(offset: _textController.text.length);
      _pageController.text = quote.page?.toString() ?? '';
      _moods
        ..clear()
        ..addAll(quote.moods);
      _source = quote.source;
      if (quote.bookId != null) {
        try {
          _book =
              await ref.read(bookRepositoryProvider).getById(quote.bookId!);
        } catch (_) {/* 책 prefill 실패 무시 */}
      }
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('인용구를 불러오지 못했어요.')),
        );
    }
  }

  Future<void> _maybeRestoreDraft() async {
    if (_restoredDraft) return;
    _restoredDraft = true;
    try {
      final store = await ref.read(quoteDraftStoreProvider.future);
      final draft = store.load();
      if (draft == null || draft.text.trim().isEmpty || !mounted) return;
      _textController.text = draft.text;
      _textController.selection =
          TextSelection.collapsed(offset: _textController.text.length);
      _pageController.text = draft.page?.toString() ?? '';
      _moods
        ..clear()
        ..addAll(draft.moods);
      _source = draft.source;
      if (draft.bookId != null) {
        try {
          _book =
              await ref.read(bookRepositoryProvider).getById(draft.bookId!);
        } catch (_) {/* ignore */}
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: const Text('작성 중이던 인용구를 불러왔어요.'),
            action: SnackBarAction(
              label: '지우기',
              onPressed: () async {
                _textController.clear();
                _pageController.clear();
                setState(() {
                  _moods.clear();
                  _book = null;
                });
                try {
                  (await ref.read(quoteDraftStoreProvider.future)).clear();
                } catch (_) {/* ignore */}
              },
            ),
          ),
        );
    } catch (_) {/* ignore */}
  }

  // ── 클립보드 붙여넣기 감지 ───────────────────────────────

  Future<void> _checkClipboard() async {
    if (_textController.text.trim().isNotEmpty) return;
    bool? has;
    try {
      has = await Clipboard.hasStrings();
    } catch (_) {
      has = null;
    }
    if (!mounted) return;
    if (has == true && !_showPasteBanner) {
      setState(() => _showPasteBanner = true);
    }
  }

  Future<void> _pasteFromClipboard() async {
    String? text;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      text = data?.text?.trim();
    } catch (_) {
      text = null;
    }
    if (!mounted) return;
    setState(() => _showPasteBanner = false);
    if (text == null || text.isEmpty) return;

    // 2000자 초과는 runes 기준으로 잘라넣고 안내 — DB CHECK(text 1~2000) 위반
    // 차단 + 사용자가 직접 잘라야 하는 마찰 해소(B6).
    final runeCount = text.runes.length;
    final wasTruncated = runeCount > _maxLen;
    if (wasTruncated) {
      text = String.fromCharCodes(text.runes.take(_maxLen));
    }

    _source = QuoteSource.clipboard;
    _textController.text = text;
    _textController.selection =
        TextSelection.collapsed(offset: _textController.text.length);

    if (wasTruncated) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          content: Text('$_maxLen자가 넘어 앞부분만 붙여넣었어요.'),
        ));
    }
  }

  // ── 입력 변경 ──────────────────────────────────────────

  void _onTextChanged() {
    if (_showPasteBanner && _textController.text.isNotEmpty) {
      setState(() => _showPasteBanner = false);
    } else {
      setState(() {}); // 글자수 카운터 · CTA 활성 상태 갱신
    }
    _scheduleDraftSave();
  }

  void _onPageChanged(String _) => _scheduleDraftSave();

  void _toggleMood(QuoteMood mood) {
    if (_moods.contains(mood)) {
      setState(() => _moods.remove(mood));
    } else if (_moods.length >= QuoteMood.maxPerQuote) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('무드는 최대 ${QuoteMood.maxPerQuote}개까지 고를 수 있어요.'),
          ),
        );
      return;
    } else {
      setState(() => _moods.add(mood));
    }
    _scheduleDraftSave();
  }

  Future<void> _pickBook() async {
    final book = await showBookSearchSheet(context);
    if (!mounted || book == null) return;
    setState(() => _book = book);
    _scheduleDraftSave();
  }

  // ── draft ──────────────────────────────────────────────

  bool get _hasEdits =>
      _textController.text.trim().isNotEmpty ||
      _book != null ||
      _pageController.text.trim().isNotEmpty ||
      _moods.isNotEmpty;

  QuoteInput _buildInput() => QuoteInput(
        text: _textController.text.trim(),
        bookId: _book?.id,
        page: int.tryParse(_pageController.text.trim()),
        source: _source,
        moods: _moods.toList(),
      );

  void _scheduleDraftSave() {
    if (_isEditMode) return;  // 편집 모드는 draft 안 만든다.
    _draftDebounce?.cancel();
    _draftDebounce = Timer(const Duration(seconds: 1), _saveDraft);
  }

  Future<void> _saveDraft() async {
    if (!mounted || !_hasEdits || _isEditMode) return;
    try {
      (await ref.read(quoteDraftStoreProvider.future)).save(_buildInput());
    } catch (_) {/* ignore — draft는 best-effort */}
  }

  Future<void> _clearDraft() async {
    if (_isEditMode) return;
    try {
      (await ref.read(quoteDraftStoreProvider.future)).clear();
    } catch (_) {/* ignore */}
  }

  // ── 저장 ───────────────────────────────────────────────

  Future<void> _submit({required bool thenCard}) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // page는 1 이상이어야 함 — DB CHECK(page > 0). 0 입력 시 generic 에러 대신
    // 명확히 안내하고 차단(B5).
    final pageText = _pageController.text.trim();
    if (pageText.isNotEmpty) {
      final page = int.tryParse(pageText);
      if (page != null && page <= 0) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(
            content: Text('쪽수는 1 이상이어야 해요. 비워두면 "모름"으로 저장돼요.'),
          ));
        return;
      }
    }
    _draftDebounce?.cancel();

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    final controller = ref.read(createQuoteControllerProvider.notifier);

    // ── 편집 모드 ── 기존 quote update + invalidate + pop으로 카드 디자인 복귀.
    if (_isEditMode) {
      try {
        await controller.submitUpdate(widget.quoteId!, _buildInput());
      } on QuoteRepositoryException catch (e) {
        if (!mounted) return;
        messenger
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(
              e.code == 'NOT_AUTHENTICATED'
                  ? '로그인이 필요해요.'
                  : '수정 저장에 실패했어요. 잠시 후 다시 시도해주세요.',
            ),
          ));
        return;
      } catch (_) {
        if (!mounted) return;
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('수정 저장에 실패했어요. 다시 시도해주세요.')),
          );
        return;
      }
      if (!mounted) return;
      ref
        ..invalidate(quoteFeedProvider)
        ..invalidate(quoteByIdProvider(widget.quoteId!));
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('수정 내용을 저장했어요.')));
      navigator.pop();
      return;
    }

    // ── 신규 작성 ──
    Quote? created;
    try {
      created = await controller.submit(_buildInput());
    } on QuoteRepositoryException catch (e) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'NOT_AUTHENTICATED'
                  ? '로그인이 필요해요.'
                  : '저장하지 못했어요. 잠시 후 다시 시도해주세요.',
            ),
          ),
        );
      return;
    } catch (_) {
      if (!mounted) return;
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('저장하지 못했어요. 다시 시도해주세요.')));
      return;
    }

    if (!mounted) return;
    await _clearDraft();
    ref.invalidate(quoteFeedProvider); // 홈 피드에 새 인용구 반영
    if (!mounted) return;

    if (created == null) {
      // 오프라인 — 아웃박스에 큐잉됨
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('오프라인이에요 — 연결되면 자동으로 저장돼요.')),
        );
      navigator.pop();
      return;
    }

    if (thenCard) {
      // 입력 화면을 카드 에디터로 치환 — 저장 끝난 입력 폼으로 되돌아오지 않게.
      router.pushReplacement('/quote/${created.id}/card');
    } else {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('인용구를 저장했어요.')));
      navigator.pop();
    }
  }

  // ── 뒤로가기 ────────────────────────────────────────────

  Future<void> _onLeaveRequested() async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('작성 중인 인용구'),
        content: const Text('작성 중인 인용구를 어떻게 할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('keep'),
            child: const Text('임시저장하고 나가기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: Text(
              '폐기',
              style: TextStyle(color: AppColors.semanticError),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('계속 쓰기'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'keep') {
      await _saveDraft();
      if (mounted) Navigator.of(context).pop();
    } else if (action == 'discard') {
      await _clearDraft();
      if (mounted) Navigator.of(context).pop();
    }
  }

  // ── build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final len = _textController.text.runes.length;
    final overLimit = len > _maxLen;
    final counterColor = overLimit
        ? AppColors.semanticError
        : len >= _warnLen
            ? AppColors.accent500
            : AppColors.primary400;
    final canSave = _textController.text.trim().isNotEmpty && !overLimit;
    final saving = ref.watch(createQuoteControllerProvider).isLoading;

    return PopScope(
      canPop: !_hasEdits,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onLeaveRequested();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: '닫기',
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(_isEditMode ? '인용구 수정' : '인용구 추가'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s4),
              child: Center(
                child: Text(
                  '$len / $_maxLen',
                  style: textTheme.labelSmall?.copyWith(color: counterColor),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s4,
              AppSpacing.s8,
            ),
            children: [
              // 인용구 본문
              TextField(
                controller: _textController,
                autofocus: true,
                enabled: !saving,
                minLines: 4,
                maxLines: 10,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontFamily: AppFonts.quote,
                  fontSize: AppFontSize.md,
                  height: AppLineHeight.relaxed,
                  color: AppColors.primary800,
                ),
                decoration: const InputDecoration(
                  hintText: "좋아하는 한 줄을 입력하거나, 아래 '붙여넣기'를 눌러보세요",
                ),
              ),
              if (overLimit)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.s2),
                  child: Text(
                    '인용구는 한 구절만 — 너무 길어요.',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppColors.semanticError),
                  ),
                ),
              if (_showPasteBanner) ...[
                const SizedBox(height: AppSpacing.s3),
                _PasteBanner(
                  onPaste: _pasteFromClipboard,
                  onDismiss: () => setState(() => _showPasteBanner = false),
                ),
              ],

              const SizedBox(height: AppSpacing.s4),

              // 책 연결
              _BookField(book: _book, onTap: saving ? null : _pickBook),

              const SizedBox(height: AppSpacing.s4),

              // 페이지 + 무드
              Row(
                children: [
                  Text('페이지', style: textTheme.bodyMedium),
                  const SizedBox(width: AppSpacing.s3),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: _pageController,
                      enabled: !saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '—',
                      ),
                      onChanged: _onPageChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s3),
              Text('무드 (선택, 최대 ${QuoteMood.maxPerQuote}개)',
                  style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.s2),
              MoodChips(selected: _moods, onToggle: _toggleMood),

              const SizedBox(height: AppSpacing.s8),

              // CTA — 편집 모드면 [수정 저장] 단일, 신규는 [카드 만들기 →] + [저장만]
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent500,
                  foregroundColor: AppColors.secondary50,
                  disabledBackgroundColor: AppColors.secondary600,
                  disabledForegroundColor: AppColors.primary400,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed:
                    (canSave && !saving) ? () => _submit(thenCard: true) : null,
                child: saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.secondary50,
                        ),
                      )
                    : Text(_isEditMode ? '수정 저장' : '카드 만들기 →'),
              ),
              if (!_isEditMode) ...[
                const SizedBox(height: AppSpacing.s2),
                TextButton(
                  onPressed: (canSave && !saving)
                      ? () => _submit(thenCard: false)
                      : null,
                  child: const Text('저장만 하기'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── 보조 위젯 ────────────────────────────────────────────

class _PasteBanner extends StatelessWidget {
  const _PasteBanner({required this.onPaste, required this.onDismiss});

  final VoidCallback onPaste;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.secondary300,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s3, AppSpacing.s2, AppSpacing.s2, AppSpacing.s2),
        child: Row(
          children: [
            Icon(Icons.content_paste, size: 18, color: AppColors.primary500),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                '클립보드에 텍스트가 있어요',
                style: textTheme.bodySmall?.copyWith(color: AppColors.primary600),
              ),
            ),
            TextButton(onPressed: onPaste, child: const Text('붙여넣기')),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: '닫기',
              onPressed: onDismiss,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _BookField extends StatelessWidget {
  const _BookField({required this.book, required this.onTap});

  final Book? book;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final book = this.book;
    final author = book?.author;
    return Material(
      color: AppColors.secondary100,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.primary100),
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
                    Icon(Icons.add, size: 20, color: AppColors.accent600),
                    const SizedBox(width: AppSpacing.s2),
                    Text('책 연결',
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.accent700)),
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
                            ?.copyWith(color: AppColors.accent600)),
                  ],
                ),
        ),
      ),
    );
  }
}
