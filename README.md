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

### 3. Supabase 마이그레이션·설정

#### 3-1. SQL 마이그레이션 적용

`supabase/migrations/` 안의 .sql 파일들을 Supabase Dashboard
> SQL Editor에서 순서대로 붙여 실행한다 (또는 Supabase CLI `supabase db push`).

#### 3-2. Auth 설정

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

> **보안**: 위 키들은 컴파일된 바이너리에 박힌다. 실서비스 단계에선
> 알라딘 API 호출을 Supabase Edge Function 등 백엔드 프록시로 옮길 것
> (Stage 4 이후 과제).
