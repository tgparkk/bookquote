-- 책귀 — books 테이블
--
-- 책은 글로벌 카탈로그(모든 사용자가 공유). 알라딘 검색 결과를 캐시 + 영속화한다.
-- PK는 UUID로, ISBN13/10은 unique 제약. 알라딘이 잘못된 ISBN을 줘서 row를 교체해야
-- 할 때 PK가 ISBN이면 cascade로 quotes·user_books가 깨지므로 UUID 채택.

create table if not exists public.books (
  id            uuid primary key default gen_random_uuid(),
  isbn13        text not null unique,
  isbn10        text unique,
  title         text not null,
  author        text,
  publisher     text,
  pub_date      text,             -- 알라딘이 'YYYY-MM-DD' 또는 'YYYY' 등 자유 형식으로 줌
  cover_url     text,             -- 알라딘 이미지 URL 직접 사용 (Storage 미러링 X)
  description   text,
  category_name text,
  source        text not null default 'aladin',
  source_id     text,             -- 알라딘 itemId 등
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

comment on table public.books is '글로벌 책 카탈로그. 알라딘 검색 결과 + 사용자 활동 시 자동 채워짐.';

drop trigger if exists books_updated_at on public.books;
create trigger books_updated_at
  before update on public.books
  for each row execute function public.set_updated_at();

-- ── 인덱스 ─────────────────────────────────────────────────
-- title 검색은 알라딘에 위임하므로 trigram 인덱스 V1엔 불필요.
-- isbn13/isbn10 unique가 자동 인덱스 생성.

-- ── RLS ──────────────────────────────────────────────────
alter table public.books enable row level security;

drop policy if exists "Books are viewable by everyone" on public.books;
create policy "Books are viewable by everyone"
  on public.books for select
  using (true);

drop policy if exists "Authenticated users can insert books" on public.books;
create policy "Authenticated users can insert books"
  on public.books for insert
  to authenticated
  with check (true);

drop policy if exists "Authenticated users can update books" on public.books;
create policy "Authenticated users can update books"
  on public.books for update
  to authenticated
  using (true)
  with check (true);

-- ── upsert 헬퍼 ─────────────────────────────────────────────
-- 클라이언트가 알라딘 결과를 그대로 upsert하기 위한 RPC. ON CONFLICT (isbn13)
-- DO UPDATE로 메타가 갱신되면(신간 정보 채워짐) 함께 반영. quotes.book_id가
-- 깨지지 않도록 id는 항상 보존.

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
    cover_url, description, category_name, source, source_id
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
    book ->> 'source_id'
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
    source_id     = coalesce(excluded.source_id,     public.books.source_id)
  returning * into result;

  return result;
end;
$$;

comment on function public.upsert_book is 'isbn13 기준 upsert. 메타가 더 풍부한 쪽으로 갱신.';
