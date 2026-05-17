// user_crypto_envelopes 테이블 데이터 레이어 (PR16-B).
//
// 사용자 1명당 1 row, lazy 생성. 잠금 비밀번호 처음 설정할 때 [insert],
// 비밀번호 변경 시 [updateWrap] (K는 그대로 → 인용구 재암호화 0).
// RLS가 본인만 select/insert/update 보장. 미로그인이면 NOT_AUTHENTICATED.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/envelope.dart';

class EnvelopeRepositoryException implements Exception {
  EnvelopeRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'EnvelopeRepositoryException($code): $message';
}

class EnvelopeRepository {
  EnvelopeRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'user_crypto_envelopes';

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw EnvelopeRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    return uid;
  }

  /// 본인 envelope 1행. 잠금 비밀번호 설정 안 했으면 null.
  Future<CryptoEnvelope?> getMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from(_table)
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      return row == null ? null : CryptoEnvelope.fromRow(row);
    } on PostgrestException catch (e) {
      throw EnvelopeRepositoryException('FETCH_FAILED', e.message);
    }
  }

  /// 잠금 비밀번호 처음 설정. caller가 KeyService.createEnvelope로 만든 envelope을
  /// 그대로 넘긴다. 이미 있으면 UNIQUE 위반.
  Future<void> insert(CryptoEnvelope envelope) async {
    final uid = _requireUid();
    try {
      await _client.from(_table).insert(<String, dynamic>{
        'user_id': uid,
        ...envelope.toInsertRow(),
      });
    } on PostgrestException catch (e) {
      throw EnvelopeRepositoryException('INSERT_FAILED', e.message);
    }
  }

  /// 비밀번호 변경 — wrap만 갱신. K는 그대로라 인용구 재암호화 0.
  /// kdf_version 회수 시엔 별도 마이그레이션(차후 V2).
  Future<void> updateWrap(CryptoEnvelope envelope) async {
    final uid = _requireUid();
    try {
      await _client
          .from(_table)
          .update(envelope.toRewrapPatch())
          .eq('user_id', uid);
    } on PostgrestException catch (e) {
      throw EnvelopeRepositoryException('UPDATE_FAILED', e.message);
    }
  }
}

final envelopeRepositoryProvider = Provider<EnvelopeRepository>((ref) {
  return EnvelopeRepository(supabase);
});
