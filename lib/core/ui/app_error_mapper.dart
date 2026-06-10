import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// 예외 → 사용자 노출 문구 공통 매핑.
///
/// 기존 화면의 문구는 건드리지 않는다 — 새 코드와 명백한 중복 자리부터
/// 점진 적용 (전면 치환은 UX 변화라 별도 PR).
/// 인증 흐름 전용 문구는 auth_controller.dart의 [authErrorMessage]가 담당.
String userMessageFor(Object error) {
  if (error is AuthException) {
    return '로그인이 필요해요. 다시 로그인해주세요.';
  }
  if (error is PostgrestException) {
    return '서버와 통신하지 못했어요. 잠시 후 다시 시도해주세요.';
  }
  if (error is SocketException) {
    return '네트워크 연결을 확인해주세요.';
  }
  if (error is TimeoutException) {
    return '응답이 늦어지고 있어요. 잠시 후 다시 시도해주세요.';
  }
  return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
}
