// 내 프로필 데이터 레이어 (PR18-B).
//
// 본인 profile 조회 + 부분 갱신(display_name, is_library_public). 나머지 컬럼
// (id/avatar_url/public_handle/created_at)은 V1.0에서 수정 안 함.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/profile.dart';

class ProfileRepositoryException implements Exception {
  ProfileRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'ProfileRepositoryException($code): $message';
}

class ProfileRepository {
  ProfileRepository(this._client);

  final SupabaseClient _client;
  static const _table = 'profiles';

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw ProfileRepositoryException('NOT_AUTHENTICATED', '로그인이 필요해요.');
    }
    return uid;
  }

  /// 본인 프로필 1행. 미로그인이면 null. 가입 트리거가 빈 row를 자동 생성하므로
  /// 정상 흐름에서는 항상 존재.
  Future<Profile?> getMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final row = await _client
          .from(_table)
          .select(
            'id, display_name, avatar_url, public_handle, is_library_public',
          )
          .eq('id', uid)
          .maybeSingle();
      return row == null ? null : Profile.fromRow(row);
    } on PostgrestException catch (e) {
      throw ProfileRepositoryException('FETCH_FAILED', e.message);
    }
  }

  /// 부분 갱신. null 인자는 patch에서 제외(= 변경 없음).
  /// displayName 빈 문자열은 명시적 X — caller가 validate 후 호출.
  Future<void> updateMine({
    String? displayName,
    bool? isLibraryPublic,
  }) async {
    final uid = _requireUid();
    final patch = <String, dynamic>{};
    if (displayName != null) patch['display_name'] = displayName;
    if (isLibraryPublic != null) patch['is_library_public'] = isLibraryPublic;
    if (patch.isEmpty) return;
    try {
      await _client.from(_table).update(patch).eq('id', uid);
    } on PostgrestException catch (e) {
      throw ProfileRepositoryException('UPDATE_FAILED', e.message);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(supabase);
});

/// 본인 프로필 — Me 화면 토글·닉네임 편집에서 watch.
/// 갱신 후 `ref.invalidate(myProfileProvider)`로 재로드.
final myProfileProvider = FutureProvider.autoDispose<Profile?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMine();
});

/// `display_name`이 이메일 local-part 의심 패턴(`.` 또는 `_` 포함)인지.
/// PR18-B "내 프로필 공개" 토글 ON 직전 강제 확인 다이얼로그 트리거.
/// 빈 값/null도 true(설정 권장).
bool looksLikeEmailLocalPart(String? displayName) {
  if (displayName == null || displayName.isEmpty) return true;
  return displayName.contains('.') || displayName.contains('_');
}
