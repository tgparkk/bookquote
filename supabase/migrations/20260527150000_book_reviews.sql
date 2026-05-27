-- PR29-D: 책 후기 (1책당 1개, 자유 감상).
--
-- 인용구는 책의 한 문장을 그대로 옮기는 것, 후기는 본인 감상문. 별도 도메인.
-- 1책당 1개 = PK가 (user_id, book_id). 수정 시 텍스트가 덮어쓰이고 created_at은
-- 보존. V1.0에는 plain text만, 5문단(~3000자) 정도 자유 감상.
--
-- 가시성 정책 (V1.0):
-- ① 본인은 항상 자기 후기를 read/insert/update/delete.
-- ② 친구 + 공개 프로필이면 read 가능 (quotes_friends_read와 동일 패턴) —
--    V1.0에는 친구 프로필에서 후기 노출은 안 하지만 RLS만 미리 깔아 V1.1에서
--    바로 활용 가능.
-- ③ E2EE 미적용 (V1.0). 후기는 본질적으로 자기 색깔이 드러나는 감상이라 본인이
--    공유하기로 결정한 경우만 친구가 보는 모델 → 잠금 분리 필요성 낮음.

create table if not exists public.book_reviews (
  user_id     uuid not null references auth.users(id) on delete cascade,
  book_id     uuid not null references public.books(id) on delete cascade,
  text        text not null check (
    length(btrim(text)) between 1 and 3000
  ),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  primary key (user_id, book_id)
);

comment on table public.book_reviews is
  '책별 1개 후기. 인용구(quotes)와 별도 도메인 — 인용구=책 문장 옮김, 후기=본인 감상.';

-- updated_at trigger (기존 set_updated_at 재사용)
drop trigger if exists book_reviews_updated_at on public.book_reviews;
create trigger book_reviews_updated_at
  before update on public.book_reviews
  for each row execute function public.set_updated_at();

-- 책별 후기 조회 (friend 프로필 read 시) 가속 — PK가 (user_id, book_id)라 book_id
-- 단독 조회는 PK 인덱스 활용 불가. 친구가 특정 책의 모든 후기를 보는 경로는 V1.0엔
-- 없지만 V1.1 대비.
create index if not exists book_reviews_book_id_idx
  on public.book_reviews (book_id);

-- ── RLS ──────────────────────────────────────────────────
alter table public.book_reviews enable row level security;

-- 본인 — 전체 CRUD
drop policy if exists "Users CRUD own book_reviews" on public.book_reviews;
create policy "Users CRUD own book_reviews"
  on public.book_reviews for all
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- 친구 read — 공개 프로필 + follow 관계 (V1.1 친구 프로필 표시 대비)
drop policy if exists "Friends see public book_reviews" on public.book_reviews;
create policy "Friends see public book_reviews"
  on public.book_reviews for select
  using (
    auth.uid() in (
      select follower_id from public.follows
       where followee_id = book_reviews.user_id
    )
    and exists (
      select 1 from public.profiles p
       where p.id = book_reviews.user_id
         and p.is_library_public = true
    )
  );
