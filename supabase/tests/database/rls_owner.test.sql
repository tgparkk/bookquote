-- To-Do 6 — RLS owner 정책 단위 테스트
--
-- rls_friends.test.sql(PR18-E)이 친구 가시성·공개 프로필 정책을 다룬다.
-- 본 파일은 *자기 소유(owner) 정책*을 다룬다: 각 테이블의 본인 CRUD 허용 +
-- 타인 행 격리 + INSERT user_id 위조 차단(with check) + 익명 접근 0 row.
-- E2EE envelope의 절대 격리(마스터키 wrap이 타인·익명에게 0 row)가 핵심.
--
-- 커버 정책 (rls_friends가 다루지 않는 owner/write 정책):
--   quotes      : own SELECT / INSERT / UPDATE / DELETE
--   user_books  : own SELECT / INSERT / DELETE
--   cards       : own SELECT / INSERT
--   envelopes   : own SELECT / INSERT / UPDATE
--   profiles    : own UPDATE
--   books       : everyone SELECT / authenticated INSERT
--   follows     : own INSERT(위조 차단)
--
-- UPDATE/DELETE 격리는 "실행은 에러 없이 0 rows" 패턴 — data-modifying CTE를
-- 서브쿼리에 넣을 수 없으므로(PG 제약) A 시점에서 실행만 하고, postgres role로
-- 전환해 대상 행이 원형 유지됐는지 검증한다.
--
-- 실행: `npx --yes supabase test db` (Docker + local Supabase).
-- 모든 단언은 한 트랜잭션 begin/rollback 내.

begin;

select plan(25);

-- ─── 시드 (postgres 역할 = RLS 우회) ──────────────────────
-- A·B 두 사용자, 둘 다 비공개(친구 가시성 정책을 배제하고 owner 정책만 검증).

insert into auth.users (id, email, created_at, updated_at, raw_user_meta_data, aud, role, instance_id)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a@test.local', now(), now(), '{"display_name":"Alpha"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'b@test.local', now(), now(), '{"display_name":"Beta"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');

-- handle_new_user 트리거가 profile을 자동 생성. 비공개로 통일.
update public.profiles set is_library_public = false
  where id in (
    'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
  );

insert into public.books (id, isbn13, title, source) values
  ('99999999-9999-9999-9999-999999999999', '9791191056556', 'TestBook', 'aladin')
  on conflict (isbn13) do nothing;

-- A·B 각각: user_books 1 + quotes 1 + cards 1 + envelope 1
insert into public.user_books (user_id, book_id) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '99999999-9999-9999-9999-999999999999');

insert into public.quotes (id, user_id, book_id, text, is_private) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 'A quote', false),
  ('22222222-2222-2222-2222-222222222222', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '99999999-9999-9999-9999-999999999999', 'B quote', false);

insert into public.cards (user_id, quote_id, design) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '{"templateId":"minimal"}'::jsonb),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', '{"templateId":"minimal"}'::jsonb);

insert into public.user_crypto_envelopes (user_id, wrapped_key, wrap_nonce, kdf_salt, kdf_iters) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '\xdeadbeef'::bytea, '\x000000000000000000000000'::bytea, '\x00000000000000000000000000000000'::bytea, 600000),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '\xdeadbeef'::bytea, '\x000000000000000000000000'::bytea, '\x00000000000000000000000000000000'::bytea, 600000);

-- ─── A 시점 (authenticated) ───────────────────────────────
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}';

-- SELECT own + 타인 격리
select is(
  (select count(*)::int from public.quotes where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1, '01 A는 자기 quotes를 본다');
select is(
  (select count(*)::int from public.quotes where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  0, '02 A는 B(비친구)의 quotes 0 row');
select is(
  (select count(*)::int from public.user_books where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1, '03 A는 자기 user_books를 본다');
select is(
  (select count(*)::int from public.user_books where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  0, '04 A는 B의 user_books 0 row');
select is(
  (select count(*)::int from public.cards where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1, '05 A는 자기 cards를 본다');
select is(
  (select count(*)::int from public.cards where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  0, '06 A는 B의 cards 0 row');
select is(
  (select count(*)::int from public.user_crypto_envelopes where user_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  1, '07 A는 자기 envelope를 본다');
select is(
  (select count(*)::int from public.user_crypto_envelopes where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  0, '08 A는 B의 envelope 0 row (E2EE 마스터키 절대 격리)');

-- INSERT user_id 위조 차단 (with check 위반 = 42501)
select throws_ok(
  $$ insert into public.quotes (user_id, book_id, text, is_private)
       values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '99999999-9999-9999-9999-999999999999', 'forged', false) $$,
  '42501', null, '09 A는 user_id=B로 quotes INSERT 불가');
select throws_ok(
  $$ insert into public.user_books (user_id, book_id)
       values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '99999999-9999-9999-9999-999999999999') $$,
  '42501', null, '10 A는 user_id=B로 user_books INSERT 불가');
select throws_ok(
  $$ insert into public.cards (user_id, quote_id, design)
       values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', '{}'::jsonb) $$,
  '42501', null, '11 A는 user_id=B로 cards INSERT 불가');
select throws_ok(
  $$ insert into public.user_crypto_envelopes (user_id, wrapped_key, wrap_nonce, kdf_salt, kdf_iters)
       values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '\xab'::bytea, '\x000000000000000000000000'::bytea, '\x00000000000000000000000000000000'::bytea, 600000) $$,
  '42501', null, '12 A는 user_id=B로 envelope INSERT 불가');
select throws_ok(
  $$ insert into public.follows (follower_id, followee_id)
       values ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') $$,
  '42501', null, '13 A는 follower_id=B로 follows INSERT 불가');

-- INSERT 자기 것 허용
select lives_ok(
  $$ insert into public.quotes (user_id, book_id, text, is_private)
       values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 'A new', false) $$,
  '14 A는 자기 quotes INSERT 허용');
select lives_ok(
  $$ insert into public.cards (user_id, quote_id, design)
       values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', '{}'::jsonb) $$,
  '15 A는 자기 cards INSERT 허용');

-- books 공용 정책
select ok(
  (select count(*) from public.books) >= 1,
  '22 A는 books를 본다 (공용 read)');
select lives_ok(
  $$ insert into public.books (isbn13, title, source)
       values ('9788900000000', 'New', 'aladin') $$,
  '23 A는 books INSERT 허용 (authenticated)');

-- UPDATE/DELETE 타인 격리 — A 시점에서 *실행만*. RLS using 조건 불일치로
-- 0 rows affected(에러 없음). 검증은 postgres role 전환 후 대상 행 원형 확인.
update public.quotes set text = 'hacked' where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
delete from public.quotes where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
delete from public.user_books where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
update public.user_crypto_envelopes set kdf_iters = 999999 where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
update public.profiles set display_name = 'hacked' where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
-- A 자기 quotes UPDATE — 허용돼야 함
update public.quotes set page = 42 where id = '11111111-1111-1111-1111-111111111111';

-- ─── postgres role 검증 (RLS 우회 — 모든 행 가시) ─────────
reset role;

select is(
  (select text from public.quotes where id = '22222222-2222-2222-2222-222222222222'),
  'B quote', '16 A는 B의 quotes를 UPDATE 못 함 (text 원형 유지)');
select is(
  (select count(*)::int from public.quotes where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  1, '17 A는 B의 quotes를 DELETE 못 함');
select is(
  (select count(*)::int from public.user_books where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  1, '18 A는 B의 user_books를 DELETE 못 함');
select is(
  (select kdf_iters from public.user_crypto_envelopes where user_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  600000, '19 A는 B의 envelope를 UPDATE 못 함 (E2EE)');
select isnt(
  (select display_name from public.profiles where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'),
  'hacked', '20 A는 B의 profile을 UPDATE 못 함');
select is(
  (select page from public.quotes where id = '11111111-1111-1111-1111-111111111111'),
  42, '21 A는 자기 quotes를 UPDATE 할 수 있음');

-- ─── 익명(anon) 시점 — auth.uid()가 null이라 모든 owner 정책 false ──
-- role뿐 아니라 jwt.claims도 비워야 진짜 익명 — sub가 남아 있으면
-- auth.uid()가 직전 사용자를 계속 가리킨다.
set local role anon;
set local "request.jwt.claims" to '{}';

select is(
  (select count(*)::int from public.quotes),
  0, '24 익명은 quotes 0 row');
select is(
  (select count(*)::int from public.user_crypto_envelopes),
  0, '25 익명은 envelope 0 row (E2EE 마스터키)');

select finish();

rollback;
