// 인용구 데이터 레이어.
//
// quotes 테이블 CRUD. RLS가 `auth.uid() = user_id`를 강제하므로 select/update/delete는
// 자동으로 본인 것만. 외부 호출은 모두 `supabase.from('quotes')`. JWT는 SDK가 자동 첨부.
// `book_repository.dart`의 패턴(도메인 예외 + Provider)을 미러링.
//
// PR16-B: E2EE 분기. [QuoteInput.isPrivate]=true면 createQuote/updateQuote가 본문을
// 캐시된 마스터키로 AES-256-GCM 암호화해 *_encrypted 컬럼에만 저장하고 평문 컬럼은
// NULL로 남긴다. 읽기 측은 [_decryptIfPrivate]로 row 내 ciphertext를 풀어 Quote.text를
// 채운다(키 없으면 null로 — UI는 PR16-C에서 [isPrivate]로 잠금 fallback view 분기).
// outbox 큐잉은 [QuoteOutbox]가 enqueue 직전에 미리 암호화한 형태로 SharedPreferences에
// 넣고 flush 시 [insertPrivatePayload]로 직접 INSERT — 평문이 prefs에 일절 머물지 않음.

import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' show SecretKey;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../book/domain/book.dart';
import '../../crypto/data/key_derivation.dart' show kKdfVersion;
import '../../crypto/data/key_service.dart';
import '../../crypto/data/quote_cipher.dart';
import '../../crypto/domain/envelope.dart' show decodePgBytea, encodePgBytea;
import '../../crypto/state/crypto_providers.dart';
import '../domain/quote.dart';
import '../domain/quote_mood.dart';

typedef _CryptoCtx = ({SecretKey key, QuoteCipher cipher});

class QuoteRepositoryException implements Exception {
  QuoteRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'QuoteRepositoryException($code): $message';
}

/// 홈 피드·인용 목록 페이지네이션 커서. `(created_at desc, id desc)` 기준.
typedef QuoteCursor = ({DateTime createdAt, String id});

/// 인용구 + 연결된 책(있으면). 홈 피드·인용 목록 카드 렌더용 — N+1 회피.
typedef QuoteWithBook = ({Quote quote, Book? book});

/// 내 인용구 무드 통계 — 전체 수 + 무드별 개수 (서재 인용 뷰 필터 칩용).
typedef MoodCounts = ({int total, Map<QuoteMood, int> byMood});

/// `my_quote_mood_counts` RPC 결과 행들을 파싱 — `'__total__'` 행은 전체 수,
/// 나머지는 무드 name별 개수(알 수 없는 name은 무시).
MoodCounts parseMoodCounts(List<dynamic> rows) {
  var total = 0;
  final byMood = <QuoteMood, int>{};
  for (final r in rows) {
    final map = r as Map;
    final name = map['mood'] as String;
    final n = (map['n'] as num).toInt();
    if (name == '__total__') {
      total = n;
      continue;
    }
    final mood = QuoteMood.fromName(name);
    if (mood != null) byMood[mood] = n;
  }
  return (total: total, byMood: byMood);
}

class QuoteRepository {
  QuoteRepository(
    this._client, {
    KeyService? keyService,
    QuoteCipher? cipher,
  })  : _keyService = keyService,
        _cipher = cipher;

  final SupabaseClient _client;
  final KeyService? _keyService;
  final QuoteCipher? _cipher;

  static const _table = 'quotes';

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw QuoteRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    return uid;
  }

  /// 잠금 인용구를 만들거나 수정하려면 KeyService + QuoteCipher가 둘 다 주입돼 있고
  /// 마스터키가 캐시돼 있어야 한다. 셋 중 하나라도 부족하면 'KEY_LOCKED'.
  Future<_CryptoCtx> _requireMasterKey() async {
    final ks = _keyService;
    final cipher = _cipher;
    if (ks == null || cipher == null) {
      throw QuoteRepositoryException(
        'KEY_LOCKED',
        '잠금 인용구를 처리할 수 없어요 (크립토 미설정).',
      );
    }
    final key = await ks.cachedMasterKey();
    if (key == null) {
      throw QuoteRepositoryException(
        'KEY_LOCKED',
        '잠금 비밀번호로 잠금을 풀어주세요.',
      );
    }
    return (key: key, cipher: cipher);
  }

  /// 새 인용구 생성. 반환은 영속화된 [Quote]. 비로그인이면 'NOT_AUTHENTICATED'.
  /// 책 미연결(`bookId == null`)도 허용 — `manualBookText`로 대체하거나 둘 다 null도 OK.
  /// [QuoteInput.isPrivate]=true면 본문을 캐시된 마스터키로 암호화해 *_encrypted 컬럼에만 저장.
  ///
  /// FK 위반(book_id가 더 이상 존재하지 않음 등)은 재시도해도 영구 실패하므로
  /// 호출자(아웃박스 flush)가 폐기 분기할 수 있게 'FK_VIOLATION' 별도 코드로 전파.
  Future<Quote> createQuote(QuoteInput input) async {
    final uid = _requireUid();
    final payload = <String, dynamic>{'user_id': uid};
    if (input.isPrivate) {
      final key = await _requireMasterKey();
      payload.addAll(<String, dynamic>{
        'text': null,
        'manual_book_text': null,
        'text_encrypted': encodePgBytea(
          await key.cipher.encrypt(plaintext: input.text, masterKey: key.key),
        ),
        'manual_book_text_encrypted': input.manualBookText == null
            ? null
            : encodePgBytea(
                await key.cipher.encrypt(
                  plaintext: input.manualBookText!,
                  masterKey: key.key,
                ),
              ),
        'book_id': input.bookId,
        'page': input.page,
        'source': input.source.name,
        'moods': input.moods.map((m) => m.name).toList(),
        'is_private': true,
        'crypto_version': kKdfVersion,
      });
    } else {
      payload.addAll(input.toJson());
    }
    try {
      final row = await _client.from(_table).insert(payload).select().single();
      return _decryptIfPrivate(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw QuoteRepositoryException('FK_VIOLATION', e.message);
      }
      throw QuoteRepositoryException('CREATE_FAILED', e.message);
    }
  }

  /// 아웃박스에서 이미 암호화돼 보존된 잠금 인용구를 그대로 INSERT — 키가 enqueue
  /// 시점에 풀려 있었기만 하면 flush 시점엔 잠겨도 동기화 가능. 평문은 prefs/메모리
  /// 어디에도 없으므로 재암호화 불필요.
  Future<Quote> insertPrivatePayload({
    required String textEncryptedHex,
    String? manualBookTextEncryptedHex,
    String? bookId,
    int? page,
    required QuoteSource source,
    required List<QuoteMood> moods,
    required int cryptoVersion,
  }) async {
    final uid = _requireUid();
    final payload = <String, dynamic>{
      'user_id': uid,
      'text': null,
      'manual_book_text': null,
      'text_encrypted': textEncryptedHex,
      'manual_book_text_encrypted': manualBookTextEncryptedHex,
      'book_id': bookId,
      'page': page,
      'source': source.name,
      'moods': moods.map((m) => m.name).toList(),
      'is_private': true,
      'crypto_version': cryptoVersion,
    };
    try {
      final row = await _client.from(_table).insert(payload).select().single();
      return _decryptIfPrivate(Map<String, dynamic>.from(row));
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw QuoteRepositoryException('FK_VIOLATION', e.message);
      }
      throw QuoteRepositoryException('CREATE_FAILED', e.message);
    }
  }

  /// 인용구 일부 수정. 전달한 필드만 패치한다. `clearBook: true`면 책 연결 해제.
  /// [isPrivate]=true면 새 본문을 암호화해 *_encrypted 컬럼에 패치(평문 컬럼은 null).
  /// 잠금 ↔ 평문 토글은 PR16-C에서 별도 API로 — 여기선 caller가 알려준 상태 그대로.
  Future<Quote> updateQuote(
    String id, {
    String? text,
    int? page,
    Set<QuoteMood>? moods,
    String? bookId,
    String? manualBookText,
    bool clearBook = false,
    bool isPrivate = false,
  }) async {
    _requireUid();
    final patch = <String, dynamic>{
      'page': ?page,
      'moods': ?moods?.map((m) => m.name).toList(),
      if (clearBook) 'book_id': null else 'book_id': ?bookId,
    };
    // 잠금↔평문 전환을 update 한 번에 처리. caller가 text를 항상 보내면(편집
    // 화면 _buildInput처럼) 데이터 손실 없음. text=null이면서 잠금→평문 전환
    // 시도면 기존 평문 컬럼이 NULL인 잠금 row가 평문 상태가 되어 본문 손실 →
    // 사전 차단(예외).
    if (isPrivate) {
      final key = await _requireMasterKey();
      if (text != null) {
        patch['text'] = null;
        patch['text_encrypted'] = encodePgBytea(
          await key.cipher.encrypt(plaintext: text, masterKey: key.key),
        );
      }
      if (manualBookText != null) {
        patch['manual_book_text'] = null;
        patch['manual_book_text_encrypted'] = encodePgBytea(
          await key.cipher
              .encrypt(plaintext: manualBookText, masterKey: key.key),
        );
      }
      patch['is_private'] = true;
      patch['crypto_version'] = kKdfVersion;
    } else {
      if (text != null) {
        patch['text'] = text;
        patch['text_encrypted'] = null;
      }
      if (manualBookText != null) {
        patch['manual_book_text'] = manualBookText;
        patch['manual_book_text_encrypted'] = null;
      }
      patch['is_private'] = false;
      patch['crypto_version'] = null;
    }
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
      return _decryptIfPrivate(Map<String, dynamic>.from(row));
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
  /// 잠금 인용구면 캐시된 마스터키로 복호화해 [Quote.text]를 채움. 키 없으면 text=null.
  Future<Quote?> getById(String id) async {
    try {
      final row =
          await _client.from(_table).select().eq('id', id).maybeSingle();
      if (row == null) return null;
      return _decryptIfPrivate(Map<String, dynamic>.from(row));
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
      final out = <Quote>[];
      for (final r in rows) {
        out.add(await _decryptIfPrivate(Map<String, dynamic>.from(r)));
      }
      return out;
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('LIST_FAILED', e.message);
    }
  }

  /// [listMyQuotes]와 같지만 연결된 책을 임베드해 [QuoteWithBook]로 반환한다 —
  /// 홈 피드·인용 목록 카드가 표지·제목을 N+1 없이 그리기 위함. `book_id`가 null이면
  /// `book`도 null.
  Future<List<QuoteWithBook>> listMyQuotesWithBook({
    String? bookId,
    Set<QuoteMood>? moods,
    QuoteCursor? after,
    int limit = 15,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    try {
      var query =
          _client.from(_table).select('*, book:books(*)').eq('user_id', uid);
      if (bookId != null) query = query.eq('book_id', bookId);
      if (moods != null && moods.isNotEmpty) {
        query = query.overlaps('moods', moods.map((m) => m.name).toList());
      }
      if (after != null) {
        final ts = after.createdAt.toUtc().toIso8601String();
        query = query
            .or('created_at.lt.$ts,and(created_at.eq.$ts,id.lt.${after.id})');
      }
      final rows = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      final out = <QuoteWithBook>[];
      for (final r in rows) {
        final row = Map<String, dynamic>.from(r);
        final bookJson = row['book'];
        final quote = await _decryptIfPrivate(row);
        out.add((
          quote: quote,
          book: bookJson is Map<String, dynamic>
              ? Book.fromJson(bookJson)
              : null,
        ));
      }
      return out;
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('LIST_FAILED', e.message);
    }
  }

  /// 친구의 공개·잠금아닌 인용구 + 책 (PR18-C 친구 프로필 인용구 탭).
  ///
  /// `quotes_friends_read` RLS(친구 + `is_library_public=true` + `is_private=false`)가
  /// 게이트 — 정책 통과 못하면 0 row. 클라이언트엔 fallback 코드 X(DB가 막음 = 신뢰
  /// 단일 출처). 잠금 인용구는 *카드 자체가 안 나옴*.
  ///
  /// cursor-after `(created_at desc, id desc)`로 무한스크롤. moods 필터는 V1엔 없음
  /// (남의 인용구는 시간순으로만 — 친구 프로필 인용 탭 단순화).
  Future<List<QuoteWithBook>> listFriendQuotesWithBook(
    String userId, {
    QuoteCursor? after,
    int limit = 15,
  }) async {
    try {
      var query =
          _client.from(_table).select('*, book:books(*)').eq('user_id', userId);
      if (after != null) {
        final ts = after.createdAt.toUtc().toIso8601String();
        query = query
            .or('created_at.lt.$ts,and(created_at.eq.$ts,id.lt.${after.id})');
      }
      final rows = await query
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      final out = <QuoteWithBook>[];
      for (final r in rows) {
        final row = Map<String, dynamic>.from(r);
        final bookJson = row['book'];
        // RLS가 is_private=false만 통과시키므로 복호화 불필요 — 그래도 분기 안전.
        final quote = await _decryptIfPrivate(row);
        out.add((
          quote: quote,
          book: bookJson is Map<String, dynamic>
              ? Book.fromJson(bookJson)
              : null,
        ));
      }
      return out;
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('LIST_FRIEND_FAILED', e.message);
    }
  }

  /// is_private=true인 row의 *_encrypted 컬럼을 캐시된 마스터키로 풀어 row의 평문
  /// 컬럼('text', 'manual_book_text')에 채운다. 키가 없거나 복호화 실패면 평문 컬럼은
  /// 그대로 null이고 Quote.text도 null로 — UI(PR16-C)가 [Quote.isPrivate]로 분기.
  Future<Quote> _decryptIfPrivate(Map<String, dynamic> row) async {
    if (row['is_private'] != true) {
      return Quote.fromJson(row);
    }
    final ks = _keyService;
    final cipher = _cipher;
    if (ks != null && cipher != null) {
      final masterKey = await ks.cachedMasterKey();
      if (masterKey != null) {
        try {
          final textEncRaw = row['text_encrypted'] as String?;
          if (textEncRaw != null) {
            row['text'] = await cipher.decrypt(
              blob: Uint8List.fromList(decodePgBytea(textEncRaw)),
              masterKey: masterKey,
            );
          }
          final manualEncRaw = row['manual_book_text_encrypted'] as String?;
          if (manualEncRaw != null) {
            row['manual_book_text'] = await cipher.decrypt(
              blob: Uint8List.fromList(decodePgBytea(manualEncRaw)),
              masterKey: masterKey,
            );
          }
        } catch (_) {
          // 복호화 실패(키 mismatch, blob 변조) — 평문 컬럼은 null 유지.
        }
      }
    }
    return Quote.fromJson(row);
  }

  /// 내 인용구 텍스트 검색 (PR20-B 출시 블로커 UX#2). `text` + `manual_book_text`
  /// ilike `'%query%'`. RLS가 본인 것만 자연 게이트. 잠금 인용구(text=null,
  /// `is_private=true`)는 NULL이 ilike 매칭 안 되므로 자연 제외.
  ///
  /// 빈 쿼리는 즉시 빈 리스트. ilike 와일드카드(`%`/`_`)는 escape.
  /// 책 정보 임베드해 N+1 회피.
  Future<List<QuoteWithBook>> searchMyQuotesWithBook(
    String query, {
    int limit = 30,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const [];
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final escaped = trimmed
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    final pattern = '%$escaped%';
    try {
      final rows = await _client
          .from(_table)
          .select('*, book:books(*)')
          .eq('user_id', uid)
          .or('text.ilike.$pattern,manual_book_text.ilike.$pattern')
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(limit);
      final out = <QuoteWithBook>[];
      for (final r in rows) {
        final row = Map<String, dynamic>.from(r);
        final bookJson = row['book'];
        final quote = await _decryptIfPrivate(row);
        out.add((
          quote: quote,
          book: bookJson is Map<String, dynamic>
              ? Book.fromJson(bookJson)
              : null,
        ));
      }
      return out;
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('SEARCH_FAILED', e.message);
    }
  }

  /// 내 인용구 총 개수. 비로그인이면 0. ('내 정보' 화면 요약용)
  Future<int> countMyQuotes() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    try {
      final res = await _client
          .from(_table)
          .select('id')
          .eq('user_id', uid)
          .count(CountOption.exact);
      return res.count;
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('COUNT_FAILED', e.message);
    }
  }

  /// 내 인용구 무드 통계 — 전체 수 + 무드별 개수 (서재 인용 뷰 필터 칩용).
  Future<MoodCounts> getMoodCounts() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return (total: 0, byMood: <QuoteMood, int>{});
    try {
      final rows = await _client.rpc('my_quote_mood_counts') as List<dynamic>;
      return parseMoodCounts(rows);
    } on PostgrestException catch (e) {
      throw QuoteRepositoryException('COUNT_FAILED', e.message);
    }
  }
}

final quoteRepositoryProvider = Provider<QuoteRepository>((ref) {
  return QuoteRepository(
    supabase,
    keyService: ref.watch(keyServiceProvider),
    cipher: ref.watch(quoteCipherProvider),
  );
});
