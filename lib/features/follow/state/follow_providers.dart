// 친구 그래프 상태 — 코어 (PR18-A).
//
// PR18-A는 isFollowingProvider 1개만. 검색·카운트·리스트 provider는 PR18-B.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/follow_repository.dart';

/// 특정 사용자를 내가 팔로우 중인가. 친구 프로필 헤더(PR18-C) [+ 팔로우]/
/// [✓ 팔로잉] 버튼 상태에 사용. autoDispose — 화면 떠나면 해제.
final isFollowingProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, userId) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.isFollowing(userId);
});
