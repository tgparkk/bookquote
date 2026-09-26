// PR29: 서재 [책] stack/shelf view 모드 공용 위젯·유틸.
//
// - pageCount → 시각 두께 환산 (stack height, shelf spine width).
// - 책 id 해시 기반 결정적 spine 컬러 — 같은 책은 항상 같은 색.
// - "두께 미수집" 섹션 + 수동 입력 BottomSheet — Google Books가 페이지 수를 주지
//   못한 책(국내 독립출판·절판본 등)을 사용자가 직접 보완.
// - "인용 N" 라벨 · "읽는 중" 책갈피 리본 (list·stack 공용).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../book/domain/book.dart';
import '../../../book/presentation/widgets/page_count_input_sheet.dart';
import '../../../quote/state/quote_providers.dart';

/// 책 행·캡슐의 인용 수 라벨. `bookQuotesProvider`는 첫 [kBookQuotesLimit]개만
/// 받아오므로 상한이면 "N+".
String quoteCountLabel(int count) => count >= kBookQuotesLimit
    ? '인용 $kBookQuotesLimit+'
    : '인용 $count';

/// "읽는 중" 가름끈 마크 — 가늘고 긴 딥 와인색 리본(아래 얕은 제비꼬리). 글자 대신
/// 마크(2026-09-26 사용자 선택, 디자이너 2인 시안 종합). 호출자가 표지와 책등의
/// 경계 윗변에 걸쳐 배치해 "책 사이에 끼운 가름끈"처럼 보이게 한다 — 표지 그림과
/// ⋮ 힌트를 가리지 않는다. [ReadingGroupHeader]의 범례로도 쓴다.
class ReadingRibbon extends StatelessWidget {
  const ReadingRibbon({
    super.key,
    this.width = 6,
    this.height = 20,
    this.excludeSemantics = false,
  });

  final double width;
  final double height;

  /// 범례처럼 옆 글자가 이미 "읽는 중"을 말하면 true — 낭독 중복 방지.
  final bool excludeSemantics;

  @override
  Widget build(BuildContext context) {
    final mark = CustomPaint(
      size: Size(width, height),
      painter: const _RibbonPainter(),
    );
    return IgnorePointer(
      child: excludeSemantics
          ? ExcludeSemantics(child: mark)
          : Semantics(label: '읽는 중', child: mark),
    );
  }
}

// 가름끈 색 — 회고 카드·강조색(구리)과 겹치지 않는 별도 계열. 라이트·다크 동일.
const Color _ribbonTop = Color(0xFF5A222C);
const Color _ribbonBottom = Color(0xFF7A2E3A);
const Color _ribbonFold = Color(0xFF3F1720);

/// 위가 짙은 세로 그라데이션(책 사이에서 빠져나온 깊이감) + 윗단 접힘 띠 + 옅은
/// 흰 바탕(어두운 책등에서도 윤곽 유지) + 약한 그림자.
class _RibbonPainter extends CustomPainter {
  const _RibbonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final notch = size.width * 0.4;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height - notch)
      ..lineTo(0, size.height)
      ..close();
    final rect = Offset.zero & size;
    canvas.drawShadow(
        path, AppColors.primary900.withValues(alpha: 0.5), 1.5, false);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.secondary50.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_ribbonTop, _ribbonBottom],
        ).createShader(rect),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height < 24 ? 1.5 : 2.5),
      Paint()..color = _ribbonFold,
    );
  }

  @override
  bool shouldRepaint(_RibbonPainter oldDelegate) => false;
}

/// 읽는 중 묶음 제목 — 리본 범례 + "지금 읽는 중 · N권". 같은 마크의 반복을
/// 의도된 묶음으로 읽히게 하고, "읽는 중 먼저" 정렬 기준을 드러낸다.
class ReadingGroupHeader extends StatelessWidget {
  const ReadingGroupHeader({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          const ReadingRibbon(width: 6, height: 14, excludeSemantics: true),
          const SizedBox(width: AppSpacing.s2),
          Text(
            '지금 읽는 중',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurface,
            ),
          ),
          Text(
            ' · $count권',
            style: TextStyle(
              fontFamily: AppFonts.ui,
              fontSize: AppFontSize.sm,
              color: context.colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 읽는 중 묶음과 나머지 책 사이 구분선 — 행 사이 구분선보다 굵게.
class ReadingGroupDivider extends StatelessWidget {
  const ReadingGroupDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(height: 2, color: context.colors.border);
  }
}

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
                color: context.colors.onSurfaceMuted,
              ),
              const SizedBox(width: AppSpacing.s2),
              Text(
                '두께 미수집 ${books.length}권',
                style: TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.sm,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurfaceMuted,
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
              color: context.colors.onSurfaceSubtle,
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
        color: context.colors.iconPrimary,
      ),
      label: Text(
        book.title,
        overflow: TextOverflow.ellipsis,
      ),
      labelStyle: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: AppFontSize.xs,
        color: context.colors.onSurface,
      ),
      backgroundColor: context.colors.chipBg,
      side: BorderSide(color: context.colors.border),
      shape: const StadiumBorder(),
      visualDensity: VisualDensity.compact,
      onPressed: () =>
          openPageCountInputSheet(context: context, ref: ref, book: book),
    );
  }
}

