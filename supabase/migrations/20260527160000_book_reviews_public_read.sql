-- PR29-F: 책 후기를 친구 follow 없이 공개. 콜드스타트 컨텐츠 발견성 + K-factor.
--
-- 정책 변경:
-- ① 친구 follow 조건 제거 — is_library_public=true인 사용자의 후기는 anon 포함 누구나 read
-- ② is_blocked_with 게이트 추가 — 차단된 사용자(양방향)의 후기는 안 보임 (PR25 일관성)
-- ③ 책별 공개 후기 + 작성자 프로필 join RPC — UI의 N+1 회피

-- 1. 기존 friends-only 정책 제거 + 공개 정책으로 대체 ───────────
drop policy if exists "Friends see public book_reviews" on public.book_reviews;

create policy "Anyone sees public book_reviews"
  on public.book_reviews for select
  using (
    exists (
      select 1 from public.profiles p
       where p.id = book_reviews.user_id
         and p.is_library_public = true
    )
    and not public.is_blocked_with(book_reviews.user_id)
  );

-- 2. 책별 공개 후기 RPC — 작성자 프로필 join, 본인 제외 ─────────
-- 본인 후기는 myBookReviewProvider로 별도 표시(중복 노출 방지).
-- RLS가 is_library_public + 차단 자연 게이트 → 단순 SELECT.

create or replace function public.book_reviews_by_book(p_book_id uuid)
returns table (
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
    br.user_id,
    p.display_name,
    p.avatar_url,
    br.text,
    br.created_at,
    br.updated_at
  from public.book_reviews br
  inner join public.profiles p on p.id = br.user_id
  where br.book_id = p_book_id
    and br.user_id is distinct from auth.uid()
  order by br.updated_at desc
  limit 50;
$$;

comment on function public.book_reviews_by_book is
  '책 한 권의 공개 후기 + 작성자 프로필. 본인 후기는 RPC 단에서 제외. RLS 자연 게이트.';

grant execute on function public.book_reviews_by_book(uuid) to anon, authenticated;
