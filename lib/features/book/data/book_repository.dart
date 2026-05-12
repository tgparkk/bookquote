// 책 데이터 레이어.
//
// 1. `searchBooks(query)` — Edge Function `aladin-search` 호출, AladinBookDto 리스트
// 2. `lookupByIsbn(isbn)` — Edge Function lookup 모드
// 3. `upsertBook(dto)` — Supabase `upsert_book(book jsonb)` RPC, 영속화 후 도메인 Book 반환
// 4. `findCachedByQuery(query)` — `public.books`에서 title/author ilike 사전 조회
// 5. `getById(id)` — `public.books`에서 단건 조회
//
// 외부 호출은 모두 `supabase.functions.invoke` / `supabase.from(...)`. JWT는 SDK가
// 자동 첨부.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/book.dart';
import 'aladin_dto.dart';

class BookRepositoryException implements Exception {
  BookRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'BookRepositoryException($code): $message';
}

class BookRepository {
  BookRepository(this._client);

  final SupabaseClient _client;

  static const _searchFn = 'aladin-search';
  static const _booksTable = 'books';
  static const _userBooksTable = 'user_books';

  /// 알라딘 검색 (Edge Function 경유).
  Future<AladinSearchResponse> searchBooks({
    required String query,
    int page = 1,
    int size = 20,
  }) async {
    return _invokeAladin({
      'mode': 'search',
      'query': query,
      'page': page,
      'size': size,
    });
  }

  /// ISBN 단건 조회 (Edge Function lookup).
  Future<AladinSearchResponse> lookupByIsbn(String isbn) {
    return _invokeAladin({'mode': 'lookup', 'isbn': isbn});
  }

  /// 알라딘 응답 한 건을 `public.books`에 upsert. 반환은 영속화된 도메인 [Book].
  Future<Book> upsertBook(AladinBookDto dto) async {
    final payload = <String, dynamic>{
      'isbn13': dto.isbn13,
      if (dto.isbn10 != null) 'isbn10': dto.isbn10,
      'title': dto.title,
      if (dto.author != null) 'author': dto.author,
      if (dto.publisher != null) 'publisher': dto.publisher,
      if (dto.pubDate != null) 'pub_date': dto.pubDate,
      if (dto.coverUrl != null) 'cover_url': dto.coverUrl,
      if (dto.description != null) 'description': dto.description,
      if (dto.categoryName != null) 'category_name': dto.categoryName,
      'source': 'aladin',
      if (dto.itemId != null) 'source_id': dto.itemId,
    };
    try {
      final row = await _client.rpc('upsert_book', params: {'book': payload});
      // RPC가 row 단건 또는 List 반환 — supabase_flutter는 보통 Map 반환
      final map = row is List ? row.first as Map<String, dynamic> : row as Map<String, dynamic>;
      return Book.fromJson(map);
    } on PostgrestException catch (e) {
      throw BookRepositoryException('UPSERT_FAILED', e.message);
    }
  }

  /// 캐시된 books 테이블에서 title/author 부분일치로 미리 찾는다 (알라딘 호출 비용 절감).
  Future<List<Book>> findCachedByQuery(String query, {int limit = 5}) async {
    final pattern = '%${_escapeLike(query.trim())}%';
    try {
      final rows = await _client
          .from(_booksTable)
          .select()
          .or('title.ilike.$pattern,author.ilike.$pattern')
          .limit(limit);
      return rows.map((r) => Book.fromJson(r)).toList();
    } on PostgrestException catch (e) {
      throw BookRepositoryException('CACHE_QUERY_FAILED', e.message);
    }
  }

  Future<Book?> getById(String id) async {
    try {
      final row = await _client.from(_booksTable).select().eq('id', id).maybeSingle();
      if (row == null) return null;
      return Book.fromJson(row);
    } on PostgrestException catch (e) {
      throw BookRepositoryException('FETCH_FAILED', e.message);
    }
  }

  // ── 내 서재 ──────────────────────────────────────────

  /// 현재 로그인 사용자의 서재에 책을 추가한다. 이미 있으면 idempotent.
  /// 비로그인 상태면 [BookRepositoryException] 'NOT_AUTHENTICATED'.
  Future<void> addToLibrary(String bookId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw BookRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    try {
      await _client
          .from(_userBooksTable)
          .upsert({'user_id': uid, 'book_id': bookId}, onConflict: 'user_id,book_id');
    } on PostgrestException catch (e) {
      throw BookRepositoryException('ADD_LIBRARY_FAILED', e.message);
    }
  }

  /// 서재에서 제거.
  Future<void> removeFromLibrary(String bookId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client
          .from(_userBooksTable)
          .delete()
          .eq('user_id', uid)
          .eq('book_id', bookId);
    } on PostgrestException catch (e) {
      throw BookRepositoryException('REMOVE_LIBRARY_FAILED', e.message);
    }
  }

  /// 내 서재 책 목록. added_at desc.
  Future<List<Book>> listMyLibrary({int limit = 50}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    try {
      final rows = await _client
          .from(_userBooksTable)
          .select('book:books(*)')
          .eq('user_id', uid)
          .order('added_at', ascending: false)
          .limit(limit);
      return rows
          .map((r) => Book.fromJson(r['book'] as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw BookRepositoryException('LIST_LIBRARY_FAILED', e.message);
    }
  }

  Future<Book?> getByIsbn(String isbn13) async {
    try {
      final row = await _client
          .from(_booksTable)
          .select()
          .eq('isbn13', isbn13)
          .maybeSingle();
      if (row == null) return null;
      return Book.fromJson(row);
    } on PostgrestException catch (e) {
      throw BookRepositoryException('FETCH_FAILED', e.message);
    }
  }

  // ── 별점 ────────────────────────────────────────────

  /// 내가 이 책에 매긴 별점 (1~5). 안 매겼거나 비로그인이면 null.
  Future<int?> getMyRating(String bookId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from(_userBooksTable)
          .select('rating')
          .eq('user_id', uid)
          .eq('book_id', bookId)
          .maybeSingle();
      return (row?['rating'] as num?)?.toInt();
    } on PostgrestException catch (e) {
      throw BookRepositoryException('FETCH_FAILED', e.message);
    }
  }

  /// 별점을 매긴다(1~5). 그 책이 서재에 없으면 자동으로 추가된다.
  /// [rating]이 null이면 별점을 지운다(서재에는 그대로 둔다). 비로그인이면 'NOT_AUTHENTICATED'.
  Future<void> setMyRating(String bookId, int? rating) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw BookRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    if (rating != null && (rating < 1 || rating > 5)) {
      throw BookRepositoryException('VAL_INVALID', '별점은 1~5 사이여야 해요.');
    }
    try {
      if (rating == null) {
        await _client
            .from(_userBooksTable)
            .update({'rating': null})
            .eq('user_id', uid)
            .eq('book_id', bookId);
      } else {
        await _client.from(_userBooksTable).upsert(
          {'user_id': uid, 'book_id': bookId, 'rating': rating},
          onConflict: 'user_id,book_id',
        );
      }
    } on PostgrestException catch (e) {
      throw BookRepositoryException('SET_RATING_FAILED', e.message);
    }
  }

  Future<AladinSearchResponse> _invokeAladin(Map<String, dynamic> body) async {
    final FunctionResponse res;
    try {
      res = await _client.functions.invoke(_searchFn, body: body);
    } on FunctionException catch (e) {
      throw BookRepositoryException('UPSTREAM', e.details?.toString() ?? e.toString());
    }

    final data = res.data;
    if (data is Map<String, dynamic>) {
      // Edge Function이 status 200 + {error: ...}로 감싸 보내는 경우도 방어
      if (data['error'] is Map<String, dynamic>) {
        final err = EdgeError.fromJson(data['error'] as Map<String, dynamic>);
        throw BookRepositoryException(err.code, err.message);
      }
      return AladinSearchResponse.fromJson(data);
    }
    throw BookRepositoryException('PARSE', 'Unexpected response shape: $data');
  }

  String _escapeLike(String input) =>
      input.replaceAllMapped(RegExp(r'[\\%_]'), (m) => '\\${m[0]}');
}

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepository(supabase);
});
