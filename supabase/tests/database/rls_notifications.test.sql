-- PR-NA — 알림 백본 트리거·RLS 회귀 테스트.
--
-- 좋아요/팔로우 시 수신자 inbox에 적재되고, 취소 시 안읽은 알림이 사라지며,
-- 수신자 본인만 조회/INSERT 불가가 *DB 단에서* 강제되는지 단언.
--
-- 실행: `npx --yes supabase test db` (한 트랜잭션 begin/rollback).

begin;

select plan(9);

-- ─── 시드 (postgres 역할 — RLS 우회, 트리거는 그대로 발화) ──
-- A(공개) · B(공개). B가 A의 콘텐츠에 좋아요/팔로우 → A가 수신자.
insert into auth.users (id, email, created_at, updated_at, raw_user_meta_data, aud, role, instance_id)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'a@test.local', now(), now(), '{"display_name":"Alpha"}'::jsonb, 'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'b@test.local', now(), now(), '{"display_name":"Beta"}'::jsonb,  'authenticated', 'authenticated', '00000000-0000-0000-0000-000000000000');

update public.profiles set is_library_public = true where id in (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
);

insert into public.books (id, isbn13, title, source) values
  ('99999999-9999-9999-9999-999999999999', '9791191056556', 'TestBook', 'aladin')
  on conflict (isbn13) do nothing;

insert into public.quotes (id, user_id, book_id, text, is_private) values
  ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 'A quote', false);

insert into public.book_reviews (id, user_id, book_id, text) values
  ('77777777-7777-7777-7777-777777777777', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 'A review');

-- B가 좋아요(인용구·후기) + 팔로우 → 트리거가 A에게 알림 3건 적재.
insert into public.quote_likes (quote_id, liker_id) values
  ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
insert into public.review_likes (review_id, liker_id) values
  ('77777777-7777-7777-7777-777777777777', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
insert into public.follows (follower_id, followee_id) values
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');

-- ① 적재 — A 수신자 알림 3건(quote_like·review_like·follow) [postgres 시점 raw 확인]
select is(
  (select count(*)::int from public.notifications
     where recipient_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  3,
  '① 좋아요×2 + 팔로우 → A에게 알림 3건 적재'
);

select is(
  (select count(*)::int from public.notifications
     where recipient_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'
       and actor_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb'
       and type = 'quote_like'
       and quote_id = '11111111-1111-1111-1111-111111111111'),
  1,
  '① quote_like 알림은 인용구 소유자(A) + actor(B) + quote_id'
);

-- ─── A 시점 (수신자) ──────────────────────────────────────
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}';

-- ② A는 안읽음 3건
select is(public.unread_notification_count(), 3, '② A 안읽음 카운트 3');

-- ② my_notifications가 3행 + actor 이름(B 공개) 노출
select is(
  (select count(*)::int from public.my_notifications(30)),
  3,
  '② A my_notifications 3행'
);
-- 공개 프로필 actor(B)는 익명 처리되지 않고 이름이 노출된다(가입 트리거가 닉네임을
-- 무작위화하므로 정확값 대신 non-null 단언).
select ok(
  (select actor_display_name from public.my_notifications(30)
     where type = 'quote_like' limit 1) is not null,
  '② 공개 프로필 actor(B) 이름 노출(익명 아님)'
);

-- ④ A는 알림을 직접 INSERT 불가(트리거 전용 — INSERT 정책 없음 → 42501)
select throws_ok(
  $$ insert into public.notifications (recipient_id, actor_id, type)
       values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'follow') $$,
  '42501',
  null,
  '④ 수신자도 알림 직접 INSERT 불가(트리거 전용)'
);

-- ─── B 시점 (actor, 수신자 아님) ──────────────────────────
reset role;
set local role authenticated;
set local "request.jwt.claims" to '{"sub":"bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"}';

-- ⑤ B는 자기 수신 알림 0(자기가 한 행동은 자기 inbox에 없음)
select is(public.unread_notification_count(), 0, '⑤ actor B는 안읽음 0');
select is(
  (select count(*)::int from public.my_notifications(30)),
  0,
  '⑤ B my_notifications 0행(수신자 게이트)'
);

-- ─── 취소(unlike) → 안 읽은 알림 삭제 ─────────────────────
reset role;
delete from public.quote_likes
  where quote_id = '11111111-1111-1111-1111-111111111111'
    and liker_id = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

-- ⑥ quote_like 취소 → A의 안 읽은 quote_like 알림 삭제(3→2)
select is(
  (select count(*)::int from public.notifications
     where recipient_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  2,
  '⑥ unlike 시 안 읽은 quote_like 알림 삭제(3→2)'
);

select finish();

rollback;
