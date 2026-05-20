// 책귀 — Supabase 인증 상태 Riverpod providers
//
// `authStreamProvider`는 Supabase auth 이벤트 raw Stream을 노출한다 — 라우터의
// `refreshListenable`처럼 Stream 자체가 필요한 컨슈머용.
// `authStateProvider`는 같은 스트림을 AsyncValue로 감싼 변종 — UI watch용.
// 환경 미초기화 빌드(테스트·`--dart-define-from-file` 누락)에선 빈 스트림.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_init.dart';

final authStreamProvider = Provider<Stream<AuthState>>((ref) {
  if (!isSupabaseReady) return const Stream.empty();
  return supabase.auth.onAuthStateChange;
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authStreamProvider);
});

/// 현재 세션. null이면 비로그인.
/// `authStateProvider`를 watch해서 이벤트마다 갱신된다.
final currentSessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider);
  if (!isSupabaseReady) return null;
  return supabase.auth.currentSession;
});

/// 현재 로그인 사용자 uid. 비로그인·환경 미초기화면 null.
/// 화면 코드가 `supabase.auth.currentUser`를 직접 읽지 않고 이 provider를
/// 거치게 해 인증 접근을 단일 지점으로 격리한다.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentSessionProvider)?.user.id;
});
