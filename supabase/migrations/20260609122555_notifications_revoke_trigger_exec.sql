-- PR-NA 보강: 알림 트리거 함수의 RPC 노출 차단.
--
-- plpgsql 함수는 기본적으로 PUBLIC에 EXECUTE가 부여돼, SECURITY DEFINER 트리거
-- 함수가 PostgREST `/rest/v1/rpc/<fn>`로 노출된다(Supabase security advisor
-- 0028/0029 경고). 트리거 *실행*은 EXECUTE 권한과 무관(테이블 소유자 컨텍스트로
-- 발화)하므로 회수해도 트리거는 정상 동작한다. 직접 호출은 NEW/OLD가 없어 어차피
-- 에러지만, API 표면에서 아예 제거해 advisor를 0으로.
--
-- 참고: blocks_cleanup_follows(기존 트리거 함수)도 같은 경고가 있으나 본 작업
-- 범위 밖이라 손대지 않는다.

revoke execute on function public.notify_quote_like()    from public, anon, authenticated;
revoke execute on function public.notify_review_like()   from public, anon, authenticated;
revoke execute on function public.notify_follow()        from public, anon, authenticated;
revoke execute on function public.unnotify_quote_like()  from public, anon, authenticated;
revoke execute on function public.unnotify_review_like() from public, anon, authenticated;
revoke execute on function public.unnotify_follow()      from public, anon, authenticated;
