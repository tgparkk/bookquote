# 화면 설계 — 카드 에디터 `/quote/:id/card`

> 그룹 1 · Stage 3 (가장 공들일 화면 — V1 차별화 ①의 무대). 입력 근거: `competitor-screen-analysis-2026-05-11.md §5.2`, QA-2 / Dart-2 가상 팀 산출, `docs/design/templates/01~05`, `docs/design/color-extraction.md`, `docs/design/mockups/all-templates.html`.

---

## 1. 목적 / 진입·이탈 / 라우트

- **목적**: 인용구 하나를 인스타그래머블 카드로 만든다. 5종 템플릿 × 표지에서 자동 추출한 색 팔레트 × 비율(1:1/4:5/9:16) × 미세 조정(텍스트 위치·워터마크). 진입하면 **이미 그럴듯한 카드가 그려져 있고**(추천 템플릿 + 표지 팔레트 적용), 사용자는 1~2탭만 만지고 공유. 북모리의 "고정 배경 라이브러리"·"앱 만든 티"를 정면으로 넘어서는 화면.
- **라우트**: `GoRoute(path: '/quote/:id/card', parentNavigatorKey: _rootNavigatorKey, builder: (c,s) => CardEditorScreen(quoteId: s.pathParameters['id']!))` — 이미 `router.dart`에 배선됨. BottomNav 셸 밖 풀스크린(또는 iOS pageSheet 스타일 모달 — 스와이프 다운 닫힘). 인증 가드.
- **진입**: 인용구 입력 화면의 "카드 만들기 →" / 인용 목록·상세의 "카드 만들기" / 홈 피드 항목의 "카드 만들기" / 받은 카드 함의 카드 → "이 카드 다시 만들기".
- **이탈**:
  - "공유" → 공유·저장 시트(모달, `card-share.md`) — 시트에서 카카오톡/인스타/저장
  - ✕ / 뒤로 / 스와이프 다운 → **카드는 인용구와 분리된 부가물**(인용구 본문은 이미 DB에 있음 → 절대 안 잃음) → 디자인 미저장 이탈은 **확인 다이얼로그 불필요**, 그냥 나감. 단 편집 상태는 로컬 영속화되어 재진입 시 복원(아래 §4)
  - PNG 생성 중(로딩)에 뒤로 → capture future 취소, 메모리 정리, 닫기

---

## 2. 레이아웃 와이어프레임 (3단 고정)

```
┌─────────────────────────────────────────┐
│ ←       ▢ 1:1  ▢ 4:5  ▣ 9:16      ⤺  공유│  ① 상단 바
│                                         │     좌: 뒤로  중: 비율 세그먼트(기본 9:16)
├─────────────────────────────────────────┤     우: 언두(스택 비면 비활성) · 공유(항상 1탭)
│         ┌───────────────────┐           │
│         │                   │           │  ② 가운데 — 라이브 프리뷰 (화면 ~55-60%)
│         │  "가장 깊은 밤에   │           │     선택한 비율로 렌더. 인용구 텍스트 박스를
│         │   가장 빛나는      │           │     "한 번 탭" → 인라인 핸들(이동/크기) — 더블탭 숨김 금지
│         │   별이 보인다."    │           │     아래 패널 조작이 즉시 반영(딜레이 체감 0)
│         │                   │           │     워터마크 = 캡처 트리 안 Positioned(켜져 있으면 보임)
│         │  미드나잇 라이브러리 │           │
│         │  ─ 책귀에서 만들었어요 ─│       │
│         └───────────────────┘           │
│  ● ● ● ● ●   ↑ 이 책 표지에서 추출       │  표지 추출 5스와치 줄 = "색 변경 UI"의 전부
│                                         │     탭 → 현재 템플릿의 해당 슬롯(배경/구분선/제목색)에 적용
│ ┌──┐┌──┐┌──┐┌══┐┌──┐                    │  ③ 하단 — 5종 템플릿 가로 한 줄
│ │미││웜││모││표││타│  ← 각 칸 = 지금 그   │     각 썸네일 = 와이어프레임 아님, "지금 그 사용자의
│ │니││  ││노││지││이│    사용자 인용구·    │     인용구·표지로 실제 렌더된 미니 카드".
│ │멀││  ││  ││발││포│    표지로 렌더된 미니 │     선택된 칸에 copper 언더라인
│ └──┘└──┘└──┘└══┘└──┘                    │
│  텍스트 │ 색 │ 위치 상·중·하 │ 워터마크 ● │ 다른 느낌 ↻ │  보조 행 — 이게 옵션의 끝(더 안 둠)
└─────────────────────────────────────────┘
```

- 비율을 1:1/4:5로 바꾸면 프리뷰 비율이 바뀌고 텍스트가 새 영역에 재매핑(상대좌표 + clamp).
- "다른 느낌 ↻": 다음 템플릿 + 팔레트 슬롯 재배정을 1탭으로(5종 안에서만 순환 — 무작위 아님, 품질 보장). Typorama의 "랜덤 생성"을 큐레이션 버전으로.
- "텍스트" = 인용구·책표시 폰트 크기 미세조정(±) + 정렬. "색" = 위 5스와치 패널 토글(또는 항상 노출). "위치" = 상/중/하 앵커(아래 §7 미결). "워터마크" = ON/OFF 토글.

---

## 3. 상태

| 상태 | 트리거 | 처리 | 표시 | 심각도 |
|---|---|---|---|---|
| **로딩: quote/book 로드** | 진입 | 입력 화면에서 막 만든 quote면 캐시 hit(빠름); deep link·목록 진입은 fetch. 카드 영역 스켈레톤(템플릿 프레임만 + 텍스트 자리 shimmer), 컨트롤 바 disabled | Inline | 낮음 |
| **로딩: 표지 이미지 다운로드** | `CachedNetworkImageProvider` fetch | 표지 자리에 베이지 placeholder + 미세 progress. **텍스트는 fallback 팔레트로 먼저 렌더** → 표지 도착 시 swap(cross-fade) | Inline (영역) | 중간 |
| **로딩: 팔레트 추출 대기** | 표지 로드 완료 → `PaletteGenerator.fromImageProvider`(100×100 다운스케일, 타임아웃 3s) | T2/T4 선택 상태면 `fallbackPalettes[templateId]`로 즉시 렌더 → 추출 완료 시 색만 cross-fade 교체. 추출 중 "색" 스와치 영역에 로딩 점 | Inline (영역) | 중간 |
| **로딩: PNG 생성** | "공유"/저장 탭 → `RepaintBoundary.toImage` → ByteData → 파일 | "카드 만드는 중…" 모달-lite 또는 버튼 spinner. 이 동안 다른 입력 차단(중복 capture 방지) | Modal-lite | 중간 |
| **로딩: 공유 시트 등장** | `share_plus.shareXFiles` 호출 → OS 시트 뜨기까지 | 버튼 spinner 유지. OS 시트 뜨면 자동 해제. 500ms+ 그냥 둠(OS 책임) | — | 낮음 |
| **빈: 카드 만들 인용 없음** | 잘못된/삭제된 quoteId 직접 진입 (`PGRST116` no rows / `BIZ_QUOTE_NOT_OWNED`) | "이 인용구를 찾을 수 없어요" empty + [내 인용 보기] CTA | Empty | 중간 |
| **빈: 표지 이미지 없는 책** (`cover_url == null`) | ISBN 직접 등록 도서 등 | T1/T3/T5 정상(고정 배경). T2/T4는 `fallbackPalettes['coverExtract']`(#3D2817 계열)로 렌더 + 작은 안내 "이 책은 표지가 없어 기본 색으로 만들었어요". **T4(표지발췌)의 blur 표지 배경 → 단색 그라데이션으로** (또는 T4 비활성 — §7 미결) | Inline 안내 | 중간 |
| **에러: 표지 URL 깨짐(404/CDN down) → 추출 불가** | Storage/External 경계 | `getPaletteWithFallback` → fallback 팔레트. **사용자에게 에러 표시 안 함**(카드는 멀쩡히 나옴). Sentry breadcrumb만 | (무표시) | 낮음 |
| **에러: PNG 생성 실패 (OOM / 큰 표지 / Skia)** | StorageError | Toast "카드 만들기에 실패했어요. 다시 시도해주세요" + **디자인 옵션 전부 유지**. 재시도 시 pixelRatio 1차 폴백(1080→720), 2차도 실패 시 "기기 메모리가 부족할 수 있어요. 다른 앱을 닫고 다시" | Toast (작업 보존) | **높음** (공유 차단 = 핵심 가치 차단) |
| **에러: 폰트 로드 실패** (NotoSerifKR asset 누락) | StorageError | 폰트는 앱 번들 asset 동봉이 1차 방어(런타임 다운로드 X — 이미 pubspec에 번들됨). 그래도 실패 시 시스템 세리프 + Sentry. **PNG 생성 직전 폰트 로드 완료 보장**(`PaintingBinding.instance.fontLoader`/`endOfFrame` await) | (방어 위주) | **높음** (첫 캡처 □□□ 방지) |
| **에러: quote/book fetch 실패 (네트워크)** | NetworkError | "카드 정보를 불러오지 못했어요" + [다시 시도] (retryable) | Inline → 재시도 | 중간 |
| **에러: quote가 다른 기기에서 삭제됨, 그 후 cards 저장 시도** | BusinessError (`23503` FK) | "이 인용구가 삭제되어 카드를 저장할 수 없어요. 이미지는 저장돼요" — PNG는 로컬에 있으니 공유/저장은 됨, `cards` 테이블 기록만 skip | Toast | 중간 |
| **에러: `cards` 테이블 INSERT(히스토리) 실패** | StorageError, **비차단** | 조용히 무시(공유는 이미 완료, 히스토리는 nice-to-have). 재시도 안 함 | (무표시) | 낮음 |
| **오프라인** | `connectivity_plus` | 표지가 `cached_network_image` 캐시에 있으면 정상 렌더. 캐시 없으면 표지 없는 책처럼 fallback 팔레트. PNG 생성·저장은 로컬이라 오프라인에서도 됨. 공유 시트도 로컬(전송은 카톡/인스타 앱 책임) | 배너(상단) | 중간 |
| **권한 거부: 사진 라이브러리 쓰기** | "이미지 저장" 시도 (`card-share.md` 참조) | **[저장] 버튼만 비활성, 카카오톡/인스타 공유 버튼은 끝까지 활성** + [설정 열기]. iOS add-only(`NSPhotoLibraryAddUsageDescription`) / Android 11+ scoped storage(권한 불필요) / Android 9↓ `WRITE_EXTERNAL_STORAGE` 분기. 전체 시트를 막지 않는다 | Toast + 부분 비활성 | **높음** |

---

## 4. 인터랙션 명세

- **진입 직후**: ① `fallbackPalettes[추천템플릿]`로 즉시 렌더(빈 화면 0초) ② 표지 fetch → 도착 시 cross-fade ③ 팔레트 추출 → 완료 시 색만 cross-fade. **추천 템플릿** = 인용구 길이·표지 유무로 결정(짧으면 T5 타이포/T3 모노, 표지 있으면 T4 우선 등 — 간단한 규칙, `card-editor` 내부 함수).
- **비율 세그먼트**: 탭 → 프리뷰 비율 전환 + 텍스트 위치 재매핑(상대좌표 0~1 → 새 비율에 재투영 + 여백 안으로 clamp) + "비율에 맞게 위치를 조정했어요" Toast(필요 시). 1:1에서 긴 인용구는 auto-fit 한계(§7) 경고. **언두 한 단위**(비율+위치 묶어서).
- **템플릿 한 줄**: 가로 스크롤. 칸 탭 → 즉시 그 템플릿으로 캔버스 갱신(딜레이 체감 0 — Tezza 패턴). 템플릿 전환 시 색 override가 리셋될 수 있으면 그 리셋까지 **언두 한 단위**로 묶음. 선택 칸에 copper 언더라인. 각 썸네일은 실제 인용구·표지로 렌더된 미니 카드(Mojo의 "고를 때 결과를 본다"를 정적 버전으로).
- **표지 5스와치**: 탭 = 현재 템플릿의 색 슬롯(템플릿마다 다름 — T1=구분선·강조, T4=overlay 톤 등; `templates/*.md`의 `colorMapping(ExtractedPalette)` 참조)에 적용. 흑백·단색 표지(채도<10)는 `lightenToBackground`/`toMidTone` 폴백으로 채워진 스와치가 나옴. 연속 색 변경은 디버운스로 묶어 1 언두.
- **인용구 텍스트 박스 조작**: 프리뷰 안에서 **한 번 탭** → 인라인 핸들 노출(이동/크기). 인스타 표준 제스처 문법(한손 드래그=이동, 핀치=크기)이되 **이동은 상/중/하 3지점 스냅 앵커**로 제한(템플릿 미관 보호 — 자유 배치 금지). 더블탭 편집(Tezza/Unfold 발견성 약점) **금지**. 드래그 종료(`onPanEnd`) 1회당 1 언두 push(드래그 중 매 프레임 push 금지).
- **"텍스트" 버튼**: 폰트 크기 ±(보간 범위 안 — `getQuoteFontSize` 기준 ±2~3 step) + 정렬(좌/중/우, 템플릿이 허용하는 범위). "색" 버튼: 5스와치 패널 토글. "위치" 버튼: 상/중/하 앵커 칩(또는 인라인 핸들과 통합 — §7). "워터마크" 토글: ON/OFF — OFF여도 `cards` 메타에 기록, OFF 비율 PostHog 추적. OFF여도 deep link sticker(카톡 공유 시)는 살아있게 별도 설계.
- **"다른 느낌 ↻"**: 다음 템플릿(순환) + 팔레트 슬롯 재배정 1탭. 언두 한 단위.
- **언두**(Mojo가 없어서 욕먹은 지점 — 필수): 스택 **최소 20단계**. 비율 전환·템플릿 전환·색 변경·텍스트 위치·폰트 크기 모두 대상. 언두 후 새 편집 = redo 스택 폐기(표준). Redo는 있으면 좋음(우선순위 중, V1 필수 아님). 스택 비면 ⤺ 버튼 disabled + "되돌렸어요" 미세 피드백.
- **편집 상태 영속화**: `templateId`·팔레트 override·텍스트 상대좌표·비율·undo 스택·워터마크 토글을 디버운스로 `shared_preferences`/hive에 저장. 재진입 시 "편집하던 카드를 이어서 만들까요? / 새로 시작" — 인용구 본문은 DB에 있어 안전하지만 디자인 작업은 잃지 않음. 같은 quote에 카드를 또 만들면 새 row(히스토리), 직전 5초 내 동일 design 해시 재요청은 dedupe.
- **뒤로/✕/스와이프 다운**: 확인 다이얼로그 없이 그냥 나감(카드는 부가물). PNG 생성 중이면 닫기 막거나 "취소하면 카드가 안 만들어져요". 공유 시트에서 사용자가 아무 앱도 안 고르고 취소 = `ShareResult.dismissed` = 에러 아님, Toast 없음, 에디터 유지.
- **성능**: 미리보기는 1080px 캔버스를 화면 폭으로 `FittedBox`/`Transform.scale` 축소 표시. 위젯 rebuild만으로 60fps(blur 들어가는 T4만 `RepaintBoundary`로 격리 + blurred bitmap 1회 캐시). 첫 렌더 jank 방지 = fallback 팔레트 즉시 렌더 후 cross-fade(`flows.md`의 "카드 미리보기 <16ms"는 첫 프레임엔 비현실적 — 이 패턴으로 충족).

---

## 5. 디자인 토큰 매핑

| 영역 | 토큰 |
|---|---|
| 화면 배경 | `AppColors.secondary200` (paper) — 또는 카드를 강조하려 약간 어둡게 `secondary300`. (다크 톤은 안 씀 — 카드 자체 색이 주인공) |
| 상단 바 | 투명 / ← `primary500` / 비율 세그먼트: 선택 `primary900` 배경·`secondary50` 텍스트, 미선택 `primary400` 텍스트·`primary200` border / ⤺ 언두 `primary500`(비활성 `primary300`) / **공유** = `accent500` 배경·`secondary50` 텍스트 ui w600 12, `AppRadius.sm` |
| 라이브 프리뷰 컨테이너 | `AppRadius.md` + `AppShadow.card`(카드를 종이 위에 올린 느낌) |
| 카드 내부 | `templates/01~05.md`의 명세 + `ExtractedPalette`/`fallbackPalettes` (이미 `tokens.dart`에 정의됨). 인용구 폰트 `AppFonts.quote`(NotoSerifKR), 책표시 `AppFonts.ui`(Pretendard) 또는 템플릿별 지정. 크기 = `getQuoteFontSize(charCount)`/`AppTextStyles.quoteForLength` |
| 표지 5스와치 | 22×22, `AppRadius.xs`, border 1.5 `rgba(0,0,0,.08)`. 추출값(`dominant/secondary/vibrant/darkVibrant/muted`) 그대로 |
| 템플릿 썸네일 | ~52×88, `AppRadius.xs`. 선택 시 border 2 `accent500` 또는 하단 언더라인 `accent500` |
| 보조 행 버튼 | 텍스트 버튼 ui xs(10.5) `primary500`, 활성 시 `accent600`. "다른 느낌 ↻" `accent500` |
| 워터마크 | `AppWatermark.minimal`/`branded` (`tokens.dart`의 `WatermarkConfig`) — 우하단/하단 중앙, opacity ~0.3, 텍스트 영역과 비겹침 좌표(`templates/*.md`에 박음) |
| Toast / Empty / 에러 | 공통 (`AppTheme.snackBarTheme` 등) |

새 토큰: `moodColors` 맵(`quote-input.md`와 공유 — 카드에 무드 칩을 표시할 경우). 카드 비율 픽셀은 `AppCardSize`(1080×1920 / 1080×1080 / 1080×1350) 이미 있음. `CardRatio` enum 이미 있음.

---

## 6. 재사용 컴포넌트 / 신규

**재사용 (코드에 있음)**
- `tokens.dart`: `ExtractedPalette`(7색), `fallbackPalettes`(템플릿별), `getQuoteFontSize`/`getQuoteLineHeight`/`AppTextStyles.quoteForLength`, `CardRatio`{story,feed,post}, `AppCardSize`, `AppWatermark`/`WatermarkConfig`, 색·간격·radius·shadow — **인프라 거의 완비, "명세 받아쓰기"에 가까움**
- `BookCover` 위젯 (표지 표시 — T2 좌측 영역 등)
- `cached_network_image` (표지 fetch — 이미 사용 중, 알라딘 URL 직접 캐시)
- `palette_generator` (이미 pubspec) — `PaletteGenerator.fromImageProvider`
- `color-extraction.md`의 함수 명세 (의사코드·WCAG 대비·캐시 직렬화) — 단 `Color` 채널/직렬화는 신 SDK 기준 `toARGB32()`로 갱신(`.red`/`.value` deprecated)
- `router.dart`의 `/quote/:id/card` 라우트 (배선됨)

**신규**
- `lib/features/card_editor/domain/card_template.dart` — `sealed class CardTemplate` + 5개 구현(`MinimalTemplate`/`WarmTemplate`/`MonoTemplate`/`CoverExtractTemplate`/`TypographyTemplate`), 각 `Widget build(spec, palette, ratio)` + `colorMapping(ExtractedPalette)` + `variants` (`templates/01~05.md`에 통째로 적혀 있음 — 옮겨쓰기)
- `lib/features/card_editor/presentation/widgets/quote_card.dart` — 공통 골격(`Stack` 슬롯: 배경 / 인용구 텍스트 / 책표시 / 워터마크) — T1/T2/T5 공유, T4는 자체 build(blur+overlay). **렌더 = 위젯 트리, CustomPaint 아님**(한글 텍스트 layout·blur·표지 이미지 재사용 — `flows.md`의 "CustomPaint 60fps" 폐기). CustomPaint는 T1 1px 구분선 같은 장식에만.
- `lib/features/card_editor/data/palette_service.dart` — 표지 URL → `ExtractedPalette`. 메모리 LRU 캐시(+선택적 `shared_preferences`). **books 테이블에 컬럼 추가 안 함**(클라이언트 캐시로 충분). `getPaletteWithFallback(coverUrl, templateId)` → 즉시 fallback 반환 + 비동기 갱신.
- `lib/features/card_editor/data/card_renderer.dart` — `Future<XFile> renderCardPng(GlobalKey boundaryKey, CardRatio ratio)`: `RepaintBoundary.toImage(pixelRatio: AppCardSize[ratio].width / displayWidth)` (또는 `OverflowBox`로 1080 논리폭 강제 후 캡처) → PNG → `path_provider` 임시 파일. 캡처 직전 `await WidgetsBinding.instance.endOfFrame` + 폰트 미로드 시 1회 재시도. `ui.Image.dispose()` 호출. 워터마크는 캡처 트리 안 `Positioned`(별도 합성 아님).
- `lib/features/card_editor/state/card_editor_controller.dart` — `templateId`/`paletteOverride`/`textAnchor`/`fontStep`/`ratio`/`watermarkOn`/`undoStack` 상태 + 영속화. NotifierProvider.
- `supabase/migrations/<ts>_cards.sql` — `cards(id, quote_id fk, user_id fk, design jsonb, ratio text, watermark bool, created_at)` — 한 인용구 → 여러 카드(1:N). `design jsonb`에 templateId·팔레트·앵커 등. RLS = user_id 패턴. (`architecture.md`의 "카드 jsonb 저장, 정규화 안 함" 결정과 정합.)
- `lib/features/card_editor/card_editor_screen.dart` — 스텁 전면 재작성. `RepaintBoundary` + `GlobalKey`로 프리뷰 감싸기.
- `pubspec.yaml`: `share_plus`, `path_provider` 추가(필수). `gal`은 명시적 다운로드 버튼 붙일 때(`card-share.md`).

---

## 7. 엣지 케이스 / 접근성 / 미결

**교차 관심사 (공통 8원칙)**: ① 오프라인=1급(표지 캐시·로컬 PNG) ② 데이터 유실 금지(편집 상태 영속화 — 인용구 본문은 DB) ③ PII 로그 금지(인용구 텍스트 미전송) ④ 막다른 골목 금지(저장 권한 거부해도 공유는 됨, 카톡 미설치해도 다른 공유 가능) ⑤ 해당 없음(이 화면엔 책 검색 시트 없음) ⑥ 에러 표시 일관성 ⑦ 인증 가드 ⑧ "미리보기 = export"(같은 위젯 트리, 스케일만 다름 — 스냅샷 테스트로 회귀 감지).

**화면 고유 엣지**

| 엣지 | 심각도 | 처리 |
|---|---|---|
| 인용구가 너무 길어 9:16에 안 들어감 (auto-fit 최소 폰트 도달 후에도 넘침, 예 1000자) | **높음** | ① 비율 자동 추천 "이 문장은 4:5/1:1이 더 잘 어울려요" ② 그래도 넘치면 **명시적 경고** "카드에 다 안 들어가요" + 사용자가 알고 공유/혹은 텍스트 짧게. **잘린 채 조용히 export 금지** |
| 1단어/초단문 인용구 → 카드 휑함 | 낮음 | T5(타이포)·T3(모노) 추천 + 폰트 자동 확대(최대 cap) + 중앙 정렬 강조 |
| 흑백·단색 표지 (채도<10) | 중간 | `color-extraction.md §6` 자동 폴백(`lightenToBackground`→secondary400, `toMidTone`→primary600). "이 표지는 색이 적어 기본 톤으로" 미세 안내(선택) |
| 표지 색 vs 텍스트 대비 부족 (흰 글씨가 밝은 배경에 안 보임) | **높음** | `ensureContrast(minRatio: 4.5)` 자동으로 primary900/secondary200 중 대비 높은 쪽 교체. T4는 그라데이션 overlay 80% 추가 보장. **이 로직 깨지면 가독성 0** → 스냅샷 + 대비 테스트 필수 |
| 비율 전환 시 텍스트 위치 깨짐 | 중간 | 텍스트 위치를 상대좌표(0~1)로 저장 → 새 비율에 재투영 + clamp. "위치를 조정했어요" Toast |
| 편집 중 앱 백그라운드 → 메모리 회수 | 중간 | 편집 상태 디버운스 영속화 → 재진입 "이어서 만들기". 인용구 본문은 DB라 안전 |
| 같은 카드 여러 번 저장/공유 | 낮음 | 허용(의도적일 수 있음). `cards`엔 매번 새 row. 직전 5초 내 동일 design 해시 재요청은 dedupe |
| 카드 PNG에 워터마크가 텍스트 가림 | 중간 | 워터마크는 항상 고정 안전 영역(`templates/*.md`에 텍스트 영역과 비겹침 좌표 박음). auto-fit 텍스트 영역 계산 시 워터마크 영역 제외 |
| quote 본문에 이모지/특수문자/RTL 섞임 | 낮음 | 시스템 이모지 폰트 fallback 체인. PNG 캡처 전 렌더 검증 |
| 잘못된 quoteId (`/quote/abc/card`) | 낮음 | 라우터 가드 또는 화면에서 `PGRST116` → "찾을 수 없어요" empty. 무한 루프 금지(리다이렉트 1회) |

**접근성**
- 카드 자체의 대비는 `ensureContrast`가 보장(WCAG AA 4.5:1). 에디터 UI 크롬: 비율 세그먼트·언두·공유·보조 행 버튼 모두 ≥48dp hit area + 충분한 대비.
- 색만으로 의미 전달 X: 선택된 템플릿은 언더라인(색 + 형태), 선택된 비율은 채워진 박스(색 + 형태).
- 스크린리더: 프리뷰에 `'카드 미리보기 — $templateName, 인용구: $text'`, 비율 세그먼트 toggle semantics, 템플릿 썸네일 `'$templateName 템플릿, ${selected ? "선택됨" : ""}'`, 공유 버튼 `'카드 공유하기'`, 언두 `'되돌리기, ${canUndo ? "" : "되돌릴 작업 없음"}'`. 표지 5스와치 = `'표지에서 추출한 색 ${i+1}'` (색 이름은 안 읽음 — 의미 없음).
- 카드 PNG 자체는 이미지라 alt text 없음(공유 산출물) — 받는 사람 deep link 화면에서 텍스트로 인용구 노출(`deep-link-receive.md`).

**결정 완료 (DECISIONS 2026-05-12)**
1. **텍스트 위치 앵커(상/중/하): V1엔 안 넣음. V1.5.** V1 미세 조정 = 폰트 크기 ±·정렬(템플릿 허용 범위)만. 이유: `templates/*.md`가 이미 고정 좌표 모델(`quoteArea y=192` 등)이라 앵커는 5종 명세 재작성 + 디자인팀 재합의 필요 → 차별화와 시간 경쟁. 단 `card_editor_controller`의 텍스트 위치는 **지금부터 상대좌표(0~1)로 직렬화** — V1.5에 앵커 3지점 스냅 붙일 때 마이그레이션 0.
2. **표지 없는 책에서 T4(표지발췌): 비활성화.** 썸네일 회색 + "표지가 필요해요" 오버레이(`templates/04.md`의 `showTemplateDisabledOverlay`), 나머지 4종 정상 + (가능하면) "표지 추가하기" 인라인 액션으로 ISBN 재검색 유도. 이유: T4의 정체성이 "이 색이 이 책 표지에서 나왔다"는 바이럴 순간 — 표지 없는데 단색 degrade하면 약속이 거짓 + T1/T3와 구분 안 됨.

---

## 변경 이력
- 2026-05-11 초안 (매니저 종합 — competitor-screen-analysis §5.2 + QA-2 + Dart-2 + templates/01~05 + color-extraction.md).
