// FCM 푸시 서비스 (PR-PB, PR-PB.1 채널/포그라운드 보강).
//
// 로그인 후 [start]로 권한 요청 + 고중요도 알림 채널 생성 + 토큰 등록 + 핸들러 연결.
// - 백그라운드/종료: FCM `notification` 페이로드를 OS가 [_channel] 채널로 표시
//   (AndroidManifest의 default_notification_channel_id = _channel.id 와 일치해야 함).
//   삼성 One UI 등에서 채널이 명시돼야 헤드업/표시가 누락되지 않는다.
// - 포그라운드: onMessage → flutter_local_notifications로 직접 표시.
// 탭하면 메시지 data.route로 라우팅(없으면 /notifications).

import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_init.dart';

/// 백그라운드/종료 상태 메시지 핸들러 — 반드시 top-level + @pragma. notification
/// 페이로드는 OS가 트레이에 표시하므로 여기선 추가 작업 없음.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // no-op.
}

/// AndroidManifest의 default_notification_channel_id와 *반드시* 동일.
const _channel = AndroidNotificationChannel(
  'bookquote_high',
  '책글귀 알림',
  description: '좋아요·팔로우 등 활동 알림',
  importance: Importance.high,
);

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  GoRouter? _router;
  bool _started = false;
  bool _localReady = false;

  void attachRouter(GoRouter router) => _router = router;

  /// 로그인 상태에서 호출. 멱등(중복 호출 무해). 비로그인·웹·미초기화면 no-op.
  Future<void> start() async {
    if (_started || kIsWeb || !isSupabaseReady) return;
    if (supabase.auth.currentUser == null) return;
    _started = true;

    await _initLocal();

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(); // Android 13+ 시스템 권한 다이얼로그.

    await _registerCurrentToken();
    messaging.onTokenRefresh.listen(_saveToken);

    // 포그라운드: 직접 로컬 알림 표시(OS는 포그라운드 땐 트레이에 안 띄움).
    FirebaseMessaging.onMessage.listen(_showLocal);
    // 백그라운드에서 탭하고 들어온 경우 / 콜드스타트 탭.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);
  }

  Future<void> _initLocal() async {
    if (_localReady) return;
    await _local.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (resp) {
        final route = resp.payload;
        _router?.push(
          route != null && route.isNotEmpty ? route : '/notifications',
        );
      },
    );
    // 고중요도 채널 생성 — 백그라운드 FCM 알림도 이 채널로 표시되게(매니페스트 메타).
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    _localReady = true;
  }

  void _showLocal(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;
    _local.show(
      id: n.hashCode,
      title: n.title,
      body: n.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: message.data['route'] as String?,
    );
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _saveToken(token);
    } catch (_) {
      // APNs 미설정(iOS) 등 — 조용히 무시.
    }
  }

  Future<void> _saveToken(String token) async {
    try {
      await supabase.rpc('register_device_token', params: {
        'p_token': token,
        'p_platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (_) {
      // 일시적 실패 — onTokenRefresh/다음 start에서 재시도.
    }
  }

  void _handleTap(RemoteMessage message) {
    final route = message.data['route'];
    _router?.push(route is String && route.isNotEmpty ? route : '/notifications');
  }

  /// 로그아웃 시 — 이 기기 토큰 삭제. 다음 로그인 시 [start]가 재등록.
  Future<void> stop() async {
    _started = false;
    if (kIsWeb || !isSupabaseReady) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await supabase.from('device_tokens').delete().eq('token', token);
      }
    } catch (_) {
      // 무시 — 토큰 cascade(계정 삭제)나 다음 기기 정리로 회수.
    }
  }
}
