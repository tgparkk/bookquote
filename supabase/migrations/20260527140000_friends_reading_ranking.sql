-- PR29-C: 내가 팔로우한 친구들의 읽은 책 권수 순위.
--
-- 본인 + 팔로위들을 한 줄씩, user_books 권수 desc 정렬해 반환.
-- 비공개 프로필 친구는 profiles SELECT RLS에 의해 자동 제외됨(LEFT JOIN profiles +
-- WHERE p.id IS NOT NULL). 친구의 user_books도 user_books_friends_read RLS(친구 +
-- is_library_public)에 의해 자동 게이트 — 비공개 서재면 권수 0으로 집계되지 않고
-- 그 친구는 결과에서 빠진다(visible_counts에 row 없음 → LEFT JOIN 결과 NULL →
-- coalesce 0 → 본인이 아니면 분리 처리 가능).
--
-- 본인(me)은 항상 포함. user_books_own RLS에 의해 본인 권수는 정확히 보임.

create or replace function public.friends_reading_ranking()
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  book_count int,
  is_me boolean
)
language sql
stable
security invoker
set search_path = public
as $$
  with me as (
    select auth.uid() as user_id
  ),
  my_friends as (
    select followee_id as user_id
    from public.follows
    where follower_id = auth.uid()
  ),
  participants as (
    select user_id, true as is_me from me
    union
    select user_id, false as is_me from my_friends
  ),
  counts as (
    select ub.user_id, count(*)::int as book_count
    from public.user_books ub
    where ub.user_id in (select user_id from participants)
    group by ub.user_id
  )
  select
    pa.user_id,
    p.display_name,
    p.avatar_url,
    coalesce(c.book_count, 0) as book_count,
    bool_or(pa.is_me) as is_me
  from participants pa
  inner join public.profiles p on p.id = pa.user_id
  left join counts c on c.user_id = pa.user_id
  group by pa.user_id, p.display_name, p.avatar_url, c.book_count
  order by coalesce(c.book_count, 0) desc nulls last,
           p.display_name asc nulls last;
$$;

comment on function public.friends_reading_ranking is
  '본인 + 팔로위들의 user_books 권수 순위. RLS 자연 게이트 — 비공개 프로필·비공개 서재 친구는 자동 제외(본인 제외).';

grant execute on function public.friends_reading_ranking() to authenticated;
