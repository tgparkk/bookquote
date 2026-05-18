// quote_card_data_provider 잠금 분기 회귀 가드 (PR16-E).
//
// PR16-B에서 Quote.text를 nullable로 전환했고, PR16-C-2에서 QuoteCardData에
// isPrivate + isLockedAndUnreadable getter가 추가됨. 이 분기 흐름이 깨지면
// 잠금 인용구가 카드 에디터에서 _Editor(빈 본문)로 들어가버려 사용자 혼란.
// 이 테스트가 회귀 게이트.

import 'package:bookquote/features/card_editor/state/quote_card_data_provider.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/state/quote_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Quote _quote({String? text, bool isPrivate = false}) => Quote(
      id: 'q1',
      userId: 'u1',
      text: text,
      isPrivate: isPrivate,
      moods: const <QuoteMood>[],
      createdAt: DateTime(2026, 5, 18),
      updatedAt: DateTime(2026, 5, 18),
    );

ProviderContainer _container(Quote? quote) {
  final container = ProviderContainer(
    overrides: [
      quoteByIdProvider.overrideWith((ref, id) async => quote),
    ],
  );
  return container;
}

void main() {
  group('quoteCardDataProvider 잠금 분기 (PR16-C-2/PR16-E)', () {
    test('isPrivate=true + text=null → isLockedAndUnreadable=true', () async {
      final container =
          _container(_quote(text: null, isPrivate: true));
      addTearDown(container.dispose);
      final data = await container.read(quoteCardDataProvider('q1').future);
      expect(data, isNotNull);
      expect(data!.isPrivate, isTrue);
      expect(data.quoteText, '');
      expect(data.isLockedAndUnreadable, isTrue);
      expect(data.charCount, 0);
    });

    test('isPrivate=true + text 복호화 성공 → isLockedAndUnreadable=false', () async {
      final container =
          _container(_quote(text: '복호화된 본문', isPrivate: true));
      addTearDown(container.dispose);
      final data = await container.read(quoteCardDataProvider('q1').future);
      expect(data, isNotNull);
      expect(data!.isPrivate, isTrue);
      expect(data.quoteText, '복호화된 본문');
      expect(data.isLockedAndUnreadable, isFalse);
    });

    test('isPrivate=false + text 있음 → 평문 일반 흐름', () async {
      final container = _container(_quote(text: '평문', isPrivate: false));
      addTearDown(container.dispose);
      final data = await container.read(quoteCardDataProvider('q1').future);
      expect(data, isNotNull);
      expect(data!.isPrivate, isFalse);
      expect(data.quoteText, '평문');
      expect(data.isLockedAndUnreadable, isFalse);
    });

    test('quote 없음 (null) → null 반환', () async {
      final container = _container(null);
      addTearDown(container.dispose);
      final data = await container.read(quoteCardDataProvider('q1').future);
      expect(data, isNull);
    });
  });
}
