import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/card_template.dart';
import '../../domain/quote_card_data.dart';
import '../../state/palette_providers.dart';
import 'quote_card.dart';

/// 표지에서 추출한 5색 thumbnail + "다른 느낌 ↻" 버튼. PR12-C.
/// 카드 미리보기와 템플릿 스트립 사이에 노출.
class CardPaletteRow extends ConsumerWidget {
  const CardPaletteRow({
    super.key,
    required this.template,
    required this.data,
    required this.selectedIndex,
    required this.onSelect,
    required this.onCycle,
  });

  final CardTemplate template;
  final QuoteCardData data;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCycle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteAsync = ref.watch(extractedPaletteProvider((
      coverUrl: data.coverUrl,
      templateId: template.id,
    )));
    final palette = paletteAsync.value ?? QuoteCard.fallbackFor(template);
    final colors = <Color>[
      palette.dominant,
      palette.secondary,
      palette.vibrant,
      palette.darkVibrant,
      palette.muted,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (var i = 0; i < colors.length; i++)
            _Swatch(
              color: colors[i],
              selected: i == selectedIndex,
              onTap: () => onSelect(i),
              index: i,
            ),
          const SizedBox(width: AppSpacing.s2),
          IconButton(
            tooltip: '다른 느낌 — 다음 템플릿',
            onPressed: onCycle,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.primary600,
            ),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
    required this.index,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '표지에서 추출한 색 ${index + 1}${selected ? ", 선택됨" : ""}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        // PR12-E: hit area 48dp 보장(WCAG/Material). visual은 28dp 유지.
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 28,
              height: 28,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.accent500
                      : const Color(0x14000000),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
