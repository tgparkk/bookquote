# DB 설계서 — 책귀 (V1, 현재 구현 기준)

**기준일**: 2026-05-14 (Stage 2 PR1~5 반영) · **단일 진실**: `supabase/migrations/*.sql` (이 문서는 그걸 사람이 읽기 쉽게 정리한 것)
**대체 관계**: `docs/discovery/api-design.md`·`architecture.md`는 2026-05-09 Validation 단계 초안(Expo/TanStack/`supabase gen types` 시절) — 현재 스키마는 **이 문서**가 기준.

---

## 0. 원칙

- **백엔드 = Supabase Postgres + RLS**. 자체 서버 없음. 클라이언트(`supabase_flutter`)가 `from(...)` 직접 쿼리, 권한은 RLS가 DB 레벨에서 강제.
- **RPC는 꼭 필요할 때만** — 멀티 row 변경(`upsert_book`)·집계(`my_quote_mood_counts`)만. 단순 CRUD는 supabase_flutter로.
- **Edge Function** — 외부 키 은닉(`aladin-search`)·service_role 권한 필요 작업(`delete-account`)에만.
- **PK는 UUID** (books·quotes) — 알라딘이 잘못된 ISBN을 줘서 row를 교체해도 FK가 안 깨지게. `profiles`만 `auth.users.id` 1:1 미러라 PK = 그 id.
- **`updated_at`은 트리거**(`set_updated_at()`)로 자동 갱신. 클라이언트가 직접 세팅 안 함.
- **회원가입 시 `profiles` 자동 생성** — `auth.users` AFTER INSERT 트리거(`handle_new_user()`).
- **모든 사용자 데이터 테이블은 `on delete cascade auth.users`** — 회원 탈퇴 시 `auth.admin.deleteUser` 한 번으로 정리됨.
- **`moods`는 `text[]`에 enum name(영문) 저장** — 앱이 화이트리스트 강제, DB CHECK는 안 검. 무드셋 바뀌어도 마이그레이션 회피(알 수 없는 값은 파싱 시 무시).

---

## 1. ER 다이어그램 (텍스트)

```
auth.users (Supabase Auth 관리)
   │ id
   ├──1:1──▶ profiles            (display_name, avatar_url)            [on delete cascade]
   ├──1:N──▶ user_books          (book_id, added_at, reading_status, rating, notes)  [cascade]
   └──1:N──▶ quotes              (book_id?, manual_book_text?, text, page?, source, moods[])  [cascade]

books (글로벌 카탈로그 — 모든 사용자 공유, 알라딘 캐시)
   │ id
   ├──1:N──▶ user_books          (book_id FK)                          [on delete cascade]
   └──1:N──▶ quotes              (book_id FK, nullable)                [on delete set null]

user_books  PK = (user_id, book_id)        — "내 서재"
quotes      PK = id                          — "내 인용구"
profiles    PK = id (= auth.users.id)

(V1.5+ 예정: cards, received_cards, follows — §6)
```

---

## 2. 테이블

### 2.1 `profiles` — 사용자 표시 프로필 (`20260510120000`)

`auth.users` 1:1 미러. 회원가입 트리거가 빈 row 자동 생성.

| 컬럼 | 타입 | 제약 | 비고 |
|---|---|---|---|
| `id` | uuid | **PK**, `references auth.users(id) on delete cascade` | = auth 유저 id |
| `display_name` | text | | 가입 시 `raw_user_meta_data`의 `display_name`/`nickname`/`name`/`full_name`, 없으면 이메일 local-part |
| `avatar_url` | text | | OAuth provider의 `avatar_url`/`picture` (이메일 매직링크 가입이면 null) |
| `created_at` | timestamptz | not null, default `now()` | |
| `updated_at` | timestamptz | not null, default `now()` | 트리거 `profiles_updated_at` → `set_updated_at()` |

**인덱스**: `profiles_display_name_idx (display_name)`
**RLS**: SELECT = 누구나(`using (true)`) / UPDATE = 본인(`auth.uid() = id`). INSERT는 트리거만(정책 없음 → 일반 클라이언트 insert 불가, `security definer` 트리거가 우회).
**현재 사용**: 코드에서 아직 직접 읽지 않음 (Me 화면은 이메일을 세션에서 읽음). V1.5 follow/프로필 화면에서 사용 예정.

### 2.2 `books` — 글로벌 책 카탈로그 (`20260510120200`)

알라딘 검색 결과를 캐시 + 영속화. 모든 사용자 공유. 사용자 활동(서재 담기·인용구 연결) 시 `upsert_book` RPC로 채워짐.

| 컬럼 | 타입 | 제약 | 비고 |
|---|---|---|---|
| `id` | uuid | **PK**, default `gen_random_uuid()` | quotes·user_books가 참조 |
| `isbn13` | text | **not null, unique** | upsert 충돌 키 |
| `isbn10` | text | unique | |
| `title` | text | not null | |
| `author` | text | | |
| `publisher` | text | | |
| `pub_date` | text | | 알라딘이 `'YYYY-MM-DD'`·`'YYYY'` 등 자유 형식 |
| `cover_url` | text | | 알라딘 이미지 URL 직접 사용 (Storage 미러링 X) |
| `description` | text | | |
| `category_name` | text | | |
| `source` | text | not null, default `'aladin'` | |
| `source_id` | text | | 알라딘 itemId 등 |
| `created_at` / `updated_at` | timestamptz | not null, default `now()` | `books_updated_at` 트리거 |

**인덱스**: `isbn13`/`isbn10` unique 제약이 자동 인덱스 생성. (title 검색은 알라딘에 위임 — trigram 인덱스 V1엔 없음.)
**RLS**: SELECT = 누구나 / INSERT·UPDATE = `authenticated` 누구나(`with check (true)`) — 카탈로그는 공유 자원, 사용자가 메타를 채워나가는 모델.
**관련 함수**: `upsert_book(book jsonb)` (§3.3).

### 2.3 `user_books` — 내 서재 (`20260510120300` + `20260512130000`)

사용자가 자기 카탈로그에 담은 책. `(user_id, book_id)`가 PK라 같은 책 두 번 담기 = 자동 idempotent.

| 컬럼 | 타입 | 제약 | 비고 |
|---|---|---|---|
| `user_id` | uuid | not null, `references auth.users(id) on delete cascade`, **PK 일부** | |
| `book_id` | uuid | not null, `references public.books(id) on delete cascade`, **PK 일부** | |
| `added_at` | timestamptz | not null, default `now()` | |
| `reading_status` | text | not null, default `'reading'`, CHECK in (`'reading'`,`'finished'`,`'wishlist'`) | V1 UI에선 아직 노출 안 함 |
| `rating` | smallint | CHECK between 1 and 5, nullable | **별점**. 매기면 그 책이 자동으로 서재에 들어옴(upsert). null = 미평가. 반쪽 별은 V1.5 |
| `notes` | text | | 미사용(V1.5) |

**인덱스**: `user_books_user_added_idx (user_id, added_at desc)` — 서재 화면 정렬.
**RLS**: SELECT/INSERT/UPDATE/DELETE 모두 `auth.uid() = user_id` (본인 것만).
**현재 사용**: `book_repository` — `addToLibrary`/`removeFromLibrary`/`listMyLibrary`/`countMyLibrary`/`getMyRating`/`setMyRating`.

### 2.4 `quotes` — 내 인용구 (`20260512120000`)

한 사용자가 책에서 모은 한 구절. `book_id`는 nullable — 오프라인 작성/ISBN 미등록 도서는 `manual_book_text`로 대체. 책 row가 삭제돼도 인용구는 살아남음(`on delete set null`). 카드 디자인 상태는 여기 두지 않음(V1.5 `cards`).

| 컬럼 | 타입 | 제약 | 비고 |
|---|---|---|---|
| `id` | uuid | **PK**, default `gen_random_uuid()` | |
| `user_id` | uuid | not null, `references auth.users(id) on delete cascade` | |
| `book_id` | uuid | `references public.books(id) on delete set null` | nullable |
| `manual_book_text` | text | | `book_id` 없을 때 사용자가 적은 책 이름 (V1.5 재매칭용) |
| `text` | text | not null, CHECK `char_length between 1 and 2000` | 인용구 본문 |
| `page` | int | CHECK `page > 0` | 선택 |
| `source` | text | not null, default `'manual'`, CHECK in (`'manual'`,`'clipboard'`) | 입력 방식. 앱 내장 OCR 안 함 |
| `moods` | text[] | not null, default `'{}'` | enum name(영문) 저장. 화이트리스트 = `QuoteMood` (`comfort`/`wistful`/`lateNight`/`insight`/`excitement`), 한 구절 최대 3개 (앱에서 강제, DB는 안 검) |
| `created_at` / `updated_at` | timestamptz | not null, default `now()` | `quotes_updated_at` 트리거 |

**인덱스**:
- `quotes_user_created_idx (user_id, created_at desc, id desc)` — 홈 피드·인용 목록 cursor 페이지네이션
- `quotes_user_book_idx (user_id, book_id)` — 책 상세 "이 책에서 모은 N구절"
- `quotes_moods_gin_idx using gin (moods)` — 무드별 필터 (`moods && {...}`)

**RLS**: SELECT = `auth.uid() = user_id` / INSERT·UPDATE·DELETE = `authenticated` + `auth.uid() = user_id`.
**페이지네이션**: cursor-after `(created_at desc, id desc)` — `or('created_at.lt.<ts>,and(created_at.eq.<ts>,id.lt.<id>)')`로 튜플 비교 에뮬레이션. offset 안 씀.
**현재 사용**: `quote_repository` — `createQuote`/`updateQuote`/`deleteQuote`/`getById`/`listMyQuotes`/`listMyQuotesWithBook`(`*, book:books(*)` 임베드, N+1 회피)/`getMoodCounts`/`countMyQuotes`.

---

## 3. 함수 / RPC / 트리거

### 3.1 `set_updated_at()` — 트리거 함수 (`20260510120000`)
`before update`에서 `new.updated_at = now()`. `profiles`·`books`·`quotes`의 `*_updated_at` 트리거가 사용.

### 3.2 `handle_new_user()` — 회원가입 트리거 함수 (`20260510120000` → `20260510120100`에서 OAuth 호환으로 갱신)
`security definer`. `auth.users` AFTER INSERT 트리거(`on_auth_user_created`)가 호출 → `profiles` row 생성. `display_name`은 `raw_user_meta_data`의 여러 후보 키를 coalesce, 없으면 이메일 local-part(이메일도 없으면 null). `avatar_url`은 `avatar_url`/`picture`.

### 3.3 `upsert_book(book jsonb) returns public.books` — RPC (`20260510120200`)
`security invoker`. `isbn13` 충돌 시 `on conflict do update`로 메타를 **더 풍부한 쪽으로** 갱신(`coalesce(excluded.X, books.X)`). `id`는 항상 보존(FK 안 깨짐). 클라이언트: `book_repository.upsertBook(AladinBookDto)`.

### 3.4 `my_quote_mood_counts() returns table(mood text, n bigint)` — RPC (`20260512140000`)
`security invoker`, `stable`. `'__total__'` 행 = 전체 인용구 수, 나머지 = 무드 name별 개수(0인 무드는 안 나옴). `moods` 배열을 `lateral unnest`로 펼쳐 group by. RLS가 `auth.uid()` 강제 → 본인 것만. 클라이언트: `quote_repository.getMoodCounts()` → 서재 "인용구" 뷰 필터 칩 카운트.

---

## 4. 회원 탈퇴 / 데이터 삭제 (cascade)

`auth.users` row 하나 삭제 → 다음이 자동 삭제:
- `profiles` (`on delete cascade`)
- `user_books` (`on delete cascade`) — 별점·서재 항목 포함
- `quotes` (`on delete cascade`)
- (`books`는 글로벌 카탈로그라 안 지워짐 — 정상)

클라이언트는 `auth.admin.deleteUser`를 직접 못 부르므로 **Edge Function `delete-account`**가 service_role로 대행(JWT로 호출자 확인 후). → §5.
⚠️ **V1.5에 `cards`·`received_cards` 등 새 사용자 테이블을 만들 때 `on delete cascade auth.users`(또는 `quotes`)를 반드시 챙길 것** — 안 그러면 탈퇴 시 orphan.

---

## 5. Edge Functions

| 함수 | 경로 | 역할 | 상태 |
|---|---|---|---|
| `aladin-search` | `supabase/functions/aladin-search/index.ts` | 알라딘 OpenAPI 프록시 — `ALADIN_TTB_KEY` 은닉 + JWT 강제(봇 차단) + 통일 에러 envelope. `{mode:"search",query,page?,size?}` / `{mode:"lookup",isbn}` | **배포됨** |
| `delete-account` | `supabase/functions/delete-account/index.ts` | 호출자 본인 계정 영구 삭제 — Authorization JWT로 `getUser()` 확인 → service_role 클라이언트로 `auth.admin.deleteUser(user.id)` → cascade가 데이터 정리. Apple Guideline 5.1.1(v) + Google Play 요구 | **코드 작성 완료, 배포 미완** (`npx --yes supabase functions deploy delete-account` — `SUPABASE_URL`/`SUPABASE_ANON_KEY`/`SUPABASE_SERVICE_ROLE_KEY`는 Edge Function에 자동 주입이라 별도 시크릿 설정 불필요). STAGES Stage 5 |

공통: `supabase/functions/_shared/cors.ts`(CORS 헤더), `_shared/aladin.ts`(알라딘 호출 로직).

---

## 6. 마이그레이션 목록 (적용 순서)

| 파일 | 내용 | 원격 적용 |
|---|---|---|
| `20260510120000_profiles.sql` | `profiles` 테이블 + `set_updated_at()` + `handle_new_user()` + `on_auth_user_created` 트리거 + RLS + 인덱스 | ✅ |
| `20260510120100_handle_new_user_oauth.sql` | `handle_new_user()`를 OAuth(닉네임/아바타 여러 키 coalesce, email null 허용)로 갱신 | ✅ |
| `20260510120200_books.sql` | `books` 테이블 + `books_updated_at` 트리거 + RLS + `upsert_book(jsonb)` RPC | ✅ |
| `20260510120300_user_books.sql` | `user_books` 테이블 (PK `(user_id,book_id)`) + 인덱스 + RLS | ✅ |
| `20260512120000_quotes.sql` | `quotes` 테이블 + `quotes_updated_at` 트리거 + 인덱스 3종 + RLS | ✅ |
| `20260512130000_user_books_rating.sql` | `user_books.rating smallint CHECK 1~5` 컬럼 추가 | ✅ |
| `20260512140000_quote_mood_counts.sql` | `my_quote_mood_counts()` RPC | ✅ |

작업 방식: 새 마이그레이션 작성 후 `npx --yes supabase db push` (`supabase` 명령은 PATH에 없음 — `npx --yes` 사용, 프롬프트는 `printf 'y\n' |`로 통과).

---

## 7. V1.5+ 예정 (아직 테이블 없음 — 화면 설계서 참조)

- **`cards`** — 인용구별 카드 디자인 히스토리(템플릿·색·폰트·정렬). `quotes`에 `on delete cascade`. `screens/card-editor.md`·`card-share.md`.
- **`received_cards`** — deep link로 받은 카드를 내 계정에 복제한 것("받은 카드 함" — V1 홈은 "내 인용 피드"만). `screens/home.md`·`deep-link-receive.md`.
- **`follows`** — 친구 follow 그래프 + 타임라인. `screens/me.md`("친구 찾기" V1 숨김), `discovery/flows.md` Flow C·E (전부 V1.5).
- **`quote_likes`** 등 소셜 — V2.

---

## 변경 이력
- 2026-05-14 초안 — 마이그레이션 7개(`profiles`/`books`/`user_books`/`quotes`/`user_books.rating`/`my_quote_mood_counts`) + Edge Function 2개 정리. Stage 2 PR1~5 기준.
