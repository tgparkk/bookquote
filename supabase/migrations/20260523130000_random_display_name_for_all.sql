-- OAuth name 신뢰 제거 — 자동 부여 닉네임을 전부 무작위로.
--
-- 1차 마이그레이션(20260523120000)은 `split_part(email, '@', 1)` 완전 일치만
-- 잡았다. 그러나 구글 OAuth가 박는 'yeeun jeong' 같은 풀네임도 privacy 위험은
-- 동일(본명 노출)인데 그대로 통과했다. 본 마이그레이션은:
--
-- a. 트리거 `handle_new_user`에서 OAuth name 분기 완전 제거 → 신규 가입은
--    무조건 무작위 닉네임.
-- b. `updated_at = created_at`인 기존 사용자(가입 트리거 박은 그대로 한 번도
--    안 건드린 행)만 무작위로 교체. 사용자가 직접 편집한 행(updated_at >
--    created_at)은 보호 — 본명 한글 닉네임 등 본인 의도.
--
-- `set_updated_at`은 BEFORE UPDATE에만 걸려 있어 INSERT에는 영향 없음 →
-- 휴리스틱 false positive/negative 없음.

-- ── 1. 트리거 갱신 ─────────────────────────────────────────
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  avatar text := coalesce(
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'picture'
  );
  attempts int := 0;
begin
  loop
    attempts := attempts + 1;
    begin
      insert into public.profiles (id, display_name, avatar_url)
      values (new.id, public.generate_random_display_name(), avatar);
      return new;
    exception when unique_violation then
      if attempts >= 20 then
        raise exception 'generate_random_display_name pool exhausted after % attempts', attempts;
      end if;
    end;
  end loop;
end;
$$;

-- ── 2. 백필 — 트리거 박은 그대로인 사용자 ──────────────────
-- row-by-row UPDATE 안에서 unique_violation retry. 한 사용자가 20회 충돌
-- (사실상 도달 불가)이면 RAISE — 마이그레이션 전체 rollback.
do $$
declare
  target_id uuid;
  attempts int;
begin
  for target_id in
    select id from public.profiles
    where updated_at = created_at
  loop
    attempts := 0;
    loop
      attempts := attempts + 1;
      begin
        update public.profiles
        set display_name = public.generate_random_display_name()
        where id = target_id;
        exit;
      exception when unique_violation then
        if attempts >= 20 then
          raise exception 'backfill pool exhausted for user %', target_id;
        end if;
      end;
    end loop;
  end loop;
end $$;
