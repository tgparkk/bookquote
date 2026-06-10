// 알림 설정 화면 (PR-PB.2) — `/me/notifications`.
//
// profiles.push_* 토글(마스터 + 타입별)을 제어한다. Edge Function(push-notification)이
// 발송 전 이 값을 보고 skip. 마스터 OFF면 타입별 토글은 비활성. OS 알림 권한이 1차
// 게이트라 안내 카피 한 줄 노출(기기 설정으로 유도).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_snackbar.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _busy = false;

  Future<void> _update(Future<void> Function(ProfileRepository) op) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await op(ref.read(profileRepositoryProvider));
      ref.invalidate(myProfileProvider);
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, '설정 변경에 실패했어요.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(title: const Text('알림 설정')),
      body: SafeArea(
        child: profileAsync.when(
          loading: () => Center(
            child: CircularProgressIndicator(color: colors.accentDefault),
          ),
          error: (_, _) => _ErrorView(
            onRetry: () => ref.invalidate(myProfileProvider),
          ),
          data: (profile) =>
              profile == null ? _buildLoggedOut() : _buildBody(profile),
        ),
      ),
    );
  }

  Widget _buildLoggedOut() => const Center(child: Text('로그인이 필요해요.'));

  Widget _buildBody(Profile profile) {
    final colors = context.colors;
    final master = profile.pushEnabled;
    final typeEnabled = master && !_busy;

    return ListView(
      children: [
        const SizedBox(height: AppSpacing.s2),
        SwitchListTile.adaptive(
          value: master,
          onChanged: _busy
              ? null
              : (v) => _update((r) => r.updateMine(pushEnabled: v)),
          activeThumbColor: colors.accentDefault,
          secondary: Icon(
            master ? Icons.notifications_active : Icons.notifications_off,
            color: master ? colors.accentDefault : colors.iconPrimary,
            size: 22,
          ),
          title: Text('푸시 알림', style: AppTextStyles.bodyLarge),
          subtitle: Text(
            master ? '좋아요·팔로우 알림을 받아요' : '모든 푸시 알림이 꺼져 있어요',
            style:
                AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceSubtle),
          ),
        ),
        const Divider(height: 1),
        _TypeTile(
          title: '인용구 좋아요',
          subtitle: '내 인용구에 좋아요가 달리면',
          value: profile.pushQuoteLike,
          enabled: typeEnabled,
          onChanged: (v) => _update((r) => r.updateMine(pushQuoteLike: v)),
        ),
        _TypeTile(
          title: '후기 좋아요',
          subtitle: '내 후기에 좋아요가 달리면',
          value: profile.pushReviewLike,
          enabled: typeEnabled,
          onChanged: (v) => _update((r) => r.updateMine(pushReviewLike: v)),
        ),
        _TypeTile(
          title: '팔로우',
          subtitle: '누군가 나를 팔로우하면',
          value: profile.pushFollow,
          enabled: typeEnabled,
          onChanged: (v) => _update((r) => r.updateMine(pushFollow: v)),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            '기기의 알림 권한이 꺼져 있으면 위 설정과 무관하게 푸시가 오지 않아요. '
            '설정 → 앱 → 책글귀 → 알림에서 확인하세요.',
            style:
                AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceSubtle),
          ),
        ),
      ],
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SwitchListTile.adaptive(
      // 마스터 OFF면 시각적으로도 꺼진 상태로 보이게 value를 false 처리.
      value: value && enabled,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: colors.accentDefault,
      title: Text(title, style: AppTextStyles.bodyLarge),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceSubtle),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('설정을 불러오지 못했어요.', style: AppTextStyles.bodyMedium),
          const SizedBox(height: AppSpacing.s3),
          OutlinedButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
