-- 출시 후 지표 조회 (Supabase 대시보드 > SQL Editor에 블록별로 붙여넣어 실행)
-- 기준: 2026-07-05 v1.3.0+17 첫 프로덕션 출시. 스키마: docs/db-schema.md
-- SQL Editor는 마지막 SELECT 결과만 표시하므로 ①~④를 한 블록씩 따로 실행할 것.

-- ─────────────────────────────────────────────
-- ① 핵심 지표 요약 (한 번에 한 표로)
-- ─────────────────────────────────────────────
select '총 가입자'                        as metric, count(*)::text as value from auth.users
union all
select '출시일(7/5) 이후 가입자', count(*)::text from auth.users where created_at >= '2026-07-05 00:00+09'
union all
select '오늘(7/6) 가입자', count(*)::text from auth.users where created_at >= '2026-07-06 00:00+09'
union all
select '총 인용구', count(*)::text from public.quotes
union all
select '출시 이후 인용구', count(*)::text from public.quotes where created_at >= '2026-07-05 00:00+09'
union all
select '잠금(E2EE) 인용구', count(*)::text from public.quotes where is_private = true
union all
select '서재 담기(user_books)', count(*)::text from public.user_books
union all
select '별점 매긴 책', count(*)::text from public.user_books where rating is not null
union all
select '카탈로그 책 수(books)', count(*)::text from public.books
union all
select '공유 카드 생성(cards)', count(*)::text from public.cards
union all
select '인용구 1개 이상 작성한 사용자', count(distinct user_id)::text from public.quotes
union all
select '서재에 책 담은 사용자', count(distinct user_id)::text from public.user_books;

-- ─────────────────────────────────────────────
-- ② 일별 가입 추이 + 로그인 방식 분포
-- ─────────────────────────────────────────────
select
  (created_at at time zone 'Asia/Seoul')::date as day,
  count(*)                                     as signups,
  count(*) filter (where raw_app_meta_data->>'provider' = 'google') as google,
  count(*) filter (where raw_app_meta_data->>'provider' = 'email')  as email,
  count(*) filter (where coalesce(raw_app_meta_data->>'provider','') not in ('google','email')) as other
from auth.users
group by 1
order by 1 desc
limit 14;

-- ─────────────────────────────────────────────
-- ③ 일별 콘텐츠 생성 추이 (인용구 / 서재 담기)
-- ─────────────────────────────────────────────
select
  coalesce(q.day, b.day)      as day,
  coalesce(q.quotes, 0)       as quotes,
  coalesce(b.books_added, 0)  as books_added
from
  (select (created_at at time zone 'Asia/Seoul')::date as day, count(*) as quotes
     from public.quotes group by 1) q
full outer join
  (select (added_at at time zone 'Asia/Seoul')::date as day, count(*) as books_added
     from public.user_books group by 1) b
  on q.day = b.day
order by 1 desc
limit 14;

-- ─────────────────────────────────────────────
-- ④ 활동 심도 — 사용자별 분포 (참여 품질)
-- ─────────────────────────────────────────────
with per_user as (
  select u.id,
         (u.created_at at time zone 'Asia/Seoul')::date as joined,
         coalesce(q.n, 0) as quotes,
         coalesce(b.n, 0) as books
  from auth.users u
  left join (select user_id, count(*) n from public.quotes group by 1) q on q.user_id = u.id
  left join (select user_id, count(*) n from public.user_books group by 1) b on b.user_id = u.id
)
select
  count(*)                                   as users,
  count(*) filter (where quotes = 0 and books = 0) as ghost_users,     -- 가입만 하고 활동 0
  count(*) filter (where quotes >= 1)        as wrote_quote,
  count(*) filter (where quotes >= 3)        as wrote_3plus,
  count(*) filter (where books >= 1)         as added_book,
  round(avg(quotes), 2)                      as avg_quotes_per_user,
  max(quotes)                                as max_quotes_one_user
from per_user
where joined >= '2026-07-05';  -- 출시 이후 가입자만. 전체 보려면 이 줄 삭제
