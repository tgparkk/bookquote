// 책 검색 상태 컨트롤러.
//
// `bookSearchQueryProvider`로 외부에서 검색어를 set하면
// `bookSearchProvider(query)`가 결과를 비동기로 노출한다.
// 캐시 전략:
//   1) public.books에서 title/author ilike 사전 조회 (알라딘 절감)
//   2) 결과가 부족하면 Edge Function `aladin-search` 호출
//   3) Riverpod 자동 캐시 (같은 query 재진입 시 재호출 X — autoDispose 사용)
// 페이지네이션은 `bookSearchPagedProvider((query, page))` family로 분리.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/aladin_dto.dart';
import '../data/book_repository.dart';
import '../domain/book.dart';

/// UI에서 텍스트필드 onChanged 후 debounce를 거쳐 set한다.
class BookSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

final bookSearchQueryProvider =
    NotifierProvider<BookSearchQueryNotifier, String>(BookSearchQueryNotifier.new);

/// 단일 페이지 검색 결과 + 캐시 사전조회 책 목록을 합쳐 노출.
final bookSearchProvider = FutureProvider.autoDispose<BookSearchResult>((ref) async {
  final query = ref.watch(bookSearchQueryProvider).trim();
  if (query.length < 2) return const BookSearchResult.empty();

  final repo = ref.read(bookRepositoryProvider);

  // 캐시·원격을 동시에 호출. UI는 둘이 합쳐진 결과를 받음.
  final cachedFuture = _safeCached(repo, query);
  final remoteFuture = _safeRemote(repo, query);

  final cached = await cachedFuture;
  final remote = await remoteFuture;

  // 같은 isbn13은 캐시(이미 영속화) 우선. dto는 캐시에 없는 것만 표시.
  final cachedIsbns = cached.map((b) => b.isbn13).toSet();
  final remoteFiltered =
      remote.items.where((dto) => !cachedIsbns.contains(dto.isbn13)).toList();

  return BookSearchResult(
    cached: cached,
    fresh: remoteFiltered,
    totalRemote: remote.totalResults,
  );
});

Future<List<Book>> _safeCached(BookRepository repo, String query) async {
  try {
    return await repo.findCachedByQuery(query);
  } on BookRepositoryException {
    return const [];
  }
}

Future<AladinSearchResponse> _safeRemote(BookRepository repo, String query) async {
  try {
    return await repo.searchBooks(query: query);
  } on BookRepositoryException catch (e) {
    if (e.code == 'NOT_FOUND') {
      return const AladinSearchResponse(
        items: [],
        totalResults: 0,
        page: 1,
        size: 20,
      );
    }
    rethrow;
  }
}

class BookSearchResult {
  const BookSearchResult({
    required this.cached,
    required this.fresh,
    required this.totalRemote,
  });

  const BookSearchResult.empty()
      : cached = const [],
        fresh = const [],
        totalRemote = 0;

  /// 이미 `public.books`에 있는 책 (탭 시 즉시 상세로 이동 가능).
  final List<Book> cached;

  /// 알라딘에서 새로 가져온 책 (탭 시 upsert 후 상세로 이동).
  final List<AladinBookDto> fresh;

  /// 알라딘 전체 결과 수 (페이지네이션 안내용).
  final int totalRemote;

  bool get isEmpty => cached.isEmpty && fresh.isEmpty;
}
