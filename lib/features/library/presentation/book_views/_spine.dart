// PR29: 서재 [책] stack/shelf view 모드 공용 위젯·유틸.
//
// - pageCount → 시각 두께 환산 (stack height, shelf spine width).
// - 책 id 해시 기반 결정적 spine 컬러 — 같은 책은 항상 같은 색.
// - "두께 미수집" 섹션 + 수동 입력 BottomSheet — Google Books가 페이지 수를 주지
//   못한 책(국내 독립출판·절판본 등)을 사용자가 직접 보완.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/page_count_input_sheet.dart';

/// stack view의 캡슐 높이 = pageCount × 0.09mm × 2.5(가시화 배율).
/// 28~130px clamp — "쌓아 보기" 메타포라 한 캡슐이 한 줄 텍스트 자리만 차지하면 충분.
/// 두꺼운 책(700p+)은 130px에 cap돼 화면당 권수 보장.
double stackHeightForPages(int pages) {
  final h = pages * 0.09 * 2.5;
  return h.clamp(28.0, 130.0);
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
      onPressed: () =>
          openPageCountInputSheet(context: context, ref: ref, book: book),
    );
  }
}

