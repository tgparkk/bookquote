// QuoteListCard 펼침 액션 — PR10.5 디자이너 권고로 [바로 공유]를 1급 액션으로
// 승격(공유 = accent500 FilledButton / 디자인 = outlined / 삭제 = text).

import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/presentation/widgets/quote_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Quote _quote() => Quote(
      id: 'q1',
      userId: 'u1',
      text: '본문 한 줄',
      moods: const <QuoteMood>[],
      createdAt: DateTime(2026, 5, 16),
      updatedAt: DateTime(2026, 5, 16),
    );

void main() {
  group('QuoteListCard', () {
    testWidgets('접힘 상태 — 액션 버튼 모두 숨김', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuoteListCard(
              quote: _quote(),
              onShare: () {},
              onMakeCard: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      expect(find.text('바로 공유'), findsNothing);
      expect(find.text('카드 디자인'), findsNothing);
      expect(find.text('삭제'), findsNothing);
    });

    testWidgets('펼침 + 3콜백 → 3버튼 노출', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuoteListCard(
              quote: _quote(),
              expanded: true,
              onShare: () {},
              onMakeCard: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      expect(find.text('바로 공유'), findsOneWidget);
      expect(find.text('카드 디자인'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('onShare 누락 → [바로 공유] 미노출(다른 두 버튼은 그대로)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuoteListCard(
              quote: _quote(),
              expanded: true,
              onMakeCard: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      expect(find.text('바로 공유'), findsNothing);
      expect(find.text('카드 디자인'), findsOneWidget);
      expect(find.text('삭제'), findsOneWidget);
    });

    testWidgets('각 버튼 탭 → 해당 콜백만 발화', (tester) async {
      var share = 0;
      var make = 0;
      var del = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QuoteListCard(
              quote: _quote(),
              expanded: true,
              onShare: () => share++,
              onMakeCard: () => make++,
              onDelete: () => del++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('바로 공유'));
      await tester.tap(find.text('카드 디자인'));
      await tester.tap(find.text('삭제'));
      expect(share, 1);
      expect(make, 1);
      expect(del, 1);
    });
  });
}
