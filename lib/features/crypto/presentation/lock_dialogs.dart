// 잠금 비밀번호 모달 + 마스터키 준비 플로우 (PR16-C-1).
//
// [FirstLockDialog] — envelope이 없는 첫 잠금 토글 ON 시.
//   영구 손실 경고 + 비밀번호 6자 이상 + 확인 입력 + [취소]/[잠금 설정].
//   확인 시 KeyService.createEnvelope + EnvelopeRepository.insert + cacheMasterKey.
//
// [UnlockDialog] — envelope이 있는데 secure_storage에 캐시가 없는 다른 기기 케이스.
//   비밀번호 1개 입력 + [취소]/[잠금 해제]. KeyService.openEnvelope → cacheMasterKey.
//   비밀번호 오답이면 mac mismatch → "비밀번호가 달라요" 안내 + 입력 유지.
//
// [ensureMasterKeyReady] — caller 진입점. envelope/캐시 상태 보고 위 둘 중 하나
// 또는 즉시 true. 반환 = true(이제 잠금 인용구 만들 수 있음) / false(취소·실패).

import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../data/envelope_repository.dart';
import '../domain/envelope.dart';
import '../state/crypto_providers.dart';

const int _minPasswordLen = 6;

/// 잠금 인용구를 만들기 전 마스터키 K가 secure_storage 캐시에 준비됐는지 보장.
///
/// 분기:
/// 1. K 이미 캐시 → true (모달 없음, 정상 경로)
/// 2. envelope 없음 → [FirstLockDialog] (첫 잠금 — 비밀번호 새로 설정)
/// 3. envelope 있음 → [UnlockDialog] (다른 기기 — 비밀번호로 unwrap)
///
/// false = 사용자가 모달 취소 또는 envelope fetch 실패. caller는 토글을 ON으로
/// 끌어올리면 안 된다.
Future<bool> ensureMasterKeyReady(
  BuildContext context,
  WidgetRef ref,
) async {
  final keyService = ref.read(keyServiceProvider);
  if ((await keyService.cachedMasterKey()) != null) return true;

  final envelopeRepo = ref.read(envelopeRepositoryProvider);
  try {
    final envelope = await envelopeRepo.getMine();
    if (!context.mounted) return false;

    if (envelope == null) {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const FirstLockDialog(),
      );
      return ok == true;
    }

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UnlockDialog(envelope: envelope),
    );
    return ok == true;
  } on EnvelopeRepositoryException {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(content: Text('잠금 상태를 확인하지 못했어요. 잠시 후 다시 시도해주세요.')),
      );
    return false;
  }
}

// ─────────────────────────────────────────────────────────
// 첫 잠금 다이얼로그
// ─────────────────────────────────────────────────────────

class FirstLockDialog extends ConsumerStatefulWidget {
  const FirstLockDialog({super.key});

  @override
  ConsumerState<FirstLockDialog> createState() => _FirstLockDialogState();
}

class _FirstLockDialogState extends ConsumerState<FirstLockDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _password.text;
    final cf = _confirm.text;
    if (pw.runes.length < _minPasswordLen) {
      setState(() => _error = '비밀번호는 $_minPasswordLen자 이상이어야 해요.');
      return;
    }
    if (pw != cf) {
      setState(() => _error = '두 비밀번호가 달라요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final keyService = ref.read(keyServiceProvider);
      final envelopeRepo = ref.read(envelopeRepositoryProvider);
      final result = await keyService.createEnvelope(password: pw);
      await envelopeRepo.insert(result.envelope);
      await keyService.cacheMasterKey(result.masterKey);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on EnvelopeRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == 'NOT_AUTHENTICATED'
            ? '로그인이 필요해요.'
            : '잠금 설정에 실패했어요. 잠시 후 다시 시도해주세요.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '잠금 설정에 실패했어요. 잠시 후 다시 시도해주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('잠금 비밀번호 설정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '잠금 인용구는 본문이 암호화되어 저장돼요. '
              '비밀번호는 책귀 서버가 모릅니다 — 잊으면 잠금 인용구를 영구히 못 봐요.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.primary700),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '※ 종이에 적어두시기를 권해요.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.semanticError,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: _password,
              enabled: !_busy,
              autofocus: true,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '잠금 비밀번호 ($_minPasswordLen자 이상)',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.s2),
            TextField(
              controller: _confirm,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: '비밀번호 확인'),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                _error!,
                style: textTheme.bodySmall
                    ?.copyWith(color: AppColors.semanticError),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('잠금 설정'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// 다른 기기 — 비밀번호로 envelope 해제
// ─────────────────────────────────────────────────────────

class UnlockDialog extends ConsumerStatefulWidget {
  const UnlockDialog({super.key, required this.envelope});

  final CryptoEnvelope envelope;

  @override
  ConsumerState<UnlockDialog> createState() => _UnlockDialogState();
}

class _UnlockDialogState extends ConsumerState<UnlockDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pw = _password.text;
    if (pw.isEmpty) {
      setState(() => _error = '비밀번호를 입력해주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final keyService = ref.read(keyServiceProvider);
      final masterKey = await keyService.openEnvelope(
        password: pw,
        envelope: widget.envelope,
      );
      await keyService.cacheMasterKey(masterKey);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SecretBoxAuthenticationError {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '비밀번호가 달라요.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '잠금 해제에 실패했어요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('잠금 비밀번호'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '이 기기에서 잠금 인용구를 처음 다뤄요. '
            '다른 기기에서 설정한 잠금 비밀번호를 입력해주세요.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.primary700),
          ),
          const SizedBox(height: AppSpacing.s4),
          TextField(
            controller: _password,
            enabled: !_busy,
            autofocus: true,
            obscureText: true,
            decoration: const InputDecoration(labelText: '잠금 비밀번호'),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.s2),
            Text(
              _error!,
              style: textTheme.bodySmall
                  ?.copyWith(color: AppColors.semanticError),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('잠금 해제'),
        ),
      ],
    );
  }
}

