import 'package:bookquote/features/book/book_detail_screen.dart';
import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/book/state/book_providers.dart';
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
  publisher: '인플루엔셜',
  pubDate: '2021',
  description: '미드나잇 라이브러리는 삶과 죽음 사이의 도서관 이야기.',
);

Quote _quote(String id, String text, {List<QuoteMood> moods = const []}) => Quote(
      id: id,
      userId: 'u1',
      bookId: 'b1',
      text: text,
      moods: moods,
      createdAt: DateTime(2026, 5, 12),
      updatedAt: DateTime(2026, 5, 12),
    );

void main() {
  Future<void> pump(
    WidgetTester tester, {
    String? from,
    Book? book = _book,
    List<Quote> quotes = const [],
    bool inLibrary = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookByIdProvider('b1').overrideWith((ref) => book),
          bookQuotesProvider('b1').overrideWith((ref) => quotes),
          isInLibraryProvider('b1').overrideWith((ref) => inLibrary),
        ],
        child: MaterialApp(
          home: BookDetailScreen(bookId: 'b1', from: from),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('일반 진입 — 제목·저자·"이 책 인용구 추가" CTA, 안 담겼으면 [서재에 담기]', (tester) async {
    await pump(tester);

    expect(find.text('미드나잇 라이브러리'), findsOneWidget);
    expect(find.text('매트 헤이그'), findsOneWidget);
    expect(find.text('ISBN 9791191056556'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '이 책 인용구 추가'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '서재에 담기'), findsOneWidget);
    // 공유 배너는 일반 진입에선 없음
    expect(find.textContaining('누군가 이 책의 한 줄을 보냈어요'), findsNothing);
  });

  testWidgets('이미 서재에 있으면 [서재에 담기] 대신 "서재에 있음" 칩', (tester) async {
    await pump(tester, inLibrary: true);

    expect(find.text('서재에 있음'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '서재에 담기'), findsNothing);
  });

  testWidgets('deep link 진입(?from=share) — 공유 배너 + "내 서재에 담기" 1급 CTA', (tester) async {
    await pump(tester, from: 'share');

    expect(find.textContaining('누군가 이 책의 한 줄을 보냈어요'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '내 서재에 담기'), findsOneWidget);
  });

  testWidgets('이 책에서 모은 구절 — 개수 + 인용구 텍스트 표시', (tester) async {
    await pump(tester, quotes: [
      _quote('q1', '가장 깊은 밤에 가장 빛나는 별이 보인다.', moods: [QuoteMood.comfort]),
      _quote('q2', '후회는 인생에서 가장 무거운 짐.'),
    ]);

    expect(find.text('이 책에서 모은 구절'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('가장 깊은 밤에'), findsOneWidget);
    expect(find.text('아직 이 책에서 모은 구절이 없어요.'), findsNothing);
  });

  testWidgets('인용구 0개면 "아직 이 책에서 모은 구절이 없어요"', (tester) async {
    await pump(tester);
    expect(find.text('아직 이 책에서 모은 구절이 없어요.'), findsOneWidget);
  });

  testWidgets('긴 설명이면 "더 보기" 토글 — 탭하면 "접기"로 바뀜', (tester) async {
    final longBook = Book(
      id: 'b1',
      isbn13: '9791191056556',
      title: '미드나잇 라이브러리',
      description: '미드나잇 라이브러리는 삶과 죽음 사이의 도서관 이야기. ' * 30,
    );
    await pump(tester, book: longBook);

    final more = find.text('더 보기');
    expect(more, findsOneWidget);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.text('접기'), findsOneWidget);
    expect(find.text('더 보기'), findsNothing);
  });

  testWidgets('책이 없으면 "이 책을 더 이상 볼 수 없어요" + 출구 버튼', (tester) async {
    await pump(tester, book: null);

    expect(find.text('이 책을 더 이상 볼 수 없어요'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '홈으로'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '내 서재'), findsOneWidget);
  });
}
