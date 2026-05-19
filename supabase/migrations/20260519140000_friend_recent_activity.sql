-- 책귀 — 친구 최근 활동 RPC (PR20-D K-factor 다리)
--
-- 근거: 매니저 모드 UX 전문가 #3 R3 — Realtime·push 없는 V1에서 친구가 새 인용구를
-- 추가했음을 *인지할 길이 없음*이 D14 retention 최대 구멍. 홈 상단 비-Realtime
-- 1줄 배너로 해소. 사용자가 앱 켜면 fetch → "지윤 3 · 민호 1" → 탭 = 친구 프로필.
--
-- 보안: SECURITY INVOKER — quotes/profiles RLS가 자연 게이트. 친구 정책
-- (quotes_friends_read + profiles_public_select)이 두 테이블에서 통과한 row만
-- 집계. RPC 안에서 추가 필터 0(정책 드리프트 차단).
--
-- 반환: setof record (user_id, display_name, avatar_url, cnt, latest). 호출자가
-- 빈 결과 시 배너 숨김.

create or replace function public.friend_recent_activity(since timestamptz)
returns table (
  user_id uuid,
  display_name text,
  avatar_url text,
  cnt int,
  latest timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    q.user_id,
    p.display_name,
    p.avatar_url,
    count(*)::int as cnt,
    max(q.created_at) as latest
  from public.quotes q
  join public.profiles p on p.id = q.user_id
  where q.created_at > since
  group by q.user_id, p.display_name, p.avatar_url
  order by max(q.created_at) desc
  limit 20;
$$;

comment on function public.friend_recent_activity is
  'PR20-D — 친구가 since 이후 올린 공개 인용구 user별 카운트. SECURITY INVOKER로 quotes_friends_read + profiles_public_select RLS 자연 게이트.';
