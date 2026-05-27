-- PR29-G: book_reviews_by_book이 본인 후기도 포함하도록 변경.
--
-- PR29-F에서 본인 후기는 myBookReviewProvider로 별도 표시하기 위해 RPC에서
-- 제외했다. 하지만 UI 분리("내 후기" vs "독자 후기") 자체가 사용자 인지에
-- 부담이라 "이 책 후기" 한 섹션으로 통합. RPC도 본인 포함 + 정렬 시 본인 우선.
--
-- RLS는 그대로(본인 owner-policy + 타인 public-policy). 반환 타입 동일.

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
  order by
    (br.user_id = auth.uid()) desc,  -- 본인 후기 맨 위
    br.updated_at desc
  limit 50;
$$;
