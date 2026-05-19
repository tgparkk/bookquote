import 'package:bookquote/features/quote/quote_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  void mockClipboard({required String text, required bool hasStrings}) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.hasStrings') {
        return <String, dynamic>{'value': hasStrings};
      }
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': text};
      }
      return null;
    });
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: QuoteInputScreen()),
      ),
    );
    await tester.pump(); // postFrame 콜백(_bootstrap) 1차 실행
  }

  testWidgets('기본 폼이 렌더된다 — 본문 입력·책 연결·무드 칩', (tester) async {
    await pumpScreen(tester);

    expect(find.text('인용구 추가'), findsOneWidget);
    expect(find.text('책 연결'), findsOneWidget);
    expect(find.byType(TextField), findsAtLeastNWidgets(2)); // 본문 + 페이지
    // 무드 칩 5종
    for (final label in ['위로', '먹먹', '새벽3시', '통찰', '설렘']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('본문이 비어 있으면 저장 CTA가 비활성, 입력하면 활성된다', (tester) async {
    await pumpScreen(tester);

    final ctaFinder = find.widgetWithText(ElevatedButton, '저장');
    expect(tester.widget<ElevatedButton>(ctaFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '가장 깊은 밤에 가장 빛나는 별이 보인다.');
    await tester.pump();

    expect(tester.widget<ElevatedButton>(ctaFinder).onPressed, isNotNull);
    expect(find.textContaining('/ 2000'), findsOneWidget); // 글자수 카운터
  });

  testWidgets(
    'UX#1 — 단일 [저장] CTA만 노출, [카드 만들기 →]·[저장만 하기] 제거 (PR20-A)',
    (tester) async {
      await pumpScreen(tester);
      // 입력 화면 CTA는 [저장] 하나뿐 — 카드 디자인/바로 공유 분기는 저장 후 SnackBar.
      expect(find.widgetWithText(ElevatedButton, '저장'), findsOneWidget);
      expect(find.text('카드 만들기 →'), findsNothing);
      expect(find.text('저장만 하기'), findsNothing);
    },
  );

  testWidgets('무드를 4개째 고르려 하면 한도 SnackBar가 뜬다', (tester) async {
    await pumpScreen(tester);

    for (final label in ['위로', '먹먹', '새벽3시']) {
      await tester.tap(find.text(label));
      await tester.pump();
    }
    await tester.tap(find.text('통찰'));
    await tester.pump();

    expect(find.textContaining('고를 수 있어요'), findsOneWidget); // 한도 SnackBar
  });

  testWidgets('페이지 0 입력 시 안내 SnackBar가 뜨고 저장이 차단된다 (B5)',
      (tester) async {
    await pumpScreen(tester);

    // 본문 채우기 — CTA 활성화 조건
    await tester.enterText(find.byType(TextField).first, '한 줄 인용구');
    await tester.pump();
    // 페이지 0 입력
    await tester.enterText(find.byType(TextField).at(1), '0');
    await tester.pump();

    await tester.tap(find.widgetWithText(ElevatedButton, '저장'));
    await tester.pump();

    expect(find.textContaining('쪽수는 1 이상이어야'), findsOneWidget);
  });

  testWidgets('클립보드 텍스트가 2000자를 넘으면 truncate되고 안내 SnackBar가 뜬다 (B6)',
      (tester) async {
    final longText = 'ㄱ' * 2001;
    mockClipboard(text: longText, hasStrings: true);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: QuoteInputScreen()),
      ),
    );
    // postFrame _bootstrap → _checkClipboard async → 배너 표시까지 두어 번 pump.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('붙여넣기'), findsOneWidget,
        reason: '클립보드에 텍스트 있으므로 배너 표시');
    await tester.tap(find.text('붙여넣기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // 본문 TextField에 truncate된 텍스트 (2000자)
    final body = tester.widget<TextField>(find.byType(TextField).first);
    expect(body.controller!.text.runes.length, 2000);
    expect(find.textContaining('앞부분만 붙여넣었어요'), findsOneWidget);
  });
}
