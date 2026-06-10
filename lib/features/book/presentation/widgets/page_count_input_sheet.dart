// 책의 쪽수를 사용자가 직접 입력하는 BottomSheet.
//
// Google Books가 페이지 수를 주지 못한 책(국내 독립출판·절판본 등)을 사용자가
// 직접 보완할 수 있는 단일 진입점. 서재 [책] 탭(_spine.dart "두께 미수집"
// 섹션)과 책 상세의 정보 그리드(쪽수 칸)에서 공통으로 호출.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../data/book_repository.dart';
import '../../domain/book.dart';
import '../../state/book_providers.dart';

/// 쪽수 입력 BottomSheet를 열고 저장까지 처리한다. 사용자가 취소했거나 저장 실패면
/// 조용히 return — 호출 측에서 추가 처리할 게 없도록 캡슐화. 저장 성공 시
/// `myLibraryProvider` + `bookByIdProvider(book.id)`를 invalidate해 호출처가 어디든
/// 갱신되게 한다.
Future<void> openPageCountInputSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Book book,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surfaceSheet, // secondary100 → surfaceSheet
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => _PageCountInputSheet(book: book),
  );
  if (saved == null) return;
  try {
    await ref.read(bookRepositoryProvider).setBookPageCount(book.id, saved);
    ref.invalidate(myLibraryProvider);
    ref.invalidate(bookByIdProvider(book.id));
    showAppSnackBarOn(messenger, '"${book.title}" 쪽수를 저장했어요');
  } on BookRepositoryException catch (e) {
    showAppSnackBarOn(messenger, '저장 실패: ${e.message}');
  }
}

class _PageCountInputSheet extends StatefulWidget {
  const _PageCountInputSheet({required this.book});
  final Book book;

  @override
  State<_PageCountInputSheet> createState() => _PageCountInputSheetState();
}

class _PageCountInputSheetState extends State<_PageCountInputSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _controller.text.trim();
    final n = int.tryParse(raw);
    if (n == null || n < 1 || n >= 10000) {
      setState(() => _error = '1~9999 사이의 숫자를 입력해주세요');
      return;
    }
    Navigator.of(context).pop(n);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s6,
        AppSpacing.s6,
        AppSpacing.s6 + viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.book.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle( // const 제거 — 런타임 색
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface, // primary900 → onSurface
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '책 뒷표지나 판권면에 적힌 쪽수를 입력해주세요',
            style: TextStyle( // const 제거 — 런타임 색
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              color: context.colors.onSurfaceSubtle, // primary500 → onSurfaceSubtle
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '쪽수',
              suffixText: '쪽',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              const SizedBox(width: AppSpacing.s2),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.accentDefault,   // accent500 → accentDefault
                  foregroundColor: context.colors.accentOnAccent,  // secondary50 → accentOnAccent
                ),
                onPressed: _submit,
                child: const Text('저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
