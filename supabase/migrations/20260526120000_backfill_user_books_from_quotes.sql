-- 책귀 — 인용구가 있는데 서재(user_books)엔 없는 (user_id, book_id) 쌍 백필
--
-- 배경: PR28에서 createQuote가 user_books에 자동 등록하도록 보강했지만, 첫 release
-- 빌드 직후 일시 transient 실패가 관찰됨(silent catch에 묻혀 원인 불명, 다음
-- 인용구부터는 정상 동작). 그 사이 작성된 인용구의 책이 서재에서 누락된 row를
-- 일괄 보충해 사용자 멘탈 모델("내가 적은 책 = 내 서재에 있는 책") 일관성 회복.
--
-- 멱등: `on conflict do nothing`. 향후 같은 류 silent fail 누적 시 같은 SQL 재실행
-- 또는 같은 마이그레이션 패턴으로 새 파일 추가 가능.
--
-- added_at: 그 책으로 *처음 인용한* 시점(`min(created_at)`)을 서재 등록일로 본다.
-- "내가 이 책을 처음 만난 날"이 가장 의미 가까움 — `now()` 디폴트로 두면 과거에
-- 적은 책이 마치 오늘 담은 것처럼 보임.

insert into public.user_books (user_id, book_id, added_at)
select q.user_id, q.book_id, min(q.created_at)
from public.quotes q
where q.book_id is not null
group by q.user_id, q.book_id
on conflict (user_id, book_id) do nothing;
