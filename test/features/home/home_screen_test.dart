import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/home/home_screen.dart';
import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/state/quote_feed_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFeed extends QuoteFeedNotifier {
  _FakeFeed(this._initial);
  final AsyncValue<List<QuoteWithBook>> _initial;
  @override
  AsyncValue<List<QuoteWithBook>> build() => _initial;
}

Quote _quote(String id, String text, {List<QuoteMood> moods = const []}) => Quote(
      id: id,
      userId: 'u1',
      text: text,
      moods: moods,
      createdAt: DateTime(2026, 5, 12),
      updatedAt: DateTime(2026, 5, 12),
    );

const _book = Book(id: 'b1', isbn13: '9791191056556', title: '미드나잇 라이브러리', author: '매트 헤이그');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHome(WidgetTester tester, AsyncValue<List<QuoteWithBook>> feed) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [quoteFeedProvider.overrideWith(() => _FakeFeed(feed))],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(); // postFrame(_flushOutbox)
  }

  testWidgets('인용구 0개면 빈 상태 + "＋ 인용구 추가" 버튼', (tester) async {
    await pumpHome(tester, const AsyncValue.data(<QuoteWithBook>[]));
    expect(find.text('아직 인용구가 없어요'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '＋ 인용구 추가'), findsOneWidget);
  });

  testWidgets('인용구가 있으면 카드 목록 — 텍스트·책·무드 표시', (tester) async {
    await pumpHome(tester, AsyncValue.data([
      (quote: _quote('q1', '가장 깊은 밤에 가장 빛나는 별이 보인다.', moods: [QuoteMood.comfort]), book: _book),
      (quote: _quote('q2', '우리는 우리가 반복하는 것이다.'), book: null),
    ]));
    expect(find.textContaining('가장 깊은 밤에'), findsOneWidget);
    expect(find.text('미드나잇 라이브러리 · 매트 헤이그'), findsOneWidget);
    expect(find.text('위로'), findsOneWidget); // 무드 뱃지
    expect(find.text('아직 인용구가 없어요'), findsNothing);
  });

  testWidgets('카드를 탭하면 펼쳐져 [카드 만들기]/[삭제] 노출', (tester) async {
    await pumpHome(tester, AsyncValue.data([
      (quote: _quote('q1', '가장 깊은 밤에 가장 빛나는 별이 보인다.'), book: _book),
    ]));
    expect(find.text('카드 만들기'), findsNothing);

    await tester.tap(find.textContaining('가장 깊은 밤에'));
    await tester.pump();

    expect(find.text('카드 만들기'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
  });
}
