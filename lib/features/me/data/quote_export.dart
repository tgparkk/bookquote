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
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/tokens.dart';
import '../../quote/data/quote_repository.dart';
import 'markdown_exporter.dart';

enum QuoteExportResult { shared, empty, failed }

/// "데이터 주권" 안내 BottomSheet 1회 노출 플래그 (PR15-A — 차별화 ③ 강화).
const String _kSovereigntyHintShown = 'md_export_sovereignty_hint_v1';

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
    // PR15-A (4): 첫 내보내기 직후 1회만 "데이터 주권" 메시지 BottomSheet —
    // 차별화 ③의 감정 모멘트를 짧은 정보성 시트로 한 번 닿게. SharedPreferences
    // flag로 재발 차단. share 성공 후라 dismissed 되어도 손해 없음.
    if (context.mounted) {
      await _maybeShowSovereigntyHint(context, entries.length);
    }
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

/// 첫 Markdown 내보내기 직후 1회만 노출하는 "데이터 주권" 안내 시트.
/// 차별화 ③ 의 감정 모멘트 — me 화면 ListTile + 토스트만으로는 짧기에 한 번은
/// 명시적으로 사용자에게 닿게 한다 (PR15-A 차별화 강화).
Future<void> _maybeShowSovereigntyHint(
  BuildContext context,
  int count,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSovereigntyHintShown) ?? false) return;
    await prefs.setBool(_kSovereigntyHintShown, true);
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.secondary100,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => _SovereigntyHintSheet(count: count),
    );
  } catch (_) {/* prefs/시트 실패는 무시 — 공유는 이미 성공 */}
}

class _SovereigntyHintSheet extends StatelessWidget {
  const _SovereigntyHintSheet({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s6,
          AppSpacing.s2,
          AppSpacing.s6,
          AppSpacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(
              Icons.lock_open_rounded,
              size: 36,
              color: AppColors.accent500,
            ),
            const SizedBox(height: AppSpacing.s3),
            Text(
              '내보낸 $count구절',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '책귀는 언제든 비워두고 떠날 수 있어요.\n'
              '내 데이터는 항상 내가 가져갈 수 있도록 Markdown으로 받았어요.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.primary600),
            ),
            const SizedBox(height: AppSpacing.s6),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent500,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }
}
