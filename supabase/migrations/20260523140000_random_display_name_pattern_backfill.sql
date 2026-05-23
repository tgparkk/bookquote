-- 2차 마이그레이션(20260523130000)의 휴리스틱 보정.
--
-- 2차는 `updated_at = created_at`인 사용자만 백필했는데, 'Yeeun Jeong'처럼
-- 가입 후 다른 컬럼(예: `is_library_public` 토글)을 건드린 사용자는 닉네임을
-- 손도 안 댔는데도 `updated_at > created_at`이 되어 보호 대상으로 잘못 분류됐다.
--
-- 더 정직한 기준: `display_name`이 generator 출력 형식인지를 직접 검사.
-- generator는 항상 `{한글 형용사} {한글 동물} {4자리 숫자}` 형식이므로 정규식
-- `^[가-힣]+ [가-힣]+ [0-9]{4}$`으로 정확히 식별. 이 형식이 *아닌* 모든 행을
-- 무작위로 교체 — 본인이 자기 손으로 정한 한글 닉네임(형식이 다른 경우)도
-- 덮임. 옵션 A "OAuth name 전부 무조건 무작위" 정신.

do $$
declare
  target_id uuid;
  attempts int;
begin
  for target_id in
    select id from public.profiles
    where display_name is null
       or display_name !~ '^[가-힣]+ [가-힣]+ [0-9]{4}$'
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
