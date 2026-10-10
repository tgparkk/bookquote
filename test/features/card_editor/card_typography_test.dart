// 공유 카드 인용구 크기 — 1080 캔버스 기준 곡선 + 영역 맞춤 회귀.
//
// 2026-10-10: 휴대폰 화면용 21~28px를 1080 캔버스에 그대로 써서 인용구가 책
// 제목(36px)보다 작았고, 표지 발췌는 긴 인용구가 선명 표지 위로 넘쳤다.

import 'package:bookquote/core/theme/tokens.dart';
import 'package:bookquote/features/card_editor/domain/card_template.dart';
import 'package:bookquote/features/card_editor/domain/card_typography.dart';
import 'package:bookquote/features/card_editor/domain/quote_card_data.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/card_quote_text.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/quote_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cardQuoteTargetSize', () {
    test('짧은 인용구는 책 정보(36px)보다 확실히 크다', () {
      expect(cardQuoteTargetSize(10, 0), 64);
      expect(cardQuoteTargetSize(10, 0), greaterThan(36));
    });

    test('글자 수가 늘수록 단조 감소, 하한·상한 안', () {
      var prev = double.infinity;
      for (final n in [1, 50, 80, 120, 200, 350, 500, 800, 2000]) {
        final s = cardQuoteTargetSize(n, 0);
        expect(s, lessThanOrEqualTo(prev), reason: '$n자');
        expect(s, inInclusiveRange(cardQuoteMinSize, cardQuoteMaxSize));
        prev = s;
      }
    });

    test('기본 단계 0에서 [A−]·[A+] 모두 크기를 바꾼다', () {
      final base = cardQuoteTargetSize(100, 0);
      expect(cardQuoteTargetSize(100, 1), greaterThan(base));
      expect(cardQuoteTargetSize(100, -1), lessThan(base));
    });

    test('행간은 1.5~1.7 안', () {
      for (final s in [20.0, 32.0, 48.0, 64.0, 84.0]) {
        expect(cardQuoteLineHeight(s), inInclusiveRange(1.5, 1.7));
      }
    });
  });

  group('CardQuoteText 영역 맞춤', () {
    Future<Size> pumpIn(WidgetTester tester, String text, Size box) async {
      await tester.pumpWidget(MaterialApp(
        home: Material(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: box.width,
              height: box.height,
              child: Align(
                alignment: Alignment.topLeft,
                child: CardQuoteText(
                  text: text,
                  targetSize: 64,
                  style: const TextStyle(),
                ),
              ),
            ),
          ),
        ),
      ));
      return tester.getSize(find.byType(Text));
    }

    testWidgets('짧은 글은 목표 크기 그대로', (tester) async {
      await pumpIn(tester, '짧은 글', const Size(900, 400));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontSize, 64);
      expect(text.maxLines, isNull);
    });

    testWidgets('긴 글은 줄어들어 영역을 넘지 않는다', (tester) async {
      final long = '가나다라마바사아자차카타파하 ' * 40;
      final size = await pumpIn(tester, long, const Size(900, 400));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontSize, lessThan(64));
      expect(size.height, lessThanOrEqualTo(400));
    });

    testWidgets('하한에서도 넘치면 말줄임으로 잘라 영역 안', (tester) async {
      final huge = '가나다라마바사아자차카타파하 ' * 400;
      final size = await pumpIn(tester, huge, const Size(900, 400));
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.style!.fontSize, cardQuoteMinSize);
      expect(text.maxLines, isNotNull);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(size.height, lessThanOrEqualTo(400));
    });
  });

  testWidgets('카드는 기기 글꼴 배율과 무관하게 같은 크기로 그린다', (tester) async {
    Future<double> quoteSize(double scale) async {
      await tester.pumpWidget(MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: MaterialApp(
          home: Material(
            child: FittedBox(
              child: QuoteCard(
                template: CardTemplate.all.first,
                data: const QuoteCardData(quoteText: '그래도 살아있다.'),
                palette: QuoteCard.fallbackFor(CardTemplate.all.first),
                ratio: CardRatio.story,
              ),
            ),
          ),
        ),
      ));
      final ctx = tester.element(find.text('그래도 살아있다.'));
      return MediaQuery.textScalerOf(ctx).scale(100);
    }

    expect(await quoteSize(1.0), 100);
    expect(await quoteSize(1.6), 100);
  });
}
