// 5종 템플릿 위젯 build smoke 테스트.
// 골든(픽셀 비교)은 PR10/12에서 폰트 로드 보장과 함께 들어온다 — 여기선
// "예외 없이 layout 통과"까지만 검증한다(폰트는 테스트 환경에서 시스템 fallback).

import 'package:bookquote/core/theme/tokens.dart';
import 'package:bookquote/features/card_editor/domain/card_template.dart';
import 'package:bookquote/features/card_editor/domain/quote_card_data.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/cover_extract_card.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/minimal_card.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/mono_card.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/quote_card.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/typography_card.dart';
import 'package:bookquote/features/card_editor/presentation/widgets/warm_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _longQuote = QuoteCardData(
  quoteText: '우리는 누군가의 가장 좋은 시절을 잘 모르는 채로도, 그 사람을 사랑할 수 있다.',
  bookTitle: '작별하지 않는다',
  bookAuthor: '한강',
  bookPublisher: '문학동네',
);

const _shortQuote = QuoteCardData(
  quoteText: '그래도 살아있다.',
  bookTitle: '미드나잇 라이브러리',
  bookAuthor: '매트 헤이그',
);

Widget _shrinkToFit(Widget card) {
  // 1080×{...} 캔버스를 800px 폭 테스트 surface에 들어가게 축소.
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: FittedBox(fit: BoxFit.contain, child: card),
      ),
    ),
  );
}

void main() {
  testWidgets('QuoteCard 디스패처 — 5종 × 9:16에서 예외 없이 빌드', (tester) async {
    for (final t in CardTemplate.all) {
      final data = t is TypographyTemplate ? _shortQuote : _longQuote;
      await tester.pumpWidget(
        _shrinkToFit(
          QuoteCard(
            template: t,
            data: data,
            palette: QuoteCard.fallbackFor(t),
            ratio: CardRatio.story,
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '${t.id} threw');
    }
  });

  testWidgets('Minimal — 3비율(9:16/1:1/4:5) 모두 빌드', (tester) async {
    for (final r in CardRatio.values) {
      await tester.pumpWidget(
        _shrinkToFit(
          MinimalCard(
            data: _longQuote,
            palette: QuoteCard.fallbackFor(const MinimalTemplate()),
            ratio: r,
          ),
        ),
      );
      expect(find.byType(MinimalCard), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '${r.label} threw');
    }
  });

  testWidgets('Warm — sideBySide(9:16,4:5) + topBottom(1:1) 모두 빌드', (tester) async {
    for (final r in CardRatio.values) {
      await tester.pumpWidget(
        _shrinkToFit(
          WarmCard(
            data: _longQuote,
            palette: QuoteCard.fallbackFor(const WarmTemplate()),
            ratio: r,
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '${r.label} threw');
    }
  });

  testWidgets('Mono — 3비율 + 차콜 배경 고정', (tester) async {
    for (final r in CardRatio.values) {
      await tester.pumpWidget(
        _shrinkToFit(
          MonoCard(
            data: _longQuote,
            palette: QuoteCard.fallbackFor(const MonoTemplate()),
            ratio: r,
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: '${r.label} threw');
    }
    // 마지막 빌드 — 차콜 배경 ColoredBox가 트리에 있음
    expect(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == AppColors.monoBackground,
      ),
      findsOneWidget,
    );
  });

  testWidgets('CoverExtract — 표지 URL 없을 때도 폴백 단색으로 빌드', (tester) async {
    await tester.pumpWidget(
      _shrinkToFit(
        CoverExtractCard(
          data: _longQuote, // coverUrl 없음
          palette: QuoteCard.fallbackFor(const CoverExtractTemplate()),
          ratio: CardRatio.story,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Typography — 시 배치 + 수직 중앙', (tester) async {
    await tester.pumpWidget(
      _shrinkToFit(
        TypographyCard(
          data: _shortQuote,
          palette: QuoteCard.fallbackFor(const TypographyTemplate()),
          ratio: CardRatio.story,
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // 시 배치 결과 — '그래도' / '살아있다.' 두 줄로 분리 렌더
    expect(find.text('그래도'), findsOneWidget);
    expect(find.text('살아있다.'), findsOneWidget);
  });
}
