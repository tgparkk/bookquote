// 마스터키 K 관리 (PR16-A).
//
// flutter_secure_storage에 마스터키 K(32B 랜덤)를 캐시 — Android Keystore (EncryptedSharedPreferences)
// + iOS Keychain. 잠금 비밀번호로 envelope unwrap → K → 캐시. K가 캐시에 있으면 매번
// 비밀번호 입력 X. 비밀번호 변경 시 K는 그대로, envelope만 새로.
//
// AndroidManifest에 `android:allowBackup="false"` 필수 — 안 하면 Google Drive로 키가
// 새서 E2EE 무력화(설계: DECISIONS 2026-05-17).
//
// 단위 테스트는 flutter_secure_storage가 native plugin이라 PR16-E의 release APK sanity에서.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/envelope.dart';
import 'key_derivation.dart';

class NewEnvelopeResult {
  const NewEnvelopeResult({required this.masterKey, required this.envelope});
  final SecretKey masterKey;
  final CryptoEnvelope envelope;
}

class RewrapResult {
  const RewrapResult({
    required this.wrappedKey,
    required this.wrapNonce,
    required this.kdfSalt,
  });
  final Uint8List wrappedKey;
  final Uint8List wrapNonce;
  final Uint8List kdfSalt;
}

class KeyService {
  KeyService({
    FlutterSecureStorage? storage,
    KeyDerivation? derivation,
    Random? random,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _derivation = derivation ?? KeyDerivation(),
        _random = random ?? Random.secure();

  final FlutterSecureStorage _storage;
  final KeyDerivation _derivation;
  final Random _random;

  static const _masterKeyName = 'bookquote.master_key.v1';

  /// 캐시된 마스터키 K. 없으면 null (envelope를 열어야 한다).
  Future<SecretKey?> cachedMasterKey() async {
    final hex = await _storage.read(key: _masterKeyName);
    if (hex == null) return null;
    return SecretKey(_hexDecode(hex));
  }

  /// 마스터키 K를 캐시에 저장.
  Future<void> cacheMasterKey(SecretKey k) async {
    final bytes = await k.extractBytes();
    await _storage.write(key: _masterKeyName, value: _hexEncode(bytes));
  }

  /// 캐시 비우기 (로그아웃·탈퇴 시). envelope는 서버 row라 별도(탈퇴 시 cascade).
  Future<void> deleteCachedMasterKey() async {
    await _storage.delete(key: _masterKeyName);
  }

  /// 새 마스터키 K + 새 salt + 새 wrap_nonce 생성. 비밀번호로 wrap.
  /// caller가 `user_crypto_envelopes`에 insert.
  Future<NewEnvelopeResult> createEnvelope({required String password}) async {
    final masterKeyBytes = _randomBytes(kMasterKeyLength);
    final salt = _randomBytes(kKdfSaltLength);
    final wrapKey =
        await _derivation.deriveWrapKey(password: password, salt: salt);
    final wrap = await _derivation.wrapMasterKey(
      masterKey: masterKeyBytes,
      wrapKey: wrapKey,
    );
    return NewEnvelopeResult(
      masterKey: SecretKey(masterKeyBytes),
      envelope: CryptoEnvelope(
        wrappedKey: wrap.wrappedKey,
        wrapNonce: wrap.nonce,
        kdfSalt: salt,
        kdfIters: kKdfIters,
        kdfVersion: kKdfVersion,
      ),
    );
  }

  /// 기존 envelope을 비밀번호로 unwrap → 마스터키 K. 잘못된 비밀번호면 throw.
  Future<SecretKey> openEnvelope({
    required String password,
    required CryptoEnvelope envelope,
  }) async {
    // envelope의 kdf_iters를 그대로 사용(미래 KDF 회수·iters 상향 대비).
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha512(),
      iterations: envelope.kdfIters,
      bits: kMasterKeyLength * 8,
    );
    final wrapKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: envelope.kdfSalt,
    );
    final masterKeyBytes = await _derivation.unwrapMasterKey(
      wrappedKey: envelope.wrappedKey,
      nonce: envelope.wrapNonce,
      wrapKey: wrapKey,
    );
    return SecretKey(masterKeyBytes);
  }

  /// 비밀번호 변경 — K는 그대로, salt + nonce + wrapped_key만 새로.
  /// 인용구 재암호화 0(K가 안 바뀜).
  Future<RewrapResult> rewrap({
    required SecretKey masterKey,
    required String newPassword,
  }) async {
    final salt = _randomBytes(kKdfSaltLength);
    final wrapKey = await _derivation.deriveWrapKey(
      password: newPassword,
      salt: salt,
    );
    final masterKeyBytes = await masterKey.extractBytes();
    final wrap = await _derivation.wrapMasterKey(
      masterKey: masterKeyBytes,
      wrapKey: wrapKey,
    );
    return RewrapResult(
      wrappedKey: wrap.wrappedKey,
      wrapNonce: wrap.nonce,
      kdfSalt: salt,
    );
  }

  Uint8List _randomBytes(int n) => Uint8List.fromList(
        List<int>.generate(n, (_) => _random.nextInt(256)),
      );

  String _hexEncode(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  Uint8List _hexDecode(String hex) {
    final out = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}
