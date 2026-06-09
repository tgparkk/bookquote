// 좋아요 상태 providers (PR-LB).
//
// 단건 카운트는 [likeCountProvider] family로 watch(책 상세의 한 후기 등 단일 맥락).
// 리스트(홈 피드·후기 목록)는 화면 쪽에서 [LikeRepository.counts]로 가시 id를 한 번에
// 배치 조회해 버튼에 seed하는 게 효율적 — family를 항목마다 watch하면 N+1이 된다.
//
// 낙관적 토글 UI 상태는 버튼 위젯(PR-LC)이 들고, 여기서는 네트워크 호출 후 단건
// provider invalidate로 권위 값과 재동기화하는 액션만 제공한다.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/like_repository.dart';

/// 좋아요 대상 식별자 — family 키. record라 구조적 동등성으로 키 안정.
typedef LikeTarget = ({LikeTargetKind kind, String id});

/// 단일 대상의 좋아요 집계. 단건 맥락(책 상세 등)에서 watch.
/// 토글 후 `ref.invalidate(likeCountProvider(target))`로 재조회.
final likeCountProvider =
    FutureProvider.autoDispose.family<LikeCount, LikeTarget>((ref, target) async {
  final repo = ref.read(likeRepositoryProvider);
  final map = await repo.counts(kind: target.kind, targetIds: [target.id]);
  return map[target.id] ?? kEmptyLikeCount;
});

/// 좋아요 토글 액션 컨트롤러. 네트워크 호출 + 단건 카운트 provider 재동기화만 담당
/// (버튼의 낙관적 표시는 위젯이 별도 관리). 화면당 하나의 컨트롤러를 공유해도
/// 무방 — 버튼은 자기 낙관적 상태를 보고, 컨트롤러는 fire-and-resync 역할.
class LikeActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// [target]을 [liked] 상태로 설정. 성공 시 단건 카운트 provider를 invalidate해
  /// 권위 값으로 재동기화한다. 실패는 state.error로 노출(호출자가 롤백·SnackBar).
  Future<void> setLiked(LikeTarget target, bool liked) async {
    final repo = ref.read(likeRepositoryProvider);
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(() async {
      await repo.setLiked(kind: target.kind, targetId: target.id, liked: liked);
      ref.invalidate(likeCountProvider(target));
    });
  }
}

final likeActionControllerProvider =
    AsyncNotifierProvider<LikeActionController, void>(LikeActionController.new);
