// 잠금 비밀번호 관리 화면 (PR16-D).
//
// Me → "잠금 비밀번호" 진입. envelope 상태 + 캐시 상태에 따라 4분기:
//
//   ① envelope 없음                 → 미설정 안내 + [잠금 비밀번호 설정] (FirstLockDialog)
//   ② envelope 있음 + 캐시 있음      → 설정됨 안내 + [비밀번호 변경] (ChangePasswordDialog)
//   ③ envelope 있음 + 캐시 없음      → 다른 기기에서 설정됨 안내 + [잠금 해제] (UnlockDialog)
//   ④ 로딩/에러                     → CircularProgressIndicator 또는 _ErrorView
//
// QR 백업/import는 V1.0.1 후보(DECISIONS 2026-05-18 — PR16-D 범위 축소).
// 비밀번호 삭제(잠금 기능 끄기)도 V1.0.1로 미룸 — 잠금 인용구 평문화 batch 필요.
//
// 종이 백업 권장 카피: "비밀번호는 책귀 서버가 모릅니다. 잊으면 잠금 인용구를
// 영구히 못 봐요." — FirstLockDialog와 같은 톤으로 일관.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../data/envelope_repository.dart';
import '../domain/envelope.dart';
import '../state/crypto_providers.dart';
import 'lock_dialogs.dart';

/// envelope/캐시 상태를 묶은 화면 분기 키.
enum LockPasswordState {
  /// envelope 없음 — 잠금 비밀번호 미설정.
  notConfigured,

  /// envelope 있음 + 이 기기에 캐시 K도 있음 — 잠금 기능 정상 사용 중.
  configuredAndUnlocked,

  /// envelope 있음 + 캐시 없음 — 다른 기기에서 설정됨. 비밀번호로 해제 필요.
  configuredButLocked,
}

/// (envelope, cachedKey 여부) 동시 조회. 둘 다 비동기지만 같이 봐야 4분기가 결정됨.
class LockSnapshot {
  const LockSnapshot({required this.envelope, required this.hasCachedKey});
  final CryptoEnvelope? envelope;
  final bool hasCachedKey;

  LockPasswordState get state {
    if (envelope == null) return LockPasswordState.notConfigured;
    if (hasCachedKey) return LockPasswordState.configuredAndUnlocked;
    return LockPasswordState.configuredButLocked;
  }
}

final _lockSnapshotProvider = FutureProvider.autoDispose<LockSnapshot>((ref) async {
  final envelopeRepo = ref.watch(envelopeRepositoryProvider);
  final keyService = ref.watch(keyServiceProvider);
  final envelope = await envelopeRepo.getMine();
  final cached = await keyService.cachedMasterKey();
  return LockSnapshot(envelope: envelope, hasCachedKey: cached != null);
});

class LockPasswordScreen extends ConsumerWidget {
  const LockPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(_lockSnapshotProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('잠금 비밀번호')),
      body: SafeArea(
        child: snapshotAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorView(
            onRetry: () => ref.invalidate(_lockSnapshotProvider),
          ),
          data: (snap) => LockPasswordBody(snapshot: snap),
        ),
      ),
    );
  }
}

/// 화면 분기 본체 — testable. 호출자는 LockSnapshot을 직접 주입해 4상태를
/// 강제 렌더할 수 있다(PR16-E 위젯 회귀 가드).
class LockPasswordBody extends ConsumerWidget {
  const LockPasswordBody({super.key, required this.snapshot});

  final LockSnapshot snapshot;

  Future<void> _setupFirstTime(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const FirstLockDialog(),
    );
    if (ok == true) {
      ref.invalidate(_lockSnapshotProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('잠금 비밀번호를 설정했어요.')));
      }
    }
  }

  Future<void> _change(BuildContext context, WidgetRef ref) async {
    final envelope = snapshot.envelope;
    if (envelope == null) return;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangePasswordDialog(envelope: envelope),
    );
    if (ok == true) {
      ref.invalidate(_lockSnapshotProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('잠금 비밀번호를 변경했어요.')));
      }
    }
  }

  Future<void> _unlock(BuildContext context, WidgetRef ref) async {
    final envelope = snapshot.envelope;
    if (envelope == null) return;
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UnlockDialog(envelope: envelope),
    );
    if (ok == true) {
      ref.invalidate(_lockSnapshotProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('잠금을 해제했어요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      children: <Widget>[
        Icon(
          _stateIcon(snapshot.state),
          size: 56,
          color: snapshot.state == LockPasswordState.notConfigured
              ? AppColors.primary400
              : AppColors.accent500,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          _stateTitle(snapshot.state),
          style: textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          _stateBody(snapshot.state),
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.primary600),
        ),
        const SizedBox(height: AppSpacing.s6),
        _ActionButton(state: snapshot.state, onPressed: () {
          switch (snapshot.state) {
            case LockPasswordState.notConfigured:
              _setupFirstTime(context, ref);
            case LockPasswordState.configuredAndUnlocked:
              _change(context, ref);
            case LockPasswordState.configuredButLocked:
              _unlock(context, ref);
          }
        }),
        const SizedBox(height: AppSpacing.s8),
        // 종이 백업 권장 — FirstLockDialog와 같은 톤. 미설정 상태일 때도 미리 알림.
        Container(
          padding: const EdgeInsets.all(AppSpacing.s4),
          decoration: BoxDecoration(
            color: AppColors.semanticWarningLight,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.semanticWarning.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AppColors.semanticWarning,
                  ),
                  const SizedBox(width: AppSpacing.s2),
                  Text(
                    '비밀번호를 종이에 적어두세요',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.semanticWarning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                '비밀번호는 책귀 서버가 모릅니다. 잊으면 잠금 인용구를 영구히 못 봐요.',
                style: textTheme.bodySmall?.copyWith(color: AppColors.primary700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _stateIcon(LockPasswordState state) => switch (state) {
        LockPasswordState.notConfigured => Icons.lock_open_outlined,
        LockPasswordState.configuredAndUnlocked => Icons.lock_outline,
        LockPasswordState.configuredButLocked => Icons.lock_clock_outlined,
      };

  String _stateTitle(LockPasswordState state) => switch (state) {
        LockPasswordState.notConfigured => '잠금 비밀번호가 없어요',
        LockPasswordState.configuredAndUnlocked => '잠금 비밀번호가 설정됐어요',
        LockPasswordState.configuredButLocked => '이 기기에서 잠금 해제가 필요해요',
      };

  String _stateBody(LockPasswordState state) => switch (state) {
        LockPasswordState.notConfigured =>
          '인용구를 잠그면 본문이 암호화되어 저장돼요. 비밀번호 설정 후 입력 화면에서 잠금 토글을 켤 수 있어요.',
        LockPasswordState.configuredAndUnlocked =>
          '필요할 때 비밀번호를 변경할 수 있어요. 변경해도 기존 잠금 인용구는 그대로 읽혀요.',
        LockPasswordState.configuredButLocked =>
          '다른 기기에서 잠금 비밀번호를 설정했어요. 이 기기에서 잠금 인용구를 보려면 비밀번호로 해제해주세요.',
      };
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.state, required this.onPressed});

  final LockPasswordState state;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = switch (state) {
      LockPasswordState.notConfigured => '잠금 비밀번호 설정',
      LockPasswordState.configuredAndUnlocked => '비밀번호 변경',
      LockPasswordState.configuredButLocked => '잠금 해제',
    };
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent500,
        foregroundColor: AppColors.secondary50,
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(
          fontFamily: AppFonts.ui,
          fontWeight: FontWeight.w600,
          fontSize: AppFontSize.base,
        ),
      ),
      child: Text(label),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.primary400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '잠금 상태를 확인하지 못했어요',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s4),
            FilledButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
