-- 책귀 — user_crypto_envelopes 테이블 (PR16-A)
--
-- "잠금 비밀번호"로 PBKDF2-HMAC-SHA512(600k) wrap_key 파생 → 마스터키 K(32B 랜덤)를
-- AES-256-GCM으로 wrap. K_wrapped만 서버에 저장 — 비밀번호 모르면 운영자(service_role,
-- pg_dump, Supabase Studio)도 못 풂.
-- 사용자 1명당 1 row (lazy 생성, 첫 잠금 시도 시점). RLS 본인만.
-- kdf_version smallint로 V2 KDF(예: Argon2id) 회수 슬롯 확보.
--
-- 비밀번호 변경 시: K는 그대로, salt + wrap_nonce + wrapped_key만 새로 만든다.
-- → 인용구 재암호화 0.
--
-- 설계: docs/DECISIONS.md 2026-05-17 "인용구 선택적 E2EE 도입".

create table if not exists public.user_crypto_envelopes (
  user_id        uuid        primary key references auth.users(id) on delete cascade,
  wrapped_key    bytea       not null,
  wrap_nonce     bytea       not null check (octet_length(wrap_nonce) = 12),
  kdf_salt       bytea       not null check (octet_length(kdf_salt) = 16),
  kdf_iters      int         not null check (kdf_iters >= 100000),
  kdf_version    smallint    not null default 1,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

comment on table public.user_crypto_envelopes is 'E2EE 마스터키의 password-wrapped envelope. 비밀번호 변경 시 wrap만 다시 — 인용구 재암호화 0. 비밀번호 분실 시 서버에 복구 수단 없음.';
comment on column public.user_crypto_envelopes.wrapped_key is 'AES-256-GCM(wrap_key)으로 wrap된 마스터키 K. (ciphertext || tag 16B).';
comment on column public.user_crypto_envelopes.wrap_nonce is 'wrapped_key의 AES-GCM nonce (12B).';
comment on column public.user_crypto_envelopes.kdf_salt is 'PBKDF2 salt (16B).';
comment on column public.user_crypto_envelopes.kdf_iters is 'PBKDF2 iteration count (V1=600000, OWASP 2024 권고).';
comment on column public.user_crypto_envelopes.kdf_version is 'KDF 알고리즘 버전 (V1=1: PBKDF2-HMAC-SHA512). V2 회수용 슬롯.';

drop trigger if exists user_crypto_envelopes_updated_at on public.user_crypto_envelopes;
create trigger user_crypto_envelopes_updated_at
  before update on public.user_crypto_envelopes
  for each row execute function public.set_updated_at();

-- ── RLS ──────────────────────────────────────────────────
alter table public.user_crypto_envelopes enable row level security;

drop policy if exists "Users see own envelope" on public.user_crypto_envelopes;
create policy "Users see own envelope"
  on public.user_crypto_envelopes for select
  using (auth.uid() = user_id);

drop policy if exists "Users create own envelope" on public.user_crypto_envelopes;
create policy "Users create own envelope"
  on public.user_crypto_envelopes for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users update own envelope" on public.user_crypto_envelopes;
create policy "Users update own envelope"
  on public.user_crypto_envelopes for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- delete 정책 없음 — auth.users on delete cascade로만 삭제(탈퇴 시).
