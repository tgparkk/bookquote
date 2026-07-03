import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/card_template.dart';
import '../../domain/quote_card_data.dart';
import '../../state/palette_providers.dart';
import 'quote_card.dart';

class CardTemplateStrip extends StatelessWidget {
  const CardTemplateStrip({
    super.key,
    required this.selected,
    required this.data,
    required this.ratio,
    required this.onSelect,
  });

  final CardTemplate selected;
  final QuoteCardData data;
  final CardRatio ratio;
  final ValueChanged<CardTemplate> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        itemCount: CardTemplate.all.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.s3),
        itemBuilder: (context, i) {
          final t = CardTemplate.all[i];
          final enabled = t.supports(
            charCount: data.charCount,
            hasCover: data.hasCover,
          );
          return _MiniCard(
            template: t,
            data: data,
            ratio: ratio,
            isSelected: t.id == selected.id,
            enabled: enabled,
            onTap: enabled ? () => onSelect(t) : null,
          );
        },
      ),
    );
  }
}

class _MiniCard extends ConsumerWidget {
  const _MiniCard({
    required this.template,
    required this.data,
    required this.ratio,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final CardTemplate template;
  final QuoteCardData data;
  final CardRatio ratio;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = enabled
        ? (ref
                .watch(extractedPaletteProvider((
                  coverUrl: data.coverUrl,
                  templateId: template.id,
                )))
                .value ??
            QuoteCard.fallbackFor(template))
        : QuoteCard.fallbackFor(template);
    return Semantics(
      label:
          '${template.name} 템플릿${isSelected ? ", 선택됨" : ""}${enabled ? "" : ", 표지 필요"}',
      button: true,
      selected: isSelected,
      child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 56,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                border: Border.all(
                  color: AppColors.primary200,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: enabled
                    ? FittedBox(
                        fit: BoxFit.cover,
                        child: QuoteCard(
                          template: template,
                          data: data,
                          palette: palette,
                          ratio: CardRatio.story,
                          watermarkEnabled: false,
                        ),
                      )
                    : Container(
                        color: AppColors.secondary400,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: const Text(
                          '표지 필요',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppFonts.ui,
                            fontWeight: FontWeight.w500,
                            fontSize: 9,
                            color: AppColors.primary600,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              template.name,
              style: TextStyle(
                fontFamily: AppFonts.ui,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 11,
                color: isSelected ? AppColors.accent500 : AppColors.primary600,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 2),
                height: 2,
                width: 24,
                color: AppColors.accent500,
              ),
          ],
        ),
      ),
    ),
    );
  }
}
