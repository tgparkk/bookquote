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

  /// 카카오 디벨로퍼스 네이티브 앱 키 (PR21). `KakaoSdk.init`에 그대로 전달.
  /// 발급: https://developers.kakao.com → 내 애플리케이션 → 앱 키 → 네이티브 앱 키.
  /// 빈 값이면 카카오 로그인 버튼은 disabled.
  static const String kakaoNativeAppKey =
      String.fromEnvironment('KAKAO_NATIVE_APP_KEY');

  /// Google OAuth 2.0 *웹* 클라이언트 ID (PR21). `signInWithIdToken`이 ID Token
  /// audience 검증에 사용하므로 *iOS/Android 클라이언트 ID가 아닌* 웹 클라이언트
  /// ID가 들어가야 한다. Supabase Dashboard → Auth → Providers → Google에
  /// 등록한 것과 동일한 값.
  /// 발급: Google Cloud Console → API & Services → Credentials → OAuth client ID
  /// (Web application). 빈 값이면 구글 로그인 버튼은 disabled.
  static const String googleWebClientId =
      String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');

  /// 누락된 키 목록 — 시작 시점 sanity check용.
  /// OAuth 키는 *옵션* (한쪽만 있어도 그쪽 버튼만 노출되도록) — 여기 안 포함.
  static List<String> missingKeys() => [
        if (aladinTtbKey.isEmpty) 'ALADIN_TTB_KEY',
        if (supabaseUrl.isEmpty) 'SUPABASE_URL',
        if (supabaseAnonKey.isEmpty) 'SUPABASE_ANON_KEY',
      ];

  /// OAuth 활성화 여부 — 각각 키 있을 때만 버튼 노출.
  static bool get isKakaoConfigured => kakaoNativeAppKey.isNotEmpty;
  static bool get isGoogleConfigured => googleWebClientId.isNotEmpty;
}
