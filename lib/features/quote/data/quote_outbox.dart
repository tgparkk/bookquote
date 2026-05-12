// 오프라인 인용구 아웃박스 (경량 — DECISIONS 2026-05-11).
//
// 저장 시 네트워크 오류면 인용구 입력을 SharedPreferences에 JSON 리스트로 쌓아두고,
// 앱 포그라운드 복귀/연결 회복 시 flush()로 best-effort 재시도한다. 완전한 동기화
// 엔진(충돌 해결·실시간·책 재매칭 UI)은 V1.5 (`flows.md` Flow F).
//
// 키는 사용자별(`quote_outbox_v1:<uid>`) — 다른 계정으로 로그인해도 섞이지 않게.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/quote.dart';
import 'quote_repository.dart';

class QuoteOutbox {
  QuoteOutbox(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'quote_outbox_v1';

  String _key([String? uid]) {
    final id = uid ?? supabase.auth.currentUser?.id;
    return id == null ? _prefix : '$_prefix:$id';
  }

  List<QuoteInput> _read([String? uid]) {
    final raw = _prefs.getStringList(_key(uid)) ?? const <String>[];
    final result = <QuoteInput>[];
    for (final s in raw) {
      try {
        result.add(QuoteInput.fromJson(jsonDecode(s) as Map<String, dynamic>));
      } catch (_) {
        // 손상된 항목은 조용히 스킵
      }
    }
    return result;
  }

  Future<void> _write(List<QuoteInput> items, [String? uid]) async {
    await _prefs.setStringList(
      _key(uid),
      items.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  /// 현재(또는 [uid]) 사용자의 대기 중인 인용구 입력 목록.
  List<QuoteInput> pending([String? uid]) => _read(uid);

  /// 인용구 입력을 아웃박스 끝에 추가.
  Future<void> enqueue(QuoteInput input, [String? uid]) async {
    final items = _read(uid)..add(input);
    await _write(items, uid);
  }

  /// 아웃박스 전체 비우기 (로그아웃 등).
  Future<void> clear([String? uid]) => _prefs.remove(_key(uid));

  /// 대기 항목을 순서대로 서버에 저장 시도. 성공한 항목만 큐에서 제거.
  /// 반환: 보낸 수 / 남은 수.
  Future<({int sent, int remaining})> flush(QuoteRepository repo) async {
    final items = _read();
    if (items.isEmpty) return (sent: 0, remaining: 0);
    final remaining = <QuoteInput>[];
    var sent = 0;
    for (final input in items) {
      try {
        await repo.createQuote(input);
        sent++;
      } catch (_) {
        remaining.add(input); // 실패한 건 남겨둔다 — 다음 기회 재시도
      }
    }
    await _write(remaining);
    return (sent: sent, remaining: remaining.length);
  }
}

/// SharedPreferences 인스턴스를 한 번 얻어 [QuoteOutbox]를 만든다.
final quoteOutboxProvider = FutureProvider<QuoteOutbox>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return QuoteOutbox(prefs);
});
