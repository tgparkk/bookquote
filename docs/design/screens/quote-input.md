# 화면 설계 — 인용구 입력 `/quote/new`

> 그룹 1 · Stage 2 최우선. 입력 근거: `competitor-screen-analysis-2026-05-11.md §5.1`, QA-1 / Dart-1 가상 팀 산출. 관련 결정: DECISIONS 2026-05-11(내장 OCR 안 함 / 경량 아웃박스).

---

## 1. 목적 / 진입·이탈 / 라우트

- **목적**: 책의 한 구절을 가장 빠르게 책귀에 넣는다. 직접 타이핑 또는 OS 기능(iOS Live Text·구글렌즈)으로 복사한 텍스트 붙여넣기 → 책 연결 → (선택) 페이지·무드 → 저장 → 곧장 카드 만들기로 이어짐. **"사진 한 장 → 1분 → 단톡방"의 입력 절반.**
- **라우트**: `GoRoute(path: '/quote/new', parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => QuoteInputScreen(bookId: s.uri.queryParameters['bookId']))` — 이미 `router.dart`에 배선됨. BottomNav 셸 밖 풀스크린. 인증 가드 라우트(미로그인 → `/auth/login?from=/quote/new`).
- **진입**:
  - BottomNav `[＋]` sentinel 탭 (책 미지정 → `/quote/new`)
  - 책 상세 / 서재의 "이 책 인용구 추가" (`/quote/new?bookId=:id` — 책 prefill)
  - 홈 빈 상태의 "＋ 인용구 추가" 버튼
- **이탈**:
  - "카드 만들기 →" → `context.push('/quote/$createdId/card')` (저장 후)
  - "저장만 하기" → 저장 후 `pop()` → 진입 직전 화면 (홈/서재/책 상세)으로, "인용구를 저장했어요" SnackBar
  - ✕ / 시스템 뒤로 → 작성 내용 있으면 폐기 확인 다이얼로그(아래 §4), 없으면 즉시 `pop()`

---

## 2. 레이아웃 와이어프레임

```
┌─────────────────────────────────────────┐
│ ✕  인용구 추가                912 / 2000 │  AppBar — 닫기 / 글자수 카운터(임계 근처만 색 변화)
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ 가장 깊은 밤에 가장 빛나는 별이      │ │  인용구 본문 — 멀티라인 TextField
│ │ 보인다.                             │ │  AppFonts.quote(NotoSerifKR), 자동 포커스+키보드
│ │ |                                   │ │  placeholder: "좋아하는 한 줄을 입력하거나,
│ │                                     │ │              아래 '붙여넣기'를 눌러보세요"
│ └─────────────────────────────────────┘ │
│ ┌── 📋 클립보드에 새 텍스트가 있어요 ──┐ │  붙여넣기 감지 배너 — 클립보드에 텍스트 있고
│ │   "그래도 별은 떠 있었다…"  [붙여넣기]│ │  본문이 비었거나 사용자가 안 만진 경우만 노출.
│ └─────────────────────────────────────┘ │  탭 → 본문에 채움 + 배너 사라짐
│                                         │
│ ┌── 📕 미드나잇 라이브러리 ─── 변경 ▸ ─┐ │  책 영역 — book prefill 시 카드, 아니면
│ │  매트 헤이그 · 인플루엔셜             │ │  "＋ 책 연결" 버튼. 탭 → showBookSearchSheet
│ └─────────────────────────────────────┘ │
│  페이지 [ 132 ]              무드 ▾      │  페이지 = 숫자 키패드, 선택. 무드 = 칩 펼침
│  〔위로〕〔먹먹〕〔새벽3시〕〔통찰〕〔설렘〕 │  멀티 선택(최대 3), 토글, 색 코딩+텍스트
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │           카드 만들기 →             │ │  Primary CTA — accent500. 본문 비면 비활성
│ └─────────────────────────────────────┘ │
│             저장만 하기                  │  Tertiary — 텍스트 버튼, ink-400
└─────────────────────────────────────────┘
```

OCR "모드"는 없음 — 별도 카메라 화면 안 만든다. 사진→텍스트는 사용자가 OS에서 처리하고 **붙여넣기 배너**로 들어온다.

---

## 3. 상태

| 상태 | 트리거 | 처리 | 표시 | 심각도 |
|---|---|---|---|---|
| **로딩: 진입** | 화면 push | 즉시 (<200ms). 스켈레톤 불필요. TextField 자동 포커스 → 키보드 (실패 시 사용자 탭으로 복구) | — | 낮음 |
| **로딩: book prefill** | `?bookId=` 로 진입 | `bookByIdProvider(id)` — 책 카드 영역만 미니 스피너, 나머지 입력은 즉시 가능 | Inline (영역 한정) | 낮음 |
| **로딩: 저장** | "카드 만들기" / "저장만" 탭 | `<300ms` 목표. 버튼 inline 스피너 + 입력 잠금(화면 비차단). 1s 초과 시 전체 dim 오버레이 | Inline → (1s+) Modal-lite | 중간 |
| **빈** | 첫 진입 | 정상 출발점 — empty-state 페이지 아님. placeholder + "＋ 책 연결" + 무드 미선택 | — | — |
| **에러: 네트워크 끊김 (저장)** | 저장 중 오프라인 | **실패 아님** → 아웃박스(`shared_preferences` JSON 리스트)에 영속화 → "오프라인이에요. 연결되면 자동 저장돼요" + 화면 닫힘(또는 "동기화 대기" 상태). 책: 골랐으면 `book_id`, 아니면 `manual_book_text` | Toast | 높음 (데이터 보존 필수) |
| **에러: Supabase 5xx / 알 수 없음** | retryable | Toast "잠시 후 다시 시도해주세요" + 폼 100% 유지 + [다시 시도] | Toast + 폼 유지 | 높음 |
| **에러: 세션 만료 (PGRST301 / JWT)** | AuthError | 입력을 아웃박스에 임시 저장 → Modal "다시 로그인이 필요해요" → 로그인 후 복귀 시 복원 | Modal | 높음 |
| **에러: 본문 빈 채로 저장** | ValidationError `VAL_REQUIRED` | "카드 만들기" 버튼 자체를 비활성 (선제 방지) | 비활성 버튼 + (강제 시) Inline | 중간 |
| **에러: 본문 너무 김 (>2000자)** | ValidationError `VAL_TOO_LONG` | 카운터를 임계 근처(예: 1800+)에서 copper→error 색으로. 2000 초과 시 Inline "인용구는 한 구절만 — 너무 길어요". **하드 자르기 금지** — 사용자가 다듬게 | Inline + 카운터 | 중간 |
| **에러: 책 검색 실패 / 0건 / rate limit / 오프라인** | (시트 내부, `book-search-sheet.md` 참조) | 시트에서 처리 + [ISBN 직접 등록]/[직접 등록] 출구. 책 못 골라도 인용구는 저장 가능(BOOK_UNRESOLVED) | 시트 내 Inline/Empty | 중간 |
| **에러: 디스크 가득 (아웃박스 영속화 실패)** | StorageError `STORAGE_DISK_FULL` | Modal "저장 공간이 부족해요" + "인용구를 클립보드로 복사할까요?"(최후 보존 수단) | Modal | 높음 |
| **오프라인 (진입 시)** | `connectivity_plus` 감지 | 상단 배너 "오프라인 — 저장하면 연결될 때 동기화돼요". 책 영역의 "＋ 책 연결"은 시트가 캐시(`findCachedByQuery`)만 보여주고 알라딘 검색 비활성 + "책 이름 직접 입력" 옵션 노출 | 배너 | 중간 |
| **권한 거부** | 해당 없음 | 이 화면은 카메라·사진 권한을 요청하지 않는다 (내장 OCR 없음 → 권한 흐름 0). 붙여넣기는 클립보드 — iOS는 붙여넣기 시 OS가 1회 알림 띄울 수 있으나 우리 권한 흐름 아님 | — | — |

---

## 4. 인터랙션 명세

- **자동 포커스**: 진입 시 본문 TextField 포커스 + 키보드. book prefill 진입이어도 동일(바로 쓰기 시작).
- **붙여넣기 배너**: 화면 포커스 획득 시(그리고 앱 포그라운드 복귀 시) `Clipboard.getData('text/plain')` 확인 → 비어있지 않고 본문이 비었거나 사용자가 한 번도 안 만졌으면 배너 노출(미리보기 ~40자 말줄임). [붙여넣기] 탭 → 본문에 set, 배너 dismiss, 커서 끝으로. 사용자가 본문을 직접 만지기 시작하면 배너 자동 dismiss(덮어쓰기 방지). 배너는 X로도 닫힘. — **PII**: 클립보드 미리보기 텍스트를 로그에 안 남김.
- **책 연결**: 책 카드/버튼 탭 → `showBookSearchSheet(context)` → `Future<Book?>`. 시트는 모달이라 본문·페이지·무드 state 유지(§7 원칙 5). 시트의 "서재에 추가했어요" SnackBar는 이 진입에선 억제(시트에 `suppressAddedToast: true` 같은 옵션 추가 — Dart-1). 반환된 `Book` → 책 영역 갱신. "변경 ▸"으로 다시 호출 가능. 책 연결 안 해도 됨(BOOK_UNRESOLVED).
- **페이지**: 숫자 키패드(`TextInputType.number` + `FilteringTextInputFormatter.digitsOnly`). 양의 정수만 의미 있게 처리; 잘못된 값은 저장 시 `page=null`. 막지 않음(선택 항목).
- **무드 칩**: "무드 ▾" 탭 → 칩 행 펼침(또는 항상 노출). 칩 탭 = 토글. 멀티 선택, **최대 3개** — 4번째 시도 시 "최대 3개까지" Toast. 색 코딩 + 텍스트 라벨 둘 다(색맹). 선택 상태 = ink 배경+흰 글씨. 무드 0개 저장 허용.
- **카드 만들기**: 본문 비었으면 비활성. 탭 → `createQuoteController` 호출(낙관적 — `client-architecture.md 7.B` 패턴) → 성공 시 `context.push('/quote/$id/card')`. 실패 시 §3 에러.
- **저장만 하기**: 동일 저장 → 성공 시 `pop()` + SnackBar.
- **뒤로/✕/시스템 뒤로/iOS 스와이프 뒤로**: `PopScope(canPop: hasNoEdits, onPopInvoked: ...)` — 작성 내용(본문/책/페이지/무드 중 하나라도) 있으면 다이얼로그: **"작성 중인 인용구를 어떻게 할까요?"** → [임시저장하고 나가기] (draft로 저장 → 다음 진입 시 "이어쓰기/폐기") / [폐기] / [계속 쓰기]. 저장 중(로딩)에 뒤로 → 저장 완료까지 차단 또는 아웃박스에 넣고 닫기 — 중간 상태로 사라지지 않음.
- **draft 자동 저장**: 본문 변경 시 debounce 1s로 `shared_preferences`에 draft 1건(본문+book_id 또는 manual_book_text+page+moods) 저장. 진입 시 draft 존재하면 "작성 중이던 인용구가 있어요. 이어서 쓸까요? / 폐기" — error-handling.md "데이터 절대 유실 금지". 저장 성공 시 draft 클리어. (아웃박스와 별개: draft = 작성 중 1건, 아웃박스 = 저장 눌렀는데 오프라인이라 대기 중 N건.)
- **앱 백그라운드 → kill → 재진입**: draft 메커니즘으로 복구.
- 애니메이션: 키보드 슬라이드(OS 기본), 붙여넣기 배너 fade+slide-in(150ms), 무드 칩 펼침 expand(200ms). 과한 모션 금지(디자인 시스템 "차분한").

---

## 5. 디자인 토큰 매핑 (`lib/core/theme/tokens.dart`)

| 영역 | 토큰 |
|---|---|
| 화면 배경 | `AppColors.secondary200` (#FAFAF8 paper base) |
| AppBar | 투명, elevation 0 (`AppTheme.appBarTheme`) · 타이틀 `AppTextStyles` ui w600 16 / `AppColors.primary900` · ✕ 아이콘 `primary500` |
| 글자수 카운터 | ui xxs(9) `primary400` → 임계(1800+) `accent500` → 초과 `semanticError` |
| 인용구 TextField | 텍스트 `AppFonts.quote` (NotoSerifKR w400) 16~17 / `primary800` · placeholder `primary400` · 컨테이너 `secondary100` 배경 + `primary200` border 1.5 + `AppRadius.sm` · 포커스 시 border `accent500` (`AppTheme.inputDecorationTheme`) · padding `AppSpacing.s4`(16) |
| 붙여넣기 배너 | 배경 `secondary300` / 아이콘·텍스트 `primary500` / [붙여넣기] = `accent500` 텍스트 버튼 / `AppRadius.sm` |
| 책 카드 | `secondary100` 배경 + `primary100` border + `AppRadius.md` · `BookCover` 위젯(34×50) · 제목 ui w600 12 `primary800` / 메타 ui xxs `primary400` · "변경 ▸" `accent600` |
| 페이지 입력 | 작은 `secondary100` 박스 + `primary200` border, ui 12 `primary700`, width ~60 |
| 무드 칩 (미선택) | 배경 `secondary300`(또는 무드별 연한 톤) / 텍스트 무드별 어두운 톤 / border 1 `secondary500` / radius pill / ui xxs(9.5) |
| 무드 칩 (선택) | 배경 `primary900` / 텍스트 `secondary50` / border `primary900` |
| Primary CTA | `accent500` 배경 / `secondary50` 텍스트 ui w600 14 / `AppRadius.md` / `AppShadow.floating` / 비활성 시 `secondary600` 배경·`primary400` 텍스트 |
| 저장만 하기 | 텍스트 버튼, ui 13 `primary500` |
| 오프라인 배너 | `semanticWarningLight` 배경 / `semanticWarning` 텍스트 / 화면 상단 full-width |
| Toast (SnackBar) | `AppTheme.snackBarTheme` — `primary900` 배경, action `accent400` |
| 에러 Inline | `semanticError` 텍스트 ui xs |

새 토큰 필요: 무드별 연한 배경/어두운 텍스트 쌍(예: 위로=success 계열, 먹먹=neutral 계열, 새벽3시=info 계열…). `tokens.dart`에 `moodColors` 맵 추가 — `card-editor.md`와 공유(카드에도 무드 칩 표시).

---

## 6. 재사용 컴포넌트 / 신규

**재사용 (코드에 있음)**
- `showBookSearchSheet(context)` → `Future<Book?>` (`book/presentation/book_search_sheet.dart`) — 단 `suppressAddedToast`/문구 옵션 파라미터 추가 필요(Dart-1)
- `bookByIdProvider(id)` (`book/state/book_providers.dart`) — `?bookId=` prefill
- `book_repository.upsertBook` (시트 내부에서 이미 호출) / `getById`
- `BookCover` 위젯 (`book/presentation/widgets/book_cover.dart`) — placeholder fallback 포함
- `tokens.dart`: `getQuoteFontSize`/`getQuoteLineHeight`(입력 중 "이 길이면 카드에서 N px" 미리보기 줄 때), `AppFonts.quote`, `AppColors.accent500`, `AppSpacing`, `AppRadius`, `AppShadow`
- `router.dart`의 `/quote/new?bookId=` 라우트 (배선됨)

**신규**
- `supabase/migrations/<ts>_quotes.sql`:
  ```sql
  create table public.quotes (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references auth.users(id) on delete cascade,
    book_id         uuid references public.books(id) on delete set null,   -- 오프라인/미등록 도서 허용
    manual_book_text text,                                                 -- book_id 없을 때 사용자가 적은 책 이름 (V1.5 재매칭용)
    text            text not null check (char_length(text) between 1 and 2000),
    page            int  check (page > 0),
    source          text not null default 'manual' check (source in ('manual','clipboard')),
    moods           text[] not null default '{}',
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
  );
  create index quotes_user_created_idx on public.quotes (user_id, created_at desc);
  create index quotes_user_book_idx    on public.quotes (user_id, book_id);
  -- RLS: select/insert/update/delete 모두 auth.uid() = user_id  (user_books 마이그레이션 패턴 복사)
  -- updated_at: set_updated_at() 트리거 (books 마이그레이션에 정의된 함수 재사용)
  ```
  무드는 `text[]` (별도 테이블 X, DB enum X — 태그셋 변경 시 마이그레이션 회피). 앱이 `enum QuoteMood`로 화이트리스트 강제. 카드 디자인 상태는 quotes에 안 넣음 → Stage 3 `cards` 테이블.
- `lib/features/quote/domain/quote.dart` — `@freezed` 모델 (`book.dart`처럼 `@JsonKey(name:)` snake_case 매핑)
- `lib/features/quote/data/quote_repository.dart` — `createQuote(input)`, `updateQuote`, `listMyQuotes({bookId, moods})`, `getById` (`book_repository.dart`의 `PostgrestException → 도메인 예외` 패턴 미러링)
- `lib/features/quote/state/quote_providers.dart` — `myQuotesProvider({bookId})` (FutureProvider.family), `createQuoteControllerProvider` (NotifierProvider, 낙관적 생성 + `ref.invalidate`)
- `lib/features/quote/data/quote_outbox.dart` — `shared_preferences` JSON 리스트 아웃박스: `enqueue(QuoteInput)`, `pending()`, `flush()` (포그라운드/연결회복 시 best-effort). `pubspec.yaml`에 `shared_preferences` 추가.
- `lib/features/quote/quote_input_screen.dart` — 현재 스텁(StatelessWidget) → `ConsumerStatefulWidget` 전면 재작성. `TextEditingController`(본문), 선택 책 state, 페이지 컨트롤러, 무드 Set, draft autosave, 붙여넣기 감지.
- `pubspec.yaml`: `shared_preferences`, `connectivity_plus` 추가. (OCR·카메라 패키지는 추가 안 함 — DECISIONS 2026-05-11.)

---

## 7. 엣지 케이스 / 접근성

**교차 관심사 (공통 8원칙 적용)**: ① 오프라인=1급(아웃박스) ② 데이터 유실 금지(draft+아웃박스) ③ PII 로그 금지(본문·붙여넣기 내용 미전송) ④ 막다른 골목 금지(책 못 골라도 저장, 시트에 ISBN 직접 등록) ⑤ 시트 왕복 시 입력 보존 ⑥ 에러 표시 일관성 ⑦ 인증 가드 ⑧ 해당 없음(이 화면은 카드 미리보기 없음).

**화면 고유 엣지**

| 엣지 | 심각도 | 처리 |
|---|---|---|
| 본문에 이모지·전각 따옴표·특수문자 | 낮음 | 그대로 저장(UTF-8). 카드 렌더 시 이모지 컬러 글리프 fallback 체인 |
| 본문에 줄바꿈 다수 (시 구절) | 낮음 | 보존, 멀티라인. 카드에서도 줄바꿈 유지(`card-editor.md` 협의) |
| 1단어 인용구 ("사랑") | 낮음 | 허용 (`VAL_TOO_SHORT` 안 씀 — 1글자도 valid). 카드는 폰트 자동 확대로 균형 |
| 같은 인용구 중복 저장 | 중간 | 차단 안 함(같은 문장 두 번 모으기는 정상). 단 직전 저장과 `(book_id, text)` 동일하면 "방금 같은 인용구를 저장했어요. 또 저장할까요?" 확인 1회 |
| 책 없이 저장 | 중간 | 허용 (BOOK_UNRESOLVED) — `book_id`/`manual_book_text` 둘 다 null도 OK. "책은 나중에 연결하세요" 안내. 책 상세/서재에서 사후 매핑 경로 |
| 거대한 텍스트 붙여넣기 (웹 기사 통째) | 중간 | `VAL_TOO_LONG` + 카운터. "인용구는 한 구절만 — 너무 길어요" |
| 클립보드에 책귀가 방금 만든 카드 텍스트가 또 있을 때 | 낮음 | 배너 정상 노출 — 무해 |
| 입력 중 시트 다녀온 뒤 본문 유실? | 높음 | 시트는 모달 → `TextEditingController` state 유지. **회귀 테스트 대상으로 명문화** |
| 페이지에 음수/0/문자/매우 큰 수 | 낮음 | 숫자 키패드 + 양의 정수만; 잘못되면 `page=null`. 막지 않음 |
| 무드 4개째 선택 시도 | 낮음 | "최대 3개까지" Toast, 4번째 무시 |
| draft 복원 후 사용자가 본문 다 지움 | 낮음 | 빈 본문 = "카드 만들기" 비활성. 폐기 다이얼로그는 그대로 동작 |

**접근성**
- 대비: 인용구 텍스트 `primary800` on `secondary100` ≈ 충분(AA 4.5:1+). 무드 칩은 색 + 텍스트 라벨 둘 다 — 색만으로 의미 전달 X. placeholder `primary400`는 보조 정보(입력 시작하면 사라짐)라 허용.
- 터치 타깃: 무드 칩·"변경 ▸"·페이지 입력·붙여넣기 버튼 모두 ≥48dp 높이(시각 크기는 작아도 hit area 확장).
- 스크린리더: TextField에 `label: '인용구 본문'`, 카운터에 `'$n / 2000자'` semantics, 무드 칩에 `'$mood, ${selected ? "선택됨" : "선택 안 됨"}'` toggle semantics, CTA `'카드 만들기, ${enabled ? "" : "인용구를 먼저 입력하세요"}'`.
- 키보드 전용(웹): Tab 순서 = 본문 → 붙여넣기 → 책 → 페이지 → 무드 → 카드만들기 → 저장만. Enter는 본문에서 줄바꿈(저장 아님 — 멀티라인).

---

## 변경 이력
- 2026-05-11 초안 (매니저 종합 — competitor-screen-analysis §5.1 + QA-1 + Dart-1). 결정 반영: 내장 OCR 제거(클립보드 붙여넣기로 대체), 경량 아웃박스.
