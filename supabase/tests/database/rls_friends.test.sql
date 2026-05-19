-- PR18-E — RLS 침투 회귀 테스트
--
-- friend-profile.md §7 보안 핵심 8건이 *DB 단에서* 강제되는지 단언.
-- 클라이언트 fallback 0(DB가 막음 = 신뢰 단일 출처) 원칙의 회귀 가드.
--
-- 실행: `npx --yes supabase test db` (Docker + local Supabase 자동 기동 +
-- 마이그 적용 + pgTAP 실행). 모든 테스트는 한 트랜잭션 내에서 begin/rollback.
--
-- 시나리오:
-- ① quotes_friends_read — 잠금 인용구(`is_private=true`)는 친구에게도 0 row
-- ② user_books_friends_read / quotes_friends_read — 비공개 프로필 차단
-- ③ 비팔로워는 공개 프로필이어도 0 row
-- ⑤ profiles SELECT — 본인 외 비공개 프로필 null
-- ⑦ 자기 자신 follow CHECK 23514 거부
-- ⑥ follows SELECT (2026-05-19 마이그) — 두 endpoint 공개면 read, 한쪽 비공개면 0

begin;

select plan(13);

-- ─── 시드 (postgres 역할로 RLS 우회) ──────────────────────

-- A(공개) · B(공개, A를 팔로우) · C(비공개, B가 팔로우) · D(공개, 누구도 팔로우 안 함)
insert into auth.users (id, email, created_at, updated_at, raw_user_meta_data, aud, role, instance_id)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a@test.local', now(), now(), '{"display_name":"Alpha"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'b@test.local', now(), now(), '{"display_name":"Beta"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000'),
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'c@test.local', now(), now(), '{"display_name":"Gamma"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'd@test.local', now(), now(), '{"display_name":"Delta"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');

-- handle_new_user 트리거가 profile row 자동 생성. 공개 여부만 갱신.
update public.profiles set is_library_public = true  where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
update public.profiles set is_library_public = true  where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
update public.profiles set is_library_public = false where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
update public.profiles set is_library_public = true  where id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';

-- 팔로우: B → A (공개·공개) 와 B → C (공개·비공개)
insert into public.follows (follower_id, followee_id) values
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'cccccccc-cccc-cccc-cccc-cccccccccccc');

-- 공유 books row 한 권
insert into public.books (id, isbn13, title, source) values
  ('99999999-9999-9999-9999-999999999999', '9791191056556', 'TestBook', 'aladin')
  on conflict (isbn13) do nothing;

-- A: 서재 + 공개 인용구 1 + 잠금 인용구 1
insert into public.user_books (user_id, book_id) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999');
insert into public.quotes (id, user_id, book_id, text, is_private) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 'A public', false),
  ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', null,      true);

-- C(비공개): 서재 + 공개 인용구 — RLS상 친구에게도 안 보여야 함
insert into public.user_books (user_id, book_id) values
  ('cccccccc-cccc-cccc-cccc-cccccccccccc', '99999999-9999-9999-9999-999999999999');
insert into public.quotes (id, user_id, book_id, text, is_private) values
  ('33333333-3333-3333-3333-333333333333', 'cccccccc-cccc-cccc-cccc-cccccccccccc', '99999999-9999-9999-9999-999999999999', 'C public', false);

-- ─── B 시점 (A의 팔로워, 공개) ────────────────────────────

set local role authenticated;
set local "request.jwt.claims" to '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"}';

-- ① B는 A의 공개 인용구 1건만 보인다 (잠금은 RLS가 hard exclude)
select is(
  (select count(*)::int from public.quotes where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1,
  '① B는 A의 공개 인용구 1건만 보인다 (잠금 제외)'
);

-- ① 잠금 인용구는 친구에게도 0 row
select is(
  (select count(*)::int from public.quotes
     where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' and is_private = true),
  0,
  '① 잠금 인용구(is_private=true)는 친구에게 0 row'
);

-- B는 A의 책 1권 보인다
select is(
  (select count(*)::int from public.user_books where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1,
  'B는 A(공개+팔로잉)의 책 1권 보인다'
);

-- ② B는 C(비공개)의 책 0 row
select is(
  (select count(*)::int from public.user_books where user_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  0,
  '② B는 C(비공개)의 책 0 row'
);

-- ② B는 C(비공개)의 인용구 0 row — 공개 인용구라도 프로필이 비공개면 차단
select is(
  (select count(*)::int from public.quotes where user_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  0,
  '② B는 C(비공개)의 공개 인용구도 0 row'
);

-- ─── D 시점 (누구도 팔로우 안 함, 공개) ─────────────────

reset role;
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd"}';

-- ③ D는 A의 책 0 row (A는 공개이지만 D는 비팔로워)
select is(
  (select count(*)::int from public.user_books where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  0,
  '③ D(비팔로워)는 공개 프로필 A의 책 0 row'
);

select is(
  (select count(*)::int from public.quotes where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  0,
  '③ D(비팔로워)는 공개 프로필 A의 인용구 0 row'
);

-- ⑤ profiles SELECT — D는 공개 프로필 A는 read 가능, 비공개 C는 null
select is(
  (select count(*)::int from public.profiles where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1,
  '⑤ D는 공개 프로필 A read 가능'
);

select is(
  (select count(*)::int from public.profiles where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  0,
  '⑤ D는 비공개 프로필 C read 0 row'
);

-- ⑥ follows SELECT (2026-05-19 마이그) — D는 B→A(공·공) 보임, B→C(공·비)는 0
select is(
  (select count(*)::int from public.follows where followee_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1,
  '⑥ D는 공개→공개 follow(B→A) read 가능'
);

select is(
  (select count(*)::int from public.follows where followee_id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  0,
  '⑥ D는 공개→비공개 follow(B→C) read 0 row'
);

-- ─── C 본인 시점 (비공개) ────────────────────────────────

reset role;
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"cccccccc-cccc-cccc-cccc-cccccccccccc"}';

-- 본인 비공개 프로필은 본인이 read 가능
select is(
  (select count(*)::int from public.profiles where id = 'cccccccc-cccc-cccc-cccc-cccccccccccc'),
  1,
  '본인은 비공개 프로필을 read 가능 (자기 자신)'
);

-- ─── DB CHECK ────────────────────────────────────────────

reset role;

-- ⑦ 자기 자신 follow는 DB CHECK(23514) 위반
select throws_ok(
  $$ insert into public.follows (follower_id, followee_id) values
       ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') $$,
  '23514',
  null,
  '⑦ 자기 자신 follow는 DB CHECK 23514로 거부'
);

select finish();

rollback;
