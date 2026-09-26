import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/book/state/book_providers.dart';
import 'package:bookquote/features/follow/state/follow_providers.dart';
import 'package:bookquote/features/home/home_screen.dart';
import 'package:bookquote/features/library/presentation/book_views/_spine.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/state/quote_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _book1 = Book(id: 'b1', isbn13: '9791191056556', title: '미드나잇 라이브러리', author: '매트 헤이그', pageCount: 400);
const _book2 = Book(id: 'b2', isbn13: '9788932917245', title: '니코마코스 윤리학', author: '아리스토텔레스');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pumpHome(
    WidgetTester tester,
    List<Book> books, {
    List<Book> reading = const [],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myLibraryProvider.overrideWith((ref) async => [
                for (final b in books)
                  (
                    book: b,
                    addedAt: DateTime(2026, 9, 1),
                    startedAt: null,
                    finishedAt: null,
                    readingStatus: 'reading',
                    rating: null,
                  ),
              ]),
          currentlyReadingProvider.overrideWith((ref) async => [
                for (final b in reading)
                  (book: b, startedAt: DateTime(2026, 9, 1)),
              ]),
          for (final b in books) ...[
            bookQuotesProvider(b.id).overrideWith((ref) async => const <Quote>[]),
            friendsAvgRatingProvider(b.id)
                .overrideWith((ref) async => (n: 0, avg: 0.0)),
          ],
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump(); // postFrame(_flushOutbox) + myLibraryProvider 완료
    await tester.pump(); // homeViewModeProvider(SharedPreferences) 완료
  }

  testWidgets('책 0권이면 빈 상태 + "＋ 인용구 추가" 버튼, 보기 토글 없음', (tester) async {
    await pumpHome(tester, const []);
    expect(find.text('아직 담은 책이 없어요'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '＋ 인용구 추가'), findsOneWidget);
    expect(find.byTooltip('리스트로 보기'), findsNothing);
    // 빈 홈에선 "지금 읽고 있어요" 줄(첫 책 등록 진입점)을 유지
    expect(find.text('지금 읽고 있어요'), findsOneWidget);
  });

  testWidgets('기본은 쌓아 보기 — 쪽수 없는 책도 목록 안에', (tester) async {
    await pumpHome(tester, const [_book1, _book2]);
    expect(find.text('2권 쌓았어요'), findsOneWidget);
    expect(find.text('미드나잇 라이브러리'), findsOneWidget);
    expect(find.text('니코마코스 윤리학'), findsOneWidget);
    expect(find.text('두께 정보 없음'), findsOneWidget);
    expect(find.text('아직 담은 책이 없어요'), findsNothing);
  });

  testWidgets(
      '읽는 중인 책은 "지금 읽는 중" 묶음으로 맨 위 + 가름끈 리본 + [✎], '
      '"지금 읽고 있어요" 줄은 없음(쌓아 보기·리스트)', (tester) async {
    // 서재 순서는 book1 → book2, 읽는 중은 book2 → book2가 맨 위로.
    await pumpHome(tester, const [_book1, _book2], reading: const [_book2]);
    expect(find.text('지금 읽고 있어요'), findsNothing);

    void expectReadingFirst() {
      expect(find.text('지금 읽는 중'), findsOneWidget);
      expect(find.text(' · 1권'), findsOneWidget);
      expect(find.byType(ReadingGroupDivider), findsOneWidget);
      // 묶음 제목의 범례 1 + 책 1권의 가름끈 1
      expect(find.byType(ReadingRibbon), findsNWidgets(2));
      expect(find.byTooltip('이 책 인용구 적기'), findsOneWidget);
      final readingY = tester.getTopLeft(find.text('니코마코스 윤리학')).dy;
      final otherY = tester.getTopLeft(find.text('미드나잇 라이브러리')).dy;
      expect(readingY, lessThan(otherY));
    }

    expectReadingFirst();

    await tester.tap(find.byTooltip('리스트로 보기'));
    await tester.pump();
    expectReadingFirst();
  });

  testWidgets('AppBar 토글 → 리스트(저자 표시), 다시 누르면 쌓아 보기', (tester) async {
    await pumpHome(tester, const [_book1, _book2]);
    expect(find.text('매트 헤이그'), findsNothing);

    await tester.tap(find.byTooltip('리스트로 보기'));
    await tester.pump();
    expect(find.text('매트 헤이그'), findsOneWidget);
    expect(find.text('아리스토텔레스'), findsOneWidget);
    expect(find.text('2권 쌓았어요'), findsNothing);

    await tester.tap(find.byTooltip('쌓아 보기'));
    await tester.pump();
    expect(find.text('2권 쌓았어요'), findsOneWidget);
  });
}
