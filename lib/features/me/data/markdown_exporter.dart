// 인용구 → Markdown 문자열 (내 데이터 내보내기 — 차별화 ③ 데이터 주권).
//
// 책별로 그룹지어 헤딩으로 나누고, 각 인용구는 blockquote + 메타(쪽수·무드) 한 줄.
// 책 미연결 인용구는 `manual_book_text`가 있으면 그걸 그룹 제목으로, 없으면 "책 없음".
// 순수 함수 — 네트워크/파일 IO 없음(테스트 쉬움). 공유는 `quote_export.dart`가 담당.

import '../../book/domain/book.dart';
import '../../quote/data/quote_repository.dart';
import '../../quote/domain/quote.dart';

/// [entries](홈 피드와 같은 `QuoteWithBook` 목록, 최근순 가정)를 Markdown 문서로 만든다.
/// [exportedAt]은 헤더의 "내보낸 날짜"(기본 = now).
String buildQuotesMarkdown(
  List<QuoteWithBook> entries, {
  DateTime? exportedAt,
}) {
  final when = exportedAt ?? DateTime.now();
  final buf = StringBuffer()
    ..writeln('# 책귀 — 내 인용구')
    ..writeln()
    ..writeln('> ${entries.length}개 · ${_fmtDate(when)} 내보냄')
    ..writeln();

  if (entries.isEmpty) {
    buf.writeln('아직 모은 인용구가 없어요.');
    return buf.toString();
  }

  // 책 단위로 묶되 첫 등장 순서를 유지한다.
  final groups = <String, _Group>{};
  for (final e in entries) {
    final key = _groupKey(e.quote, e.book);
    (groups[key] ??= _Group(_groupTitle(e.quote, e.book))).quotes.add(e.quote);
  }

  for (final g in groups.values) {
    buf
      ..writeln('## ${g.title}')
      ..writeln();
    for (final q in g.quotes) {
      for (final line in q.text.trim().split('\n')) {
        buf.writeln('> ${line.trimRight()}');
      }
      final meta = _metaLine(q);
      if (meta != null) {
        buf
          ..writeln('>')
          ..writeln('> — $meta');
      }
      buf.writeln();
    }
  }
  return '${buf.toString().trimRight()}\n';
}

class _Group {
  _Group(this.title);
  final String title;
  final List<Quote> quotes = [];
}

String _groupKey(Quote q, Book? book) {
  if (book != null) return 'book:${book.id}';
  final manual = q.manualBookText?.trim();
  if (manual != null && manual.isNotEmpty) return 'manual:${manual.toLowerCase()}';
  return '__none__';
}

String _groupTitle(Quote q, Book? book) {
  if (book != null) {
    final author = book.author?.trim();
    return (author != null && author.isNotEmpty)
        ? '${book.title} — $author'
        : book.title;
  }
  final manual = q.manualBookText?.trim();
  if (manual != null && manual.isNotEmpty) return manual;
  return '책 없음';
}

String? _metaLine(Quote q) {
  final parts = <String>[
    if (q.page != null) '${q.page}쪽',
    if (q.moods.isNotEmpty) q.moods.map((m) => m.label).join(', '),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String _fmtDate(DateTime d) {
  final local = d.toLocal();
  final mm = local.month.toString().padLeft(2, '0');
  final dd = local.day.toString().padLeft(2, '0');
  return '${local.year}-$mm-$dd';
}
