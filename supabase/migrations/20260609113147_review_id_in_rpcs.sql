-- PR-LC: 후기 RPC가 review_likes FK 타깃인 book_reviews.id를 반환하도록 확장.
--
-- 좋아요는 review_id(=book_reviews.id)가 있어야 누른다. 기존 RPC
-- (book_reviews_by_book / recent_public_book_reviews)는 id를 안 줘서 클라가 좋아요
-- 타깃을 못 잡았다. 반환 컬럼 추가 = 반환 타입 변경 → create or replace 불가,
-- drop + create. 본문·정렬·게이트는 기존과 동일하고 첫 컬럼에 br.id만 추가.

-- ── 1. book_reviews_by_book — id 추가 ──────────────────────
drop function if exists public.book_reviews_by_book(uuid);
create function public.book_reviews_by_book(p_book_id uuid)
returns table (
  id uuid,
  user_id uuid,
  display_name text,
  avatar_url text,
  text text,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    br.id,
    br.user_id,
    p.display_name,
    p.avatar_url,
    br.text,
    br.created_at,
    br.updated_at
  from public.book_reviews br
  inner join public.profiles p on p.id = br.user_id
  where br.book_id = p_book_id
  order by
    (br.user_id = auth.uid()) desc,  -- 본인 후기 맨 위
    br.updated_at desc
  limit 50;
$$;

comment on function public.book_reviews_by_book is
  '책 한 권의 후기(본인 포함, 본인 우선) + 작성자 프로필 + review_likes용 id. RLS 자연 게이트.';

grant execute on function public.book_reviews_by_book(uuid) to anon, authenticated;

-- ── 2. recent_public_book_reviews — id 추가 ────────────────
drop function if exists public.recent_public_book_reviews(int);
create function public.recent_public_book_reviews(p_limit int default 10)
returns table (
  id uuid,
  user_id uuid,
  display_name text,
  avatar_url text,
  book_id uuid,
  book_title text,
  book_cover_url text,
  text text,
  updated_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    br.id,
    br.user_id,
    p.display_name,
    p.avatar_url,
    br.book_id,
    b.title as book_title,
    b.cover_url as book_cover_url,
    br.text,
    br.updated_at
  from public.book_reviews br
  inner join public.profiles p on p.id = br.user_id
  inner join public.books b on b.id = br.book_id
  where br.user_id is distinct from auth.uid()
  order by br.updated_at desc
  limit greatest(1, least(coalesce(p_limit, 10), 50));
$$;

comment on function public.recent_public_book_reviews is
  '본인 외 공개 후기 최신 N개 + 작성자 프로필 + 책 + review_likes용 id. RLS 자연 게이트.';

grant execute on function public.recent_public_book_reviews(int) to anon, authenticated;
