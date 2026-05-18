// 내 프로필 설정 ListTile 묶음 (PR18-B).
//
// Me 화면 "설정" 섹션에 노출. 두 항목:
//  - [ProfilePublicToggleTile] — `profiles.is_library_public` 토글 + 현재 노출 상태
//    카피. 토글 OFF→ON 시 닉네임이 email local-part 의심 패턴이면 강제 확인
//    다이얼로그(본명/직장 이메일 노출 사고 방지, DECISIONS 2026-05-18 P0).
//  - [DisplayNameTile] — 현재 닉네임 + 편집 다이얼로그.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

// ─────────────────────────────────────────────────────────
// 토글 — 내 프로필 공개
// ─────────────────────────────────────────────────────────

class ProfilePublicToggleTile extends ConsumerStatefulWidget {
  const ProfilePublicToggleTile({super.key});

  @override
  ConsumerState<ProfilePublicToggleTile> createState() =>
      _ProfilePublicToggleTileState();
}

class _ProfilePublicToggleTileState
    extends ConsumerState<ProfilePublicToggleTile> {
  bool _busy = false;

  Future<void> _onChanged(bool value, Profile current) async {
    if (_busy) return;
    // OFF→ON: 닉네임 패턴 감지 → 강제 확인. ON→OFF는 즉시.
    if (value && looksLikeEmailLocalPart(current.displayName)) {
      final ok = await _confirmNicknamePattern(context, current.displayName);
      if (!ok || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateMine(isLibraryPublic: value);
      ref.invalidate(myProfileProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(content: Text('공개 설정 변경에 실패했어요.')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final profile = profileAsync.value;
    final isPublic = profile?.isLibraryPublic ?? false;
    final displayName = profile?.displayName ?? '';
    final subtitle = isPublic
        ? (displayName.isEmpty
            ? '현재 공개 — 닉네임 없음(설정 권장)'
            : '현재 공개 — "$displayName"로 검색됨')
        : '현재 비공개 — 검색에 표시 안 됨';
    return ListTile(
      leading: Icon(
        isPublic ? Icons.public : Icons.lock_outline,
        color: isPublic ? AppColors.accent500 : AppColors.primary500,
        size: 22,
      ),
      title: Text('내 프로필 공개', style: AppTextStyles.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary400),
      ),
      trailing: Switch.adaptive(
        value: isPublic,
        onChanged:
            _busy || profile == null ? null : (v) => _onChanged(v, profile),
        activeThumbColor: AppColors.accent500,
      ),
    );
  }
}

Future<bool> _confirmNicknamePattern(
  BuildContext context,
  String? displayName,
) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final textTheme = Theme.of(ctx).textTheme;
      return AlertDialog(
        title: const Text('닉네임 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${displayName ?? '(없음)'}" 닉네임이 친구 검색·서재 공개 시 그대로 노출돼요. '
              '이메일 이름이 그대로면 본명·직장 이메일이 노출될 수 있어요.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: AppColors.primary700),
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              '※ 먼저 닉네임을 바꾸시기를 권해요.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.semanticError,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('그대로 공개'),
          ),
        ],
      );
    },
  );
  return ok == true;
}

// ─────────────────────────────────────────────────────────
// 공개 닉네임 편집 ListTile + 다이얼로그
// ─────────────────────────────────────────────────────────

class DisplayNameTile extends ConsumerWidget {
  const DisplayNameTile({super.key});

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    String? current,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _DisplayNameEditDialog(initial: current ?? ''),
    );
    if (newName == null || newName.trim().isEmpty) return;
    final repo = ref.read(profileRepositoryProvider);
    try {
      await repo.updateMine(displayName: newName.trim());
      ref.invalidate(myProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('닉네임을 변경했어요.')),
          );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(content: Text('닉네임 변경에 실패했어요.')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final displayName = profileAsync.value?.displayName ?? '';
    return ListTile(
      leading: const Icon(
        Icons.badge_outlined,
        color: AppColors.primary500,
        size: 22,
      ),
      title: Text('공개 닉네임', style: AppTextStyles.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayName.isEmpty ? '미설정' : displayName,
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.primary400),
          ),
          const SizedBox(width: AppSpacing.s1),
          const Icon(
            Icons.chevron_right,
            color: AppColors.primary300,
            size: 20,
          ),
        ],
      ),
      onTap: () => _edit(context, ref, displayName),
    );
  }
}

class _DisplayNameEditDialog extends StatefulWidget {
  const _DisplayNameEditDialog({required this.initial});

  final String initial;

  @override
  State<_DisplayNameEditDialog> createState() => _DisplayNameEditDialogState();
}

class _DisplayNameEditDialogState extends State<_DisplayNameEditDialog> {
  late final TextEditingController _ctrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '닉네임을 입력해주세요.');
      return;
    }
    if (name.runes.length > 30) {
      setState(() => _error = '30자 이내로 입력해주세요.');
      return;
    }
    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('공개 닉네임 편집'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '친구 검색과 친구 프로필 헤더에 노출돼요. 본명·이메일은 피해주세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.primary700,
                  ),
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '닉네임 (30자 이내)',
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.s2),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.semanticError,
                    ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        FilledButton(onPressed: _submit, child: const Text('저장')),
      ],
    );
  }
}
