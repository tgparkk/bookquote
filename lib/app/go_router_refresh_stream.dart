// `GoRouter.refreshListenable`에 Stream을 어댑팅하는 표준 cookbook 패턴.
// auth state stream의 어떤 이벤트든 들어오면 `notifyListeners()`를 호출해
// `redirect`가 재평가되도록 한다.
//
// 출처: go_router 공식 example의 `GoRouterRefreshStream` 클래스.

import 'dart:async';

import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
