import 'package:bookquote/features/book/domain/book.dart';
import 'package:bookquote/features/me/data/markdown_exporter.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:flutter_test/flutter_test.dart';

Quote _q(
  String id,
  String text, {
  String? bookId,
  String? manualBookText,
  int? page,
  List<QuoteMood> moods = const [],
}) =>
    Quote(
      id: id,
      userId: 'u1',
      bookId: bookId,
      manualBookText: manualBookText,
      text: text,
      page: page,
      moods: moods,
      createdAt: DateTime(2026, 5, 12),
      updatedAt: DateTime(2026, 5, 12),
    );

const _book = Book(
  id: 'b1',
  isbn13: '9791191056556',
  title: '미드나잇 라이브러리',
  author: '매트 헤이그',
);

void main() {
  test('빈 목록 — 헤더 + "없어요" 안내', () {
    final md = buildQuotesMarkdown(const [], exportedAt: DateTime(2026, 5, 13));
    expect(md, contains('# 책귀 — 내 인용구'));
    expect(md, contains('> 0개 · 2026-05-13 내보냄'));
    expect(md, contains('아직 모은 인용구가 없어요.'));
  });

  test('책별 그룹 — 제목·저자 헤딩 + 인용구 blockquote + 쪽수·무드 메타', () {
    final md = buildQuotesMarkdown([
      (
        quote: _q('q1', '가장 깊은 밤에 가장 빛나는 별이 보인다.',
            bookId: 'b1', page: 12, moods: [QuoteMood.comfort, QuoteMood.insight]),
        book: _book,
      ),
      (quote: _q('q2', '두 번째 구절.', bookId: 'b1'), book: _book),
    ], exportedAt: DateTime(2026, 5, 13));

    expect(md, contains('## 미드나잇 라이브러리 — 매트 헤이그'));
    expect(md, contains('> 가장 깊은 밤에 가장 빛나는 별이 보인다.'));
    expect(md, contains('> — 12쪽 · 위로, 통찰'));
    expect(md, contains('> 두 번째 구절.'));
    expect(md, contains('> 2개 · 2026-05-13 내보냄'));
  });

  test('같은 책의 인용구는 한 헤딩 아래로 묶인다', () {
    final md = buildQuotesMarkdown([
      (quote: _q('q1', 'A', bookId: 'b1'), book: _book),
      (quote: _q('q2', 'B', bookId: 'b1'), book: _book),
    ]);
    expect('## 미드나잇 라이브러리'.allMatches(md).length, 1);
  });

  test('책 미연결 — manualBookText면 그 제목, 없으면 "책 없음"', () {
    final md = buildQuotesMarkdown([
      (quote: _q('q1', '직접 적은 책.', manualBookText: '데미안'), book: null),
      (quote: _q('q2', '출처 모름.'), book: null),
    ]);
    expect(md, contains('## 데미안'));
    expect(md, contains('## 책 없음'));
  });

  test('여러 줄 인용구는 각 줄마다 blockquote prefix', () {
    final md = buildQuotesMarkdown([
      (quote: _q('q1', '첫 줄\n둘째 줄'), book: null),
    ]);
    expect(md, contains('> 첫 줄'));
    expect(md, contains('> 둘째 줄'));
  });
}
