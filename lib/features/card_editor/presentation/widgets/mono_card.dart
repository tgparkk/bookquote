import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/quote_card_data.dart';
import 'card_watermark.dart';

/// T3 — 모노 카드. `docs/design/templates/03-mono.md`.
///
/// 배경은 항상 `AppColors.monoBackground`(#0F0F0F) 고정.
/// 표지 추출 색은 상/하 1px 라인과 책 제목 글로우(`vibrant`)에만 사용.
/// 따옴표 없이 시작하고 책 제목 앞에 em dash(`— `) prefix.
class MonoCard extends StatelessWidget {
  const MonoCard({
    super.key,
    required this.data,
    required this.palette,
    required this.ratio,
    this.watermarkConfig = AppWatermark.minimal,
    this.watermarkEnabled = true,
  });

  final QuoteCardData data;
  final ExtractedPalette palette;
  final CardRatio ratio;
  final WatermarkConfig watermarkConfig;
  final bool watermarkEnabled;

  static const Map<CardRatio, _Variant> _variants = <CardRatio, _Variant>{
    CardRatio.story: _Variant(
      width: 1080,
      height: 1920,
      topLineY: 120,
      bottomLineFromBottom: 60,
      quoteAreaTop: 300,
      bookAreaFromBottom: 120,
      watermarkFromBottom: 80,
    ),
    CardRatio.feed: _Variant(
      width: 1080,
      height: 1080,
      topLineY: 80,
      bottomLineFromBottom: 40,
      quoteAreaTop: 200,
      bookAreaFromBottom: 80,
      watermarkFromBottom: 56,
    ),
    CardRatio.post: _Variant(
      width: 1080,
      height: 1350,
      topLineY: 100,
      bottomLineFromBottom: 50,
      quoteAreaTop: 240,
      bookAreaFromBottom: 100,
      watermarkFromBottom: 68,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final v = _variants[ratio]!;
    final fontSize = getQuoteFontSize(data.charCount);
    final lineHeight = getQuoteLineHeight(fontSize);
    final hasTitle = data.bookTitle != null && data.bookTitle!.isNotEmpty;
    final hasAuthor = data.bookAuthor != null && data.bookAuthor!.isNotEmpty;
    final hasPublisher =
        data.bookPublisher != null && data.bookPublisher!.isNotEmpty;
    final authorLine = <String>[
      if (hasAuthor) data.bookAuthor!,
      if (hasPublisher) data.bookPublisher!,
    ].join(' · ');

    return SizedBox(
      width: v.width,
      height: v.height,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: ColoredBox(color: AppColors.monoBackground),
          ),
          Positioned(
            left: 80,
            right: 80,
            top: v.topLineY,
            child: Container(height: 1, color: palette.vibrant),
          ),
          Positioned(
            left: 80,
            right: 80,
            top: v.quoteAreaTop,
            child: Text(
              data.quoteText,
              style: TextStyle(
                fontFamily: AppFonts.quote,
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
                height: lineHeight,
                letterSpacing: fontSize * AppLetterSpacing.tight,
                color: AppColors.secondary200,
              ),
            ),
          ),
          Positioned(
            left: 80,
            right: 80,
            bottom: v.bookAreaFromBottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (hasTitle)
                  Text(
                    '— ${data.bookTitle!}',
                    style: TextStyle(
                      fontFamily: AppFonts.ui,
                      fontWeight: FontWeight.w400,
                      fontSize: AppFontSize.sm,
                      letterSpacing: AppFontSize.sm * AppLetterSpacing.wider,
                      color: AppColors.primary300,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (authorLine.isNotEmpty) ...<Widget>[
                  const SizedBox(height: AppSpacing.s1),
                  Text(
                    authorLine,
                    style: TextStyle(
                      fontFamily: AppFonts.ui,
                      fontWeight: FontWeight.w400,
                      fontSize: AppFontSize.xs,
                      letterSpacing: AppFontSize.xs * AppLetterSpacing.wider,
                      color: AppColors.primary400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (watermarkEnabled)
            Positioned(
              right: 80,
              bottom: v.watermarkFromBottom,
              child: CardWatermark(
                config: watermarkConfig,
                color: AppColors.secondary200,
              ),
            ),
          Positioned(
            left: 80,
            right: 80,
            bottom: v.bottomLineFromBottom,
            child: Container(height: 1, color: palette.vibrant),
          ),
        ],
      ),
    );
  }
}

class _Variant {
  const _Variant({
    required this.width,
    required this.height,
    required this.topLineY,
    required this.bottomLineFromBottom,
    required this.quoteAreaTop,
    required this.bookAreaFromBottom,
    required this.watermarkFromBottom,
  });

  final double width;
  final double height;
  final double topLineY;
  final double bottomLineFromBottom;
  final double quoteAreaTop;
  final double bookAreaFromBottom;
  final double watermarkFromBottom;
}
