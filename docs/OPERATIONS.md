# 운영 설정 대장 (OPERATIONS)

책글귀의 외부 서비스 설정·계정·배포 절차의 단일 기준 문서.
마지막 갱신: **2026-07-05 (v1.3.0+17 첫 프로덕션 출시일)**

> ⚠️ 이 문서에 **비밀키를 적지 않는다.** 키 값은 전부 리포 루트 `.env.json`(gitignore됨)에만 존재.

---

## 0. 계정

| 항목 | 값 |
|---|---|
| 운영 Google 계정 | sttgpark@gmail.com (Play Console·AdMob·Firebase 공통) |
| Play Console 이력 | 계정 정지 → **복구 완료(2026-05-21)**. 정책 위반에 극도로 보수적으로 운영할 것 |
| 실기기 | Samsung SM F956N (Galaxy Z Fold6) |

## 1. Google Play Console

| 항목 | 값 |
|---|---|
| 패키지 | `io.github.tgparkk.bookquote` |
| 개발자 ID | 7910626417257295631 |
| 앱 ID (콘솔 URL용) | 4974877844432261185 |
| 앱 콘텐츠 바로가기 | `https://play.google.com/console/u/0/developers/7910626417257295631/app/4974877844432261185/app-content` |
| 스토어 페이지 | `https://play.google.com/store/apps/details?id=io.github.tgparkk.bookquote` |
| 첫 프로덕션 출시 | **2026-07-05, v1.3.0+17** (광고 포함 버전) |

### 앱 콘텐츠 선언 상태 (2026-07-03~04 갱신)
- **광고**: 포함 = 예
- **광고 ID**: 사용 = 예, 목적: 광고 또는 마케팅. *"출시 오류 사용 중지" 체크박스는 비워둠* — AAB에 AD_ID 권한 누락 시 콘솔이 막아주는 안전장치 유지
- **데이터 보안**: 기기 또는 기타 ID + 대략적 위치 → 수집됨+공유됨, 임시 처리 아니요, 필수, 목적: 광고 또는 마케팅
- **개발자 웹사이트**: `https://tgparkk.github.io/` (app-ads.txt 인증의 전제 — 바꾸지 말 것)

### 콘솔 UI 길찾기 (2026 개편 기준)
- 앱 콘텐츠: **모니터링 및 개선 → 정책 및 프로그램 → 앱 콘텐츠** (조치됨 탭에 완료 선언 목록)
- 선언 수정 후엔 **게시 개요 → [변경사항 검토를 위해 전송]** 까지 눌러야 제출됨

### 함정 기록
- 프로덕션 트랙에 **임시 버전(draft)이 남아 있으면 버전 승급이 "트랙에 이미 임시 버전이 있음"으로 거부**됨 → 프로덕션 페이지에서 낡은 임시 버전 삭제 후 승급 (2026-07-05 발생, 1.0.1+13 초안이 원인)

## 2. AdMob

| 항목 | 값 |
|---|---|
| 퍼블리셔 ID | `pub-7230084799824817` |
| 앱 ID | `ca-app-pub-7230084799824817~1381070822` → `AndroidManifest.xml` APPLICATION_ID meta-data |
| 광고 단위: 홈 하단 배너 | `home_bottom_banner` = `ca-app-pub-7230084799824817/7141462724` → `lib/features/ads/ad_ids.dart` |
| 광고 단위: 내정보 배너 | **미발급** — 발급 전까지 홈 단위로 폴백(수익 동일, 리포트 합산). 발급 시 `_prodMeBannerAdUnitId` 채우기 |
| app-ads.txt | `https://tgparkk.github.io/app-ads.txt` — 내용 한 줄: `google.com, pub-7230084799824817, DIRECT, f08c47fec0942fa0` |
| 승인 이력 | app-ads.txt 인증 + 앱 검토 **승인 완료(2026-07-04 메일 "앱이 승인됨")** |
| 수익 대시보드 | https://apps.admob.com |

### 광고 정책 (불가침)
1. **종료 시/뒤로가기 인터스티셜 영구 금지** (2026-05-28 협의, AdMob 정책 + 재정지 리스크)
2. **본인 기기에서 실 광고 클릭 절대 금지** (무효 트래픽 = 계정 정지). 테스트할 거면 AdMob 콘솔 → 설정 → 테스트 기기 등록
3. debug 빌드는 항상 Google 테스트 광고 (`ad_ids.dart`의 kDebugMode 분기 유지)
4. CMP(동의 관리): 한국 전용 배포 동안 불필요. **글로벌 확장 시 UMP SDK + CMP 설정 필수** (EEA/영국/스위스)

## 3. GitHub Pages (웹 인프라)

| 사이트 | 저장소 | 역할 |
|---|---|---|
| `tgparkk.github.io` | `tgparkk/tgparkk.github.io` (main, 루트, Jekyll legacy 빌드) | **app-ads.txt**, ads.txt(블로그 AdSense), 개발자 웹사이트 |
| `tgparkk.github.io/bookquote` | 이 리포 `/docs` | **이용약관** `/bookquote/terms`, **개인정보처리방침** `/bookquote/privacy`, **공유 랜딩** `/bookquote/b/?id=<bookId>` |

- 개인정보처리방침에 광고(ADID 수집·AdMob 위탁·국외 이전) 고지 포함됨 (2026-07-03, PR#14)
- 공유 랜딩(`/bookquote/b/`, 2026-08-01): 카드 공유 텍스트의 https 링크가 여기로 옴. Android 설치자는 [앱에서 이 책 열기](intent:// → 커스텀 스킴), 미설치자는 Play 폴백(UTM `utm_source=share_card`). 향후 App Links 자동 열기를 원하면 **루트 저장소**(`tgparkk/tgparkk.github.io`)의 `/.well-known/assetlinks.json` 추가 필요 — app-ads.txt 안 깨지게 주의
- Pages 배포가 가끔 "Deployment failed, try again later"로 실패 — 저장소 Actions에서 실패한 `pages build and deployment` **재실행**으로 해결 (2026-07-03 발생)

## 4. Supabase

| 항목 | 값 |
|---|---|
| URL / anon key | `.env.json`의 `SUPABASE_URL` / `SUPABASE_ANON_KEY` |
| Edge Functions | `aladin-search`(책 검색 프록시, ALADIN_TTB_KEY 사용), `delete-account`(인앱 계정 삭제), `push-notification`, `enrich-book-page-count`, `backfill-page-counts` |
| 보안 | 전 테이블 RLS. E2EE 잠금 인용구는 AES-256-GCM on-device key(서버는 평문 모름) |
| 스키마/운영 문서 | `docs/db-schema.md`, `docs/db-operations.md` |

## 5. Firebase

- **Crashlytics**: 크래시 수집 (보존 90일 — 개인정보처리방침에 고지됨). 콘솔: https://console.firebase.google.com
- **FCM**: 푸시 알림 (기본 채널 `bookquote_high`, Manifest meta-data)
- 권장: Firebase 콘솔 → Crashlytics → 알림 설정에서 **신규 이슈/급증(velocity) 이메일 알림 켜기**

### Firebase MCP (Claude 세션에서 Crashlytics 직접 조회 — 2026-07-06 설정)
- `.mcp.json`에 firebase 서버 등록됨 (`npx firebase-tools mcp --only core,crashlytics`). `.firebaserc`가 기본 프로젝트 `bookquote-aa178` 지정
- **Crashlytics Data API 활성화됨** (2026-07-06, 프로젝트 105975163034)
- ⚠️ **인증은 반드시 `firebase login` 사용자 계정으로** — 서비스 계정(GOOGLE_APPLICATION_CREDENTIALS)은 조회 API가 404를 반환하는 알려진 버그 (firebase-tools#10310). 로그인 풀리면 새 터미널에서 `npx -y firebase-tools login`
- Android 앱 ID: `1:105975163034:android:558e54cb508f8142fd9723` (google-services.json의 mobilesdk_app_id)

## 6. OAuth

- **Google**: `GOOGLE_WEB_CLIENT_ID` (.env.json) → Supabase signInWithIdToken
- **Kakao**: `KAKAO_NATIVE_APP_KEY` (.env.json) → manifestPlaceholder로 scheme 주입. V1.0 UI에서는 카카오 버튼 숨김
- 키 해시는 **최종 서명 키 기준** — 서명 키 변경 시 카카오/구글 콘솔 재등록 필요

## 7. 빌드·배포 절차 (절대 규칙)

```powershell
# 1) 빌드 — dart-define 없이 빌드 금지 (3회 재발한 함정. 예외 없음)
flutter build appbundle --release --dart-define-from-file=.env.json

# 2) 키 임베드 검증 — 3개 ABI 모두 1 이상이어야 함. 0이면 업로드 금지
#    (bash) AAB면 base/lib/*/libapp.so 를 unzip 후 검사, APK 빌드면 intermediates로 충분
grep -ac "32327959348" build/app/intermediates/merged_native_libs/release/*/out/lib/*/libapp.so

# 3) 매니페스트 확인 — versionCode / AdMob 앱 ID / AD_ID 권한
Select-String build\app\intermediates\merged_manifests\release\processReleaseManifest\AndroidManifest.xml -Pattern "versionCode|APPLICATION_ID|AD_ID"

# 4) 실기기 설치는 반드시 adb install -r (flutter install 금지 — 데이터 리셋 + 재빌드 안 함)
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r build\app\outputs\flutter-apk\app-release.apk
```

- versionCode는 트랙 무관 전역 단조 증가. 현재 최신: **17 (v1.3.0)**
- 매 PR마다 release 빌드 실기기 검증 (release-only 함정: INTERNET 권한, `debug*` API, dart-define)

## 8. 모니터링 (출시 후 안정성)

### 자동 체크 — `tool/check_release.ps1`
```powershell
powershell -File tool\check_release.ps1
```
검사 항목: 스토어 페이지 게시 상태 · app-ads.txt · 이용약관/개인정보처리방침 URL · Supabase Auth/REST 가용성. 실패는 [FAIL]로 표시, exit code = 실패 건수.

### 일일 자동 실행 — Windows 작업 스케줄러 (2026-07-05 등록)
- 작업명 **`Bookquote Release Check`** — 매일 09:00, 놓치면 부팅 후 실행(StartWhenAvailable)
- 실행 대상: `tool/check_release_task.ps1` (래퍼) — 결과를 `%LOCALAPPDATA%\bookquote\check_release.log`에 누적(최근 500줄), **실패 시에만 팝업 경보**, 성공은 무음
- 관리: `Get-ScheduledTask -TaskName 'Bookquote Release Check'` / 해제: `Unregister-ScheduledTask -TaskName 'Bookquote Release Check'`
- 재등록 명령은 `tool/check_release_task.ps1` 상단 주석 참고 (PC를 바꾸면 재등록 필요)

### Crashlytics 이메일 알림 (계정별 설정 — sttgpark@gmail.com으로 켜둠)
Firebase 콘솔 → 프로젝트 → ⚙️ 프로젝트 설정 → **알림** 탭 → Crashlytics 항목(신규 이슈·급증 알림·회귀)의 이메일 토글 ON.

### 수동 체크 (콘솔 로그인 필요 — 출시 후 첫 주는 매일, 이후 주 1회)
| 무엇 | 어디 | 경보 기준 |
|---|---|---|
| 비정상 종료·ANR | Play Console → 모니터링 및 개선 → Android vitals | 비정상 종료율 1.09%↑, ANR 0.47%↑ (Play 불량 임계값) |
| 크래시 상세 | Firebase 콘솔 → Crashlytics | 신규 이슈 발생, 특정 기기/OS 집중 |
| 광고 수익·노출 | apps.admob.com → 홈 | 노출 0 지속(광고 단위 문제), 매치율 급락 |
| 정책 상태 | Play Console → 정책 및 프로그램 → 정책 상태 / AdMob 정책 센터 | 위반 항목 등장 시 즉시 대응 |
| 리뷰 | Play Console → 평점 및 리뷰 | 별 1~2점 리뷰의 공통 패턴 |

### DB 지표 조회 — `tool/launch_metrics.sql`
가입자·인용구·서재 등 출시 후 지표 쿼리 4종(①요약 ②일별 가입 ③일별 콘텐츠 ④활동 심도). Claude 세션에서 Supabase MCP(`/mcp` 인증)로 바로 실행하거나, 대시보드 SQL Editor에 블록별로 붙여넣기.

### 이상 발견 시
크래시 스택/vitals 스크린샷을 Claude 세션에 붙여넣으면 코드와 대조해 진단. Supabase 장애 의심 시 `check_release.ps1` 우선 실행.
