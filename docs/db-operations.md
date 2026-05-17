# 책귀 DB 운영 가이드

**기준**: Supabase project `ndbvptxwznogcuuumzzh` (Seoul), Free Plan 가정, 2026-05-17 작성
**대상**: 솔로 운영자 — V1 출시 후 사용자 문의·사고·정기 점검 시 빠르게 참조

> document-specialist 에이전트 조사 산출 (2026-05-17). 실제 Supabase 콘솔 동작·플랜 한계는 Dashboard에서 직접 재확인 권고.

---

## 0. 전제 — Supabase Studio 진입점

콘솔 URL: `https://supabase.com/dashboard/project/ndbvptxwznogcuuumzzh`

북마크 필수 페이지:
- Table Editor: `.../editor`
- SQL Editor: `.../sql`
- Authentication > Users: `.../auth/users`
- Database > Backups: `.../database/backups/scheduled`
- Logs > Postgres: `.../logs/postgres-logs`
- Logs > Edge Functions: `.../logs/edge-logs`
- Logs > Auth: `.../logs/auth-logs`

---

## 1. Supabase Studio 메뉴별 운영

### 1-1. Table Editor
- 테이블 행 직접 조회·편집·삭제 (GUI). Foreign Key 클릭으로 연관 row 즉시 이동.
- **RLS 우회**: Table Editor는 service_role 권한 — 모든 사용자 데이터가 보임.
- **주의 — cascade**: `auth.users` row 삭제 시 `profiles`, `user_books`, `quotes`, `cards`까지 자동 삭제.
- 자주 쓰는 조작: 특정 사용자 인용구 조회 → Filter `user_id = <uuid>` + Sort `created_at desc` + Export CSV (우상단).

### 1-2. SQL Editor
- postgres(superuser)로 실행 → RLS 무시. 진단·운영 쿼리는 여기서.
- **안전 패턴**: 수정 전 SELECT로 영향 행 확인 → `BEGIN; ... ROLLBACK;`으로 감싸 검토 후 `COMMIT`.
- 저장된 쿼리(Saved queries) 사이드바 — 6절 추천 6개 등록 권고.

### 1-3. Authentication > Users
- 이메일/UUID 검색, 가입일·마지막 로그인·provider 확인.
- 수동 삭제 (Delete user) — cascade 발동. JWT는 만료까지 유효(기본 1시간).
- "Send magic link"로 임시 링크 재발송.
- **강제 로그아웃** (GUI 미지원): SQL Editor에서
  ```sql
  UPDATE auth.sessions SET not_after = now() WHERE user_id = '<uuid>';
  ```

### 1-4. Database > Backups (Free Plan 한계)
- **Free Plan**: 자동 백업은 생성되지만 **복원 UI 없음**. 사고 시 지원팀 의존(보장 없음).
- **Pro Plan ($25/월)**: 7일치 자동 백업 + 클릭 한 번 복원.
- **Free Plan 권고**: 수동 `supabase db dump`가 유일한 안전망(3절 참조).

### 1-5. Database > Roles
- `anon` — 비로그인. 책귀 RLS상 `books` SELECT만.
- `authenticated` — 로그인 사용자. `auth.uid() = user_id` 패턴으로 자기 데이터만.
- `service_role` — RLS 우회, 전체 접근. `delete-account` Edge Function 전용. **절대 클라이언트 노출 금지.**

### 1-6. Logs
| 종류 | 위치 | 용도 |
|---|---|---|
| Postgres Logs | Logs > Postgres Logs | 슬로우 쿼리·에러·DDL 변경 |
| Auth Logs | Logs > Auth Logs | 로그인 시도·매직링크 발송·실패 |
| Edge Function Logs | Logs > Edge Logs | `aladin-search`/`delete-account` 호출량·에러 |
| API Logs | Logs > API Logs | REST/GraphQL 요청 |

보존 기간은 Dashboard에서 직접 확인(Free Plan 일반적으로 1~3일).

---

## 2. 사용자 데이터 운영 시나리오 5개

### A. "내 인용구가 사라졌어요"
1. Authentication > Users에서 이메일 검색 → UUID 복사.
2. SQL Editor 진단:
   ```sql
   SELECT id, text, book_id, moods, created_at
   FROM public.quotes
   WHERE user_id = '<uuid>'
   ORDER BY created_at DESC;
   ```
3. 행이 있다 → 앱 클라이언트 버그(필터·세션). 재로그인 안내.
4. 행이 없다 → cascade 삭제됨. `auth.users`에 row 있는지 확인 → 있으면 Edge Function 로그에서 `delete-account` 호출 이력 확인.
5. **Free Plan에서 복구**: 수동 백업이 있을 때만 가능. 없으면 사용자에게 솔직히 안내.

### B. GDPR/개인정보 삭제 요청
앱 내 `delete-account`가 정상 동작했다면 cascade로 모두 삭제. 잔여물 확인:
```sql
SELECT id, email, deleted_at FROM auth.users WHERE email = 'user@example.com';
SELECT COUNT(*) FROM public.cards WHERE user_id = '<uuid>';
SELECT COUNT(*) FROM public.quotes WHERE user_id = '<uuid>';
```
`books`는 글로벌 카탈로그라 cascade 제외 — 개인정보 없음. Storage 오브젝트는 V1 없음(V1.5 아바타 추가 시 별도 삭제 로직 필요).

### C. "책 표지가 깨졌어요"
알라딘 URL 변경/삭제 케이스.
```sql
SELECT id, isbn13, title, cover_url FROM public.books
WHERE title LIKE '%파친코%' OR isbn13 = '9788936433598';
```
알라딘 API 재조회로 새 URL 확인 → transaction으로 UPDATE.

### D. "공유했는데 cards에 기록이 없어요"
`cards` INSERT는 fire-and-forget (PR11 비차단). 실패해도 UX 영향 없음.
```sql
SELECT id, quote_id, design, shared_at FROM public.cards
WHERE user_id = '<uuid>' ORDER BY shared_at DESC LIMIT 20;
```
원인 분류:
- RLS 위반: `user_id`가 JWT의 `auth.uid()`와 불일치.
- FK 위반: `quote_id`가 삭제됨.
- 네트워크 타임아웃: fire-and-forget이라 재시도 없음.

### E. 테스트 계정 일괄 정리
```sql
-- 1) 대상 확인
SELECT id, email, created_at FROM auth.users
WHERE email LIKE '%@example.com';

-- 2) 안전한 삭제 (cascade가 처리)
BEGIN;
DELETE FROM auth.users WHERE email LIKE '%@example.com';
SELECT COUNT(*) FROM auth.users WHERE email LIKE '%@example.com';
ROLLBACK; -- 확인 후 COMMIT
```

---

## 3. 백업·복원 전략 (Free Plan)

### 3-1. 한계 인지
- 자동 백업은 생성되나 Dashboard 복원 UI 없음 → 수동 백업이 유일한 안전망.

### 3-2. 수동 백업 — `supabase db dump`

준비:
```powershell
npx --yes supabase link --project-ref ndbvptxwznogcuuumzzh
```

스키마 백업:
```powershell
npx --yes supabase db dump --linked -f backup/schema_$(Get-Date -Format 'yyyyMMdd').sql
```

데이터 백업:
```powershell
npx --yes supabase db dump --linked --data-only -f backup/data_$(Get-Date -Format 'yyyyMMdd').sql
```

**백업 저장 위치**: `backup/` 디렉터리 `.gitignore`로 제외하고 로컬/개인 클라우드. 백업 파일에 사용자 개인정보 포함 — repo push 절대 금지.

### 3-3. 백업해야 하는 것
| 항목 | 방법 | 비고 |
|---|---|---|
| DB 스키마 | `db dump` | migrations 있어 낮은 우선순위 |
| DB 데이터 | `db dump --data-only` | 핵심 (사용자 인용구·서재) |
| Edge Function 코드 | git repo | `supabase/functions/` |
| migrations | git repo | `supabase/migrations/` |
| Storage 오브젝트 | V1 없음 | V1.5 추가 시 별도 CLI |
| Secrets | 1Password 등 별도 | `.env`/비밀번호 관리자 |

### 3-4. 복원 검증 (로컬)
```powershell
npx --yes supabase start
npx --yes supabase db push --local
psql postgresql://postgres:postgres@localhost:54322/postgres -f backup/data_20260517.sql
psql postgresql://postgres:postgres@localhost:54322/postgres -c "SELECT COUNT(*) FROM public.quotes;"
```

### 3-5. 백업 주기
- **출시 직전**: 즉시 1회
- **정기**: 주 1회 (사용자 100명 미만)
- **사용자 100명 이후**: Pro Plan 강력 권고

---

## 4. 정기 점검 체크리스트

### 주간 (월요일 15분)
```
□ Auth Logs — 비정상 대량 가입 시도
□ Edge Logs — aladin-search 에러율 (키 만료 징후)
□ Authentication > Users — 지난 7일 신규 가입자
□ 주간 수동 백업 (data-only)
```

빠른 현황 SQL:
```sql
SELECT
  (SELECT COUNT(*) FROM auth.users) AS total_users,
  (SELECT COUNT(*) FROM public.quotes) AS total_quotes,
  (SELECT COUNT(*) FROM public.user_books) AS total_library,
  (SELECT COUNT(*) FROM public.cards) AS total_cards,
  (SELECT COUNT(*) FROM auth.users WHERE created_at > now() - interval '7 days') AS new_users_7d,
  (SELECT COUNT(*) FROM public.quotes WHERE created_at > now() - interval '7 days') AS new_quotes_7d;
```

### 월간 (1일 30분)
```
□ Database 용량 (500MB 한도 접근?)
□ 새 테이블 RLS 활성화 여부
□ 느린 쿼리 (pg_stat_statements)
□ 월간 수동 백업 (schema + data)
□ Supabase 청구서·플랜·pausing 경고
```

RLS 미적용 탐지:
```sql
SELECT schemaname, tablename FROM pg_tables
WHERE schemaname = 'public' AND rowsecurity = false;
```

DB 용량:
```sql
SELECT pg_size_pretty(pg_database_size('postgres')) AS db_size;
-- Free Plan 한도: 500 MB
```

의심 활동 (봇 의심):
```sql
SELECT user_id, COUNT(*) AS quotes_24h
FROM public.quotes
WHERE created_at > now() - interval '24 hours'
GROUP BY user_id HAVING COUNT(*) > 50
ORDER BY quotes_24h DESC;
```

---

## 5. 응급 대응

### 5-1. 실수로 DROP TABLE / 대량 DELETE
1. 트랜잭션 안이면 즉시 `ROLLBACK;`
2. Free Plan은 자동 복원 UI 없음 → 수동 백업 파일에서 복원
   ```powershell
   psql <supabase-connection-string> -f backup/data_20260516.sql
   ```
3. 수동 백업도 없으면 `support@supabase.io` 즉시 연락 (보장 없음)
4. **예방**: 모든 DDL/대량 DML은 반드시 `BEGIN; ... ROLLBACK;` 패턴

### 5-2. service_role key가 git에 push됨
1. Dashboard > Settings > API > "Regenerate" 새 키 발급
   URL: `https://supabase.com/dashboard/project/ndbvptxwznogcuuumzzh/settings/api`
2. Edge Function은 `SUPABASE_SERVICE_ROLE_KEY` 자동 주입 — 별도 업데이트 불필요
3. git 히스토리 노출 키 제거 (BFG Repo Cleaner)
4. 노출 시간 동안 Auth Logs·API Logs 비정상 호출 검토

### 5-3. 알라딘 API 키 노출
1. 알라딘 개발자센터 → TTB Key 재발급
2. Supabase > Settings > Edge Functions > `ALADIN_TTB_KEY` 업데이트
3. `aladin-search` 재배포:
   ```powershell
   printf 'y\n' | npx --yes supabase functions deploy aladin-search
   ```

### 5-4. 매직링크 잘못 전달
매직링크는 one-time use → 사용 전이라면 무효화 가능:
```sql
UPDATE auth.users
SET confirmation_token = '', recovery_token = ''
WHERE email = 'victim@example.com';

UPDATE auth.sessions SET not_after = now()
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'victim@example.com');
```

---

## 6. 추천 운영 도구·습관

### 6-1. SQL Editor 저장 쿼리 6개 (Saved Queries)

**Q1. weekly_stats** — 주간 현황 요약 (4절 빠른 현황 SQL)

**Q2. rls_check** — RLS 미적용 테이블 (4절 RLS 미적용 탐지)

**Q3. user_lookup** — 이메일로 사용자 전체 조회
```sql
SELECT
  u.id, u.email, u.created_at, u.last_sign_in_at,
  p.display_name,
  (SELECT COUNT(*) FROM public.quotes WHERE user_id = u.id) AS quotes,
  (SELECT COUNT(*) FROM public.user_books WHERE user_id = u.id) AS library,
  (SELECT COUNT(*) FROM public.cards WHERE user_id = u.id) AS cards
FROM auth.users u
LEFT JOIN public.profiles p ON p.id = u.id
WHERE u.email = 'user@example.com';
```

**Q4. db_size** — DB 용량 현황
```sql
SELECT
  pg_size_pretty(pg_database_size('postgres')) AS db_total,
  pg_size_pretty(pg_relation_size('public.quotes')) AS quotes_size,
  pg_size_pretty(pg_relation_size('public.books')) AS books_size,
  pg_size_pretty(pg_relation_size('public.cards')) AS cards_size;
```

**Q5. slow_queries** — 느린 쿼리 상위 5개
```sql
SELECT LEFT(query, 80) AS preview, calls, round(mean_exec_time::numeric, 2) AS avg_ms
FROM pg_stat_statements
ORDER BY mean_exec_time DESC LIMIT 5;
```

**Q6. suspicious_activity** — 의심 활동 (4절)

### 6-2. 마이그레이션 안전 패턴
```sql
-- 백업 후 적용 + idempotent + transaction
BEGIN;
ALTER TABLE public.quotes
  ADD COLUMN IF NOT EXISTS language text DEFAULT 'ko';
SELECT column_name FROM information_schema.columns
WHERE table_name = 'quotes' AND column_name = 'language';
COMMIT;
```

적용:
```powershell
printf 'y\n' | npx --yes supabase db push
```

### 6-3. 솔로 개발자 모니터링 자동화
- **Supabase 내장 알림**: Dashboard > Settings > Alerts. DB 용량 80% / 프로젝트 pausing 예고.
- **UptimeRobot** (무료): 5분 간격 Edge Function 헬스체크. JWT 없이 호출하면 401 응답이 와야 정상:
  - URL: `https://ndbvptxwznogcuuumzzh.supabase.co/functions/v1/aladin-search`
- **GitHub Issues로 incident log**: `incident` 라벨 + 날짜·증상·원인·조치·재발 방지 기록.

### 6-4. Pro Plan 업그레이드 시점
| 조건 | 행동 |
|---|---|
| DB 용량 400MB 초과 (한도 500MB) | Pro |
| 사용자 100명 이상 | Pro (백업 복원 UI 보장) |
| Project pausing 경고 | Pro (Free는 7일 비활동 시 pause) |
| 복원 필요 사고 발생 | Pro + 지원팀 |

Pro Plan 비용: 월 $25 (2026 기준).

---

## 7. Cheat Sheet (한 화면 요약)

```
# 매주 수동 백업
npx --yes supabase db dump --linked --data-only -f backup/data_$(Get-Date -Format 'yyyyMMdd').sql

# 사용자 조회
Authentication > Users > 이메일 검색

# 특정 사용자 인용구 (SQL Editor)
SELECT * FROM public.quotes WHERE user_id = '<uuid>' ORDER BY created_at DESC;

# 강제 세션 종료
UPDATE auth.sessions SET not_after = now() WHERE user_id = '<uuid>';

# RLS 누락 확인
SELECT tablename FROM pg_tables WHERE schemaname='public' AND rowsecurity=false;

# DB 용량
SELECT pg_size_pretty(pg_database_size('postgres'));

# 마이그레이션 적용
printf 'y\n' | npx --yes supabase db push

# service_role key 교체
Dashboard > Settings > API > Regenerate
```

---

**Sources**:
- https://supabase.com/docs/guides/platform/backups
- https://supabase.com/docs/guides/auth/managing-user-data
- https://supabase.com/docs/guides/platform/logs
- https://supabase.com/docs/guides/database/postgres/row-level-security
- https://supabase.com/docs/reference/cli/supabase-db-dump
- https://supabase.com/docs/guides/platform/going-into-prod
- 로컬: `docs/db-schema.md`, `supabase/migrations/`
