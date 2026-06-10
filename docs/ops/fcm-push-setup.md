# FCM 푸시 셋업 (PR-PC 수동 단계)

코드(PA 마이그레이션·PB 클라이언트·PC Edge Function)는 모두 들어가 있다. 실제로
푸시가 *발송*되려면 아래 Firebase/Supabase 콘솔 작업이 필요하다(사람 손).

전제: Firebase 프로젝트는 이미 존재(Crashlytics용), `android/app/google-services.json`
존재. iOS(APNs)는 V1 범위 밖.

## 1. Firebase에서 Cloud Messaging 활성화
1. Firebase Console → 프로젝트 → **Build → Cloud Messaging**. (FCM API v1이 자동 활성)
2. 만약 비활성이면 Google Cloud Console에서 **Firebase Cloud Messaging API** 사용 설정.

## 2. 서비스계정 키 발급
1. Firebase Console → ⚙️ 프로젝트 설정 → **서비스 계정** 탭.
2. **새 비공개 키 생성** → JSON 다운로드(`client_email`·`private_key`·`project_id` 포함).
3. 이 JSON 전체를 한 줄/원문 문자열로 보관(다음 단계 secret에 넣음).

## 3. Edge Function secret 등록
```bash
# JSON 파일 경로로 등록 (파일 내용 전체가 FCM_SERVICE_ACCOUNT 값이 됨)
npx supabase secrets set FCM_SERVICE_ACCOUNT="$(cat path/to/service-account.json)"
# 웹훅 인증용 임의 시크릿(아무 긴 랜덤 문자열)
npx supabase secrets set WEBHOOK_SECRET="<랜덤-긴-문자열>"
```
(`SUPABASE_URL`·`SUPABASE_SERVICE_ROLE_KEY`는 Edge 런타임이 자동 주입.)

## 4. Edge Function 배포
```bash
# 웹훅은 사용자 JWT가 없으므로 verify_jwt 끄고, 대신 x-webhook-secret로 게이트.
npx supabase functions deploy push-notification --no-verify-jwt
```
배포 후 함수 URL: `https://<project-ref>.supabase.co/functions/v1/push-notification`

## 5. Database Webhook 연결 (notifications INSERT → 함수)
Supabase Dashboard → **Database → Webhooks → Create**:
- Table: `public.notifications`
- Events: **Insert**
- Type: **Supabase Edge Functions** → `push-notification`
- HTTP Headers 추가: `x-webhook-secret: <3단계 WEBHOOK_SECRET와 동일 값>`

(또는 SQL로 `supabase_functions.http_request` 트리거를 직접 생성 — 대시보드가 더 쉽다.)

## 6. 검증
1. 두 계정(A·B). B로 A의 공개 인용구/후기에 좋아요, 또는 A를 팔로우.
2. A 기기(앱 **종료** 상태)에 상태바 푸시가 떠야 한다: "○○님이 회원님의 인용구를 좋아해요".
3. 푸시 탭 → 앱 열리며 해당 책 상세/프로필로 이동.
4. 안 오면: Edge Function 로그(`npx supabase functions logs push-notification`)에서
   `skipped`(prefs/토큰 없음)·`oauth token failed`(서비스계정 키)·401(웹훅 시크릿 불일치) 확인.

## 동작 요약
- `notifications` insert(좋아요·팔로우 트리거 적재) → 웹훅 → 함수가 수신자 prefs
  (`profiles.push_*`) 확인 → `device_tokens` 조회 → FCM 발송 → UNREGISTERED 토큰 정리.
- opt-out: 사용자가 `profiles.push_enabled=false`거나 타입별 토글 off면 발송 skip.
  (설정 UI는 후속 — 현재는 DB 컬럼만, 기본 ON. OS 알림 권한이 1차 게이트.)
- 토큰 등록: 앱이 로그인 시 `register_device_token` RPC로 등록, 로그아웃 시 삭제.
