-- 책귀 — cards 테이블 (Stage 3 PR11)
--
-- 공유 성공 시 비차단으로 INSERT되는 공유 이력. 인용구·책·디자인 스냅샷.
-- update/delete 없음 (V1) — 카드는 "공유한 순간"의 immutable 기록.
-- 탈퇴 시 cascade로 함께 삭제(스토어 가이드라인 ⑤.1.1(v) 정합).
-- 인용구가 삭제되면 카드도 같이 삭제(orphan 방지).
-- 책이 삭제돼도 카드는 살아남는다(design jsonb에 시점 메타가 남음) — set null.
-- 화면 노출: V1엔 직접 없음. 분석·V1.5 "내가 만든 카드 갤러리" 기반.

create table if not exists public.cards (
  id        uuid        primary key default gen_random_uuid(),
  user_id   uuid        not null references auth.users(id) on delete cascade,
  quote_id  uuid        not null references public.quotes(id) on delete cascade,
  book_id   uuid                 references public.books(id) on delete set null,
  design    jsonb       not null,          -- {templateId, ratio, watermarkEnabled} (PR12에서 fontStep/textAnchor 등 확장)
  shared_at timestamptz not null default now()
);

comment on table public.cards is '공유한 카드의 이력 (immutable). design jsonb로 시점의 디자인 스냅샷.';

-- ── 인덱스 ─────────────────────────────────────────────────
-- 향후 "내가 만든 카드 갤러리" cursor 페이지네이션 = (user_id, shared_at desc, id desc)
create index if not exists cards_user_shared_idx
  on public.cards (user_id, shared_at desc, id desc);

-- ── RLS ──────────────────────────────────────────────────
alter table public.cards enable row level security;

drop policy if exists "Users see own cards" on public.cards;
create policy "Users see own cards"
  on public.cards for select
  using (auth.uid() = user_id);

drop policy if exists "Users create own cards" on public.cards;
create policy "Users create own cards"
  on public.cards for insert
  to authenticated
  with check (auth.uid() = user_id);

-- update/delete 정책 없음 — V1은 immutable. 필요해지면 별도 PR.
