import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../../book/presentation/widgets/book_cover.dart';
import '../../data/color_utils.dart';
import '../../domain/quote_card_data.dart';
import 'card_watermark.dart';

/// T4 — 표지 발췌 카드. `docs/design/templates/04-cover-extract.md`.
///
/// 레이어 0: 표지 blur 배경(`ImageFilter.blur` 35px)
/// 레이어 1: `palette.dominant` 72% overlay (PR29: 60→72, 텍스트 대비 보강)
/// 레이어 2: 인용구 텍스트 (NotoSerifKR Bold, 토큰 하한 15px)
/// 레이어 3: 그라데이션 overlay (transparent → `darkVibrant` 85%)
/// 레이어 4: 선명 표지 (우하단)
/// 레이어 5: 책 정보 (좌하단, 선명 표지와 겹치지 않게 maxWidth 540)
/// 레이어 6: 워터마크
///
/// 표지가 없으면 (`data.hasCover == false`) `CardTemplate.supports`가 `false`라
/// 정상 흐름에서는 도달하지 않지만, 도달 시 단색 배경으로 폴백한다.
class CoverExtractCard extends StatelessWidget {
  const CoverExtractCard({
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
      coverSharpW: 360,
      coverSharpH: 504,
      coverSharpX: 640,
      coverSharpY: 1336,
      gradientStartY: 960,
    ),
    CardRatio.feed: _Variant(
      width: 1080,
      height: 1080,
      coverSharpW: 240,
      coverSharpH: 336,
      coverSharpX: 760,
      coverSharpY: 680,
      gradientStartY: 400,
    ),
    CardRatio.post: _Variant(
      width: 1080,
      height: 1350,
      coverSharpW: 300,
      coverSharpH: 420,
      coverSharpX: 700,
      coverSharpY: 880,
      gradientStartY: 600,
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
          Positioned.fill(child: _BlurredBackground(data: data, palette: palette)),
          Positioned.fill(
            child: ColoredBox(
              // PR29: 60→72. blur 배경이 비치는 정도를 줄여 인용구 텍스트와
              // dominant 배경 사이의 실제 대비가 palette.textOnBackground 계산값
              // (vs dominant)에 더 가까워진다.
              color: palette.dominant.withValues(alpha: 0.72),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: v.gradientStartY,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    palette.dominant.withValues(alpha: 0.0),
                    palette.darkVibrant.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 80,
            right: 80,
            top: 200,
            child: Text(
              data.quoteText,
              style: TextStyle(
                fontFamily: AppFonts.quote,
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                height: lineHeight,
                color: palette.textOnBackground,
              ),
            ),
          ),
          Positioned(
            left: v.coverSharpX,
            top: v.coverSharpY,
            width: v.coverSharpW,
            height: v.coverSharpH,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: const <BoxShadow>[AppShadows.card],
                border: Border.all(
                  color: palette.vibrant.withValues(alpha: 0.40),
                  width: 1,
                ),
              ),
              child: BookCover(
                url: data.coverUrl,
                title: data.bookTitle ?? '',
                width: v.coverSharpW,
                height: v.coverSharpH,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
          ),
          Positioned(
            left: 80,
            bottom: 120,
            width: 540,
            child: _BookInfo(data: data, palette: palette),
          ),
          if (watermarkEnabled)
            Positioned(
              right: 80,
              bottom: 60,
              child: CardWatermark(
                config: watermarkConfig,
                color: AppColors.secondary200,
              ),
            ),
        ],
      ),
    );
  }
}

class _BlurredBackground extends StatelessWidget {
  const _BlurredBackground({required this.data, required this.palette});

  final QuoteCardData data;
  final ExtractedPalette palette;

  @override
  Widget build(BuildContext context) {
    if (!data.hasCover) {
      return ColoredBox(color: palette.dominant);
    }
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 35, sigmaY: 35),
      child: CachedNetworkImage(
        imageUrl: data.coverUrl!,
        fit: BoxFit.cover,
        // blur 35px 배경이라 저해상도 디코드로 시각 차이 없음 — 원본 해상도
        // 디코딩은 순수 메모리 낭비(B9).
        memCacheWidth: 250,
        placeholder: (_, _) => ColoredBox(color: palette.dominant),
        errorWidget: (_, _, _) => ColoredBox(color: palette.dominant),
      ),
    );
  }
}

class _BookInfo extends StatelessWidget {
  const _BookInfo({required this.data, required this.palette});

  final QuoteCardData data;
  final ExtractedPalette palette;

  @override
  Widget build(BuildContext context) {
    final hasTitle = data.bookTitle != null && data.bookTitle!.isNotEmpty;
    final hasAuthor = data.bookAuthor != null && data.bookAuthor!.isNotEmpty;
    // PR29: BookInfo는 카드 하단 그라데이션(→ darkVibrant 85%) 구간에 배치된다.
    // palette.subtextOnBackground는 dominant 기준으로 계산되어 하단 darkVibrant
    // 위에서는 대비 미달 가능 — 실제 배경(darkVibrant)에 다시 ensureContrast.
    final infoColor = ensureContrast(
      palette.darkVibrant,
      palette.subtextOnBackground,
      minRatio: 4.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (hasTitle)
          Text(
            data.bookTitle!,
            style: TextStyle(
              fontFamily: AppFonts.quote,
              fontWeight: FontWeight.w500,
              fontSize: 36,
              color: infoColor,
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
              fontSize: 36,
              color: infoColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _Variant {
  const _Variant({
    required this.width,
    required this.height,
    required this.coverSharpW,
    required this.coverSharpH,
    required this.coverSharpX,
    required this.coverSharpY,
    required this.gradientStartY,
  });

  final double width;
  final double height;
  final double coverSharpW;
  final double coverSharpH;
  final double coverSharpX;
  final double coverSharpY;
  final double gradientStartY;
}
