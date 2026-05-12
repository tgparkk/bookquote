-- 책귀 — 내 인용구 무드별 개수 RPC (서재 "인용구" 뷰 필터 칩의 카운트용)
--
-- '__total__' 행 = 전체 인용구 수, 나머지 행 = 무드 name별 개수(0인 무드는 안 나옴).
-- moods가 text[]라 unnest로 펼쳐서 group by. RLS가 auth.uid()를 강제하므로 본인 것만.

create or replace function public.my_quote_mood_counts()
returns table(mood text, n bigint)
language sql
security invoker
stable
set search_path = public
as $$
  select '__total__'::text as mood, count(*)::bigint as n
    from public.quotes where user_id = auth.uid()
  union all
  select m as mood, count(*)::bigint as n
    from public.quotes q, lateral unnest(q.moods) as m
    where q.user_id = auth.uid()
    group by m
$$;

comment on function public.my_quote_mood_counts is '내 인용구의 전체 수(__total__)와 무드 name별 개수.';
