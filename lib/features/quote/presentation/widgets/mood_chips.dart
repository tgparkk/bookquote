// 무드 태그 선택 칩 행.
//
// `QuoteMood`별 색 매핑(`moodColors`)의 단일 정의처 — 인용구 입력·목록·카드 등에서
// 이 위젯/맵을 재사용한다. 색만으로 의미를 전달하지 않도록 칩에 항상 한국어 라벨을
// 함께 보여준다. 선택 한도(최대 3개)는 호출자가 `onToggle`에서 처리.

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/quote_mood.dart';

/// 무드별 (연한 배경 / 어두운 텍스트) 쌍. Ink-Paper-Copper 토큰 기반.
const Map<QuoteMood, ({Color light, Color dark})> moodColors = {
  QuoteMood.comfort: (
    light: AppColors.semanticSuccessLight,
    dark: AppColors.semanticSuccess,
  ),
  QuoteMood.wistful: (light: AppColors.neutral100, dark: AppColors.neutral600),
  QuoteMood.lateNight: (
    light: AppColors.semanticInfoLight,
    dark: AppColors.semanticInfo,
  ),
  QuoteMood.insight: (light: AppColors.accent100, dark: AppColors.accent700),
  QuoteMood.excitement: (light: AppColors.accent50, dark: AppColors.accent600),
};

({Color light, Color dark}) moodColorOf(QuoteMood mood) =>
    moodColors[mood] ?? (light: AppColors.secondary300, dark: AppColors.primary500);

/// 무드 태그 다중 선택 칩 행. [onToggle]은 칩이 눌릴 때마다 그 무드를 넘긴다
/// (선택/해제 토글 + 한도 검사는 호출자 책임).
class MoodChips extends StatelessWidget {
  const MoodChips({
    super.key,
    required this.selected,
    required this.onToggle,
  });

  final Set<QuoteMood> selected;
  final ValueChanged<QuoteMood> onToggle;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s2,
      runSpacing: AppSpacing.s2,
      children: [
        for (final mood in QuoteMood.values)
          _MoodChip(
            mood: mood,
            selected: selected.contains(mood),
            onTap: () => onToggle(mood),
          ),
      ],
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final QuoteMood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = moodColorOf(mood);
    // F9: 시스템 글씨 1.3x에서 칩이 과하게 커져 Wrap 줄바꿈/레이아웃 마찰. 칩은
    // UI 컨트롤이므로 max 1.15x로 clamp(어르신/저시력 케이스 어느 정도 보장하되
    // 레이아웃 안정성 유지).
    final clamped =
        MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15);
    return ChoiceChip(
      label: Text(mood.label, textScaler: clamped),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: c.light,
      selectedColor: AppColors.primary900,
      side: BorderSide(color: selected ? AppColors.primary900 : c.light),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(
        fontFamily: AppFonts.ui,
        fontSize: AppFontSize.sm,
        fontWeight: FontWeight.w500,
        color: selected ? AppColors.secondary50 : c.dark,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}
