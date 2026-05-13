// quote + book 합성 — 카드 에디터가 그릴 도메인 데이터.
//
// `quoteByIdProvider(quoteId)`로 인용구 한 건을 가져오고, `quote.bookId`가
// 있으면 `bookByIdProvider`로 책을 join한다. 책이 없는 경우(`manual_book_text`
// 입력만 한 quote)는 책 제목 자리에 `manualBookText`를 채워준다.
//
// 결과 = `AsyncValue<QuoteCardData?>` — null이면 quoteId가 잘못됐거나 삭제됨
// (`card-editor.md §3 빈 카드 만들 인용 없음`).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../book/state/book_providers.dart';
import '../../quote/state/quote_providers.dart';
import '../domain/quote_card_data.dart';

final quoteCardDataProvider = FutureProvider.autoDispose
    .family<QuoteCardData?, String>((ref, quoteId) async {
  final quote = await ref.watch(quoteByIdProvider(quoteId).future);
  if (quote == null) return null;

  final book = quote.bookId == null
      ? null
      : await ref.watch(bookByIdProvider(quote.bookId!).future);

  return QuoteCardData(
    quoteText: quote.text,
    bookTitle: book?.title ?? quote.manualBookText,
    bookAuthor: book?.author,
    bookPublisher: book?.publisher,
    coverUrl: book?.coverUrl,
  );
});
