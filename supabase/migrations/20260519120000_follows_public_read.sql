-- 책귀 — follows SELECT RLS 확장: 공개 프로필 양 끝 follow는 누구나 read (PR18-C)
--
-- 근거: friend-profile.md §4 "헤더 팔로워/팔로잉 카운트 탭 → 시트로 리스트" + §7
-- "비공개 프로필이지만 팔로워/팔로잉 카운트는 공개 — V1: 공개(트위터식, social proof)".
--
-- 기존 정책(20260518): SELECT = `auth.uid() = follower_id OR auth.uid() = followee_id` —
-- 본인 관련 row만. PR18-C에선 *남의* 팔로워/팔로잉 목록을 헤더에서 노출해야 하므로
-- "두 endpoint 모두 공개 프로필"인 follow row를 누구나 read 가능하게 OR로 확장.
--
-- Supabase RLS는 동일 명령 정책 OR 합치므로 기존 self-only 정책은 유지 — 본인이
-- 비공개 프로필인 사용자의 follow row도 본인엔 계속 가시(내 팔로잉/팔로워 화면 등).
--
-- 보안 침투 가드(PR18-E):
-- - 비공개 프로필(`is_library_public=false`)의 follow row는 본인 외엔 0 row 응답
-- - 한쪽이 비공개여도 read 차단 — 비공개 사용자가 누구를 팔로우/누가 팔로우 하는지 노출 X
-- - quotes/user_books에는 영향 없음 — 별도 정책으로 게이팅 유지

drop policy if exists "Follows visible when both endpoints public" on public.follows;
create policy "Follows visible when both endpoints public"
  on public.follows for select
  using (
    exists (
      select 1 from public.profiles p
       where p.id = follows.follower_id
         and p.is_library_public = true
    )
    and exists (
      select 1 from public.profiles p
       where p.id = follows.followee_id
         and p.is_library_public = true
    )
  );
