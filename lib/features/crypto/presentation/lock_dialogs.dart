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
//
// [showPrivateShareWarningDialog] — PR16-C-2. 잠금 인용구를 카드로 만들어 공유하기
// 직전 "이미지에는 평문이 박힙니다" 경고. 사용자가 본문 보안과 카드 공유의 의미를
// 혼동하지 않도록 1회 명시 확인. true = 그래도 공유 / false = 취소.
//
// [ChangePasswordDialog] — PR16-D. 현재 비밀번호 검증(openEnvelope) → 새 비밀번호로
// rewrap → envelope_repository.updateWrap → cacheMasterKey. K는 그대로라
// 인용구 재암호화 0. 현재 비밀번호 오답이면 mac mismatch → "현재 비밀번호가 달라요".

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

// ─────────────────────────────────────────────────────────
// 잠금 인용구 공유 직전 평문 경고
// ─────────────────────────────────────────────────────────

/// 잠금 인용구를 카드 이미지로 공유하기 직전 1회 노출. 본문 보안과 이미지 공유의
/// 의미를 혼동하지 않게 — 카드 PNG에는 인용구가 평문으로 박힌다는 사실을 명시.
///
/// 반환 = true(그래도 공유) / false(취소). 사용자가 외부 영역 탭으로 닫으면
/// `barrierDismissible: false`라 동작하지 않고 명시 버튼만 받는다.
Future<bool> showPrivateShareWarningDialog(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      final textTheme = Theme.of(dialogCtx).textTheme;
      return AlertDialog(
        title: const Text('잠금 인용구 공유'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '본문은 잠겨 있지만, 카드 이미지에는 인용구가 평문으로 박혀요. '
              '이 이미지를 공유하면 받는 사람이 본문을 볼 수 있어요.',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.primary700),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '※ 카톡·인스타·갤러리 어디든 한 번 나가면 회수할 수 없어요.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.semanticError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('그래도 공유'),
          ),
        ],
      );
    },
  );
  return ok == true;
}

// ─────────────────────────────────────────────────────────
// 비밀번호 변경 — 현재 비밀번호 검증 후 rewrap (PR16-D)
// ─────────────────────────────────────────────────────────

class ChangePasswordDialog extends ConsumerStatefulWidget {
  const ChangePasswordDialog({super.key, required this.envelope});

  final CryptoEnvelope envelope;

  @override
  ConsumerState<ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<ChangePasswordDialog> {
  final _current = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPassword.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cur = _current.text;
    final np = _newPassword.text;
    final cf = _confirm.text;
    if (cur.isEmpty) {
      setState(() => _error = '현재 비밀번호를 입력해주세요.');
      return;
    }
    if (np.runes.length < _minPasswordLen) {
      setState(() => _error = '새 비밀번호는 $_minPasswordLen자 이상이어야 해요.');
      return;
    }
    if (np != cf) {
      setState(() => _error = '새 비밀번호가 서로 달라요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final keyService = ref.read(keyServiceProvider);
      final envelopeRepo = ref.read(envelopeRepositoryProvider);
      // 1. 현재 비밀번호로 envelope을 열어 K 추출(자기 자신 확인 + K 획득).
      //    SecretBoxAuthenticationError가 mac mismatch 시 throw.
      final masterKey = await keyService.openEnvelope(
        password: cur,
        envelope: widget.envelope,
      );
      // 2. K는 그대로 두고 새 비밀번호로 wrap만 갱신(인용구 재암호화 0).
      final rewrap = await keyService.rewrap(
        masterKey: masterKey,
        newPassword: np,
      );
      final newEnvelope = CryptoEnvelope(
        wrappedKey: rewrap.wrappedKey,
        wrapNonce: rewrap.wrapNonce,
        kdfSalt: rewrap.kdfSalt,
        kdfIters: widget.envelope.kdfIters,
        kdfVersion: widget.envelope.kdfVersion,
      );
      await envelopeRepo.updateWrap(newEnvelope);
      // 3. 캐시 K 재박음 — 같은 K지만 다른 기기에서 변경 흐름 진입했다면
      //    이 시점이 캐시 신규 생성 동선이기도 함.
      await keyService.cacheMasterKey(masterKey);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on SecretBoxAuthenticationError {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '현재 비밀번호가 달라요.';
      });
    } on EnvelopeRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.code == 'NOT_AUTHENTICATED'
            ? '로그인이 필요해요.'
            : '비밀번호 변경에 실패했어요.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '비밀번호 변경에 실패했어요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('잠금 비밀번호 변경'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '현재 비밀번호를 확인한 뒤 새 비밀번호로 바꿔요. '
              '기존 잠금 인용구는 그대로 읽을 수 있어요(재암호화 X).',
              style: textTheme.bodyMedium?.copyWith(color: AppColors.primary700),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: _current,
              enabled: !_busy,
              autofocus: true,
              obscureText: true,
              decoration: const InputDecoration(labelText: '현재 비밀번호'),
            ),
            const SizedBox(height: AppSpacing.s2),
            TextField(
              controller: _newPassword,
              enabled: !_busy,
              obscureText: true,
              decoration: InputDecoration(
                labelText: '새 비밀번호 ($_minPasswordLen자 이상)',
              ),
            ),
            const SizedBox(height: AppSpacing.s2),
            TextField(
              controller: _confirm,
              enabled: !_busy,
              obscureText: true,
              decoration: const InputDecoration(labelText: '새 비밀번호 확인'),
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
              : const Text('변경'),
        ),
      ],
    );
  }
}

