// 활동 탭 "친구가 읽은 책" 섹션 상태.
//
// `friend_recent_books(p_limit)` RPC가 RLS(user_books_friends_read +
// profiles_public_select) 게이트 통과 row만 반환. 본인 제외는 RPC가 처리.
// 미초기화/미로그인이면 빈 리스트 — 호출자가 빈 결과 시 섹션 숨김.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_init.dart';

/// 친구가 최근 담은 책 1건.
typedef FriendRecentBook = ({
  String userId,
  String? displayName,
  String? avatarUrl,
  String bookId,
  String bookTitle,
  String? bookCoverUrl,
  DateTime addedAt,
});

/// 친구가 최근 담은 책 — RLS+RPC 통과 row. autoDispose라 활동 화면 떠나면 해제.
final friendRecentBooksProvider =
    FutureProvider.autoDispose<List<FriendRecentBook>>((ref) async {
  if (!isSupabaseReady) return const [];
  if (supabase.auth.currentUser == null) return const [];
  try {
    final rows = await supabase.rpc(
      'friend_recent_books',
      params: {'p_limit': 20},
    ) as List<dynamic>;
    return rows.cast<Map<String, dynamic>>().map((r) {
      return (
        userId: r['user_id'] as String,
        displayName: r['display_name'] as String?,
        avatarUrl: r['avatar_url'] as String?,
        bookId: r['book_id'] as String,
        bookTitle: (r['book_title'] as String?) ?? '(제목 없음)',
        bookCoverUrl: r['book_cover_url'] as String?,
        addedAt: DateTime.parse(r['added_at'] as String),
      );
    }).toList(growable: false);
  } catch (_) {
    return const [];
  }
});
