# 화면 설계 — 홈 `/` (내 인용 피드)

> 그룹 2 · Stage 2. 입력 근거: `competitor-screen-analysis-2026-05-11.md §5.5`, 가상 팀(기획·UI/UX·Dart·QA) Phase B 협의. 결정: DECISIONS 2026-05-12 — 홈 = 순수 "내 인용 피드"(받은 카드 함은 V1.5), follow 타임라인은 V1.5.

---

## 1. 목적 / 진입·이탈 / 라우트

- **목적**: 내가 모은 인용구를 시간순 흐름으로 다시 만난다 — "사진은 찍는데 다시 안 봄" 페인의 1차 답(테마·책 단위 *탐색*은 서재>인용구 뷰가 맡음 — 홈은 흐름). 빈 화면이면 첫 인용구를 남기게 유도.
- **라우트**: `StatefulShellBranch[0]` `GoRoute(path: '/')`. 인증 가드(미로그인 → `/auth/login`). 현행 `HomeScreen`(StatelessWidget 스텁, "친구의 새 인용구") → `ConsumerStatefulWidget` 전면 재작성.
- **진입**: 콜드스타트 → `/splash` → `/`(로그인됨) / BottomNav [홈] 탭 / 인용구 저장 후 `pop()`이 홈으로 떨어질 때.
- **이탈**: 피드 항목 탭 → 인라인 확장(`quote-list.md`와 같은 카드 컴포넌트) / [카드 만들기] → `/quote/:id/card` / 무드 칩 탭 → `context.go('/library?tab=quotes&mood=...')`(서재 인용구 뷰로, 그 무드 필터) / AppBar 🔍 → 검색(서재 인용구 뷰의 검색과 동일 위젯) / BottomNav [＋] → `/quote/new`.

> **받은 카드 함은 V1엔 없음** (DECISIONS 2026-05-12). V1 deep link 수신 = "책 상세 + 서재 담기"(`deep-link-receive.md`)이고 받은 카드의 영속 저장소가 V1에 없다. V1.5에 `received_cards` 테이블 + 홈 상단 가로 함으로 추가, follow 타임라인도 V1.5에 같은 피드에 합류.

---

## 2. 레이아웃 와이어프레임

```
┌─────────────────────────────────────────┐
│ 책귀                                  🔍 │  AppBar — 좌: 워드마크. 우: 검색 아이콘
├─────────────────────────────────────────┤
│ ┌─────────────────────────────────────┐ │
│ │ ┌──┐ "가장 깊은 밤에 가장 빛나는      │ │  피드 항목 = 인용구 미니 카드
│ │ │표│  별이 보인다."                    │ │  표지 34×50 + 인용구 2~3줄(NotoSerifKR)
│ │ │지│  미드나잇 라이브러리 · p.132      │ │  + 책·저자·페이지 + 무드칩
│ │ └──┘  〔위로〕〔먹먹〕      [카드 만들기]│ │  우하단 보조 액션 [카드 만들기]
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ ┌──┐ "우리는 우리가 반복하는 것이다." │ │  탭 → 인라인 확장(전체 텍스트 + 메모
│ │ │표│  니코마코스 윤리학 · p.55  〔통찰〕│ │  + [수정]/[무드 변경]/[공유]/[삭제])
│ │ └──┘                     [카드 만들기]│ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │  ⏳ 동기화 대기 · "오래된 것은…"        │ │  아웃박스 대기 항목 = "동기화 대기" 뱃지
│ │     잃어버린 시간을 찾아서             │ │  연결 복구 시 실제 DB 행으로 swap(fade-in)
│ └─────────────────────────────────────┘ │
│              … (무한 스크롤, 페이지 15)   │  ListView.builder 가상화, cursor-after
└─────────────────────────────────────────┘
  (BottomNav: 홈 · 서재 · ＋ · 나)            FAB 없음 — [＋] sentinel과 중복, 마지막 항목 가림

[ 빈 상태 — 인용구 0개 ]
┌─────────────────────────────────────────┐
│ 책귀                                  🔍 │
├─────────────────────────────────────────┤
│              (📖 아이콘)                 │  Icon(Icons.format_quote, 48, primary300)
│        아직 인용구가 없어요               │  headlineSmall, primary900
│   좋아하는 책의 한 줄을 저장해보세요.      │  bodyMedium, primary500  (flows.md Flow A 3.1)
│        ┌───────────────────────┐        │
│        │     ＋ 인용구 추가      │        │  큰 버튼 1개 — accent500, AppShadows.floating
│        └───────────────────────┘        │  → /quote/new   (튜토리얼 없음 — flows.md 3.3)
└─────────────────────────────────────────┘
```

---

## 3. 상태

| 상태 | 트리거 | 처리 | 표시 | 심각도 |
|---|---|---|---|---|
| 로딩: 첫 페이지 | 탭 진입 / cold-start 후 첫 `/` | 스켈레톤 카드 3~4개(스피너 아님). `RefreshIndicator`. 목표 `<800ms`(`flows.md §9`) | Inline 스켈레톤 | 낮음 |
| 로딩: 페이지네이션 | 하단 도달 | 하단 spinner. `cursor-after`(created_at + id), 페이지 15(DECISIONS 2026-05-10, offset 금지). in-flight 가드(`_isLoadingMore`) | Inline (하단) | 낮음 |
| 빈: 인용 0개 | 신규 가입 직후 | empty 페이지 — 아이콘 + "아직 인용구가 없어요. 좋아하는 책의 한 줄을 저장해보세요." + [＋ 인용구 추가] 큰 버튼 1개(`flows.md` Flow A 3.1, 튜토리얼 없음) | Empty | 중간 |
| 에러: 피드 로드 실패 — 네트워크 | NetworkError | "인용구를 불러오지 못했어요" + [다시 시도]. 캐시 있으면 캐시 먼저(아래 오프라인) | Empty 에러 → 재시도 | 중간 |
| 에러: 피드 로드 실패 — RLS(`PGRST301`) | AuthError | `onAuthStateChange(SIGNED_OUT)` 한 곳에서 잡혀 `/auth/login`으로(화면마다 중복 처리 X). 잠깐 보이다 리다이렉트, 가능하면 Modal "다시 로그인이 필요해요" 1회 | Modal → 리다이렉트 | 중간 |
| 에러: 5xx/알 수 없음 | retryable | "문제가 발생했어요. 잠시 후 다시 시도해주세요" + [다시 시도] | Empty 에러 → 재시도 | 중간 |
| 오프라인 | `connectivity_plus` | stale-while-revalidate — 마지막 캐시 피드 즉시 표시 + 상단 `semanticWarningLight` 배너 "오프라인 — 연결되면 자동 새로고침". 아웃박스 대기 인용구는 피드 상단에 "동기화 대기" 뱃지 | 배너 + 뱃지 | 중간 |
| 동기화 대기 → 완료 교체 | 연결 복구 → `quote_outbox.flush()` 성공 | "동기화 대기" 임시 항목 → 실제 DB 행 swap(자리 유지, fade-in, 깜빡임 최소). 책 자동 매칭 실패 건은 "책 정보 필요" 액션 뱃지 유지(`flows.md §8.3`) | (자동 교체) | 중간 |
| 매우 긴 피드(수백 항목) | 활성 사용자 | `ListView.builder` 가상화. 카드 안 표지 작게 | (성능) | 낮음 |
| 피드 항목 삭제 | 카드의 [삭제] | 낙관적 제거 + undo SnackBar 5s. 미클릭 시 실제 삭제. 실패 시 롤백 + "삭제하지 못했어요" Toast | Toast (undo) | 중간 |
| 피드에서 [카드 만들기] | 항목 "카드 만들기" 탭 | `context.push('/quote/$id/card')`. 표지 없는 책이면 `card-editor.md §3` "표지 없는 책" 상태로 위임(T4 비활성 — DECISIONS 2026-05-12) | (위임) | 낮음 |
| BOOK_UNRESOLVED 항목 | 책 미연결 인용구 | 표지 자리 placeholder("책 미연결") + "책 연결하기" 인라인 액션 | Inline (항목) | 중간 |
| 권한 거부 | 해당 없음 | 홈은 권한 요청 0 | — | — |

---

## 4. 인터랙션

- **피드 항목 탭**: 인라인 확장(전체 인용구 텍스트 + 메모 + 액션 행 [카드 만들기]/[수정]/[무드 변경]/[공유]/[삭제]) — `quote-list.md`와 동일 위젯(`quote_list_card.dart`) 재사용. 화면 전환 줄임(Readwise식).
- **[카드 만들기]**: 항목 우하단 보조 액션 — `context.push('/quote/$id/card')`. 라벨 노출(아이콘만 X — "더블탭 숨김 금지" 원칙 연장).
- **무드 칩 탭**: `context.go('/library?tab=quotes&mood=$mood')` — 서재 탭으로 전환하며 그 무드 필터. 홈 안에서 필터링 안 함(홈=흐름, 필터=서재).
- **RefreshIndicator**: pull-to-refresh → `ref.invalidate(myQuotesProvider)` + 아웃박스 flush 시도. `library_screen` 패턴 재사용.
- **AppBar 검색 🔍**: 탭 → 검색(인용구 텍스트 + 책 제목 `ilike`, 디바운스 300ms). **서재 인용구 뷰의 검색과 동일 위젯 재사용**.
- **FAB 없음**: BottomNav [＋] sentinel(`root_scaffold.dart`의 `_createSentinelIndex=2`)이 모든 셸 탭에서 `/quote/new` 접근을 제공 → FAB는 중복 + 마지막 피드 항목의 [카드 만들기]를 가림 + 빈 상태엔 큰 버튼이 이미 있음. (서재 FAB는 "책 추가"라는 다른 액션이라 별개.) 사용자 테스트에서 [＋] 발견성이 낮으면 V1.5에 FAB 검토.
- 애니메이션: 항목 인라인 확장 expand(200ms), 동기화 대기→완료 fade(150ms). 과한 모션 금지(디자인 시스템 "차분한").

---

## 5. 디자인 토큰 매핑 (`lib/core/theme/tokens.dart` — `AppShadows` 복수형 주의)

| 영역 | 토큰 |
|---|---|
| 화면 배경 | `AppColors.secondary200` (#FAFAF8) |
| AppBar | `AppTheme.appBarTheme`(투명·elev 0). 워드마크 `AppFonts.ui` w700 18 `AppColors.primary900` / 🔍 `AppColors.primary500` |
| 피드 항목 카드 | 배경 `AppColors.secondary100` + border 1 `AppColors.primary100` + `AppRadius.md`(8) + `AppShadows.card` · 인용구 `AppFonts.quote`(NotoSerifKR w400) `AppFontSize.sm`(13) `AppColors.primary800`, 2~3줄 말줄임, height `AppLineHeight.relaxed`(1.6) · 책·저자·페이지 `AppFonts.ui` `AppFontSize.xxs`(9) `AppColors.primary400` · 패딩 `AppSpacing.s4`(16) · 항목 간 `AppSpacing.s3`(12) |
| 무드 칩 | `moodColors[mood]` 맵(신규 — `quote-input.md`·`quote-list.md`·`card-editor.md` 공유) — 미선택: `light` 배경 / `dark` 텍스트 / border 1 `secondary500` / `AppRadius.full` / `AppFontSize.xxs`(9) |
| [카드 만들기] 보조 액션 | 텍스트 버튼 `AppFonts.ui` `AppFontSize.xs`(11) `AppColors.accent600` + 아이콘 `Icons.auto_awesome` 14 |
| 동기화 대기 뱃지 | `AppColors.semanticWarningLight` 배경 / `AppColors.semanticWarning` 텍스트 `AppFontSize.xxs` / `AppRadius.xs` |
| 빈 상태 | 아이콘 `Icons.format_quote` 48 `AppColors.primary300` / 타이틀 `headlineSmall` `AppColors.primary900` / 본문 `bodyMedium` `AppColors.primary500` / CTA 버튼 `AppColors.accent500` 배경·`secondary50` 텍스트 ui w600 14·`AppRadius.md`·`AppShadows.floating`·가로 패딩 `AppSpacing.s8` |
| 오프라인 배너 | `AppColors.semanticWarningLight` 배경 / `AppColors.semanticWarning` 텍스트 `AppFontSize.xs` / full-width 상단 |
| 에러 뷰 | `library_screen._ErrorView` 패턴 — userMessage만(raw `$e` 금지), `AppColors.primary400` + [다시 시도] `accent500` |
| Toast | `AppTheme.snackBarTheme` — `primary900` 배경, action `accent400` |

신규 토큰: `moodColors` — `Map<QuoteMood, ({Color light, Color dark})>`, 단일 정의처(`tokens.dart`). 예: 위로=`semanticSuccessLight`/`semanticSuccess`, 먹먹=`neutral100`/`neutral600`, 새벽3시=`semanticInfoLight`/`semanticInfo`, 통찰=`accent100`/`accent700`, 설렘=`accent50`/`accent600`.

---

## 6. 재사용 / 신규

**재사용**: `library_screen.dart`의 `RefreshIndicator(onRefresh: invalidate)` / `_EmptyView` / `_ErrorView` 패턴, `BookCover`(width 파라미터화), `quote-list.md`의 `quote_list_card.dart`(피드 항목 = 같은 카드), `myQuotesProvider`(`quote-input.md`/`quote-list.md` 신규 — cursor 시그니처는 DECISIONS 2026-05-12에 확정), `root_scaffold.dart`의 [＋] sentinel(FAB 안 더함), `tokens.dart`.

**신규**: `lib/features/home/home_screen.dart`(스텁 → `ConsumerStatefulWidget` 재작성, 스크롤 컨트롤러로 무한스크롤 트리거 + `_isLoadingMore` 가드), `myQuotesProvider`의 홈 피드용 누적 상태(`Notifier<AsyncValue<List<Quote>>>` 패턴 — `quote_providers.dart`). **Realtime 구독 코드 금지**(Realtime은 V2). `home_screen.dart`에 follow `timelineProvider` 의존 0(코드에 애초에 없음 — `client-architecture.md §7.A`/`flows.md` Flow E의 해당 절을 "V1.5"로 마킹).

---

## 7. 엣지 / 접근성

**교차 관심사 (공통 8원칙)**: ① 오프라인=1급(stale-while-revalidate + 배너 + 동기화 대기 뱃지) ② 데이터 유실 금지(인용구는 DB, 아웃박스 항목 가시화) ③ PII 로그 금지(인용구 텍스트·검색어 미전송) ④ 막다른 골목 금지(빈/에러 상태마다 출구 CTA) ⑤ 해당 없음(홈엔 시트 없음) ⑥ 에러 표시 일관성(섹션별 인라인 / 세션만료는 한 곳에서 Modal) ⑦ 인증 가드(`redirect`가 처리) ⑧ 해당 없음(홈엔 카드 미리보기 없음 — 미니 썸네일은 export 아님).

| 엣지 | 심각도 | 처리 |
|---|---|---|
| 인용 0개 + (V1.5)받은 카드 0개 | 중간 | 빈 상태 우선(아이콘+카피+버튼 1개) |
| 무드 값이 앱 업데이트로 바뀜 | 낮음 | "기타"로 표시, 필터 시 무시 — 데이터 보존 |
| 피드 항목이 BOOK_UNRESOLVED | 중간 | 표지 placeholder + "책 연결하기" 인라인 |
| 빠른 스크롤로 페이지네이션 연타 | 낮음 | `_isLoadingMore` 가드 — in-flight면 무시 |
| 동기화 대기 항목이 flush 실패 반복 | 중간 | 뱃지 유지 + (책 매칭 실패면) "책 정보 필요" 액션. 무한 재시도 X — 포그라운드/연결복구 트리거만 |

**접근성**: 피드 카드 ≥48dp 탭 영역, semantics `'$book의 인용구: $text, ${page}페이지, 무드: $moods'`. 무드 칩 = 색 + 텍스트(색만 X). 빈 상태 CTA `'인용구 추가, 첫 인용구를 남기세요'`. 검색 아이콘 `'인용구 검색'`. 동기화 대기 항목 `'$text, 동기화 대기 중'`. 대비: 인용구 `primary800` on `secondary100` AA 통과.

---

## 변경 이력
- 2026-05-12 초안 (매니저 종합 — competitor-screen-analysis §5.5 + Phase B 가상 팀 협의). 결정: 받은 카드 함 V1 제외(V1.5), follow 타임라인 V1.5, FAB 없음, cursor-after 페이지네이션.
