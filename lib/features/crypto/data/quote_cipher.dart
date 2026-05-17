// 인용구 본문 AES-256-GCM 암복호 (PR16-A).
//
// 저장 형식: nonce(12B) || ciphertext || tag(16B). 단일 bytea로 quotes.text_encrypted에.
// 본문(text)과 manual_book_text는 각각 별도 nonce — nonce 재사용 금지(GCM 치명).
// 같은 평문이라도 매번 다른 ciphertext (nonce 랜덤).
//
// 잘못된 키·변조된 blob → `SecretBoxAuthenticationError` throw.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'key_derivation.dart' show kAesGcmNonceLength, kAesGcmTagLength;

class QuoteCipher {
  QuoteCipher({AesGcm? aesGcm}) : _aesGcm = aesGcm ?? AesGcm.with256bits();

  final AesGcm _aesGcm;

  /// 평문 string → nonce||cipher||tag bytea.
  Future<Uint8List> encrypt({
    required String plaintext,
    required SecretKey masterKey,
  }) async {
    final nonce = _aesGcm.newNonce();
    final box = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: masterKey,
      nonce: nonce,
    );
    final out = BytesBuilder(copy: false)
      ..add(nonce)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.toBytes();
  }

  /// nonce||cipher||tag bytea → 평문.
  Future<String> decrypt({
    required Uint8List blob,
    required SecretKey masterKey,
  }) async {
    if (blob.length < kAesGcmNonceLength + kAesGcmTagLength) {
      throw const FormatException('encrypted blob too short');
    }
    final nonce = blob.sublist(0, kAesGcmNonceLength);
    final cipher =
        blob.sublist(kAesGcmNonceLength, blob.length - kAesGcmTagLength);
    final mac = blob.sublist(blob.length - kAesGcmTagLength);
    final plain = await _aesGcm.decrypt(
      SecretBox(cipher, nonce: nonce, mac: Mac(mac)),
      secretKey: masterKey,
    );
    return utf8.decode(plain);
  }
}
