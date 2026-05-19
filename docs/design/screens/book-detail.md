# 화면 설계 — 책 상세 `/book/:id` (보강)

> 그룹 2 · Stage 2~4. 입력 근거: `competitor-screen-analysis §5.7`, Phase B 가상 팀. **`deep-link-receive.md`(그룹 1)와 같은 화면 컴포넌트의 두 진입 모드** — 일반 진입(서재·검색) vs deep link 진입(`?from=share`). deep link 상세 동작은 `deep-link-receive.md`로 위임, 여기선 일반 진입 + 차이만.

---

## 1. 목적 / 진입·이탈 / 라우트

- **목적**: ① 일반 진입 = 이 책 메타 보기 + "내가 이 책에서 모은 N구절" + "이 책 인용구 추가" CTA. ② deep link 진입 = 보낸 사람 컨텍스트 + "내 서재에 담기" 1탭(K-factor — `deep-link-receive.md`).
- **라우트**: top-level `GoRoute(path: '/book/:id')` — `_redirect`가 게스트 허용(`if (loc.startsWith('/book/')) return null`). 셸 밖. 쿼리: `?from=share|kakao`(보낸 사람 payload는 deep link handler 경유). 현행 `BookDetailScreen`(ConsumerWidget, read-only) → 보강. **현행 갭**: `router.dart`의 `/book/:id` GoRoute가 `bookId`만 builder에 넘김 → `from` 쿼리도 넘기게 수정 필요.
- **진입**: 서재 책 탭 / 인용구 카드의 책 영역 탭 / 검색 시트에서 책 고른 뒤 / **deep link** `io.github.tgparkk.bookquote://book/:id?from=share`(현행 `deep_link_handler.dart`가 무시 중 → 일반화 필요, `deep-link-receive.md §6`).
- **이탈**: "이 책 인용구 추가" → `/quote/new?bookId=:id`(라우터 배선됨) / "내 서재에 담기" → (로그인) 담기+Toast / (미로그인) → `/auth/login?from=...` → 복귀해 담기 / "전체 보기 ▸" → `/library?tab=quotes&bookId=:id` / 인용구 미니 항목 탭 → 인라인 확장 또는 `/quote/:id/card` / `←` → push 스택(deep link 콜드스타트로 스택 비면 `context.go('/')`).

---

## 2. 와이어프레임

**일반 진입 (서재·검색에서)**
```
┌─────────────────────────────────────────┐
│ ←  책 상세                          ⋮    │  AppBar — ⋮ = 담긴 책이면 "서재에서 빼기"
├─────────────────────────────────────────┤
│ ┌────────┐  미드나잇 라이브러리           │  헤더 — 표지 96×140 + 메타
│ │  표지   │  매트 헤이그                   │  제목 headlineMedium / 저자 bodyMedium
│ │        │  ─────────────────────────── │
│ │        │  인플루엔셜 · 2021            │  출판사·연도 bodySmall (페이지·날짜 등은 접힘)
│ │        │  ISBN 9791159..   [더 보기 ▾] │
│ │        │  내 별점  ★★★☆☆  ← 로그인 시만 │  (탭=설정, 현재 별점 별 재탭=지우기. DECISIONS 2026-05-13)
│ │        │  읽기 시작 [오늘][어제][직접]  │  PR17: 입력 후 〔5월 12일 시작〕 [지우기]
│ │        │  다 읽음  [오늘][어제][직접]  │  (started_at 없이 누르면 둘 다 today + Toast)
│ └────────┘                               │
│ ┌─────────────────────────────────────┐ │  서재에 없으면 [＋ 인용구 추가] + 보조 [서재에 담기]
│ │       ＋ 이 책 인용구 추가            │ │  서재에 있으면 이 줄 대신 "✓ 서재에 있음" 칩
│ └─────────────────────────────────────┘ │  → /quote/new?bookId=:id
│  이 책에서 모은 구절  3                   │  ── 0개면 "아직 이 책에서 모은 구절이 없어요"
│ ┌─────────────────────────────────────┐ │  미니 리스트(quote_list_card 컴팩트 변형 —
│ │ "가장 깊은 밤에 가장 빛나는 별이…"    │ │  책 고정이라 표지 썸네일 생략)
│ │  p.132   〔위로〕                     │ │
│ ├─────────────────────────────────────┤ │
│ │ "후회는 인생에서 가장 무거운 짐…"     │ │
│ │  p.87                                │ │
│ └─────────────────────────────────────┘ │
│                  [ 전체 보기 ▸ ]          │  3개 초과 시 → /library?tab=quotes&bookId=
│  설명                                     │  ── 점진적 공개
│  미드나잇 라이브러리는 삶과 죽음 사이의…   │  4줄 표시 + fade
│  …                            [ 더 보기 ]│  → 전체 펼침(접기 토글)
└─────────────────────────────────────────┘
```

**deep link 진입 (`?from=share`)** — 위 레이아웃에 상단 2개 영역 추가:
```
┌─────────────────────────────────────────┐
│ ←  미드나잇 라이브러리                     │  뒤로는 홈/검색으로(스택 비면 context.go('/'))
├─────────────────────────────────────────┤
│ ╭─────────────────────────────────────╮ │  ① 보낸 사람 컨텍스트 (deep link 전용)
│ │ 💬 지윤님이 이 책의 한 줄을 보냈어요   │ │  배경 accent50, accent800 텍스트
│ │  "가장 깊은 밤에 가장 빛나는 별이…"   │ │  (sender 이름은 payload에 있을 때만 — 없으면
│ │  ─ 미드나잇 라이브러리, p.132         │ │   "누군가 이 책의 한 줄을 보냈어요"). V1: 텍스트만,
│ ╰─────────────────────────────────────╯ │   sender 이름·받은 인용구 카드 풀스펙은 V1.5
│ ┌─────────────────────────────────────┐ │  ② "내 서재에 담기" CTA — accent500, 큼 (1급)
│ │       📚 내 서재에 담기              │ │  로그인 → 담기+Toast / 미로그인 → 로그인 후 복귀
│ └─────────────────────────────────────┘ │  이미 담겼으면 "✓ 이미 서재에 있어요"(정보성)
│  … (이하 일반 진입과 동일: 표지·메타·구절·설명) │
└─────────────────────────────────────────┘
```

### ✅ PR18-D 보강 (친구 서재 탐험 V1.0 합류, 2026-05-19 구현)

**일반 진입 와이어프레임에 1줄 추가** — "이 책에서 모은 구절" 헤더 *위*에:

```
│ 👥  이 책을 담은 친구 3명  ▸               │  탭=시트 미니리스트(아바타·display_name).
│                                          │  N≥1일 때만 자체 렌더(0이면 숨김 — 빈상태 회피).
```

**구현**: `follow_repository.countFriendsWithBook(bookId)`(헤더 카운트 — `user_books.eq(book_id).neq(user_id=self).count(exact)` + RLS 게이트) + `friendsWithBook(bookId, limit)`(시트 lazy fetch — 2-step `user_books` → `profiles inFilter`). RPC 미사용(`user_books_friends_read` 정책이 가시성 단일 출처, V1 측정 후 hotfix 슬롯). 미니리스트 항목 탭 → `/u/:userId`(friend-profile.md) + 시트 닫힘.

**deep link 진입 와이어프레임에 1탭 옵션 추가** — `?sender=<uid>`가 deep link URL에 박혀 있으면 "보낸 사람 컨텍스트 박스" 우하단에 `[이 사람 서재 ▸]` TextButton 추가. 탭 → `/u/:sender`. sender가 비공개 프로필이거나 미존재면 버튼 숨김(친구 화면 도달 후 "잠긴 서재" 빈상태로 빠지는 사용자 경험 회피 — 사전 차단).

세부 = `friend-profile.md`. RLS 정책 = `db-schema.md §2.5`.

---

## 3. 상태

| 상태 | 트리거 | 처리 | 표시 | 심각도 |
|---|---|---|---|---|
| 로딩: 책 fetch | `bookByIdProvider(id)` | 헤더 영역 스켈레톤(표지 placeholder + 텍스트 shimmer). deep link면 받은 인용구 텍스트는 payload에 이미 있어 먼저 표시 가능. 목표 `<1s`(`flows.md §5.5`) | Inline 스켈레톤 | 낮음 |
| 로딩: 이 책 인용구 리스트 | `myQuotesProvider(bookId: id)` | 섹션만 스켈레톤 2줄, 메타·CTA는 즉시 | Inline (영역) | 낮음 |
| 빈: 책 없음/삭제됨 | `bookByIdProvider == null` (`PGRST116`) | "이 책을 더 이상 볼 수 없어요" Empty + [홈으로] / [책 검색]. 현행 "검색 결과에서 다시 선택해주세요"보다 deep link 진입 고려한 카피로 | Empty | 중간 |
| 빈: 이 책 인용구 0개 | 리스트 비음 | "아직 이 책에서 모은 구절이 없어요" — 위에 이미 [＋ 인용구 추가] CTA 있으니 추가 버튼 생략 가능 | Empty (영역) | 낮음 |
| 에러: 책 fetch 실패 — 네트워크 | NetworkError / `FETCH_FAILED` | "책 정보를 불러오지 못했어요" + [다시 시도](retryable). **현행 `'책을 불러오지 못했어요: $e'` raw 노출 → userMessage만**(PII·보안, error-handling §9) | Inline → 재시도 | 중간 |
| 에러: 인용구 fetch 실패 (부분) | 책 정보 OK, 인용 섹션만 5xx/RLS | **책 정보·표지·메타는 그대로 보여줌**(부분 실패 격리). 인용 섹션 자리에 "이 책의 인용구를 못 불러왔어요 · 다시 시도" 인라인. 전체 화면 안 죽임 | Inline (섹션) | 중간 |
| 에러: "담기" — 이미 있음 (`23505`) | unique_violation on user_books | "이미 서재에 있어요" Toast — **에러 아닌 정보성** | Toast | 낮음 |
| 에러: "담기" — 네트워크 | NetworkError | 낙관적 표시 후 롤백 + "담지 못했어요. 다시 시도해주세요" Toast | Toast | 중간 |
| 표지 URL 깨짐 (404/CDN) | `BookCover` | placeholder fallback 내장(`book_cover.dart`) — 베이지 + 제목 텍스트. 사용자에게 에러 표시 안 함(북모리의 표지 로딩 실패 약점을 우아한 fallback으로 차별화) | (무표시) | 낮음 |
| 게스트 진입 (미로그인) | `_redirect`가 `/book/` 통과 | 책 정보 read-only로 보여줌. 인용구 섹션 = 본인 인용 위주라 게스트면 섹션 숨김 또는 "로그인하면 모은 구절을 볼 수 있어요". [＋ 인용구 추가]·[내 서재 담기] 탭 → `/auth/login?from=${Uri.encodeComponent('/book/$id?from=share')}` → 로그인 후 `_redirect`의 `from`으로 복귀(payload 보존 — 신규 작업) | (정상 흐름) | 높음 (현재 담기 CTA 자체 미구현) |
| deep link 무한 루프 | 잘못된 redirect / `/book/:id`가 다시 deep link 트리거 | deep link 앱당 1회 consume 후 클리어, 라우터 redirect 1홉 max. handler 측 처리한 URI를 세션 단위 set으로 기억 | (방어) | 중간 |
| 설명 매우 김 | `description` 수천 자 | 현행은 전체를 `Text`로 무제한 → 인용구 섹션을 밀어냄. 4줄 클램프(`maxLines: 4` + fade) + "더 보기" | Inline | 낮음 |
| 메타 일부 누락 (저자·출판일·ISBN null) | 알라딘 데이터 불완전 / ISBN 직접 등록 도서 | 현행이 이미 `if (book.author != null)` 등 null-guard 함 — 누락 필드는 안 보임. `"ISBN ${book.isbn13}"`가 빈 값 출력 안 되게 guard 추가 | (방어) | 낮음 |
| 오프라인 진입 | `connectivity_plus` | 책이 books 캐시(서재)에 있으면 표시, 없으면 "오프라인 — 연결되면 책 정보를 불러와요" + [다시 시도]. "담기"·"인용구 추가"는 온라인 필요(인용은 아웃박스 큐) | 배너 + 재시도 | 중간 |
| 권한 거부 | 해당 없음 | 책 상세는 권한 요청 0 | — | — |

---

## 4. 인터랙션

- **일반 vs deep link 차이 (요약)**: ① deep link면 최상단에 "보낸 사람 + 받은 인용구 미니" 박스 + "내 서재에 담기" 큰 CTA(1급). ② 일반 진입이면 그 자리에 "이 책 인용구 추가" CTA(이미 담겼으면 "✓ 서재에 있음"). ③ deep link에서 미로그인이면 read-only로 다 보여주되 "담기"·"추가"는 로그인 유도. ④ deep link payload는 1회 consume(redirect 1홉 — 무한 루프 금지).
- **"이 책 인용구 추가"**: `context.push('/quote/new?bookId=$id')` — 라우터 배선됨. 인용구 입력 화면이 책 prefill 상태로 열림. (미로그인이면 `/quote/new`가 인증 가드라 → `/auth/login?from=/quote/new?bookId=:id` → 로그인 후 prefill 입력 화면 복귀.)
- **"내 서재에 담기"**: 로그인 → `book_repository.addToLibrary(id)`(낙관적 — 즉시 "✓" 표시) → 성공 Toast "서재에 담았어요" + action [서재 보기]. `23505` → "이미 서재에 있어요". 미로그인 → `/auth/login?from=...` → 로그인 콜백 → `_redirect`가 `from`으로 복귀 → payload 살아있으면 자동 담기(또는 사용자 재탭). **payload 보존 = 신규**(현행 `deep_link_handler`·`auth_callback`이 안 함).
- **"이 책에서 모은 구절"**: 미니 리스트는 `quote_list_card.dart`의 컴팩트 변형(표지 썸네일 생략 — 책 고정). 3개까지 인라인, 초과면 "전체 보기 ▸" → `context.go('/library?tab=quotes&bookId=$id')`. 항목 탭 → 인라인 확장 또는 `/quote/:id/card`. **카피: "내가 이 책에서 모은 N구절"** — `quotes` RLS는 `auth.uid() = user_id`라 본인 것만(다른 사람 인용 X). 게스트는 빈 결과(정상).
- **메타 점진적 공개**: 헤더에 제목·저자·출판사·연도만. ISBN·페이지수·카테고리는 "[더 보기 ▾]"로 접힘(북모리 depth 과다 회피 — 첫 화면 가볍게).
- **설명 점진적 공개**: `description` 4줄(`maxLines: 4` + `TextOverflow.fade`) + "더 보기" → 전체 펼침(접기 토글). 현행은 통째 노출 중(긴 설명이 인용구 섹션 밀어내는 흠).
- **AppBar ⋮**: 담긴 책이면 "서재에서 빼기"(확인 다이얼로그 — "이 책의 인용구는 유지돼요" 명시, `quotes.book_id`가 `on delete set null`). 안 담긴 책이면 ⋮ 안 보임.
- **뒤로**: 일반 진입은 push 스택. deep link 콜드스타트 진입은 스택이 비었을 수 있음 → `←` 누르면 `context.go('/')`(빈 스택 앱 종료 방지).

---

## 5. 토큰 매핑

| 영역 | 토큰 |
|---|---|
| 화면 배경 / AppBar | `AppColors.secondary200` / `AppTheme.appBarTheme` — `←`·⋮ 아이콘 `AppColors.primary500`, 타이틀 `AppFonts.ui` w600 `AppFontSize.md`(17) `AppColors.primary900` |
| 보낸 사람 컨텍스트 박스 (deep link) | 배경 `AppColors.accent50` + border 1 `AppColors.accent200` + `AppRadius.lg`(12) · "💬 …" `AppFonts.ui` w600 `AppFontSize.sm`(13) `AppColors.accent800` · 받은 인용구 `AppFonts.quote` `AppFontSize.base`(15) `AppColors.primary800` height `AppLineHeight.loose`(1.7) · 출처 줄 `AppFonts.ui` `AppFontSize.xs`(11) `AppColors.accent700` · 패딩 `AppSpacing.s4`(16) |
| 책 제목 / 저자 / 출판사·연도 | `headlineMedium` `AppColors.primary900` / `bodyMedium` `AppColors.primary700` / `bodySmall` `AppColors.primary400` |
| ISBN / "더 보기 ▾" | `labelSmall` `AppColors.primary300` / "더 보기" `AppColors.accent600` `AppFontSize.xs`(11) |
| 표지 | `BookCover(width: 96, height: 140)` (현행 그대로) |
| "내 서재에 담기" CTA | 배경 `AppColors.accent500` / 텍스트 `AppColors.secondary50` `AppFonts.ui` w600 14 / `AppRadius.md`(8) / `AppShadows.floating` / 풀폭, 세로 패딩 `AppSpacing.s4` |
| "이 책 인용구 추가" CTA | 같은 accent500 — 또는 deep link "담기"보다 우선순위 낮으면 `OutlinedButton`(border accent500) |
| "✓ 서재에 있음" 칩 | 배경 `AppColors.semanticSuccessLight` / 텍스트 `AppColors.semanticSuccess` `AppFontSize.sm`(13) / `AppRadius.full` |
| "이 책에서 모은 구절 N" 헤더 | `AppFonts.ui` w600 `AppFontSize.base`(15) `AppColors.primary800` · 개수 `AppColors.primary400` |
| 인용구 미니 항목 | 배경 `AppColors.secondary100` + border 1 `AppColors.primary100` + `AppRadius.md`(8) · 인용구 `AppFonts.quote` `AppFontSize.sm`(13) `AppColors.primary800`(2줄 말줄임) · p.N `AppFontSize.xxs`(9) `AppColors.primary400` · 무드칩 `moodColors` |
| "설명" 헤더 / 본문 | `titleMedium` `AppColors.primary800` / `bodyMedium` `AppColors.primary700` height `AppLineHeight.normal`(1.5), 4줄 후 fade(`maxLines` + "더 보기") |
| Toast / 오프라인 배너 / 빈·에러 | `AppTheme.snackBarTheme`(action `accent400`) / `semanticWarningLight`·`semanticWarning` / `library_screen._EmptyView`·`_ErrorView` 패턴 — userMessage만 |

---

## 6. 재사용 / 신규

**재사용**: `bookByIdProvider(id)`(현행), `BookCover`(현행), `book_repository.addToLibrary`(현행 — `library_screen`에서 호출 중, idempotent `onConflict: 'user_id,book_id'`, 비로그인 시 `NOT_AUTHENTICATED` throw), `myLibraryProvider`(담김 여부 1차 판정 — 단 limit 50이라 정확 판정은 `isInLibrary(bookId)` EXISTS 쿼리 권고), `myQuotesProvider(bookId: id)`(`quote-list.md` 신규), `quote_list_card.dart`(컴팩트 변형 — `quote-list.md` 신규), `router.dart`의 `/quote/new?bookId=` 라우트(배선됨), `library_screen`의 `_EmptyView`/`_ErrorView` 패턴, `tokens.dart`.

**신규 / 변경**: `lib/features/book/book_detail_screen.dart` 보강(인용구 섹션, 점진적 공개, deep link 분기, raw `$e` 노출 제거), `lib/features/book/presentation/widgets/sender_context_box.dart`(deep link 상단 박스), `lib/app/deep_link_handler.dart` 일반화(`/book/:id` 라우팅 + payload 보존 + 1회 consume — `deep-link-receive.md §6`), `book_repository`에 `removeFromLibrary`(이미 있음 — UI만 추가) + `isInLibrary(bookId)` EXISTS, `router.dart`의 `/book/:id` GoRoute builder가 `?from=` 쿼리도 넘기게 수정. `pubspec.yaml`: payload 보존용 `shared_preferences`(그룹 1에서 이미 추가) 재사용.

---

## 7. 엣지 / 접근성

**교차 관심사 (공통 8원칙)**: ① 오프라인=1급(표지/메타 캐시, "담기" 큐) ② 데이터 유실 금지(책 메타는 DB, deep link payload 1회 consume 전까지 보존) ③ PII 로그 금지(raw `$e` 노출 제거 — 현행 흠, 보낸 사람 이름은 화면에만) ④ 막다른 골목 금지(죽은 책에 [홈]/[검색], 미로그인 deep link도 read-only 다 보임) ⑤ 해당 없음(이 화면엔 책 검색 시트 없음 — `/quote/new`로 넘김) ⑥ 에러 표시 일관성(Toast=담기 실패, Empty=죽은 책, Modal=세션) ⑦ **게스트 허용**(deep link 진입용 — 라우터 이미 처리) ⑧ 해당 없음.

| 엣지 | 심각도 | 처리 |
|---|---|---|
| 표지 URL 깨짐 | 낮음 | `BookCover` placeholder(이미 동작) |
| 설명 없음 | 낮음 | "설명" 섹션 통째 숨김(현행 동작 유지) |
| 설명 1000자+ | 낮음 | 4줄 + 더보기로 해결 |
| deep link payload에 sender 없음 | 낮음 | "누군가 이 책의 한 줄을 보냈어요" |
| 이미 담긴 책에 deep link 재진입 | 낮음 | "✓ 이미 서재에 있어요" + 인용구 추가 CTA 노출 |
| `/book/abc` (잘못된 id) | 낮음 | `bookByIdProvider == null` → Empty + 출구 |
| 미로그인 deep link | 높음 | read-only로 다 보임, "담기"·"추가"는 로그인 유도, payload 보존 |
| deep link 책이 books 테이블에 없음 | 낮음 | books는 공유 시 upsert되어 있어야 정상. 없으면 "더 이상 볼 수 없어요" |

**접근성**: 표지 semantics `'$title 표지'` 또는 placeholder에 제목 텍스트. "담기" 버튼 `'$title을 내 서재에 담기'`(또는 `'이미 서재에 있음'`). 인용구 미니 항목 ≥48dp. 보낸 사람 박스 `'$sender가 보낸 인용구: $text, $book ${page}페이지'`. "더 보기" 토글 `'설명 ${expanded ? "접기" : "더 보기"}'`. 색만으로 "담김" 표시 X(✓ 아이콘 + 텍스트). 헤더 대비 `primary900` on `secondary200` AA 통과.

---

## 변경 이력
- 2026-05-12 초안 (매니저 종합 — competitor-screen-analysis §5.7 + Phase B 가상 팀). `deep-link-receive.md`와 같은 컴포넌트의 두 진입 모드임을 명시. 수정 항목: raw `$e` 노출 제거, 설명 점진적 공개, `?from=` 라우트 전달.
- 2026-05-17 별점 행 아래 신규 위젯 `_ReadingDatesRow` 추가 결정(PR17, DECISIONS 2026-05-17 "독서 시작·완독일 캘린더..."). [오늘]/[어제]/[직접 선택] 칩 → `book_repository.setReadingDate(bookId, kind, date)` 호출. 입력 후엔 그 자리에 〔YYYY월 D일 시작/완독〕 칩 + 재탭=지우기(별점과 일관). `started_at` 없이 "다 읽음" 탭 시 둘 다 today로 set + Toast "함께 시작일도 오늘로 저장했어요"(StoryGraph 자동 기입 패턴). 게스트 진입(deep link)이면 별점·읽기 날짜 모두 숨김. 캘린더 풀스펙 = `library-calendar.md`(신규).
