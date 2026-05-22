-- 책글귀 — 신고·차단 (PR25, Google Play UGC 정책 대응)
--
-- 친구 기능(PR18)으로 사용자끼리 인용구·프로필이 보이므로 Google Play
-- 사용자 제작 콘텐츠(UGC) 정책상 ① 신고 ② 차단 수단이 필수다. 본 마이그레이션이 둘을 추가한다.
--
-- 핵심:
-- ① reports — 신고 적재 테이블. reporter만 본인 row insert/select. 운영자(개발자) 수동 검토.
-- ② blocks — 차단 그래프. blocker → blocked 단방향 저장, 효과는 양방향.
-- ③ is_blocked_with(other) — SECURITY DEFINER. RLS 정책 안에서 "auth.uid()와 other
--    사이에 (어느 방향이든) 차단이 있는가" 판정. blocks RLS를 우회해 양방향 검사하되,
--    "누가 나를 차단했는지"는 blocks 직접 select로는 여전히 비노출.
-- ④ 기존 친구 RLS 5종에 not is_blocked_with(...) 추가 — 차단한 상대의 프로필·인용구·
--    책·follow 그래프가 서로 0 row.
-- ⑤ blocks insert 트리거가 양방향 follow row 삭제 — 차단 = 즉시 언팔 강제.
-- ⑥ list_blocked_profiles() — 차단한 상대 프로필은 ④의 RLS가 가리므로, 차단 목록
--    화면용 표시 정보(id/이름/아바타)를 SECURITY DEFINER RPC로 가져온다.

-- 1. reports ────────────────────────────────────────────────
create table if not exists public.reports (
  id                uuid        primary key default gen_random_uuid(),
  reporter_id       uuid        not null references auth.users(id) on delete cascade,
  reported_user_id  uuid        references auth.users(id) on delete cascade,
  reported_quote_id uuid        references public.quotes(id) on delete cascade,
  reason            text        not null,
  detail            text,
  status            text        not null default 'pending',
  created_at        timestamptz not null default now(),
  check (reported_user_id is not null or reported_quote_id is not null)
);

comment on table public.reports is
  'PR25 — 사용자/인용구 신고 적재. reporter만 본인 row insert·select. 운영자가 수동 검토(status).';

create index if not exists reports_created_idx on public.reports (created_at desc);

alter table public.reports enable row level security;

drop policy if exists "Users create own reports" on public.reports;
create policy "Users create own reports"
  on public.reports for insert
  to authenticated
  with check (auth.uid() = reporter_id);

drop policy if exists "Users see own reports" on public.reports;
create policy "Users see own reports"
  on public.reports for select
  to authenticated
  using (auth.uid() = reporter_id);

-- 2. blocks ─────────────────────────────────────────────────
create table if not exists public.blocks (
  blocker_id uuid        not null references auth.users(id) on delete cascade,
  blocked_id uuid        not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

comment on table public.blocks is
  'PR25 — 차단 그래프. blocker → blocked 단방향 저장, 효과는 is_blocked_with로 양방향. blocker만 select(차단 목록)/insert/delete(해제).';

create index if not exists blocks_blocked_idx on public.blocks (blocked_id);

alter table public.blocks enable row level security;

drop policy if exists "Users see own blocks" on public.blocks;
create policy "Users see own blocks"
  on public.blocks for select
  to authenticated
  using (auth.uid() = blocker_id);

drop policy if exists "Users create own blocks" on public.blocks;
create policy "Users create own blocks"
  on public.blocks for insert
  to authenticated
  with check (auth.uid() = blocker_id);

drop policy if exists "Users delete own blocks" on public.blocks;
create policy "Users delete own blocks"
  on public.blocks for delete
  to authenticated
  using (auth.uid() = blocker_id);

-- 3. is_blocked_with(other) ──────────────────────────────────
-- SECURITY DEFINER로 blocks RLS를 우회해 양방향 차단을 판정. RLS 정책 전용 헬퍼.
create or replace function public.is_blocked_with(other uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.blocks b
     where (b.blocker_id = auth.uid() and b.blocked_id = other)
        or (b.blocker_id = other and b.blocked_id = auth.uid())
  );
$$;

comment on function public.is_blocked_with is
  'PR25 — auth.uid()와 other 사이 (어느 방향이든) 차단 존재 시 true. RLS 정책 안에서 양방향 차단 게이트로 사용.';

-- 4. blocks insert 시 양방향 follow 자동 삭제 ─────────────────
create or replace function public.blocks_cleanup_follows()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from public.follows
   where (follower_id = new.blocker_id and followee_id = new.blocked_id)
      or (follower_id = new.blocked_id and followee_id = new.blocker_id);
  return new;
end;
$$;

comment on function public.blocks_cleanup_follows is
  'PR25 — 차단 시 두 사용자 사이 follow row를 양방향 삭제(차단=즉시 언팔). SECURITY DEFINER로 상대방 follow row까지 정리.';

drop trigger if exists blocks_remove_follows on public.blocks;
create trigger blocks_remove_follows
  after insert on public.blocks
  for each row execute function public.blocks_cleanup_follows();

-- 5. 기존 친구 RLS 5종에 차단 필터 추가 ───────────────────────
-- drop + create로 재정의. 정책 본문은 기존(20260518/20260519)과 동일하고
-- 마지막에 not public.is_blocked_with(...)만 AND로 덧붙인다.

-- 5-1. profiles SELECT (20260518) — 본인 또는 (공개 + 미차단)
drop policy if exists "Profiles are viewable when public or self" on public.profiles;
create policy "Profiles are viewable when public or self"
  on public.profiles for select
  using (
    id = auth.uid()
    or (is_library_public = true and not public.is_blocked_with(id))
  );

-- 5-2. quotes — Friends see public unlocked quotes (20260518)
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
    and not public.is_blocked_with(quotes.user_id)
  );

-- 5-3. user_books — Friends see public user_books (20260518)
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
    and not public.is_blocked_with(user_books.user_id)
  );

-- 5-4. follows — Users see own follow rows (20260518)
-- follower_id/followee_id 중 하나는 auth.uid() 자신이라 is_blocked_with(self)=false(무해),
-- 나머지 한쪽이 실제 차단 게이트.
drop policy if exists "Users see own follow rows" on public.follows;
create policy "Users see own follow rows"
  on public.follows for select
  using (
    (auth.uid() = follower_id or auth.uid() = followee_id)
    and not public.is_blocked_with(follower_id)
    and not public.is_blocked_with(followee_id)
  );

-- 5-5. follows — Follows visible when both endpoints public (20260519)
drop policy if exists "Follows visible when both endpoints public" on public.follows;
create policy "Follows visible when both endpoints public"
  on public.follows for select
  using (
    exists (
      select 1 from public.profiles p
       where p.id = follows.follower_id
         and p.is_library_public = true
    )
    and exists (
      select 1 from public.profiles p
       where p.id = follows.followee_id
         and p.is_library_public = true
    )
    and not public.is_blocked_with(follows.follower_id)
    and not public.is_blocked_with(follows.followee_id)
  );

-- friend_recent_activity RPC(20260519140000)는 security invoker라 위 quotes/profiles
-- 정책을 자연 상속 — 차단한 친구의 활동은 자동 제외. 별도 수정 불필요.

-- 6. list_blocked_profiles() — 차단 목록 화면용 ─────────────
-- 5-1의 RLS가 차단한 상대 프로필을 가리므로, 차단 목록에 이름·아바타를 띄우려면
-- SECURITY DEFINER로 우회한다. 호출자가 차단한 row만 반환하므로 노출 위험 없음.
create or replace function public.list_blocked_profiles()
returns table (
  id           uuid,
  display_name text,
  avatar_url   text
)
language sql
stable
security definer
set search_path = public
as $$
  select p.id, p.display_name, p.avatar_url
    from public.blocks b
    join public.profiles p on p.id = b.blocked_id
   where b.blocker_id = auth.uid()
   order by b.created_at desc;
$$;

comment on function public.list_blocked_profiles is
  'PR25 — 내가 차단한 사용자 프로필 목록(차단 목록 화면). 호출자가 차단한 row만 반환.';
