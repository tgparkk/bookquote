import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/card_typography.dart';

/// 카드 인용구 본문 — 목표 크기에서 시작해 주어진 영역 높이에 들어갈 때까지
/// 2px씩 줄인다([cardQuoteMinSize] 하한). 하한에서도 넘치면 들어가는 줄까지만
/// 그리고 말줄임 — 책 정보·표지 위로 넘쳐 겹치지 않게.
///
/// 높이 제약이 없으면(unbounded) 목표 크기 그대로.
class CardQuoteText extends StatelessWidget {
  const CardQuoteText({
    super.key,
    required this.text,
    required this.style,
    required this.targetSize,
  });

  final String text;

  /// fontSize·height를 뺀 스타일(폰트·굵기·색). 크기·행간은 여기서 정한다.
  final TextStyle style;
  final double targetSize;

  TextStyle _styleAt(double size) =>
      style.copyWith(fontSize: size, height: cardQuoteLineHeight(size));

  double _heightAt(double size, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _styleAt(size)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout(maxWidth: maxWidth);
    final h = painter.height;
    painter.dispose();
    return h;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        var size = targetSize;
        int? maxLines;
        if (maxHeight.isFinite) {
          while (size > cardQuoteMinSize &&
              _heightAt(size, constraints.maxWidth) > maxHeight) {
            size -= 2;
          }
          size = math.max(size, cardQuoteMinSize);
          if (_heightAt(size, constraints.maxWidth) > maxHeight) {
            final lineHeight = size * cardQuoteLineHeight(size);
            maxLines = math.max(1, (maxHeight / lineHeight).floor());
          }
        }
        return Text(
          text,
          style: _styleAt(size),
          maxLines: maxLines,
          overflow: maxLines == null ? null : TextOverflow.ellipsis,
          textScaler: TextScaler.noScaling,
        );
      },
    );
  }
}
