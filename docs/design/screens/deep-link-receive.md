# 화면 설계 — 받은 카드 → 책 담기 (deep link 진입) `/book/:id?from=share`

> 그룹 1 · Stage 4 — 바이럴 K-factor의 핵심 경로. 입력 근거: `competitor-screen-analysis §5.4`, QA-2 / Dart-2, `flows.md Flow C`, `lib/app/deep_link_handler.dart`. 북적북적의 "우연한 인스타 캡처 바이럴"을 deep link 메커닉으로 의도 설계한다.

---

## 1. 목적 / 진입·이탈 / 라우트

- **목적**: 단톡방에서 누가 책귀 카드를 공유했을 때, 받은 사람이 카드를 탭 → 책귀가 열리며 그 책 정보를 보여주고 **"내 서재에 담기" 1탭**으로 끝나게 한다. 받는 사람이 책귀 사용자가 아니어도(미설치/미로그인) 막다른 골목 없이 흘러야 함.
- **라우트**: 이미 있는 `/book/:id` (게스트 허용 — `router.dart`의 redirect 통과 목록에 포함됨). `?from=share`(또는 `from=kakao`) 쿼리로 "deep link로 들어왔음"을 표시 → "내 서재 담기" CTA를 1급으로 노출 + (V1.5) 보낸 사람·인용구 컨텍스트.
- **deep link URI**: `io.github.tgparkk.bookquote://book/<bookId>?from=share[&quoteId=<id>]`. AndroidManifest의 `<data android:scheme="io.github.tgparkk.bookquote" />`는 host 제한 없음 → `book/...` path도 들어옴. iOS `CFBundleURLSchemes` 동일. **현재 갭**: `deep_link_handler.dart`가 `/auth/callback`만 처리하고 그 외 URI는 `return`으로 무시 → 핸들러를 일반화해야 함(§6).
- **진입**:
  - 카톡/인스타 등에서 카드(또는 카드에 붙은 텍스트 링크 — V1) / 카카오 메시지 카드의 버튼(V1.1) 탭
  - 콜드스타트(앱 미실행 상태에서 링크 탭): `app_links`의 `getInitialLink`
  - 웜(앱 실행 중): `app_links`의 `uriLinkStream`
  - 앱 미설치 → 스토어 → 설치 후: deferred deep link(Universal/App Link 필요 — §3·§7)
- **이탈**:
  - "내 서재에 담기" 1탭 → `book_repository.addToLibrary` → "서재에 담았어요" Toast → 그 책 상세 유지(또는 서재로) — 다음 행동: "이 책 인용구 추가"(→ `/quote/new?bookId=`) 권유
  - 미로그인 → "담기" 탭 → `/auth/login?from=/book/:id` → 로그인 후 복귀해서 담기 자동 실행(또는 재노출) — deep link payload를 로그인 동안 보존
  - 뒤로/홈 → BottomNav 홈으로(또는 앱 종료)

---

## 2. 와이어프레임

```
┌─────────────────────────────────────────┐
│ ←  책              지영님이 단톡방에서 공유 │  AppBar — from=share/kakao면 보낸 사람 컨텍스트(V1.5)
├─────────────────────────────────────────┤
│  ┌────┐  미드나잇 라이브러리              │  표지(BookCover) + 제목/저자/출판사
│  │표지│  매트 헤이그 · 인플루엔셜          │  ISBN, 설명(점진적 공개 — 길면 "더 보기")
│  │    │  ISBN 9791191056556              │
│  └────┘                                  │
│  ┌─────────────────────────────────────┐ │  (quoteId 있으면) 받은 인용구 카드
│  │ "가장 깊은 밤에 가장 빛나는 별이      │ │  — 인용구 텍스트 + 페이지 + "지영님의 인용구"
│  │  보인다."     p.132 · 지영님의 인용구 │ │
│  └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐  │
│ │          ＋ 내 서재에 담기           │  │  Primary CTA — accent500. 이미 담겼으면
│ └─────────────────────────────────────┘  │  "이미 서재에 있어요 ✓" (비활성)
│   비로그인이면: 책 정보 먼저 → "담기" 누르면 │
│   로그인 → 원래 화면 복귀해 담기            │  (안내 — 미로그인 시만)
└─────────────────────────────────────────┘
```

기존 `/book/:id` read-only 화면(`book_detail_screen.dart`)에 ① `?from=` 컨텍스트 헤더 ② "내 서재에 담기" CTA(deep link 진입 시 1급, 일반 진입 시에도 노출 가능) ③ (quoteId 있을 때) 받은 인용구 카드 — 를 더한다. 책 상세 보강은 `book-detail.md`(그룹 2)와 공유.

---

## 3. 상태

| 상태 | 트리거 | 처리 | 표시 | 심각도 |
|---|---|---|---|---|
| 로딩: 책 fetch | deep link 진입 | `bookByIdProvider(id)` — 표지·메타 로딩 스피너. 표지는 `BookCover` placeholder fallback | Inline | 낮음 |
| 로딩: 인용구 fetch (quoteId 있을 때) | — | 인용구 카드 영역만 미니 스피너 | Inline (영역) | 낮음 |
| 로딩: "담기" 처리 | CTA 탭 | `addToLibrary` `<300ms`. 버튼 inline 스피너. 낙관적으로 "담김" 표시 후 실패 시 롤백 | Inline | 중간 |
| 빈 | 해당 없음 (책 ID로 진입) | — | — | — |
| 에러: 그 책/인용이 삭제됨 (`PGRST116`) | `BusinessError` | "이 책은 더 이상 볼 수 없어요" 화면 + [홈으로] / [책 검색]. (`flows.md` Flow C 5.4) | Empty | 중간 |
| 에러: 인용구가 비공개/차단된 사용자 | RLS 필터 | 책 상세는 보여주되 그 인용구는 표시 안 함. "내 서재 담기"는 가능 | (인용구 영역만 숨김) | 중간 |
| 에러: "담기" 중 네트워크 끊김 | `NetworkError` | "연결을 확인해주세요" + [다시 시도]. 낙관적 표시 롤백 | Toast → 재시도 | 중간 |
| 에러: 이미 서재에 있는 책 (`23505` unique_violation on user_books) | `BusinessError` | "이미 서재에 있는 책이에요" Toast(에러 아닌 정보성) + 그 책 상세 유지. 중복 INSERT 안 함 | Toast (정보성) | 중간 |
| 에러: deep link URI 변조/형식 오류 (`://book/` id 없음) | `ValidationError` | 무시하고 홈으로. 크래시 금지 | (조용히) | 낮음 |
| 에러: deep link 무한 루프 (잘못된 redirect / `/book/:id`가 다시 deep link 트리거) | — | deep link는 **앱당 1회 consume** 후 클리어. 라우터 redirect 최대 1홉. 이미 처리한 URI를 세션 단위 기억 | (방어) | 중간 |
| 미로그인 진입 | redirect 안 함 (게스트 허용) | 책 상세 read-only로 먼저 보여줌. "담기" 탭 → `/auth/login?from=/book/:id` → 로그인 → 복귀해 담기 자동 실행(또는 재노출). deep link payload를 로그인 동안 보존 | (정상 흐름) | 높음 (현재 미구현 — §6) |
| 콜드스타트 + 미로그인 + deep link | `getInitialLink` | `/splash` → 로그인 게이트 → 로그인 후 보존된 deep link 소비 → 책 상세. 가입 흐름(`flows.md` Flow A 3.4 profiles trigger 지연)이면 "프로필 생성 중" 짧은 대기 후 책 상세 | (정상 흐름) | 높음 |
| 앱 미설치 → 설치 후 | deferred deep link | 커스텀 스킴(`io.github.tgparkk.bookquote://`)은 미설치 시 OS가 "열 수 없음" — fallback 안 됨. **진짜 fallback(웹 뷰어)은 Universal Link/App Link(https://) + 도메인 + apple-app-site-association/assetlinks.json 필요 = 인프라 작업 → V1.5.** V1은 "앱 있는 사람끼리만 deep link 동작" 한계 수용 + 단톡방 텍스트에 "책귀 앱에서 보기" 안내 | (V1 한계) | 중간 |
| 오프라인 진입 | `connectivity_plus` | 책 fetch 실패 → "연결을 확인해주세요" + [다시 시도]. "담기"는 온라인 필요 | 배너 + 재시도 | 중간 |

---

## 4. 인터랙션

- deep link 수신 → `deep_link_handler`가 URI 분기: auth code 포함이면 `getSessionFromUrl`(기존), 아니면 `router.go('/book/$id?from=$from')`. 미로그인이면 router redirect가 `/auth/login?from=...`로 보냄 + handler가 pending deep link 보관 → 로그인 후 `currentSessionProvider` 변화 감지 → pending 소비 → `router.go(원래 경로)`.
- "내 서재에 담기" 탭 → `addToLibrary(bookId)` (idempotent `onConflict: 'user_id,book_id'`). 성공 → 버튼 → "서재에 담았어요 ✓"(또는 "이미 서재에 있어요"). Toast + (선택) "이 책에서 인용구 모으기" 권유 카드.
- (quoteId 있을 때) 받은 인용구 카드 탭 → 그 인용구로 카드 만들기(`/quote/$quoteId/card`)는 V1.5(받은 인용구를 내 quotes로 복제 후) — V1은 텍스트로 보여주기만.
- 같은 deep link를 단톡방 스크롤하며 여러 번 탭 → 이미 담겼으면 정보성 Toast(폭탄 방지 — `clearSnackBars`).
- 뒤로 → BottomNav 홈(셸 안)으로. (deep link로 들어와 셸 밖이면 셸 홈으로 이동.)

---

## 5. 토큰

| 영역 | 토큰 |
|---|---|
| 화면/AppBar | `secondary200` 배경, 투명 AppBar. 보낸 사람 컨텍스트 ui xxs `primary400` |
| 표지 | `BookCover` 64×94 (또는 더 크게) |
| 책 메타 | 제목 ui w600 16~18 `primary900` / 저자·출판사 ui 12 `primary500` / ISBN ui xxs `primary400` / 설명 ui 13 `primary600`, 4줄 후 "더 보기" `accent600` |
| 받은 인용구 카드 | `copper-100`(accent100 #FAEBD6) 배경 + `accent300` border + `AppRadius.md` / 인용구 `AppFonts.quote` 13 `primary800` / "지영님의 인용구" ui xxs `primary400` |
| Primary CTA | `accent500` 배경 / `secondary50` 텍스트 ui w600 14 / `AppRadius.md` / `AppShadow.floating` / 이미 담김 = `secondary500` 배경·`primary400` 텍스트 + ✓ |
| 안내 (미로그인) | ui xxs `primary400`, 중앙 |
| "더 이상 볼 수 없어요" | Empty 상태 — `primary400` 텍스트 + [홈으로]/[책 검색] 버튼 |

---

## 6. 재사용 / 신규

**재사용**: `book_detail_screen.dart`(read-only 표시 — 확장), `bookByIdProvider`(book_providers.dart), `BookCover`, `book_repository.addToLibrary`/`getById`, `router.dart`의 `/book/:id` 라우트(게스트 허용 — 그대로), `app_links`(deep_link_handler에서 이미 사용).

**신규 / 변경**
- `lib/app/deep_link_handler.dart` **일반화** — 현재 `_handle()`이 `uri.path.startsWith('/auth/callback') || uri.host == 'auth' || code 포함`이 아니면 `return`. → "URI dispatcher"로: auth code면 `supabase.auth.getSessionFromUrl`, 아니면 `router.go(uri.path + uri.query)`. 콜드스타트 미로그인 시 `_pendingDeepLink`에 보관 → 로그인 후 소비. 이미 처리한 URI를 세션 단위 set으로 기억(무한 루프 방지). GoRouter 인스턴스 접근(전역 `appRouter` 또는 ProviderContainer 경유).
- `lib/features/book/presentation/book_detail_screen.dart` 확장 — `from` 쿼리 파라미터 받아 컨텍스트 헤더 + "내 서재에 담기" CTA + (quoteId 있으면) 받은 인용구 카드. `addToLibraryControllerProvider`(낙관적).
- AndroidManifest/Info.plist: 스킴은 이미 등록됨(추가 설정 불필요 — host 미제한). **V1.5에 Universal/App Link 추가 시** `apple-app-site-association`(도메인의 `.well-known/`) + `assetlinks.json` + `<intent-filter android:autoVerify="true">` 필요 — 도메인 확보 후.
- `pubspec.yaml`: 추가 없음(`app_links`·`go_router` 이미 있음).

---

## 7. 엣지 / 접근성

**교차 관심사**: ④ 막다른 골목 금지 = 미로그인이어도 책 정보 먼저 보여주고 담기→로그인→복귀; 미설치는 V1 한계(웹 뷰어 V1.5)지만 안내 카피로 완충. ② 데이터 유실 = deep link payload를 로그인 동안 보존. ③ PII = 보낸 사람 이름·인용구를 로그에 안 남김. ⑥ 에러 표시 일관성(삭제=Empty, 중복=정보성 Toast). ⑦ `/book/:id`는 게스트 허용(deep link용) — DECISIONS와 정합. ⑧ 해당 없음.

| 엣지 | 심각도 | 처리 |
|---|---|---|
| deep link인데 그 책이 books 테이블에 없음(보낸 사람만 가지고 있던 임시 데이터?) | 낮음 | books는 공유 시 upsert되어 있어야 정상. 없으면 "더 이상 볼 수 없어요" |
| 받는 사람이 그 책을 이미 가지고 있음 | 중간 | `23505` → "이미 서재에 있어요" 정보성 Toast |
| 받는 사람이 보낸 사람을 차단함 | 낮음 | 책 정보만, 보낸 사람 컨텍스트·인용구 숨김 |
| deep link로 가입 → profiles trigger 지연 | 낮음 | "프로필 생성 중" 짧은 대기 후 책 상세 |
| 동일 deep link 여러 번 탭 | 낮음 | 이미 담겼으면 idempotent, Toast 폭탄 방지 |
| `from=share`인데 quoteId 없음 (텍스트 링크만 공유, 카드 메타 없음) | 낮음 | 받은 인용구 카드 영역 생략, 책 정보 + 담기만 |
| 웹에서 deep link (브라우저로 `https://...` 열림 — V1.5) | — | V1.5 웹 뷰어가 같은 책 상세를 보여주고 "앱에서 담기"/"앱 설치" 안내 |

**접근성**: "내 서재에 담기" ≥48dp, 라벨 명확. 표지에 `'$title 표지'` 또는 표지 없으면 placeholder에 제목 텍스트. 받은 인용구 카드에 `'$senderName이 보낸 인용구: $text, $page페이지'` semantics. "이미 서재에 있어요" 상태도 스크린리더에 명시. 보낸 사람 컨텍스트는 색만으로 구분 안 함(텍스트).

---

## 변경 이력
- 2026-05-11 초안 (매니저 종합 — competitor-screen-analysis §5.4 + QA-2 + Dart-2 + flows.md Flow C + deep_link_handler.dart 현황).
