-- 책귀 — profiles 테이블
--
-- auth.users는 Supabase Auth가 관리하므로 그대로 두고, 앱에서 자유롭게
-- 읽고 수정할 수 있는 표시 정보(닉네임, 아바타)를 별도 테이블로 둔다.
-- 회원가입 시 트리거가 빈 프로필을 자동 생성한다.

-- 1. 테이블 ────────────────────────────────────────────────
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

comment on table public.profiles is '사용자 표시 프로필 (닉네임/아바타). auth.users 1:1 미러.';

-- 2. updated_at 자동 갱신 ───────────────────────────────────
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_updated_at on public.profiles;
create trigger profiles_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- 3. 회원가입 시 프로필 자동 생성 ─────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      split_part(new.email, '@', 1)
    )
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 4. RLS ──────────────────────────────────────────────────
alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by everyone" on public.profiles;
create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

-- 5. 인덱스 ───────────────────────────────────────────────
create index if not exists profiles_display_name_idx
  on public.profiles (display_name);
