// 차단 목록 — `/me/blocked` (PR25).
//
// 내가 차단한 사용자 로스터. 각 항목 [차단 해제]. Google Play UGC 정책상 차단은
// 사용자가 되돌릴 수 있어야 한다. 진입: 내정보 "친구" 섹션 → "차단 목록" 타일.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../profile/domain/profile.dart';
import '../state/moderation_providers.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(blockedListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('차단 목록')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(blockedListProvider),
          child: async.when(
            loading: () => Center(
              // accentDefault: 로딩 스피너 — 다크/라이트 copper 액센트
              child: CircularProgressIndicator(color: context.colors.accentDefault),
            ),
            error: (_, _) => _ErrorView(
              onRetry: () => ref.invalidate(blockedListProvider),
            ),
            data: (profiles) => profiles.isEmpty
                ? const _EmptyView()
                : ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.s2),
                    itemCount: profiles.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => _BlockedTile(profile: profiles[i]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _BlockedTile extends ConsumerStatefulWidget {
  const _BlockedTile({required this.profile});

  final Profile profile;

  @override
  ConsumerState<_BlockedTile> createState() => _BlockedTileState();
}

class _BlockedTileState extends ConsumerState<_BlockedTile> {
  bool _busy = false;

  Future<void> _unblock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final name = widget.profile.displayName ?? '사용자';
    try {
      await ref
          .read(moderationRepositoryProvider)
          .unblock(widget.profile.id);
      ref.invalidate(blockedListProvider);
      messenger
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$name님 차단을 해제했어요.')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('차단 해제에 실패했어요. 잠시 후 다시 시도해주세요.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    final name = p.displayName ?? '(이름 없음)';
    final hasAvatar = p.avatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);
    return ListTile(
      leading: CircleAvatar(
        // accentContainer: 라이트 accent100(#FAEBD6) / 다크 accent900(#4A2D0E)
        backgroundColor: context.colors.accentContainer,
        backgroundImage: hasAvatar ? NetworkImage(p.avatarUrl!) : null,
        child: hasAvatar
            ? null
            : Text(
                initial,
                style: AppTextStyles.bodyMedium.copyWith(
                  // onSurface: 라이트 primary900 / 다크 secondary200 — 배경 위 기본 텍스트
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
      title: Text(name, style: AppTextStyles.bodyLarge),
      trailing: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : OutlinedButton(
              onPressed: _unblock,
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('차단 해제'),
            ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    // RefreshIndicator 아래라 스크롤 가능해야 pull 동작 — ListView로 감싼다.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s16,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      children: [
        // iconMuted: 라이트 primary400 / 다크 primary400 — 보조 아이콘
        Icon(Icons.block, size: 48, color: context.colors.iconMuted),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '차단한 사용자가 없어요',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '차단한 사용자는 여기서 다시 해제할 수 있어요.',
          textAlign: TextAlign.center,
          // onSurfaceMuted: 라이트 primary600 / 다크 secondary500 — 보조 텍스트
          style: AppTextStyles.bodyMedium.copyWith(color: context.colors.onSurfaceMuted),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.s8),
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        Text(
          '목록을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.s3),
        Center(
          child: OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ),
      ],
    );
  }
}
