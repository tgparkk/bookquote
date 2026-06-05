// 홈 화면 위젯 브리지 (Flutter ↔ 네이티브).
//
// 위젯 2종:
//   1) '이 책의 한 줄' (HW-A/B) — 읽는 책 + 그 책 글귀(**잠금 E2EE 제외**), 매일 회전.
//   2) '읽고 있는 책'   (HW-D)   — 읽는 책 표지 + 제목·저자 + 'N일째 읽는 중'.
// 둘 다 탭 → GoRouter `/quote/new?bookId=`. 갱신 트리거: 앱 진입·포그라운드 복귀(main.dart).
//
// 안드로이드 updatePeriodMillis(일1회)는 저장된 데이터를 다시 그릴 뿐이라, 실제 회전/일수
// 갱신은 앱 실행 시점에 일어난다(진짜 백그라운드 갱신 = WorkManager는 후속 과제).

import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../book/data/book_repository.dart';
import '../quote/data/quote_repository.dart';
import '../quote/domain/quote.dart';

/// 그 책/서재에 아직 글귀가 없을 때 위젯에 띄우는 유도 문구('첫 줄 적기' 램프).
const String _emptyQuotePrompt = '이 책에서 마음에 남은 한 줄을 적어보세요.';
const String _noBookPrompt = '오늘 읽은 책의 한 줄을 책글귀에 남겨보세요.';

class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  /// 안드로이드 provider 클래스명 — Kotlin 클래스명과 일치해야 한다.
  static const String _quoteProvider = 'BookQuoteWidgetProvider';
  static const String _readingProvider = 'ReadingBookWidgetProvider';

  bool _interactivityWired = false;

  /// '이 책의 한 줄' 위젯에 푸시. 위젯 미설치·웹(플러그인 미지원)에서는 조용히 무시.
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
      await HomeWidget.updateWidget(androidName: _quoteProvider);
    } catch (_) {
      // 위젯 미설치/플랫폼 미지원은 정상 상황 — 무시.
    }
  }

  /// '읽고 있는 책' 위젯에 푸시(HW-D). [coverPath]가 비면 표지 숨김, [title]이 비면 빈 상태.
  Future<void> pushReadingBook({
    required String title,
    required String author,
    required String daysLabel,
    required String bookId,
    required String coverPath,
  }) async {
    if (kIsWeb) return;
    try {
      await HomeWidget.saveWidgetData<String>('reading_book_title', title);
      await HomeWidget.saveWidgetData<String>('reading_book_author', author);
      await HomeWidget.saveWidgetData<String>('reading_days_label', daysLabel);
      await HomeWidget.saveWidgetData<String>('reading_book_id', bookId);
      await HomeWidget.saveWidgetData<String>('reading_cover_path', coverPath);
      await HomeWidget.updateWidget(androidName: _readingProvider);
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
    // bookId 있으면 그 책 '한 줄 적기'로, 없으면(폴백/빈 상태) 홈으로.
    router.go(bookId.isNotEmpty ? '/quote/new?bookId=$bookId' : '/');
  }
}

/// 두 위젯을 한 번에 새로고침. 읽는 책을 한 번 조회해 글귀 위젯·읽는책 위젯 양쪽에 푸시한다.
/// 네트워크/비로그인 등 실패는 조용히 무시 — 위젯은 직전 데이터를 유지한다.
Future<void> refreshHomeWidget({
  required BookRepository bookRepo,
  required QuoteRepository quoteRepo,
}) async {
  if (kIsWeb) return;
  try {
    final reading = await bookRepo.listCurrentlyReading(limit: 1);
    await _pushQuoteWidget(reading, quoteRepo);
    await _pushReadingBookWidget(reading);
  } catch (_) {
    // 비로그인/오프라인 등 — 위젯은 직전 데이터 유지.
  }
}

/// '이 책의 한 줄' 위젯 데이터. 우선순위:
///   1) 현재 읽는 책 + 그 책 글귀(잠금 제외, 일일 회전)
///   2) 그 책 글귀 0개 → 제목 + '첫 줄 적기'
///   3) 읽는 책 0권 → '오늘의 인용구'(아무 책 글귀) 강등
///   4) 글귀 전무(신규) → 시작 유도
Future<void> _pushQuoteWidget(
  List<CurrentlyReading> reading,
  QuoteRepository quoteRepo,
) async {
  if (reading.isNotEmpty) {
    final book = reading.first.book;
    final quotes = await quoteRepo.listMyQuotes(bookId: book.id, limit: 30);
    final usable = quotes.where(_isWidgetSafe).toList();
    await HomeWidgetService.instance.push(
      title: book.title,
      author: book.author ?? '',
      quote: usable.isEmpty ? _emptyQuotePrompt : _pickDaily(usable).text!.trim(),
      bookId: book.id,
    );
    return;
  }

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
    await HomeWidgetService.instance.push(
      title: '읽고 있는 책',
      author: '',
      quote: _noBookPrompt,
      bookId: '',
    );
  }
}

/// '읽고 있는 책' 위젯 데이터(HW-D) — 가장 최근 시작 1권 + 표지 + 'N일째'.
Future<void> _pushReadingBookWidget(List<CurrentlyReading> reading) async {
  if (reading.isEmpty) {
    await HomeWidgetService.instance.pushReadingBook(
      title: '',
      author: '',
      daysLabel: '',
      bookId: '',
      coverPath: '',
    );
    return;
  }
  final r = reading.first;
  final book = r.book;
  final url = book.coverUrl;
  final coverPath =
      (url != null && url.isNotEmpty) ? (await _downloadCover(url) ?? '') : '';
  await HomeWidgetService.instance.pushReadingBook(
    title: book.title,
    author: book.author ?? '',
    daysLabel: '${_daysReading(r.startedAt)}일째 읽는 중',
    bookId: book.id,
    coverPath: coverPath,
  );
}

/// 시작일 당일 = 1일째. (날짜만 비교 — 시각 무관)
int _daysReading(DateTime startedAt) {
  final now = DateTime.now();
  final s = DateTime(startedAt.year, startedAt.month, startedAt.day);
  final n = DateTime(now.year, now.month, now.day);
  final d = n.difference(s).inDays + 1;
  return d < 1 ? 1 : d;
}

/// 표지 이미지를 받아 앱 지원 디렉토리에 저장하고 경로를 반환(위젯이 비트맵으로 읽음).
/// 실패하면 null — 위젯은 표지를 숨긴다. (매 갱신 다운로드 — 캐시 최적화는 후속)
Future<String?> _downloadCover(String url) async {
  try {
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) return null;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/reading_cover.png');
    await file.writeAsBytes(resp.bodyBytes, flush: true);
    return file.path;
  } catch (_) {
    return null;
  }
}

/// 위젯에 띄워도 되는 글귀인지 — **잠금(E2EE) 제외** + 평문 본문 존재.
bool _isWidgetSafe(Quote q) =>
    !q.isPrivate && (q.text?.trim().isNotEmpty ?? false);

/// 날짜 기준 결정적 선택 — 같은 날엔 고정, 날이 바뀌면 회전.
T _pickDaily<T>(List<T> items) {
  final dayIndex = DateTime.now().difference(DateTime.utc(2026)).inDays;
  return items[dayIndex.abs() % items.length];
}
