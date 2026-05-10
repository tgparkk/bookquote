// 책귀 — Auth 컨트롤러
//
// `signInWithOtp` (이메일 매직링크) 발송과 로그아웃을 한곳에서 다룬다.
// `AsyncValue<void>`로 진행 상태·에러를 표현하므로 화면에서 `when` 패턴으로
// 로딩 인디케이터·스낵바를 쉽게 띄울 수 있다.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_init.dart';

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // 초기 상태는 idle. 사용자 액션에서 state 변경.
  }

  /// 이메일 매직링크 발송. [redirectTo]는 Supabase Dashboard
  /// > Authentication > URL Configuration > Redirect URLs에 등록되어 있어야 한다.
  Future<void> sendMagicLink({
    required String email,
    required String redirectTo,
  }) async {
    if (!isSupabaseReady) {
      throw const AuthException('Supabase 환경이 설정되지 않았습니다.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.auth.signInWithOtp(
        email: email.trim(),
        emailRedirectTo: redirectTo,
        shouldCreateUser: true,
      );
    });
  }

  /// Kakao OAuth로 로그인. 웹에선 같은 창에서 Kakao 로그인 페이지로
  /// 리다이렉트되며, 인증 후 [redirectTo]로 돌아온다.
  ///
  /// scope 제한: 카카오 개인 앱은 비즈니스 인증 없이 `account_email`을
  /// 받을 수 없다. 명시적으로 nickname/image만 요청해야 KOE205를 피한다.
  Future<void> signInWithKakao({required String redirectTo}) async {
    if (!isSupabaseReady) {
      throw const AuthException('Supabase 환경이 설정되지 않았습니다.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.kakao,
        redirectTo: redirectTo,
        scopes: 'profile_nickname profile_image',
      );
    });
  }

  Future<void> signOut() async {
    if (!isSupabaseReady) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => supabase.auth.signOut());
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

/// 사용자에게 보여줄 한국어 에러 메시지로 변환한다.
String authErrorMessage(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('rate limit')) {
      return '메일을 너무 자주 요청했어요. 잠시 후 다시 시도해주세요.';
    }
    if (msg.contains('invalid email')) return '올바른 이메일 주소를 입력해주세요.';
    if (kDebugMode) return error.message;
  }
  return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
}
