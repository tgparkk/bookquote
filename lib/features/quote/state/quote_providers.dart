// 인용구 providers.
//
// - bookQuotesProvider(bookId): 책 상세의 "이 책에서 모은 구절" 첫 페이지.
// - quoteByIdProvider(id): 카드 에디터 등에서 단건 조회.
// - createQuoteControllerProvider: 인용구 생성 (AsyncValue<void>로 진행/에러).
//   네트워크 오류면 아웃박스에 큐잉하고 성공으로 처리한다. 성공 시 호출자가
//   ref.invalidate로 목록(홈 피드·인용 목록·책 상세)을 갱신한다.
//
// 홈 피드의 무한스크롤 누적 상태(Notifier<AsyncValue<List<Quote>>> + cursor)는
// 별도로 — PR 3(홈 화면)에서.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/quote_outbox.dart';
import '../data/quote_repository.dart';
import '../domain/quote.dart';

/// 책 상세용 — 그 책에서 모은 내 인용구 (최근순 첫 페이지).
final bookQuotesProvider =
    FutureProvider.autoDispose.family<List<Quote>, String>((ref, bookId) async {
  final repo = ref.read(quoteRepositoryProvider);
  return repo.listMyQuotes(bookId: bookId, limit: 20);
});

/// 단건 조회 — 카드 에디터(`/quote/:id/card`) 등.
final quoteByIdProvider =
    FutureProvider.autoDispose.family<Quote?, String>((ref, id) async {
  final repo = ref.read(quoteRepositoryProvider);
  return repo.getById(id);
});

/// 인용구 생성 컨트롤러.
///
/// [submit]은 온라인 저장에 성공하면 생성된 [Quote]를, 네트워크 오류로
/// 아웃박스에 큐잉됐으면 `null`을 반환한다. 인증/검증 오류([QuoteRepositoryException])는
/// 그대로 던져 화면에서 처리하게 한다.
class CreateQuoteController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Quote?> submit(QuoteInput input) async {
    state = const AsyncLoading();
    final repo = ref.read(quoteRepositoryProvider);
    try {
      final created = await repo.createQuote(input);
      state = const AsyncData(null);
      return created;
    } on QuoteRepositoryException {
      // 인증 실패·서버가 응답한 에러(5xx 등)는 화면이 재시도/로그인 유도로 처리.
      state = const AsyncData(null);
      rethrow;
    } catch (error, stackTrace) {
      // 응답 없는 네트워크성 오류 — 아웃박스에 큐잉하고 성공으로 본다.
      try {
        final outbox = await ref.read(quoteOutboxProvider.future);
        await outbox.enqueue(input);
        state = const AsyncData(null);
        return null;
      } catch (_) {
        state = AsyncError(error, stackTrace);
        rethrow;
      }
    }
  }

  /// 기존 인용구 수정. 신규 생성과 달리 outbox 큐잉은 하지 않는다(편집은 사용자가
  /// 다시 시도하는 게 자연스러움). 성공 시 갱신된 [Quote]를, 인증·서버 오류는
  /// [QuoteRepositoryException]을 그대로 던진다.
  ///
  /// [clearBook]은 사용자가 명시적으로 책 연결을 해제할 때만 `true`. 기본 `false`로
  /// 둬서 `input.bookId == null`이 prefill 실패(저속 회선·일시 미응답)에서 와도
  /// 책 연결이 silent 해제되지 않게 한다. V1엔 책 해제 UI 자체가 없으므로 호출자가
  /// 명시하지 않으면 항상 false.
  Future<Quote> submitUpdate(
    String quoteId,
    QuoteInput input, {
    bool clearBook = false,
  }) async {
    state = const AsyncLoading();
    final repo = ref.read(quoteRepositoryProvider);
    try {
      final updated = await repo.updateQuote(
        quoteId,
        text: input.text,
        page: input.page,
        moods: input.moods.toSet(),
        bookId: input.bookId,
        clearBook: clearBook,
      );
      state = const AsyncData(null);
      return updated;
    } on QuoteRepositoryException {
      state = const AsyncData(null);
      rethrow;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final createQuoteControllerProvider =
    AsyncNotifierProvider<CreateQuoteController, void>(CreateQuoteController.new);
