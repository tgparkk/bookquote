// E2EE envelope 도메인 모델 (PR16-A → PR16-B 직렬화 통합).
//
// PBKDF2(password, salt, iters)로 wrap_key 파생 → AES-256-GCM(wrap_key, nonce)으로
// 마스터키 K wrap → server에 저장. 비밀번호 변경 시 K는 그대로 두고 salt + nonce +
// wrapped_key만 새로.
//
// Supabase bytea 직렬화: PostgREST는 bytea를 `\x` prefix hex string으로 응답하고
// INSERT/UPDATE 시에도 동일 형식 string으로 보내면 자동 디코딩한다.
// fromRow에서 prefix를 떼고 hex 디코드, toInsertRow에서 prefix 붙여 hex 인코드.

import 'dart:typed_data';

class CryptoEnvelope {
  const CryptoEnvelope({
    required this.wrappedKey,
    required this.wrapNonce,
    required this.kdfSalt,
    required this.kdfIters,
    required this.kdfVersion,
  });

  /// AES-256-GCM(wrap_key)으로 wrap된 마스터키 K. (ciphertext || tag 16B).
  final Uint8List wrappedKey;

  /// wrapped_key의 AES-GCM nonce (12B).
  final Uint8List wrapNonce;

  /// PBKDF2 salt (16B).
  final Uint8List kdfSalt;

  /// PBKDF2 iteration count (V1=600000).
  final int kdfIters;

  /// KDF 알고리즘 버전 (V1=1: PBKDF2-HMAC-SHA512).
  final int kdfVersion;

  /// `user_crypto_envelopes` row → 도메인. PostgREST가 bytea 컬럼을
  /// `\x...` hex string으로 반환한다고 가정.
  factory CryptoEnvelope.fromRow(Map<String, dynamic> row) {
    return CryptoEnvelope(
      wrappedKey: decodePgBytea(row['wrapped_key'] as String),
      wrapNonce: decodePgBytea(row['wrap_nonce'] as String),
      kdfSalt: decodePgBytea(row['kdf_salt'] as String),
      kdfIters: (row['kdf_iters'] as num).toInt(),
      kdfVersion: (row['kdf_version'] as num).toInt(),
    );
  }

  /// 도메인 → INSERT 페이로드. `user_id`는 caller(repository)가 덧붙인다.
  Map<String, dynamic> toInsertRow() => <String, dynamic>{
        'wrapped_key': encodePgBytea(wrappedKey),
        'wrap_nonce': encodePgBytea(wrapNonce),
        'kdf_salt': encodePgBytea(kdfSalt),
        'kdf_iters': kdfIters,
        'kdf_version': kdfVersion,
      };

  /// 비밀번호 변경(rewrap) 시 UPDATE 페이로드 — K는 그대로라 wrapped_key/wrap_nonce/
  /// kdf_salt만 갱신. kdf_iters/kdf_version은 사용자가 KDF 회수 안 한 한 동일.
  Map<String, dynamic> toRewrapPatch() => <String, dynamic>{
        'wrapped_key': encodePgBytea(wrappedKey),
        'wrap_nonce': encodePgBytea(wrapNonce),
        'kdf_salt': encodePgBytea(kdfSalt),
      };
}

/// PostgREST hex 응답(`\xDEADBEEF`) → bytes. prefix 없으면 그대로 hex로 시도.
/// 잘못된 형식은 [FormatException].
Uint8List decodePgBytea(String raw) {
  final hex = raw.startsWith(r'\x') ? raw.substring(2) : raw;
  if (hex.length.isOdd) {
    throw const FormatException('bytea hex length odd');
  }
  final out = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// bytes → `\xDEADBEEF` (PostgREST가 INSERT/UPDATE 시 받아주는 형식).
String encodePgBytea(List<int> bytes) {
  final buf = StringBuffer(r'\x');
  for (final b in bytes) {
    buf.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}
