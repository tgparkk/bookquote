import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../data/color_utils.dart';
import '../../domain/quote_card_data.dart';
import 'card_watermark.dart';

/// T2 — 따뜻 카드. `docs/design/templates/02-warm.md`.
///
/// 9:16·4:5는 좌측 표지 패널 + 우측 텍스트 패널의 sideBySide,
/// 1:1은 표지 상단 가로 전체 + 텍스트 하단의 topBottom(Spotify 스타일).
class WarmCard extends StatelessWidget {
  const WarmCard({
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
      mode: _Mode.sideBySide,
      coverPanelSize: 380,
      paddingTop: 240,
    ),
    CardRatio.feed: _Variant(
      width: 1080,
      height: 1080,
      mode: _Mode.topBottom,
      coverPanelSize: 360,
      paddingTop: 96,
    ),
    CardRatio.post: _Variant(
      width: 1080,
      height: 1350,
      mode: _Mode.sideBySide,
      coverPanelSize: 360,
      paddingTop: 160,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final v = _variants[ratio]!;
    final background = lightenToBackground(palette.dominant);
    final fontSize = getEffectiveQuoteFontSize(data.charCount, fontStep);
    final lineHeight = getQuoteLineHeight(fontSize);

    final cover = _CoverPanel(mode: v.mode, data: data, palette: palette);
    final text = _TextPanel(
      variant: v,
      background: background,
      data: data,
      palette: palette,
      fontSize: fontSize,
      lineHeight: lineHeight,
    );

    final body = v.mode == _Mode.sideBySide
        ? Row(
            children: <Widget>[
              SizedBox(
                width: v.coverPanelSize,
                height: v.height,
                child: cover,
              ),
              Expanded(child: text),
            ],
          )
        : Column(
            children: <Widget>[
              SizedBox(
                width: v.width,
                height: v.coverPanelSize,
                child: cover,
              ),
              Expanded(child: text),
            ],
          );

    return SizedBox(
      width: v.width,
      height: v.height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: body),
          if (watermarkEnabled)
            Positioned(
              right: 64,
              bottom: 80,
              child: CardWatermark(
                config: watermarkConfig,
                color: palette.textOnBackground,
              ),
            ),
        ],
      ),
    );
  }
}

enum _Mode { sideBySide, topBottom }

class _Variant {
  const _Variant({
    required this.width,
    required this.height,
    required this.mode,
    required this.coverPanelSize,
    required this.paddingTop,
  });

  final double width;
  final double height;
  final _Mode mode;
  final double coverPanelSize;
  final double paddingTop;
}

class _CoverPanel extends StatelessWidget {
  const _CoverPanel({
    required this.mode,
    required this.data,
    required this.palette,
  });

  final _Mode mode;
  final QuoteCardData data;
  final ExtractedPalette palette;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = mode == _Mode.sideBySide;
    return Container(
      color: palette.dominant,
      alignment: Alignment.center,
      child: BookCover(
        url: data.coverUrl,
        title: data.bookTitle ?? '',
        width: isHorizontal ? 300 : 240,
        height: isHorizontal ? 420 : 336,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _TextPanel extends StatelessWidget {
  const _TextPanel({
    required this.variant,
    required this.background,
    required this.data,
    required this.palette,
    required this.fontSize,
    required this.lineHeight,
  });

  final _Variant variant;
  final Color background;
  final QuoteCardData data;
  final ExtractedPalette palette;
  final double fontSize;
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    final hasTitle = data.bookTitle != null && data.bookTitle!.isNotEmpty;
    final hasAuthor = data.bookAuthor != null && data.bookAuthor!.isNotEmpty;

    // palette.textOnBackground 등은 표지의 *원본* dominant 기준으로 계산되는데
    // 실제 배경은 `lightenToBackground(palette.dominant)`로 밝혀진 톤이라
    // 그대로 쓰면 대비가 부족해 텍스트가 거의 안 보이는 케이스(특히 어두운 표지)
    // 가 발생. 실 배경 기준으로 재보정한다(2026-05-16 실기기 발견).
    final quoteColor =
        ensureContrast(background, palette.textOnBackground, minRatio: 4.5);
    final titleColor =
        ensureContrast(background, palette.darkVibrant, minRatio: 4.5);
    final authorColor =
        ensureContrast(background, palette.subtextOnBackground, minRatio: 3.0);

    return Container(
      color: background,
      padding: EdgeInsets.fromLTRB(48, variant.paddingTop, 48, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Flexible(
            child: Text(
              data.quoteText,
              style: TextStyle(
                fontFamily: AppFonts.quote,
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
                height: lineHeight,
                color: quoteColor,
              ),
            ),
          ),
          const SizedBox(height: 64),
          Container(
            width: 200,
            height: 1,
            color: palette.vibrant.withValues(alpha: 0.40),
          ),
          const SizedBox(height: 32),
          if (hasTitle)
            Text(
              data.bookTitle!,
              style: TextStyle(
                fontFamily: AppFonts.quote,
                fontWeight: FontWeight.w500,
                fontSize: AppFontSize.md,
                color: titleColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasAuthor) ...<Widget>[
            const SizedBox(height: AppSpacing.s1),
            Text(
              data.bookAuthor!,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontWeight: FontWeight.w400,
                fontSize: AppFontSize.sm,
                color: authorColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
