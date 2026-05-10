-- handle_new_user 트리거 함수를 OAuth(Kakao 등) 호환으로 갱신.
--
-- Kakao 같은 OAuth provider는 사용자가 이메일 동의를 안 했을 때 email이 null일
-- 수 있다. 닉네임·아바타 URL은 raw_user_meta_data에 provider별로 다른 키로 들어
-- 오므로 여러 후보 키를 coalesce로 시도한다.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'display_name',
      new.raw_user_meta_data ->> 'nickname',
      new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name',
      case
        when new.email is not null and new.email <> '' then
          split_part(new.email, '@', 1)
        else null
      end
    ),
    coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    )
  );
  return new;
end;
$$;
