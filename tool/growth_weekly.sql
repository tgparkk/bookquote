-- 성장 실험 8주(2026-09-28 ~ 11-22) 주간 지표 — docs/DECISIONS.md 2026-09-26 "성장 실험 8주" 참조
-- 매주 월요일 실행. 8/3~9/27 행은 기준선(마케팅 0 기간: 8주 가입 3명·인용구 0개).
-- SELECT 1개라 Supabase MCP execute_sql 또는 대시보드 SQL Editor에 통째로 붙여넣으면 된다.
--
-- 컬럼
--   signups                 : 그 주 신규 가입(대표 계정 제외)
--   settled_by_signup_week  : 그 주 가입자 중 정착 작성자(가입 후 14일 안에 서로 다른 2일 이상 인용구 저장).
--                             최근 2주 행은 14일 창이 안 끝나 아직 늘어날 수 있다.
--   quotes_others / writers_others : 대표 외 사용자의 인용구 수 / 작성자 수
--   quotes_mine             : 대표 본인 인용구 수 — 주간 실행 체크("인용구 3개 기록")
-- Play 획득 보고서(소스별 방문·설치: threads / share_card)는 Play Console에서 따로 본다.

with weeks as (
  select generate_series(date '2026-08-03', (now() at time zone 'Asia/Seoul')::date, interval '7 days')::date as wk
), owner as (
  select id from auth.users where email = 'sttgpark@gmail.com'
), signups as (
  select date_trunc('week', created_at at time zone 'Asia/Seoul')::date as wk, count(*) as n
  from auth.users
  where id not in (select id from owner)
  group by 1
), quotes as (
  select date_trunc('week', q.created_at at time zone 'Asia/Seoul')::date as wk,
         count(*) filter (where q.user_id not in (select id from owner))                as others,
         count(distinct q.user_id) filter (where q.user_id not in (select id from owner)) as other_writers,
         count(*) filter (where q.user_id in (select id from owner))                    as mine
  from public.quotes q
  group by 1
), settled as (
  select date_trunc('week', u.created_at at time zone 'Asia/Seoul')::date as wk, count(*) as n
  from auth.users u
  where u.id not in (select id from owner)
    and (select count(distinct (q.created_at at time zone 'Asia/Seoul')::date)
           from public.quotes q
          where q.user_id = u.id
            and q.created_at < u.created_at + interval '14 days') >= 2
  group by 1
)
select w.wk as week_mon,
       case when w.wk < date '2026-09-28' then '기준선'
            else 'W' || ((w.wk - date '2026-09-28') / 7 + 1) end as phase,
       coalesce(s.n, 0)             as signups,
       coalesce(st.n, 0)            as settled_by_signup_week,
       coalesce(q.others, 0)        as quotes_others,
       coalesce(q.other_writers, 0) as writers_others,
       coalesce(q.mine, 0)          as quotes_mine
from weeks w
left join signups s  on s.wk  = w.wk
left join quotes  q  on q.wk  = w.wk
left join settled st on st.wk = w.wk
order by w.wk;
