// 책귀 — Supabase 초기화
//
// `main()`에서 한 번 호출. 키가 비어 있으면 초기화를 건너뛰고 false를 반환해
// 테스트나 키 미주입 빌드에서도 앱이 부팅되게 한다.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Supabase가 초기화되었는지 여부.
///
/// `false`면 인증·DB·Storage 호출을 시도하지 않아야 한다 — Auth gate, splash,
/// 책 검색 화면 등에서 이 값을 보고 환경 미설정 안내를 보여줄 수 있다.
bool get isSupabaseReady => _ready;
bool _ready = false;

/// Supabase를 초기화한다. 환경 키 누락 시 디버그 로그만 남기고 통과.
/// 반환값: 실제로 초기화에 성공했는지.
Future<bool> initSupabase() async {
  final missing = Env.missingKeys();
  if (missing.contains('SUPABASE_URL') ||
      missing.contains('SUPABASE_ANON_KEY')) {
    if (kDebugMode) {
      debugPrint(
        '⚠️ Supabase env 누락: ${missing.join(", ")}. '
        '`flutter run --dart-define-from-file=.env.json`로 실행하세요.',
      );
    }
    return false;
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );
  _ready = true;
  return true;
}

/// 초기화된 Supabase 클라이언트. `isSupabaseReady`가 false면 호출 금지.
SupabaseClient get supabase => Supabase.instance.client;
