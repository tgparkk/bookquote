// 서재 [인용구] 무드 hub 그리드 (PR22 도입, PR29 리디자인).
//
// 2열 그리드 — 각 카드 = 무드 아이콘·라벨·tagline·카운트 + 평문 발췌 2건.
// 탭하면 [onMoodTap]으로 그 무드 단면 진입(호출자가 QuoteListView를 단면 모드로
// 전환). 잠금만 있는 무드는 발췌 placeholder를 보여준다.
//
// PR29 변경: "카드가 뭘 의미하는지 모르겠다"는 피드백 해결.
// - tagline 1줄("마음이 무거울 때" 등) 라벨 바로 아래.
// - 카운트 pill을 카드 우하단으로 이동 → 라벨이 카드의 1차 정보.
// - 발췌 1줄 → 2건 스택. 한 줄로는 무드의 분위기가 전달되지 않음.
// - aspect ratio 1.05 → 0.80(세로 확장)로 2개 발췌 자리 확보.

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
        // 카드 세로로 확장 — 발췌 2건 + tagline 자리 확보(PR29).
        childAspectRatio: 0.80,
      ),
      itemCount: snapshots.length,
      itemBuilder: (_, i) {
        final s = snapshots[i];
        return _MoodCard(
          snapshot: s,
          onTap: () => onMoodTap(s.mood),
        );
      },
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({
    required this.snapshot,
    required this.onTap,
  });

  final MoodHubSnapshot snapshot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = moodColorOf(snapshot.mood);
    final mood = snapshot.mood;
    final s1 = snapshot.sampleText?.trim();
    final s2 = snapshot.sampleText2?.trim();
    final hasS1 = s1 != null && s1.isNotEmpty;
    final hasS2 = s2 != null && s2.isNotEmpty;

    return Semantics(
      button: true,
      label: '${mood.label} ${snapshot.count}개',
      hint: hasS1 ? '탭하면 이 무드 인용구를 모아 봐요' : '잠금 인용구만 있어요',
      child: Material(
        color: c.light,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.dark.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 헤더: 아이콘 + 라벨 (라벨이 1차 정보)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(mood.icon, size: 18, color: c.dark),
                    const SizedBox(width: AppSpacing.s2),
                    Expanded(
                      child: Text(
                        mood.label,
                        style: TextStyle(
                          fontFamily: AppFonts.ui,
                          fontSize: AppFontSize.base,
                          fontWeight: FontWeight.w700,
                          color: c.dark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // ── tagline: 무드의 정체성을 한 줄로
                Padding(
                  padding: const EdgeInsets.only(left: 18 + AppSpacing.s2),
                  child: Text(
                    mood.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppFonts.ui,
                      fontSize: AppFontSize.xs,
                      color: c.dark.withValues(alpha: 0.60),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s2),
                // ── 발췌 영역
                Expanded(
                  child: hasS1
                      ? _SampleStack(sample1: s1, sample2: hasS2 ? s2 : null, c: c)
                      : Text(
                          '잠긴 인용구만 있어요',
                          style: TextStyle(
                            fontFamily: AppFonts.quote,
                            fontSize: AppFontSize.sm,
                            fontStyle: FontStyle.italic,
                            color: c.dark.withValues(alpha: 0.50),
                          ),
                        ),
                ),
                // ── 카운트 pill을 우하단으로 이동 — 라벨과 시각 weight 경쟁 회피.
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s2,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.dark.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '${snapshot.count}개',
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: AppFontSize.xs,
                        fontWeight: FontWeight.w600,
                        color: c.dark.withValues(alpha: 0.80),
                      ),
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

/// 발췌 1건(+선택적 2건) — 두 번째는 더 작고 흐리게 → "이 무드엔 더 있어요" 신호.
class _SampleStack extends StatelessWidget {
  const _SampleStack({
    required this.sample1,
    required this.sample2,
    required this.c,
  });
  final String sample1;
  final String? sample2;
  final ({Color light, Color dark}) c;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            sample1,
            maxLines: sample2 == null ? 5 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: AppFonts.quote,
              fontSize: AppFontSize.sm,
              height: 1.55,
              color: c.dark.withValues(alpha: 0.82),
            ),
          ),
        ),
        if (sample2 != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
            child: Container(
              height: 1,
              color: c.dark.withValues(alpha: 0.12),
            ),
          ),
          Flexible(
            child: Text(
              sample2!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppFonts.quote,
                fontSize: AppFontSize.xs,
                height: 1.5,
                color: c.dark.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
