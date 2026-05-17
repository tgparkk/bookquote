// PR16-A: 크립토 코어 단위 테스트 — PBKDF2 + AES-256-GCM round-trip.
//
// `flutter_secure_storage`가 native plugin이라 `KeyService` 단위 테스트는 안 함
// (PR16-E의 release APK sanity에서 검증). 여기선 알고리즘 자체의 정합성만:
// 파생/wrap/unwrap/암복호/위조 거부/nonce 랜덤성.
//
// PBKDF2 600k iters는 테스트에 너무 느려 1000으로 override(알고리즘 자체는 동일).

import 'dart:typed_data';

import 'package:bookquote/features/crypto/data/key_derivation.dart';
import 'package:bookquote/features/crypto/data/quote_cipher.dart';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

KeyDerivation _fastKd() => KeyDerivation(
      pbkdf2: Pbkdf2(
        macAlgorithm: Hmac.sha512(),
        iterations: 1000,
        bits: kMasterKeyLength * 8,
      ),
    );

void main() {
  group('PBKDF2 + AES-GCM key wrapping', () {
    test('wrap → unwrap round-trip로 마스터키 복원', () async {
      final kd = _fastKd();
      const password = 'correct horse battery staple';
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      final masterKey =
          Uint8List.fromList(List.generate(32, (i) => i * 7 % 256));

      final wrapKey =
          await kd.deriveWrapKey(password: password, salt: salt);
      final wrap = await kd.wrapMasterKey(
        masterKey: masterKey,
        wrapKey: wrapKey,
      );

      final wrapKey2 =
          await kd.deriveWrapKey(password: password, salt: salt);
      final unwrapped = await kd.unwrapMasterKey(
        wrappedKey: wrap.wrappedKey,
        nonce: wrap.nonce,
        wrapKey: wrapKey2,
      );
      expect(unwrapped, masterKey);
    });

    test('잘못된 비밀번호면 unwrap 실패 (SecretBoxAuthenticationError)', () async {
      final kd = _fastKd();
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      final masterKey = Uint8List.fromList(List.generate(32, (i) => i));

      final wrapKey =
          await kd.deriveWrapKey(password: 'right', salt: salt);
      final wrap = await kd.wrapMasterKey(
        masterKey: masterKey,
        wrapKey: wrapKey,
      );

      final wrongKey =
          await kd.deriveWrapKey(password: 'wrong', salt: salt);
      expect(
        () => kd.unwrapMasterKey(
          wrappedKey: wrap.wrappedKey,
          nonce: wrap.nonce,
          wrapKey: wrongKey,
        ),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('같은 비밀번호 + 다른 salt → 다른 wrap_key', () async {
      final kd = _fastKd();
      const password = 'p';
      final salt1 = Uint8List.fromList(List.generate(16, (i) => i));
      final salt2 = Uint8List.fromList(List.generate(16, (i) => i + 1));

      final k1Bytes =
          await (await kd.deriveWrapKey(password: password, salt: salt1))
              .extractBytes();
      final k2Bytes =
          await (await kd.deriveWrapKey(password: password, salt: salt2))
              .extractBytes();
      expect(k1Bytes, isNot(k2Bytes));
    });
  });

  group('QuoteCipher (AES-256-GCM)', () {
    test('encrypt → decrypt round-trip (한글 본문 포함)', () async {
      final cipher = QuoteCipher();
      final key = SecretKey(List.generate(32, (i) => i));
      const plain = '가장 깊은 밤에 가장 빛나는 별이 보인다.';

      final blob = await cipher.encrypt(plaintext: plain, masterKey: key);
      final back = await cipher.decrypt(blob: blob, masterKey: key);
      expect(back, plain);
    });

    test('잘못된 키로 decrypt면 SecretBoxAuthenticationError', () async {
      final cipher = QuoteCipher();
      final key1 = SecretKey(List.generate(32, (i) => i));
      final key2 = SecretKey(List.generate(32, (i) => 255 - i));

      final blob = await cipher.encrypt(plaintext: 'secret', masterKey: key1);
      expect(
        () => cipher.decrypt(blob: blob, masterKey: key2),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('blob 변조 시 SecretBoxAuthenticationError', () async {
      final cipher = QuoteCipher();
      final key = SecretKey(List.generate(32, (i) => i));

      final blob = await cipher.encrypt(plaintext: 'secret', masterKey: key);
      // 마지막 바이트(tag 일부) 뒤집기
      blob[blob.length - 1] ^= 0xFF;
      expect(
        () => cipher.decrypt(blob: blob, masterKey: key),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    });

    test('같은 평문 → 매번 다른 ciphertext (nonce 랜덤)', () async {
      final cipher = QuoteCipher();
      final key = SecretKey(List.generate(32, (i) => i));

      final a = await cipher.encrypt(plaintext: 'same', masterKey: key);
      final b = await cipher.encrypt(plaintext: 'same', masterKey: key);
      expect(a, isNot(b));
    });

    test('빈 문자열도 round-trip', () async {
      final cipher = QuoteCipher();
      final key = SecretKey(List.generate(32, (i) => i));
      final blob = await cipher.encrypt(plaintext: '', masterKey: key);
      expect(await cipher.decrypt(blob: blob, masterKey: key), '');
    });

    test('2000자 본문 round-trip (quotes.text 상한)', () async {
      final cipher = QuoteCipher();
      final key = SecretKey(List.generate(32, (i) => i));
      final plain = '가' * 2000;
      final blob = await cipher.encrypt(plaintext: plain, masterKey: key);
      expect(await cipher.decrypt(blob: blob, masterKey: key), plain);
    });
  });
}
