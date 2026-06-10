import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 에러·NotFound·빈 상태 등 전면 상태 뷰.
///
/// 두 레이아웃 변형:
/// - 기본: `Center` + `Column(min)` — 화면 중앙 배치
/// - [topHeightFraction] 지정: `ListView` + 화면 높이 비례 상단 여백 —
///   스크롤 가능한 본문 화면 (book_detail 계열)
///
/// 색·스타일은 전부 파라미터로 받는다. 내부에서 context.colors를 쓰지
/// 않으므로 카드 테마와 결합하지 않는다 (호출부가 원하는 색을 주입).
class AppStatusView extends StatelessWidget {
  const AppStatusView({
    super.key,
    this.icon,
    this.iconSize = 48,
    this.iconColor,
    this.title,
    this.titleStyle,
    this.subtitle,
    this.subtitleStyle,
    this.actions = const <Widget>[],
    this.padding = const EdgeInsets.all(AppSpacing.s8),
    this.gapAfterTitle = AppSpacing.s2,
    this.gapBeforeActions = AppSpacing.s4,
    this.topHeightFraction,
  });

  final IconData? icon;
  final double iconSize;
  final Color? iconColor;
  final String? title;

  /// 미지정 시 `textTheme.headlineSmall`.
  final TextStyle? titleStyle;
  final String? subtitle;

  /// 미지정 시 `textTheme.bodyMedium`.
  final TextStyle? subtitleStyle;

  /// 버튼들. 2개 이상이면 [AppSpacing.s3] 간격의 가운데 정렬 Row.
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final double gapAfterTitle;
  final double gapBeforeActions;

  /// non-null이면 ListView 변형: 화면 높이 × 이 값만큼 상단 여백.
  final double? topHeightFraction;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final children = <Widget>[
      if (icon != null) ...[
        Icon(icon, size: iconSize, color: iconColor),
        const SizedBox(height: AppSpacing.s4),
      ],
      if (title != null)
        Text(
          title!,
          textAlign: TextAlign.center,
          style: titleStyle ?? textTheme.headlineSmall,
        ),
      if (subtitle != null) ...[
        if (title != null) SizedBox(height: gapAfterTitle),
        Text(
          subtitle!,
          textAlign: TextAlign.center,
          style: subtitleStyle ?? textTheme.bodyMedium,
        ),
      ],
      if (actions.isNotEmpty) ...[
        SizedBox(height: gapBeforeActions),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s3),
              actions[i],
            ],
          ],
        ),
      ],
    ];

    final fraction = topHeightFraction;
    if (fraction != null) {
      return ListView(
        padding: padding,
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * fraction),
          ...children,
        ],
      );
    }
    return Center(
      child: Padding(
        padding: padding,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
