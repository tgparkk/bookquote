// 서재 [인용구] 무드 hub 그리드 (PR22).
//
// 2열 그리드 — 각 카드 = 무드 아이콘·라벨·카운트 + 대표 한 줄 발췌(평문만).
// 탭하면 [onMoodTap]으로 그 무드 단면 진입(호출자가 QuoteListView를 단면 모드로
// 전환). 잠긴 인용구 한 줄만 있는 무드는 발췌 placeholder를 보여준다.
//
// 색감은 `mood_chips.dart`의 `moodColorOf` 단일 정의처를 재사용 — 무드 시각
// 언어가 칩·hub·미래 카드 디자인까지 일관.

import 'package:flutter/material.dart';

import '../../../../core/theme/tokens.dart';
import '../../data/quote_repository.dart' show MoodHubSnapshot;
import '../../domain/quote_mood.dart';
import 'mood_chips.dart' show moodColorOf;

class MoodHubGrid extends StatelessWidget {
  const MoodHubGrid({
    super.key,
    required this.snapshots,
    required this.onMoodTap,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.s4,
      AppSpacing.s2,
      AppSpacing.s4,
      AppSpacing.s8,
    ),
  });

  final List<MoodHubSnapshot> snapshots;
  final ValueChanged<QuoteMood> onMoodTap;
  final EdgeInsets padding;

  static IconData _iconFor(QuoteMood mood) => switch (mood) {
        QuoteMood.comfort => Icons.favorite_outline_rounded,
        QuoteMood.wistful => Icons.cloud_outlined,
        QuoteMood.lateNight => Icons.nightlight_outlined,
        QuoteMood.insight => Icons.lightbulb_outline_rounded,
        QuoteMood.excitement => Icons.auto_awesome_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      // RefreshIndicator로 감쌀 때 끝까지 짧아도 pull 가능하도록.
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s3,
        crossAxisSpacing: AppSpacing.s3,
        childAspectRatio: 0.95,
      ),
      itemCount: snapshots.length,
      itemBuilder: (_, i) {
        final s = snapshots[i];
        return _MoodCard(
          snapshot: s,
          icon: _iconFor(s.mood),
          onTap: () => onMoodTap(s.mood),
        );
      },
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.snapshot,
    required this.icon,
    required this.onTap,
  });

  final MoodHubSnapshot snapshot;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = moodColorOf(snapshot.mood);
    final hasSample =
        snapshot.sampleText != null && snapshot.sampleText!.trim().isNotEmpty;

    return Semantics(
      button: true,
      label: '${snapshot.mood.label} ${snapshot.count}개',
      hint: hasSample ? '탭하면 이 무드 인용구를 모아 봐요' : '잠금 인용구만 있어요',
      child: Material(
        color: c.light,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.dark.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: c.dark),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(
                      child: Text(
                        snapshot.mood.label,
                        style: TextStyle(
                          fontFamily: AppFonts.ui,
                          fontSize: AppFontSize.md,
                          fontWeight: FontWeight.w700,
                          color: c.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${snapshot.count}',
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: AppFontSize.sm,
                        fontWeight: FontWeight.w600,
                        color: c.dark.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: c.dark.withValues(alpha: 0.15),
                  ),
                ),
                Expanded(
                  child: Text(
                    hasSample ? snapshot.sampleText! : '잠긴 인용구만 있어요',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.quote,
                      fontSize: AppFontSize.sm,
                      height: 1.45,
                      fontStyle: hasSample ? FontStyle.normal : FontStyle.italic,
                      color: hasSample
                          ? c.dark.withValues(alpha: 0.88)
                          : c.dark.withValues(alpha: 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
