// PR22 — MoodHubGrid 위젯 단위 테스트.
//
// QuoteListView의 hub/단면 분기는 Repository 의존이 깊어 폰 시각 검증에서. 여기는
// 위젯 입력→출력 회귀 가드만:
//   - 카드 렌더 + 카운트 표시
//   - 발췌 없는 카드 placeholder
//   - 카드 탭 시 onMoodTap 콜백에 mood 전달
//   - 빈 snapshots 크래시 없음

import 'package:bookquote/features/quote/data/quote_repository.dart'
    show MoodHubSnapshot;
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/presentation/widgets/mood_hub_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpGrid(
  WidgetTester tester, {
  required List<MoodHubSnapshot> snapshots,
  required ValueChanged<QuoteMood> onMoodTap,
}) async {
  // 폰 비율 확보 — childAspectRatio 0.95에서 2열이 좁아지면 ellipsis로 라벨이
  // 잘려 findsOneWidget가 실패할 수 있음.
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MoodHubGrid(snapshots: snapshots, onMoodTap: onMoodTap),
      ),
    ),
  );
}

void main() {
  testWidgets('무드 카드들이 렌더링되고 카운트·발췌가 표시된다', (tester) async {
    await _pumpGrid(
      tester,
      snapshots: const [
        (mood: QuoteMood.comfort, count: 12, sampleText: '위로의 한 줄 발췌'),
        (mood: QuoteMood.wistful, count: 7, sampleText: '먹먹한 한 줄'),
        (mood: QuoteMood.lateNight, count: 4, sampleText: null),
      ],
      onMoodTap: (_) {},
    );
    expect(find.text('위로'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('먹먹'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.textContaining('위로의 한 줄 발췌'), findsOneWidget);
    // 발췌 없는 카드는 placeholder.
    expect(find.text('잠긴 인용구만 있어요'), findsOneWidget);
  });

  testWidgets('카드 탭 → onMoodTap 콜백에 해당 무드 전달', (tester) async {
    QuoteMood? tappedMood;
    // sampleText는 라벨과 정확히 같은 문자열을 피한다 — find.text(라벨)가 라벨 + 발췌
    // 두 곳을 동시에 매칭해 tap 호출이 ambiguous로 실패한다.
    await _pumpGrid(
      tester,
      snapshots: const [
        (mood: QuoteMood.comfort, count: 12, sampleText: '위로의 한 줄 발췌'),
        (mood: QuoteMood.wistful, count: 7, sampleText: '먹먹한 본문 한 줄'),
        (mood: QuoteMood.insight, count: 5, sampleText: '통찰의 한 줄 발췌'),
      ],
      onMoodTap: (m) => tappedMood = m,
    );
    // '먹먹' 라벨만 정확히 매칭(exact text). 발췌는 '먹먹한…'이라 비매칭.
    await tester.tap(find.text('먹먹'));
    expect(tappedMood, QuoteMood.wistful);
  });

  testWidgets('snapshots 비어있어도 크래시 없음', (tester) async {
    await _pumpGrid(tester, snapshots: const [], onMoodTap: (_) {});
    expect(find.byType(MoodHubGrid), findsOneWidget);
  });
}
