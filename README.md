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

### 3. 실행

`--dart-define-from-file` 플래그가 필수다.

```sh
flutter run --dart-define-from-file=.env.json
flutter build apk --dart-define-from-file=.env.json
```

IDE에서는 launch configuration에 같은 인자를 추가한다 (Android Studio/IntelliJ:
Run/Debug Configurations → Additional run args).

### 4. 검증

```sh
flutter analyze
flutter test
```

> **보안**: 위 키들은 컴파일된 바이너리에 박힌다. 실서비스 단계에선
> 알라딘 API 호출을 Supabase Edge Function 등 백엔드 프록시로 옮길 것
> (Stage 4 이후 과제).
