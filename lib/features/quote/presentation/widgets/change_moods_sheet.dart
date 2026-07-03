// 인용구 무드 변경 BottomSheet (PR3 — 2026-05-28).
//
// 펼친 카드 [무드] 액션에서 호출. 현재 무드를 preselect, 최대 3개까지 토글 가능
// (입력 화면과 동일 제약). [저장] 시 `setMoods` RPC 한 번 — 본문/잠금 컬럼은
// 안 건드림. 성공 시 caller가 quoteFeed/moodCounts/quoteById invalidate.
//
// quote_input_screen 전체 편집 모드보다 가볍게 — 책 연결·페이지·잠금 토글을
// 건드리지 않고 무드만 빠르게 바꾸는 동선.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/ui/app_snackbar.dart';
import '../../data/quote_repository.dart';
import '../../domain/quote.dart';
import '../../domain/quote_mood.dart';
import 'mood_chips.dart';

const int _kMaxMoods = 3;

/// `quote.moods`를 초기값으로 시트를 띄우고, 사용자가 저장하면 새 무드 set을
/// 반환한다. 취소/dismiss면 null. caller는 반환값을 보고 provider invalidate.
Future<Set<QuoteMood>?> showChangeMoodsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Quote quote,
}) {
  // 바텀시트 배경: 라이트=secondary100, 다크=primary800(surfaceSheet 토큰)
  final sheetBg = AppSemanticColors.of(context).surfaceSheet;
  return showModalBottomSheet<Set<QuoteMood>>(
    context: context,
    backgroundColor: sheetBg,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (ctx) => _ChangeMoodsSheet(quote: quote, ref: ref),
  );
}

class _ChangeMoodsSheet extends StatefulWidget {
  const _ChangeMoodsSheet({required this.quote, required this.ref});

  final Quote quote;
  final WidgetRef ref;

  @override
  State<_ChangeMoodsSheet> createState() => _ChangeMoodsSheetState();
}

class _ChangeMoodsSheetState extends State<_ChangeMoodsSheet> {
  late final Set<QuoteMood> _selected = {...widget.quote.moods};
  bool _saving = false;

  void _toggle(QuoteMood mood) {
    setState(() {
      if (_selected.contains(mood)) {
        _selected.remove(mood);
      } else {
        if (_selected.length >= _kMaxMoods) {
          showAppSnackBar(
            context,
            '무드는 최대 3개까지 선택할 수 있어요.',
            duration: const Duration(milliseconds: 1500),
          );
          return;
        }
        _selected.add(mood);
      }
    });
  }

  bool get _changed {
    final original = widget.quote.moods;
    if (original.length != _selected.length) return true;
    return !original.every(_selected.contains);
  }

  Future<void> _save() async {
    if (_saving || !_changed) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.ref
          .read(quoteRepositoryProvider)
          .setMoods(widget.quote.id, _selected);
      if (!mounted) return;
      navigator.pop(_selected);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBarOn(messenger, '무드를 바꾸지 못했어요. 다시 시도해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.s6,
          AppSpacing.s2,
          AppSpacing.s6,
          AppSpacing.s4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('무드 바꾸기', style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s1),
            Text(
              '최대 $_kMaxMoods개까지 선택할 수 있어요.',
              // 보조 텍스트: 라이트=primary500, 다크=primary400(onSurfaceSubtle 토큰)
              style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceSubtle),
            ),
            const SizedBox(height: AppSpacing.s4),
            MoodChips(selected: _selected, onToggle: _toggle),
            const SizedBox(height: AppSpacing.s6),
            FilledButton(
              onPressed: _saving || !_changed ? null : _save,
              style: FilledButton.styleFrom(
                // CTA: accentDefault 토큰
                backgroundColor: colors.accentDefault,
                foregroundColor: colors.accentOnAccent,
                // disabled 배경: border 토큰(primary200/primary600)으로 대체
                disabledBackgroundColor: colors.border,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }
}
