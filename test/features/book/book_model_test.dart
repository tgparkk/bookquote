import 'package:bookquote/features/book/data/aladin_dto.dart';
import 'package:bookquote/features/book/domain/book.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Book.fromJson', () {
    test('Supabase row의 snake_case를 정확히 camelCase로 매핑한다', () {
      final book = Book.fromJson({
        'id': '00000000-0000-0000-0000-000000000001',
        'isbn13': '9788932473901',
        'isbn10': '8932473900',
        'title': '데미안',
        'author': '헤르만 헤세',
        'publisher': '민음사',
        'pub_date': '2009-01-01',
        'cover_url': 'https://image.aladin.co.kr/x.jpg',
        'category_name': '소설',
        'source': 'aladin',
        'source_id': '12345',
        'created_at': '2026-05-10T00:00:00.000Z',
        'updated_at': '2026-05-10T00:00:00.000Z',
      });

      expect(book.title, '데미안');
      expect(book.isbn10, '8932473900');
      expect(book.pubDate, '2009-01-01');
      expect(book.coverUrl, 'https://image.aladin.co.kr/x.jpg');
      expect(book.categoryName, '소설');
      expect(book.sourceId, '12345');
      expect(book.createdAt?.year, 2026);
    });

    test('nullable 필드가 빠져도 깨지지 않는다', () {
      final book = Book.fromJson({
        'id': 'abc',
        'isbn13': '9780000000000',
        'title': 'untitled',
      });
      expect(book.author, isNull);
      expect(book.coverUrl, isNull);
      expect(book.source, 'aladin'); // default
    });
  });

  group('AladinBookDto.fromJson', () {
    test('Edge Function 응답의 camelCase를 그대로 받는다', () {
      final dto = AladinBookDto.fromJson({
        'isbn13': '9788932473901',
        'title': '데미안',
        'author': '헤르만 헤세',
        'pubDate': '2009-01-01',
        'coverUrl': 'https://image.aladin.co.kr/x.jpg',
      });
      expect(dto.title, '데미안');
      expect(dto.pubDate, '2009-01-01');
      expect(dto.coverUrl, 'https://image.aladin.co.kr/x.jpg');
    });
  });

  group('AladinSearchResponse.fromJson', () {
    test('items 배열을 DTO 리스트로 변환한다', () {
      final res = AladinSearchResponse.fromJson({
        'items': [
          {'isbn13': '9780000000001', 'title': 'a'},
          {'isbn13': '9780000000002', 'title': 'b'},
        ],
        'totalResults': 2,
        'page': 1,
        'size': 20,
      });
      expect(res.items, hasLength(2));
      expect(res.items.first.title, 'a');
      expect(res.totalResults, 2);
    });
  });

  group('EdgeError.fromJson', () {
    test('code/message를 그대로 받는다', () {
      final err = EdgeError.fromJson({'code': 'RATE_LIMIT', 'message': '한도 초과'});
      expect(err.code, 'RATE_LIMIT');
      expect(err.message, '한도 초과');
    });
  });
}
