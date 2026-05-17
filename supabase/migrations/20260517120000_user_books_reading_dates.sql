-- 책귀 — user_books에 독서 시작·완독일 추가 (PR17-A)
--
-- 별점·서재 추가일과는 별개로 "이 책을 언제 시작했고 언제 다 읽었는가" 기록.
-- date 타입(시각 없음) — 시간대 혼란 회피. CHECK로 finished_at >= started_at 보장.
-- 둘 다 null과 한쪽만 null도 허용(시작만 입력하고 아직 안 다 읽은 케이스가 V1 핵심).
-- partial index 2개로 캘린더 조회 시 풀 스캔 회피.
--
-- 명세: docs/DECISIONS.md 2026-05-17 · docs/design/screens/library-calendar.md.

alter table public.user_books
  add column if not exists started_at  date,
  add column if not exists finished_at date;

alter table public.user_books
  drop constraint if exists user_books_finished_after_started;
alter table public.user_books
  add constraint user_books_finished_after_started
    check (finished_at is null or started_at is null or finished_at >= started_at);

comment on column public.user_books.started_at  is '읽기 시작일 (date, null=미입력).';
comment on column public.user_books.finished_at is '완독일 (date, null=미완독). started_at 이상이어야 함.';

create index if not exists user_books_user_finished_idx
  on public.user_books (user_id, finished_at desc)
  where finished_at is not null;

create index if not exists user_books_user_started_idx
  on public.user_books (user_id, started_at desc)
  where started_at is not null;
