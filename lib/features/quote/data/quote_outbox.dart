// 오프라인 인용구 아웃박스 (경량 — DECISIONS 2026-05-11 + PR16-B E2EE).
//
// 저장 시 네트워크 오류면 인용구 입력을 SharedPreferences에 JSON 리스트로 쌓아두고,
// 앱 포그라운드 복귀/연결 회복 시 flush()로 best-effort 재시도한다. 완전한 동기화
// 엔진(충돌 해결·실시간·책 재매칭 UI)은 V1.5 (`flows.md` Flow F).
//
// 키는 사용자별(`quote_outbox_v1:<uid>`) — 다른 계정으로 로그인해도 섞이지 않게.
//
// PR16-B: 잠금 인용구는 enqueue 시점에 캐시된 마스터키로 AES-256-GCM 암호화 후
// `kind:'private'` 태그된 JSON으로 저장 — 평문은 prefs/메모리에 일절 남기지 않는다
// (앱 압수·플래시 덤프·prefs 백업 누수 차단). flush 시 [QuoteRepository.insertPrivatePayload]로
// 평문 재경유 없이 그대로 INSERT.
// 평문 입력은 기존 그대로 — 'kind' 필드 없는 legacy 항목도 평문으로 해석(PR3 이전 큐잉 호환).

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_init.dart';
import '../../crypto/data/key_derivation.dart' show kKdfVersion;
import '../../crypto/data/key_service.dart';
import '../../crypto/data/quote_cipher.dart';
import '../../crypto/domain/envelope.dart' show encodePgBytea;
import '../../crypto/state/crypto_providers.dart';
import '../domain/quote.dart';
import '../domain/quote_mood.dart';
import 'quote_repository.dart';

class QuoteOutbox {
  QuoteOutbox(
    this._prefs, {
    KeyService? keyService,
    QuoteCipher? cipher,
  })  : _keyService = keyService,
        _cipher = cipher;

  final SharedPreferences _prefs;
  final KeyService? _keyService;
  final QuoteCipher? _cipher;

  static const _prefix = 'quote_outbox_v1';

  // Process-wide flush 가드 — quoteOutboxProvider invalidate로 인스턴스가 새로
  // 만들어져도 SharedPreferences는 단일 데이터 소스이므로 static으로 둬야
  // 동시 flush가 같은 항목을 두 번 INSERT하는 race를 막을 수 있다.
  static bool _isFlushing = false;

  String _key([String? uid]) {
    final id = uid ?? supabase.auth.currentUser?.id;
    return id == null ? _prefix : '$_prefix:$id';
  }

  List<_OutboxEntry> _read([String? uid]) {
    final raw = _prefs.getStringList(_key(uid)) ?? const <String>[];
    final result = <_OutboxEntry>[];
    for (final s in raw) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        result.add(_OutboxEntry.fromJson(map));
      } catch (_) {
        // 손상된 항목은 조용히 스킵
      }
    }
    return result;
  }

  Future<void> _write(List<_OutboxEntry> items, [String? uid]) async {
    await _prefs.setStringList(
      _key(uid),
      items.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  /// 평문 입력만 [QuoteInput]로 노출 — 테스트/디버그 용도. 잠금 항목은 평문 없음.
  List<QuoteInput> pending([String? uid]) => _read(uid)
      .whereType<_PlainEntry>()
      .map((e) => e.input)
      .toList(growable: false);

  /// 전체 대기 개수(평문+잠금) — 홈/인용목록 "동기화 대기 N개" 배너용.
  int pendingCount([String? uid]) => _read(uid).length;

  /// 인용구 입력을 아웃박스 끝에 추가. [QuoteInput.isPrivate]=true면 enqueue 시점에
  /// 캐시된 마스터키로 암호화해 평문 컬럼 없이 ciphertext만 저장. 키가 없으면 'KEY_LOCKED'
  /// 예외 — caller가 사용자에게 잠금 비밀번호 입력을 요구해야 한다.
  Future<void> enqueue(QuoteInput input, [String? uid]) async {
    final entry = input.isPrivate
        ? await _encryptToEntry(input)
        : _PlainEntry(input);
    final items = _read(uid)..add(entry);
    await _write(items, uid);
  }

  Future<_PrivateEntry> _encryptToEntry(QuoteInput input) async {
    final ks = _keyService;
    final cipher = _cipher;
    if (ks == null || cipher == null) {
      throw QuoteRepositoryException(
        'KEY_LOCKED',
        '잠금 인용구를 큐잉할 수 없어요 (크립토 미설정).',
      );
    }
    final key = await ks.cachedMasterKey();
    if (key == null) {
      throw QuoteRepositoryException(
        'KEY_LOCKED',
        '잠금 비밀번호로 잠금을 풀어주세요.',
      );
    }
    final textEnc = await cipher.encrypt(plaintext: input.text, masterKey: key);
    final manualEnc = input.manualBookText == null
        ? null
        : await cipher.encrypt(
            plaintext: input.manualBookText!,
            masterKey: key,
          );
    return _PrivateEntry(
      textEncryptedHex: encodePgBytea(textEnc),
      manualBookTextEncryptedHex:
          manualEnc == null ? null : encodePgBytea(manualEnc),
      bookId: input.bookId,
      page: input.page,
      source: input.source,
      moods: List<QuoteMood>.unmodifiable(input.moods),
      cryptoVersion: kKdfVersion,
    );
  }

  /// 아웃박스 전체 비우기 (로그아웃 등).
  Future<void> clear([String? uid]) => _prefs.remove(_key(uid));

  /// 대기 항목을 순서대로 서버에 저장 시도.
  ///
  /// - 성공: 큐에서 제거 (`sent` 증가)
  /// - FK 위반(`FK_VIOLATION`): 영구 실패 → 큐에서 폐기 (`discarded` 증가).
  ///   책이 사후 삭제됐거나 user 정합이 깨진 케이스. 재시도 무의미.
  /// - 그 외 실패: 큐에 남겨 다음 기회 재시도 (`remaining`).
  ///
  /// 동시 진입 가드: 다른 호출이 이미 flush 중이면 즉시 (0, pending, 0) 반환 —
  /// 인스턴스가 invalidate로 새로 만들어져도 static 가드라 중복 INSERT 방지.
  Future<({int sent, int remaining, int discarded})> flush(
    QuoteRepository repo, {
    String? uid,
  }) async {
    if (_isFlushing) {
      return (sent: 0, remaining: _read(uid).length, discarded: 0);
    }
    _isFlushing = true;
    try {
      final items = _read(uid);
      if (items.isEmpty) return (sent: 0, remaining: 0, discarded: 0);
      final remaining = <_OutboxEntry>[];
      var sent = 0;
      var discarded = 0;
      for (final entry in items) {
        try {
          await entry.flushTo(repo);
          sent++;
        } on QuoteRepositoryException catch (e) {
          if (e.code == 'FK_VIOLATION') {
            discarded++;
          } else {
            remaining.add(entry);
          }
        } catch (_) {
          remaining.add(entry);
        }
      }
      await _write(remaining, uid);
      return (sent: sent, remaining: remaining.length, discarded: discarded);
    } finally {
      _isFlushing = false;
    }
  }
}

/// 평문 또는 잠금 — 직렬화/dispatch만 추상화. 평문은 [QuoteInput] 그대로 들고
/// 가고, 잠금은 ciphertext + 메타만 들고 간다(평문은 enqueue 직후 폐기).
sealed class _OutboxEntry {
  Map<String, dynamic> toJson();
  Future<void> flushTo(QuoteRepository repo);

  factory _OutboxEntry.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] as String?;
    if (kind == 'private') {
      return _PrivateEntry.fromJson(json);
    }
    // 'kind' 없는 legacy 항목 + 'plain' 모두 평문으로 해석.
    final clean = Map<String, dynamic>.from(json)..remove('kind');
    return _PlainEntry(QuoteInput.fromJson(clean));
  }
}

class _PlainEntry implements _OutboxEntry {
  _PlainEntry(this.input);
  final QuoteInput input;

  @override
  Map<String, dynamic> toJson() => input.toJson();

  @override
  Future<void> flushTo(QuoteRepository repo) async {
    await repo.createQuote(input);
  }
}

class _PrivateEntry implements _OutboxEntry {
  _PrivateEntry({
    required this.textEncryptedHex,
    this.manualBookTextEncryptedHex,
    this.bookId,
    this.page,
    required this.source,
    required this.moods,
    required this.cryptoVersion,
  });

  final String textEncryptedHex;
  final String? manualBookTextEncryptedHex;
  final String? bookId;
  final int? page;
  final QuoteSource source;
  final List<QuoteMood> moods;
  final int cryptoVersion;

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': 'private',
        'text_encrypted_hex': textEncryptedHex,
        'manual_book_text_encrypted_hex': manualBookTextEncryptedHex,
        'book_id': bookId,
        'page': page,
        'source': source.name,
        'moods': moods.map((m) => m.name).toList(),
        'crypto_version': cryptoVersion,
      };

  factory _PrivateEntry.fromJson(Map<String, dynamic> json) {
    final moodsRaw = (json['moods'] as List?) ?? const <dynamic>[];
    final moods = <QuoteMood>[];
    for (final m in moodsRaw) {
      final parsed = QuoteMood.fromName(m.toString());
      if (parsed != null) moods.add(parsed);
    }
    final sourceName = json['source'] as String? ?? QuoteSource.manual.name;
    final source = QuoteSource.values.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => QuoteSource.manual,
    );
    return _PrivateEntry(
      textEncryptedHex: json['text_encrypted_hex'] as String,
      manualBookTextEncryptedHex:
          json['manual_book_text_encrypted_hex'] as String?,
      bookId: json['book_id'] as String?,
      page: (json['page'] as num?)?.toInt(),
      source: source,
      moods: moods,
      cryptoVersion: (json['crypto_version'] as num).toInt(),
    );
  }

  @override
  Future<void> flushTo(QuoteRepository repo) async {
    await repo.insertPrivatePayload(
      textEncryptedHex: textEncryptedHex,
      manualBookTextEncryptedHex: manualBookTextEncryptedHex,
      bookId: bookId,
      page: page,
      source: source,
      moods: moods,
      cryptoVersion: cryptoVersion,
    );
  }
}

/// SharedPreferences 인스턴스를 한 번 얻어 [QuoteOutbox]를 만든다.
/// PR16-B: keyService/cipher 주입 — 잠금 입력 enqueue 시 즉시 암호화에 사용.
final quoteOutboxProvider = FutureProvider<QuoteOutbox>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return QuoteOutbox(
    prefs,
    keyService: ref.watch(keyServiceProvider),
    cipher: ref.watch(quoteCipherProvider),
  );
});

/// 현재 대기 중인 인용구 개수(평문+잠금) — 홈/인용목록 "동기화 대기 N개" 배너용.
/// enqueue/flush 후 호출자가 `ref.invalidate(quoteOutboxProvider)`로 갱신.
final pendingOutboxCountProvider = FutureProvider<int>((ref) async {
  final outbox = await ref.watch(quoteOutboxProvider.future);
  return outbox.pendingCount();
});
