import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Quote.fromJson', () {
    test('Supabase row의 snake_case를 camelCase로 매핑하고 moods를 enum으로 변환한다', () {
      final quote = Quote.fromJson({
        'id': '00000000-0000-0000-0000-000000000001',
        'user_id': '00000000-0000-0000-0000-0000000000aa',
        'book_id': '00000000-0000-0000-0000-0000000000bb',
        'manual_book_text': null,
        'text': '가장 깊은 밤에 가장 빛나는 별이 보인다.',
        'page': 132,
        'source': 'clipboard',
        'moods': ['comfort', 'wistful'],
        'created_at': '2026-05-12T09:41:00.000Z',
        'updated_at': '2026-05-12T09:41:00.000Z',
      });

      expect(quote.userId, '00000000-0000-0000-0000-0000000000aa');
      expect(quote.bookId, '00000000-0000-0000-0000-0000000000bb');
      expect(quote.page, 132);
      expect(quote.source, QuoteSource.clipboard);
      expect(quote.moods, [QuoteMood.comfort, QuoteMood.wistful]);
      expect(quote.createdAt.year, 2026);
    });

    test('nullable 필드가 빠지거나 책 미연결이어도 깨지지 않는다 (기본값 적용)', () {
      final quote = Quote.fromJson({
        'id': 'q1',
        'user_id': 'u1',
        'text': '사랑',
        'created_at': '2026-05-12T00:00:00.000Z',
        'updated_at': '2026-05-12T00:00:00.000Z',
      });

      expect(quote.bookId, isNull);
      expect(quote.manualBookText, isNull);
      expect(quote.page, isNull);
      expect(quote.source, QuoteSource.manual); // default
      expect(quote.moods, isEmpty); // default
    });

    test('알 수 없는 무드 name은 조용히 드롭한다 (데이터 보존)', () {
      final quote = Quote.fromJson({
        'id': 'q1',
        'user_id': 'u1',
        'text': 't',
        'moods': ['comfort', 'someFutureMood', 'insight'],
        'created_at': '2026-05-12T00:00:00.000Z',
        'updated_at': '2026-05-12T00:00:00.000Z',
      });
      expect(quote.moods, [QuoteMood.comfort, QuoteMood.insight]);
    });
  });

  group('QuoteInput', () {
    test('toJson은 DB insert용 snake_case 키와 무드 name 리스트를 만든다', () {
      const input = QuoteInput(
        text: '한 줄',
        bookId: 'b1',
        page: 10,
        source: QuoteSource.clipboard,
        moods: [QuoteMood.comfort, QuoteMood.lateNight],
      );
      final json = input.toJson();

      expect(json['text'], '한 줄');
      expect(json['book_id'], 'b1');
      expect(json['manual_book_text'], isNull);
      expect(json['page'], 10);
      expect(json['source'], 'clipboard');
      expect(json['moods'], ['comfort', 'lateNight']);
    });

    test('아웃박스 직렬화 — toJson → fromJson 라운드트립이 보존된다', () {
      const input = QuoteInput(
        text: '오프라인에서 쓴 구절',
        manualBookText: '제목 미상의 책',
        moods: [QuoteMood.insight],
      );
      final restored = QuoteInput.fromJson(input.toJson());
      expect(restored, input);
    });
  });

  group('parseMoodCounts (my_quote_mood_counts RPC 결과)', () {
    test('__total__ 행은 전체 수, 나머지는 무드별 개수, 알 수 없는 name은 무시', () {
      final r = parseMoodCounts([
        {'mood': '__total__', 'n': 42},
        {'mood': 'comfort', 'n': 12},
        {'mood': 'someFutureMood', 'n': 3}, // 무시
        {'mood': 'insight', 'n': 5},
      ]);
      expect(r.total, 42);
      expect(r.byMood[QuoteMood.comfort], 12);
      expect(r.byMood[QuoteMood.insight], 5);
      expect(r.byMood.containsKey(QuoteMood.wistful), isFalse); // 0인 무드는 행 없음
      expect(r.byMood.length, 2);
    });

    test('빈 결과면 total 0, byMood 비어있음', () {
      final r = parseMoodCounts(const []);
      expect(r.total, 0);
      expect(r.byMood, isEmpty);
    });
  });

  group('QuoteMood', () {
    test('fromName은 알려진 이름만 매칭하고 나머지는 null', () {
      expect(QuoteMood.fromName('comfort'), QuoteMood.comfort);
      expect(QuoteMood.fromName('lateNight'), QuoteMood.lateNight);
      expect(QuoteMood.fromName('nope'), isNull);
    });

    test('한국어 label이 작업 가정 셋과 일치한다', () {
      expect(QuoteMood.comfort.label, '위로');
      expect(QuoteMood.wistful.label, '먹먹');
      expect(QuoteMood.lateNight.label, '새벽3시');
      expect(QuoteMood.insight.label, '통찰');
      expect(QuoteMood.excitement.label, '설렘');
    });
  });
}
