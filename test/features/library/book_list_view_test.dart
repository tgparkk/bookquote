// PR30-D: 서재 [책] 탭 list_view의 친구 평균 + 무드 chip 가드 검증.

import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/follow/state/follow_providers.dart';
import 'package:bookquote/features/library/presentation/book_views/book_list_view.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/state/quote_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _book = Book(
  id: 'b1',
  isbn13: '9791191056556',
  title: '미드나잇 라이브러리',
  author: '매트 헤이그',
);

Quote _quote(String id, {List<QuoteMood> moods = const []}) => Quote(
      id: id,
      userId: 'u1',
      bookId: 'b1',
      text: '한 줄',
      moods: moods,
      createdAt: DateTime(2026, 5, 12),
      updatedAt: DateTime(2026, 5, 12),
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    ({int n, double avg}) friendsAvgRating = (n: 0, avg: 0.0),
    List<Quote> quotes = const [],
  }) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendsAvgRatingProvider('b1')
              .overrideWith((ref) async => friendsAvgRating),
          bookQuotesProvider('b1').overrideWith((ref) async => quotes),
        ],
        child: const MaterialApp(
          home: Scaffold(body: BookListView(books: [_book])),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('빈 시그널 — chip 없이 책 정보만 노출', (tester) async {
    await pump(tester);
    expect(find.text('미드나잇 라이브러리'), findsOneWidget);
    expect(find.text('매트 헤이그'), findsOneWidget);
    // 어느 chip도 노출 안 됨
    expect(find.textContaining('친구'), findsNothing);
    expect(find.text('위로'), findsNothing);
  });

  testWidgets('친구 평균 N=2 → 친구 chip 숨김(N<3 가드)', (tester) async {
    await pump(tester, friendsAvgRating: (n: 2, avg: 4.5));
    expect(find.textContaining('친구'), findsNothing);
  });

  testWidgets('친구 평균 N=3 → "4.0 친구 3" chip 노출', (tester) async {
    await pump(tester, friendsAvgRating: (n: 3, avg: 4.0));
    expect(find.text('4.0 친구 3'), findsOneWidget);
  });

  testWidgets('quotes 있지만 moods 비면 무드 chip 숨김', (tester) async {
    await pump(tester, quotes: [_quote('q1')]);
    expect(find.text('위로'), findsNothing);
    expect(find.text('통찰'), findsNothing);
  });

  testWidgets('무드 top 2만 노출 — 위로 ×3, 통찰 ×2, 설렘 ×1이면 위로·통찰만',
      (tester) async {
    await pump(tester, quotes: [
      _quote('q1', moods: [QuoteMood.comfort, QuoteMood.insight]),
      _quote('q2', moods: [QuoteMood.comfort]),
      _quote('q3',
          moods: [QuoteMood.comfort, QuoteMood.insight, QuoteMood.excitement]),
    ]);
    expect(find.text('위로 3'), findsOneWidget);
    expect(find.text('통찰 2'), findsOneWidget);
    // 설렘(top 3째)은 list view에서 잘림 — top 2만 노출
    expect(find.textContaining('설렘'), findsNothing);
  });
}
