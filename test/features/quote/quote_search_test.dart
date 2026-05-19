// PR20-B — 인용구 검색 (UX#2): QuoteSearchDelegate + provider override 통합 테스트.
//
// 실제 ilike 쿼리는 RLS+ilike escape 검증 어려우니 provider를 override해 UI 분기
// (힌트 / zero result / 결과 리스트 / 잠금 인용구 자연 제외)만 확인.

import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/presentation/quote_search_delegate.dart';
import 'package:bookquote/features/quote/state/quote_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

QuoteWithBook _result(String text) => (
      quote: Quote(
        id: 'q-${text.hashCode}',
        userId: 'u1',
        text: text,
        moods: const <QuoteMood>[],
        createdAt: DateTime(2026, 5, 19),
        updatedAt: DateTime(2026, 5, 19),
      ),
      book: null,
    );

GoRouter _router(Widget child) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, _) => child),
        GoRoute(path: '/quote/:id/share', builder: (_, _) => const Scaffold()),
      ],
    );

class _LaunchPad extends StatelessWidget {
  const _LaunchPad();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () =>
                  showSearch(context: context, delegate: QuoteSearchDelegate()),
            ),
          ],
        ),
      );
}

void main() {
  Future<void> pumpAndOpenSearch(
    WidgetTester tester, {
    required List<QuoteWithBook> Function(String query) onSearch,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // family override: any query returns onSearch(query).
          quoteSearchProvider.overrideWith(
            (ref, query) async => onSearch(query),
          ),
        ],
        child: MaterialApp.router(routerConfig: _router(const _LaunchPad())),
      ),
    );
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
  }

  testWidgets('쿼리 없으면 힌트 화면', (tester) async {
    await pumpAndOpenSearch(tester, onSearch: (_) => const []);
    expect(find.text('모은 인용구를 검색해요'), findsOneWidget);
    expect(find.textContaining('잠금 인용구는 검색에서 제외'), findsOneWidget);
  });

  testWidgets('결과 0건 → "찾지 못했어요"', (tester) async {
    await pumpAndOpenSearch(tester, onSearch: (_) => const []);
    await tester.enterText(find.byType(TextField), '없음');
    // 디버운스(300ms) + Future resolve를 충분히 기다리도록 settle 시간 부여.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('찾지 못했어요'), findsOneWidget);
  });

  testWidgets('결과 ≥1건 → 인용구 카드 노출', (tester) async {
    await pumpAndOpenSearch(
      tester,
      onSearch: (q) => [_result('가장 깊은 밤에 가장 빛나는 별이 보인다.')],
    );
    await tester.enterText(find.byType(TextField), '깊은');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('가장 깊은 밤에'), findsOneWidget);
  });
}
