import 'package:flutter/material.dart';

/// 화면·섹션 중앙 로딩. `Center(child: CircularProgressIndicator())` 표준형.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// 버튼·타일 안에 들어가는 소형 스피너.
class AppInlineSpinner extends StatelessWidget {
  const AppInlineSpinner({
    super.key,
    this.size = 16,
    this.strokeWidth = 2,
    this.color,
  });

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: strokeWidth, color: color),
      );
}
