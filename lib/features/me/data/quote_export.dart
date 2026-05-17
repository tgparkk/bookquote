// 내 인용구 Markdown 내보내기 — 전체 인용구를 페이지네이션으로 모아 Markdown 문자열로
// 만든 뒤 임시 `.md` 파일로 저장해 OS 공유 시트에 첨부한다 (차별화 ③ 데이터 주권).
// 문자열 조립은 `markdown_exporter.dart`.
//
// PR14-E B4: 이전에는 `SharePlus.share(ShareParams(text: ...))`로 텍스트를 그대로
// 인텐트에 넣었으나, 컬렉션이 커지면(인용구 250건+) Android Binder transaction
// 한도(~500KB)에 걸려 `TransactionTooLargeException` 위험. `.md` XFile 첨부로
// 일관 전환 — share_plus가 FileProvider 처리.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../quote/data/quote_repository.dart';
import 'markdown_exporter.dart';

enum QuoteExportResult { shared, empty, failed }

/// 내 인용구 전체를 모아 Markdown으로 공유한다. 진행 중 토스트 없이, 결과만 토스트.
/// 반환값으로 호출자(예: 탈퇴 플로우)가 후속 처리 가능.
Future<QuoteExportResult> exportMyQuotesAsMarkdown({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final repo = ref.read(quoteRepositoryProvider);

  final List<QuoteWithBook> entries;
  try {
    entries = await _fetchAllQuotes(repo);
  } catch (_) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('인용구를 불러오지 못해 내보내기를 못 했어요.')),
      );
    return QuoteExportResult.failed;
  }

  if (entries.isEmpty) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('내보낼 인용구가 없어요.')));
    return QuoteExportResult.empty;
  }

  final markdown = buildQuotesMarkdown(entries);
  final subject = '책귀 인용구 ${entries.length}개';
  try {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/bookquote-quotes-$ts.md');
    await file.writeAsString(markdown);
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[
          XFile(
            file.path,
            mimeType: 'text/markdown',
            name: 'bookquote-quotes.md',
          ),
        ],
        text: subject,
        subject: subject,
      ),
    );
    return QuoteExportResult.shared;
  } catch (_) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('내보내기를 마치지 못했어요.')));
    return QuoteExportResult.failed;
  }
}

/// cursor-after로 끝까지 모은다. 페이지 크기는 넉넉히 100.
Future<List<QuoteWithBook>> _fetchAllQuotes(QuoteRepository repo) async {
  const pageSize = 100;
  final all = <QuoteWithBook>[];
  QuoteCursor? after;
  while (true) {
    final page = await repo.listMyQuotesWithBook(after: after, limit: pageSize);
    all.addAll(page);
    if (page.length < pageSize) break;
    final last = page.last.quote;
    after = (createdAt: last.createdAt, id: last.id);
  }
  return all;
}
