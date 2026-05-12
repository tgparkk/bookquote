-- 책귀 — quotes 테이블
--
-- 인용구. 한 사용자가 책에서 모은 한 구절. book_id는 nullable —
-- 오프라인 작성/ISBN 미등록 도서를 위해 manual_book_text로 대체할 수 있고,
-- 책 row가 삭제돼도 인용구는 살아남게 on delete set null.
-- 카드 디자인 상태는 여기 두지 않는다 (Stage 3 cards 테이블).
-- moods는 text[]에 enum name(영문)을 저장하고 앱이 화이트리스트를 강제 — 태그셋
-- 변경 시 마이그레이션 회피. CHECK는 source만(2종).

create table if not exists public.quotes (
  id               uuid        primary key default gen_random_uuid(),
  user_id          uuid        not null references auth.users(id) on delete cascade,
  book_id          uuid        references public.books(id) on delete set null,
  manual_book_text text,                    -- book_id 없을 때 사용자가 적은 책 이름 (V1.5 재매칭용)
  text             text        not null check (char_length(text) between 1 and 2000),
  page             int         check (page > 0),
  source           text        not null default 'manual' check (source in ('manual', 'clipboard')),
  moods            text[]      not null default '{}',
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);

comment on table public.quotes is '사용자가 책에서 모은 인용구. 카드 디자인은 별도(cards). book_id는 nullable.';

drop trigger if exists quotes_updated_at on public.quotes;
create trigger quotes_updated_at
  before update on public.quotes
  for each row execute function public.set_updated_at();

-- ── 인덱스 ─────────────────────────────────────────────────
-- 홈 피드·인용 목록의 cursor 페이지네이션 = (user_id, created_at desc, id desc)
create index if not exists quotes_user_created_idx
  on public.quotes (user_id, created_at desc, id desc);
-- 책 상세의 "이 책에서 모은 N구절"
create index if not exists quotes_user_book_idx
  on public.quotes (user_id, book_id);
-- 무드별 필터 (moods && {...})
create index if not exists quotes_moods_gin_idx
  on public.quotes using gin (moods);

-- ── RLS ──────────────────────────────────────────────────
alter table public.quotes enable row level security;

drop policy if exists "Users see own quotes" on public.quotes;
create policy "Users see own quotes"
  on public.quotes for select
  using (auth.uid() = user_id);

drop policy if exists "Users create own quotes" on public.quotes;
create policy "Users create own quotes"
  on public.quotes for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users update own quotes" on public.quotes;
create policy "Users update own quotes"
  on public.quotes for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users delete own quotes" on public.quotes;
create policy "Users delete own quotes"
  on public.quotes for delete
  to authenticated
  using (auth.uid() = user_id);
