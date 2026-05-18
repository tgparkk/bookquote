// 사용자 표시 프로필 (`profiles` 테이블 1:1) — PR18-B.
//
// 친구 검색 결과·친구 프로필 헤더·책 상세 "친구 N명" 미니리스트 등에서 사용.
// V1.0 미사용 `public_handle`도 포함(V1.0.1 hotfix 슬롯, DECISIONS 2026-05-18 P1).
//
// `is_library_public=false`인 프로필은 SELECT RLS(`using is_library_public = true
// OR id = auth.uid()`)가 거르므로 검색 결과·`/u/:userId`에 0 row. 본인 프로필만
// 본인이 read 가능. 따라서 검색 결과에 도착한 Profile은 항상 `isLibraryPublic=true`
// 가정 가능(클라 단에서 한 번 더 명시 필터해 defense in depth).

import 'package:flutter/foundation.dart';

@immutable
class Profile {
  const Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    this.publicHandle,
    required this.isLibraryPublic,
  });

  final String id;

  /// 가입 시 이메일 local-part로 자동 채워짐. 본명 노출 위험이 있어 PR18-B에서
  /// Me에 "공개 닉네임 편집" 다이얼로그 + email local-part 패턴 감지 도입.
  final String? displayName;

  final String? avatarUrl;

  /// V1.0 미사용. V1.0.1 hotfix에서 "@핸들" 검색 경로로 활성화 예정.
  final String? publicHandle;

  /// 친구 서재 탐험 게이트. true면 검색·`/u/:userId`에 노출, 친구가 책·인용구 read 가능.
  final bool isLibraryPublic;

  factory Profile.fromRow(Map<String, dynamic> row) => Profile(
        id: row['id'] as String,
        displayName: row['display_name'] as String?,
        avatarUrl: row['avatar_url'] as String?,
        publicHandle: row['public_handle'] as String?,
        isLibraryPublic: (row['is_library_public'] as bool?) ?? false,
      );
}
