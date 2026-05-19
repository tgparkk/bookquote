// PR20-D — 친구 최근 활동 배너 위젯 테스트.
//
// 데이터 0건 → 자체 숨김 (빈상태 회피). 1건 → "지윤님이 새 인용구 N개" 단수 카피.
// ≥2건 → "지윤 외 N명" 카피 분기.

import 'package:bookquote/features/follow/presentation/widgets/friend_activity_banner.dart';
import 'package:bookquote/features/follow/state/friend_activity_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

FriendActivity _activity(String name, {int count = 1, String? id}) => (
      userId: id ?? 'u-${name.hashCode}',
      displayName: name,
      avatarUrl: null,
      count: count,
      latest: DateTime(2026, 5, 19),
    );

GoRouter _router() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(body: SafeArea(child: FriendActivityBanner())),
        ),
        GoRoute(path: '/u/:userId', builder: (_, _) => const Scaffold()),
      ],
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<FriendActivity> activities,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendActivityProvider.overrideWith((ref) async => activities),
        ],
        child: MaterialApp.router(routerConfig: _router()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('빈 리스트 → 배너 자체 숨김', (tester) async {
    await pump(tester, activities: const []);
    expect(find.byType(InkWell), findsNothing);
    expect(find.textContaining('보탰어요'), findsNothing);
  });

  testWidgets('1건 → "지윤님이 새 인용구 3개를 보탰어요"', (tester) async {
    await pump(tester, activities: [_activity('지윤', count: 3)]);
    expect(find.text('지윤님이 새 인용구 3개를 보탰어요'), findsOneWidget);
  });

  testWidgets('≥2건 → "지윤 외 N명" 카피', (tester) async {
    await pump(tester, activities: [
      _activity('지윤', count: 3),
      _activity('민호', count: 1),
      _activity('하나', count: 2),
    ]);
    expect(find.text('지윤 외 2명이 새 인용구를 보탰어요'), findsOneWidget);
  });
}
