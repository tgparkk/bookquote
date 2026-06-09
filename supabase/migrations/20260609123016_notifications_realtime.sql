-- PR-NB: notifications를 Supabase Realtime로 노출(라이브 안읽음 배지).
--
-- ① supabase_realtime publication에 테이블 추가 → postgres_changes 이벤트 송출.
--    Realtime은 notifications의 SELECT RLS(recipient_id = auth.uid())를 적용하므로
--    각 사용자는 자기 알림 변경만 수신(클라 필터는 belt-and-suspenders).
-- ② replica identity full — DELETE(unlike/unfollow 정리, dismiss) 이벤트에서도 old
--    행 전체가 실려 Realtime이 RLS(recipient_id)를 평가할 수 있게. 기본(PK만)이면
--    삭제 이벤트가 RLS를 통과 못해 배지가 갱신 안 될 수 있음. 알림은 저volume이라
--    WAL 비용 무시 가능.

alter table public.notifications replica identity full;

alter publication supabase_realtime add table public.notifications;
