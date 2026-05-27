-- PR29-B: 서재 책 탭의 스택/책장 view 모드를 위한 page_count 컬럼.
--
-- 두께(mm)는 view 위젯이 pageCount * 0.09mm로 환산. 페이지 수가 수집되지 않은 책은
-- stack/shelf view에서 별도 "두께 미수집" 섹션으로 분리되어 사용자가 수동 보완할
-- 수 있다 — 임의 기본값(예: 250페이지)을 박지 않아 도메인이 명확.
--
-- 데이터 출처: aladin-search Edge Function이 책 upsert 직후 ISBN13으로 Google
-- Books를 비동기 조회해 UPDATE. 사용자가 BottomSheet에서 직접 입력한 값은
-- coalesce로 덮어쓰기 방지(수동 우선).

alter table public.books
  add column if not exists page_count int
  check (page_count is null or (page_count > 0 and page_count < 10000));

comment on column public.books.page_count is
  '책 페이지 수. Google Books API 또는 사용자 수동 입력. NULL = 미수집.';

-- upsert_book이 page_count를 함께 받도록 확장. 기존 값은 coalesce로 보존 —
-- 알라딘 재호출이 page_count를 누락해도(알라딘 API는 page_count 미제공) 이미
-- 수집된 값이 NULL로 덮이지 않는다.

create or replace function public.upsert_book(book jsonb)
returns public.books
language plpgsql
security invoker
set search_path = public
as $$
declare
  result public.books;
begin
  insert into public.books (
    isbn13, isbn10, title, author, publisher, pub_date,
    cover_url, description, category_name, source, source_id, page_count
  )
  values (
    book ->> 'isbn13',
    book ->> 'isbn10',
    book ->> 'title',
    book ->> 'author',
    book ->> 'publisher',
    book ->> 'pub_date',
    book ->> 'cover_url',
    book ->> 'description',
    book ->> 'category_name',
    coalesce(book ->> 'source', 'aladin'),
    book ->> 'source_id',
    nullif(book ->> 'page_count', '')::int
  )
  on conflict (isbn13) do update set
    isbn10        = coalesce(excluded.isbn10,        public.books.isbn10),
    title         = coalesce(excluded.title,         public.books.title),
    author        = coalesce(excluded.author,        public.books.author),
    publisher     = coalesce(excluded.publisher,     public.books.publisher),
    pub_date      = coalesce(excluded.pub_date,      public.books.pub_date),
    cover_url     = coalesce(excluded.cover_url,     public.books.cover_url),
    description   = coalesce(excluded.description,   public.books.description),
    category_name = coalesce(excluded.category_name, public.books.category_name),
    source_id     = coalesce(excluded.source_id,     public.books.source_id),
    page_count    = coalesce(excluded.page_count,    public.books.page_count)
  returning * into result;

  return result;
end;
$$;

comment on function public.upsert_book is
  'isbn13 기준 upsert. 메타가 더 풍부한 쪽으로 갱신. page_count는 coalesce로 보존.';
