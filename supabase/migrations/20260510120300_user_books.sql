-- 책귀 — user_books 테이블
--
-- "내 서재" — 사용자가 자기 카탈로그에 담아둔 책. (user_id, book_id)이 PK라
-- 같은 책을 두 번 담는 건 자동으로 idempotent. books는 글로벌 카탈로그라
-- 그대로 두고, 서재는 그 카탈로그 위에 사용자별 view를 얹는다.

create table if not exists public.user_books (
  user_id        uuid        not null references auth.users(id) on delete cascade,
  book_id        uuid        not null references public.books(id) on delete cascade,
  added_at       timestamptz not null default now(),
  reading_status text        not null default 'reading'
                              check (reading_status in ('reading', 'finished', 'wishlist')),
  notes          text,
  primary key (user_id, book_id)
);

comment on table public.user_books is '사용자별 책 카탈로그 (내 서재). books를 user 시점에서 고른 view.';

-- 서재 화면이 added_at desc 정렬로 페이지하므로 복합 인덱스
create index if not exists user_books_user_added_idx
  on public.user_books (user_id, added_at desc);

-- ── RLS ──────────────────────────────────────────────────
alter table public.user_books enable row level security;

drop policy if exists "Users see own library" on public.user_books;
create policy "Users see own library"
  on public.user_books for select
  using (auth.uid() = user_id);

drop policy if exists "Users add to own library" on public.user_books;
create policy "Users add to own library"
  on public.user_books for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "Users update own library" on public.user_books;
create policy "Users update own library"
  on public.user_books for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users remove from own library" on public.user_books;
create policy "Users remove from own library"
  on public.user_books for delete
  to authenticated
  using (auth.uid() = user_id);
