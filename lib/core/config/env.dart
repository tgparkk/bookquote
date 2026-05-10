// 책귀 — 환경 변수
//
// 빌드 시점에 `--dart-define-from-file=.env.json`으로 주입되는 값들을
// 컴파일 타임 상수(`String.fromEnvironment`)로 노출한다.
//
// 실행 예:
//   flutter run --dart-define-from-file=.env.json
//   flutter build apk --dart-define-from-file=.env.json
//
// 키는 `.env.json` (gitignored)에 저장한다. 템플릿은 `.env.json.example`.
//
// 주의: 컴파일된 바이너리에 키 값이 포함된다. 실서비스에서는 클라이언트에서
// 직접 외부 API를 호출하지 말고 Supabase Edge Function 등 백엔드 프록시로
// 옮길 것 (Stage 4 이후 과제).

abstract final class Env {
  /// 알라딘 TTB OpenAPI 인증키.
  /// 발급: https://www.aladin.co.kr/ttb/wblog_manage.aspx
  /// 한도: 5,000건/일.
  static const String aladinTtbKey = String.fromEnvironment('ALADIN_TTB_KEY');

  /// Supabase 프로젝트 URL.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase 클라이언트 키 — 구식 anon JWT (`eyJ...`) 또는 신식 publishable
  /// (`sb_publishable_...`) 양쪽 다 SDK의 `anonKey:` 자리에 그대로 들어간다.
  /// RLS 정책으로 보호되는 전제.
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// 누락된 키 목록 — 시작 시점 sanity check용.
  static List<String> missingKeys() => [
        if (aladinTtbKey.isEmpty) 'ALADIN_TTB_KEY',
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
      ];
}
