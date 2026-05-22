// 신고·차단 Riverpod providers (PR25).
//
// moderationRepositoryProvider는 repository 파일에 정의(follow_repository 패턴 일관).
// 본 파일은 화면 단위 파생 provider만 모은다.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile.dart';
import '../data/moderation_repository.dart';

export '../data/moderation_repository.dart' show moderationRepositoryProvider;

/// 내가 차단한 사용자 목록. 차단 목록 화면(`/me/blocked`)에서 watch.
/// autoDispose — 화면을 떠나면 해제, 재진입 시 최신 fetch.
final blockedListProvider =
    FutureProvider.autoDispose<List<Profile>>((ref) async {
  return ref.watch(moderationRepositoryProvider).listBlocked();
});
