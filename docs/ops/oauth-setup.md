# OAuth 설정 가이드 (PR21)

V1 로그인은 **구글 + 카카오** 두 OAuth로만 동작합니다. 매직링크는 V1에서 제거됨. 이 문서는 본인이 콘솔에서 직접 처리할 단계 모두를 정리합니다.

> 한 번만 끝내면 됩니다. 키들은 `.env.json`(gitignored) + `android/local.properties`(gitignored)에 박는 구조라 코드 푸시 후 본인 환경에서만 살아 있어요.

---

## 0. 사전 준비

- 구글 계정 1개(콘솔용)
- 카카오 계정 1개
- Supabase 프로젝트 대시보드 접근 권한
- Windows PowerShell + JDK(keytool)

다음 두 정보를 메모해 두세요 — 두 콘솔 모두에서 묻습니다.

| 항목 | 값 |
|---|---|
| Android 패키지명 | `io.github.tgparkk.bookquote` |
| iOS Bundle ID | `io.github.tgparkk.bookquote` |

---

## 1. Android 키해시·SHA-1 추출 (PowerShell)

두 콘솔 모두 *앱 서명 키*의 지문을 등록해야 합니다. 디버그 키 1개 + 릴리즈 키 1개.

### Debug 키 (개발 중)

```powershell
# SHA-1 (구글 콘솔용)
keytool -list -v -alias androiddebugkey `
  -keystore "$env:USERPROFILE\.android\debug.keystore" `
  -storepass android -keypass android | Select-String "SHA1:"

# 카카오 키해시 (Base64, 카카오 디벨로퍼스용)
$debugStorePath = "$env:USERPROFILE\.android\debug.keystore"
keytool -exportcert -alias androiddebugkey -keystore $debugStorePath `
  -storepass android -keypass android `
  | & "C:\Program Files\Git\usr\bin\openssl.exe" sha1 -binary `
  | & "C:\Program Files\Git\usr\bin\openssl.exe" base64
```

> Git Bash가 다른 위치라면 `openssl.exe` 경로를 본인 환경에 맞게 조정. WSL이면 `wsl sha1sum | base64`로도 가능.

### Release 키 (스토어 배포용)

`android/app/build.gradle.kts`의 `signingConfigs`가 아직 debug라면(현재 상태) release SHA-1은 debug와 동일. 추후 별도 keystore 만들면 같은 명령어에서 `alias`·`keystore`·암호만 교체.

---

## 2. Google Cloud Console

### 2-1. 프로젝트 생성

1. https://console.cloud.google.com 진입
2. 좌측 상단 프로젝트 드롭다운 → **새 프로젝트** → 이름 `bookquote` → 만들기

### 2-2. OAuth 동의 화면

좌측 메뉴 **API 및 서비스 → OAuth 동의 화면**

- User Type: **외부** (테스트 사용자에게만 노출되는 동안 무료)
- 앱 이름: 책귀
- 사용자 지원 이메일: 본인 Gmail
- 앱 로고: 선택(나중에)
- 애플리케이션 홈페이지: `https://tgparkk.github.io/bookquote/`
- 개인정보처리방침 URL: `https://tgparkk.github.io/bookquote/privacy/`
- 서비스 약관 URL: `https://tgparkk.github.io/bookquote/terms/`
- 승인된 도메인: `github.io` 추가
- 개발자 연락처: 본인 Gmail
- **저장 후 계속** → 범위는 *기본만* (email, profile, openid)
- 테스트 사용자: 본인 이메일 + 베타테스터 이메일들 추가

### 2-3. OAuth 클라이언트 ID 3개 발급

**API 및 서비스 → 사용자 인증 정보 → 사용자 인증 정보 만들기 → OAuth 클라이언트 ID**

#### (a) 웹 애플리케이션 ← **이 값을 .env.json + Supabase에 박음**

- 애플리케이션 유형: **웹 애플리케이션**
- 이름: `bookquote-web`
- 승인된 리디렉션 URI: `https://<프로젝트>.supabase.co/auth/v1/callback` (Supabase Dashboard → Auth → Providers → Google 페이지 상단에 적혀 있음)

발급 후 표시되는 **클라이언트 ID**(끝이 `.apps.googleusercontent.com`)와 **클라이언트 보안 비밀번호**를 둘 다 복사.

#### (b) Android

- 애플리케이션 유형: **Android**
- 이름: `bookquote-android`
- 패키지 이름: `io.github.tgparkk.bookquote`
- SHA-1 인증서 디지털 지문: 1-Debug에서 추출한 SHA-1

#### (c) iOS

- 애플리케이션 유형: **iOS**
- 이름: `bookquote-ios`
- 번들 ID: `io.github.tgparkk.bookquote`

### 2-4. Supabase Dashboard에 등록

**Supabase Dashboard → Authentication → Providers → Google**

- Enable Sign in with Google: **ON**
- Client ID (for OAuth): 2-3 (a)의 *클라이언트 ID*
- Client Secret: 2-3 (a)의 *클라이언트 보안 비밀번호*
- **Save**

> Authorized Client IDs는 비워둬도 됨(우리는 `signInWithIdToken` 방식이고 audience 검증을 위 Client ID가 처리).

---

## 3. Kakao Developers

### 3-1. 앱 생성

1. https://developers.kakao.com 진입 → 로그인
2. **내 애플리케이션 → 애플리케이션 추가하기**
3. 앱 이름: 책귀 / 회사명: 본인 / 카테고리: 라이프스타일 또는 도서

### 3-2. 앱 키 확인

좌측 **앱 설정 → 앱 키**

- **네이티브 앱 키** ← 이 값을 `.env.json` + `local.properties`에 박음

### 3-3. 플랫폼 등록

좌측 **앱 설정 → 플랫폼**

#### Android
- 패키지명: `io.github.tgparkk.bookquote`
- 키해시: 1-Debug에서 추출한 Base64 해시 ← **여러 줄로 debug + release 둘 다 등록 가능**
- 마켓 URL: 비워둠(출시 후 채움)

#### iOS
- 번들 ID: `io.github.tgparkk.bookquote`

### 3-4. 카카오 로그인 활성화

좌측 **제품 설정 → 카카오 로그인**

- 활성화 설정: **ON**
- **OpenID Connect 활성화: ON** ← 이게 켜져 있어야 `signInWithIdToken`이 작동. 안 켜면 idToken이 null로 와서 앱에서 즉시 에러.
- Redirect URI: 비워둠(SDK 방식이라 불필요)

### 3-5. 동의항목 설정

좌측 **제품 설정 → 카카오 로그인 → 동의항목**

- 닉네임 (profile_nickname): **필수 동의**
- 프로필 사진 (profile_image): **선택 동의**
- **카카오계정(이메일)은 설정하지 않음** ← 비즈 앱 미인증 상태에서 이 동의가 필수면 KOE205. 그래서 일부러 뺍니다.

---

## 4. 키 박기

콘솔에서 받은 값들을 본인 로컬 환경에만 박습니다. 둘 다 gitignored.

### 4-1. `.env.json` (Dart 측)

프로젝트 루트의 `.env.json`을 열어 키 추가:

```json
{
  "SUPABASE_URL": "https://<프로젝트>.supabase.co",
  "SUPABASE_ANON_KEY": "...기존...",
  "ALADIN_TTB_KEY": "...기존...",
  "GOOGLE_WEB_CLIENT_ID": "1234567890-abc.apps.googleusercontent.com",
  "KAKAO_NATIVE_APP_KEY": "abcdef1234567890..."
}
```

### 4-2. `android/local.properties` (AndroidManifest placeholder)

같은 카카오 네이티브 앱 키를 Gradle 빌드에도 박아줘야 합니다(AndroidManifest의 `kakao{KEY}://oauth` scheme 주입용):

```properties
sdk.dir=...기존...
flutter.sdk=...기존...
kakao.nativeAppKey=abcdef1234567890...
```

### 4-3. `ios/Runner/Info.plist` (수동 치환)

`Info.plist`의 `kakaoKAKAO_NATIVE_APP_KEY` 문자열을 본인 키로 치환:

```xml
<!-- 수정 전 -->
<string>kakaoKAKAO_NATIVE_APP_KEY</string>

<!-- 수정 후 (예시) -->
<string>kakaoabcdef1234567890</string>
```

> `Info.plist`는 *gitignored가 아닙니다*. 키를 박은 채로 커밋하지 마세요. 본인 빌드 직전에만 치환, 커밋 전엔 `git checkout ios/Runner/Info.plist`로 되돌리거나 별도 빌드 시점에 sed로 처리하는 방식 권장. (V1.0.1에 .xcconfig + 환경 변수 주입 방식으로 정리 예정.)

---

## 5. 빌드 + 검증

```powershell
flutter pub get
flutter run --dart-define-from-file=.env.json
```

성공 시나리오 체크리스트:
- [ ] 로그인 화면에 `구글로 시작` + `카카오로 시작` 두 버튼 모두 *enabled* 상태
- [ ] 구글 버튼 탭 → 계정 선택 시트 → 선택 → 자동 홈 진입
- [ ] 카카오 버튼 탭(카카오톡 설치 폰) → 카카오톡 인증 → 자동 홈 진입
- [ ] 카카오 버튼 탭(미설치 폰) → 카카오 계정 웹 로그인 → 자동 홈 진입
- [ ] 내정보 → 로그아웃 → 로그인 화면 복귀
- [ ] 재로그인 시 계정 선택 화면이 다시 뜸(자동 로그인 X)

release APK로도 검증:

```powershell
flutter build apk --release --dart-define-from-file=.env.json
flutter install --release
```

> Memory의 `feedback_release_only_traps` 패턴 — debug에서 통과해도 release APK에서만 깨지는 함정이 있음. 매 PR마다 release 빌드로 한 번 더 검증.

---

## 6. 자주 발생하는 문제

| 증상 | 원인 | 해결 |
|---|---|---|
| 구글 버튼 탭 → 즉시 에러 "ID Token을 받지 못했어요" | `GOOGLE_WEB_CLIENT_ID`가 *iOS/Android 클라이언트 ID*로 박힘. Web Client ID가 들어가야 함 | 2-3 (a)의 *웹* Client ID 재확인 |
| 구글 로그인 후 Supabase 세션이 안 만들어짐 | Supabase Dashboard의 Google Provider에 Client ID/Secret 미등록 | 2-4 다시 |
| 카카오 버튼 탭 → "ID Token을 받지 못했어요" | OpenID Connect 비활성화 | 3-4의 *OpenID Connect 활성화* 토글 ON |
| 카카오 KOE205 | 동의항목에 *카카오계정(이메일)* 필수가 켜져 있음. 비즈 앱 미인증 카카오는 이 동의 거부 | 3-5에 따라 닉네임·프로필사진만 |
| Android 빌드 후 카카오 버튼 탭이 무반응 | `local.properties`의 `kakao.nativeAppKey` 누락 → AndroidManifest scheme이 `kakao://oauth`(빈 키)가 됨 | 4-2 다시 + `flutter clean` 후 재빌드 |
| iOS 빌드 후 카카오 버튼 탭 시 카카오톡이 안 열림 | `Info.plist`의 `kakaoKAKAO_NATIVE_APP_KEY` 치환 누락 | 4-3 다시 |

---

## 7. 관련 파일

| 위치 | 역할 |
|---|---|
| `lib/features/auth/auth_controller.dart` | `signInWithGoogle` · `signInWithKakao` |
| `lib/features/auth/login_screen.dart` | OAuth 2버튼 UI |
| `lib/core/config/env.dart` | `KAKAO_NATIVE_APP_KEY`·`GOOGLE_WEB_CLIENT_ID` 컴파일 타임 상수 |
| `android/app/build.gradle.kts` | `local.properties` → `manifestPlaceholders` 주입 |
| `android/app/src/main/AndroidManifest.xml` | 카카오 `AuthCodeCustomTabsActivity` + scheme |
| `ios/Runner/Info.plist` | 카카오 URL scheme + `LSApplicationQueriesSchemes` |
| `lib/main.dart` | `KakaoSdk.init` 호출 |
