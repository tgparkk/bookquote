// 홈 화면 위젯 '이 책의 한 줄' — Flutter ↔ 네이티브 위젯 브리지 (HW-A 스캐폴드 + HW-B 데이터).
//
// 현재 읽는 책 1권 + 그 책에서 뽑은 글귀(**잠금 E2EE 인용구 제외**)를 위젯에 푸시하고,
// 위젯 탭을 GoRouter 경로(`/quote/new?bookId=`)로 라우팅한다.
//
// 갱신 트리거: 앱 진입·포그라운드 복귀(main.dart). 안드로이드 updatePeriodMillis(일1회)는
// SharedPreferences에 *저장된* 데이터를 다시 그릴 뿐 새 글귀를 못 고르므로, 실제 일일
// 회전은 앱 실행 시점에 일어난다(진짜 백그라운드 회전 = WorkManager는 후속 과제).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';

import '../book/data/book_repository.dart';
import '../quote/data/quote_repository.dart';
import '../quote/domain/quote.dart';

/// 그 책/서재에 아직 글귀가 없을 때 위젯에 띄우는 유도 문구('첫 줄 적기' 램프).
const String _emptyQuotePrompt = '이 책에서 마음에 남은 한 줄을 적어보세요.';
const String _noBookPrompt = '오늘 읽은 책의 한 줄을 책글귀에 남겨보세요.';

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// 안드로이드 provider 클래스명 — `BookQuoteWidgetProvider`와 일치해야 한다.
  static const String _androidProvider = 'BookQuoteWidgetProvider';

  bool _interactivityWired = false;

  /// 위젯에 한 건을 푸시한다. 위젯 미설치·웹(플러그인 미지원)에서는 조용히 무시.
  Future<void> push({
    required String title,
    required String author,
    required String quote,
    required String bookId,
  }) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('book_title', title);
      await HomeWidget.saveWidgetData<String>('book_author', author);
      await HomeWidget.saveWidgetData<String>('quote_text', quote);
      await HomeWidget.saveWidgetData<String>('book_id', bookId);
      await HomeWidget.updateWidget(androidName: _androidProvider);
    } catch (_) {
      // 위젯 미설치/플랫폼 미지원은 정상 상황 — 무시.
    }
  }

  /// 위젯 탭 → GoRouter 라우팅 연결. 한 번만 호출(앱 시작 시).
  void initInteractivity(GoRouter router) {
    if (kIsWeb || _interactivityWired) return;
    _interactivityWired = true;
    // 워밍 상태에서 위젯 탭.
    HomeWidget.widgetClicked.listen(
      (uri) => _route(router, uri),
      onError: (_) {},
    );
    // 콜드스타트로 위젯에서 부팅된 경우.
    HomeWidget.initiallyLaunchedFromHomeWidget().then(
      (uri) {
        if (uri != null) _route(router, uri);
      },
      onError: (_, _) {},
    );
  }

  void _route(GoRouter router, Uri? uri) {
    if (uri == null) return;
    final bookId = uri.queryParameters['bookId'] ?? '';
    // bookId 있으면 그 책 '한 줄 적기'로, 없으면(오늘의 인용구 폴백) 홈으로.
    router.go(bookId.isNotEmpty ? '/quote/new?bookId=$bookId' : '/');
  }
}

/// HW-B: 위젯 데이터 새로고침. 우선순위:
///   1) 현재 읽는 책(가장 최근 시작 1권) + 그 책 글귀(잠금 제외, 일일 회전)
///   2) 그 책에 글귀 0개 → 책 제목 + '첫 줄 적기' 유도
///   3) 읽는 책 0권 → '오늘의 인용구'(아무 책 글귀, 잠금 제외)로 강등
///   4) 글귀가 하나도 없음(신규) → 시작 유도 문구
/// 네트워크/비로그인 등 실패는 조용히 무시 — 위젯은 직전 데이터를 유지한다.
Future<void> refreshHomeWidget({
  required BookRepository bookRepo,
  required QuoteRepository quoteRepo,
}) async {
  if (kIsWeb) return;
  try {
    final reading = await bookRepo.listCurrentlyReading(limit: 1);
    if (reading.isNotEmpty) {
      final book = reading.first.book;
      final quotes = await quoteRepo.listMyQuotes(bookId: book.id, limit: 30);
      final usable = quotes.where(_isWidgetSafe).toList();
      await HomeWidgetService.instance.push(
        title: book.title,
        author: book.author ?? '',
        quote: usable.isEmpty
            ? _emptyQuotePrompt
            : _pickDaily(usable).text!.trim(),
        // 글귀가 없어도 '첫 줄 적기'가 그 책으로 가도록 bookId는 항상 싣는다.
        bookId: book.id,
      );
      return;
    }

    // 읽는 책 0권 → '오늘의 인용구' 폴백.
    final feed = await quoteRepo.listMyQuotesWithBook(limit: 30);
    final usable = feed.where((e) => _isWidgetSafe(e.quote)).toList();
    if (usable.isNotEmpty) {
      final picked = _pickDaily(usable);
      await HomeWidgetService.instance.push(
        title: picked.book?.title ?? '오늘의 한 줄',
        author: picked.book?.author ?? '',
        quote: picked.quote.text!.trim(),
        bookId: picked.quote.bookId ?? '',
      );
    } else {
      // 글귀가 하나도 없는 신규 사용자.
      await HomeWidgetService.instance.push(
        title: '읽고 있는 책',
        author: '',
        quote: _noBookPrompt,
        bookId: '',
      );
    }
  } catch (_) {
    // 비로그인/오프라인 등 — 위젯은 직전 데이터 유지.
  }
}

/// 위젯에 띄워도 되는 글귀인지 — **잠금(E2EE) 제외** + 평문 본문 존재.
/// 잠금 인용구는 키가 기기 secure storage에 있어 위젯 프로세스에서 풀 수 없고,
/// 푼다 해도 잠금 의도를 깨므로 절대 노출하지 않는다.
bool _isWidgetSafe(Quote q) =>
    !q.isPrivate && (q.text?.trim().isNotEmpty ?? false);

/// 날짜 기준 결정적 선택 — 같은 날엔 고정(앱을 여러 번 열어도 안 바뀜),
/// 날이 바뀌면 회전. `Math.random` 대신 일자 인덱스라 재현 가능.
T _pickDaily<T>(List<T> items) {
  final dayIndex = DateTime.now().difference(DateTime.utc(2026)).inDays;
  return items[dayIndex.abs() % items.length];
}
