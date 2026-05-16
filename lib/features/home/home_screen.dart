// 홈 화면 — "내 인용 피드".
//
// 내가 모은 인용구가 시간순으로 쌓이는 곳. cursor-after 무한스크롤, pull-to-refresh,
// 빈 상태 CTA. 친구 follow 타임라인은 V1.5에 여기 합류 — V1 홈은 내 인용구만, Realtime
// 없음 (DECISIONS 2026-05-12). FAB 없음(BottomNav [＋] sentinel과 중복).
// 앱이 포그라운드로 돌아올 때 오프라인 아웃박스를 best-effort flush.
//
// 설계: docs/design/screens/home.md

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/tokens.dart';
import '../quote/data/quote_outbox.dart';
import '../quote/data/quote_repository.dart';
import '../quote/presentation/widgets/quote_list_card.dart';
import '../quote/state/quote_feed_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _flushOutbox());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _flushOutbox();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      ref.read(quoteFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _flushOutbox() async {
    try {
      final outbox = await ref.read(quoteOutboxProvider.future);
      if (outbox.pending().isEmpty) return;
      final result = await outbox.flush(ref.read(quoteRepositoryProvider));
      if (!mounted) return;
      if (result.sent > 0) ref.invalidate(quoteFeedProvider);
    } catch (_) {/* best-effort */}
  }

  Future<void> _confirmDelete(QuoteWithBook entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('인용구 삭제'),
        content: const Text('이 인용구를 삭제할까요? 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('삭제', style: TextStyle(color: AppColors.semanticError)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    ref.read(quoteFeedProvider.notifier).removeLocal(entry.quote.id);
    if (_expandedId == entry.quote.id) setState(() => _expandedId = null);
    try {
      await ref.read(quoteRepositoryProvider).deleteQuote(entry.quote.id);
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('인용구를 삭제했어요.')));
    } catch (_) {
      if (mounted) ref.invalidate(quoteFeedProvider); // 삭제 실패 — 목록 복구
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('삭제하지 못했어요. 다시 시도해주세요.')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(quoteFeedProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('책귀')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(quoteFeedProvider.notifier).refresh(),
        child: feed.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.accent500),
          ),
          error: (e, _) => _errorView(context),
          data: (entries) =>
              entries.isEmpty ? _emptyView(context) : _feedList(entries),
        ),
      ),
    );
  }

  Widget _feedList(List<QuoteWithBook> entries) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.s4),
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s3),
      itemBuilder: (context, i) {
        final e = entries[i];
        return QuoteListCard(
          quote: e.quote,
          book: e.book,
          expanded: _expandedId == e.quote.id,
          onTap: () => setState(
            () => _expandedId = _expandedId == e.quote.id ? null : e.quote.id,
          ),
          onShare: () => context.push('/quote/${e.quote.id}/share'),
          onMakeCard: () => context.push('/quote/${e.quote.id}/card'),
          onDelete: () => _confirmDelete(e),
        );
      },
    );
  }

  Widget _emptyView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.16),
        Icon(Icons.format_quote, size: 48, color: AppColors.primary300),
        const SizedBox(height: AppSpacing.s4),
        Text('아직 인용구가 없어요',
            textAlign: TextAlign.center, style: textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.s2),
        Text('좋아하는 책의 한 줄을 저장해보세요.',
            textAlign: TextAlign.center, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.s6),
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent500,
              foregroundColor: AppColors.secondary50,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8,
                vertical: AppSpacing.s3,
              ),
            ),
            onPressed: () => context.push('/quote/new'),
            child: const Text('＋ 인용구 추가'),
          ),
        ),
      ],
    );
  }

  Widget _errorView(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.28),
        Text('인용구를 불러오지 못했어요',
            textAlign: TextAlign.center, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.s3),
        Center(
          child: OutlinedButton(
            onPressed: () => ref.invalidate(quoteFeedProvider),
            child: const Text('다시 시도'),
          ),
        ),
      ],
    );
  }
}
