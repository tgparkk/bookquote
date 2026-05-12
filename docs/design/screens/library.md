# 화면 설계 — 서재 `/library` (이미 구현 — 역정리 + 보강 권고)

> 그룹 3. 입력 근거: `lib/features/library/library_screen.dart`, `lib/features/book/data/book_repository.dart`(코드 기준), `competitor-screen-analysis §3·§5.8`, DECISIONS 2026-05-12(서재 = 책↔인용구 세그먼트). **빈/로딩/에러 뷰 + `RefreshIndicator + invalidate` 패턴은 다른 화면(홈·인용목록·책상세)이 따라야 할 레퍼런스.**

## 1. 목적 / 진입·이탈 / 라우트
- **목적**: 내 서재(담은 책) 목록 + (보강) "책 ↔ 인용구" 세그먼트 — 인용구 뷰는 `quote-list.md`. 각 책에서 인용구 추가·카드 만들기로 이어짐.
- **라우트**: `StatefulShellBranch[1]` `GoRoute(path: '/library')`. 인증 가드. (보강) `?tab=quotes&mood=...&bookId=...` 쿼리로 인용구 뷰 + 필터.
- **진입**: BottomNav [서재] 탭 / Me의 "서재 N권" / 홈 무드 칩(→ `?tab=quotes&mood=`) / 책 상세 "전체 보기 ▸"(→ `?tab=quotes&bookId=`). **이탈**: `_BookRow` 탭 → `/book/:id` / FAB "책 추가" → `showBookSearchSheet` → 선택 시 `addToLibrary` → `/book/:id` 권유 / (보강) 인용구 뷰 → `quote-list.md` 동선.

## 2. 와이어프레임
```
┌─────────────────────────────────────────┐
│ 내 서재          [ 책 ]  [ 인용구 ]      │  ← (보강) 세그먼트. 현행은 "내 서재"만
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │  _BookRow (ListView.separated)
│ │▎┌──┐ 미드나잇 라이브러리      [7구절]│ │  (보강) 좌측 4px 표지색 띠 + trailing "N구절" 배지
│ │▎│표│ 매트 헤이그                      │ │  현행: 표지 + 제목 2줄말줄임 + 저자 + publisher·pubDate
│ │▎└──┘ 인플루엔셜 · 2021               │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │▎┌──┐ 니코마코스 윤리학         [3구절]│ │
│ │▎│표│ 아리스토텔레스 · 길              │ │
│ │▎└──┘                                 │ │
│ └─────────────────────────────────────┘ │
│              … (RefreshIndicator)         │  현행 limit 50 — 페이지네이션 없음
│                              ╭───────╮  │  FAB.extended "책 추가" → showBookSearchSheet
│                              │ ＋ 책  │  │
│                              ╰───────╯  │
└─────────────────────────────────────────┘

[ 빈 상태 — 책 0권 ]  현행 _EmptyView: 아이콘 + "아직 책이 없어요" + 안내 (ListView라 pull-to-refresh 동작)
                       (보강) 본문에도 [＋ 책 추가] 버튼 — 홈 빈 상태와 일관
```

## 3. 상태 (코드 기준)
| 상태 | 처리 | 심각도 |
|---|---|---|
| 로딩 | `myLibraryProvider`(`FutureProvider.autoDispose<List<Book>>` → `book_repository.listMyLibrary()`, limit 50, `added_at desc`, `user_books.select('book:books(*)')` 조인). `asyncLibrary.when(loading: CircularProgressIndicator(accent500))`. (보강: 스켈레톤 권고) | 낮음 |
| 빈 | `data == []` → `_EmptyView`("아직 책이 없어요" + 안내). `ListView`라 빈 상태에서도 pull-to-refresh 동작. (보강: 본문에 [＋ 책 추가] 버튼) | 낮음 |
| 에러 | `_ErrorView`("서재를 불러오지 못했어요... ($error)" — **raw error 노출, 재시도 버튼 없음**) | 중간 (개선) |
| 데이터 | `_BookList`(`ListView.separated`, `_BookRow`: `BookCover` + 제목 2줄말줄임 + 저자 + publisher·pubDate). `_BookRow` 탭 → `context.push('/book/${book.id}')` | — |
| 책 추가 (FAB) | `_onAddBook`: `showBookSearchSheet(context)` → `Book?` → null/unmounted면 return → `bookRepository.addToLibrary(book.id)` → `ref.invalidate(myLibraryProvider)` → SnackBar("\"$title\" 서재에 추가됐어요" + "열기" → `/book/${book.id}`). `on BookRepositoryException` → SnackBar("서재 추가 실패: ${e.message}" — **raw message 노출**) | 중간 (개선) |
| (보강) 오프라인 | `connectivity_plus` 미연동 — 오프라인이면 `myLibraryProvider`가 그냥 에러로 떨어짐. stale-while-revalidate 미적용 | 중간 (개선) |
| 권한 거부 | 해당 없음 | — |

## 4. 인터랙션
- pull-to-refresh → `ref.invalidate(myLibraryProvider)`. FAB → 시트 → 선택 → 담기 → SnackBar(action 열기). `_BookRow` 탭 → 책 상세.
- (보강) 세그먼트 "책 ↔ 인용구" 전환 — 각 뷰 스크롤 위치 보존(`StatefulShellRoute` state). 인용구 뷰는 `quote_list_view.dart`(`quote-list.md`).
- (보강) `removeFromLibrary` UI — 현행 repo에 메서드 있으나 화면 UI 없음. 책 상세 ⋮ "서재에서 빼기"(`book-detail.md`)로 충분할 수도 — 서재 화면 스와이프 삭제는 우발 삭제 우려로 보류.

## 5. 토큰 매핑
- 배경 `AppColors.secondary200` · AppBar `AppTheme.appBarTheme`("내 서재" `AppFonts.ui` w600 17 `primary900`) · (보강) 세그먼트: 선택 `primary900`/`secondary50`, 미선택 `primary400`/border `primary200` · `_BookRow`: `BookCover` + 제목 `AppFonts.ui` w600 `AppFontSize.base`(15) `primary800`(2줄 말줄임) + 저자 `AppFontSize.sm`(13) `primary500` + publisher·pubDate `AppFontSize.xxs`(9) `primary400` · (보강) 좌측 4px 표지색 띠(`palette_service`의 dominant — 표지 없으면 `secondary400`) · (보강) "N구절" 배지 `semanticSuccessLight`/`semanticSuccess` `AppFontSize.xxs` `AppRadius.full` · FAB `accent500`/`secondary50`/`AppShadows.floating` · `_EmptyView` 아이콘 `primary300`/텍스트 `primary400` · `_ErrorView`(개선: userMessage만)/SnackBar `AppTheme.snackBarTheme`.

## 6. 재사용 / 신규
- 재사용: `myLibraryProvider`(`book_providers.dart`), `BookCover`, `showBookSearchSheet`, `book_repository.addToLibrary`/`listMyLibrary`/`removeFromLibrary`, `tokens.dart`. 신규(보강): 세그먼트 + `quote_list_view.dart`(인용구 뷰), `_BookRow`에 표지색 띠 + 구절 수 배지(`quote_repository`의 book별 count + `palette_service`), `_ErrorView`에 [다시 시도] + userMessage 매핑, `_EmptyView`에 [＋ 책 추가] 버튼, `connectivity_plus` 연동(stale-while-revalidate).

## 7. 엣지 / 접근성 + 수정·보강 항목
**교차 관심사**: ① 오프라인=1급(stale-while-revalidate — 보강) · ⑥ 에러 일관성(raw 노출 금지) · ⑦ 인증 가드 · ⑤ 책 검색 시트 왕복 시 (서재 화면 자체 state 없으니 무관).
**양호(유지·레퍼런스)**: `RefreshIndicator + asyncX.when(data/loading/error)` 패턴 — 홈·인용목록·책상세가 이걸 따름. `_BookRow` null-guard. FAB → 시트 → 담기 → SnackBar(action) 흐름.
**수정·보강 권고 (현행 ≠ 권고)**:
- ① **에러 뷰 raw `$error` 노출** — `_ErrorView`가 `'($error)'`를 화면에 — PII/내부 구조 노출, 사용자에게 무의미(error-handling §9 안티패턴). userMessage만 + [다시 시도] 버튼(→ `ref.invalidate(myLibraryProvider)`). `$error`는 Sentry로.
- ② **추가 실패 시 `e.message` raw 노출** — `"서재 추가 실패: ${e.message}"` → `AppError.userMessage` 매핑.
- ③ **구절 수 배지·표지색 띠 미구현** — `competitor-screen-analysis §3`이 V1에 심어두라 권고. 저비용(`quotes` count + `palette_service` dominant 재사용). V1.5 "인용 서가" 시각화의 발판.
- ④ **책 ↔ 인용구 세그먼트 미구현** — DECISIONS 2026-05-12: 인용구 목록은 별도 탭 X, 서재 안 세그먼트. `?tab=quotes` 쿼리 + `quote_list_view.dart`.
- ⑤ **`listMyLibrary(limit: 50)` 하드캡** — 51번째부터 안 보임(페이지네이션 없음). 책은 인용보다 적게 쌓이니 V1 수용 가능하나 명시 — V1.5에 cursor 페이지네이션.
- ⑥ **시트가 책 고르면 "서재에 추가했어요" SnackBar를 *두 번*** — 시트 내부(`book_search_sheet._onPick`이 `upsertBook` 후 토스트, 실제론 `public.books` 카탈로그 upsert일 뿐 `user_books` 등록 아님) + `_onAddBook`이 `addToLibrary` 후 또 토스트. 시트 토스트는 `suppressAddedToast` 옵션으로 억제 또는 문구를 "이 책을 선택했어요"로(`book-search-sheet.md` 참조).
- ⑦ **오프라인 미연동** — `connectivity_plus` 추가 + stale-while-revalidate(마지막 캐시 표시 + 배너).
- ⑧ **책 제거 UI 없음** — repo엔 `removeFromLibrary` 있으나 UI 없음. 책 상세 ⋮ "서재에서 빼기"로 커버(`book-detail.md`).
**접근성**: `_BookRow` ≥48dp(기본 충족), semantics `'$title, $author, 이 책에서 모은 N구절'`. FAB `'책 추가'`. `_EmptyView` CTA `'책 추가, 첫 책을 담으세요'`. 표지색 띠는 장식(semantics 불필요). 색만으로 의미 전달 X(구절 수는 텍스트 배지).

## 변경 이력
- 2026-05-12 역정리 초안 (코드 기준 + Phase B 가상 팀 — 개선/보강 8건). `RefreshIndicator + when` 패턴은 레퍼런스로 유지.
