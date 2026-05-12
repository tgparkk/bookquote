// 인용구 입력 화면의 작성 중 임시저장(draft).
//
// 한 번에 하나의 draft만 — 작성 중인 인용구를 keystroke마다(debounce) SharedPreferences에
// 넣어두고, 화면 재진입 시 복원한다. 앱이 죽거나 백그라운드에서 회수돼도 쓰던 구절을
// 잃지 않게 ("데이터 절대 유실 금지" — DECISIONS 2026-05-11). 저장 성공 시 / 명시적
// 폐기 시 clear. 키는 사용자별(`quote_draft_v1:<uid>`).
//
// 오프라인 저장 실패로 큐잉되는 "아웃박스"(여러 건)와는 별개 — 이건 작성 중 1건.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/quote.dart';

class QuoteDraftStore {
  QuoteDraftStore(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'quote_draft_v1';

  String _key([String? uid]) {
    final id = uid ?? supabase.auth.currentUser?.id;
    return id == null ? _prefix : '$_prefix:$id';
  }

  /// 현재(또는 [uid]) 사용자의 작성 중 draft. 없으면 null.
  QuoteInput? load([String? uid]) {
    final raw = _prefs.getString(_key(uid));
    if (raw == null) return null;
    try {
      return QuoteInput.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // 손상된 draft는 무시
    }
  }

  Future<void> save(QuoteInput draft, [String? uid]) =>
      _prefs.setString(_key(uid), jsonEncode(draft.toJson()));

  Future<void> clear([String? uid]) => _prefs.remove(_key(uid));
}

final quoteDraftStoreProvider = FutureProvider<QuoteDraftStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return QuoteDraftStore(prefs);
});
