import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/card_template.dart';
import '../../domain/quote_card_data.dart';
import 'cover_extract_card.dart';
import 'minimal_card.dart';
import 'mono_card.dart';
import 'typography_card.dart';
import 'warm_card.dart';

/// 5종 템플릿 디스패처. `CardTemplate` 인스턴스 → 해당 위젯 라우팅.
/// 미리보기·골든·`card_renderer`(PR10) 캡처 모두 이 한 위젯을 통한다 — "미리보기=export".
class QuoteCard extends StatelessWidget {
  const QuoteCard({
    super.key,
    required this.template,
    required this.data,
    required this.palette,
    required this.ratio,
    this.watermarkConfig = AppWatermark.minimal,
    this.watermarkEnabled = true,
    this.fontStep = 0,
  });

  final CardTemplate template;
  final QuoteCardData data;
  final ExtractedPalette palette;
  final CardRatio ratio;
  final WatermarkConfig watermarkConfig;
  final bool watermarkEnabled;
  /// 사용자 폰트 미세조정 step(±3). PR12-B.
  final int fontStep;

  /// 템플릿 id에 해당하는 fallback 팔레트. PR8 `palette_service` 도입 전까지 모든 색의 소스.
  static ExtractedPalette fallbackFor(CardTemplate template) =>
      fallbackPalettes[template.id] ?? fallbackPalettes['minimal']!;

  @override
  Widget build(BuildContext context) {
    return switch (template) {
      MinimalTemplate() => MinimalCard(
          data: data,
          palette: palette,
          ratio: ratio,
          watermarkConfig: watermarkConfig,
          watermarkEnabled: watermarkEnabled,
          fontStep: fontStep,
        ),
      WarmTemplate() => WarmCard(
          data: data,
          palette: palette,
          ratio: ratio,
          watermarkConfig: watermarkConfig,
          watermarkEnabled: watermarkEnabled,
          fontStep: fontStep,
        ),
      MonoTemplate() => MonoCard(
          data: data,
          palette: palette,
          ratio: ratio,
          watermarkConfig: watermarkConfig,
          watermarkEnabled: watermarkEnabled,
          fontStep: fontStep,
        ),
      CoverExtractTemplate() => CoverExtractCard(
          data: data,
          palette: palette,
          ratio: ratio,
          watermarkConfig: watermarkConfig,
          watermarkEnabled: watermarkEnabled,
          fontStep: fontStep,
        ),
      TypographyTemplate() => TypographyCard(
          data: data,
          palette: palette,
          ratio: ratio,
          watermarkConfig: watermarkConfig,
          watermarkEnabled: watermarkEnabled,
          fontStep: fontStep,
        ),
    };
  }
}
