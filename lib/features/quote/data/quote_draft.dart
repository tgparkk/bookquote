// 인용구 입력 화면의 작성 중 임시저장(draft).
//
// 한 번에 하나의 draft만 — 작성 중인 인용구를 keystroke마다(debounce) SharedPreferences에
// 넣어두고, 화면 재진입 시 복원한다. 앱이 죽거나 백그라운드에서 회수돼도 쓰던 구절을
// 잃지 않게 ("데이터 절대 유실 금지" — DECISIONS 2026-05-11). 저장 성공 시 / 명시적
// 폐기 시 clear. 키는 사용자별(`quote_draft_v1:<uid>`).
//
// 오프라인 저장 실패로 큐잉되는 "아웃박스"(여러 건)와는 별개 — 이건 작성 중 1건.
//
// 저장 포맷 v2 (PR14-E F5): `{input: <QuoteInput JSON>, savedAt: <ISO8601>}` 래퍼.
// 복원 시 "N분/시간/일 전" 단서를 SnackBar에 보여 한 달 만에 재진입한 사용자도
// 맥락 없이 선택 강요받지 않게 한다. 구 포맷(래핑 안 된 QuoteInput JSON)도 호환.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/quote.dart';

/// load() 결과 — input + savedAt(있으면).
typedef LoadedDraft = ({QuoteInput input, DateTime savedAt});

class QuoteDraftStore {
  QuoteDraftStore(this._prefs);

  final SharedPreferences _prefs;

  static const _prefix = 'quote_draft_v1';

  String _key([String? uid]) {
    final id = uid ?? supabase.auth.currentUser?.id;
    return id == null ? _prefix : '$_prefix:$id';
  }

  /// 현재(또는 [uid]) 사용자의 작성 중 draft. 없으면 null.
  ///
  /// 신규 포맷(`{input, savedAt}`)이면 그대로 파싱, 구 포맷(QuoteInput JSON 단독)이면
  /// savedAt을 현재시각으로 채워 호환. 손상 시 null.
  LoadedDraft? load([String? uid]) {
    final raw = _prefs.getString(_key(uid));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      // 신규 포맷
      if (json['input'] is Map && json['savedAt'] is String) {
        return (
          input: QuoteInput.fromJson(json['input'] as Map<String, dynamic>),
          savedAt: DateTime.parse(json['savedAt'] as String),
        );
      }
      // 구 포맷 — QuoteInput JSON 그대로 (savedAt 추정 불가 → 현재로)
      final input = QuoteInput.fromJson(json);
      return (input: input, savedAt: DateTime.now());
    } catch (_) {
      return null; // 손상된 draft는 무시
    }
  }

  Future<void> save(QuoteInput draft, [String? uid, DateTime? savedAt]) =>
      _prefs.setString(
        _key(uid),
        jsonEncode(<String, dynamic>{
          'input': draft.toJson(),
          'savedAt': (savedAt ?? DateTime.now()).toIso8601String(),
        }),
      );

  Future<void> clear([String? uid]) => _prefs.remove(_key(uid));
}

final quoteDraftStoreProvider = FutureProvider<QuoteDraftStore>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return QuoteDraftStore(prefs);
});
