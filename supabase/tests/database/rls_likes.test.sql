-- PR-LA — 좋아요 RLS 침투 회귀 테스트
--
-- 좋아요 insert/select 정책이 *DB 단에서* 대상 가시성을 그대로 상속하는지 단언.
-- 클라이언트 fallback 0(DB가 막음 = 신뢰 단일 출처) 원칙의 회귀 가드.
--
-- 실행: `npx --yes supabase test db` (한 트랜잭션 begin/rollback).
--
-- 핵심 시나리오:
-- ① 팔로워는 친구의 공개 인용구를 좋아요 가능 + 카운트 1 + liked_by_me
-- ② 비팔로워는 친구 인용구를 좋아요 불가(RLS 42501) + 카운트 0 row
-- ③ 후기는 공개 프로필이면 비팔로워도 좋아요 가능(quotes와 다른 게이트)
-- ④ self-like 차단(인용구·후기 모두 42501)
-- ⑤ 인용구 삭제 시 좋아요 cascade(orphan 0)

begin;

select plan(10);

-- ─── 시드 (postgres 역할로 RLS 우회) ──────────────────────
-- A(공개) · B(공개, A를 팔로우) · D(공개, 비팔로워)
insert into auth.users (id, email, created_at, updated_at, raw_user_meta_data, aud, role, instance_id)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a@test.local', now(), now(), '{"display_name":"Alpha"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'b@test.local', now(), now(), '{"display_name":"Beta"}'::jsonb,  'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000'),
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'd@test.local', now(), now(), '{"display_name":"Delta"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');

update public.profiles set is_library_public = true where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
update public.profiles set is_library_public = true where id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
update public.profiles set is_library_public = true where id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';

-- B → A 팔로우 (D는 비팔로워)
insert into public.follows (follower_id, followee_id) values
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

insert into public.books (id, isbn13, title, source) values
  ('99999999-9999-9999-9999-999999999999', '9791191056556', 'TestBook', 'aladin')
  on conflict (isbn13) do nothing;

-- A: 공개 인용구 1 + 책 후기 1
insert into public.quotes (id, user_id, book_id, text, is_private) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 'A public quote', false);

insert into public.book_reviews (id, user_id, book_id, text) values
  ('77777777-7777-7777-7777-777777777777', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 'A review text');

-- ─── B 시점 (A의 팔로워, 공개) ────────────────────────────
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"}';

-- ① B는 A의 공개 인용구에 좋아요 가능
select lives_ok(
  $$ insert into public.quote_likes (quote_id, liker_id) values
       ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb') $$,
  '① 팔로워 B는 A의 공개 인용구에 좋아요 가능'
);

-- ① 카운트 1
select is(
  (select n from public.quote_like_counts(array['11111111-1111-1111-1111-111111111111'::uuid])),
  1::bigint,
  '① quote_like_counts: A 인용구 좋아요 1'
);

-- ① liked_by_me true
select is(
  (select liked_by_me from public.quote_like_counts(array['11111111-1111-1111-1111-111111111111'::uuid])),
  true,
  '① B 본인 좋아요라 liked_by_me=true'
);

-- ─── D 시점 (비팔로워, 공개) ──────────────────────────────
reset role;
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd"}';

-- ② D(비팔로워)는 A 인용구를 못 보므로 좋아요 insert가 RLS WITH CHECK 위반(42501)
select throws_ok(
  $$ insert into public.quote_likes (quote_id, liker_id) values
       ('11111111-1111-1111-1111-111111111111', 'dddddddd-dddd-dddd-dddd-dddddddddddd') $$,
  '42501',
  null,
  '② 비팔로워 D는 친구 인용구에 좋아요 불가(RLS 42501)'
);

-- ② D는 A 인용구의 좋아요 카운트를 0 row로 받음(가시성 없음)
select is(
  (select count(*)::int from public.quote_like_counts(array['11111111-1111-1111-1111-111111111111'::uuid])),
  0,
  '② 비팔로워 D는 친구 인용구 좋아요 카운트 0 row'
);

-- ③ 후기는 공개 프로필이면 비팔로워도 좋아요 가능(quotes와 다른 게이트)
select lives_ok(
  $$ insert into public.review_likes (review_id, liker_id) values
       ('77777777-7777-7777-7777-777777777777', 'dddddddd-dddd-dddd-dddd-dddddddddddd') $$,
  '③ 비팔로워 D도 공개 프로필 A의 후기에 좋아요 가능'
);

-- ③ 후기 카운트 1
select is(
  (select n from public.review_like_counts(array['77777777-7777-7777-7777-777777777777'::uuid])),
  1::bigint,
  '③ review_like_counts: A 후기 좋아요 1'
);

-- ─── A 시점 (self-like 차단) ──────────────────────────────
reset role;
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}';

-- ④ A는 자기 인용구에 좋아요 불가(user_id <> liker_id 위반 → 42501)
select throws_ok(
  $$ insert into public.quote_likes (quote_id, liker_id) values
       ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') $$,
  '42501',
  null,
  '④ self-like 차단(인용구) — A는 자기 인용구 좋아요 불가'
);

-- ④ A는 자기 후기에 좋아요 불가
select throws_ok(
  $$ insert into public.review_likes (review_id, liker_id) values
       ('77777777-7777-7777-7777-777777777777', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa') $$,
  '42501',
  null,
  '④ self-like 차단(후기) — A는 자기 후기 좋아요 불가'
);

-- ─── 인용구 삭제 cascade ──────────────────────────────────
reset role;
delete from public.quotes where id = '11111111-1111-1111-1111-111111111111';

-- ⑤ 인용구 삭제 시 그 인용구의 좋아요 행이 cascade로 사라짐(orphan 0)
select is(
  (select count(*)::int from public.quote_likes
     where quote_id = '11111111-1111-1111-1111-111111111111'),
  0,
  '⑤ 인용구 삭제 시 quote_likes cascade — orphan 0'
);

select finish();

rollback;
