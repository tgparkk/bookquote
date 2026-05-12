-- 책귀 — user_books에 별점(rating) 추가
--
-- 별점은 "내 서재에서의 이 책에 대한 평가"라 user_books에 둔다. 정수 1~5, nullable
-- (안 매김). 별점을 매기면 그 책이 자동으로 내 서재에 들어온다 (upsert).
-- 반쪽 별(0.5 단위)은 입력 UI 복잡도 때문에 V1엔 안 함 — 필요하면 numeric으로 확장.

alter table public.user_books
  add column if not exists rating smallint check (rating between 1 and 5);

comment on column public.user_books.rating is '내 별점 (1~5, null=미평가). 별점을 매기면 그 책이 내 서재에 들어옴.';
