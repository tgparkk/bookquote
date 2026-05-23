-- 무작위 닉네임 + display_name unique 강제 (이메일 local-part 노출 사고 차단).
--
-- 배경: `handle_new_user`가 OAuth 메타에 닉네임이 없을 때 `split_part(email, '@', 1)`
-- 를 display_name으로 박았다. 친구 검색·프로필에 이메일 앞부분(본명·직장 이메일
-- 의심) 그대로 노출 → privacy 사고. DECISIONS에 V1.0.1 핫픽스로 미뤄져 있었으나
-- 사용자 보고로 V1.0에 동봉 (2026-05-23).
--
-- 변경(순서가 중요):
-- 1. `generate_random_display_name()` — '느긋한 수달 4283' 1개 후보를 반환(단순).
--    unique 보장은 호출 측(트리거/백필)의 INSERT·UPDATE + EXCEPTION retry로.
-- 2. 기존 중복 display_name 정리 — 같은 닉네임 그룹에서 가장 오래된 1명만 유지,
--    나머지는 무작위로 교체. unique constraint 추가 전제 조건.
-- 3. 이메일 local-part 백필 — `display_name = split_part(email, '@', 1)`인 사용자.
-- 4. `display_name` unique constraint 추가 (race-free 게이트).
-- 5. `handle_new_user` 업데이트 — 이메일 fallback 제거, race-free retry.

-- ── 1. 무작위 닉네임 생성기 ─────────────────────────────────
create or replace function public.generate_random_display_name()
returns text
language plpgsql
volatile
set search_path = public
as $$
declare
  adjectives constant text[] := array[
    '느긋한', '다정한', '고요한', '포근한', '책읽는', '사색하는', '잔잔한', '차분한',
    '따뜻한', '부드러운', '솔직한', '친절한', '호기심많은', '명랑한', '우아한', '신중한',
    '똑똑한', '용감한', '순수한', '청량한', '산뜻한', '정다운', '따스한', '다부진',
    '든든한', '살뜰한', '단아한', '그윽한', '향긋한', '푸근한'
  ];
  animals constant text[] := array[
    '수달', '고양이', '여우', '달팽이', '두루미', '강아지', '토끼', '다람쥐',
    '너구리', '사슴', '곰돌이', '펭귄', '부엉이', '까치', '학', '해달',
    '거북이', '고래', '돌고래', '햄스터', '코알라', '판다', '코끼리', '미어캣',
    '카피바라', '알파카', '라쿤', '오리', '백조', '비둘기'
  ];
begin
  return
    adjectives[1 + floor(random() * array_length(adjectives, 1))::int]
    || ' '
    || animals[1 + floor(random() * array_length(animals, 1))::int]
    || ' '
    || lpad(floor(random() * 10000)::text, 4, '0');
end;
$$;

-- ── 2. 기존 중복 display_name 정리 ──────────────────────────
-- 같은 닉네임 그룹에서 created_at 가장 빠른 1명만 유지(선점 원칙), 나머지는
-- 무작위로 교체. unique constraint 추가 전에 필수. unique 아직 없으므로 UPDATE
-- 시 또 다른 중복이 생길 수 있으나, 30×30×10000 풀에서 통계적 무시 수준.
-- (4단계 unique constraint 추가가 사후 게이트.)
with ranked as (
  select id,
         row_number() over (partition by display_name
                            order by created_at asc, id asc) as rn
  from public.profiles
  where display_name is not null
)
update public.profiles p
set display_name = public.generate_random_display_name()
from ranked r
where p.id = r.id and r.rn > 1;

-- ── 3. 이메일 local-part 백필 ──────────────────────────────
-- 사용자가 직접 정한 한글 닉네임·카카오 nickname은 패턴이 다르므로 안 건드림.
update public.profiles p
set display_name = public.generate_random_display_name()
from auth.users u
where p.id = u.id
  and u.email is not null
  and u.email <> ''
  and p.display_name = split_part(u.email, '@', 1);

-- ── 4. unique constraint 추가 ─────────────────────────────
-- 4단계 시점에 백필 결과로 우연한 중복이 남아있으면 ALTER가 실패한다. 그 경우
-- 마이그레이션 자체가 롤백되어 안전(데이터 불일치 상태로 안 끝남). 재실행 시
-- 2/3단계가 새 random을 뽑으므로 통계적으로 다음 시도엔 통과.
alter table public.profiles
  add constraint profiles_display_name_unique unique (display_name);

-- 5단계에서 unique 위반 retry가 필요해지므로, 함수 안에서 매 candidate를
-- 따로 SELECT 체크할 필요 없이 INSERT의 unique_violation을 잡으면 된다.

-- ── 5. handle_new_user 트리거 갱신 ─────────────────────────
-- 이메일 fallback 제거. OAuth 메타 nickname이 없으면 무작위 닉네임.
--
-- 두 분기를 명확히 분리:
-- ① OAuth 닉네임 있음 → 그대로 INSERT. unique 충돌이면 RAISE(가입 실패) —
--    V1.0 규모에서 같은 OAuth nickname 충돌은 사실상 0. 그 0에 가까운 케이스에서
--    사용자 OAuth identity를 조용히 무작위로 덮는 건 정직하지 않음. 실제 발생
--    리포트가 들어오면 그때 사용자 닉네임 입력 흐름 추가.
-- ② OAuth 닉네임 없음 → 무작위 닉네임 + unique_violation retry(최대 20회).
--    user 요청 "트리거에서 unique 보장". 20회는 9M 조합 풀에서 도달 불가 —
--    도달 시 풀 고갈 신호로 RAISE(알람 케이스).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  meta_name text := nullif(trim(coalesce(
    new.raw_user_meta_data ->> 'display_name',
    new.raw_user_meta_data ->> 'nickname',
    new.raw_user_meta_data ->> 'name',
    new.raw_user_meta_data ->> 'full_name'
  )), '');
  avatar text := coalesce(
    new.raw_user_meta_data ->> 'avatar_url',
    new.raw_user_meta_data ->> 'picture'
  );
  attempts int := 0;
begin
  if meta_name is not null then
    insert into public.profiles (id, display_name, avatar_url)
    values (new.id, meta_name, avatar);
    return new;
  end if;

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
