// 알림 데이터 레이어 (PR-NB).
//
// `my_notifications`·`unread_notification_count`·`mark_all_notifications_read` RPC
// 래핑 + 안읽음 카운트 Realtime 스트림. 적재/삭제는 DB 트리거(PR-NA)가 하므로 여기선
// 읽기·읽음처리만.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_init.dart';
import '../domain/app_notification.dart';

class NotificationRepositoryException implements Exception {
  NotificationRepositoryException(this.code, this.message);
  final String code;
  final String message;

  @override
  String toString() => 'NotificationRepositoryException($code): $message';
}

class NotificationRepository {
  NotificationRepository(this._client);

  final SupabaseClient _client;

  /// 알림함 목록(최신순). actor 비공개/차단은 RPC가 익명 처리.
  Future<List<AppNotification>> fetch({int limit = 30}) async {
    try {
      final rows = await _client.rpc(
        'my_notifications',
        params: {'p_limit': limit},
      ) as List<dynamic>;
      return rows
          .cast<Map<String, dynamic>>()
          .map(AppNotification.fromRow)
          .toList(growable: false);
    } on PostgrestException catch (e) {
      throw NotificationRepositoryException('FETCH_FAILED', e.message);
    }
  }

  /// 안읽음 개수(배지). 비로그인이면 0.
  Future<int> unreadCount() async {
    if (_client.auth.currentUser == null) return 0;
    try {
      final n = await _client.rpc('unread_notification_count');
      return (n as num?)?.toInt() ?? 0;
    } on PostgrestException catch (e) {
      throw NotificationRepositoryException('COUNT_FAILED', e.message);
    }
  }

  /// 안읽음 알림 전체를 읽음 처리(알림함 진입 시).
  Future<void> markAllRead() async {
    if (_client.auth.currentUser == null) return;
    try {
      await _client.rpc('mark_all_notifications_read');
    } on PostgrestException catch (e) {
      throw NotificationRepositoryException('MARK_READ_FAILED', e.message);
    }
  }

  /// 안읽음 카운트 라이브 스트림 — 초기값 1회 + notifications 변경마다 재집계.
  /// Realtime이 notifications SELECT RLS(recipient=본인)를 적용 + recipient_id eq
  /// 필터로 본인 행만 수신. 구독 취소 시 채널 정리.
  Stream<int> watchUnreadCount() {
    final controller = StreamController<int>();
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      controller.add(0);
      controller.close();
      return controller.stream;
    }

    Future<void> refresh() async {
      if (controller.isClosed) return;
      try {
        controller.add(await unreadCount());
      } catch (_) {
        // 일시적 실패는 무시 — 다음 이벤트/재진입 시 회복.
      }
    }

    final channel = _client.channel('notifications:$uid');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: uid,
          ),
          callback: (_) => refresh(),
        )
        .subscribe();

    refresh(); // 초기값

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };
    return controller.stream;
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(supabase);
});
