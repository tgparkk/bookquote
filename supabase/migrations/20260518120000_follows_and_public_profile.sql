-- 책귀 — follows 단방향 친구 그래프 + profiles 공개 정책 (PR18-A)
--
-- 근거: DECISIONS 2026-05-17 "친구 서재 탐험 V1.0 합류" + 2026-05-18 "P0/P1 흡수".
--
-- 핵심 결정:
-- ① 단방향 follow (트위터식, request-accept 없음)
-- ② profiles.is_library_public bool default false — 공개 토글, 기본 비공개 사수(opt-in)
-- ③ profiles.public_handle text unique — V1.0 미사용 슬롯, V1.0.1 "@핸들" 검색 hotfix 대비
-- ④ profiles SELECT RLS 좁힘 — 비공개 프로필은 검색·/u/:userId에 0 row (본명 노출 원천 차단)
-- ⑤ quotes_friends_read / user_books_friends_read RLS (SELECT OR 추가) — 친구 + 공개 +
--    (잠금 quotes.is_private=false). 잠금 hard exclude를 RLS 안에서 DB 단으로 강제 →
--    클라이언트 fallback 0 (DB가 막음 = 신뢰 단일 출처).
-- ⑥ follows self-only RLS — 제3자의 follow 그래프는 사생활.

-- 1. profiles 확장 ─────────────────────────────────────────
alter table public.profiles
  add column if not exists is_library_public boolean not null default false;

comment on column public.profiles.is_library_public is
  '친구 서재 탐험 게이트. true일 때만 친구가 user_books/quotes read 가능. 기본 false (opt-in).';

alter table public.profiles
  add column if not exists public_handle text unique;

comment on column public.profiles.public_handle is
  'V1.0 미사용 슬롯. V1.0.1 hotfix에서 "@핸들" 검색 경로로 활성화 예정 (DECISIONS 2026-05-18 P1). 미리 unique 박아 핸들 점거 사고 0.';

-- 2. profiles SELECT RLS 좁힘 ──────────────────────────────
-- DECISIONS 2026-05-18 P0: 비공개 프로필이 검색·/u/:userId에 0 row로 응답해
-- 본명 노출 원천 차단. 본인은 항상 자기 프로필 read 가능.
-- 기존 정책 "Profiles are viewable by everyone" (using true)을 대체.
drop policy if exists "Profiles are viewable by everyone" on public.profiles;
drop policy if exists "Profiles are viewable when public or self" on public.profiles;
create policy "Profiles are viewable when public or self"
  on public.profiles for select
  using (is_library_public = true or id = auth.uid());

-- 3. follows 테이블 ─────────────────────────────────────────
create table if not exists public.follows (
  follower_id  uuid not null references auth.users(id) on delete cascade,
  followee_id  uuid not null references auth.users(id) on delete cascade,
  created_at   timestamptz not null default now(),
  primary key (follower_id, followee_id),
  check (follower_id <> followee_id)
);

comment on table public.follows is
  '단방향 친구 그래프 (트위터식). follower → followee. 자기 자신 follow 차단(CHECK). cascade × 2로 탈퇴 시 자동 정리.';

-- 4. follows 역방향 인덱스 ──────────────────────────────────
-- 정방향(내가 누구를 팔로우)은 PK가 자동 인덱싱.
-- 역방향(누가 나를 팔로우) + quotes_friends_read의 서브쿼리 가속.
create index if not exists follows_followee_idx
  on public.follows (followee_id);

-- 5. follows RLS ────────────────────────────────────────────
alter table public.follows enable row level security;

drop policy if exists "Users see own follow rows" on public.follows;
create policy "Users see own follow rows"
  on public.follows for select
  using (auth.uid() = follower_id or auth.uid() = followee_id);

drop policy if exists "Users create own follows" on public.follows;
create policy "Users create own follows"
  on public.follows for insert
  to authenticated
  with check (auth.uid() = follower_id);

drop policy if exists "Users delete own follows" on public.follows;
create policy "Users delete own follows"
  on public.follows for delete
  to authenticated
  using (auth.uid() = follower_id);

-- update 정책 없음 — created_at 외 변경할 게 없음. 강제 언팔(피팔로워가 끊기)은
-- V1.5 blocks 도입 시 추가.

-- 6. quotes_friends_read RLS (SELECT OR 추가) ───────────────
-- 친구 + 공개 프로필 + 잠금 아닌 인용구만 read. 기존 "Users see own quotes"는 유지 —
-- Supabase RLS는 동일 명령 여러 정책을 OR로 합치므로 본인 + 친구 동시 조회 가능.
drop policy if exists "Friends see public unlocked quotes" on public.quotes;
create policy "Friends see public unlocked quotes"
  on public.quotes for select
  using (
    auth.uid() in (
      select follower_id from public.follows where followee_id = quotes.user_id
    )
    and exists (
      select 1 from public.profiles p
       where p.id = quotes.user_id
         and p.is_library_public = true
    )
    and quotes.is_private = false
  );

-- 7. user_books_friends_read RLS (SELECT OR 추가) ───────────
-- 공개 프로필이면 책은 전부 노출(별도 게이트 컬럼 없음).
drop policy if exists "Friends see public user_books" on public.user_books;
create policy "Friends see public user_books"
  on public.user_books for select
  using (
    auth.uid() in (
      select follower_id from public.follows where followee_id = user_books.user_id
    )
    and exists (
      select 1 from public.profiles p
       where p.id = user_books.user_id
         and p.is_library_public = true
    )
  );
