// 서재 [인용구] hub 모드의 "전체 N" — 무드별 개수 합이 아니라 실제 인용구 수.
//
// 무드 여러 개 단 인용구는 무드마다 세이고, 무드 없는 인용구는 빠지므로 무드 합
// ≠ 인용구 수. (2026-10-10 점검: 실제 12개인데 hub 헤더·칩이 17로 표시)

import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/presentation/quote_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepo implements QuoteRepository {
  _FakeRepo({this.countsFail = false});
  final bool countsFail;

  @override
  Future<List<MoodHubSnapshot>> listMoodHubSnapshots() async => const [
        (mood: QuoteMood.insight, count: 8, sampleText: 'a', sampleText2: null),
        (mood: QuoteMood.wistful, count: 5, sampleText: 'b', sampleText2: null),
        (mood: QuoteMood.comfort, count: 4, sampleText: 'c', sampleText2: null),
      ];

  @override
  Future<MoodCounts> getMoodCounts() async {
    if (countsFail) throw Exception('rpc down');
    return (
      total: 12,
      byMood: const {
        QuoteMood.insight: 8,
        QuoteMood.wistful: 5,
        QuoteMood.comfort: 4,
      },
    );
  }

  @override
  Future<List<QuoteWithBook>> listMyQuotesWithBook({
    String? bookId,
    Set<QuoteMood>? moods,
    QuoteCursor? after,
    int limit = 15,
  }) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, _FakeRepo repo) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [quoteRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: Scaffold(body: QuoteListView())),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hub 헤더·전체 칩 = 실제 인용구 수(무드 합 17 아님)', (tester) async {
    await _pump(tester, _FakeRepo());
    expect(find.textContaining('3개 무드 · 12개 인용구', findRichText: true),
        findsOneWidget);

    await tester.tap(find.text('전체 보기'));
    await tester.pumpAndSettle();
    expect(find.text('전체 12'), findsOneWidget);
    expect(find.text('전체 17'), findsNothing);
  });

  testWidgets('전체 수 조회 실패 시 틀린 숫자 대신 생략', (tester) async {
    await _pump(tester, _FakeRepo(countsFail: true));
    expect(find.textContaining('3개 무드', findRichText: true), findsOneWidget);
    expect(find.textContaining('개 인용구', findRichText: true), findsNothing);
  });
}
