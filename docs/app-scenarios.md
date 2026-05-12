# 앱 시나리오 — 책귀 (V1, 현재 구현 기준)

**기준일**: 2026-05-14 (Stage 2 PR1~5 반영)
**대체 관계**: `docs/discovery/flows.md`는 2026-05-09 Validation 초안(Expo/TanStack/Realtime/follow 타임라인 시절) — V1 실제 동선은 **이 문서** + `docs/design/screens/*.md`가 기준. flows.md는 시점 고정 자료로만 본다.
**관련**: 화면별 세부 = `docs/design/screens/*.md` · 시각 목업 = `docs/design/mockups/{screens,walkthrough}.html` · DB = `docs/db-schema.md` · 결정 = `docs/DECISIONS.md`

---

## 0. 한 줄 요약

> 책을 읽다 좋은 구절을 만나면 → 폰으로 찍어 텍스트 복사 → 책귀에 붙여넣고 책 연결·페이지·무드 태그 → 저장 → 홈 "내 인용 피드"에 쌓임 → 나중에 무드별로 다시 보고, 카드로 만들어 SNS·단톡방에 공유한다.

V1 = 내가 모으는 인용구 컬렉션 + 카드 공유. **친구 follow/타임라인/Realtime/받은 카드 함은 V1.5** (DECISIONS 2026-05-12).

---

## 1. 화면 지도 (구현 상태)

```
/splash ──(세션 있음)──▶ ┌──────── StatefulShellRoute (BottomNav 4슬롯) ────────┐
        │ ✅              │ [0] /          홈 — 내 인용 피드             ✅       │
        └─(없음)──┐       │ [1] /library   서재 — [책 ↔ 인용구] 세그먼트  ✅       │
                  │       │ [2] (＋)       sentinel → push /quote/new            │
   /auth/login ◀──┤ ✅    │ [3] /me        내 정보 — 프로필·내보내기·약관·탈퇴 ✅  │
        │         │       └─────────────────────────────────────────────────────┘
   /auth/callback │       풀스크린 (셸 밖):
   /callback   ✅ │         /quote/new[?bookId=]  인용구 입력            ✅
                  │           └ "카드 만들기 →" → push /quote/:id/card  ⏳ 스텁(Stage 3)
   /book/:id ◀────┘                                  └ "공유" → 시트     ⏳ Stage 3
     ✅ read-only (보강은 PR6)                              └ 카카오톡 등 → 받는 사람 ⏳

  모달 시트(어느 탭에서도): showBookSearchSheet — 알라딘 검색 + 캐시 사전조회   ✅

  받는 사람 deep link: io.github.tgparkk.bookquote://book/:id?from=share        ⏳ deep_link_handler 일반화(PR6)
```

✅ = 구현·동작 / ⏳ = 스텁 또는 미구현(다음 PR 또는 Stage 3) — 라우트 진실은 `lib/app/router.dart`.

---

## 2. 시나리오 A — 처음 시작 → 첫 인용구 (Activation)

1. 앱 첫 실행 → **스플래시**(`/splash`)가 세션 hydrate를 기다림 → 세션 없으면 `/auth/login`.
2. **로그인**: 이메일 입력 → "이메일로 시작" → Supabase 매직링크 발송 → "메일을 확인해주세요". (카카오 버튼은 placeholder — 비즈 인증 전이라 동선엔 두되 V1 핵심 아님.)
3. 메일의 링크 탭 → 앱이 deep link(`io.github.tgparkk.bookquote://auth/callback?code=...`)를 받음 → **인증 콜백**(`/auth/callback`·`/callback`)이 세션 교환 → 가입이면 트리거가 `profiles` 자동 생성 → `redirect`가 `?from=` 또는 `/`로.
4. **홈**(`/`) 진입 — 인용구 0개면 빈 상태: "아직 인용구가 없어요 / 좋아하는 책의 한 줄을 저장해보세요" + **[＋ 인용구 추가]** 버튼 하나.
5. 버튼 또는 BottomNav [＋] 탭 → 시나리오 B로.

> 차이(설계 대비): 설계 초안의 "홈 = 친구 타임라인"은 폐기 — V1 홈 = **내 인용 피드**(DECISIONS 2026-05-12). 온보딩 튜토리얼 없음(빈 상태 CTA 하나로 학습).
> 미해결: 릴리스 APK에서 매직링크 발송 실패 사례(Supabase 이메일 한도/ Resend SMTP 물림 확인 필요 — STAGES 백로그).

---

## 3. 시나리오 B — 인용구 추가 (핵심, 매일)

1. BottomNav [＋] → `/quote/new` (풀스크린, 셸 밖). 본문 입력 자동 포커스.
2. 책에서 찍은 텍스트를 폰 OCR로 복사해 둔 상태면 → **"클립보드에서 붙여넣기"** 배너 탭 한 번. (앱 내장 OCR 안 함 — DECISIONS 2026-05-11.)
3. **책 연결** 탭 → `showBookSearchSheet` 모달:
   - 검색어 입력 → 먼저 `books` 캐시를 `ilike` 사전조회(빠름) → 없으면 알라딘 검색(Edge Function `aladin-search` 경유, 키 은닉).
   - 결과에서 책 선택 → `upsert_book` RPC로 카탈로그에 영속화 → 시트 닫히고 입력 화면에 "📕 제목 · 저자" 표시. *(시트는 모달이라 본문 입력 state 보존 — 회귀 테스트.)*
   - 책을 안 고르고 닫아도 OK — `manual_book_text`로 나중에 적거나 책 없이 저장 가능.
4. **페이지**(선택) 입력 + **무드 칩**(위로/먹먹/새벽3시/통찰/설렘 — 최대 3개) 선택.
5. 입력 중 자동으로 **draft 저장**(`shared_preferences`) — 앱이 죽거나 뒤로 가도 복원. 본문 비우고 뒤로 = PopScope 폐기 확인.
6. **[카드 만들기 →]** 또는 **[저장만]** 탭:
   - 온라인이면 `quotes` INSERT → 홈 피드 invalidate → 홈에 즉시 반영.
   - 네트워크 오류면 **오프라인 아웃박스**(`shared_preferences`)에 큐잉하고 성공으로 처리 → 다음에 앱이 포그라운드로 돌아올 때 best-effort flush(시나리오 F).
   - "카드 만들기 →"는 `/quote/:id/card`로 가지만 **카드 에디터는 아직 스텁**(Stage 3) — V1 현재는 인용구 저장까지가 완성된 동선.

---

## 4. 시나리오 C — 다시 보기 / 카드 만들기

- **홈 피드**(`/`): 내 인용구가 최근순으로 무한스크롤. 당겨서 새로고침. 카드 탭 → 펼침 → **[카드 만들기]**(→ `/quote/:id/card` 스텁) / **[삭제]**(확인 다이얼로그 → 낙관적 제거). FAB 없음(BottomNav [＋]과 중복), Realtime 없음.
- **서재 → "인용구" 세그먼트**(`/library?tab=quotes`): 무드 필터 칩(전체 N + 무드별 개수 — `my_quote_mood_counts` RPC) + 무드별 무한스크롤 목록(홈과 같은 카드 위젯). 차별화 ④(무드별 컬렉션). 빈 상태 = 전체면 "아직 없어요"+＋ / 무드면 "이 무드 없어요"+전체보기.
- **서재 → "책" 세그먼트**(`/library`): 내가 담은 책 리스트(added_at desc). 탭 → 책 상세. FAB **[책 추가]** → `showBookSearchSheet` → `addToLibrary`.
- **책 상세**(`/book/:id`): 표지·제목·저자·출판사·설명 + (로그인 시) **별점 매기기**(1~5, `user_books.rating` — 별점 매기면 그 책이 자동으로 서재에 들어옴). 게스트도 read-only로 볼 수 있음(deep link용). *"이 책에서 모은 N구절" 섹션 + "인용구 추가" CTA + 설명 점진 공개는 PR6.*
- 카드 에디터·공유 시트·받는 쪽 deep link = **Stage 3** (가장 공들일 단계).

---

## 5. 시나리오 D — 내 데이터 관리 (내 정보 화면)

`/me` (BottomNav [내정보]):
- **프로필**: 이니셜 아바타 + 이메일 + "로그인됨". (이메일은 세션에서 읽음 — `profiles`는 아직 직접 안 씀.)
- **내 데이터**: 인용구 N개(→ `/library?tab=quotes`) · 서재 N권(→ `/library`) · **Markdown으로 내보내기** — 전체 인용구를 cursor로 끝까지 모아 책별 그룹 + 쪽수·무드 메타가 든 `.md` 문자열을 만들어 OS 공유 시트로(차별화 ③ 데이터 주권). 0개면 "내보낼 인용구 없어요".
- **설정**: 다크 모드 "시스템 설정"(읽기 전용 — 토글은 V1.5, 다크 팔레트 미정) / 알림 "곧 추가될 기능"(비활성).
- **정보**: 앱 버전 · 문의하기(`mailto:`) · 이용약관·개인정보처리방침(외부 링크 — **URL은 아직 placeholder**, 출시 전 호스팅 필요).
- **계정**: 로그아웃 — 아웃박스에 동기화 대기 인용구가 있으면 "이 기기에서 사라질 수 있어요" 경고 다이얼로그 먼저(데이터 유실 방지) → `signOut` → 라우터가 `/auth/login`으로. / **회원 탈퇴** 2단계 — ① 영구 삭제 경고 + 내보내기 권유 → ② "탈퇴합니다" 타이핑 확인 → dim → Edge Function `delete-account` invoke(JWT 검증 → `auth.admin.deleteUser` → cascade로 `quotes`/`user_books`/`profiles` 삭제) → `signOut`. *(함수 배포 전엔 invoke 404 → 실패 토스트 — STAGES Stage 5.)*
- "친구 찾기" = V1엔 **숨김**(렌더 안 함).

---

## 6. 시나리오 F — 오프라인 작성 (지하철 등)

- 인용구 입력 중 저장 시 네트워크가 없으면 → `QuoteInput`을 사용자별 키(`quote_outbox_v1:<uid>`)로 `shared_preferences`에 JSON 리스트로 쌓음 → "오프라인이에요. 연결되면 자동으로…" 안내, 저장 성공으로 처리.
- 앱이 **포그라운드로 복귀**할 때(`AppLifecycleState.resumed`) 또는 홈 진입 시 → 아웃박스를 순서대로 `createQuote` 재시도, 성공한 것만 큐에서 제거 → 보낸 게 있으면 홈 피드 invalidate.
- V1 = 경량 모델(완전 동기화 엔진·충돌 해결·책 재매칭 UI는 V1.5 — `flows.md` Flow F). 다른 계정으로 로그인해도 아웃박스 안 섞임(키가 uid별).
- 백로그: `connectivity_plus`로 연결-회복 즉시 flush(현재 포그라운드 복귀 시만) + 홈/인용목록에 "동기화 대기 N개" 배너.

---

## 7. V1.5+ (지금 동선에 없음)

- 카드 에디터·공유 시트·받는 쪽 deep link = **Stage 3** (V1 내, 가장 공들일 단계).
- 친구 follow·타임라인·"받은 카드 함"(`received_cards`)·카톡 친구 매칭·좋아요 = **V1.5+** (`flows.md` Flow C·E, `screens/me.md` "친구 찾기").
- 다크 모드 토글, 인용구 [수정], 인라인 [무드 변경], 인용 목록 정렬·검색, 무드 칩 탭 → 서재 navigation, 서재 책 카드 "N구절" 배지·표지색 띠, 삭제 undo SnackBar — STAGES 백로그.

---

## 변경 이력
- 2026-05-14 초안 — Stage 2 PR1~5 기준 V1 동선 정리. `flows.md`(2026-05-09) 대체.
