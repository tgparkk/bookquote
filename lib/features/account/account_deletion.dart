// 회원 탈퇴 플로우 — 2단계 확인 후 Edge Function `delete-account`로 계정 삭제.
//
// 1단계: 영구 삭제 경고 + Markdown 내보내기 권유 ([내보내고 탈퇴] / [계속] / [취소]).
// 2단계: "탈퇴합니다" 타이핑 확인 ([탈퇴] / [취소]).
// 확정 → dim 다이얼로그 + `supabase.functions.invoke('delete-account')` → `signOut`.
//   삭제 성공 시 라우터 가드가 `/auth/login`으로 보낸다 (auth.users 삭제 → quotes·user_books·
//   profiles cascade). 실패 시 세션 유지 + 재시도 안내(중간 상태 방지).
//
// 출시 블로커: Edge Function `delete-account`가 배포돼 있어야 한다 (미배포 시 invoke가 실패 →
// "탈퇴 처리에 실패했어요" 토스트). STAGES Stage 5 참고.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_init.dart';
import '../../core/theme/tokens.dart';
import '../me/data/quote_export.dart';

enum AccountDeletionResult { cancelled, deleted, failed }

enum _Step1Choice { exportFirst, continueDelete }

/// 회원 탈퇴 플로우 전체. 호출 화면이 `mounted`/`ref`를 넘겨준다.
Future<AccountDeletionResult> runAccountDeletionFlow({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final messenger = ScaffoldMessenger.of(context);

  // ── 1단계: 영구 삭제 경고 + 내보내기 권유 ─────────────────────────────
  final step1 = await showDialog<_Step1Choice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('회원 탈퇴'),
      content: const Text(
        '탈퇴하면 모은 인용구·서재·카드가 모두 삭제되고 되돌릴 수 없어요.\n'
        '먼저 Markdown으로 내보내 두는 걸 권해요.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _Step1Choice.exportFirst),
          child: const Text('내보내고 탈퇴'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _Step1Choice.continueDelete),
          child: Text('계속', style: TextStyle(color: AppColors.semanticError)),
        ),
      ],
    ),
  );
  if (step1 == null) return AccountDeletionResult.cancelled;

  if (step1 == _Step1Choice.exportFirst) {
    if (!context.mounted) return AccountDeletionResult.cancelled;
    await exportMyQuotesAsMarkdown(context: context, ref: ref);
    if (!context.mounted) return AccountDeletionResult.cancelled;
  }

  // ── 2단계: "탈퇴합니다" 타이핑 확인 ─────────────────────────────────
  if (!context.mounted) return AccountDeletionResult.cancelled;
  final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const _ConfirmTypeDialog(),
      ) ??
      false;
  if (!confirmed) return AccountDeletionResult.cancelled;

  // ── 처리 중 ──────────────────────────────────────────────────────
  if (!context.mounted) return AccountDeletionResult.cancelled;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _DeletingDialog(),
  );

  try {
    await supabase.functions.invoke('delete-account');
  } catch (_) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(); // dim 닫기
    }
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('탈퇴 처리에 실패했어요. 잠시 후 다시 시도해주세요.')),
      );
    return AccountDeletionResult.failed;
  }

  if (context.mounted) {
    Navigator.of(context, rootNavigator: true).pop(); // dim 닫기
  }
  await supabase.auth.signOut(); // 라우터 가드가 /auth/login으로
  messenger
    ..clearSnackBars()
    ..showSnackBar(const SnackBar(content: Text('탈퇴가 완료됐어요.')));
  return AccountDeletionResult.deleted;
}

/// "탈퇴합니다"를 정확히 입력해야 [탈퇴] 버튼이 활성화되는 확인 다이얼로그.
class _ConfirmTypeDialog extends StatefulWidget {
  const _ConfirmTypeDialog();

  @override
  State<_ConfirmTypeDialog> createState() => _ConfirmTypeDialogState();
}

class _ConfirmTypeDialogState extends State<_ConfirmTypeDialog> {
  static const _phrase = '탈퇴합니다';
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _ok => _controller.text.trim() == _phrase;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('정말 탈퇴할까요?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('확인을 위해 아래 칸에 "$_phrase"라고 입력해주세요.'),
          const SizedBox(height: AppSpacing.s3),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: _phrase),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _ok ? () => Navigator.pop(context, true) : null,
          child: Text(
            '탈퇴',
            style: TextStyle(
              color: _ok ? AppColors.semanticError : AppColors.primary300,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeletingDialog extends StatelessWidget {
  const _DeletingDialog();

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accent500,
              ),
            ),
            SizedBox(width: AppSpacing.s4),
            Text('탈퇴 처리 중…'),
          ],
        ),
      ),
    );
  }
}
