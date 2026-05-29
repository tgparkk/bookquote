-- OAuth 아바타 신뢰 제거 — 닉네임 무작위화의 누락된 짝.
--
-- 배경: 2026-05-23 두 마이그레이션(random_display_name / _for_all)이 OAuth name을
-- 신뢰하지 않고 `display_name`을 무작위로 강제했다(본명·이메일 노출 차단). 그러나
-- `avatar_url`은 그대로 두어 구글 OAuth의 `picture`를 계속 저장했다.
--
-- 문제: 구글은 사진을 직접 올리지 않은 사용자에게 "실명 첫 글자"가 박힌 기본
-- 아바타 이미지를 준다. 앱 거의 모든 화면(친구 프로필·팔로워 시트·책 상세·활동
-- 피드·친구 검색·내 팔로잉·독서 순위·차단 목록·책 리뷰)이 이 URL을 그대로
-- NetworkImage로 렌더 → 무작위 닉네임으로 막았던 실명이 아바타 경로로 그대로
-- 노출. 닉네임 무작위화와 정확히 같은 privacy 사고 클래스인데 빠져 있었다.
--
-- 결정(2026-05-29): 닉네임과 동일하게 OAuth 아바타도 신뢰 제거. V1.0엔 아바타
-- 업로드 기능이 없어 `avatar_url`은 항상 필터 안 된 구글 사진뿐이다. 클라이언트의
-- 모든 아바타 위젯은 이미 `avatar_url`이 비면 닉네임 이니셜 동그라미로 폴백하므로,
-- 컬럼을 안 채우게 + null 백필하면 Dart 변경 없이 전 화면이 이니셜로 통일된다.

-- ── 1. 트리거 갱신 — avatar_url 저장 중단 ──────────────────
-- OAuth 메타의 picture/avatar_url을 더 이상 읽지 않는다. 닉네임은 기존대로
-- 무작위 + unique_violation retry.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  attempts int := 0;
begin
  loop
    attempts := attempts + 1;
    begin
      insert into public.profiles (id, display_name, avatar_url)
      values (new.id, public.generate_random_display_name(), null);
      return new;
    exception when unique_violation then
      if attempts >= 20 then
        raise exception 'generate_random_display_name pool exhausted after % attempts', attempts;
      end if;
    end;
  end loop;
end;
$$;

-- ── 2. 기존 행 백필 — avatar_url 전부 null ─────────────────
-- V1.0엔 아바타 업로드가 없으므로 현재 모든 비-null avatar_url은 구글 사진이다.
-- 따라서 휴리스틱 없이 전부 비운다(set_updated_at은 BEFORE UPDATE라 닉네임
-- 무작위화 백필과 달리 created_at 보존 분기가 불필요 — 어차피 전 행 대상).
update public.profiles
set avatar_url = null
where avatar_url is not null;
