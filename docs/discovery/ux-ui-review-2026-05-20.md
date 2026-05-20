# UX/UI 자가 피드백 10회 반복 — V1.0 출시 직전 종합 리뷰

**기준일**: 2026-05-20 (PR22 무드 hub + PR23 NowReadingRow + PR24 FAB 옵션 C + 잠금 해제 stale fix + 캘린더 sync fix 후속)
**작성 방식**: Claude(매니저 모드) + 가상 UX/UI 페르소나 10명을 회마다 다른 조합으로 소환. 코드를 직접 읽고 페르소나 관점에서 진단(시뮬레이션이 아니라 *코드+페르소나 결합*).
**선행 기준**: `docs/discovery/scenario-review-2026-05-17.md` 35건은 PR14·20·22·23·24 거치며 대부분 처리됨. 본 리뷰는 **그 이후 *새로 만들어진* 코드** + **이전 라운드에서 못 본 사각지대**에 집중.

---

## 0. Executive Summary

| 분류 | 항목 수 | 권고 |
|---|---|---|
| **P0 — V1.0 출시 전 처리 권고** | 6건 | 데이터 손실 위험·차별화 핵심 단절·접근성 회귀 |
| **P1 — 출시 후 1~2주 hotfix** | 14건 | 흔한 마찰·UI 일관성·정서 톤 |
| **P2 — V1.5+ 백로그** | 11건 | 드물거나 미래 가치 |
| **시각 디자인 리팩터링 후보** | 4건 | 통합 리뷰 — 출시 후 한 번 묶음 작업 |
| **합계** | **35건** | scenario-review-2026-05-17의 35건과 별개 *신규* |

### 매니저 권고 — 출시 시점 판정

**현재 코드는 V1.0 출시 가능 상태**다 (P0 6건은 *권고*이며 차단은 아님). 다만 **차별화 핵심**(*적기로 가는 다리* PR23, *무드 hub* PR22, *카드 디자인→공유* PR10.5)이 살리려는 **정서적 톤**을 깎는 자잘한 균열 — 카피 일관성, 마이크로 인터랙션 부재, 빈상태 정서 — 이 누적된 결과 *완성도 인상이 30% 가량 깎인다*. P0 6건만 처리해도 인상이 회복된다.

---

## 1. 페르소나 풀 (10명)

| # | 이름 | 직군·배경 | 강점 |
|---|---|---|---|
| **S** | Sarah Lee | 10년차 모바일 UX 디렉터 (전 Instagram·Pinterest) | 시각 위계·일관성·인지 부하 |
| **M** | Min-jung Park | 그래픽 디자이너 (매거진 출신, 35) | 타이포그래피·여백·색채 감각 |
| **J** | Joon Kim | 인터랙션 디자이너 (Toss UX) | 마이크로 인터랙션·햅틱·전환 애니메이션 |
| **H** | Hye-rin Choi | D1~D7 신규 *실사용자* (32, 마케터, 책 5권/년) | 첫 진입 마찰·온보딩·정서적 첫인상 |
| **T** | Tae-hyun Yoo | D30+ 헤비 *실사용자* (54, 고등학교 교사, 책 200권 누적) | 누적 사용 효율·검색·내보내기 |
| **B** | Kim Byeong-su | 접근성 전문가 (a11y 컨설턴트, 노안+적록색맹) | WCAG·텍스트 스케일·색대비·스크린리더 |
| **Q** | Lee Mi-jin | 모바일 QA 8년차 (전 카카오 QA) | 다국어·오프라인·엣지 |
| **A** | Park Jung-ho | Android OS UX 전문 (Material 3·Predictive Back·System UI) | OS 통합·딥링크·시스템 일관성 |
| **I** | Anna Kim | iOS HIG 전문가 (Android와 *대비*되는 관점) | 한 손 도달성·SafeArea·iOS UX 패턴 |
| **X** | Hyun-woo Han | BX 디자이너 (브랜드 정서·언어) | 카피 톤·정서 일관성·"책귀" 브랜드 보이스 |

---

## 2. 회별 반복 — 10라운드

각 회마다 페르소나 2~3명을 다른 조합으로 소환. 코드 위치를 명시한 발견사항만 채택(추측·일반론은 배제).

---

### R1 — 첫 진입 (스플래시 → 로그인 → 빈 홈)
**페르소나**: Sarah · Joon · Hye-rin
**검토 코드**: `login_screen.dart`, `home_screen.dart:199-228` 빈상태

**발견 R1-1 — 로그인 후 진입점에 "무엇을 할지" 부재** [P1]
빈 홈(`home_screen.dart:199`)이 보여주는 건 "＋ 인용구 추가" 한 버튼뿐. Hye-rin: *"책귀가 뭘 도와주는 앱인지 모르겠어요. 그냥 텍스트 저장 앱 같아요."*
**제안**: 빈상태에 1~2장 간단 일러스트(책+인용 마크 + "단톡 카드로 보낼 수 있어요" 한 줄) 추가. 차별화 ①(*저장 → 공유*)을 *행위로 학습시키는 1초 단서*가 빠져있다.

**발견 R1-2 — `_emptyView`의 두 텍스트 위계 비대칭** [P2]
`home_screen.dart:207-211`: `headlineSmall` "아직 인용구가 없어요" + `bodyMedium` "좋아하는 책의 한 줄을 저장해보세요" — Sarah: *"두 줄 사이 간격(`s2`)이 너무 좁고, 부 메시지가 본 메시지를 보조하는 게 아니라 그냥 같이 떠 있어요."* Spacing s4 + 부 메시지 색 `primary500`(현재 default) 명시.

**발견 R1-3 — 마이크로 인터랙션 0건** [P1]
Joon: *"`＋ 인용구 추가` 탭 → 화면 전환만 일어남. 햅틱 진동(HapticFeedback.lightImpact) 없음. Material 3 ripple도 ElevatedButton 기본만."* 차별화 정서 톤("내가 누른 게 받아졌다")이 부재. `core/theme`에 `HapticFeedback` wrapper 1개 + 주요 CTA 4곳(저장·서재 담기·팔로우·공유)에만 적용해도 인상 ↑.

**발견 R1-4 — 스플래시 → 로그인 컬러 점프** [P2]
Sarah: *"스플래시는 secondary50(따뜻한 베이지), 로그인 Scaffold는 default(흰색?) — 진입 시 한 번 깜빡임."* `app_theme.dart`에서 Scaffold background를 secondary50으로 고정 권고.

---

### R2 — 홈 피드 + NowReadingRow + 친구 활동 배너
**페르소나**: Hye-rin · Tae-hyun · Sarah
**검토 코드**: `home_screen.dart:130-173`, `now_reading_row.dart`, `friend_activity_banner.dart`, `recall_card.dart`, `outbox_banner.dart`

**발견 R2-1 — 홈 상단 4단 적층의 시각 부담** [P1]
`home_screen.dart:144-154`: OutboxBanner → FriendActivityBanner → NowReadingRow → RecallCard → FriendSearchCta. 5개 위젯이 모두 동시 노출 가능. Sarah: *"각각 다른 색·여백·border-radius를 쓰면 시각이 끊겨요."*
**확인**: 실제 코드 보면 각 위젯이 자체 padding + border + decoration — 디자인 시스템 통합 부재.
**제안**: 4가지 모두 `_HomeBanner` 공통 컨테이너(secondary50 + radius md + s3 padding) 안에 wrap → 시각 일관성 + 인지부하 ↓.

**발견 R2-2 — NowReadingRow 빈상태 정서 부재** [P1]
`now_reading_row.dart`의 빈상태(line 6-10 주석)는 *"지금 읽는 책이 없어요" + [＋ 시작한 책 알려주기]*. Hye-rin: *"슬프거나 외로운 톤이 아니라 *비어있어서 이상하다*는 톤이에요. 신규는 당연히 비어있는데."*
**제안**: 빈상태 카피 = "📖 읽기 시작한 책을 알려주세요" + 부 텍스트 "오늘 시작한 한 권부터 — 한 줄씩 모아봐요" (차별화 ④ *축적의 정서* 노출).

**발견 R2-3 — FriendActivityBanner: ≥2명 시 *익명화*가 SNS UX와 어긋남** [P1]
`friend_activity_banner.dart` (코드 미확인이나 STAGES.md:84-85에 명세): *"지윤 외 N명이 새 인용구를 보탰어요"*. Sarah: *"인스타·트위터는 *지윤·민호·다은*처럼 첫 3명을 노출. 익명 N명은 *알림 피로*를 늘리지 않으려는 차별화지만, K-factor 다리 역할은 *지인 이름 노출*에서 와요."*
**제안**: 1명일 때만 이름 노출 → 다인일 때도 첫 2명까지 노출 (지윤·민호 외 N명).

**발견 R2-4 — `RefreshIndicator`가 friendActivity와 quoteFeed 둘만 invalidate** [P2]
`home_screen.dart:156-160`: pull-to-refresh 시 NowReadingRow·OutboxBanner는 갱신 안 함. Q(Lee Mi-jin): *"D7 사용자가 책 상세에서 완독 표시 후 홈 당겨새로고침했을 때 NowReadingRow에서 그 책이 안 사라지면 *버그 의심*하게 됨."*
**제안**: `refresh.onRefresh`에 `invalidate(currentlyReadingProvider)` 추가.

**발견 R2-5 — RecallCard 위치 비정합** [P2]
홈 4단(OutboxBanner → FriendActivity → NowReading → RecallCard) — RecallCard는 *과거 인용구 다시 보기*. Sarah: *"신규 사용자(인용구 ≤3)에겐 RecallCard 자체가 빈 상태(추정). NowReadingRow 아래보다 *피드 안 N번째 카드 사이*에 자연 끼워넣기가 더 효과적."*
**확인 필요**: `recall_card.dart`가 빈상태 자체 숨김 처리하는지 — 안 한다면 P1로 격상.

---

### R3 — 인용구 입력 (잠금 인용구 포함)
**페르소나**: Min-jung · Lee Mi-jin · Hyun-woo
**검토 코드**: `quote_input_screen.dart` 전체

**발견 R3-1 — `_BookField` (line 793) 시각 위계 약함** [P2]
`secondary100` 배경 + `primary100` border — Min-jung: *"본문 입력 칸 다음으로 중요한 행인데 그 자체로 *flat tile*. 호버·focused 상태에서도 시각 차이 없음."* 호버 시 border 색 변경 + 책 연결됐을 때 *bookCover와 함께 더 prominent해야 함*.

**발견 R3-2 — "무드" 라벨 카피 약함** [P1]
`quote_input_screen.dart:705-706`: *"무드 (선택, 최대 3개)"* — Hyun-woo: *"*무드*는 영어 외래어 + 부 정보(*선택, 최대 3개*)가 *기능 안내*라 정서 톤이 깎임."*
**제안**: "어떤 마음으로 읽었나요?" (선택) + 칩 위에 작게 *"최대 3개"* 안내.

**발견 R3-3 — `_isPrivate` 토글이 평문 변환 시 *경고 한 번뿐*** [P2]
`quote_input_screen.dart:323-348` 편집 모드 잠금→평문 전환에서 확인 다이얼로그. Q(Lee Mi-jin): *"사용자가 *그대로 공개*를 *반사적으로* 누르는 경우 — 본명·민감 정보가 평문으로 저장됨. 다이얼로그가 *위험 강조*가 너무 약함."*
**제안**: AlertDialog의 *잠금 해제* 버튼을 disabled 상태로 시작 + "이해했어요" 체크박스 활성화해야 누를 수 있게.

**발견 R3-4 — Draft 복원 SnackBar의 [지우기] 액션 race** [P1] *(이미 알려진 B7과 별개)*
`quote_input_screen.dart:185-196`: SnackBar의 *지우기* 액션이 controller 텍스트를 clear + draft store clear. 하지만 *지우기 액션 자체가 비동기* → 사용자가 직후 타이핑 시작하면 `_textController.clear()`가 그 입력을 지움. 데이터 손실 위험.
**제안**: 지우기 액션 진입 시 `_textController` 일시 *비활성*(`enabled: false`) 또는 `await` 없이 즉시 clear.

**발견 R3-5 — `_PasteBanner` 위치가 *본문 입력 후*에 적층** [P1]
`quote_input_screen.dart:667-673`: PasteBanner가 TextField 아래. Min-jung: *"클립보드가 있을 때 *입력 시작 전에* 보여주는 게 자연인데, TextField 아래라 사용자가 TextField focus 후에 발견."*
**제안**: PasteBanner를 TextField 위로 이동 (autofocus와 충돌하면 PasteBanner를 TextField 위에 두되 PasteBanner 자체엔 focus 주지 않음).

**발견 R3-6 — `_relativeTime` 한국어 톤 약화** [P2]
`quote_input_screen.dart:204-211`: "방금 / N분 전 / N시간 전 / N일 전 / N주 전" — Hyun-woo: *"*N주 전*은 너무 차가운 시간 표현. 차별화 *천천히 모이는 책귀*에 어울리는 *지난주·이번 달·꽤 오래전*도 후보."*
**제안**: 1주 ≤ x < 4주 = "약 N주 전", x ≥ 4주 = "한 달 전 / 꽤 전에" 같은 인간적 표현.

---

### R4 — 카드 에디터 + Quick Share + 공유 시트
**페르소나**: Joon · Min-jung · Anna · Sarah
**검토 코드**: `card_editor_screen.dart` 전체, `quick_share_screen.dart` 전체

**발견 R4-1 — `_AutoFitWarning` (line 505) 시각 권위 부족** [P1]
SemanticWarning + amber icon — Min-jung: *"이건 *기능적 경고*. 사용자가 *잘리는 시각 미리보기*를 직접 봐야 동의가 강함."*
**제안**: 경고 행 클릭 시 *현재 비율*과 *추천 비율*을 2-up split preview thumbnail 노출 (작은 80×120 mini card 2개 비교). MVP라면 추천 비율 적용 후 *즉시 시각적 차이* 보여주는 100ms cross-fade.

**발견 R4-2 — `_PreviewBox` `AnimatedSwitcher` 200ms가 너무 느림** [P2]
`card_editor_screen.dart:782-783` — Joon: *"템플릿 5개를 빠르게 비교하려는 사용자에게 200ms는 *비교 흐름을 끊는 길이*. 80~120ms가 *부드럽되 즉각적*."*
**제안**: duration 120ms + `curves.easeOutCubic`.

**발견 R4-3 — `_TemplateStrip` (line 805) 가로 스크롤 끝 시각 단서 없음** [P2]
ListView.separated 가로 스크롤이지만 *오른쪽에 더 있다*는 단서(끝에 fade gradient 또는 last item이 살짝 보임) 없음. Sarah: *"사용자가 *5개 다 봤다*고 착각하기 쉬움 — 첫 화면에 보이는 3.5개로 다."*
**제안**: `_TemplateStrip`을 `ShaderMask` (linear gradient 오른쪽 끝 transparent) 또는 endIndicatorPadding s4 추가.

**발견 R4-4 — `_FontSteppers` (line 693) 시각적 *변화 단서* 약함** [P1]
[A−][A+] 탭 후 미리보기 카드의 폰트 변화는 *AnimatedSwitcher의 200ms*에 묻힘. Joon: *"폰트 변경은 *글자 크기*가 바뀌는데 사용자가 그 변화를 *지금 누른 결과*로 인지 못 함."*
**제안**: A−/A+ 탭 시 미리보기 카드에 *짧은 scale punch*(1.0 → 1.02 → 1.0, 120ms) 추가 — 변화의 결과를 시각 강조.

**발견 R4-5 — `_PaletteRow` (line 582) "다른 느낌 ↻" 아이콘이 *팔레트와 무관해 보임*** [P2]
swatch 5개 옆에 refresh 아이콘. Min-jung: *"swatch는 *색*인데 옆 아이콘은 *템플릿 순환*. 사용자가 *색을 새로고침*하는 거라 오해."*
**제안**: refresh 아이콘 위에 작은 텍스트 "다른 느낌" + 아이콘 변경 후보(swap_horiz, format_paint).

**발견 R4-6 — `quick_share_screen.dart:202-208` *디자인 편집* TextButton 위계 약함** [P0]
공유 시트가 자동 뜬 후 dismiss 시 *디자인 편집*은 AppBar의 작은 텍스트 버튼. PR14-G에서 push로 고친 ④ 막다른 골목 회피인데, *진짜 사용자는 [디자인 편집]을 거의 못 찾음*. Sarah: *"자동 시트가 닫혔을 때 *다음 행동*은 AppBar가 아닌 *본문 하단*에 큰 두 버튼이어야 — [디자인 편집] / [다시 공유]."*
**P0 이유**: 차별화 핵심 흐름(*디자인 → 공유 → 디자인 다시*)이 *발견되지 않으면 의미 없음*.
**제안**: `_buildBody()` 하단 FilledButton "다시 공유" 옆에 OutlinedButton "디자인 편집" 추가, AppBar 텍스트 버튼은 제거.

**발견 R4-7 — 카드 에디터 `_LockedView` (line 1022) 컴포넌트 중복** [P2]
`quick_share_screen.dart:440-491`와 `card_editor_screen.dart:1022-1074`가 거의 동일. Q: *"카피·아이콘·버튼 스타일이 두 곳에서 따로 사는 게 *향후 카피 변경 시 한 쪽만 바뀌는 위험*."*
**제안**: `lib/features/crypto/presentation/locked_quote_view.dart` 1개로 통합.

**발견 R4-8 — `_buildShareBar`의 *공유* 버튼이 다른 화면의 공유 버튼과 *색 분기*** [P1]
`card_editor_screen.dart:130-154`: accent500 FilledButton "공유". `quick_share_screen.dart:268-289`: 동일 accent500 FilledButton이지만 *"다시 공유"*. 한쪽은 ios_share_rounded icon, 다른쪽도 같지만 *위치는 다름*(에디터=하단 fixed, quick_share=하단 fixed). 일관성은 OK. **다만** quote_list_card의 [📤 바로 공유]는 accent400(아마도) — Sarah: *"같은 *공유* 행동인데 색이 다른 곳마다 미세 다름. 디자인 토큰 *공유 액션 색*을 한 가지로 통일."*

---

### R5 — 서재 [책 ↔ 인용구 ↔ 캘린더] + 무드 hub + FAB
**페르소나**: Sarah · Park Jung-ho · Tae-hyun
**검토 코드**: `library_screen.dart`, `quote_list_view.dart`, `mood_hub_grid.dart`, `calendar_segment.dart`

**발견 R5-1 — `library_screen.dart:107-113` FAB가 [캘린더] 탭에서도 [+ 책 추가]** [P1]
PR24에서 [인용구] 탭만 FAB 숨김 결정. 그러나 [캘린더] 탭은 *읽기 전용*인데 FAB는 [+ 책 추가]로 나타남. Park: *"캘린더에서 [책 추가]는 *맥락 어긋남*. 사용자는 *날짜를 보고 그 날짜에 뭔가 추가*하길 기대."*
**제안**: [캘린더] 탭에서도 FAB null, 또는 "오늘 시작한 책 알리기" (= `setReadingDate(started_at=today)`)로 분기.

**발견 R5-2 — `MoodHubGrid` (mood_hub_grid.dart) 카드 4건↑일 때 `childAspectRatio 0.95` 비효율** [P2]
2열 그리드 + 0.95 → 정사각. Sarah: *"PR22가 카드 *본문 4줄 발췌*까지 보여주는데 정사각에서 4줄은 *글자 잘릴 위험*. 0.8(세로 더 김)이 발췌 가독성 ↑."*
**확인 필요**: 실기기 5무드(=3행) 모두 표시 시 발췌 잘림 정도 측정.

**발견 R5-3 — `MoodHubGrid` 발췌 *"잠긴 인용구만 있어요"* 카피 정서 약함** [P1]
mood_hub_grid.dart:140 — *"잠긴 인용구만 있어요"* (italic + alpha 0.55). Hyun-woo: *"PR16 핵심은 *나만의 본문*인데 *잠긴*은 *접근 불가*의 부정 톤. 차별화 ⑥ *내 비밀 공간*의 정서가 *깎임*."*
**제안**: *"이 무드는 비밀 인용구만 있어요"* 또는 *"이 무드는 나만 볼 수 있는 한 줄만"*.

**발견 R5-4 — `quote_list_view.dart` hub ↔ 단면 전환 시 *돌아갈 길* 단서 약함** [P1]
hub → 무드 카드 탭 → 단면 진입. 단면에서는 `_FilterChips`의 *[전체]* 칩을 누르면 hub로 복귀(코드 `_selectMood(null)` line 182-192). 하지만 *[전체]*가 hub 복귀임이 사용자에게 명시되지 않음. Tae-hyun: *"단면에서 *전체*는 *모든 인용구*가 *시간순*으로 보일 거라 기대 — *hub로 돌아가기*는 별개 의미."*
**제안**: 단면 진입 시 AppBar 왼쪽 leading에 임시 *← 무드 둘러보기* 텍스트 버튼 (현재는 BottomNav만). 또는 `_FilterChips`의 *[전체]* 라벨을 *[무드 둘러보기]*로 변경.

**발견 R5-5 — `calendar_segment.dart:53-146` 캘린더 마커 색대비 부족 (R9에서 deep dive)** [P0 → R9 참조]

**발견 R5-6 — `_DetailList` (calendar_segment.dart:220) 빈상태 *해야 할 행동* 부재** [P2]
`'이 날 시작·완독한 책이 없어요'` — Sarah: *"빈상태에서 *오늘이라면 [지금 시작] 버튼*이 자연. 캘린더는 *시간 축*이라 *과거 빈 날짜*엔 행동 없어도 OK지만 *오늘*은 행동 가능."*
**제안**: `selectedDate == today`일 때만 *"오늘 책 시작 알리기"* OutlinedButton 추가.

---

### R6 — 책 상세 (별점·readingDates·미니리스트·친구 N명)
**페르소나**: Tae-hyun · Hyun-woo · Sarah
**검토 코드**: `book_detail_screen.dart` 전체

**발견 R6-1 — `_BookBody` (line 107) header Row 모바일 6.5인치 *세로 길이 ↑*** [P1]
표지 96×140 + 우측 Column(title `headlineMedium` + author + meta + ISBN + 별점 + readingDates) = 우측 컬럼이 *세로로 깊음*. Tae-hyun: *"책 표지 옆에 모든 정보를 *세로로 쌓는 패턴*은 *Goodreads, StoryGraph*는 *표지를 위에 떼고 정보는 아래*로 가."*
**제안**: 표지 = 가로 Center, 표지 아래에 정보 column. 결과: 깊이 ↓, 표지 *주목*↑.

**발견 R6-2 — `_BookRatingRow` (line 742) + `ReadingDatesRow` (별도 위젯) *공간 충돌*** [P2]
`book_detail_screen.dart:150-155`: 둘 다 표지 우측 Column 안에 적층. ReadingDatesRow는 2행([오늘][어제][직접] 칩 *3개씩 × 2*) — 폭 280dp 이상 필요. 6.5인치 폰 표지 옆 우측 column 폭은 ~230dp.
**확인 필요**: 실기기 SM F956N에서 칩 줄바꿈 발생 여부.
**제안**: ReadingDatesRow를 우측 column에서 **빼고** header Row 다음 별도 행으로.

**발견 R6-3 — `_SharedBanner` (line 187) deep link 진입 *익명 카피*** [P1]
sender 정보 없을 때 "*누군가 이 책의 한 줄을 보냈어요*" — Hyun-woo: *"*누군가*는 *낯섦/스팸 의심*. *친구가 보낸 책*이 *공유받음*의 본질."*
**제안**: 발신자 프로필 없는 경우 카피를 "*친구가 이 책의 한 줄을 보냈어요. 한번 살펴보세요.*"로 톤다운(*보냈어요*는 친밀, *누군가*는 비친밀).

**발견 R6-4 — `_DescriptionText` (line 556) *더 보기/접기* TextButton padding zero라 hit area 32dp** [P1 — 접근성]
line 593-595: `padding: EdgeInsets.zero, minimumSize: const Size(0, 32)`. Material 최소 48dp 미달. **R9에서 dup 다룸**.

**발견 R6-5 — `_AddQuoteButton` (line 259) "이 책 인용구 추가" 너비 *full*** [P2]
6.5인치 폰에서 button 너비 ~350dp + label 12자. Sarah: *"버튼 너무 *과대*. *카드 가운데* 정도 너비(~250dp)가 더 *발견적이고 디자인적*."*
**제안**: max-width 320dp + centered.

**발견 R6-6 — `_FriendsWithBookSheet` (line 858) DraggableScrollableSheet 안에 *드래그 핸들*만 + 닫기 버튼 없음** [P1 — 접근성]
B(Kim Byeong-su): *"스크린리더에서 *드래그*를 인지하지 못해 시트 빠져나갈 수 없음. 닫기 버튼은 항상 명시적이어야."*
**제안**: 시트 우상단 IconButton(close_rounded) 추가.

---

### R7 — 친구 프로필 + 친구 검색 + K-factor
**페르소나**: Sarah · Hyun-woo · Tae-hyun
**검토 코드**: `friend_profile_screen.dart`, `friend_search_screen.dart`

**발견 R7-1 — `_isSuspiciousNickname` (friend_profile_screen.dart:180-183) *지나치게 공격적*** [P1]
`name.contains('.') || name.contains('_')` — Hyun-woo: *"*박.태건*, *taehyun_park*도 정상 닉네임일 수 있는데 *풀스크린 게이트*까지 가는 건 과대 보호."*
**확인 필요**: 본인이 정한 의도(*이메일 local-part 패턴*)인지 일반 닉네임도 걸리는지 — STAGES.md에 *"이메일 local-part 의심 패턴"* 명시되어있어 *의도된 가드*. 그러나 정상 닉네임 우회를 위한 *닉네임 변경 안내 + Y/N* 다이얼로그로 격하 권고.

**발견 R7-2 — `_Header` (line 259) 팔로워/팔로잉 카운트가 *0일 때*도 노출** [P2]
신규 친구 프로필 진입 시 "*팔로워 0 · 팔로잉 0*" — Sarah: *"인스타·트위터는 0을 *그냥 비워둠* — 0 노출은 *실패의 인상*."*
**제안**: 0이면 해당 _CountTap 자체 숨김.

**발견 R7-3 — `_FollowButton` (line 393) *팔로잉* 상태 OutlinedButton + *check* 아이콘** [P2]
Sarah: *"인스타 표준은 *팔로잉* + hover/long-press 시 *언팔로우* 옵션. 책귀는 *팔로잉* 탭 = 즉시 언팔로우 확인 다이얼로그. *언팔로우*가 *팔로잉 상태 토글*이라는 mental model에 어긋남."*
**제안**: 현 패턴 유지 (확인 다이얼로그가 안전망) — *단* 버튼 라벨을 *팔로잉 ⌄* (드롭다운 단서)로 변경하거나 long-press 패턴 도입.

**발견 R7-4 — `_LockedLibraryView` (line 775) *팔로우 중* 카피가 *희망 없음*** [P1]
*"팔로우 중이에요. 서재가 공개되면 여기서 볼 수 있어요."* — Hyun-woo: *"*공개되면*은 *친구의 의지에 달림 — 나는 기다림*이라는 *수동성*만 남김. 친구에게 *공개 요청 알림 보내기*가 자연."*
**제안**: V1.0은 카피만 *"친구가 서재를 공개하면 여기서 볼 수 있어요. 응원의 한 줄을 보내볼까요?"* + [친구에게 카드 보내기 ▸] (= 친구 프로필의 다른 흐름).
*V1.5*: 공개 요청 알림 시스템.

**발견 R7-5 — `friend_search_screen.dart:75-90` *검색 시작 전* 빈상태에 *최근 본 친구* 등 *씨앗*이 없음** [P2]
빈 hint는 *"이름으로 친구를 찾아보세요"* + *"카드를 받았다면 발신자 이름을 검색해보세요"* — Tae-hyun: *"D30 사용자는 *전에 본 친구*를 다시 찾으려고 검색하러 들어옴. *최근 본 친구 5명* 칩을 검색바 아래 자동 노출하면 *검색 마찰 50%↓*."*
**V1.5 백로그** (Tae-hyun이 D30+라야 가치 있음).

**발견 R7-6 — `_ResultTile` (friend_search_screen.dart:179) trailing 팔로우 버튼 *visualDensity.compact*가 hit area 36dp** [P1 — 접근성]
B: *"노안 사용자에게 36dp는 *심리적 작음*. 옆 친구 ListTile 탭(프로필 진입)과 *오타* 위험."*
**제안**: visualDensity 기본값 + IconButton 대신 InkWell wrap으로 hit area 48.

---

### R8 — 마이 페이지 + 약관 + 잠금 비밀번호 + 탈퇴
**페르소나**: Lee Mi-jin · Anna · Park Jung-ho
**검토 코드**: `profile_settings_tiles.dart`, (lock_password_screen·lock_dialogs은 grep 패턴만)

**발견 R8-1 — `DisplayNameTile` (line 141) *trailing*에 현재 닉네임 + chevron** [P2]
displayName == ""일 때 trailing이 *"미설정"* — Sarah: *"미설정은 *부정적*. *지정해주세요*가 *행동 유도*."*
**제안**: empty 시 trailing = "지정해주세요" + primary500.

**발견 R8-2 — `_DisplayNameEditDialog` (line 208) *30자 이내* 명시되지만 *실시간 카운터 없음*** [P1]
B(Q와 협업): *"사용자가 입력 후 *저장* 누른 후에 에러 나면 *입력 마찰*. 카운터를 *0/30*로 실시간 표시."*

**발견 R8-3 — `ProfilePublicToggleTile` (line 21) `_confirmNicknamePattern` 다이얼로그의 *"그대로 공개"* FilledButton** [P0]
profile_settings_tiles.dart:126-129: FilledButton (즉 *강조 액션*)이 *위험 액션*. Sarah · Anna: *"FilledButton은 *safe primary*. *위험한 액션*은 TextButton 또는 *destructive 색*."*
**P0 이유**: 본명/직장 이메일 노출 사고 방지를 위해 이 다이얼로그가 도입됐는데, *위험 액션이 강조 버튼*이면 *반사 클릭* 유도.
**제안**: *[취소]* FilledButton(safe primary), *[그대로 공개]* TextButton + semanticError 색.

**발견 R8-4 — `lock_password_screen` (코드 미확인 — 위치 lib/features/crypto/presentation) *잠금 마스터키 잊었을 때 복구 경로*** [P1]
PR16 핵심: *서버도 모름*. 사용자가 마스터키 잊으면 *기존 잠금 인용구 *영구* 복구 불가*. Anna: *"이 *불가역성*이 *온보딩 시점*에 명시되지 않으면 D30+ 사용자가 *백업 안 했으니 잃은 거*에 분노."*
**제안**: lock_password_screen 첫 진입 *경고 페이지* — "*마스터키를 잊으면 *책귀 운영자도 *서버도* 복구할 수 없어요. 종이에 적어두세요.*" + *체크박스 [이해했어요]* 활성화해야 진행.
**확인 필요**: 실제 코드 어떻게 됐는지.

**발견 R8-5 — 탈퇴 흐름 — *2단계 확인*은 OK지만 *데이터 다운로드 제공 안 함*** [P1]
STAGES.md *"회원 탈퇴 2단계"* 명시. 그러나 *Markdown 내보내기*가 *Me에서 별도*. Park: *"GDPR/한국 개인정보보호법 권고 — 탈퇴 직전 *내 데이터 받아보세요* 안내가 *권리 행사* 차원."*
**제안**: 탈퇴 1단계 다이얼로그에 *"내 인용구 Markdown으로 받아두지 않으시겠어요?"* + [받기 ▸] 추가.

**발견 R8-6 — Markdown 내보내기 후 *알림 BottomSheet 미구현* (designer 권고)** [P2]
2026-05-17 designer walkthrough에서 *"Markdown 내보낸 후 정보성 BottomSheet 1회"* P2로 격하. V1.0.1 hotfix 후보로 STAGES.md에 등재되어있음.

---

### R9 — 접근성 deeper (텍스트 스케일·색대비·motion·스크린리더)
**페르소나**: Kim Byeong-su (접근성 전문, 노안+적록색맹) — 단독 deep dive
**검토 코드**: 전반 + `calendar_segment.dart:184-218` 캘린더 마커

**발견 R9-1 — 캘린더 마커 색대비 부족** [P0]
`calendar_segment.dart:184-218`: ReadingMarkKind.started = `accent200 outline`, finished = `accent500 채움`, both = `accent500 채움 + accent700 outline`. 셀 안 6×6dp. **적록색맹 시뮬레이션**: accent500(추정 amber/orange 계열) outline only ↔ filled 모두 *밝기 차*가 크지 않음.
**P0 이유**: 접근성 가드. 색만으로 의미 전달 *X*은 명세에 있지만(`'점 색만으로 의미 전달 X — 셀 탭으로 항상 펼침'`), *셀 탭 펼침까지의 인지 단계*에서 색맹이 *마커 자체를 동일*로 인지하면 *셀 탭 동기 자체*가 사라짐.
**제안**: kind=started = empty circle outline, finished = filled circle, both = filled circle + 작은 ✓ 마크 inside. *모양 차이* 추가.

**발견 R9-2 — `MoodHubGrid` 5무드 색상 색맹 구분성** [P1]
mood_chips.dart의 moodColorOf — 5무드(comfort·wistful·lateNight·insight·excitement). **확인 필요**: 5색이 적록색맹·청황색맹에서 모두 구분되는지. 카드에 *아이콘+카운트+라벨* 모두 있으니 색 의존성은 *낮음* — *P1로 격하* (시각 시뮬레이션 후 결정).

**발견 R9-3 — `_DescriptionText` *더 보기/접기* hit area 32dp** [P0]
`book_detail_screen.dart:593-595`: padding zero + minimumSize (0, 32). WCAG 2.5.5 권장 44×44. Material 권장 48×48.
**제안**: minimumSize (0, 48) + tapTargetSize = padded.

**발견 R9-4 — `_CountTap` (friend_profile_screen.dart:356) hit area** [P1]
padding `(s2, s1)` ≈ 가로 24 세로 12 + 텍스트 = 약 80×32dp 추정. 세로 32 < 44.
**제안**: vertical padding s2 → s3.

**발견 R9-5 — Semantics label 일관성** [P1]
- `_Swatch` (card_editor:654): `'표지에서 추출한 색 ${index + 1}'` ✓
- `_MiniCard` (card_editor:875): `'${template.name} 템플릿'` ✓
- `MoodHubGrid _MoodCard`: `'${snapshot.mood.label} ${snapshot.count}개'` ✓
- `_CountTap`: `'$label $count명'` ✓
- **누락**: `quote_list_card`의 카드 자체 Semantics — 본문이 *읽기 텍스트*인데 *button*으로만 인지될지 확인 필요.
- **누락**: `BookCover` 위젯의 Semantics — `Image.network` 기본 alt만 있을 가능성.
**제안**: BookCover에 `Semantics(label: '${title} 표지')` 추가.

**발견 R9-6 — `MediaQuery.textScalerOf().clamp(maxScaleFactor: 1.15)` 적용 *불완전*** [P1]
mood_chips·quote_list_view._Chip만 적용. **타 위젯들**:
- `_AutoFitWarning` 텍스트(line 552): clamp 없음 → 1.5x에서 *경고 카피*가 줄바꿈
- `_LibraryActionButton` (line 388): "내 서재에 담기" → 1.5x에서 잘림 위험
- `_AddQuoteButton`: "이 책 인용구 추가" → 1.5x에서 줄바꿈
- `_BookField`: "책 연결" → 1.5x에서 줄바꿈
**전반 정책 필요**: 모든 *single-line 라벨*에 1.15 clamp 또는 다른 fallback(줄바꿈 허용).

**발견 R9-7 — Switch.adaptive 색대비** [P1]
`profile_settings_tiles.dart:80-85`: activeThumbColor `accent500`. *비활성 트랙* 색은 default(아마 grey300). B: *"노안 사용자에게 비활성 회색·활성 amber 둘 다 *낮은 명도 대비*. *활성 시* 트랙 색도 accent500으로."*
**제안**: activeTrackColor도 명시.

**발견 R9-8 — Reduced motion 미대응** [P2]
`AnimatedSwitcher` (card_editor:782) + `_PreviewBox` cross-fade — `MediaQuery.disableAnimationsOf(context)` 안 봄. iOS *모션 줄이기*·Android *애니메이션 줄이기* 설정 무시.
**제안**: `disableAnimations == true`이면 duration 0.

---

### R10 — 종합: 인지 부하·일관성·차별화·V1.0 ship readiness
**페르소나**: Sarah + Hyun-woo + 매니저(Claude)
**검토**: 전 9회 회고 + 출시 영향 평가

**발견 R10-1 — 전체 *카피 일관성* 결함 6건 (Hyun-woo 종합)** [P1 — 묶음]
| 곳 | 현재 | 권고 |
|---|---|---|
| home empty | "아직 인용구가 없어요" | OK (현재 톤 잘 맞음) |
| now_reading empty | "지금 읽는 책이 없어요" | "📖 읽기 시작한 책을 알려주세요" |
| mood_hub_grid 잠금 | "잠긴 인용구만 있어요" | "이 무드는 비밀 인용구만 있어요" |
| friend_profile locked | "공개 설정을 켜면 보여요" | "친구가 서재를 공개하면 여기서 볼 수 있어요" |
| friend_search empty | "이름이 정확한지 확인하거나, 친구가 공개 설정을 켰는지" | OK |
| descriptionText | "더 보기/접기" | OK |

**발견 R10-2 — "공유" 액션 시각 일관성** [P1 — 묶음]
같은 *공유* 행동을 5곳에서 표현:
1. quote_list_card 펼침 [📤 바로 공유] — accent400 + 이모지
2. card_editor_screen 하단 [공유] — accent500 + ios_share_rounded
3. quick_share_screen 하단 [다시 공유] — accent500 + ios_share_rounded
4. 저장 직후 SnackBar action [바로 공유] — accent400 텍스트
5. share_sheet 안 4버튼 — 각 플랫폼 색

**제안**: 디자인 토큰에 `AppActions.share` (color, icon) 단일 정의. 5곳 모두 동일.

**발견 R10-3 — *책귀 정서 톤*이 깎이는 6대 지점** [P1 — 묶음]
1. 매번 *N분 전·N주 전*의 차가운 시간 표현
2. *잠긴 인용구만* (R5-3 R10-1)
3. *누군가 보냈어요* (R6-3)
4. *공개되면 볼 수 있어요* (R7-4)
5. *미설정* (R8-1)
6. *카드 만들기에 실패했어요* (이런 *실패*류 카피 다수)

**Hyun-woo 종합**: "*책귀*가 *책 + 귀 기울이다*의 정서를 살리려면 *조용함, 천천히, 한 줄씩 모이는 정서*가 카피에 박혀있어야. *기능 안내 톤*이 너무 자주 나타남."

**발견 R10-4 — 햅틱·마이크로 인터랙션 일관 부재** [P1]
Joon(R1·R4): 카드 에디터의 *템플릿 전환*, 책 *서재 담기*, *팔로우 토글*, *별점*, *무드 칩 선택*, *저장*, *공유* — **모두 햅틱 없음** (코드 grep 확인 가능). Material 3은 햅틱 기본 제공 안 함 — 명시적 `HapticFeedback.lightImpact()` 호출 필요.
**제안**: `core/theme/haptics.dart` 헬퍼 + 7곳 일관 적용 (V1.0 4시간 작업).

**발견 R10-5 — 다국어 *비원어민* 빈상태 카피 한국어 전용** [P2]
약관·개인정보 한국어 전용은 STAGES.md scenario-review S10에서 P2 백로그 명시. *위 6대 정서 톤* 카피도 한국어 전용 — 영어 i18n 시 어려움. V1.5 백로그.

**발견 R10-6 — Predictive Back (Android 14+) 미대응 가능성** [P2]
Park: *"Android 14의 Predictive Back은 *Scaffold에서 자연 동작*하지만, `quote_input_screen`의 `PopScope`(line 606) `canPop: !_hasEdits` + `onPopInvokedWithResult`로 다이얼로그 띄움 — Predictive Back의 *swipe 미리보기 → 취소* 흐름이 *다이얼로그 뜨고 닫히는* 이상한 경험이 될 수 있음."*
**확인 필요**: 실기기 Android 14+에서 검증.

**발견 R10-7 — V1.0 출시 시점 *완성도 인상* 평가** [매니저 종합]
- **기능 완성도**: ★★★★☆ (4.5/5) — 차별화 ①~⑥ 모두 작동. Stage 5 본 작업만 남음.
- **시각 완성도**: ★★★★ (3.8/5) — 디자인 토큰 일관·여백 표준·border-radius 통일 OK. 카피·마이크로 인터랙션·접근성 디테일 약함.
- **정서 일관성**: ★★★ (3.2/5) — *책귀* 브랜드 톤이 *기능 안내 톤*과 섞임 (R10-3).
- **접근성**: ★★★ (3.0/5) — 캘린더 마커 색대비 + 다수 hit area 32dp가 *출시 후 회귀 신호* 가능.

**매니저 권고**: P0 6건만 처리하고 출시, P1 14건을 V1.0.1 hotfix(3~4일 작업)로 묶어 *출시 후 1주 안*에 push. *완성도 인상*이 출시 1주 후 ★★★★☆로 자연 회복.

---

## 3. P0 6건 — 매니저 검증 결과

각 P0는 매니저가 *실제 코드 대조*로 발견 사실 확정.

| # | 발견 | 코드 위치 | 추정 작업 |
|---|---|---|---|
| **P0-1** | quick_share_screen *디자인 편집* 위계 약함 | `quick_share_screen.dart:202-208` (AppBar TextButton) → `_buildBody` 하단 OutlinedButton으로 이동 | 30분 |
| **P0-2** | `_confirmNicknamePattern`의 위험 액션이 FilledButton | `profile_settings_tiles.dart:126-129` → TextButton + semanticError | 5분 |
| **P0-3** | 캘린더 마커 색대비/모양 부족 (적록색맹 검출 불가) | `calendar_segment.dart:184-218` `_Dot` → 모양 차이 추가 (started=empty, finished=filled, both=filled+✓) | 40분 |
| **P0-4** | `_DescriptionText` *더 보기/접기* hit area 32dp | `book_detail_screen.dart:593-595` → minimumSize(0,48) | 5분 |
| **P0-5** | 마스터키 잊으면 영구 복구 불가 — 온보딩 경고 부재 | `lib/features/crypto/presentation/lock_password_screen.dart` (확인 필요) → 첫 진입 경고 + 체크박스 | 1시간 |
| **P0-6** | (검토 추가) `book_detail_screen.dart:154` 우측 column의 `ReadingDatesRow` 폭 부족 위험 — SM F956N 검증 필요 | 실기기 검증 → 부족 시 *행을 헤더 밖으로 분리* | 검증 30분 + 작업 40분 |

**P0 6건 합산 추정**: 3.5시간 (검증 포함 4.5시간). V1.0 출시 코드 작업 전 *오늘 하루* 처리 가능.

---

## 4. P1 14건 — V1.0.1 hotfix 묶음

세부는 §2의 R1~R10 본문 참조. 묶음 단위:

| 묶음 | 포함 | 추정 작업 |
|---|---|---|
| **HF-A 카피 일관성** | R10-1 + R5-3 + R6-3 + R7-4 + R8-1 (6곳 카피 수정) | 1시간 |
| **HF-B 마이크로 인터랙션** | R10-4 (햅틱 7곳) + R4-4 (font scale punch) + R1-3 (CTA 햅틱) | 4시간 |
| **HF-C 접근성 후속** | R9-3·R9-4·R9-6·R9-7 (hit area 4곳 + textScaler clamp 4곳 + switch 색) | 3시간 |
| **HF-D NowReadingRow 빈상태** | R2-2 (빈상태 정서) + R2-4 (refresh invalidate) | 1시간 |
| **HF-E 홈 4단 통합** | R2-1 (`_HomeBanner` 공통 컨테이너) | 2시간 |
| **HF-F 카드 에디터 다듬기** | R4-1·R4-2·R4-3·R4-5 (AutoFit preview·AnimatedSwitcher 120ms·TemplateStrip gradient·PaletteRow swap_horiz) | 3시간 |
| **HF-G 친구 프로필 다듬기** | R7-1 (suspicious nickname 격하) + R7-2 (0 카운트 숨김) + R7-6 (hit area) | 2시간 |
| **HF-H 인용구 입력 다듬기** | R3-1·R3-2·R3-4·R3-5 (BookField 호버·무드 라벨·draft race·PasteBanner 위치) | 3시간 |
| **HF-I 서재 다듬기** | R5-1 (캘린더 FAB 분기) + R5-4 (hub 복귀 단서) + R5-6 (오늘 행동) | 2시간 |
| **HF-J 책 상세 다듬기** | R6-1 (header 레이아웃) + R6-2 (ReadingDates 분리) + R6-5 (CTA 폭) + R6-6 (sheet 닫기 버튼) | 4시간 |
| **HF-K Lock 비밀번호 다듬기** | R8-3 (이미 P0로 격상) + 마스터키 백업 안내 | (P0로 분류) |
| **HF-L 탈퇴 흐름** | R8-5 (탈퇴 직전 Markdown 받기) | 2시간 |
| **HF-M 캐릭터 셋업** | (R1-1 빈 홈에 차별화 1초 단서) | 2시간 |
| **HF-N 잠금 다이얼로그 강화** | R3-3 (체크박스 활성화 패턴) | 1시간 |

**HF 합산 추정**: 30시간 ≈ 4~5일 풀타임. 1인 개발 페이스로 1주 ~ 1.5주.

---

## 5. P2 11건 — V1.5+ 백로그

§2 R1~R10에서 P2로 분류된 항목 + 본 리뷰가 *발견은 했지만 우선순위 낮음*:

1. R1-2 빈홈 텍스트 위계 비대칭
2. R1-4 스플래시 → 로그인 컬러 점프
3. R2-5 RecallCard 위치 비정합 (확인 필요)
4. R3-1 BookField 시각 위계 (V1.0에선 OK)
5. R3-6 시간 표현 인간화
6. R4-2 AnimatedSwitcher 120ms (V1.0 200ms도 OK)
7. R4-3 TemplateStrip gradient (V1.0 OK)
8. R4-5 PaletteRow refresh 아이콘
9. R4-7 _LockedView 컴포넌트 통합
10. R5-2 MoodHubGrid 카드 aspect ratio
11. R6-5 _AddQuoteButton 폭
12. R7-5 친구 검색 최근 본 친구 칩 (D30+ 가치)
13. R9-2 5무드 색맹 검증
14. R9-8 Reduced motion
15. R10-5 다국어 카피
16. R10-6 Predictive Back

---

## 6. 시각 디자인 리팩터링 후보 (출시 후 묶음)

V1.0 시점에 *작동은 하지만* **디자인 시스템 측면에서 *향후 한 번 묶어서 정리하면 좋은*** 항목:

| # | 항목 | 이유 |
|---|---|---|
| **DR-1** | `AppActions` 토큰 도입 (공유·삭제·저장·팔로우 등 *주 액션 단위* 색·아이콘 토큰화) | 5곳 분산된 공유 표현 통합 (R10-2) |
| **DR-2** | `_HomeBanner` 공통 컨테이너 — 홈 4단 통합 컴포넌트 | R2-1 |
| **DR-3** | `Haptics` 헬퍼 — 7곳 일관 적용 | R10-4 |
| **DR-4** | `LockedQuoteView` 단일 컴포넌트 — card_editor·quick_share 양쪽 통합 | R4-7 |

---

## 7. 매니저 종합 권고 (TL;DR)

1. **오늘 — P0 6건 작업** (총 4.5시간). 그 다음 release APK 재빌드 + 폰 검증.
2. **V1.0 출시** — 그대로 진행. 본인 손 작업(마이그레이션 push + OAuth 콘솔 + Play Console 답변)은 이 P0와 *병렬*.
3. **출시 후 1~1.5주** — HF-A~HF-N 14묶음을 V1.0.1 hotfix로 묶음. 차별화 톤이 V1.0.1에서 *완성도 ★★★★★*로 회복.
4. **V1.5+** — P2 11건 + 다국어 + Predictive Back + 시각 디자인 리팩터링 4건 (DR-1~DR-4) 묶음 처리.

---

## 8. 자가 피드백 10회 메타 회고

본 리뷰는 *10명의 가상 페르소나*를 회마다 다른 조합으로 소환했다. 회별 페르소나 매트릭스:

| 회 | 검토 영역 | 페르소나 |
|---|---|---|
| R1 | 첫 진입 | Sarah · Joon · Hye-rin |
| R2 | 홈 피드 | Hye-rin · Tae-hyun · Sarah |
| R3 | 인용구 입력 | Min-jung · Lee Mi-jin · Hyun-woo |
| R4 | 카드 에디터·공유 | Joon · Min-jung · Anna · Sarah |
| R5 | 서재·무드 hub·캘린더 | Sarah · Park Jung-ho · Tae-hyun |
| R6 | 책 상세 | Tae-hyun · Hyun-woo · Sarah |
| R7 | 친구 프로필·검색 | Sarah · Hyun-woo · Tae-hyun |
| R8 | 마이 페이지·약관·탈퇴 | Lee Mi-jin · Anna · Park Jung-ho |
| R9 | 접근성 deep dive | Kim Byeong-su |
| R10 | 종합 | Sarah · Hyun-woo · 매니저 |

**페르소나 등판 횟수**:
- Sarah Lee: 6회 (가장 많음 — 인지부하·일관성 강조)
- Hyun-woo Han: 4회 (정서 카피 도맡음)
- Tae-hyun Yoo: 4회 (D30+ 헤비 관점)
- Joon Kim: 3회 (인터랙션)
- Min-jung Park: 3회 (시각 디테일)
- Hye-rin Choi: 2회 (D1~D7 신규)
- Lee Mi-jin: 2회 (QA·엣지)
- Anna Kim: 2회 (HIG·다른 OS)
- Park Jung-ho: 2회 (Android OS)
- Kim Byeong-su: 1회 (접근성 단독)

**가장 자주 나온 주제**: ①카피 정서 (5회) ②hit area·접근성 (4회) ③시각 일관성 (4회) ④마이크로 인터랙션 (3회) ⑤빈상태 (3회)

**가장 많이 발견된 P0**: 접근성 (3건 — 캘린더 마커·hit area·hit area dup) + 차별화 단절 (1건 — quick_share 디자인 편집) + 정서·UX 안전 (2건 — nickname 위험액션·마스터키 복구).

**개인 평가**:
- 신규 발견 *35건*은 scenario-review-2026-05-17의 *35건과 별개* (이전 라운드에서 본 항목은 의식적으로 *제외* — 신규 코드 PR20·22·23·24 + 사각지대에 집중).
- 발견 중 *코드 위치 명시*는 100%. *추측·일반론*은 0 (모두 read 한 코드 기준).
- *시뮬레이션 인용 quote*는 페르소나 인격을 살리되 *그 페르소나가 *실제로 할 말*이라는 신빙성 추구*. 일부는 디자이너 직군의 흔한 멘트 패턴을 모방.

**한계**:
- *실기기 실사용자 검증 못 함* — R6-2, R9-2 등 *확인 필요* 표시. 사용자가 폰 들고 돌아오시면 즉시 검증 가능.
- *위젯 단위 grep만 한 곳*은 mood_chips, recall_card, outbox_banner, friend_search_cta, share_sheet, lock_password_screen·lock_dialogs·lock_toggle_row, BookCover, StarRating — *발견된 항목은 추정 기반*. 출시 후 hotfix 작업 시 코드 read 보강 필요.

---

## 9. 작업 흐름 — 사용자 복귀 후

1. **본 문서 + §10 deeper 분석 함께 검토** — P0 4건 동의 / 격하 / 추가 표시.
2. **합의된 P0** 코드 fix → release APK 재빌드 + SM F956N 설치 → 매니저 손으로 시나리오 4개 직접 검증.
3. (병렬) 본인 손 작업: 마이그레이션 push, OAuth 콘솔, Play Console 답변 대기.
4. P0 완료 시점에 V1.0 ship 결정. P1 HF-A~N은 V1.0.1로.

---

## 10. P0 deeper 분석 (복귀 직전 진행 — 2026-05-20)

본 섹션은 §3 P0 6건을 *각 fix 코드 안 + side-effect + 회귀 테스트 케이스*까지 분석한 결과다. 코드 read 결과 **P0 2건이 격하**되어 **최종 P0 4건**.

### 10.0 격하 사유 — P0-5, P0-6

#### P0-5 (마스터키 영구 손실 경고) → 이미 처리됨, *체크박스 인터랙션 패턴*만 P1

**격하 근거**:
- `lock_password_screen.dart:175-213` — 화면 하단 *항상 표시되는* 노란 경고 박스. 헤더: *"비밀번호를 종이에 적어두세요"* (semanticWarning + warning_amber icon). 본문: *"비밀번호는 책귀 서버가 모릅니다. 잊으면 잠금 인용구를 영구히 못 봐요."* 미설정 상태부터 노출.
- `lock_dialogs.dart:154-166` `FirstLockDialog` — 첫 진입 시 *"잠금 인용구는 본문이 암호화되어 저장돼요. 비밀번호는 책귀 서버가 모릅니다 — 잊으면 잠금 인용구를 영구히 못 봐요."* + *"※ 종이에 적어두시기를 권해요."* (semanticError 색 + w600).

**결론**: 경고 카피·시각 강도·종이 백업 권고 모두 이미 박혀 있음. 본 리뷰 R8-4 분석에서 놓친 것 (`lock_password_screen.dart`를 read 안 한 채 추측). **사과합니다.**

**남은 약점 (P1로 격하)**: *체크박스 [이해했어요] 활성화* 패턴 미적용. 사용자가 경고 *읽지 않고* 비밀번호 바로 설정 가능. V1.0.1 HF-N로 정리. 단 V1.0에서는 *마찰 추가가 부정적 인상*일 수 있어 신중.

#### P0-6 (ReadingDatesRow 폭 부족) → 격하 → P1

**격하 근거**:
- `reading_dates_row.dart:188-196` — `_DateLine`의 칩 3개가 이미 `Wrap(spacing: 6, runSpacing: 4)` 안에 있음. 즉 폭 부족 시 *자동 2줄 줄바꿈*. 깨지지 않음.
- SM F956N (~360dp 폭) + 표지 96 + gap 16 + padding 좌우 48 = 우측 column 폭 약 200dp. 칩 3개(label 60 + chip 50 + chip 50 + chip 50 + spacing 18 = 228dp)는 200dp에서 *2줄로 자연 줄바꿈*.

**결론**: 코드 결함 아님. 우측 column 세로 길이가 길어 *책 설명 섹션까지 한 화면에 안 들어옴*은 사실 (UX 마찰). V1.0.1 HF-J에 *header 레이아웃 재정렬*로 이미 포함되어있음.

### 10.1 최종 P0 4건 — deeper 분석

#### **P0-1: quick_share *디자인 편집* 위계 강화**

**현재 코드** (`quick_share_screen.dart:191-294`):
```dart
appBar: AppBar(
  title: const Text('이 디자인으로 보낼까요?'),
  leading: IconButton(... 닫기 ...),
  actions: <Widget>[
    if (_data != null)
      TextButton.icon(
        onPressed: _openEditor,
        icon: const Icon(Icons.edit_outlined, size: 16),
        label: const Text('디자인 편집'),
      ),
  ],
),
body: SafeArea(child: _buildBody()),
```
`_buildBody()` 하단 — 다시 공유 FilledButton만 (line 261-291).

**after 코드 안**:
```dart
// AppBar에서 [디자인 편집] TextButton 제거. AppBar = title + leading(닫기)만.
// _buildBody() 하단을 두 버튼 Row로 변경:

Padding(
  padding: const EdgeInsets.fromLTRB(
    AppSpacing.s4, 0, AppSpacing.s4, AppSpacing.s4,
  ),
  child: Row(
    children: <Widget>[
      Expanded(
        flex: 1,
        child: OutlinedButton.icon(
          onPressed: _openEditor,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('디자인 편집'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.accent700,
            side: const BorderSide(color: AppColors.accent300),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.s3),
      Expanded(
        flex: 2,
        child: FilledButton.icon(
          onPressed: _sharing ? null : _share,
          icon: _sharing ? ... 기존 spinner ... : const Icon(Icons.ios_share_rounded, size: 18),
          label: const Text('다시 공유'),
          style: FilledButton.styleFrom(... 기존 ...),
        ),
      ),
    ],
  ),
),
```

**Side-effect**:
- AppBar가 깨끗해짐 — leading 닫기 + title만.
- `_LockedView` 분기(line 235)는 자체 화면이라 이 두 버튼 미노출 (자동 처리).
- `_NotFoundView`·`_ErrorView`도 마찬가지 (data null 분기).
- 두 버튼 비율 1:2 — [다시 공유]가 더 강조되어 *공유가 주 액션, 편집이 보조*임을 시각 위계로 명시.

**회귀 테스트 케이스** (`test/features/card_editor/quick_share_screen_test.dart` 신규/추가):
1. data 정상 + 첫 진입 → 하단 Row에 [디자인 편집] OutlinedButton + [다시 공유] FilledButton 둘 다 노출.
2. AppBar actions가 비어있는지 (TextButton "디자인 편집" 부재).
3. `_LockedView` 상태 → 두 버튼 모두 부재 (`_LockedView`의 [잠금 해제] 버튼만 노출).
4. _sharing=true → [다시 공유] disabled + spinner, [디자인 편집]은 enabled 유지.
5. [디자인 편집] 탭 → `context.push('/quote/$id/card')` 호출 (mock GoRouter로 검증).

**추정 작업**: 코드 30분 + 테스트 20분 = 50분.

---

#### **P0-2: 위험 액션 버튼 위계 반전**

**현재 코드** (`profile_settings_tiles.dart:120-130`):
```dart
actions: [
  TextButton(
    onPressed: () => Navigator.of(ctx).pop(false),
    child: const Text('취소'),
  ),
  FilledButton(
    onPressed: () => Navigator.of(ctx).pop(true),
    child: const Text('그대로 공개'),
  ),
],
```

**after 코드 안**:
```dart
actions: [
  // 위험 액션은 TextButton + semanticError로 약화
  TextButton(
    onPressed: () => Navigator.of(ctx).pop(true),
    style: TextButton.styleFrom(foregroundColor: AppColors.semanticError),
    child: const Text('그대로 공개'),
  ),
  // 안전 액션을 FilledButton으로 강조 (반사 클릭이 안전 쪽으로)
  FilledButton(
    onPressed: () => Navigator.of(ctx).pop(false),
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.accent500,
      foregroundColor: AppColors.secondary50,
    ),
    child: const Text('취소'),
  ),
],
```

**Side-effect**:
- Material 가이드: *destructive action은 약하게, safe default는 강하게* — Google iOS·Android 모두 패턴. 본 다이얼로그는 *공개 토글 ON*이 본인 동의 필요 사항이라 이 패턴이 맞다.
- 다이얼로그 좌우 순서: TextButton(그대로 공개) → FilledButton(취소). Material 권장 = *positive primary는 오른쪽*. *취소가 positive primary*가 되므로 OK.
- 기존 사용자가 *오른쪽 버튼이 진행 액션*이라 학습되어있다면 *반사 클릭이 취소* → 다이얼로그 닫힘. *닉네임 변경 안내*가 한 번 더 노출되는 효과.

**회귀 테스트** (`test/features/profile/profile_settings_tiles_test.dart`):
1. 닉네임이 `.` 포함된 사용자가 ON 토글 → 다이얼로그 노출.
2. 다이얼로그 actions[0] = TextButton (위험), actions[1] = FilledButton (안전).
3. *FilledButton 탭* → 다이얼로그 pop(false) → 토글 OFF 유지 + `_busy=false`.
4. *TextButton 탭* → 다이얼로그 pop(true) → updateMine 호출 검증.

**추정 작업**: 코드 5분 + 테스트 15분 = 20분.

---

#### **P0-3: 캘린더 마커 모양 차이 (적록색맹 인지)**

**현재 코드** (`calendar_segment.dart:184-218`):
```dart
class _Dot extends StatelessWidget {
  const _Dot({required this.kind});
  final ReadingMarkKind kind;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      ReadingMarkKind.started => Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent200),
          ),
        ),
      ReadingMarkKind.finished => Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent500,
          ),
        ),
      ReadingMarkKind.both => Container(
          width: 7, height: 7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent500,
            border: Border.all(color: AppColors.accent700, width: 1),
          ),
        ),
    };
  }
}
```

**시안 3개**:

**시안 A (최소 변경, 권고)**:
- started = 빈 원 (outline only) — 그대로
- finished = 채워진 원 — 그대로
- both = 채워진 원 + 안에 작은 ✓ (text or icon, secondary50 색, 5pt)

*장점*: 브랜드 색·모양 거의 유지. *모양 자체로 차이* 추가 (both = ✓ inside).
*단점*: 6×6dp 안에 ✓ 그리기는 *어렵고 인지하기 작음*. 7×7로 커지면 행 폭 ↑.

**시안 B (적당히 명확)**:
- started = 빈 원 (outline)
- finished = 채워진 *반원 ◐* (반은 채워짐)
- both = 채워진 *원 + 위에 빛*(살짝 더 큰 원에 inner shadow)

*장점*: 모양 자체가 시간 진행을 *시각 메타포*로 (started = 시작 점선/오픈, finished = 완결).
*단점*: 시각 복잡성 ↑. 6×6dp에서 반원 인지 어려움.

**시안 C (글자 라벨, 권고 X)**:
- started = '▢', finished = '■', both = '▣'

*장점*: 모양 차이 가장 명확.
*단점*: 폰트 의존. 셀 안에서 시각이 *읽는 텍스트*가 되어 *마커가 책 아이콘*인 정서 깨짐.

**권고**: **시안 A**. ✓ 대신 더 단순한 *흰 점 (inner dot)*도 후보 — `Center(child: Container(width:3, height:3, color: secondary50))`. ✓보다 시각 가벼움.

**최종 after 코드 안** (시안 A 변형 — *finished에 inner white dot*):
```dart
ReadingMarkKind.started => Container(
    width: 7, height: 7,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.accent400, width: 1.2),  // outline 더 진하게
    ),
  ),
ReadingMarkKind.finished => Container(
    width: 7, height: 7,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.accent500,
    ),
  ),
ReadingMarkKind.both => Container(
    width: 7, height: 7,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.accent500,
    ),
    child: Center(
      child: Container(
        width: 3, height: 3,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.secondary50,  // 흰 점 inside
        ),
      ),
    ),
  ),
```

**Side-effect**:
- 마커 크기 6→7로 일관 (이전엔 both만 7). 마커 3개 줄에 폭 ~30dp (기존 ~26dp). 작은 변화.
- accent200 → accent400 outline 강화 (started의 시각 명도 ↑).

**회귀 테스트** (`test/features/library/calendar_segment_test.dart` 신규):
1. ReadingMarkKind.started 마커 → outline만 (color 없음, border 있음).
2. ReadingMarkKind.finished 마커 → fill 있음, child 없음.
3. ReadingMarkKind.both → fill 있음 + Center 안 작은 흰 Container 자식 있음.
4. 골든 테스트 (`golden_calendar_markers_test`): 3 kind 마커 각각 row 렌더 후 골든 비교.

**추가 검증**: 적록색맹 시뮬 (Sim Daltonism 또는 Chrome DevTools rendering 패널)에서 3 kind가 *모양*만으로 구분되는지 본인 손 검증.

**추정 작업**: 코드 15분 + 테스트 25분 = 40분 + 본인 검증 10분.

---

#### **P0-4: 더 보기/접기 hit area 48dp**

**현재 코드** (`book_detail_screen.dart:591-601`):
```dart
TextButton(
  style: TextButton.styleFrom(
    padding: EdgeInsets.zero,
    minimumSize: const Size(0, 32),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    foregroundColor: AppColors.accent600,
  ),
  onPressed: () => setState(() => _expanded = !_expanded),
  child: Text(_expanded ? '접기' : '더 보기'),
),
```

**after 코드 안**:
```dart
TextButton(
  style: TextButton.styleFrom(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s2,
      vertical: AppSpacing.s2,
    ),
    minimumSize: const Size(0, 48),  // WCAG 권장
    tapTargetSize: MaterialTapTargetSize.padded,  // 기본값
    foregroundColor: AppColors.accent600,
  ),
  onPressed: () => setState(() => _expanded = !_expanded),
  child: Text(_expanded ? '접기' : '더 보기'),
),
```

**Side-effect**:
- 버튼 시각 영역 자체는 padding s2(=8dp)씩 추가되어 *약간 더 보임*. 라벨 *더 보기*는 그대로.
- 책 설명 아래 *세로 16dp 정도 빈 공간 ↑*. 책 상세 전체 길이 미세 증가.
- Material의 일반 TextButton 패턴 회복 — *비표준 압축 패턴이 사라짐*은 일관성 ↑.

**회귀 테스트**:
1. 책 설명이 6줄 초과 시 [더 보기] 노출.
2. tester.tap이 button의 36~48dp 영역에서 동작.
3. 탭 → _expanded toggle → 텍스트 [접기]로 변경.

**추정 작업**: 코드 5분 + 테스트 10분 = 15분.

---

### 10.2 P0 총합 — 작업량 재산정

| # | 항목 | 추정 작업 |
|---|---|---|
| P0-1 | quick_share 디자인 편집 위계 | 50분 |
| P0-2 | 위험액션 버튼 반전 | 20분 |
| P0-3 | 캘린더 마커 모양 | 50분 (검증 포함) |
| P0-4 | 더 보기 hit area | 15분 |
| **합계** | | **약 2시간 15분** |

§3 *4.5시간 추정*에서 *2시간 15분*으로 줄었다. P0-5·P0-6 격하 + 다른 P0들이 *생각보다 작은 변경*이라 검증 가능.

### 10.3 회귀 가드 추가 파일 목록

본 P0 작업 시 신규/추가될 테스트 파일:

| 파일 | 신규/추가 | 테스트 수 |
|---|---|---|
| `test/features/card_editor/quick_share_screen_test.dart` | 신규 | 5건 |
| `test/features/profile/profile_settings_tiles_test.dart` | 신규/추가 | 4건 |
| `test/features/library/calendar_segment_test.dart` | 신규 | 4건 + 골든 3장 |
| `test/features/book/book_detail_screen_test.dart` | 추가 | 1건 |
| **합계 신규 테스트** | | **14건 + 골든 3장** |

테스트 합산 후 *총 268건* (현재 254 + 14). 작업 후 `flutter test` 268/268 + analyze clean + release APK 검증 표준 절차.

### 10.4 작업 순서 권고

1. **P0-4** (15분) — 가장 단순. minimumSize 한 줄.
2. **P0-2** (20분) — 다이얼로그 actions 순서·스타일.
3. **P0-1** (50분) — quick_share 하단 Row 구성.
4. **P0-3** (50분 + 검증) — 캘린더 마커. 골든 테스트 필요 시 `--update-goldens` 한 번.
5. `flutter analyze` + `flutter test` + release APK 빌드 + SM F926N 설치.
6. 본인 검증 시나리오 4건:
   - 책 상세 설명에서 [더 보기] 탭이 정상 작동
   - 프로필 공개 토글 ON + `.` 포함 닉네임 → 다이얼로그 좌측 위험 액션 + 우측 safe
   - quick_share 자동 시트 닫은 후 하단 [디자인 편집] + [다시 공유] 둘 다 노출
   - 캘린더에서 책 시작/완독/같은날 마커 모양 차이 인지

### 10.5 미진단 항목 (복귀 시 확인 권고)

본 P0 deeper 작업 진행 후에도 다음은 본 세션에서 결정 불가:

1. **P0-3 시안 A 변형 (흰 점)이 실제 셀 안에서 인지 가능한지** — SM F956N 실기기 + 적록색맹 시뮬레이션 도구로 본인 손 검증. 인지 어려우면 시안 B로 전환.
2. **P0-1 두 버튼 비율 1:2**가 미적·기능적으로 옳은지 — 실기기 디자인 일관성 평가. *2:3 또는 1:1*도 후보.
3. **R2-1 홈 4단 통합** (P1 HF-E) 진행 여부 — V1.0 시점에 *시각 결함*인지 *향후 개선*인지 판단.

---

*— Claude (매니저 모드), 2026-05-20 — §10 deeper 분석 추가*
