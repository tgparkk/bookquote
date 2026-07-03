import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../profile/data/profile_repository.dart';
import '../../data/color_utils.dart';
import '../../domain/card_template.dart';
import '../../domain/quote_card_data.dart';
import '../../state/palette_providers.dart';
import 'quote_card.dart';

class CardPreviewBox extends ConsumerWidget {
  const CardPreviewBox({
    super.key,
    required this.captureKey,
    required this.template,
    required this.data,
    required this.ratio,
    required this.watermarkEnabled,
    required this.fontStep,
    required this.paletteSlotIndex,
  });

  final GlobalKey captureKey;
  final CardTemplate template;
  final QuoteCardData data;
  final CardRatio ratio;
  final bool watermarkEnabled;
  final int fontStep;
  final int paletteSlotIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteAsync = ref.watch(extractedPaletteProvider((
      coverUrl: data.coverUrl,
      templateId: template.id,
    )));
    final rawPalette = paletteAsync.value ?? QuoteCard.fallbackFor(template);
    final palette = applyPaletteSlot(rawPalette, paletteSlotIndex);
    final displayName = ref.watch(myProfileProvider).value?.displayName;
    final watermarkConfig = AppWatermark.forUser(displayName);
    return Semantics(
      label: '카드 미리보기, ${template.name} 템플릿, 인용구: ${data.quoteText}',
      child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const <BoxShadow>[AppShadows.card],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AspectRatio(
          aspectRatio: ratio.size.aspectRatio,
          // `card_renderer.renderCardPng`이 toImage 로 캡처하는 지점.
          // boundary.size = 화면 표시 크기, pixelRatio 로 1080 폭까지 업스케일.
          child: RepaintBoundary(
            key: captureKey,
            child: FittedBox(
              fit: BoxFit.contain,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: QuoteCard(
                  key: ValueKey<String>(
                    '${template.id}-${data.coverUrl ?? ""}-$watermarkEnabled-$fontStep-$paletteSlotIndex-${displayName ?? ""}',
                  ),
                  template: template,
                  data: data,
                  palette: palette,
                  ratio: ratio,
                  watermarkConfig: watermarkConfig,
                  watermarkEnabled: watermarkEnabled,
                  fontStep: fontStep,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
