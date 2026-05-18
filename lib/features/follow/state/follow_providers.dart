// 친구 그래프 상태 (PR18-A 코어 + PR18-B 검색).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile.dart';
import '../data/follow_repository.dart';

/// 특정 사용자를 내가 팔로우 중인가. 친구 프로필 헤더(PR18-C) [+ 팔로우]/
/// [✓ 팔로잉] 버튼 상태에 사용. autoDispose — 화면 떠나면 해제.
final isFollowingProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, userId) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.isFollowing(userId);
});

/// 친구 찾기 화면 검색 결과 (PR18-B). 쿼리가 family arg.
/// 호출자(친구 찾기 화면)가 400ms debounce 후 watch.
final friendSearchProvider =
    FutureProvider.autoDispose.family<List<Profile>, String>((ref, query) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.searchByDisplayName(query);
});

/// 내 팔로잉 카운트 (PR18-B) — 홈 친구 찾기 CTA 조건부 노출
/// ("인용구 ≥1 + 친구 0명"의 친구 0 검사).
final myFollowingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(followRepositoryProvider);
  return repo.myFollowingCount();
});
