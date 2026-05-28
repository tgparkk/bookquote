-- 친구 프로필 segment 카운트(책 N / 인용구 N) 한 round-trip RPC. PR5-A (2026-05-28).
--
-- SECURITY INVOKER — caller의 RLS가 자동 적용되므로 친구·공개 필터를 RPC 본문에서
-- 다시 박을 필요 없음 (`user_books_friends_read`/`quotes_friends_read` 정책이
-- target_uid에 대해 가시성 결정). 본인 진입(라우터 _redirect로 차단되지만 방어용)이면
-- own 정책으로 자기 데이터 자체 카운트.
--
-- 잠금 인용구는 quotes_friends_read의 `is_private=false` 게이트로 제외 — 친구는
-- 잠금 인용구 카운트도 못 봐야 하므로 정합. 본인은 잠금 포함.
--
-- 한 RPC가 두 카운트를 함께 반환 → 친구 프로필 진입 시 segment 라벨 한 번에 갱신.

create or replace function public.friend_profile_aggregate(
  target_uid uuid
)
returns table (
  book_count int,
  quote_count int
)
language sql
security invoker
stable
as $$
  select
    (select count(*)::int from public.user_books where user_id = target_uid) as book_count,
    (select count(*)::int from public.quotes where user_id = target_uid) as quote_count;
$$;

grant execute on function public.friend_profile_aggregate(uuid) to authenticated;
