import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../domain/card_template.dart';
import '../../domain/quote_card_data.dart';
import '../../state/card_editor_controller.dart';
import 'palette_row.dart';
import 'preview_box.dart';
import 'template_strip.dart';

/// 비율별 안전한 인용구 길이 휴리스틱 — 이 임계를 넘으면 카드에 다 안 들어갈 위험.
/// 1080×{1920/1080/1350} 캔버스에서 NotoSerifKR 15~22px·행간 1.6~1.8 기준 측정값.
/// `screens/card-editor.md §7`의 auto-fit 경고 트리거. PR12-D.
const Map<CardRatio, int> _ratioCharLimit = <CardRatio, int>{
  CardRatio.feed: 300,
  CardRatio.post: 450,
  CardRatio.story: 600,
};

/// 현재 인용구 길이와 비율로 "더 잘 어울리는" 비율을 추천. 현재가 충분히 크면 null.
/// 모든 비율 초과 시에도 가장 큰 비율(story) 추천 — 사용자가 그 다음 어떻게 할지 결정.
CardRatio? _recommendRatio(int charCount, CardRatio current) {
  final entries = _ratioCharLimit.entries.toList()
    ..sort((a, b) => a.value.compareTo(b.value));
  for (final e in entries) {
    if (e.value >= charCount && e.key != current) return e.key;
  }
  return null;
}

class CardEditorPanel extends ConsumerWidget {
  const CardEditorPanel({super.key, required this.data, required this.captureKey});

  final QuoteCardData data;
  final GlobalKey captureKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cardEditorControllerProvider);
    final controller = ref.read(cardEditorControllerProvider.notifier);
    final template = CardTemplate.byId(state.templateId);

    // F8: 템플릿 전환 직전 사용자가 폰트 ±로 조정해뒀다면, setTemplate이 fontStep을
    // 0으로 리셋한 사실을 SnackBar로 안내. 이미 0이면 toast 생략.
    void notifyFontReset() {
      showAppSnackBar(
        context,
        '템플릿이 바뀌면서 글자 크기는 기본으로 되돌렸어요.',
        duration: const Duration(milliseconds: 1800),
      );
    }

    final fontBaseline = CardEditorState.initial.fontStep;
    void selectTemplate(CardTemplate t) {
      final hadTweak = state.fontStep != fontBaseline;
      final willChange = state.templateId != t.id;
      controller.setTemplate(t.id);
      if (hadTweak && willChange) notifyFontReset();
    }

    void cycleTemplate() {
      final hadTweak = state.fontStep != fontBaseline;
      final beforeId = state.templateId;
      controller.cycleTemplate(
        charCount: data.charCount,
        hasCover: data.hasCover,
      );
      final afterId = ref.read(cardEditorControllerProvider).templateId;
      if (hadTweak && afterId != beforeId) notifyFontReset();
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s4,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _RatioSegment(
                value: state.ratio,
                onChanged: controller.setRatio,
              ),
              const SizedBox(width: AppSpacing.s3),
              _FontSteppers(
                step: state.fontStep,
                onDecrease: controller.decreaseFont,
                onIncrease: controller.increaseFont,
              ),
            ],
          ),
        ),
        if (data.charCount > (_ratioCharLimit[state.ratio] ?? 600))
          _AutoFitWarning(
            currentRatio: state.ratio,
            charCount: data.charCount,
            onApplyRatio: controller.setRatio,
          ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: CardPreviewBox(
                captureKey: captureKey,
                template: template,
                data: data,
                ratio: state.ratio,
                watermarkEnabled: state.watermarkEnabled,
                fontStep: state.fontStep,
                paletteSlotIndex: state.paletteSlotIndex,
              ),
            ),
          ),
        ),
        CardPaletteRow(
          template: template,
          data: data,
          selectedIndex: state.paletteSlotIndex,
          onSelect: controller.setPaletteSlot,
          onCycle: cycleTemplate,
        ),
        const SizedBox(height: AppSpacing.s2),
        CardTemplateStrip(
          selected: template,
          data: data,
          ratio: state.ratio,
          onSelect: selectTemplate,
        ),
        const SizedBox(height: AppSpacing.s4),
      ],
    );
  }
}

class _RatioSegment extends StatelessWidget {
  const _RatioSegment({required this.value, required this.onChanged});

  final CardRatio value;
  final ValueChanged<CardRatio> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CardRatio>(
      // B16: textStyle override 제거 — 고정 fontSize.xs면 시스템 1.3x에서
      // 레이블이 잘려 보임. Theme(textTheme.labelLarge)에 위임해 textScaler 적용.
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segments: const <ButtonSegment<CardRatio>>[
        ButtonSegment(value: CardRatio.feed, label: Text('1:1')),
        ButtonSegment(value: CardRatio.post, label: Text('4:5')),
        ButtonSegment(value: CardRatio.story, label: Text('9:16')),
      ],
      selected: <CardRatio>{value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

/// 인용구가 현재 비율에 다 안 들어갈 위험을 알린다. 더 잘 어울리는 비율이 있으면
/// 1탭으로 적용. `screens/card-editor.md §7` 명세 — "잘린 채 조용히 export 금지".
/// PR12-D.
class _AutoFitWarning extends StatelessWidget {
  const _AutoFitWarning({
    required this.currentRatio,
    required this.charCount,
    required this.onApplyRatio,
  });

  final CardRatio currentRatio;
  final int charCount;
  final ValueChanged<CardRatio> onApplyRatio;

  @override
  Widget build(BuildContext context) {
    final recommended = _recommendRatio(charCount, currentRatio);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: AppSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: AppColors.semanticWarningLight,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: AppColors.semanticWarning.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            const Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.semanticWarning,
            ),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Text(
                recommended != null
                    ? '이 인용구는 ${currentRatio.label}에서 잘릴 수 있어요. ${recommended.label}을 추천해요.'
                    : '카드에 다 안 들어갈 수 있어요. 텍스트를 줄이거나 비율을 바꿔 보세요.',
                style: const TextStyle(
                  fontFamily: AppFonts.ui,
                  fontSize: AppFontSize.sm,
                  color: AppColors.semanticWarning,
                ),
              ),
            ),
            if (recommended != null) ...<Widget>[
              const SizedBox(width: AppSpacing.s2),
              TextButton(
                onPressed: () => onApplyRatio(recommended),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s2,
                  ),
                  foregroundColor: AppColors.semanticWarning,
                ),
                child: Text('${recommended.label} 적용'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 비율 행에 함께 노출하는 [A−][A+] 폰트 미세조정. PR12-B.
class _FontSteppers extends StatelessWidget {
  const _FontSteppers({
    required this.step,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int step;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    final canDecrease = step > CardEditorState.fontStepMin;
    final canIncrease = step < CardEditorState.fontStepMax;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          tooltip: '글자 작게',
          onPressed: canDecrease ? onDecrease : null,
          icon: Icon(
            Icons.text_decrease_rounded,
            color: canDecrease
                ? AppColors.primary600
                : AppColors.primary300,
          ),
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          tooltip: '글자 크게',
          onPressed: canIncrease ? onIncrease : null,
          icon: Icon(
            Icons.text_increase_rounded,
            color: canIncrease
                ? AppColors.primary600
                : AppColors.primary300,
          ),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
