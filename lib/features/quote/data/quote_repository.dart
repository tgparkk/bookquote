// 인용구 데이터 레이어.
//
// quotes 테이블 CRUD. RLS가 `auth.uid() = user_id`를 강제하므로 select/update/delete는
// 자동으로 본인 것만. 외부 호출은 모두 `supabase.from('quotes')`. JWT는 SDK가 자동 첨부.
// `book_repository.dart`의 패턴(도메인 예외 + Provider)을 미러링.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/quote.dart';
import '../domain/quote_mood.dart';

class QuoteRepositoryException implements Exception {
  QuoteRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'QuoteRepositoryException($code): $message';
}

/// 홈 피드·인용 목록 페이지네이션 커서. `(created_at desc, id desc)` 기준.
typedef QuoteCursor = ({DateTime createdAt, String id});

class QuoteRepository {
  QuoteRepository(this._client);

  final SupabaseClient _client;

  static const _table = 'quotes';

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw QuoteRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    return uid;
  }

  /// 새 인용구 생성. 반환은 영속화된 [Quote]. 비로그인이면 'NOT_AUTHENTICATED'.
  /// 책 미연결(`bookId == null`)도 허용 — `manualBookText`로 대체하거나 둘 다 null도 OK.
  Future<Quote> createQuote(QuoteInput input) async {
    final uid = _requireUid();
    final payload = <String, dynamic>{...input.toJson(), 'user_id': uid};
    try {
      final row = await _client.from(_table).insert(payload).select().single();
      return Quote.fromJson(row);
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('CREATE_FAILED', e.message);
    }
  }

  /// 인용구 일부 수정. 전달한 필드만 패치한다. `clearBook: true`면 책 연결 해제.
  Future<Quote> updateQuote(
    String id, {
    String? text,
    int? page,
    Set<QuoteMood>? moods,
    String? bookId,
    String? manualBookText,
    bool clearBook = false,
  }) async {
    _requireUid();
    final patch = <String, dynamic>{
      'text': ?text,
      'page': ?page,
      'moods': ?moods?.map((m) => m.name).toList(),
      if (clearBook) 'book_id': null else 'book_id': ?bookId,
      'manual_book_text': ?manualBookText,
    };
    if (patch.isEmpty) {
      final current = await getById(id);
      if (current == null) {
        throw QuoteRepositoryException('FETCH_FAILED', '인용구를 찾지 못했어요.');
      }
      return current;
    }
    try {
      final row = await _client
          .from(_table)
          .update(patch)
          .eq('id', id)
          .select()
          .single();
      return Quote.fromJson(row);
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('UPDATE_FAILED', e.message);
    }
  }

  Future<void> deleteQuote(String id) async {
    _requireUid();
    try {
      await _client.from(_table).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('DELETE_FAILED', e.message);
    }
  }

  /// 단건 조회 — 카드 에디터(`/quote/:id/card`) 등. RLS상 본인 것만 반환.
  Future<Quote?> getById(String id) async {
    try {
      final row =
          await _client.from(_table).select().eq('id', id).maybeSingle();
      return row == null ? null : Quote.fromJson(row);
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('FETCH_FAILED', e.message);
    }
  }

  /// 내 인용구 목록. cursor-after(`(created_at, id)` desc), 기본 15개 (offset 금지).
  /// [bookId] 지정 시 그 책 것만, [moods]가 비어있지 않으면 그 무드 중 하나라도 가진 것만.
  Future<List<Quote>> listMyQuotes({
    String? bookId,
    Set<QuoteMood>? moods,
    QuoteCursor? after,
    int limit = 15,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    try {
      var query = _client.from(_table).select().eq('user_id', uid);
      if (bookId != null) query = query.eq('book_id', bookId);
      if (moods != null && moods.isNotEmpty) {
        query = query.overlaps('moods', moods.map((m) => m.name).toList());
      }
      if (after != null) {
        final ts = after.createdAt.toUtc().toIso8601String();
        // (created_at, id) < (after.createdAt, after.id) — 튜플 비교 에뮬레이션
        query = query
            .or('created_at.lt.$ts,and(created_at.eq.$ts,id.lt.${after.id})');
      }
      final rows = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      return rows.map((r) => Quote.fromJson(r)).toList();
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('LIST_FAILED', e.message);
    }
  }
}

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(supabase);
});
