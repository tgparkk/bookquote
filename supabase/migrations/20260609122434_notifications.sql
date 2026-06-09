-- PR-NA: 알림 백본 (notifications) + 적재/취소 트리거 + 조회 RPC.
--
-- 근거: DECISIONS 2026-06-09. 좋아요/팔로우 이벤트를 수신자 inbox에 적재. 전달 채널
-- (인앱 알림함·Realtime 배지는 PR-NB, FCM은 PR-PC)은 이 백본 위에 올라간다.
--
-- 핵심 설계:
-- ① 적재는 클라 금지 — DB 트리거(SECURITY DEFINER)가 quote_likes/review_likes/
--    follows insert 시 수신자(=대상 소유자/팔로이) row를 만든다. 클라 INSERT 정책
--    없음 → 위변조 0.
-- ② 취소(unlike/unfollow)는 *안 읽은* 알림만 삭제(스팸 방지, 읽은 건 보존).
-- ③ 묶음("외 N명")·미리보기는 저장이 아니라 read-time RPC가 만든다.
-- ④ SELECT/UPDATE/DELETE는 수신자 본인만. actor 프로필은 read-time에 profiles RLS로
--    자연 게이트 — 비공개/차단 actor는 익명 처리(이름·아바타 null).

-- ── 1. 테이블 ──────────────────────────────────────────────
create table if not exists public.notifications (
  id           uuid        primary key default gen_random_uuid(),
  recipient_id uuid        not null references auth.users(id)       on delete cascade,
  actor_id     uuid        not null references auth.users(id)       on delete cascade,
  type         text        not null check (type in ('quote_like', 'review_like', 'follow')),
  quote_id     uuid        references public.quotes(id)             on delete cascade,
  review_id    uuid        references public.book_reviews(id)       on delete cascade,
  read_at      timestamptz,
  created_at   timestamptz not null default now(),
  check (recipient_id <> actor_id)
);

comment on table public.notifications is
  'PR-NA 알림 inbox. 적재는 트리거(DEFINER)만, 클라는 read/read처리/삭제만. 묶음·미리보기는 read-time RPC.';

-- 알림함 목록(수신자별 최신순) + 안읽음 카운트 둘 다 커버.
create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc);
-- 안읽음 배지 가속(부분 인덱스).
create index if not exists notifications_unread_idx
  on public.notifications (recipient_id)
  where read_at is null;

-- ── 2. RLS ─────────────────────────────────────────────────
alter table public.notifications enable row level security;

-- 수신자 본인만 조회.
drop policy if exists "see own notifications" on public.notifications;
create policy "see own notifications"
  on public.notifications for select
  to authenticated
  using (recipient_id = auth.uid());

-- 읽음 처리(read_at)만 — INSERT 정책 없음(트리거 전용).
drop policy if exists "mark own notifications read" on public.notifications;
create policy "mark own notifications read"
  on public.notifications for update
  to authenticated
  using (recipient_id = auth.uid())
  with check (recipient_id = auth.uid());

-- 알림 개별/전체 삭제(dismiss).
drop policy if exists "delete own notifications" on public.notifications;
create policy "delete own notifications"
  on public.notifications for delete
  to authenticated
  using (recipient_id = auth.uid());

-- ── 3. 적재 트리거 (SECURITY DEFINER) ──────────────────────
-- quote_like: 인용구 소유자에게.
create or replace function public.notify_quote_like()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (recipient_id, actor_id, type, quote_id)
  select q.user_id, new.liker_id, 'quote_like', new.quote_id
    from public.quotes q
   where q.id = new.quote_id
     and q.user_id <> new.liker_id;  -- self-like 방어(RLS도 막지만 이중)
  return new;
end; $$;

drop trigger if exists quote_like_notify on public.quote_likes;
create trigger quote_like_notify
  after insert on public.quote_likes
  for each row execute function public.notify_quote_like();

-- review_like: 후기 소유자에게.
create or replace function public.notify_review_like()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (recipient_id, actor_id, type, review_id)
  select br.user_id, new.liker_id, 'review_like', new.review_id
    from public.book_reviews br
   where br.id = new.review_id
     and br.user_id <> new.liker_id;
  return new;
end; $$;

drop trigger if exists review_like_notify on public.review_likes;
create trigger review_like_notify
  after insert on public.review_likes
  for each row execute function public.notify_review_like();

-- follow: 팔로이에게.
create or replace function public.notify_follow()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.notifications (recipient_id, actor_id, type)
  values (new.followee_id, new.follower_id, 'follow');
  return new;
end; $$;

drop trigger if exists follow_notify on public.follows;
create trigger follow_notify
  after insert on public.follows
  for each row execute function public.notify_follow();

-- ── 4. 취소 트리거 — 안 읽은 알림만 삭제(스팸 방지) ─────────
create or replace function public.unnotify_quote_like()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  delete from public.notifications n
   using public.quotes q
   where q.id = old.quote_id
     and n.recipient_id = q.user_id
     and n.actor_id = old.liker_id
     and n.type = 'quote_like'
     and n.quote_id = old.quote_id
     and n.read_at is null;
  return old;
end; $$;

drop trigger if exists quote_like_unnotify on public.quote_likes;
create trigger quote_like_unnotify
  after delete on public.quote_likes
  for each row execute function public.unnotify_quote_like();

create or replace function public.unnotify_review_like()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  delete from public.notifications n
   using public.book_reviews br
   where br.id = old.review_id
     and n.recipient_id = br.user_id
     and n.actor_id = old.liker_id
     and n.type = 'review_like'
     and n.review_id = old.review_id
     and n.read_at is null;
  return old;
end; $$;

drop trigger if exists review_like_unnotify on public.review_likes;
create trigger review_like_unnotify
  after delete on public.review_likes
  for each row execute function public.unnotify_review_like();

create or replace function public.unnotify_follow()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  delete from public.notifications n
   where n.recipient_id = old.followee_id
     and n.actor_id = old.follower_id
     and n.type = 'follow'
     and n.read_at is null;
  return old;
end; $$;

drop trigger if exists follow_unnotify on public.follows;
create trigger follow_unnotify
  after delete on public.follows
  for each row execute function public.unnotify_follow();

-- ── 5. 조회 RPC (SECURITY INVOKER + 자연 게이트) ───────────
-- 안읽음 카운트(배지).
create or replace function public.unread_notification_count()
returns int
language sql
stable
security invoker
set search_path = public
as $$
  select count(*)::int
    from public.notifications
   where recipient_id = auth.uid() and read_at is null;
$$;

comment on function public.unread_notification_count is
  'PR-NA 안읽음 알림 수(배지). RLS 자연 게이트(수신자 본인).';

-- 알림함 목록 — actor 프로필(비공개/차단은 null=익명) + 대상 미리보기 + 대상 책.
create or replace function public.my_notifications(p_limit int default 30)
returns table (
  id uuid,
  type text,
  actor_id uuid,
  actor_display_name text,
  actor_avatar_url text,
  quote_id uuid,
  review_id uuid,
  target_book_id uuid,
  preview text,
  read_at timestamptz,
  created_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    n.id,
    n.type,
    n.actor_id,
    ap.display_name as actor_display_name,
    ap.avatar_url   as actor_avatar_url,
    n.quote_id,
    n.review_id,
    coalesce(q.book_id, br.book_id) as target_book_id,
    -- 본인 콘텐츠라 RLS 통과. 잠금 인용구(text null)는 미리보기 null.
    left(coalesce(q.text, br.text), 80) as preview,
    n.read_at,
    n.created_at
  from public.notifications n
  left join public.profiles ap on ap.id = n.actor_id  -- 비공개/차단 actor → null(익명)
  left join public.quotes q on q.id = n.quote_id
  left join public.book_reviews br on br.id = n.review_id
  where n.recipient_id = auth.uid()
  order by n.created_at desc
  limit greatest(1, least(coalesce(p_limit, 30), 100));
$$;

comment on function public.my_notifications is
  'PR-NA 알림함 목록. actor 프로필은 profiles RLS로 자연 게이트(비공개/차단=익명). 미리보기는 본인 콘텐츠.';

-- 전체 읽음 처리(알림함 진입 시). UPDATE RLS가 수신자 본인 게이트.
create or replace function public.mark_all_notifications_read()
returns void
language sql
volatile
security invoker
set search_path = public
as $$
  update public.notifications
     set read_at = now()
   where recipient_id = auth.uid() and read_at is null;
$$;

comment on function public.mark_all_notifications_read is
  'PR-NA 내 안읽음 알림 전체를 읽음 처리. RLS 자연 게이트.';

grant execute on function public.unread_notification_count()   to authenticated;
grant execute on function public.my_notifications(int)         to authenticated;
grant execute on function public.mark_all_notifications_read() to authenticated;
