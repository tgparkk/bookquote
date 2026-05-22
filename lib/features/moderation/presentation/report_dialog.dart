// 신고 다이얼로그 — 사용자/인용구 신고 (PR25, Google Play UGC 정책).
//
// showReportDialog(context, reportedUserId|reportedQuoteId, targetLabel)로 호출.
// 사유 선택(필수) + 자세한 내용(선택) → moderation_repository.report.
// 접수되면 SnackBar "신고가 접수됐어요" 후 true 반환, 취소·실패면 false.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../data/moderation_repository.dart';

/// 신고 사유. [code]는 DB `reports.reason`에 저장, [label]은 UI 노출.
enum ReportReason {
  sexual('sexual', '음란물·선정적 콘텐츠'),
  violence('violence', '폭력적·혐오스러운 콘텐츠'),
  hate('hate', '혐오 발언·괴롭힘'),
  spam('spam', '스팸·광고·도배'),
  other('other', '기타');

  const ReportReason(this.code, this.label);
  final String code;
  final String label;
}

/// 신고 다이얼로그를 띄운다. [reportedUserId]·[reportedQuoteId] 중 하나는 필수.
/// 신고가 접수되면 true, 취소·실패면 false.
Future<bool> showReportDialog(
  BuildContext context, {
  String? reportedUserId,
  String? reportedQuoteId,
  required String targetLabel,
}) async {
  assert(
    reportedUserId != null || reportedQuoteId != null,
    'reportedUserId 또는 reportedQuoteId 중 하나는 필요',
  );
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(
      reportedUserId: reportedUserId,
      reportedQuoteId: reportedQuoteId,
      targetLabel: targetLabel,
    ),
  );
  return result ?? false;
}

class _ReportDialog extends ConsumerStatefulWidget {
  const _ReportDialog({
    this.reportedUserId,
    this.reportedQuoteId,
    required this.targetLabel,
  });

  final String? reportedUserId;
  final String? reportedQuoteId;
  final String targetLabel;

  @override
  ConsumerState<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends ConsumerState<_ReportDialog> {
  ReportReason? _reason;
  final _detailController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(moderationRepositoryProvider).report(
            reportedUserId: widget.reportedUserId,
            reportedQuoteId: widget.reportedQuoteId,
            reason: reason.code,
            detail: _detailController.text,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('신고가 접수됐어요. 검토 후 조치할게요.')),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = '신고를 접수하지 못했어요. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('신고하기'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.targetLabel,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.primary400),
            ),
            const SizedBox(height: 2),
            Text(
              '어떤 점이 문제인지 알려주세요.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.s2),
            for (final r in ReportReason.values)
              InkWell(
                onTap: _submitting ? null : () => setState(() => _reason = r),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s1),
                  child: Row(
                    children: [
                      Icon(
                        _reason == r
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: _reason == r
                            ? AppColors.accent500
                            : AppColors.primary300,
                      ),
                      const SizedBox(width: AppSpacing.s2),
                      Expanded(
                        child: Text(r.label, style: AppTextStyles.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.s2),
            TextField(
              controller: _detailController,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText: '자세한 내용 (선택)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.semanticError),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _submitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: (_reason == null || _submitting) ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.semanticError,
            foregroundColor: Colors.white,
          ),
          child: _submitting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('신고'),
        ),
      ],
    );
  }
}
