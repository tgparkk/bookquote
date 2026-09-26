// 쌓아 보기 — 두께 미수집 처리(서재: 하단 섹션 / 홈: 인라인 캡슐)와 "인용 N" 검증.

import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/library/presentation/book_views/_spine.dart';
import 'package:bookquote/features/library/presentation/book_views/book_stack_view.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/state/quote_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _thick = Book(
  id: 'b1',
  isbn13: '9791191056556',
  title: '미드나잇 라이브러리',
  pageCount: 400,
);
const _noPages = Book(id: 'b2', isbn13: '', title: '쪽수 모르는 책');

Quote _quote(String id) => Quote(
      id: id,
      userId: 'u1',
      bookId: 'b1',
      text: '한 줄',
      createdAt: DateTime(2026, 5, 12),
      updatedAt: DateTime(2026, 5, 12),
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    bool inlinePending = false,
    List<Quote> quotes = const [],
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookQuotesProvider('b1').overrideWith((ref) async => quotes),
          bookQuotesProvider('b2').overrideWith((ref) async => const <Quote>[]),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: BookStackView(
              books: const [_noPages, _thick],
              inlinePending: inlinePending,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('서재 기본 — 쪽수 없는 책은 하단 "두께 미수집" 섹션으로', (tester) async {
    await pump(tester);
    expect(find.text('1권 쌓았어요'), findsOneWidget);
    expect(find.text('두께 미수집 1권'), findsOneWidget);
    expect(find.text('두께 정보 없음'), findsNothing);
  });

  testWidgets('inlinePending(홈) — 쪽수 없는 책도 캡슐로, "두께 정보 없음" 라벨',
      (tester) async {
    await pump(tester, inlinePending: true);
    expect(find.text('2권 쌓았어요'), findsOneWidget);
    expect(find.text('쪽수 모르는 책'), findsOneWidget);
    expect(find.text('두께 정보 없음'), findsOneWidget);
    expect(find.textContaining('두께 미수집'), findsNothing);
  });

  testWidgets('서재(읽는 중 미지정) — 묶음 제목·구분선·리본 없음', (tester) async {
    await pump(tester);
    expect(find.byType(ReadingGroupHeader), findsNothing);
    expect(find.byType(ReadingGroupDivider), findsNothing);
    expect(find.byType(ReadingRibbon), findsNothing);
  });

  testWidgets('인용구 있는 책만 캡슐에 "인용 N"', (tester) async {
    await pump(tester, quotes: [_quote('q1'), _quote('q2')]);
    expect(find.text('인용 2'), findsOneWidget);
  });

  test('quoteCountLabel — 조회 상한이면 "N+"', () {
    expect(quoteCountLabel(3), '인용 3');
    expect(quoteCountLabel(kBookQuotesLimit), '인용 $kBookQuotesLimit+');
  });
}
