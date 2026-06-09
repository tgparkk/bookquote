// FCM 푸시 서비스 (PR-PB).
//
// 로그인 후 [start]로 권한 요청 + 토큰 등록(register_device_token RPC) + 핸들러 연결.
// 로그아웃 시 [stop]으로 이 기기 토큰 삭제(다른 사람 알림 방지). 탭하면 메시지
// data.route로 라우팅(없으면 /notifications).
//
// 발송은 Edge Function(push-notification, PR-PC)이 notifications insert webhook으로
// 처리한다 — 여기선 수신·토큰 관리만.

import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_init.dart';

/// 백그라운드/종료 상태 메시지 핸들러 — 반드시 top-level + @pragma. notification
/// 페이로드는 OS가 트레이에 표시하므로 여기선 추가 작업 없음(향후 로컬 처리 훅).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // no-op: 트레이 표시는 OS가, 인앱 배지는 앱 기동 시 Realtime이 처리.
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  GoRouter? _router;
  bool _started = false;

  void attachRouter(GoRouter router) => _router = router;

  /// 로그인 상태에서 호출. 멱등(중복 호출 무해). 비로그인·웹·미초기화면 no-op.
  Future<void> start() async {
    if (_started || kIsWeb || !isSupabaseReady) return;
    if (supabase.auth.currentUser == null) return;
    _started = true;

    final messaging = FirebaseMessaging.instance;
    // Android 13+ 시스템 권한 다이얼로그. 거부해도 토큰 등록은 진행(추후 허용 대비).
    await messaging.requestPermission();

    await _registerCurrentToken();
    messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);
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
