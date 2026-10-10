-- 성장 실험 8주(2026-09-28 ~ 11-22) 주간 지표 — docs/DECISIONS.md 2026-09-26 "성장 실험 8주" 참조
-- 매주 월요일 실행. 8/3~9/27 행은 기준선(마케팅 0 기간).
-- SELECT 1개라 Supabase MCP execute_sql 또는 대시보드 SQL Editor에 통째로 붙여넣으면 된다.
--
-- 2026-10-10 개정: 인용구만 세서 "사용 0"으로 오판했다(실제로는 출시 후 다른 사용자 9명이 책 21권을 담음).
-- 실사용은 '독서 기록(책 담기·완독)'이 중심 → 책 지표와 '기록자' 정착 정의를 추가했다.
--
-- 컬럼 (대표 계정 제외가 기본, *_mine만 대표 본인)
--   signups                  : 그 주 신규 가입
--   settled_writers          : 그 주 가입자 중 가입 후 14일 안에 서로 다른 2일 이상 '인용구'를 저장한 사람 (구 정의)
--   settled_recorders        : 그 주 가입자 중 가입 후 14일 안에 서로 다른 2일 이상 '기록'(인용구 저장 또는 책 담기)한 사람
--                              최근 2주 행은 14일 창이 안 끝나 아직 늘어날 수 있다.
--   active_recorders         : 그 주에 인용구를 저장하거나 책을 담은 사람 수 (주간 활성 기록자)
--   books_added / book_adders: 그 주에 담긴 책 수 / 담은 사람 수 (added_at 기준)
--   books_finished           : 그 주에 완독 처리된 책 수. 앱과 같은 판정(library_entry.dart libraryStatusOf) —
--                              finished_at이 있으면 그 날짜, 날짜 없이 reading_status='finished'로 담았으면 담은 날.
--                              ⚠️ finished_at은 사용자가 입력하는 '다 읽은 날'이라 과거로 소급될 수 있다(기록한 주 ≠ 완독한 주).
--   quotes / quote_writers   : 인용구 수 / 작성자 수
--   quotes_mine, books_mine, finished_mine : 대표 본인 — 주간 실행 체크
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
), books as (
  select date_trunc('week', b.added_at at time zone 'Asia/Seoul')::date as wk,
         count(*) filter (where b.user_id not in (select id from owner))                as others,
         count(distinct b.user_id) filter (where b.user_id not in (select id from owner)) as other_adders,
         count(*) filter (where b.user_id in (select id from owner))                    as mine
  from public.user_books b
  group by 1
), finished as (
  select date_trunc('week', coalesce(b.finished_at, (b.added_at at time zone 'Asia/Seoul')::date))::date as wk,
         count(*) filter (where b.user_id not in (select id from owner)) as others,
         count(*) filter (where b.user_id in (select id from owner))     as mine
  from public.user_books b
  where b.finished_at is not null
     or (b.started_at is null and b.reading_status = 'finished')
  group by 1
), records as (
  -- 기록 이벤트(인용구 저장 · 책 담기)를 한 줄씩 — 활성 기록자·정착 기록자 계산용
  select user_id, created_at as at from public.quotes
  union all
  select user_id, added_at as at from public.user_books
), active as (
  select date_trunc('week', r.at at time zone 'Asia/Seoul')::date as wk, count(distinct r.user_id) as n
  from records r
  where r.user_id not in (select id from owner)
  group by 1
), settled as (
  select date_trunc('week', u.created_at at time zone 'Asia/Seoul')::date as wk,
         count(*) filter (where (select count(distinct (q.created_at at time zone 'Asia/Seoul')::date)
                                   from public.quotes q
                                  where q.user_id = u.id
                                    and q.created_at < u.created_at + interval '14 days') >= 2) as writers,
         count(*) filter (where (select count(distinct (r.at at time zone 'Asia/Seoul')::date)
                                   from records r
                                  where r.user_id = u.id
                                    and r.at < u.created_at + interval '14 days') >= 2)        as recorders
  from auth.users u
  where u.id not in (select id from owner)
  group by 1
)
select w.wk as week_mon,
       case when w.wk < date '2026-09-28' then '기준선'
            else 'W' || ((w.wk - date '2026-09-28') / 7 + 1) end as phase,
       coalesce(s.n, 0)             as signups,
       coalesce(st.writers, 0)      as settled_writers,
       coalesce(st.recorders, 0)    as settled_recorders,
       coalesce(a.n, 0)             as active_recorders,
       coalesce(b.others, 0)        as books_added,
       coalesce(b.other_adders, 0)  as book_adders,
       coalesce(f.others, 0)        as books_finished,
       coalesce(q.others, 0)        as quotes,
       coalesce(q.other_writers, 0) as quote_writers,
       coalesce(q.mine, 0)          as quotes_mine,
       coalesce(b.mine, 0)          as books_mine,
       coalesce(f.mine, 0)          as finished_mine
from weeks w
left join signups  s  on s.wk  = w.wk
left join settled  st on st.wk = w.wk
left join active   a  on a.wk  = w.wk
left join books    b  on b.wk  = w.wk
left join finished f  on f.wk  = w.wk
left join quotes   q  on q.wk  = w.wk
order by w.wk;
