# Play Console 자동 업로드 셋업

`.github/workflows/play-release.yml` 이 동작하려면 한 번 셋업이 필요해요. 5단계 — 처음 한 번만.

## 0. 사전 조건

- 첫 번째 AAB는 **반드시 Play Console에서 수동 업로드** 해야 합니다 (Google 정책). API 자동화는 그 다음 빌드부터 풀립니다.
- 패키지명은 `io.github.tgparkk.bookquote` 고정 — workflow 에 하드코딩.

## 1. Service Account 생성

1. Play Console → 설정 → **API 액세스** (https://play.google.com/console/u/0/developers/api-access)
2. "새 서비스 계정 만들기" → "Google Cloud Console로 이동" 클릭
3. Google Cloud Console에서:
   - 서비스 계정 이름: `play-uploader` 같은 거 아무거나
   - 만들고 나면 그 서비스 계정 클릭 → **키** 탭 → **키 추가 → 새 키 만들기 → JSON** → 다운로드
   - 다운로드한 JSON 파일은 안전한 곳에 보관 (이게 secret이 됨)
4. Play Console로 돌아와서 "갱신" → 방금 만든 서비스 계정이 목록에 나옴 → **액세스 권한 부여**
5. 권한: **"릴리스 관리자"** (앱 만들기·편집·출시) 만 있으면 됨

## 2. GitHub Secrets 등록

저장소 → Settings → Secrets and variables → **Actions** → New repository secret.

7개를 등록합니다. 각 값을 어떻게 만드는지:

### `ENV_JSON_BASE64`

```powershell
# Windows PowerShell
[Convert]::ToBase64String([IO.File]::ReadAllBytes(".env.json")) | Set-Clipboard
```

클립보드에 들어간 값을 그대로 붙여넣기.

### `UPLOAD_KEYSTORE_BASE64`

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/upload-keystore.jks")) | Set-Clipboard
```

### `KEYSTORE_STORE_PASSWORD` / `KEYSTORE_KEY_PASSWORD` / `KEYSTORE_KEY_ALIAS`

`android/key.properties` 의 값을 그대로 (각 줄의 `=` 오른쪽 문자열). `keyAlias` 는 보통 `upload`.

> ⚠️ **이번 셋업 끝나면 keystore 비밀번호 rotate 권장** — `key.properties` 가 한 번이라도 화면에 출력된 적 있다면 채팅/스크린샷 등으로 누출 위험. Play 앱 서명을 쓰는 중이면 *upload key* 만 바꾸면 됨 ([Play Console → 앱 무결성 → 앱 서명 키 재설정](https://support.google.com/googleplay/android-developer/answer/9842756)).

### `KAKAO_NATIVE_APP_KEY`

`android/local.properties` 의 `kakao.nativeAppKey=` 오른쪽 값.

### `PLAY_SERVICE_ACCOUNT_JSON`

1단계에서 받은 JSON 파일 **내용 전체** 를 그대로 붙여넣기 (base64 인코딩 X, JSON 원문).

## 3. 첫 업로드는 수동으로

Play Console에서 internal testing 트랙에 AAB 한 번을 수동 업로드해야 API가 풀립니다.

```powershell
flutter build appbundle --release --dart-define-from-file=.env.json
```

→ `build/app/outputs/bundle/release/app-release.aab` 파일을 Play Console → 테스트 → 내부 테스트 → 새 버전 만들기 에 끌어다 놓으면 끝.

## 4. 자동 업로드 실행

GitHub 저장소 → **Actions** 탭 → 왼쪽 "Play Console — internal upload" → **Run workflow** 버튼.

"릴리스 노트" 입력란에 한국어로 변경사항 적고 실행. 5~10분 정도 빌드 후 internal track 에 올라갑니다.

## 5. 다음에 새 버전 올릴 때

1. `pubspec.yaml` 의 `version: 1.0.0+5` 에서 `+5` 의 숫자를 올림 (예: `+6`)
2. commit → push
3. Actions → Run workflow → 릴리스 노트 적기 → Run

versionCode 안 올리면 Play Console이 "이미 사용 중인 버전" 으로 거절합니다.

## 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| `403 The caller does not have permission` | Service Account 가 Play Console 에 권한 없음 | Play Console → API 액세스 → 해당 계정 → 액세스 권한 부여 다시 확인 |
| `400 APK specifies a version code that has already been used` | versionCode 안 올림 | pubspec.yaml 의 `+N` 숫자 +1 |
| `Package not found: io.github.tgparkk.bookquote` | 첫 업로드 수동 안 했음 | 위 3단계 먼저 |
| `Validation Error: Only releases with status draft may be created on draft app` | 앱이 아직 한 번도 출시된 적 없음 (draft 상태) | Play Console 에서 internal 트랙 한 번 출시 완료 후 재시도 |
| 빌드는 통과했는데 release APK 에서만 깨짐 | `INTERNET` 권한 누락·`debugNeedsPaint` 등 release-only 함정 | 로컬에서 `flutter build apk --release` 후 실기기 설치 검증 |
