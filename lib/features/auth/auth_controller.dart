// 책귀 — Auth 컨트롤러 (PR21 OAuth 전용)
//
// 매직링크는 V1에서 제거됨(Supabase 내장 SMTP의 team-only 제한 + 발신 도메인
// 없음). 대신 두 OAuth 흐름을 SDK 직접 통합으로 처리하고 Supabase에는 ID
// Token만 넘겨 세션을 받는다.
//
//   - Google: `google_sign_in`으로 ID Token + Access Token 받기
//             → `supabase.auth.signInWithIdToken(provider: google, ...)`
//   - Kakao : `kakao_flutter_sdk_user`로 OAuthToken 받기 (KakaoTalk 우선 →
//             카카오 계정 fallback). `signInWithIdToken(provider: kakao, ...)`
//             → 카카오 디벨로퍼스에서 "OpenID Connect 활성화" 토글 필수.
//
// SDK 통합으로 가는 이유: Supabase의 카카오 *서버 OAuth*는 `account_email`
// scope를 강제 요청하는데 비즈 앱 미인증 카카오는 그 scope를 거부 → KOE205.
// SDK 흐름은 클라이언트가 scope를 직접 통제하므로 nickname/profile_image만
// 받고 우회 가능.

import 'dart:async' show unawaited;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/analytics/app_analytics.dart';
import '../../core/config/env.dart';
import '../../core/supabase/supabase_init.dart';

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // 초기 상태는 idle. 사용자 액션에서 state 변경.
  }

  /// Google OAuth로 로그인. 사용자가 취소(`signIn()`이 null)하면 state는
  /// idle 데이터로 돌아가고 화면은 아무 안내도 띄우지 않는다.
  Future<void> signInWithGoogle() async {
    if (!isSupabaseReady) {
      throw const AuthException('Supabase 환경이 설정되지 않았습니다.');
    }
    if (!Env.isGoogleConfigured) {
      throw const AuthException('Google 로그인 키가 설정되지 않았습니다.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // `serverClientId`는 *웹* 클라이언트 ID — Supabase가 ID Token aud 검증에
      // 쓰는 값과 동일해야 한다. iOS/Android client ID가 들어가면 검증 실패.
      final google = GoogleSignIn(
        serverClientId: Env.googleWebClientId,
      );
      final account = await google.signIn();
      if (account == null) {
        // 사용자 취소. 에러로 표시하지 않음.
        return;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        throw const AuthException('Google ID Token을 받지 못했어요.');
      }
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );
      unawaited(appAnalytics.logLoginSuccess('google'));
    });
  }

  /// Kakao OAuth로 로그인. 카카오톡 설치 폰은 자동 호출, 미설치 폰은 카카오
  /// 계정 웹 로그인으로 fallback. 어느 쪽이든 ID Token을 받아 Supabase에 전달.
  Future<void> signInWithKakao() async {
    if (!isSupabaseReady) {
      throw const AuthException('Supabase 환경이 설정되지 않았습니다.');
    }
    if (!Env.isKakaoConfigured) {
      throw const AuthException('Kakao 로그인 키가 설정되지 않았습니다.');
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      kakao.OAuthToken token;
      // KakaoTalk이 설치돼 있고 정상 동작하면 우선 사용 — 사용자 친화 UX.
      // 카카오톡 측이 실패(취소·버전 낮음·계정 미연결 등)하면 카카오 계정 웹
      // 로그인으로 자연 fallback. 사용자가 거기서도 닫으면 그쪽 throw가 외곽
      // AsyncValue.guard로 흘러 idle 상태로 복귀.
      if (await kakao.isKakaoTalkInstalled()) {
        try {
          token = await kakao.UserApi.instance.loginWithKakaoTalk();
        } on Exception catch (e) {
          if (kDebugMode) debugPrint('[kakao] talk login failed → account: $e');
          token = await kakao.UserApi.instance.loginWithKakaoAccount();
        }
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      final idToken = token.idToken;
      if (idToken == null) {
        // OIDC 미활성화로 ID Token이 없는 경우. 카카오 디벨로퍼스 콘솔에서
        // "OpenID Connect 활성화"를 켜야 한다. 가이드 문서로 안내.
        throw const AuthException(
          'Kakao ID Token을 받지 못했어요. 디벨로퍼스에서 OpenID Connect를 활성화해 주세요.',
        );
      }
      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.kakao,
        idToken: idToken,
        accessToken: token.accessToken,
      );
      unawaited(appAnalytics.logLoginSuccess('kakao'));
    });
  }

  Future<void> signOut() async {
    if (!isSupabaseReady) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 각 SDK 측 토큰도 함께 무효화 — 다음 로그인 시 계정 선택 화면이 복귀.
      // SDK가 토큰 없는 상태에서 호출되면 PlatformException을 던지는데, 그건
      // 사용자에게 보일 에러가 아니므로 narrow하게 무시.
      await supabase.auth.signOut();
      try {
        await GoogleSignIn().signOut();
      } on PlatformException catch (_) {/* 토큰 없음 — best-effort */}
      try {
        await kakao.UserApi.instance.logout();
      } on PlatformException catch (_) {/* 토큰 없음 — best-effort */}
    });
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, void>(AuthController.new);

/// 사용자에게 보여줄 한국어 에러 메시지로 변환한다.
String authErrorMessage(Object error) {
  if (error is AuthException) {
    final msg = error.message.toLowerCase();
    if (msg.contains('id token')) {
      return '로그인 토큰을 받지 못했어요. 잠시 후 다시 시도해주세요.';
    }
    if (msg.contains('환경이 설정')) return error.message;
    if (msg.contains('키가 설정')) return error.message;
    if (msg.contains('openid connect')) return error.message;
    if (kDebugMode) return error.message;
  }
  if (error is PlatformException) {
    if (kDebugMode) return '${error.code}: ${error.message}';
  }
  return '문제가 발생했어요. 잠시 후 다시 시도해주세요.';
}
