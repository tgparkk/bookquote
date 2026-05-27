-- PR29-I: 홈 "최근 독자 후기" row용 RPC.
--
-- 본인 외 공개 프로필 사용자의 최신 후기 N개 + 작성자 프로필 + 책(title/cover_url).
-- 본인 후기는 제외 — 이 row의 목적이 "모르는 사람의 발견"이라 본인 자기 후기 노출은
-- 의미 없음. 본인 후기는 책 상세에서 확인.
--
-- RLS 자연 게이트(book_reviews의 'Anyone sees public book_reviews' 정책)가
-- is_library_public + 차단 안 됨 검사. 미로그인도 호출 가능.

create or replace function public.recent_public_book_reviews(p_limit int default 10)
returns table (
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

grant execute on function public.recent_public_book_reviews(int) to anon, authenticated;
