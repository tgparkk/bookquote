# 화면 설계 — 서재 [캘린더] 세그먼트 (PR17, V1.0)

> 그룹 2. `library.md`의 3번째 세그먼트. 입력 근거: DECISIONS 2026-05-17 "독서 시작·완독일 캘린더 + 마찰 감소 UX 3건", `book-detail.md`의 신규 `_ReadingDatesRow`, 경쟁사 조사(왓챠피디아·Letterboxd·StoryGraph).

---

## 1. 목적 / 진입·이탈 / 라우트

- **목적**: 사용자가 입력한 `user_books.started_at`/`finished_at`을 월 단위로 시각화. 셀 탭=그 날 시작·완독한 책 리스트. 왓챠피디아가 *평가일=감상일* 강제로 묶어 실패한 지점 직격 — 우리는 책 상세에서 두 날짜를 *명시적*으로 분리 입력받음.
- **라우트**: `/library?tab=calendar`. 현행 `_LibraryScreenState`의 `_tab` 0/1을 0/1/2로 확장. 인증 가드(서재 자체가 가드). 쿼리 `?date=YYYY-MM-DD`로 특정 날짜 진입 가능(추후 deep link 후보, V1.0엔 안 씀).
- **진입**: 서재 세그먼트 [캘린더] 탭 / (V1.5 후보) Me 화면 "올해 N권" 카운트 → `?tab=calendar`.
- **이탈**: 셀의 책 카드 탭 → `/book/:id` push / 책 상세에서 날짜 수정·삭제 후 pop → `ref.invalidate(userBooksCalendarProvider(...))` 로 즉시 반영.

---

## 2. 와이어프레임

```
┌─────────────────────────────────────────┐
│ 내 서재    [ 책 ] [ 인용구 ] [ 캘린더 ]   │
├─────────────────────────────────────────┤
│   ◀  2026년 5월  ▶                        │  월 네비 + 좌/우 스와이프 (2주/월 토글은 V1.5)
│                                          │
│  일  월  화  수  목  금  토               │
│              1   2   3   4   5            │
│   6   7   8   9   10  11  12              │  ─ 시작일: accent200 outline 점
│       ●         ▲       ●●               │  ─ 완독일: accent500 채움 점
│  13  14  15  16  17  18  19              │  ─ 같은 날 시작+완독: 채움+테두리
│  20  21  22  23  24  25  26              │  ─ 한 날 ≥4권: 점 3 + "···"
│  27  28  29  30  31                       │
│                                          │  오늘: 굵은 outline (accent500) · 선택: accent50 채움
├─────────────────────────────────────────┤
│ 5월 17일                                  │  선택 셀 상세 — 일자 헤더
│ ┌─────────────────────────────────────┐ │  그 날 책 리스트(시작·완독 둘 다)
│ │ 표지 │ 미드나잇 라이브러리            │ │  컴팩트 `_BookRow` 변형
│ │      │ 다 읽음 ✓ · ★★★★             │ │  부 텍스트로 "읽기 시작"/"다 읽음" 명시
│ └─────────────────────────────────────┘ │  + (있으면) 별점
│ ┌─────────────────────────────────────┐ │
│ │ 표지 │ 데미안                          │ │
│ │      │ 읽기 시작                       │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘

[ 빈 상태 — 이 달 시작·완독 0건 ]
"이 달엔 시작·완독한 책이 없어요"
[ 책 탭으로 → ] OutlinedButton

[ 빈 상태 — 전체 0건 ]
"아직 독서 기간을 입력한 책이 없어요"
"책 상세에서 〔오늘〕 칩을 눌러 시작일·완독일을 기록해보세요."
[ 책 탭으로 → ]
```

---

## 3. 상태

| 상태 | 트리거 | 처리 | 표시 | 심각도 |
|---|---|---|---|---|
| 로딩 | 월 전환 시 `userBooksCalendarProvider(year, month)` 재호출 | 셀 점들만 shimmer, 그리드는 즉시. 인접 달 prefetch는 V1.5 | Inline | 낮음 |
| 빈: 그 달 0건 | 그 달 셀 마커 0개 | 그리드 그대로, 상세 영역에 "이 달엔..." + CTA | Empty(영역) | 낮음 |
| 빈: 전체 0건 | 전체 user_books의 시작·완독 모두 null | 캘린더는 빈 그리드. 상단 안내 카드 + [책 탭으로 →] | Empty(전체) | 낮음 |
| 데이터 | provider에서 그 달 마커 + 선택 셀 책 리스트 | 점 색 분기 + 선택 셀 리스트 | — | — |
| 에러: 페치 실패 | NetworkError / RLS | "캘린더를 불러오지 못했어요" + [다시 시도]. raw `$error` 노출 금지 | Inline → 재시도 | 중간 |
| 오프라인 | `connectivity_plus`(V1.5에 도입) | V1.0은 stale 데이터 그대로 + 상단 배너 "오프라인 — 마지막으로 받은 데이터예요" | 배너 | 낮음 |
| 책 상세에서 날짜 수정 후 복귀 | pop | invalidate로 변경 즉시 반영 | (정상) | — |

---

## 4. 인터랙션

- **월 전환**: ◀/▶ 탭 또는 좌/우 스와이프(`table_calendar`의 `availableGestures`). 미래 달은 다음 달까지만 — `lastDay = today + Duration(days: 365)` 정도 cap.
- **셀 탭**: 그 날 책 리스트로 하단 펼침(애니메이션 250ms). 빈 날 셀 탭도 OK — 하단에 "이 날 시작·완독한 책이 없어요" 한 줄(과한 빈 화면 X).
- **오늘 셀**: 굵은 outline + accent500 — 다른 셀 선택 시에도 오늘 셀 표식은 유지.
- **셀의 책 카드 탭**: `/book/:id` push. 책 상세에서 날짜 수정·삭제 후 돌아오면 invalidate로 반영.
- **점 마커 규칙** (왓챠피디아의 단일 점 → 우리는 두 색 분리, 정보 압축):
  - `started_at == 그 날` → accent200 outline 점
  - `finished_at == 그 날` → accent500 채움 점
  - 같은 날 시작+완독 → 채움+테두리
  - 한 날 책 ≥4권 → 점 3개 + "···" (전체는 셀 탭으로)
- **데이터 절대 유실 금지**: 캘린더는 *읽기 전용*. 입력·수정은 책 상세에서만 — 책 상세에서 invalidate된 후 캘린더가 최신 반영.

---

## 5. 토큰 매핑

| 영역 | 토큰 |
|---|---|
| 캘린더 배경 / AppBar | `AppColors.secondary200` / 서재 AppBar 공유 |
| 요일 헤더 (일~토) | `AppFonts.ui` w500 `AppFontSize.xs`(11) `AppColors.primary500`. 일·토도 같은 색(절제) |
| 날짜 숫자 | `AppFonts.ui` w400 `AppFontSize.sm`(13) `AppColors.primary700`. 오늘은 w600 `accent700` |
| 시작일 점 | `accent200` outline, 직경 6 |
| 완독일 점 | `accent500` 채움, 직경 6 |
| 같은 날 시작+완독 | `accent500` 채움 + `accent700` 1px outline |
| 오늘 셀 | `accent500` outline 1.5px, 배경 무변 |
| 선택 셀 | `accent50` 배경 + `accent500` outline 1.5px |
| 다른 달 날짜 | `primary300` opacity 0.5 |
| 선택 셀 상세 헤더 (날짜) | `AppFonts.ui` w600 `AppFontSize.base`(15) `primary800` |
| 책 카드 (컴팩트) | `library_screen._BookRow` 컴팩트 변형. 부 텍스트(읽기 시작/다 읽음)는 `accent700` `AppFontSize.xs` |
| 빈 상태 / 에러 / 배너 | 기존 `library_screen._EmptyView`·`_ErrorView` 패턴 / `semanticWarningLight`+`semanticWarning` |

---

## 6. 재사용 / 신규

**재사용**: `library_screen` 세그먼트 컨테이너 / `BookCover` / `tokens.dart` / `book_repository.listMyLibrary`(가공 후) / 책 상세의 `_ReadingDatesRow`(입력은 책 상세, 캘린더는 읽기 전용).

**신규**:
- `lib/features/library/presentation/calendar_segment.dart` — `ConsumerStatefulWidget`, `table_calendar` 래퍼 + 선택 셀 상세
- `lib/features/library/state/calendar_providers.dart`:
  - `userBooksCalendarProvider(year, month)` `FutureProvider.family<Map<DateTime, List<UserBookOnDay>>>` — 그 달 [1일, 말일+1일) 사이의 `started_at` ∪ `finished_at` 가진 user_books 한꺼번에 fetch(`or` 조건)
  - `selectedDateProvider` `StateProvider<DateTime>` — 캘린더 선택 상태(month 전환 시 자동 1일로)
- `lib/features/library/domain/user_book_on_day.dart` — `Book` + `kind: started|finished|both` + `rating?`
- `book_repository.listCalendarMarkers({year, month})` 메서드
- `pubspec.yaml`: `table_calendar: ^3.x`

---

## 7. 엣지 / 접근성

**교차 관심사 (공통 8원칙)**: ① 오프라인=1급(stale 데이터 + 배너) · ③ PII 로그 금지(raw `$error` X) · ④ 막다른 골목 금지(빈 상태에 [책 탭으로 →]) · ⑥ 에러 일관성(Inline 재시도) · ⑦ 인증 가드(서재 자체).

| 엣지 | 심각도 | 처리 |
|---|---|---|
| `started_at > finished_at` (DB CHECK 통과해버리면) | 매우 낮음 (DB CHECK + 클라이언트 가드 둘 다) | DB CHECK + 클라이언트 `setReadingDate`가 finished < started면 raise. DatePicker `lastDate=finished_at`(시작 입력 시), `firstDate=started_at`(완독 입력 시) clamp |
| 한 날에 책 ≥10권 | 낮음 | 점 3개 + "···", 셀 탭하면 전체 노출 |
| 월 전환을 빠르게 5번 연속 | 낮음 | Riverpod 캐시 — 같은 키 1번만 호출 |
| 표지 깨진 책 | 낮음 | `BookCover` placeholder fallback (기존 동작) |
| 사용자 시간대 변경(여행) | 낮음 | `date` 타입(시각 없음)이라 시간대 무관. "오늘" 판정은 `DateTime.now()` 기준 — 자정 직전·직후 케이스는 V1에 정확 동작, V1.5에 사용자 정의 day-start 검토 |
| 매우 옛날 책(완독일 10년 전) | 낮음 | 월 네비로 무한 과거 이동. 미래 달은 다음 달까지 cap. DatePicker `lastDate = today` |
| E2EE 잠금 인용구 있는 책 | 낮음 | 캘린더는 책 메타만 표시 — 잠금 인용구 본문은 안 보임(메타 평문 유지 결정과 정합, DECISIONS 2026-05-17 E2EE) |

**접근성**: 셀 ≥40dp(`table_calendar` 기본 충족). 점 색만으로 의미 전달 X → 셀 탭으로 항상 펼침 + 책 카드 부 텍스트 "읽기 시작"/"다 읽음" 명시. 오늘 셀 semantics `'오늘, $date, 시작 N권, 완독 M권'`. 선택 셀 semantics 동일 + `' 선택됨'`. 월 네비 버튼 tooltip `'이전 달'`/`'다음 달'`.

---

## 변경 이력
- 2026-05-17 신규 작성 — DECISIONS 2026-05-17 "독서 시작·완독일 캘린더 + 마찰 감소 UX 3건" + 경쟁사 조사(왓챠피디아 빈자리 + Letterboxd·StoryGraph UX 학습) 통합. PR17-C로 구현. [인용구] 세그먼트도 같은 PR에 묶임(`library.md` 변경 이력 참조).
