-- 책귀 — quotes E2EE 컬럼 추가 (PR16-A)
--
-- 사용자가 잠금 토글한 인용구만 클라이언트 측 E2E 암호화(AES-256-GCM) 후 저장.
-- text + manual_book_text만 암호화, 메타데이터(moods/page/book_id/created_at)는
-- 평문 유지(무드 GIN 인덱스·my_quote_mood_counts RPC·홈 피드 그대로 작동).
-- 기존 평문 인용구는 그대로(is_private=false default).
--
-- 설계: docs/DECISIONS.md 2026-05-17 "인용구 선택적 E2EE 도입".

alter table public.quotes
  add column if not exists is_private boolean not null default false,
  add column if not exists text_encrypted bytea,
  add column if not exists manual_book_text_encrypted bytea,
  add column if not exists crypto_version smallint;

-- text NOT NULL 해제 — 잠금 인용구는 text NULL + text_encrypted NOT NULL.
alter table public.quotes
  alter column text drop not null;

-- 평문/암호 분기 정확히 한 쪽만 채워지도록 CHECK.
-- 기존 인라인 CHECK (char_length(text) between 1 and 2000)는 text가 NULL이면
-- PG의 3-value logic에 의해 TRUE 통과(NULL은 CHECK를 위반하지 않음) — 유지.
alter table public.quotes
  drop constraint if exists quotes_text_xor_encrypted;
alter table public.quotes
  add constraint quotes_text_xor_encrypted check (
    (is_private = false
      and text is not null
      and text_encrypted is null
      and manual_book_text_encrypted is null
      and crypto_version is null)
    or
    (is_private = true
      and text is null
      and text_encrypted is not null
      and manual_book_text is null
      and crypto_version is not null)
  );

comment on column public.quotes.is_private is '잠금(E2EE) 여부. true면 text·manual_book_text는 NULL이고 *_encrypted만 채워짐.';
comment on column public.quotes.text_encrypted is 'AES-256-GCM 암호문 (nonce 12B || ciphertext || tag 16B). 잠금 인용구일 때만.';
comment on column public.quotes.manual_book_text_encrypted is 'manual_book_text 암호문 (잠금 인용구일 때만, 본문과 별도 nonce).';
comment on column public.quotes.crypto_version is '암호화 알고리즘 버전 (V1=1: AES-256-GCM + PBKDF2-HMAC-SHA512 600k). V2 회수용 슬롯.';

-- 잠금 인용구 본인 조회 최적화 (홈 피드는 평문/잠금 섞임 — 전체 quotes_user_created_idx 그대로 사용)
create index if not exists quotes_user_private_idx
  on public.quotes (user_id)
  where is_private = true;
