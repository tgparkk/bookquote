// 친구 프로필 상태 (PR18-C `/u/:userId`).
//
// 화면 단위 cursor 페이지네이션(인용구 무한스크롤)은 screen 내부 state로 관리 —
// quote_list_view와 같은 패턴(family Notifier 안 씀). 여기는 단발성 fetch
// (프로필 헤더·책 목록·팔로우 카운트)만 family FutureProvider로 노출.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../book/data/book_repository.dart';
import '../../book/domain/book.dart';
import '../../follow/data/follow_repository.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

/// 친구 프로필 헤더(아바타·display_name·is_library_public). null이면 "사용자를
/// 찾을 수 없어요" 빈상태. RLS상 `is_library_public=true OR id=auth.uid()`인
/// row만 반환되므로 비공개 + 비-본인이면 null.
final friendProfileProvider =
    FutureProvider.autoDispose.family<Profile?, String>((ref, userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getById(userId);
});

/// 친구 공개 서재 책 목록. RLS가 비공개·비팔로워에 0 row 응답.
final friendBooksProvider =
    FutureProvider.autoDispose.family<List<Book>, String>((ref, userId) async {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.listFriendBooks(userId);
});

/// 친구의 팔로워·팔로잉 카운트 (V1: social proof로 공개 — friend-profile.md §7).
typedef FollowCounts = ({int followers, int following});

final friendFollowCountsProvider = FutureProvider.autoDispose
    .family<FollowCounts, String>((ref, userId) async {
  final repo = ref.watch(followRepositoryProvider);
  final followers = await repo.countFollowers(userId);
  final following = await repo.countFollowing(userId);
  return (followers: followers, following: following);
});

/// 팔로워/팔로잉 시트용. follower/followee 어느 쪽인지는 family arg `.kind`.
enum FollowListKind { followers, following }

typedef _FollowListKey = ({String userId, FollowListKind kind});

final friendFollowListProvider = FutureProvider.autoDispose
    .family<List<Profile>, _FollowListKey>((ref, key) async {
  final repo = ref.watch(followRepositoryProvider);
  return switch (key.kind) {
    FollowListKind.followers => repo.listFollowers(key.userId),
    FollowListKind.following => repo.listFollowing(key.userId),
  };
});
