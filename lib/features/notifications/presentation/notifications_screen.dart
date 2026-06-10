// 알림함 화면 (PR-NB) — `/notifications`.
//
// 진입 시 전체 읽음 처리(배지는 Realtime UPDATE 이벤트로 자동 0). 목록은 이번
// 세션 동안 안읽음 하이라이트를 유지해 "새로 온 것"을 보여준다. 탭하면 대상으로
// 이동(좋아요→책 상세, 팔로우→작성자 프로필).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/tokens.dart';
import '../data/notification_repository.dart';
import '../domain/app_notification.dart';
import '../state/notification_providers.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // 첫 프레임 후 전체 읽음 처리(목록 하이라이트는 유지 — 재진입 시 읽음 반영).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationRepositoryProvider).markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('알림')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(notificationsProvider),
          child: async.when(
            loading: () => Center(
              child: CircularProgressIndicator(
                color: context.colors.accentDefault,
              ),
            ),
            error: (_, _) => _ErrorView(
              onRetry: () => ref.invalidate(notificationsProvider),
            ),
            data: (items) => items.isEmpty
                ? const _EmptyView()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s2,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: context.colors.border,
                    ),
                    itemBuilder: (_, i) => _NotificationTile(item: items[i]),
                  ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item});
  final AppNotification item;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = item.actorDisplayName ?? '누군가';
    final hasAvatar = item.actorAvatarUrl?.isNotEmpty ?? false;
    final initial = name.isEmpty ? '?' : String.fromCharCode(name.runes.first);

    return Material(
      // 안읽음은 옅은 accent 배경으로 강조.
      color: item.isRead ? colors.surface : colors.accentContainer,
      child: InkWell(
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s4,
            vertical: AppSpacing.s3,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: colors.accentBorder,
                backgroundImage:
                    hasAvatar ? NetworkImage(item.actorAvatarUrl!) : null,
                child: hasAvatar
                    ? null
                    : Text(
                        initial,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _message(name),
                      style: TextStyle(
                        fontFamily: AppFonts.ui,
                        fontSize: AppFontSize.sm,
                        fontWeight:
                            item.isRead ? FontWeight.w500 : FontWeight.w700,
                        color: colors.onSurface,
                        height: 1.35,
                      ),
                    ),
                    if (item.preview != null && item.preview!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.preview!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppFonts.quote,
                          fontSize: AppFontSize.xs,
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      _relativeTime(item.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.onSurfaceSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _message(String name) => switch (item.type) {
        NotificationType.quoteLike => '$name님이 회원님의 인용구를 좋아해요',
        NotificationType.reviewLike => '$name님이 회원님의 후기를 좋아해요',
        NotificationType.follow => '$name님이 회원님을 팔로우했어요',
        NotificationType.unknown => '$name님의 새 알림',
      };

  void _onTap(BuildContext context) {
    switch (item.type) {
      case NotificationType.quoteLike:
      case NotificationType.reviewLike:
        if (item.targetBookId != null) {
          context.push('/book/${item.targetBookId}');
        }
      case NotificationType.follow:
        context.push('/u/${item.actorId}');
      case NotificationType.unknown:
        break;
    }
  }
}

String _relativeTime(DateTime t) {
  final now = DateTime.now();
  final d = now.difference(t.toLocal());
  if (d.inMinutes < 1) return '방금';
  if (d.inMinutes < 60) return '${d.inMinutes}분 전';
  if (d.inHours < 24) return '${d.inHours}시간 전';
  if (d.inDays < 7) return '${d.inDays}일 전';
  final local = t.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '$y.$m.$day';
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s6,
        AppSpacing.s16,
        AppSpacing.s6,
        AppSpacing.s8,
      ),
      children: [
        Icon(
          Icons.notifications_none_rounded,
          size: 48,
          color: colors.onSurfaceSubtle,
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '아직 알림이 없어요',
          textAlign: TextAlign.center,
          style: AppTextStyles.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          '친구가 회원님의 인용구·후기를 좋아하거나 팔로우하면 여기에 모여요.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceMuted),
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
          '알림을 불러오지 못했어요. 잠시 후 다시 시도해주세요.',
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
