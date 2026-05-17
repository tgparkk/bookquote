// 홈 회고 카드 — 차별화 ④ "테마 단위 다시 보기" 진입성 1행.
//
// 사용자가 6개월 만에 책귀를 다시 열어도 첫 화면에서 "다시 만날 이유"를 받는다.
// 가장 많이 모은 무드를 부드러운 카피로 노출 + 탭하면 그 무드 필터로 서재 인용
// 목록 진입. dismissible 7일(`SharedPreferences.recall_card_dismissed_until_v1`).
//
// 출처: scenario-review-2026-05-17.md S5 페르소나 + planner walkthrough 권고 (3).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/tokens.dart';
import '../../domain/quote_mood.dart';
import '../../state/quote_providers.dart';

const String _kRecallDismissedUntil = 'recall_card_dismissed_until_v1';

/// 회고 카드 노출 최소 인용구 수 — 너무 적으면 "가장 많이"라는 단어가 어색.
const int _kMinTotalQuotes = 5;

class RecallCard extends ConsumerStatefulWidget {
  const RecallCard({super.key});

  @override
  ConsumerState<RecallCard> createState() => _RecallCardState();
}

class _RecallCardState extends ConsumerState<RecallCard> {
  bool _checkedPrefs = false;
  DateTime? _dismissedUntil;

  @override
  void initState() {
    super.initState();
    _loadDismissState();
  }

  Future<void> _loadDismissState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRecallDismissedUntil);
      final until = raw == null ? null : DateTime.tryParse(raw);
      if (mounted) {
        setState(() {
          _dismissedUntil = until;
          _checkedPrefs = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checkedPrefs = true);
    }
  }

  Future<void> _dismissForWeek() async {
    final until = DateTime.now().add(const Duration(days: 7));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kRecallDismissedUntil, until.toIso8601String());
    } catch (_) {/* ignore */}
    if (mounted) setState(() => _dismissedUntil = until);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedPrefs) return const SizedBox.shrink();
    if (_dismissedUntil != null &&
        _dismissedUntil!.isAfter(DateTime.now())) {
      return const SizedBox.shrink();
    }

    final countsAsync = ref.watch(moodCountsProvider);
    return countsAsync.maybeWhen(
      data: (counts) {
        if (counts.total < _kMinTotalQuotes) return const SizedBox.shrink();
        if (counts.byMood.isEmpty) return const SizedBox.shrink();

        // 가장 많이 모은 무드 1개 선정.
        final top = counts.byMood.entries
            .reduce((a, b) => a.value >= b.value ? a : b);
        // 단일 무드가 너무 적으면 안내 가치가 약함.
        if (top.value < 3) return const SizedBox.shrink();

        return _buildCard(context, top.key, top.value);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildCard(BuildContext context, QuoteMood mood, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s3,
        AppSpacing.s4,
        0,
      ),
      child: Material(
        color: AppColors.accent50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: () =>
              context.push('/library?tab=quotes&mood=${mood.name}'),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s4,
              AppSpacing.s3,
              AppSpacing.s2,
              AppSpacing.s3,
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.bookmark_rounded,
                  size: 20,
                  color: AppColors.accent600,
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: AppFontSize.sm,
                        color: AppColors.primary700,
                      ),
                      children: <InlineSpan>[
                        const TextSpan(text: '가장 많이 모은 '),
                        TextSpan(
                          text: '"${mood.label}" ',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent700,
                          ),
                        ),
                        TextSpan(text: '$count구절 다시 보기 →'),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '7일 동안 숨기기',
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.primary400,
                  visualDensity: VisualDensity.compact,
                  onPressed: _dismissForWeek,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
