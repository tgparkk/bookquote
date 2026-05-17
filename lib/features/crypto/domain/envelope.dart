// E2EE envelope 도메인 모델 (PR16-A).
//
// PBKDF2(password, salt, iters)로 wrap_key 파생 → AES-256-GCM(wrap_key, nonce)으로
// 마스터키 K wrap → server에 저장. 비밀번호 변경 시 K는 그대로 두고 salt + nonce +
// wrapped_key만 새로.
//
// DB 직렬화(fromRow/toRow)는 PR16-B의 repository 통합 시 추가. PR16-A는 value class만.

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
}
