import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../domain/quote_card_data.dart';
import 'card_watermark.dart';

/// T1 — 미니멀 카드. `docs/design/templates/01-minimal.md` 명세 기반.
///
/// 캔버스는 명세대로 1080×{1920|1080|1350} 절대 픽셀로 그린다.
/// 호출자(`QuoteCard` 디스패처)가 `FittedBox`로 화면 폭에 축소하고,
/// `card_renderer`(PR10)는 같은 위젯 트리를 그대로 PNG로 캡처한다 — "미리보기=export".
class MinimalCard extends StatelessWidget {
  const MinimalCard({
    super.key,
    required this.data,
    required this.palette,
    required this.ratio,
    this.watermarkConfig = AppWatermark.minimal,
    this.watermarkEnabled = true,
    this.fontStep = 0,
  });

  final QuoteCardData data;
  final ExtractedPalette palette;
  final CardRatio ratio;
  final WatermarkConfig watermarkConfig;
  final bool watermarkEnabled;
  final int fontStep;

  static const Map<CardRatio, _Variant> _variants = <CardRatio, _Variant>{
    CardRatio.story: _Variant(
      width: 1080,
      height: 1920,
      paddingTop: 192,
      paddingBottom: 144,
      paddingHorizontal: 96,
    ),
    CardRatio.feed: _Variant(
      width: 1080,
      height: 1080,
      paddingTop: 96,
      paddingBottom: 80,
      paddingHorizontal: 96,
    ),
    CardRatio.post: _Variant(
      width: 1080,
      height: 1350,
      paddingTop: 144,
      paddingBottom: 112,
      paddingHorizontal: 96,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final v = _variants[ratio]!;
    final fontSize = getEffectiveQuoteFontSize(data.charCount, fontStep);
    final lineHeight = getQuoteLineHeight(fontSize);

    return SizedBox(
      width: v.width,
      height: v.height,
      child: Stack(
        children: <Widget>[
          const Positioned.fill(
            child: ColoredBox(color: AppColors.secondary200),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              v.paddingHorizontal,
              v.paddingTop,
              v.paddingHorizontal,
              v.paddingBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  data.quoteText,
                  style: TextStyle(
                    fontFamily: AppFonts.quote,
                    fontWeight: FontWeight.w500,
                    fontSize: fontSize,
                    height: lineHeight,
                    color: AppColors.primary800,
                  ),
                ),
                const SizedBox(height: 96),
                Container(
                  height: 1,
                  color: palette.vibrant.withValues(alpha: 0.30),
                ),
                const SizedBox(height: 48),
                _BookRow(data: data, palette: palette),
              ],
            ),
          ),
          if (watermarkEnabled)
            Positioned(
              right: 96,
              bottom: 80,
              child: CardWatermark(
                config: watermarkConfig,
                color: AppColors.primary900,
              ),
            ),
        ],
      ),
    );
  }
}

class _BookRow extends StatelessWidget {
  const _BookRow({required this.data, required this.palette});

  final QuoteCardData data;
  final ExtractedPalette palette;

  @override
  Widget build(BuildContext context) {
    final hasTitle = data.bookTitle != null && data.bookTitle!.isNotEmpty;
    final hasAuthor = data.bookAuthor != null && data.bookAuthor!.isNotEmpty;
    final hasPublisher =
        data.bookPublisher != null && data.bookPublisher!.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        BookCover(
          url: data.coverUrl,
          title: data.bookTitle ?? '',
          width: 60,
          height: 84,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (hasTitle)
                Text(
                  data.bookTitle!,
                  style: TextStyle(
                    fontFamily: AppFonts.quote,
                    fontWeight: FontWeight.w500,
                    fontSize: AppFontSize.base,
                    color: palette.darkVibrant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (hasAuthor) ...<Widget>[
                const SizedBox(height: AppSpacing.s1),
                Text(
                  data.bookAuthor!,
                  style: const TextStyle(
                    fontFamily: AppFonts.ui,
                    fontWeight: FontWeight.w400,
                    fontSize: AppFontSize.sm,
                    color: AppColors.primary500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (hasPublisher) ...<Widget>[
                const SizedBox(height: AppSpacing.s1),
                Text(
                  data.bookPublisher!,
                  style: const TextStyle(
                    fontFamily: AppFonts.ui,
                    fontWeight: FontWeight.w400,
                    fontSize: AppFontSize.xs,
                    color: AppColors.primary400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Variant {
  const _Variant({
    required this.width,
    required this.height,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingHorizontal,
  });

  final double width;
  final double height;
  final double paddingTop;
  final double paddingBottom;
  final double paddingHorizontal;
}
