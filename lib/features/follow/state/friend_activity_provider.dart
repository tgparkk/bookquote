// 홈 "최근 친구 활동" 1줄 배너 상태 (PR20-D — UX#4 K-factor 다리).
//
// 매니저 UX 전문가 #3 R3: V1엔 Realtime·push 없음 → 친구가 새 인용구 추가했음을
// 인지할 길 0%가 D14 retention 최대 구멍. 비-Realtime poll로 해소 — 앱 켜면 fetch,
// 보면 last_seen 갱신.
//
// `friend_recent_activity(since)` RPC가 RLS 게이트 통과 row만 group-by 집계.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/supabase/supabase_init.dart';

/// 친구 1명의 since-이후 공개 인용구 카운트 + 최근 시각.
typedef FriendActivity = ({
  String userId,
  String? displayName,
  String? avatarUrl,
  int count,
  DateTime latest,
});

const String _kLastSeenKey = 'friend_activity_last_seen_v1';

/// `last_seen` 미설정 시 기본 lookback 윈도우.
const Duration _kDefaultLookback = Duration(days: 7);

Future<DateTime> _loadSince() async {
  final prefs = await SharedPreferences.getInstance();
  final iso = prefs.getString(_kLastSeenKey);
  if (iso == null) {
    return DateTime.now().toUtc().subtract(_kDefaultLookback);
  }
  return DateTime.tryParse(iso) ??
      DateTime.now().toUtc().subtract(_kDefaultLookback);
}

Future<void> markFriendActivitySeen() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_kLastSeenKey, DateTime.now().toUtc().toIso8601String());
}

/// 친구 최근 활동 — RLS+RPC 통과 user별 카운트. autoDispose라 홈 화면 떠나면 해제.
/// 미초기화/미로그인이면 빈 리스트.
final friendActivityProvider =
    FutureProvider.autoDispose<List<FriendActivity>>((ref) async {
  if (!isSupabaseReady) return const [];
  if (supabase.auth.currentUser == null) return const [];
  final since = await _loadSince();
  try {
    final rows = await supabase.rpc(
      'friend_recent_activity',
      params: {'since': since.toIso8601String()},
    ) as List<dynamic>;
    return rows.cast<Map<String, dynamic>>().map((r) {
      return (
        userId: r['user_id'] as String,
        displayName: r['display_name'] as String?,
        avatarUrl: r['avatar_url'] as String?,
        count: (r['cnt'] as num).toInt(),
        latest: DateTime.parse(r['latest'] as String),
      );
    }).toList(growable: false);
  } catch (_) {
    return const [];
  }
});
