// 알림 상태 providers (PR-NB).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_repository.dart';
import '../domain/app_notification.dart';

/// 알림함 목록. 진입 시 watch, 읽음 처리·pull-to-refresh 후 invalidate.
final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  return ref.read(notificationRepositoryProvider).fetch();
});

/// 안읽음 카운트 — Realtime 라이브 스트림. 배지(하단 네비·앱바)가 watch.
/// 로딩/에러 시 0으로 폴백(배지 숨김)하도록 컨슈머가 `.value ?? 0` 사용.
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  return ref.read(notificationRepositoryProvider).watchUnreadCount();
});
