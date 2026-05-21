// V1.0 — 내 팔로잉 명단 화면 `/me/following` 위젯 테스트.
//
// `myFollowingProvider` override로 빈상태·목록·에러 3분기 검증.

import 'package:bookquote/features/follow/presentation/my_following_screen.dart';
import 'package:bookquote/features/follow/state/follow_providers.dart';
import 'package:bookquote/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Profile _p(String id, String name) =>
    Profile(id: id, displayName: name, isLibraryPublic: true);

void main() {
  Future<void> pump(
    WidgetTester tester, {
    List<Profile> following = const [],
    bool error = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myFollowingProvider.overrideWith((ref) async {
            if (error) throw Exception('boom');
            return following;
          }),
        ],
        child: const MaterialApp(home: MyFollowingScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('팔로잉 0명 → 빈상태 + [친구 찾기]', (tester) async {
    await pump(tester);

    expect(find.text('아직 팔로우한 사람이 없어요'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '친구 찾기'), findsOneWidget);
  });

  testWidgets('팔로잉 목록 렌더 — 이름·타일 수', (tester) async {
    await pump(tester, following: [_p('u1', '지윤'), _p('u2', '민준')]);

    expect(find.text('지윤'), findsOneWidget);
    expect(find.text('민준'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(2));
  });

  testWidgets('로드 실패 → [다시 시도]', (tester) async {
    await pump(tester, error: true);

    expect(find.widgetWithText(OutlinedButton, '다시 시도'), findsOneWidget);
  });
}
