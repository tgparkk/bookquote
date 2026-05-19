-- PR22: 서재 [인용구] 무드 hub 데이터 RPC.
--
-- 무드별 카운트 + 무드별 대표 한 줄(가장 최근, 평문만) 한 번에 반환.
-- 잠금 인용구(text IS NULL = ciphertext 컬럼만 있는 E2EE 인용구)는 발췌에서
-- 자연 제외 — 카운트에는 포함되되 sample_text는 NULL. UI에서 "🔒 잠긴 인용구"
-- 처럼 안내하거나 사용 가능한 일반 발췌가 있으면 그쪽 우선.
--
-- SECURITY INVOKER + auth.uid() 게이트로 RLS 일관성 유지(quotes RLS가
-- user_id = auth.uid()만 select하므로 별도 WHERE 필요 없으나, 명시적
-- 일관성 위해 둠).

create or replace function public.my_quote_mood_hub_snapshots()
returns table (
  mood text,
  cnt int,
  sample_text text,
  sample_id uuid
)
language sql
stable
security invoker
set search_path = public
as $$
  with mine as (
    select q.id, q.text, q.created_at, m.mood
    from public.quotes q
    cross join lateral unnest(q.moods) as m(mood)
    where q.user_id = auth.uid()
  ),
  counts as (
    select mood, count(*)::int as cnt
    from mine
    group by mood
  ),
  samples as (
    select distinct on (mood)
      mood, id, text
    from mine
    where text is not null
    order by mood, created_at desc, id desc
  )
  select c.mood, c.cnt, s.text as sample_text, s.id as sample_id
  from counts c
  left join samples s using (mood);
$$;

grant execute on function public.my_quote_mood_hub_snapshots() to authenticated;
