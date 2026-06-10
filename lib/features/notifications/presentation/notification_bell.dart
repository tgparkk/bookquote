// 알림 벨 + 안읽음 배지 (PR-NB). 활동 탭 AppBar 액션.
//
// 안읽음 카운트는 Realtime 스트림(unreadNotificationCountProvider)을 watch —
// 좋아요/팔로우가 들어오면 배지가 라이브로 갱신. 탭하면 알림함(/notifications).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/notification_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificationCountProvider).value ?? 0;
    return IconButton(
      tooltip: '알림',
      onPressed: () => context.push('/notifications'),
      icon: Badge.count(
        count: count,
        isLabelVisible: count > 0,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
