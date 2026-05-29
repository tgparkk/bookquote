-- 책귀 — 친구가 최근 담은 책 RPC ("활동" 탭 "친구가 읽은 책" 섹션)
--
-- friend_recent_activity(인용구) 패턴을 그대로 본뜸. 친구가 서재에 최근 담은
-- 책 N개 + 작성자 프로필 + 책(title/cover_url). 본인 책은 제외 — 이 피드의
-- 목적이 "친구가 무엇을 읽는지 발견"이라 자기 서재는 의미 없음(서재 탭에서 확인).
--
-- 보안: SECURITY INVOKER — user_books/profiles/books RLS가 자연 게이트.
-- user_books_friends_read 정책(팔로우 + 상대 is_library_public)이 통과한 row만
-- 반환. RPC 안에서 추가 필터 0(정책 드리프트 차단). 본인 제외만 명시.
--
-- 반환: setof record (user_id, display_name, avatar_url, book_id, book_title,
-- book_cover_url, added_at). 호출자가 빈 결과 시 섹션 숨김.

create or replace function public.friend_recent_books(p_limit int default 20)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  book_id uuid,
  book_title text,
  book_cover_url text,
  added_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    ub.user_id,
    p.display_name,
    p.avatar_url,
    ub.book_id,
    b.title as book_title,
    b.cover_url as book_cover_url,
    ub.added_at
  from public.user_books ub
  inner join public.profiles p on p.id = ub.user_id
  inner join public.books b on b.id = ub.book_id
  where ub.user_id is distinct from auth.uid()
  order by ub.added_at desc
  limit greatest(1, least(coalesce(p_limit, 20), 50));
$$;

grant execute on function public.friend_recent_books(int) to authenticated;

comment on function public.friend_recent_books is
  '활동 탭 — 친구가 최근 담은 책 N개. SECURITY INVOKER로 user_books_friends_read + profiles_public_select RLS 자연 게이트. 본인 제외.';
