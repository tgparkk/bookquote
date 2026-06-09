-- PR-PA: FCM 디바이스 토큰 + 푸시 환경설정.
--
-- ① device_tokens — 디바이스별 FCM 등록 토큰. token이 전역 PK(한 기기 1행). 계정
--    전환 시 같은 토큰의 소유자를 갱신해야 하는데, RLS update는 기존 행 소유자
--    검사 때문에 막힌다 → 등록은 SECURITY DEFINER RPC로 upsert(소유자 재지정).
--    조회·삭제(로그아웃)는 본인 것만 RLS로.
-- ② profiles 푸시 토글 — 마스터 + 타입별. 기본 ON(런타임 POST_NOTIFICATIONS 권한이
--    실질 opt-in 게이트). Edge Function이 발송 전 이 값을 본다.

-- 1. device_tokens ─────────────────────────────────────────
create table if not exists public.device_tokens (
  token      text        primary key,
  user_id    uuid        not null references auth.users(id) on delete cascade,
  platform   text        not null check (platform in ('android', 'ios')),
  updated_at timestamptz not null default now()
);

comment on table public.device_tokens is
  'PR-PA FCM 등록 토큰(기기당 1행, token PK). 등록은 register_device_token RPC(DEFINER), 조회·삭제는 본인 RLS.';

create index if not exists device_tokens_user_idx
  on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;

drop policy if exists "see own device_tokens" on public.device_tokens;
create policy "see own device_tokens"
  on public.device_tokens for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "delete own device_tokens" on public.device_tokens;
create policy "delete own device_tokens"
  on public.device_tokens for delete
  to authenticated
  using (user_id = auth.uid());
-- insert/update 정책 없음 — 등록은 register_device_token(DEFINER) 단일 경로.

-- 2. 등록 RPC (SECURITY DEFINER — 계정 전환 시 토큰 소유자 재지정) ──
create or replace function public.register_device_token(p_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated';
  end if;
  if p_platform not in ('android', 'ios') then
    raise exception 'invalid platform: %', p_platform;
  end if;
  insert into public.device_tokens (token, user_id, platform)
  values (p_token, auth.uid(), p_platform)
  on conflict (token) do update
    set user_id = excluded.user_id,
        platform = excluded.platform,
        updated_at = now();
end;
$$;

comment on function public.register_device_token is
  'PR-PA FCM 토큰 등록/갱신. DEFINER로 계정 전환 시 토큰 소유자 재지정. auth.uid() 강제.';

-- DEFINER 함수는 호출자 게이트가 없으므로 authenticated에게만 실행 부여(anon 차단).
revoke execute on function public.register_device_token(text, text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;

-- 3. profiles 푸시 토글 ─────────────────────────────────────
alter table public.profiles
  add column if not exists push_enabled     boolean not null default true,
  add column if not exists push_quote_like  boolean not null default true,
  add column if not exists push_review_like boolean not null default true,
  add column if not exists push_follow       boolean not null default true;

comment on column public.profiles.push_enabled is
  'PR-PA 푸시 마스터 토글. false면 Edge Function이 발송 skip. 기본 ON(OS 권한이 실질 게이트).';
