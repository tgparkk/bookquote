// PBKDF2-HMAC-SHA512 키 파생 + 마스터키 wrap/unwrap (PR16-A).
//
// 잠금 비밀번호 → PBKDF2-HMAC-SHA512(600k iters, salt 16B) → wrap_key 32B
// → AES-256-GCM(wrap_key, nonce 12B)으로 마스터키 K(32B) wrap.
//
// `cryptography` 패키지는 순수 Dart (native 의존 0) — release-only 함정 회피.
// Argon2id는 native plugin 필요해서 V1에 안 씀(`crypto_version` 슬롯으로 V2 회수 대비).

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

const int kKdfIters = 600000;
const int kKdfSaltLength = 16;
const int kMasterKeyLength = 32;
const int kAesGcmNonceLength = 12;
const int kAesGcmTagLength = 16;
const int kKdfVersion = 1;

class KeyDerivation {
  KeyDerivation({Pbkdf2? pbkdf2, AesGcm? aesGcm})
      : _pbkdf2 = pbkdf2 ??
            Pbkdf2(
              macAlgorithm: Hmac.sha512(),
              iterations: kKdfIters,
              bits: kMasterKeyLength * 8,
            ),
        _aesGcm = aesGcm ?? AesGcm.with256bits();

  final Pbkdf2 _pbkdf2;
  final AesGcm _aesGcm;

  /// 잠금 비밀번호 → wrap_key (PBKDF2-HMAC-SHA512).
  Future<SecretKey> deriveWrapKey({
    required String password,
    required List<int> salt,
  }) {
    return _pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
  }

  /// 마스터키 K를 wrap_key로 wrap → (cipher||tag, nonce).
  Future<({Uint8List wrappedKey, Uint8List nonce})> wrapMasterKey({
    required List<int> masterKey,
    required SecretKey wrapKey,
  }) async {
    final nonce = _aesGcm.newNonce();
    final box = await _aesGcm.encrypt(
      masterKey,
      secretKey: wrapKey,
      nonce: nonce,
    );
    final wrapped = Uint8List(box.cipherText.length + box.mac.bytes.length)
      ..setRange(0, box.cipherText.length, box.cipherText)
      ..setRange(
        box.cipherText.length,
        box.cipherText.length + box.mac.bytes.length,
        box.mac.bytes,
      );
    return (wrappedKey: wrapped, nonce: Uint8List.fromList(nonce));
  }

  /// wrap된 마스터키를 풂. 잘못된 비밀번호면 `SecretBoxAuthenticationError` throw.
  Future<Uint8List> unwrapMasterKey({
    required Uint8List wrappedKey,
    required Uint8List nonce,
    required SecretKey wrapKey,
  }) async {
    if (wrappedKey.length < kAesGcmTagLength + 1) {
      throw const FormatException('wrapped_key too short');
    }
    final cipher = wrappedKey.sublist(0, wrappedKey.length - kAesGcmTagLength);
    final mac = wrappedKey.sublist(wrappedKey.length - kAesGcmTagLength);
    final plain = await _aesGcm.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
      secretKey: wrapKey,
    );
    return Uint8List.fromList(plain);
  }
}
