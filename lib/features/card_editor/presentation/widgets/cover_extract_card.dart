import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import 'card_cover_image.dart';
import '../../data/color_utils.dart';
import '../../domain/card_typography.dart';
import '../../domain/quote_card_data.dart';
import 'card_quote_text.dart';
import 'card_watermark.dart';

/// T4 — 표지 발췌 카드. `docs/design/templates/04-cover-extract.md`.
///
/// 레이어 0: 표지 blur 배경(16px 디코드 + `ImageFilter.blur` 160 — 명세 35px×4.8)
/// 레이어 1: `palette.dominant` 72% overlay (PR29: 60→72, 텍스트 대비 보강)
/// 레이어 2: 인용구 텍스트 (NotoSerifKR Bold, 토큰 하한 15px)
/// 레이어 3: 그라데이션 overlay (transparent → `darkVibrant` 85%)
/// 레이어 4: 선명 표지 (우하단)
/// 레이어 5: 책 정보 (좌하단, 선명 표지와 겹치지 않게 maxWidth 540)
/// 레이어 6: 워터마크 (좌하단 책 정보 아래 — 선명 표지를 가리지 않게)
///
/// 표지가 없으면 (`data.hasCover == false`) `CardTemplate.supports`가 `false`라
/// 정상 흐름에서는 도달하지 않지만, 도달 시 단색 배경으로 폴백한다.
/// 인용구 영역 하단과 선명 표지 상단 사이 간격.
const double _quoteCoverGap = 48;

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
    final targetSize = cardQuoteTargetSize(data.charCount, fontStep);

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
          // 인용구는 선명 표지 위쪽까지만 — 길어도 표지·책 정보와 겹치지 않게
          // 그 높이 안에서 맞춘다(CardQuoteText).
          Positioned(
            left: 80,
            right: 80,
            top: 200,
            height: v.coverSharpY - _quoteCoverGap - 200,
            child: CardQuoteText(
              text: data.quoteText,
              targetSize: targetSize,
              style: TextStyle(
                fontFamily: AppFonts.quote,
                fontWeight: FontWeight.w700,
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
              child: CardCoverImage(
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
            // 우하단은 선명 표지(레이어 4) 자리 — 워터마크가 표지를 가리면 안
            // 된다(2026-08-01 사용자 피드백). 좌하단 책 정보(bottom:120) 아래로.
            // 폭은 표지 왼쪽 경계 전까지로 제한 — 긴 닉네임이 표지 영역까지
            // 뻗어 겹치던 문제(FittedBox로 줄여서 브랜드 병기 유지).
            Positioned(
              left: 80,
              bottom: 60,
              width: v.coverSharpX - 80 - 32,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CardWatermark(
                  config: watermarkConfig,
                  color: AppColors.secondary200,
                ),
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
    // 명세의 "blur 35px"는 225px 폭 목업 기준이라 1080 캔버스에선 ×4.8 ≈ 170.
    // 35 그대로 두니 표지에 인쇄된 제목·띠가 카드 전체로 늘어난 400px급 덩어리를
    // 못 지워 "로딩 스켈레톤" 같은 흐린 막대로 남았다(2026-10-10). 16px 폭
    // 디코드로 인쇄 요소를 먼저 뭉개고(업스케일 보간) 큰 blur로 경계를 지운다.
    // 저해상도 디코드는 메모리도 절약(B9).
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 160, sigmaY: 160),
      // 16px 디코드 provider는 card_cover_image.dart — 공유 캡처 전 precache 대상.
      child: CardBackdropImage(
        url: data.coverUrl!,
        fallback: palette.dominant,
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
