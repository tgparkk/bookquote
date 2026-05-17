// PR16-B: CryptoEnvelope DB 직렬화 — PostgREST bytea \x prefix hex 양방향.
//
// EnvelopeRepository 자체는 Supabase 네트워크 필요라 여기서 안 다룸 —
// fromRow/toInsertRow/toRewrapPatch + 헬퍼 encode/decodePgBytea만 검증.

import 'dart:typed_data';

import 'package:bookquote/features/crypto/domain/envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('encodePgBytea / decodePgBytea', () {
    test('빈 bytes', () {
      expect(encodePgBytea(const <int>[]), r'\x');
      expect(decodePgBytea(r'\x'), Uint8List(0));
    });

    test('round-trip — 0~255 전 범위', () {
      final bytes = Uint8List.fromList(List<int>.generate(256, (i) => i));
      final encoded = encodePgBytea(bytes);
      expect(encoded.startsWith(r'\x'), isTrue);
      expect(encoded.length, 2 + 256 * 2);
      expect(decodePgBytea(encoded), bytes);
    });

    test('hex는 소문자 + 항상 2자리 padded', () {
      expect(encodePgBytea(const [0x00, 0x0a, 0xff]), r'\x000aff');
    });

    test('prefix 없는 hex string도 디코드 (방어적)', () {
      expect(decodePgBytea('deadbeef'),
          Uint8List.fromList(const [0xde, 0xad, 0xbe, 0xef]));
    });

    test('홀수 길이 hex는 FormatException', () {
      expect(() => decodePgBytea(r'\xabc'), throwsA(isA<FormatException>()));
    });
  });

  group('CryptoEnvelope fromRow / toInsertRow', () {
    final envelope = CryptoEnvelope(
      wrappedKey: Uint8List.fromList(List<int>.generate(48, (i) => i)),
      wrapNonce: Uint8List.fromList(List<int>.generate(12, (i) => i + 100)),
      kdfSalt: Uint8List.fromList(List<int>.generate(16, (i) => i + 200)),
      kdfIters: 600000,
      kdfVersion: 1,
    );

    test('toInsertRow → fromRow round-trip', () {
      final row = envelope.toInsertRow();
      // user_id는 caller가 덧붙이는 거라 row에는 들어가지 않는다.
      expect(row.containsKey('user_id'), isFalse);
      final back = CryptoEnvelope.fromRow(row);
      expect(back.wrappedKey, envelope.wrappedKey);
      expect(back.wrapNonce, envelope.wrapNonce);
      expect(back.kdfSalt, envelope.kdfSalt);
      expect(back.kdfIters, envelope.kdfIters);
      expect(back.kdfVersion, envelope.kdfVersion);
    });

    test('toInsertRow 컬럼명은 snake_case + bytea는 \\x prefix string', () {
      final row = envelope.toInsertRow();
      expect(row.keys.toSet(), {
        'wrapped_key',
        'wrap_nonce',
        'kdf_salt',
        'kdf_iters',
        'kdf_version',
      });
      expect(row['wrapped_key'], isA<String>());
      expect((row['wrapped_key'] as String).startsWith(r'\x'), isTrue);
    });

    test('toRewrapPatch는 wrapped_key/wrap_nonce/kdf_salt만 포함', () {
      // 비밀번호 변경 시 K는 그대로 — kdf_iters/kdf_version은 명시 회수 전엔 동일.
      final patch = envelope.toRewrapPatch();
      expect(patch.keys.toSet(), {'wrapped_key', 'wrap_nonce', 'kdf_salt'});
    });

    test('fromRow은 PostgREST 실제 응답 형식(\\x hex) 그대로 받는다', () {
      // 실제 PostgREST가 보내는 모양을 직접 만들어 fromRow에 흘려본다.
      final row = <String, dynamic>{
        'user_id': 'user-uuid',
        'wrapped_key': r'\x00010203',
        'wrap_nonce': r'\x' + List.generate(12, (i) => 'aa').join(),
        'kdf_salt': r'\x' + List.generate(16, (i) => '11').join(),
        'kdf_iters': 600000,
        'kdf_version': 1,
        'created_at': '2026-05-17T12:00:00Z',
        'updated_at': '2026-05-17T12:00:00Z',
      };
      final env = CryptoEnvelope.fromRow(row);
      expect(env.wrappedKey, Uint8List.fromList(const [0, 1, 2, 3]));
      expect(env.wrapNonce.length, 12);
      expect(env.kdfSalt.length, 16);
      expect(env.kdfIters, 600000);
      expect(env.kdfVersion, 1);
    });
  });
}
