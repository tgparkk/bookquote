-- PR-LA: 인용구·후기 좋아요 (quote_likes / review_likes)
--
-- 근거: 2026-06-09 매니저 모드 4팀 협의 결정(DECISIONS 동일 날짜). 좋아요는 인용구·
-- 후기 두 객체 모두 대상. 알림 백본(PR-NA)·FCM(PR-NC)은 후속 마이그레이션.
--
-- 핵심 설계:
-- ① 폴리모픽 단일 테이블 금지 — quote_likes / review_likes 2개로 분리(FK·RLS 단순).
-- ② 후기는 PK가 (user_id, book_id) 복합키라 FK 타깃 없음 → book_reviews에 surrogate
--    id(unique) 추가. 1책당 1개 불변식은 기존 PK 유지, id는 FK용 alt key.
-- ③ 멱등 PK (target_id, liker_id) — 더블탭·오프라인 재전송 무해.
-- ④ INSERT는 "그 대상을 read 가능 + 본인 것 아님"만 — 하위 exists가 quotes/
--    book_reviews RLS를 그대로 상속 → 차단·잠금·비공개·비공개프로필·self-like가
--    한 subquery로 게이트(정책 드리프트 0, 별도 차단 필터 추가 금지).
-- ⑤ liker 프라이버시(A안): 앱은 "누가 눌렀나" 목록을 절대 표시하지 않는다. SELECT는
--    카운트 RPC(INVOKER) 자연 집계용으로만 허용 — 카운트 RPC가 liker_id를 절대 반환
--    안 함. 본인 콘텐츠엔 좋아요 버튼 미노출 + 카운트만(작성 위축 방어).
-- ⑥ cascade ×2 — 대상/계정 삭제 시 좋아요 자동 정리(orphan 0).

-- ── 1. book_reviews surrogate id ───────────────────────────
-- 1책당 1개 PK(user_id, book_id)는 유지. id는 review_likes FK 타깃용 unique alt key.
-- 기존 행은 default gen_random_uuid()로 자동 채워짐. FK는 unique '제약'을 요구하므로
-- create unique index가 아니라 add constraint로(quotes_text_xor_encrypted와 동일 패턴).
alter table public.book_reviews
  add column if not exists id uuid not null default gen_random_uuid();

alter table public.book_reviews drop constraint if exists book_reviews_id_key;
alter table public.book_reviews add constraint book_reviews_id_key unique (id);

comment on column public.book_reviews.id is
  'review_likes FK 타깃용 surrogate unique key. 1책당 1개 불변식은 PK(user_id, book_id)가 계속 강제.';

-- ── 2. quote_likes ─────────────────────────────────────────
create table if not exists public.quote_likes (
  quote_id   uuid        not null references public.quotes(id) on delete cascade,
  liker_id   uuid        not null references auth.users(id)    on delete cascade,
  created_at timestamptz not null default now(),
  primary key (quote_id, liker_id)
);

comment on table public.quote_likes is
  '인용구 좋아요. PK(quote_id, liker_id)로 멱등. 카운트는 quote_like_counts RPC. liker 목록은 앱 미표시(프라이버시).';

-- PK 선두 컬럼이 quote_id라 카운트(where quote_id = any) 는 PK 인덱스 활용 → 별도 인덱스 불필요.

alter table public.quote_likes enable row level security;

-- SELECT: 본인이 누른 것 + (그 인용구를 read 가능한 경우의 like 행). 하위 exists가
-- quotes RLS 상속 → 카운트 RPC(INVOKER)가 가시 인용구의 좋아요만 집계. RPC는 liker_id를
-- 반환하지 않으므로 목록 노출 0(A안).
drop policy if exists "see quote_likes of visible quotes" on public.quote_likes;
create policy "see quote_likes of visible quotes"
  on public.quote_likes for select
  using (
    liker_id = auth.uid()
    or exists (select 1 from public.quotes q where q.id = quote_id)
  );

-- INSERT: 본인 + 그 인용구 read 가능 + 본인 인용구 아님(self-like 차단).
drop policy if exists "create own quote_likes" on public.quote_likes;
create policy "create own quote_likes"
  on public.quote_likes for insert
  to authenticated
  with check (
    liker_id = auth.uid()
    and exists (
      select 1 from public.quotes q
       where q.id = quote_id and q.user_id <> liker_id
    )
  );

drop policy if exists "delete own quote_likes" on public.quote_likes;
create policy "delete own quote_likes"
  on public.quote_likes for delete
  to authenticated
  using (liker_id = auth.uid());

-- ── 3. review_likes ────────────────────────────────────────
create table if not exists public.review_likes (
  review_id  uuid        not null references public.book_reviews(id) on delete cascade,
  liker_id   uuid        not null references auth.users(id)          on delete cascade,
  created_at timestamptz not null default now(),
  primary key (review_id, liker_id)
);

comment on table public.review_likes is
  '후기 좋아요. PK(review_id, liker_id)로 멱등. book_reviews.id(unique) 참조. 카운트는 review_like_counts RPC.';

alter table public.review_likes enable row level security;

drop policy if exists "see review_likes of visible reviews" on public.review_likes;
create policy "see review_likes of visible reviews"
  on public.review_likes for select
  using (
    liker_id = auth.uid()
    or exists (select 1 from public.book_reviews r where r.id = review_id)
  );

drop policy if exists "create own review_likes" on public.review_likes;
create policy "create own review_likes"
  on public.review_likes for insert
  to authenticated
  with check (
    liker_id = auth.uid()
    and exists (
      select 1 from public.book_reviews r
       where r.id = review_id and r.user_id <> liker_id
    )
  );

drop policy if exists "delete own review_likes" on public.review_likes;
create policy "delete own review_likes"
  on public.review_likes for delete
  to authenticated
  using (liker_id = auth.uid());

-- ── 4. 카운트 RPC (SECURITY INVOKER + 자연 게이트) ──────────
-- 리스트의 id 배열을 한 번에 집계(N+1 회피). SELECT RLS가 가시성 게이트 →
-- 안 보이는 대상은 0 row로 빠짐(클라가 0으로 처리). liked_by_me는 본인 like 행이
-- 항상 보이므로 정확. liker_id는 절대 반환하지 않음(A안 프라이버시).

create or replace function public.quote_like_counts(p_ids uuid[])
returns table (quote_id uuid, n bigint, liked_by_me boolean)
language sql
stable
security invoker
set search_path = public
as $$
  select ql.quote_id,
         count(*)::bigint as n,
         bool_or(ql.liker_id = auth.uid()) as liked_by_me
    from public.quote_likes ql
   where ql.quote_id = any(p_ids)
   group by ql.quote_id;
$$;

comment on function public.quote_like_counts is
  '인용구 id 배열별 좋아요 수 + 본인 누름 여부. INVOKER로 quote_likes SELECT RLS 자연 게이트. liker_id 미반환.';

create or replace function public.review_like_counts(p_ids uuid[])
returns table (review_id uuid, n bigint, liked_by_me boolean)
language sql
stable
security invoker
set search_path = public
as $$
  select rl.review_id,
         count(*)::bigint as n,
         bool_or(rl.liker_id = auth.uid()) as liked_by_me
    from public.review_likes rl
   where rl.review_id = any(p_ids)
   group by rl.review_id;
$$;

comment on function public.review_like_counts is
  '후기 id 배열별 좋아요 수 + 본인 누름 여부. INVOKER로 review_likes SELECT RLS 자연 게이트. liker_id 미반환.';

grant execute on function public.quote_like_counts(uuid[])  to anon, authenticated;
grant execute on function public.review_like_counts(uuid[]) to anon, authenticated;
