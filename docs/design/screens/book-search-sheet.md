# 화면 설계 — 책 검색 시트 (모달) (이미 구현 — 역정리 + 개선 권고)

> 그룹 3. 입력 근거: `lib/features/book/presentation/book_search_sheet.dart`, `lib/features/book/state/book_search_controller.dart`, `lib/features/book/data/book_repository.dart`, `supabase/functions/aladin-search/`(코드 기준), `competitor-screen-analysis §5.8`. **모달 시트** — 서재 FAB·인용구 입력 화면에서 호출, `Future<Book?>` 반환.

## 1. 목적 / 진입·이탈
- **목적**: 알라딘 API 검색 + 로컬 캐시(`public.books`)에서 책을 찾아 선택 → `public.books`에 영속화(upsert)하고 그 `Book`을 반환. (서재 등록 = `user_books` INSERT는 호출자 책임 — 시트는 카탈로그 upsert만.)
- **호출**: `showBookSearchSheet(context) → Future<Book?>` (취소 시 null, 선택 시 영속화된 `Book`). `showModalBottomSheet<Book>(isScrollControlled: true, useSafeArea: true, backgroundColor: secondary100, shape: top radius xl)`, 높이 = 화면 90%.
- **진입**: 서재 `library_screen`의 FAB "책 추가" / 인용구 입력 `/quote/new`의 "＋ 책 연결"·"변경 ▸". **이탈**: 책 선택 → `Navigator.pop(book)` / dismiss(드래그 다운·바깥 탭·뒤로) → `Navigator.pop(null)`.

## 2. 와이어프레임
```
┌─────────────────────────────────────────┐
│              ────                        │  _DragHandle (36×4, primary200)
│  ┌─────────────────────────────────────┐ │
│  │ 🔍 책 제목, 저자, ISBN               │ │  TextField autofocus, enabled: !_saving
│  └─────────────────────────────────────┘ │  400ms 디바운스 → bookSearchQueryProvider
│  내 서재 카탈로그                          │  cached 섹션 (findCachedByQuery, ilike, limit 5)
│  ┌──┐ 미드나잇 라이브러리 · 매트 헤이그   │  _CachedRow
│  └──┘                                    │
│  알라딘 검색 결과                          │  fresh 섹션 (searchBooks Edge Function,
│  ┌──┐ 미드나잇 라이브러리 (개정판) · …    │  같은 isbn13은 캐시 우선)
│  └──┘ …                                  │  _FreshRow
└─────────────────────────────────────────┘
[ query 길이 < 2 / 빈 ]  현행: _EmptyState("찾는 책이 없어요") ← 검색 전인데 뜨는 흠
                          (개선) → cached 카탈로그 + "책 제목·저자·ISBN으로 검색해보세요" 안내
[ query 있고 결과 0건 ]  _EmptyState("찾는 책이 없어요. 제목 일부만 다시 시도하거나, 책 뒤표지 ISBN을 붙여넣어 보세요.")
                          (개선) + [ISBN으로 등록] [직접 입력해서 등록] 버튼 2개
[ 에러 ]                  _ErrorView: code=='RATE_LIMIT' → "오늘 책 검색이 일시적으로 제한됐어요…" / 그 외 "검색에 실패했어요. 네트워크 상태를 확인해주세요." ← 재시도 버튼 없음
[ _saving ]               반투명 0x66000000 오버레이 + 스피너
```

## 3. 상태 (코드 기준)
| 상태 | 처리 | 심각도 |
|---|---|---|
| 입력 | `_controller` + `_debounce` Timer(400ms) → `ref.read(bookSearchQueryProvider.notifier).update(value)` | — |
| 검색 | `bookSearchProvider`(`FutureProvider.autoDispose<BookSearchResult>`): `query.trim().length < 2`면 `BookSearchResult.empty()`. 아니면 `findCachedByQuery`(title/author ilike, limit 5)와 `searchBooks`(Edge Function) **동시 호출** → 같은 `isbn13`은 캐시 우선, remote는 캐시에 없는 것만 `fresh`. `_safeCached`: `BookRepositoryException` 시 빈 리스트. `_safeRemote`: `code == 'NOT_FOUND'` → 빈 응답 흡수, 그 외 rethrow | — |
| 로딩 | `result.when(loading: CircularProgressIndicator())` — **화면 전체 덮음**(캐시가 즉시 있어도 안 보임) | 낮음 (개선) |
| 빈: query < 2 / empty | `_EmptyState`("찾는 책이 없어요") — **검색 전인데 뜸**(혼란) | 중간 (개선) |
| 빈: query 있고 0건 | `_EmptyState` + "ISBN 붙여넣어 보세요" 안내 — **버튼 없음**(말만, 막다른 골목) | 높음 (개선) |
| 에러 | `_ErrorView`: `error is BookRepositoryException && code == 'RATE_LIMIT'` → "오늘 책 검색이 일시적으로…", 그 외 "검색에 실패했어요. 네트워크 상태를 확인해주세요." — **[다시 시도] 없음**. (Edge Function이 던지는 코드: `RATE_LIMIT`/`UPSTREAM`/`PARSE`/`NOT_FOUND`/`INVALID_INPUT` — `_shared/aladin.ts`; `book_repository`가 추가로 `UPSTREAM`(FunctionException)/`PARSE`(shape) 전파. **`RATE_LIMIT` 문자열이 실제로 도달하는지 검증 필요**) | 중간 (개선) |
| 선택 (`_onPick`) | `_saving` 가드 → `setState(_saving=true)` → `input.cached != null`이면 그대로 / `input.fresh != null`이면 `repo.upsertBook(dto)`(`upsert_book` RPC). `on BookRepositoryException` → `_saving=false` + SnackBar("책 저장 실패: ${e.message}" — raw). 성공 시 SnackBar("\"$title\"을(를) 서재에 추가했어요" 2s — **카피 부정확**, 실제론 카탈로그 upsert) → `Navigator.pop(book)` | 중간 (개선) |
| 오프라인 | `connectivity_plus` 미연동 — `searchBooks`가 `UPSTREAM`으로 rethrow → `bookSearchProvider` 전체 error → **cached 책도 안 보임** | 중간 (개선) |

## 4. 인터랙션
- 입력 → 400ms 디바운스 → 검색. 결과 = "내 서재 카탈로그"(cached) + "알라딘 검색 결과"(fresh) 두 섹션. 행 탭 → `_onPick` → upsert(fresh면) → `pop(book)`. dismiss = `pop(null)`. `_saving` 중엔 입력·탭 비활성(오버레이).
- (개선) ISBN 13자리 패턴(`^97[89]\d{10}$` 또는 `^\d{10,13}$`) 입력 시 → `lookupByIsbn` 우선 호출(현재는 일반 `searchBooks`로만).
- (개선) `_saving` 중 시트 닫기(뒤로/드래그 다운) 차단 — `PopScope`로 진행 중 upsert orphan 방지.

## 5. 토큰 매핑
- 시트 `AppTheme.bottomSheetTheme`(`secondary100` 배경, 상단 `AppRadius.xl`, backdrop) · `_DragHandle` `primary200` 36×4 · TextField `AppTheme.inputDecorationTheme`(filled, hint `primary400`, 포커스 `accent500`) · 섹션 헤더 ("내 서재 카탈로그"/"알라딘 검색 결과") `AppFonts.ui` w600 `AppFontSize.sm`(13) `primary500` · `_CachedRow`/`_FreshRow` = `BookCover` + 제목 `AppFontSize.base`(15) `primary800` + 저자·메타(판형·출판일) `AppFontSize.xxs`(9) `primary400` · `_EmptyState`/`_ErrorView` `primary400` (개선: + [ISBN 등록]/[직접 등록]/[다시 시도] `accent500` 텍스트 버튼) · `_saving` 오버레이 `Color(0x66000000)` + `CircularProgressIndicator(accent500)` · SnackBar `AppTheme.snackBarTheme`.

## 6. 재사용 / 신규
- 재사용: `bookSearchProvider`/`bookSearchQueryProvider`(`book_search_controller.dart`), `book_repository.findCachedByQuery`/`searchBooks`/`upsertBook`/`lookupByIsbn`/`getByIsbn`, `BookCover`, `_DragHandle`(이 파일 내), `tokens.dart`, `aladin-search` Edge Function. 신규(개선): `showBookSearchSheet(context, {bool suppressAddedToast = false})` 옵션, `_EmptyState`에 [ISBN으로 등록]/[직접 입력해서 등록] 버튼(→ `lookupByIsbn` / 최소 필드 `manual` book 생성), ISBN 패턴 감지 → lookup 분기, `_ErrorView`에 [다시 시도], `PopScope`(`_saving` 중 닫기 차단), `connectivity_plus` 연동(오프라인 = cached만 + "직접 입력").

## 7. 엣지 / 접근성 + 수정·보강 항목
**교차 관심사**: ④ 막다른 골목 금지 = ISBN/직접 등록 출구 + 알라딘 다운 시 [다시 시도] (현행 위반 — 개선 핵심) · ⑤ 시트 왕복 시 호출자 입력 보존(시트는 모달 → 호출자 state 안 건드림 — 회귀 테스트) · ② 데이터 = 시트 닫혀도 upsert 완료까지 책임(또는 `_saving` 중 닫기 차단) · ③ PII = 검색어 raw 미전송.
**양호(유지)**: 캐시 우선 + 알라딘 fresh 동시 호출 · isbn13 dedupe · 400ms 디바운스 · `_saving` 가드·오버레이 · `sheetCtx.mounted`/`context.mounted` 가드.
**수정·보강 권고 (현행 ≠ 권고)**:
- ① **검색 전 빈 결과 메시지** — `query.isEmpty`면 `_EmptyState`("찾는 책이 없어요") 대신 cached 카탈로그 + "책 제목·저자·ISBN으로 검색해보세요" 안내. "0건" 메시지는 `query.isNotEmpty && result.isEmpty`일 때만.
- ② **0건/알라딘 다운 시 정상 경로 출구 없음** — `_EmptyState`/`_ErrorView`에 [ISBN으로 등록]·[직접 입력해서 등록] 버튼 + 알라딘 다운 시 [다시 시도]. error-handling §6.4가 요구한 "ISBN 직접 입력 정상 경로 V1부터" 미구현.
- ③ **ISBN 패턴 감지 안 함** — 13자리 숫자 입력 시 `lookupByIsbn`으로 자동 전환(정확도↑).
- ④ **로딩 중 캐시 결과 못 봄** — `result.when(loading:)`이 화면 전체 덮음. 캐시는 동기로 먼저 그리고 fresh 영역만 하단 로딩 점("팔레트 비동기·카드 동기"와 같은 사고).
- ⑤ **`_onPick` 토스트 카피 부정확** — "서재에 추가했어요"는 실제론 `public.books` upsert일 뿐(서재 등록은 호출자). 인용구 입력 진입에선 더 부적절. `suppressAddedToast` 옵션 또는 문구 "이 책을 선택했어요".
- ⑥ **오프라인 미연동** — `searchBooks`가 `UPSTREAM` rethrow → 전체 error → cached도 안 보임. `_safeRemote`가 네트워크 오류도 흡수하고 cached만 반환하도록 + "오프라인이에요. 서재에 있는 책에서 고르거나 직접 입력하세요".
- ⑦ **`_saving` 중 시트 닫기 방어 미흡** — 오버레이는 있으나 시스템 뒤로/드래그 다운으로 닫으면 진행 중 `upsertBook` orphan. `PopScope`로 차단.
- ⑧ **"내 서재 카탈로그" 라벨 vs 의미** — cached는 `books` 테이블 전체(다른 사람 등록 포함) ilike 조회 — 내 서재가 아닐 수 있음. "이전 검색 결과" 또는 "캐시된 책" 정도로.
- ⑨ **시트 높이 고정 0.9 + 키보드** — 키보드 올라오면 결과 영역 좁아짐(작은 폰 1~2개만). `DraggableScrollableSheet` 검토(우선순위 낮음, V1 수용 가능).
**접근성**: TextField `label: '책 검색'`, 키보드 기본. 행 ≥48dp, semantics `'$title, $author'`. `_EmptyState` 버튼 라벨 명확("ISBN으로 등록", "직접 입력해서 등록"). `_saving` 오버레이 동안 `Semantics(label: '책 저장 중')` + 배경 비활성. 색만으로 섹션 구분 X(헤더 텍스트).

## 변경 이력
- 2026-05-12 역정리 초안 (코드 기준 + Phase B 가상 팀 — 개선/보강 9건). 캐시+알라딘 동시 호출·dedupe·디바운스는 유지.
