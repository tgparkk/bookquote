# Play Console 자동 업로드 셋업

`.github/workflows/play-release.yml` 이 동작하려면 한 번 셋업이 필요해요. 처음 한 번만.

> ✅ **셋업 완료 (2026-09-26)** — 서비스 계정 `play-uploader@bookquote-aa178.iam.gserviceaccount.com`,
> GitHub secret 7개 등록. 키 JSON 원본은 저장소 밖 `C:\Users\sttgp\keys\`. 이후 업로드는 아래 5절.

## 0. 사전 조건

- 첫 번째 AAB는 **반드시 Play Console에서 수동 업로드** 해야 합니다 (Google 정책). API 자동화는 그 다음 빌드부터 풀립니다. (책글귀는 2026-07-05 프로덕션 출시로 충족)
- 패키지명은 `io.github.tgparkk.bookquote` 고정 — workflow 에 하드코딩.

## 1. Service Account 생성 (2026 기준 절차)

Play Console의 "API 액세스" 페이지는 개편으로 사라졌을 수 있다. 서비스 계정은 **Google Cloud에서 만들고
Play Console "사용자 및 권한"에 초대**한다.

1. Google Cloud 프로젝트는 Firebase 프로젝트 **`bookquote-aa178`** 재사용.
2. **Google Play Android Developer API 사용 설정**:
   https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com → [사용]
3. **서비스 계정 생성**: https://console.cloud.google.com/iam-admin/serviceaccounts → [+ 서비스 계정 만들기]
   - 이름 `play-uploader`, 역할 부여는 건너뛰고 [완료]
   - 계정 클릭 → **키** 탭 → 키 추가 → 새 키 만들기 → **JSON** → 다운로드
   - ⚠️ JSON은 비밀번호와 같다. **저장소 폴더 밖**에 보관(공개 저장소). `.gitignore`에 `bookquote-aa178-*.json` 방어 패턴 있음
4. **Play Console에 초대**: https://play.google.com/console/u/0/developers/7910626417257295631/users-and-permissions
   - [새 사용자 초대] → 서비스 계정 이메일 입력 → **앱 권한**에 책글귀 추가
   - 체크: **테스트 트랙에 앱 출시**, **테스트 트랙 관리 및 테스터 목록 수정** (프로덕션 자동 출시는 일부러 제외)
   - 권한 반영까지 몇 시간~하루 걸릴 수 있음 — 첫 업로드 403이면 기다렸다 재시도

## 2. GitHub Secrets 등록

저장소 → Settings → Secrets and variables → **Actions** → New repository secret.
(Claude 세션에선 `gh secret set NAME < 파일` 로 값을 화면에 출력하지 않고 등록했다.)

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
또는 CLI: `gh workflow run play-release.yml --ref main -f release_notes="..."` → `gh run watch`.

"릴리스 노트" 입력란에 한국어로 변경사항 적고 실행. 5~10분 정도 빌드 후 internal track 에 올라갑니다.
CI 테스트는 `--exclude-tags golden` — 카드 골든은 로컬 Windows 이미지라 ubuntu에서 깨짐(로컬에서만 비교).

## 5. 다음에 새 버전 올릴 때

1. `pubspec.yaml` 의 `version: X.Y.Z+N` 에서 `+N` 을 올림 (versionCode는 트랙 무관 전역 단조 증가)
2. PR → main 머지
3. Actions → Run workflow(`--ref main`) → 릴리스 노트 적기 → Run
4. 내부 테스트에서 확인 후 **프로덕션 승급은 Play Console에서 직접**(서비스 계정엔 프로덕션 권한 없음)

versionCode 안 올리면 Play Console이 "이미 사용 중인 버전" 으로 거절합니다.

## 트러블슈팅

| 증상 | 원인 | 해결 |
|---|---|---|
| `403 The caller does not have permission` | Service Account 가 Play Console 에 권한 없음(또는 초대 직후 반영 대기) | Play Console → 사용자 및 권한 → 서비스 계정의 앱 권한 확인. 초대 직후면 몇 시간 뒤 재시도 |
| `400 APK specifies a version code that has already been used` | versionCode 안 올림 | pubspec.yaml 의 `+N` 숫자 +1 |
| `Package not found: io.github.tgparkk.bookquote` | 첫 업로드 수동 안 했음 | 위 3단계 먼저 |
| `Validation Error: Only releases with status draft may be created on draft app` | 앱이 아직 한 번도 출시된 적 없음 (draft 상태) | Play Console 에서 internal 트랙 한 번 출시 완료 후 재시도 |
| 빌드는 통과했는데 release APK 에서만 깨짐 | `INTERNET` 권한 누락·`debugNeedsPaint` 등 release-only 함정 | 로컬에서 `flutter build apk --release` 후 실기기 설치 검증 |
