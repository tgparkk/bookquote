// PR16-B: 잠금 인용구의 enqueue 직전 암호화 + flush 시 insertPrivatePayload 디스패치.
//
// 검증 포인트:
// 1. enqueue(isPrivate:true) 직후 SharedPreferences에 평문이 일절 들어가지 않는다.
// 2. legacy/평문 entries(PR3 이전 포맷)는 'kind' 키 없이 그대로 _PlainEntry로 해석.
// 3. flush가 _PrivateEntry는 repo.insertPrivatePayload로, _PlainEntry는 repo.createQuote로
//    각각 라우팅한다.
// 4. KeyService/QuoteCipher 미주입 시 잠금 enqueue는 'KEY_LOCKED' 예외.
//
// flutter_secure_storage native 의존을 회피하기 위해 [KeyService]를 직접 mock하지 않고
// 마스터키 캐시만 흉내내는 [_StubKeyService]로 대체한다.

import 'dart:convert';
import 'dart:typed_data';

import 'package:bookquote/features/crypto/data/key_service.dart';
import 'package:bookquote/features/crypto/data/quote_cipher.dart';
import 'package:bookquote/features/quote/data/quote_outbox.dart';
import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uid = 'u1';

/// 마스터키 캐시만 in-memory로 흉내 — flutter_secure_storage native 채널 회피.
class _StubKeyService extends Mock implements KeyService {
  _StubKeyService({SecretKey? initialKey}) : _key = initialKey;
  SecretKey? _key;

  @override
  Future<SecretKey?> cachedMasterKey() async => _key;

  @override
  Future<void> cacheMasterKey(SecretKey k) async {
    _key = k;
  }
}

class _SpyRepo extends Mock implements QuoteRepository {
  int createCalls = 0;
  int privateCalls = 0;
  String? lastTextEncryptedHex;
  String? lastBookId;
  int? lastPage;
  List<QuoteMood>? lastMoods;

  @override
  Future<Quote> createQuote(QuoteInput? input) async {
    createCalls++;
    return Quote(
      id: 'q$createCalls',
      userId: _uid,
      text: input!.text,
      moods: input.moods,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<Quote> insertPrivatePayload({
    String? textEncryptedHex,
    String? manualBookTextEncryptedHex,
    String? bookId,
    int? page,
    QuoteSource? source,
    List<QuoteMood>? moods,
    int? cryptoVersion,
  }) async {
    privateCalls++;
    lastTextEncryptedHex = textEncryptedHex;
    lastBookId = bookId;
    lastPage = page;
    lastMoods = moods;
    return Quote(
      id: 'p$privateCalls',
      userId: _uid,
      text: null,
      isPrivate: true,
      cryptoVersion: cryptoVersion,
      moods: moods ?? const <QuoteMood>[],
      bookId: bookId,
      page: page,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }
}

KeyService _cachedKeyService() => _StubKeyService(
      initialKey:
          SecretKey(Uint8List.fromList(List<int>.generate(32, (i) => i))),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('잠금 입력은 enqueue 직후 prefs에 평문이 절대 들어가지 않는다', () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(
      prefs,
      keyService: _cachedKeyService(),
      cipher: QuoteCipher(),
    );
    const secret = '운영자도 못 볼 비밀 한 줄';
    await outbox.enqueue(
      const QuoteInput(
        text: secret,
        manualBookText: '비밀 책 이름',
        isPrivate: true,
      ),
      _uid,
    );

    final raw = prefs.getStringList('quote_outbox_v1:$_uid')!.single;
    expect(raw.contains(secret), isFalse, reason: '평문 본문이 prefs에 노출');
    expect(raw.contains('비밀 책 이름'), isFalse, reason: '평문 책명이 prefs에 노출');
    expect(raw.contains('"kind":"private"'), isTrue);
    expect(raw.contains('text_encrypted_hex'), isTrue);
  });

  test('flush는 평문은 createQuote, 잠금은 insertPrivatePayload로 라우팅', () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(
      prefs,
      keyService: _cachedKeyService(),
      cipher: QuoteCipher(),
    );
    await outbox.enqueue(const QuoteInput(text: '평문1'), _uid);
    await outbox.enqueue(
      const QuoteInput(text: '잠금1', isPrivate: true, page: 42),
      _uid,
    );
    await outbox.enqueue(const QuoteInput(text: '평문2'), _uid);

    final repo = _SpyRepo();
    final r = await outbox.flush(repo, uid: _uid);
    expect(r.sent, 3);
    expect(repo.createCalls, 2);
    expect(repo.privateCalls, 1);
    expect(repo.lastPage, 42);
    expect(repo.lastTextEncryptedHex, isNotNull);
    expect(repo.lastTextEncryptedHex!.startsWith(r'\x'), isTrue);
  });

  test('crypto 미주입 outbox에 잠금 enqueue 시 KEY_LOCKED 예외', () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(prefs);
    expect(
      () => outbox
          .enqueue(const QuoteInput(text: 'x', isPrivate: true), _uid),
      throwsA(isA<QuoteRepositoryException>()
          .having((e) => e.code, 'code', 'KEY_LOCKED')),
    );
  });

  test('cachedMasterKey 없이 잠금 enqueue 시 KEY_LOCKED 예외', () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(
      prefs,
      keyService: _StubKeyService(), // no key cached
      cipher: QuoteCipher(),
    );
    expect(
      () => outbox
          .enqueue(const QuoteInput(text: 'x', isPrivate: true), _uid),
      throwsA(isA<QuoteRepositoryException>()
          .having((e) => e.code, 'code', 'KEY_LOCKED')),
    );
  });

  test('legacy 평문 entry(kind 없음)는 평문으로 해석되어 createQuote로 flush',
      () async {
    final prefs = await SharedPreferences.getInstance();
    final legacyJson = QuoteInput(
      text: '레거시 본문',
      moods: const [QuoteMood.lateNight],
    ).toJson();
    await prefs.setStringList('quote_outbox_v1:$_uid', [jsonEncode(legacyJson)]);
    final outbox = QuoteOutbox(prefs);
    expect(outbox.pendingCount(_uid), 1);
    expect(outbox.pending(_uid).single.text, '레거시 본문');

    final repo = _SpyRepo();
    final r = await outbox.flush(repo, uid: _uid);
    expect(r.sent, 1);
    expect(repo.createCalls, 1);
    expect(repo.privateCalls, 0);
  });

  test('pending()은 평문만, pendingCount()는 전체를 센다', () async {
    final prefs = await SharedPreferences.getInstance();
    final outbox = QuoteOutbox(
      prefs,
      keyService: _cachedKeyService(),
      cipher: QuoteCipher(),
    );
    await outbox.enqueue(const QuoteInput(text: '평문'), _uid);
    await outbox.enqueue(
      const QuoteInput(text: '잠금', isPrivate: true),
      _uid,
    );

    expect(outbox.pending(_uid).length, 1, reason: '평문만 노출');
    expect(outbox.pendingCount(_uid), 2, reason: '잠금 포함 전체 count');
  });
}
