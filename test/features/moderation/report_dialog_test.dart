// 신고 다이얼로그 위젯 테스트 (PR25).
//
// showReportDialog → 사유 선택 게이팅 + moderation_repository.report 호출 검증.
// 실제 SupabaseClient 생성 X — ModerationRepository를 implements한 페이크로 override.

import 'package:bookquote/features/moderation/data/moderation_repository.dart';
import 'package:bookquote/features/moderation/presentation/report_dialog.dart';
import 'package:bookquote/features/profile/domain/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeModerationRepo implements ModerationRepository {
  int reportCalls = 0;
  String? lastReason;
  String? lastReportedUserId;
  String? lastReportedQuoteId;

  @override
  Future<void> report({
    String? reportedUserId,
    String? reportedQuoteId,
    required String reason,
    String? detail,
  }) async {
    reportCalls++;
    lastReason = reason;
    lastReportedUserId = reportedUserId;
    lastReportedQuoteId = reportedQuoteId;
  }

  @override
  Future<void> block(String userId) async {}

  @override
  Future<void> unblock(String userId) async {}

  @override
  Future<List<Profile>> listBlocked() async => const <Profile>[];
}

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    _FakeModerationRepo repo, {
    String? reportedUserId,
    String? reportedQuoteId,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          moderationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showReportDialog(
                    context,
                    reportedUserId: reportedUserId,
                    reportedQuoteId: reportedQuoteId,
                    targetLabel: '지윤님',
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
  }

  testWidgets('사유 선택 전 — [신고] 버튼 비활성', (tester) async {
    final repo = _FakeModerationRepo();
    await openDialog(tester, repo, reportedUserId: 'u2');

    expect(find.text('신고하기'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '신고'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('사유 선택 후 [신고] → report 호출(사유 코드 전달)', (tester) async {
    final repo = _FakeModerationRepo();
    await openDialog(tester, repo, reportedUserId: 'u2');

    await tester.tap(find.text('스팸·광고·도배'));
    await tester.pump();
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '신고'),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '신고'));
    await tester.pumpAndSettle();

    expect(repo.reportCalls, 1);
    expect(repo.lastReason, 'spam');
    expect(repo.lastReportedUserId, 'u2');
    expect(repo.lastReportedQuoteId, isNull);
    // 접수 후 다이얼로그 닫힘 + SnackBar 노출
    expect(find.text('신고하기'), findsNothing);
    expect(find.textContaining('신고가 접수됐어요'), findsOneWidget);
  });

  testWidgets('인용구 신고 — reportedQuoteId 전달', (tester) async {
    final repo = _FakeModerationRepo();
    await openDialog(tester, repo, reportedQuoteId: 'q9');

    await tester.tap(find.text('음란물·선정적 콘텐츠'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '신고'));
    await tester.pumpAndSettle();

    expect(repo.reportCalls, 1);
    expect(repo.lastReason, 'sexual');
    expect(repo.lastReportedQuoteId, 'q9');
    expect(repo.lastReportedUserId, isNull);
  });

  testWidgets('취소 → report 미호출 + 다이얼로그 닫힘', (tester) async {
    final repo = _FakeModerationRepo();
    await openDialog(tester, repo, reportedUserId: 'u2');

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(repo.reportCalls, 0);
    expect(find.text('신고하기'), findsNothing);
  });
}
