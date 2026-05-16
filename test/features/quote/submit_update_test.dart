// CreateQuoteController.submitUpdate clearBook 기본값 회귀 가드 (B11).
//
// `input.bookId == null`이 prefill 실패에서 와도 책 연결을 silent 해제하지
// 않아야 한다. V1에 책 해제 UI가 없으므로 호출자가 `clearBook: true`를
// 명시할 일이 없고, 기본값 false면 quote_repository의 `?bookId` null-aware
// map literal로 patch에서 book_id 키가 제외돼 책 연결이 유지된다.

import 'package:bookquote/features/quote/data/quote_repository.dart';
import 'package:bookquote/features/quote/domain/quote.dart';
import 'package:bookquote/features/quote/domain/quote_mood.dart';
import 'package:bookquote/features/quote/state/quote_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRepo implements QuoteRepository {
  bool? lastClearBook;
  String? lastBookId;
  String? lastText;

  @override
  Future<Quote> updateQuote(
    String id, {
    String? text,
    int? page,
    Set<QuoteMood>? moods,
    String? bookId,
    String? manualBookText,
    bool clearBook = false,
  }) async {
    lastClearBook = clearBook;
    lastBookId = bookId;
    lastText = text;
    return Quote(
      id: id,
      userId: 'u1',
      text: text ?? '',
      moods: moods?.toList() ?? const <QuoteMood>[],
      bookId: bookId,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
  }

  // updateQuote 외엔 호출되지 않아야 한다 — 호출되면 NoSuchMethodError로 실패.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected ${invocation.memberName} call');
}

void main() {
  test('bookId null로 호출해도 clearBook 기본값 false — silent 해제 방지 (B11)',
      () async {
    final repo = _RecordingRepo();
    final container = ProviderContainer(overrides: [
      quoteRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final controller =
        container.read(createQuoteControllerProvider.notifier);
    await controller.submitUpdate(
      'q1',
      const QuoteInput(
        text: '수정된 본문',
        bookId: null, // prefill 실패 가정
        page: 100,
        moods: [QuoteMood.insight],
      ),
    );

    expect(repo.lastClearBook, isFalse,
        reason: 'clearBook이 false여야 책 연결 유지');
    expect(repo.lastBookId, isNull);
    expect(repo.lastText, '수정된 본문');
  });

  test('clearBook: true 명시하면 책 연결 해제 — V1.5 책 해제 액션용', () async {
    final repo = _RecordingRepo();
    final container = ProviderContainer(overrides: [
      quoteRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final controller =
        container.read(createQuoteControllerProvider.notifier);
    await controller.submitUpdate(
      'q1',
      const QuoteInput(text: '본문', bookId: null),
      clearBook: true,
    );

    expect(repo.lastClearBook, isTrue);
  });

  test('새 책 선택 시 bookId 전달 + clearBook 기본 false', () async {
    final repo = _RecordingRepo();
    final container = ProviderContainer(overrides: [
      quoteRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);

    final controller =
        container.read(createQuoteControllerProvider.notifier);
    await controller.submitUpdate(
      'q1',
      const QuoteInput(text: '본문', bookId: 'b1'),
    );

    expect(repo.lastBookId, 'b1');
    expect(repo.lastClearBook, isFalse);
  });
}
