import 'package:bookquote/features/quote/quote_input_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

    final ctaFinder = find.widgetWithText(ElevatedButton, '카드 만들기 →');
    expect(tester.widget<ElevatedButton>(ctaFinder).onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, '가장 깊은 밤에 가장 빛나는 별이 보인다.');
    await tester.pump();

    expect(tester.widget<ElevatedButton>(ctaFinder).onPressed, isNotNull);
    expect(find.textContaining('/ 2000'), findsOneWidget); // 글자수 카운터
  });

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
}
