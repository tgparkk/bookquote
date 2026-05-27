// PR29: 서재 [책] stack/shelf view 모드 공용 위젯·유틸.
//
// - pageCount → 시각 두께 환산 (stack height, shelf spine width).
// - 책 id 해시 기반 결정적 spine 컬러 — 같은 책은 항상 같은 색.
// - "두께 미수집" 섹션 + 수동 입력 BottomSheet — Google Books가 페이지 수를 주지
//   못한 책(국내 독립출판·절판본 등)을 사용자가 직접 보완.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/data/book_repository.dart';
import '../../../book/domain/book.dart';
import '../../../book/state/book_providers.dart';

/// 1mm = 4 logical px (stack 세로 가시화 배율). pageCount × 0.09mm/페이지.
/// 50~200px clamp — 너무 얇으면 탭하기 어렵고 너무 두꺼우면 화면 점유 과함.
double stackHeightForPages(int pages) {
  final h = pages * 0.09 * 4.0;
  return h.clamp(50.0, 200.0);
}

/// 1mm = 2.5 logical px (shelf spine 가로 가시화 배율).
/// 20~80px clamp — 너무 좁으면 제목 한 글자도 안 보이고 너무 넓으면 책장 느낌 X.
double shelfWidthForPages(int pages) {
  final w = pages * 0.09 * 2.5;
  return w.clamp(20.0, 80.0);
}

/// 같은 책은 항상 같은 spine 색이 되도록 id 해시로 결정. categoryName 기반은
/// V1엔 카테고리 정규화가 부족(알라딘 raw 값) — id 해시가 안정적·균등.
Color spineColorOf(String bookId) {
  final i = bookId.hashCode.abs() % _spinePalette.length;
  return _spinePalette[i];
}

const List<Color> _spinePalette = [
  Color(0xFF6B4423), // 갈색
  Color(0xFF3D2817), // 진한 갈색
  Color(0xFF2E4057), // 네이비
  Color(0xFF5C4D7D), // 머트 퍼플
  Color(0xFF4A7C59), // 포레스트
  Color(0xFF7D4D1E), // 코퍼
  Color(0xFF2C3E50), // 슬레이트
  Color(0xFF8B2C0F), // 다크 레드
  Color(0xFF1B4F3F), // 틸
  Color(0xFF54430C), // 머스타드
];

/// 두께 미수집 책 섹션 (stack/shelf 하단 공통). 칩 행으로 책 표시 +
/// 탭하면 페이지 수 입력 BottomSheet. 비어 있으면 자체적으로 렌더 안 함.
class PendingThicknessSection extends StatelessWidget {
  const PendingThicknessSection({super.key, required this.books});
  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s6,
        AppSpacing.s4,
        AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: AppColors.primary500,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                '두께 미수집 ${books.length}권',
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            '탭하면 쪽수를 직접 입력할 수 있어요',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.xs,
              color: AppColors.primary400,
            ),
          ),
          const SizedBox(height: AppSpacing.s3),
          Wrap(
            spacing: AppSpacing.s2,
            runSpacing: AppSpacing.s2,
            children: [
              for (final b in books) _PendingChip(book: b),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingChip extends ConsumerWidget {
  const _PendingChip({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      avatar: Icon(
        Icons.edit_outlined,
        size: 14,
        color: AppColors.primary600,
      ),
      label: Text(
        book.title,
        overflow: TextOverflow.ellipsis,
      ),
      labelStyle: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: AppFontSize.xs,
        color: AppColors.primary700,
      ),
      backgroundColor: AppColors.secondary300,
      side: BorderSide(color: AppColors.secondary500),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      onPressed: () => _openPageCountSheet(context, ref, book),
    );
  }
}

Future<void> _openPageCountSheet(
  BuildContext context,
  WidgetRef ref,
  Book book,
) async {
  // ScaffoldMessenger를 await 전에 캡처 — 비동기 갭 후 context 사용 회피.
  final messenger = ScaffoldMessenger.of(context);
  final saved = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.secondary100,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (ctx) => _PageCountInputSheet(book: book),
  );
  if (saved == null) return;
  try {
    await ref.read(bookRepositoryProvider).setBookPageCount(book.id, saved);
    ref.invalidate(myLibraryProvider);
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('"${book.title}" 쪽수를 저장했어요')));
  } on BookRepositoryException catch (e) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('저장 실패: ${e.message}')));
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
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.md,
              fontWeight: FontWeight.w700,
              color: AppColors.primary900,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            '책 뒷표지나 판권면에 적힌 쪽수를 입력해주세요',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              color: AppColors.primary500,
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
                  backgroundColor: AppColors.accent500,
                  foregroundColor: AppColors.secondary50,
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
