// 친구 찾기 화면 위젯 테스트 — 검색어 입력 전 '둘러보기' 목록.
//
// followRepositoryProvider를 Mock으로 override (실제 SupabaseClient 생성 X).

import 'package:bookquote/features/follow/data/follow_repository.dart';
import 'package:bookquote/features/follow/presentation/friend_search_screen.dart';
import 'package:bookquote/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class _FakeFollowRepo extends Mock implements FollowRepository {
  _FakeFollowRepo(this._discover);
  final List<Profile> _discover;

  @override
  Future<List<Profile>> listPublicProfiles({int limit = 50}) async => _discover;

  @override
  Future<bool> isFollowing(String userId) async => false;

  @override
  Future<List<Profile>> searchByDisplayName(
    String query, {
    int limit = 20,
  }) async =>
      const <Profile>[];
}

Profile _profile(String id, String name) => Profile(
      id: id,
      displayName: name,
      avatarUrl: null,
      publicHandle: null,
      isLibraryPublic: true,
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<Profile> discover,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          followRepositoryProvider.overrideWithValue(_FakeFollowRepo(discover)),
        ],
        child: const MaterialApp(home: FriendSearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('검색 전 — 공개 프로필 둘러보기 목록 노출', (tester) async {
    await pump(
      tester,
      discover: [_profile('u2', '지윤'), _profile('u3', '민호')],
    );

    expect(find.text('둘러보기'), findsOneWidget);
    expect(find.text('지윤'), findsOneWidget);
    expect(find.text('민호'), findsOneWidget);
  });

  testWidgets('공개 프로필 0명 → "아직 둘러볼 공개 서재가 없어요" 빈 안내', (tester) async {
    await pump(tester, discover: const []);

    expect(find.text('아직 둘러볼 공개 서재가 없어요'), findsOneWidget);
  });
}
