// 차단 목록 화면 위젯 테스트 (PR25).
//
// blockedListProvider override로 빈상태·목록 렌더 + [차단 해제] → unblock 호출 검증.

import 'package:bookquote/features/moderation/data/moderation_repository.dart';
import 'package:bookquote/features/moderation/presentation/blocked_users_screen.dart';
import 'package:bookquote/features/moderation/state/moderation_providers.dart';
import 'package:bookquote/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeModerationRepo implements ModerationRepository {
  int unblockCalls = 0;
  String? lastUnblocked;

  @override
  Future<void> unblock(String userId) async {
    unblockCalls++;
    lastUnblocked = userId;
  }

  @override
  Future<void> block(String userId) async {}

  @override
  Future<void> report({
    String? reportedUserId,
    String? reportedQuoteId,
    required String reason,
    String? detail,
  }) async {}

  @override
  Future<List<Profile>> listBlocked() async => const <Profile>[];
}

Profile _profile(String id, String name) => Profile(
      id: id,
      displayName: name,
      avatarUrl: null,
      publicHandle: null,
      isLibraryPublic: false,
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required List<Profile> blocked,
    ModerationRepository? repo,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          blockedListProvider.overrideWith((ref) async => blocked),
          if (repo != null)
            moderationRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('빈 목록 → "차단한 사용자가 없어요" 빈상태', (tester) async {
    await pump(tester, blocked: const []);
    expect(find.text('차단한 사용자가 없어요'), findsOneWidget);
  });

  testWidgets('차단 목록 → 이름 + [차단 해제] 노출', (tester) async {
    await pump(
      tester,
      blocked: [_profile('u2', '지윤'), _profile('u3', '민호')],
    );
    expect(find.text('지윤'), findsOneWidget);
    expect(find.text('민호'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '차단 해제'), findsNWidgets(2));
  });

  testWidgets('[차단 해제] 탭 → unblock 호출', (tester) async {
    final repo = _FakeModerationRepo();
    await pump(tester, blocked: [_profile('u2', '지윤')], repo: repo);

    await tester.tap(find.widgetWithText(OutlinedButton, '차단 해제'));
    // 무한 회전 인디케이터 때문에 pumpAndSettle 대신 명시 pump.
    await tester.pump();
    await tester.pump();

    expect(repo.unblockCalls, 1);
    expect(repo.lastUnblocked, 'u2');
  });
}
