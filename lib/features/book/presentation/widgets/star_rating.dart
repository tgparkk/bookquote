// 별점 위젯 — 1~5 별. [onRated]가 null이면 읽기 전용, 아니면 탭으로 별점을 매긴다.
// 현재 별점과 같은 별을 다시 탭하면 별점을 지운다(onRated(null)).
// 색만으로 의미를 전달하지 않게 채워진 별/빈 별 아이콘 모양으로도 구분된다.

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';

class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.onRated,
    this.size = 28,
  });

  /// 현재 별점 (1~5). 미평가면 null.
  final int? rating;

  /// 별을 탭했을 때 호출 — 값은 1~5 또는 null(지우기). null이면 읽기 전용.
  final ValueChanged<int?>? onRated;

  final double size;

  bool get _interactive => onRated != null;

  @override
  Widget build(BuildContext context) {
    final filled = rating ?? 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          _interactive
              ? IconButton(
                  iconSize: size,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(2),
                  constraints: BoxConstraints(
                    minWidth: size + 8,
                    minHeight: size + 8,
                  ),
                  tooltip: i == filled ? '별점 지우기' : '$i점',
                  onPressed: () => onRated!(i == filled ? null : i),
                  icon: _star(i <= filled, size),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: _star(i <= filled, size),
                ),
      ],
    );
  }

  Widget _star(bool isFilled, double size) => Icon(
        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
        size: size,
        color: isFilled ? AppColors.accent500 : AppColors.primary300,
      );
}
