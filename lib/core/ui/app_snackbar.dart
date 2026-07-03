import 'package:flutter/material.dart';

/// 앱 전역 스낵바 헬퍼.
///
/// 지배적 관용구 `messenger..clearSnackBars()..showSnackBar(SnackBar(...))`를
/// 캡슐화한다. 연속 액션 시 스낵바가 줄줄이 쌓이지 않도록 기본으로 이전
/// 스낵바를 지운다 — 쌓임이 필요한 자리만 [clearPrevious]를 끈다.
void showAppSnackBar(
  BuildContext context,
  String message, {
  SnackBarAction? action,
  Duration? duration,
  bool clearPrevious = true,
}) {
  showAppSnackBarOn(
    ScaffoldMessenger.of(context),
    message,
    action: action,
    duration: duration,
    clearPrevious: clearPrevious,
  );
}

/// async gap 이전에 캡처해 둔 [ScaffoldMessengerState]로 표시할 때 사용.
void showAppSnackBarOn(
  ScaffoldMessengerState messenger,
  String message, {
  SnackBarAction? action,
  Duration? duration,
  bool clearPrevious = true,
}) {
  if (clearPrevious) messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      action: action,
      // SnackBar 기본값(4초)과 동일 — duration 미지정 시 기존 동작 유지.
      duration: duration ?? const Duration(milliseconds: 4000),
    ),
  );
}
