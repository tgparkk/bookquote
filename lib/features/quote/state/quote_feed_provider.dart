// 홈 "내 인용 피드" — cursor-after 무한스크롤 누적 상태.
//
// `Notifier<AsyncValue<List<QuoteWithBook>>>` — build()에서 첫 페이지를 비동기 로드,
// loadMore()로 다음 페이지를 append. autoDispose 아님(탭 전환에도 살아있게 — 셸 브랜치
// 유지와 정합). 새 인용구 저장/삭제 후 화면이 `ref.invalidate(quoteFeedProvider)` 또는
// removeLocal로 갱신.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quote_repository.dart';

class QuoteFeedNotifier extends Notifier<AsyncValue<List<QuoteWithBook>>> {
  static const _pageSize = 15;

  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _loadingMore;

  @override
  AsyncValue<List<QuoteWithBook>> build() {
    _hasMore = true;
    _loadingMore = false;
    _loadInitial();
    return const AsyncValue.loading();
  }

  Future<void> _loadInitial() async {
    try {
      final page = await ref
          .read(quoteRepositoryProvider)
          .listMyQuotesWithBook(limit: _pageSize);
      _hasMore = page.length == _pageSize;
      state = AsyncValue.data(page);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// 다음 페이지 append. 이미 로딩 중이거나 더 없으면 무시. 실패는 조용히
  /// (현재 목록 유지 — 다시 스크롤하면 재시도).
  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null || current.isEmpty) return;
    _loadingMore = true;
    try {
      final last = current.last.quote;
      final page = await ref.read(quoteRepositoryProvider).listMyQuotesWithBook(
            after: (createdAt: last.createdAt, id: last.id),
            limit: _pageSize,
          );
      _hasMore = page.length == _pageSize;
      state = AsyncValue.data([...current, ...page]);
    } catch (_) {
      // 무시 — 현재 목록 유지
    } finally {
      _loadingMore = false;
    }
  }

  /// pull-to-refresh — 현재 목록을 화면에 유지한 채 첫 페이지 다시 로드.
  Future<void> refresh() async {
    _hasMore = true;
    await _loadInitial();
  }

  /// 낙관적 삭제 — UI에서 즉시 제거. (실제 삭제는 호출자가 repository로.)
  void removeLocal(String quoteId) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(
      current.where((e) => e.quote.id != quoteId).toList(),
    );
  }
}

final quoteFeedProvider =
    NotifierProvider<QuoteFeedNotifier, AsyncValue<List<QuoteWithBook>>>(
  QuoteFeedNotifier.new,
);
