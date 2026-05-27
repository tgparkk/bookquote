-- PR29-A: 무드 hub 카드 미리보기 강화.
--
-- 기존 my_quote_mood_hub_snapshots()는 무드별 평문 한 줄만 반환했다 — 카드의
-- "이 무드가 무엇을 모은 묶음인지" 전달이 약했다. 무드별 최신 평문 2개로 확장
-- (LATERAL ... LIMIT 2). 두 번째 평문이 없는 무드는 sample_text2/sample_id2가
-- 자연스럽게 NULL.
--
-- DISTINCT ON 1개 → LATERAL LIMIT 2로 바뀌면서 컬럼이 sample_text/sample_id에
-- sample_text2/sample_id2가 더해진다. 기존 컬럼명 유지 = 클라이언트 backward
-- compat. SECURITY/auth 정책은 동일.

create or replace function public.my_quote_mood_hub_snapshots()
returns table (
  mood text,
  cnt int,
  sample_text text,
  sample_id uuid,
  sample_text2 text,
  sample_id2 uuid
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
    -- 무드별 최신 평문 2건 (잠금 인용구 자연 제외 — text IS NULL).
    -- row_number 윈도우 후 pivot으로 sample/sample2 2개 컬럼 추출.
    select
      mood,
      max(case when rn = 1 then id end)   as id1,
      max(case when rn = 1 then text end) as text1,
      max(case when rn = 2 then id end)   as id2,
      max(case when rn = 2 then text end) as text2
    from (
      select
        mood,
        id,
        text,
        row_number() over (
          partition by mood
          order by created_at desc, id desc
        ) as rn
      from mine
      where text is not null
    ) ranked
    where rn <= 2
    group by mood
  )
  select
    c.mood,
    c.cnt,
    s.text1 as sample_text,
    s.id1   as sample_id,
    s.text2 as sample_text2,
    s.id2   as sample_id2
  from counts c
  left join samples s using (mood);
$$;

grant execute on function public.my_quote_mood_hub_snapshots() to authenticated;
