# bookquote

책귀 - 책 인용구를 카드로 만들어 공유하는 앱

기획·설계는 [`docs/`](docs/) 참조 (특히 [`docs/PLAN.md`](docs/PLAN.md), [`docs/STAGES.md`](docs/STAGES.md)).

## 개발 환경 셋업

### 1. 의존성

```sh
flutter pub get
```

### 2. 환경 변수

루트의 `.env.json.example`을 복사해 `.env.json`을 만들고 실제 키를 채운다.
`.env.json`은 `.gitignore` 처리되어 커밋되지 않는다.

```sh
cp .env.json.example .env.json
```

필요한 키:
- `ALADIN_TTB_KEY` — 알라딘 OpenAPI TTB 키 ([발급](https://www.aladin.co.kr/ttb/wblog_manage.aspx), 5,000건/일)
- `SUPABASE_URL` — Supabase 프로젝트 URL
- `SUPABASE_ANON_KEY` — Supabase anon public 키 (RLS로 보호)

### 3. Supabase 마이그레이션·Edge Function·설정

#### 3-1. SQL 마이그레이션 적용

`supabase/migrations/` 안의 .sql 파일들을 Supabase Dashboard
> SQL Editor에서 순서대로 붙여 실행한다 (또는 Supabase CLI `supabase db push`).

현재 마이그레이션:
- `001_profiles.sql` — profiles 테이블 + 회원가입 트리거 + RLS
- `002_handle_new_user_oauth.sql` — OAuth 사용자(이메일 null 케이스) 호환
- `003_books.sql` — books 글로벌 카탈로그 + `upsert_book` RPC

#### 3-2. Edge Function 배포

`supabase/functions/aladin-search/`가 알라딘 OpenAPI 호출을 프록시한다 (클라이언트
키 노출 회피 + 5,000건/일 한도 보호). 배포 두 가지 방법:

**Supabase CLI** (권장):
```sh
supabase login
supabase link --project-ref ndbvptxwznogcuuumzzh
supabase secrets set ALADIN_TTB_KEY=<TTB키>
supabase functions deploy aladin-search
```

**Dashboard** (CLI 없을 때):
1. Edge Functions 메뉴 > **Create function** > 이름 `aladin-search`
2. `supabase/functions/aladin-search/index.ts`와 `_shared/aladin.ts`,
   `_shared/cors.ts` 내용 그대로 붙여넣기
3. **Settings > Secrets**에서 `ALADIN_TTB_KEY` 추가
4. Deploy

#### 3-3. Auth 설정

Dashboard > Authentication > URL Configuration:
- **Site URL**: `http://localhost:8080` (개발 기본)
- **Redirect URLs**: 다음 항목들을 추가
  - `http://localhost:**`  (모든 로컬 dev 포트 허용)
  - 향후 배포 도메인

Dashboard > Authentication > Providers:
- **Email**: 기본 ON. 매직링크가 이 provider로 발송됨

### 4. 실행

`--dart-define-from-file` 플래그가 필수. 매직링크 redirect를 안정적으로 처리하려면 `--web-port=8080`도 함께.

```sh
flutter run -d chrome --dart-define-from-file=.env.json --web-port=8080
flutter build apk --dart-define-from-file=.env.json
```

IDE에서는 launch configuration의 "Additional run args"에 동일한 인자 추가
(Android Studio/IntelliJ: Run/Debug Configurations → Additional run args).

### 5. 검증

```sh
flutter analyze
flutter test
```

> **보안**: 환경 키는 컴파일된 바이너리에 박힌다. `ALADIN_TTB_KEY`는 이제
> Edge Function이 대신 호출하므로 클라이언트에는 더 이상 필요 없음 — `.env.json`
> 항목과 `Env.aladinTtbKey` 상수는 다음 정리 PR에서 삭제 예정. `SUPABASE_*` 두
> 키는 클라이언트가 직접 사용 (RLS로 보호되는 anon/publishable 키라 노출 OK).
