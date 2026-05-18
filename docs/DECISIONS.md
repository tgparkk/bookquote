# 결정 대장 (Decision Log)

이 프로젝트의 주요 결정사항을 **날짜 역순**으로 기록한다. 한 결정당 한 섹션, 핵심만.
새 결정은 맨 위에 추가한다. 결정을 뒤집을 때는 기존 항목을 수정하지 말고 새 항목으로 추가하면서 어떤 항목을 대체하는지 명시한다.

---

## 2026-05-18 — 친구 서재 탐험 P0/P1 흡수 (검색 funnel 사수 + 본명·잠금 누수 0% 게이트 + 일정 5~6주 양보)

- **결정**: 2026-05-17 PR18 결정의 핵심 모델(단방향 follow·프로필 토글·hard exclude·BottomNav 4탭·홈 미섞기)은 *유지*하되, 매니저 모드 4명(critic·planner·designer·qa-tester) 병렬 검토로 발견된 P0 3건 + P1 4건을 PR18 분할 *내부*로 흡수. deep link sender(PR18-D)는 critic 손으로 **유지**(친구 발견 funnel의 두 다리 사수). 한 달 패키지 약속은 5~6주로 양보(planner의 critical path 추정 받아들임).
- **이유**: 4명 중 2명 이상 *독립 발견*한 약점 3건은 출시 후 신뢰 파괴 1순위 — ① 닉네임 회피 ↔ `display_name ilike` 검색의 silent killer(critic + qa-tester): 본명 회피를 유도하면 닉네임이 의미없는 문자열로 수렴 → 검색 무력화 → 친구 발견 funnel이 deep link 단일 경로로 축소 → 단방향 follow의 "모르는 사람 발견" 가치 0 ② PR18-B 닉네임 prerequisite가 *강제 게이트* 아님(planner + qa-tester): PR18-C가 PR18-B 없이 머지되면 본명 노출 사고가 곧 신호 ③ 친구 진입점 전무 + 선행 신호 부재(planner + qa-tester): 현재 `me_screen` "친구 찾기"는 V1엔 숨김. PR18-B에서 활성화하지만 그동안 진입점 0. 재검토 트리거가 모두 *사후* 신호. 출시 전 가족 5명 단계에서 잡을 선행 지표 부재.
- **P0 (출시 전 반드시 조치)**:
  - `profiles` SELECT RLS를 `using(true)` → `using(is_library_public = true OR id = auth.uid())`로 좁힘. 비공개 프로필이 검색·`/u/:userId`에 0 row로 응답. 본명 노출 원천 차단.
  - `follow_repository.searchByDisplayName` 쿼리에 클라이언트 단 `.eq('is_library_public', true)` 명시 필터 추가 — defense in depth(DB+클라 이중 방어).
  - **PR18-B → PR18-C 강제 게이트** 신설: 닉네임 미설정(또는 email local-part 의심 패턴) 사용자가 `/u/:userId` 또는 "내 프로필 공개" 토글 접근 시 풀스크린 "닉네임 먼저 설정해주세요" gate. PR18-C 본 화면 진입 봉쇄.
  - 닉네임 패턴 자동 감지 — `display_name`이 email local-part 의심 패턴(`.`·`_`·`@` 앞 형식)이면 공개 토글 활성화 직전 강제 다이얼로그 + 추천 닉네임 제안. 다이얼로그 OK 연타 회피 위해 *닉네임 입력 확인 후*에만 활성화.
- **P1 (강력 권고, 흡수)**:
  - `profiles.public_handle text unique` 컬럼을 PR18-A 마이그레이션에 *미리 박기* — V1.0엔 미사용, V1.0.1에 "@핸들 검색" 경로로 활성화. 스키마 마이그레이션 비용 0 추가, 데이터 backfill만으로 hotfix 가능. critic의 닉네임-검색 충돌 funnel 회피 두 번째 다리. unique constraint는 처음부터 박아 향후 핸들 점거 사고 0.
  - Me Switch 옆 현재 노출 상태 카피 — "현재 비공개 — 검색에 표시 안 됨" / "현재 공개 — 닉네임 `<display_name>`로 검색됨". 사용자가 자기 노출 상태를 *언제든* 인지.
  - 홈 빈 상태 CTA에 "친구 찾기 →" 1줄 — 조건부(인용구 ≥1개 + 친구 0명). 신규 가입자 친구 진입점 마찰 해소. 인용구 0개일 때는 기존 인용구 CTA가 우선(qa-tester).
  - 친구 프로필 비공개 빈상태에 `FollowState` enum 분기 카피(팔로우 전 vs 팔로잉 다른 문구) — designer 손. 인지 부조화("내 팔로우가 먹혔나?") 회피. 본문 카피가 상태 설명하므로 SnackBar는 단순 확인만.
- **P2 (지표·테스트)**:
  - PR18-A 직후 PostHog 선행 이벤트 3종 등재: `friend_search_zero_result_exit`(검색 0건 후 종료), `library_public_toggle_unchanged`(Me 진입 후 토글 미변경 종료), `book_detail_friend_count_zero`("친구 N명" 0 노출 빈도). 가족 5명 가입 단계에서 임계 ≥40%면 *출시 전* 재검토 — 사후 클레임이 아닌 선행 신호.
  - PR18-E 침투 테스트에 X-feature 매트릭스 추가 — 잠금×친구×캘린더 3축 (8조합 중 4 골든). 친구의 잠금 인용구가 캘린더 마커에 안 뜨는지 / 비공개 프로필 사용자의 캘린더 통계가 친구 화면에 노출 안 되는지 등.
  - 본인 진입 redirect를 라우터 `_redirect` 단계로 끌어올림(현 명세는 initState) — 1프레임 흰 화면 깜박임 회피 + RLS 회귀 가드.
- **갱신된 PR 분할**:
  - **18-A** 마이그레이션 + 도메인 + `follow_repository` 코어 — 기존(`follows` + `profiles.is_library_public` + RLS 3종) + **`profiles.public_handle text unique` 컬럼 추가** + **`profiles` SELECT RLS 좁힘**(`is_library_public = true OR id = auth.uid()`).
  - **18-B** 검색·카운트 + Me 토글·닉네임 편집 — 기존 + **닉네임 패턴 감지 다이얼로그** + **Switch 상태 카피** + **`searchByDisplayName` 클라 필터** + **홈 빈 상태 CTA 친구 링크**(조건부) + **PostHog 선행 이벤트 3종 등재**.
  - **18-B/C 게이트** (신설 sub-PR): 닉네임 미설정/의심 패턴 사용자 → `/u/:userId` 풀스크린 gate. PR18-B 머지 후, PR18-C 진입 전 별도 sub-PR.
  - **18-C** `/u/:userId` 친구 프로필 화면 — 기존 + **`FollowState` enum 분기 카피** + **본인 진입 라우터 `_redirect` 가드**.
  - **18-D** 책 상세 친구 N명 + deep link sender — *유지*(critic 손, 친구 발견 funnel의 두 번째 다리).
  - **18-E** 골든 + RLS 침투 + release APK — 기존 + **X-feature 매트릭스**(잠금×친구×캘린더 3축, 8조합 중 4 골든) + **PostHog 선행 이벤트 발동 검증**.
- **의존 순서**: PR16-C-2(잠금 password 화면) → PR16-D/E → PR18-A. E2EE 트랙을 *완전히* 닫고 PR18 진입. 병렬 X(planner — 회귀 베이스 흔들림 회피).
- **일정 양보**: 한 달 → 5~6주(2026-06-08 ~ 06-22 → 06-22 ~ 06-29 범위). 사용자 모토 "서두르지 않고 고득하게"와 정합. 추가 1~2주는 P0 게이트 강화(+0.5주) + X-feature 매트릭스(+0.5주) + 일정 여유(+0.5~1주).
- **재검토 트리거 (선행 신호 신설)**:
  - 가족·지인 5명 가입 단계에서 `friend_search_zero_result_exit ≥ 40%` → PR18-A에 박아둔 `public_handle` 검색 활성화를 V1.0.1 → V1.0으로 격상.
  - `library_public_toggle_unchanged ≥ 60%` → 토글 UX 재설계(설명 보강 또는 기본값 변경 검토).
  - `book_detail_friend_count_zero ≥ 80%` → 친구 N명 표시 UX 재검토(다른 retention 후크 탐색).
- **대체**: 2026-05-17 "친구 서재 탐험 V1.0 합류" 결정의 PR 분할·일정·재검토 트리거 부분을 갱신. 핵심 모델(단방향 follow·프로필 토글·hard exclude·BottomNav 4탭·홈 미섞기)은 유지.

---

## 2026-05-17 — 친구 서재 탐험 V1.0 합류 (단방향 follow + 프로필 토글 + 잠금 자동 제외)

- **결정**: 친구 follow/타임라인을 V1.5+로 미뤘던 2026-05-12 결정을 부분 뒤집어 V1.0 패키지에 합류. 단 **풀-소셜 X**: ① 모델 = 단방향 follow(트위터식, request-accept 없음) ② 공개 정책 = 프로필 단위 토글 `profiles.is_library_public bool default false`(per-quote `is_public` X) ③ 잠금 인용구(`quotes.is_private = true`, PR16)는 RLS에서 **hard exclude** — 친구 화면에 절대 노출 0% 보장 ④ 친구 발견 = `display_name` 검색 + 카드 공유 deep link → 보낸 사람 서재 두 경로만, 카톡 매칭 X ⑤ 화면 신설 1개(`/u/:userId` 친구 프로필 read-only) + 기존 화면 갱신 2건(Me "친구 찾기" 활성화 + 책 상세 "이 책을 담은 친구 N명" 1줄). BottomNav 슬롯 추가 X, 홈 피드에 친구 인용구 섞기 X — "내 인용 피드" 정체성 사수.
- **이유**: V1.0 차별화 5가지가 모두 "나" 중심이라 카드 공유는 외부 SNS 의존 → retention 약점. Letterboxd·StoryGraph가 입증한 "이 책을 담은 친구 N명" 한 줄이 retention 후크로 가장 가벼움. 카드 공유 deep link(`?from=share`)는 이미 인프라(PR10·deep_link_handler)가 있어 sender_user_id만 payload에 추가하면 "보낸 사람 서재 보기" 동선 자연. 풀-소셜은 정체성 흔들 위험(2026-05-12 보류 이유) → 단방향 + 부속 진입점 3개로 무게 최소화. PR16(E2EE)의 `is_private` 정책이 친구 탐험의 "공개 vs 비공개" 정책과 자연 호응 — 둘이 같은 한 달 패키지에 들어가는 게 결합 비용 낮음(친구 노출 게이트를 RLS에 한 번만 박음).
- **알고리즘·모델 선택**:
  - **공개 정책 = 프로필 단위 토글** (vs per-quote `is_public`) — UI 부담 1번(Me에서 토글), PR16 잠금 토글과 혼동 0(잠금 = "나만 보기"·공개 = "공개 프로필이 ON일 때 친구가 보기"). per-quote는 V1.5 검토 슬롯.
  - **follow = 단방향** (vs request-accept) — V1 가벼움. `follows(follower_id, followee_id, created_at, PK(follower_id, followee_id))` 1테이블. `follows_followee_idx` 역방향. 차단(`blocks`)·뮤트는 V1.5.
  - **잠금 hard exclude** — 친구가 read하는 모든 quotes 쿼리에 RLS `using` 조건 `is_private = false`. 정책 단위로 강제 = 클라이언트 버그가 있어도 DB가 막음. PR18-E에 RLS 침투 테스트로 회귀 가드.
  - **friend_quotes RLS 정책 신규** = `(auth.uid() in (select follower_id from follows where followee_id = quotes.user_id) and exists profile where id = quotes.user_id and is_library_public = true and quotes.is_private = false)`. SELECT 정책 OR로 추가(기존 본인 정책 유지).
  - **카드 deep link sender** = `cards` 테이블에 `shared_at` 외 별도 컬럼 추가 X. 공유 시 deep link URL에 `&sender=<user_id>` 직접 인코딩(`share_service.dart`). 받는 쪽 `deep_link_handler`가 query 파싱 → `/book/:id?from=share&sender=<uid>` → book_detail의 sender 컨텍스트 배너에 [이 사람 서재 보기] 버튼.
  - **닉네임 노출 사고 방지** — `display_name`이 가입 시 이메일 local-part 자동 채워짐(현 `handle_new_user_oauth`). 본명 노출 위험. **PR18 prerequisite = Me에 "공개 닉네임 편집" UI** 필수(기본값=현재 display_name 표시 + "공개될 이름이에요" 안내). `is_library_public=true` 토글하기 전 닉네임 확인 다이얼로그 강제.
- **대안 검토**:
  - (a) per-quote `is_public bool` 토글 → 거부. 입력 화면에 토글 1개 더, PR16 잠금 토글과 혼동, "공개 1개 / 비공개 99개"의 흔한 패턴이 사실 프로필 단위 토글로 충분.
  - (b) follow request-accept 양방향 → 거부. V1 무거움. `follow_requests` 테이블 + 거절/대기 UI까지 따라옴. V2 슬롯.
  - (c) 카톡 친구 매칭 → 거부. 카카오 SDK가 카카오 로그인 의존 → 카카오 로그인 V1.5로 미뤄둔 상태(2026-05-10). 매직링크 only V1.0과 부정합. V1.5에 카카오 로그인과 묶음.
  - (d) 친구 인용구를 홈 피드에 시간순 섞기 → 거부. "내 인용 피드"가 인스타화. 정체성 사수. 친구 인용구는 친구 프로필에 들어가서만 봄(별도 진입점).
  - (e) BottomNav 5탭화([친구] 슬롯) → 거부. DECISIONS 2026-05-10 "4탭 위계"·"빈 탭 cold-start 함정" 직접 위반. 신규 가입자 친구 0명에서 [친구] 탭 = 빈 탭.
  - (f) follows 테이블 없이 누구나 공개 프로필 read → 거부. 친구 컨텍스트가 없으면 "이 책을 담은 친구 N명" 자체가 무의미(전 사용자 카운트는 retention 후크 X). 카드 deep link sender도 "내가 팔로우한 사람"이어야 [팔로우 중] 칩 표시 가능.
  - (g) Edge Function `friend-explore`로 RLS 우회 + 서버 단위 권한 체크 → 거부. RLS가 정통이고 단위 테스트 가능. Edge는 service_role 필요한 경우만.
- **영향**:
  - 마이그레이션 1장: `20260518xxxxxx_follows_and_public_profile.sql` — `follows` 테이블(PK `(follower_id, followee_id)`, 둘 다 cascade) + `profiles.is_library_public bool not null default false` 컬럼 + `follows_followee_idx (followee_id)` + 새 RLS 정책 `quotes_friends_read`/`user_books_friends_read`(둘 다 `is_library_public=true` + `quotes.is_private=false` 게이트) + `profiles` RLS 변경(공개 프로필만 누구나 read, 비공개는 본인만 — 현행 `using(true)` 좁힘).
  - `pubspec.yaml` 변경 없음(순수 Flutter + supabase_flutter).
  - `lib/features/follow/` 신규 모듈 — `domain/follow.dart` + `data/follow_repository.dart`(`searchByDisplayName` `ilike` + `follow/unfollow/isFollowing/listFollowing/listFollowers/followersCountForBook`) + `state/follow_providers.dart`.
  - `lib/features/profile/friend_profile_screen.dart` 신규 (`/u/:userId`) — 공개 책 리스트 + 공개 인용구 무한스크롤(잠금 자동 제외) + [팔로우/언팔로우] 버튼. 비공개 프로필 시 "잠긴 서재" 빈상태.
  - `me_screen` "친구 찾기" 활성화(현행 숨김 → ListTile 1줄) + 신규 섹션 "내 프로필 공개"(토글 + 닉네임 편집 다이얼로그).
  - `book_detail_screen` 헤더 메타 다음 "이 책을 담은 친구 N명" 1줄(N≥1일 때만 렌더, 0이면 숨김 — 빈 상태 회피) + 탭 시 시트로 친구 미니리스트.
  - `share_service.dart` deep link URL에 `&sender=<user_id>` 추가 + `deep_link_handler` 파싱.
  - `book_detail_screen`의 deep link 진입 배너에 sender가 팔로우 중이면 [이 사람 서재 ▸], 아니면 [팔로우 + 서재 보기] 1탭.
  - `router.dart`에 `GoRoute(path: '/u/:userId')` 추가. 로그인 가드(deep link도 로그인 필수 — 친구 컨텍스트라).
  - `delete-account` Edge Function 흐름 변경 없음(`auth.users` cascade가 `follows`도 자동 정리 — 양방향 FK 둘 다 cascade).
  - PR16(E2EE)·PR17(캘린더)·PR18(친구 탐험) **3 PR이 같은 한 달 패키지**. 결합점 = `quotes`의 `is_private` 컬럼(PR16 추가 → PR18 RLS에서 게이트로 사용). PR16-A 마이그레이션이 PR18-A에 선행. PR18은 PR16-B(quotes 읽기 측 wiring) 닫힌 다음.
- **재검토 트리거**:
  - 베타 사용자 ≥2명이 "친구 1명도 못 찾았다" 호소 → PR19로 카톡 친구 매칭(카카오 로그인 V1.5와 묶음) 우선순위 ↑.
  - "친구 인용구를 홈에서 보고 싶다" 강한 호소 → 별도 [친구] 탭 X, 대신 홈 상단 "이번 주 친구들이 모은 인용구 N개" 1줄 카드 추가 검토(정체성 영향 최소화).
  - 잠금 인용구 노출 사고 0건이지만 친구 화면에서 책 상세로 갔을 때 "내 잠금 인용구"가 "이 책에서 모은 N구절"에 포함돼 카운트 누수 → `is_private=true` 카운트도 제외하는지 PR18-E 침투 테스트 필수.
  - 닉네임이 이메일 local-part로 노출되는 사고 ≥1건 → 가입 흐름에 "공개 닉네임 입력" 강제 단계 추가(V1.0.1 hotfix).
  - "공개 프로필 토글 OFF인데 책 상세 '담은 친구 N명'에 내 닉네임 노출" 사고 → 카운트·미니리스트 둘 다 `is_library_public=true` 게이트 통과한 사용자만 집계.
- **PR 분할**: **18-A** 마이그레이션 1장(`follows` + `profiles.is_library_public` + RLS 정책 3종) + `follow.dart` 도메인 + `follow_repository` 코어(`follow/unfollow/isFollowing`만) · **18-B** `follow_repository` 검색·카운트(`searchByDisplayName` `ilike` + `followersCountForBook` + `listFollowing/listFollowers`) + Me 신규 섹션 "내 프로필 공개" 토글 + "공개 닉네임" 편집 다이얼로그(prerequisite — `is_library_public=true` 가기 전 강제 확인) · **18-C** `/u/:userId` 친구 프로필 화면(공개 책 + 공개 인용구, 잠금 hard exclude, [팔로우/언팔로우] 버튼) + 라우터 추가 · **18-D** 책 상세 "이 책을 담은 친구 N명" 1줄 + 친구 미니리스트 시트 + `share_service.dart` deep link sender 추가 + `deep_link_handler` sender 파싱 + book_detail sender 배너에 [이 사람 서재 ▸] 1탭 · **18-E** 골든(친구 프로필 비공개·공개 두 상태) + RLS 침투 테스트(잠금 quote 0 row · 비공개 프로필 0 row · 팔로우 안 한 사용자 0 row) + release APK 검증. 각 PR 끝 `flutter analyze` + `flutter test` + release APK 빌드 sanity(`feedback_release_only_traps` 강제).

---

## 2026-05-17 — 독서 시작·완독일 캘린더 + 마찰 감소 UX 3건 (V1.0 포함)

- **결정**: V1.0에 ① `user_books`에 `started_at date`/`finished_at date` 컬럼 추가(CHECK `finished_at >= started_at`, 둘 다 null 허용 — 시작만 입력하고 아직 안 다 읽은 케이스가 핵심) ② 책 상세에 별점 행 아래 "읽기 시작 / 다 읽음" 1탭 입력 영역(오늘/어제/직접선택 칩, 입력 후 칩 형태 표시 + 재탭=지우기) ③ 서재 탭을 [책]·[인용구]·[캘린더] 3 세그먼트로 확장 — 캘린더 셀 마커는 시작(`accent200` outline)·완독(`accent500` 채움) 두 색 분리, 셀 탭=그 날 책 리스트. 동시에 글로벌 검증된 마찰 감소 UX 3건 채택 — (a) 날짜 기본값=오늘, DatePicker 숨김(Letterboxd·StoryGraph — 왓챠피디아 *평가일=감상일* 실패 지점 직격) (b) 별점 재탭=해제 패턴을 캘린더 칩에도 일관 적용(이미 `StarRating`에 구현됨) (c) 표지 long-press → 액션시트(V1.0.1 후속 PR로 분리).
- **이유**: 왓챠피디아 도서 기능 조사 결과 — "이 책 좋았다" 정량 트래커는 강함(컬렉션·캘린더·월말결산)이지만 "*이 한 줄이 좋았다*"(인용구 1급)는 빈자리. brunch 사용자 회고가 "ISBN을 검색해 넣거나 상세한 인용을 달기엔" 부적합 명시. 캘린더 자체는 retention 후크로 검증됐고 우리 차별화(인용구·표지색 카드·1탭 공유)와 충돌 0. 단 왓챠피디아가 *평가일=감상일* 강제로 묶어 실패한 지점은 우리 설계에서 별점 ≠ 날짜 두 행 분리로 직격(Letterboxd·StoryGraph가 같은 답).
- **알고리즘 선택**:
  - 시작/완독 자동 전이 — "다 읽음" 탭 시 `started_at` 없으면 둘 다 today로 set + Toast "함께 시작일도 오늘로 저장했어요"(StoryGraph 자동 기입 패턴, *과거에 읽었던 책* 등록 마찰 0).
  - 캘린더 위젯 — `table_calendar ^3.x`(Flutter ecosystem 표준, 자체 구현 대비 -2~3일).
  - 셀 마커 — 단일 점이 아닌 두 색 분리. 한 날 ≥4권은 점 3개+"···". 색만으로 의미 전달 X — 셀 탭하면 그 날 책 리스트 펼침(접근성).
  - 기존 `reading_status` 컬럼(`reading`/`finished`/`wishlist`, 기본값 `reading`) — 시작만 입력=`reading` 유지, 완독 입력=`finished` 자동 갱신. UI에 한 번도 안 쓰이고 있던 컬럼을 캘린더와 묶어 활성화.
- **대안 검토**:
  - (a) 인용구 저장일 캘린더(`quotes.created_at` 활용, 즉시 가능) → 거부. *우리 본진을 또 다른 단면으로 보여줄 뿐* 차별화 없음.
  - (b) 새 탭(5탭화) → 거부. DECISIONS 2026-05-10 "4탭 위계"·"빈 탭 cold-start" 원칙 충돌.
  - (c) 홈 상단 캘린더 카드 → 거부. PR15-B "이번 주 회고" 카드와 영역 경쟁.
  - (d) 진행률 페이지/% 입력(북적북적) → 거부. 정체성 흐림(독서 진도 추적 ≠ 본진).
  - (e) 캘린더 셀에 표지 썸네일(Letterboxd 다이어리) → 거부. 1080픽셀 카드가 본진, 캘린더 셀은 dot 마커로 충분.
- **영향**:
  - 마이그레이션 1장: `20260518xxxxxx_user_books_reading_dates.sql` — `started_at`/`finished_at` date 컬럼 + CHECK + partial index 2개 (`(user_id, finished_at desc) where finished_at is not null`·동 started_at).
  - `pubspec.yaml`: `table_calendar ^3.x` 추가. release APK 검증 필수(`feedback_release_only_traps` 강제).
  - `book_repository`에 `setReadingDate({bookId, kind: started|finished, date?})` — `setMyRating`의 upsert + auto-add-to-library 패턴 재사용. date=null이면 그 컬럼만 unset.
  - `library_screen` 세그먼트 2→3개. `library.md`의 V1.5 보강 권고였던 [인용구] 세그먼트도 PR17과 묶어 V1.0으로 끌어올림(서재 화면 두 번 건드림 회피).
  - `book_detail_screen` — 별점 행 아래 신규 위젯 `_ReadingDatesRow`.
  - PR16(E2EE)·PR17(캘린더)이 같은 한 달 패키지. `user_books` 컬럼 추가만이라 스키마 충돌 0. 책 상세 헤더가 별점+읽기 날짜+E2EE 잠금 토글로 합류 — 디자인 검토 1회 필요.
- **재검토 트리거**:
  - 베타 사용자 ≥2명이 "독서 기간 입력 귀찮다" 호소 → "읽기 시작" 칩 제거, 완독일 단일 축으로 단순화.
  - 캘린더 진입 빈도가 30일 후 DAU의 <10%면 → V1.5 "월말결산 카드"로 진입 후크 강화.
- **PR 분할**: 17-A 스키마 + `book_repository.setReadingDate` · 17-B 책 상세 `_ReadingDatesRow` · 17-C 서재 3 세그먼트화 + `calendar_segment.dart`(`table_calendar`) + 이전 V1.5 보강 [인용구] 세그먼트 합본 · 17-D 골든 + release APK 검증. 각 PR 끝 release 빌드 검증.

---

## 2026-05-17 — 인용구 선택적 E2EE 도입 (V1.0 출시 전)

- **결정**: 사용자가 잠금 토글한 인용구만 클라이언트 측 E2E 암호화(AES-256-GCM)해서 저장. `text` + `manual_book_text`만 암호화, 메타데이터(`moods`/`page`/`book_id`/`created_at`)는 평문 유지(무드 GIN 인덱스·`my_quote_mood_counts` RPC·홈 피드 그대로). 마스터키 K(32B 랜덤)는 `flutter_secure_storage`에 캐시. 다기기는 envelope 암호화 — 사용자가 설정한 "잠금 비밀번호"로 PBKDF2-HMAC-SHA512(600k iters) wrap_key 파생 → `K_wrapped`만 새 테이블 `user_crypto_envelopes`에 서버 저장. 비상 백업으로 K 자체를 QR/base64 종이 인쇄. 기존 평문 인용구는 그대로(`is_private=false`).
- **이유**: 현재 RLS는 다른 *사용자*만 막을 뿐 `service_role`·Supabase Studio·`pg_dump`로 운영자(나)가 평문 접근 가능. PR15-A의 "데이터 주권" 차별화 메시지를 *기술적으로* 진실하게 만들어야 거짓말이 안 됨. 출시 후 E2EE 추가하면 "그 사이 운영자가 봤다"는 사실이 안 지워짐. → 출시는 한 달 미루더라도 V1.0에 포함하기로 합의.
- **알고리즘 선택**:
  - 본문 = AES-256-GCM + 12B 랜덤 nonce, `cryptography` 패키지(순수 Dart, native 의존 0).
  - KDF = PBKDF2-HMAC-SHA512 600k iters(OWASP 2024 권고 충족). Argon2id는 native plugin 필요해서 release-only 함정(`INTERNET`·`debugNeedsPaint` 사건 패턴) 회피 위해 거부.
  - `crypto_version smallint` 컬럼으로 V2 알고리즘 회수 슬롯 확보.
- **다기기 = Envelope**: K 자체는 안 변하고 wrap만 바뀜 → 비밀번호 변경 시 인용구 재암호화 0. `user_crypto_envelopes` 테이블 RLS 본인만, lazy 생성(첫 잠금 시도 시점). "잠금 비밀번호"는 Supabase 매직링크 로그인과 명확히 분리된 *독립* 항목 — UI에 "이 비밀번호는 서버가 모릅니다" 명시.
- **대안 검토**:
  - (a) 전체 E2EE → 거부. `ilike` 검색·서버 통계 전부 죽음, V1.5 텍스트 검색 백로그와 충돌.
  - (b) 로컬 전용(서버 미동기화) → 거부. Isar/Drift 도입 + 다기기·백업 사용자 책임 → 아키텍처 크게 변경, 출시 일정 파괴.
  - (c) Argon2id native plugin → 거부. release-only 함정 위험 가중.
  - (d) Supabase 패스워드 로그인 재사용 → 거부. 서버가 해시·접근권 가지면 oracle 가능.
  - (e) 6자리 PIN → 거부. brute-force 일구.
  - (f) QR 페어링만(envelope 없이) → 거부. 신규 기기마다 옛 기기 필요, 폰 분실 = 손실.
- **영향**:
  - 마이그레이션 2장: `20260517_quotes_e2ee.sql`(`text_encrypted bytea`·`manual_book_text_encrypted bytea`·`crypto_version smallint`·`is_private boolean default false` 추가, `text`·`manual_book_text` NOT NULL 해제, CHECK 재정의, `quotes_user_private_idx (user_id) where is_private = true` partial index) + `20260518_user_crypto_envelopes.sql`(envelope 테이블 + RLS 본인만 select/insert/update).
  - pubspec: `cryptography ^2.7.0`, `qr_flutter`(백업 QR), `mobile_scanner`(가져오기 스캔). 카메라 권한 + ProGuard rules 점검.
  - AndroidManifest `android:allowBackup="false"` 또는 `dataExtractionRules`로 `flutter_secure_storage` 경로 백업 제외 — 안 하면 Google Drive로 키 새서 E2EE 무력화.
  - `delete-account` Edge Function 흐름에 클라이언트 `KeyService.deleteAll()` 추가(envelope row는 `auth.users` cascade로 자동).
  - 잠금 인용구 공유 시 이미지에 평문 박힘 → 공유 직전 확인 모달.
  - `cards.design jsonb`에 quote text 사본이 들어가는지 PR16-B에서 검증(들어가면 그 경로도 암호화 대상).
  - 디버그 로그 본문 마스킹 점검 (현재 `print` 호출 grep 필요).
- **재검토 트리거**:
  - 베타 사용자가 패스프레이즈 빈도 분실로 인용구 손실 호소 시 → "종이 QR 강제 인쇄" 정책 강화 또는 잠금 인용구 자동 만료.
  - iOS 출시 시 → Keychain 동작 + 다기기 동기화 흐름 재시험(`flutter_secure_storage`·`mobile_scanner` iOS 동작 점검).
  - `cryptography` 패키지가 Argon2 지원 추가 시 → KDF 마이그레이션 검토(`crypto_version` 슬롯 활용).
- **PR 분할**: 16-A 스키마+크립토 코어 / 16-B repository·outbox wiring / 16-C 입력 UI+모달 / 16-D 잠금 비밀번호 화면(설정·변경·QR 백업/가져오기·fingerprint 표시) / 16-E 골든+release 검증. 각 PR 끝 release APK 실기기 검증 — `feedback_release_only_traps` 패턴 강제. Stage 4에 편성, 출시 한 달 후로 일정 합의(2026-05-17).

## 2026-05-13 — 책 별점 = `user_books.rating` (정수 1~5, nullable)

- **결정**: 책 별점은 "내 서재에서의 이 책 평가"라 `user_books`에 컬럼 추가(`rating smallint check between 1 and 5`, nullable=미평가). 별도 `book_ratings` 테이블 X. 별점을 매기면 그 책이 자동으로 내 서재에 들어옴(`setMyRating` = upsert `{user_id, book_id, rating}` onConflict — `addToLibrary`는 rating 미포함 upsert라 기존 별점을 안 건드림). 별점 지우기 = `rating=null` update(서재에는 그대로). 마이그레이션 `20260512130000_user_books_rating.sql` **remote 적용 완료**.
- **반쪽 별(0.5 단위) 안 함 — V1.5**: 입력 UI(별 좌/우반 탭) 복잡도 + 책귀는 책 트래커가 아니라 인용구 앱이라 별점은 보조 기능. 필요하면 `numeric(2,1)`로 확장(데이터 마이그레이션 쉬움).
- **UI**: `book_detail_screen` 헤더에 `StarRating` 행(로그인 시만 — `/book/:id`는 게스트 허용이라 비로그인은 별점 행 숨김). 탭=설정, 현재 별점 별 재탭=지우기. `repo.setMyRating` → `ref.invalidate(myRatingProvider(bookId))` + `myLibraryProvider`. `book-detail.md` 설계 문서에 반영.

## 2026-05-12 — 화면 설계 Phase B 그룹 1·2 결정 묶음 (가상 팀 협의 종합)

매니저 모드(UI/UX·기획·Dart·QA) 협의 후 `competitor-screen-analysis-2026-05-11.md §7` 미해결 5건 중 4건 + 신규 2건 결정. 근거 상세는 `docs/sessions/2026-05-12-screen-design-b.md`.

- **카드 텍스트 위치 앵커(상/중/하): V1엔 안 넣음. V1.5.** V1 카드 에디터의 미세 조정은 폰트 크기 ±·정렬(템플릿이 허용하는 범위)만. 이유: `docs/design/templates/01~05.md`가 이미 고정 좌표 모델(`quoteArea y=192` 등)이라 앵커를 넣으면 5종 명세를 "정렬 기반"으로 재작성 + 디자인팀 재합의 필요 → V1 차별화(①②④)와 시간 경쟁. Tezza/Unfold의 자유 배치가 미관 깨고 신규 사용자 헤매게 한 사례(competitor §2.5)와도 어긋남. 단 `card_editor_controller`의 텍스트 위치는 **지금부터 상대좌표(0~1)로 직렬화** — V1.5에 앵커 3지점 스냅 붙일 때 마이그레이션 0. (`card-editor.md §7` 미결 1 → 해소)
- **표지 없는 책(`cover_url == null`)에서 T4(표지발췌): 비활성화.** 썸네일 회색 + "표지가 필요해요" 오버레이(`templates/04.md`의 `showTemplateDisabledOverlay`), 나머지 4종(T1/T2/T3/T5)은 정상 제공 + (가능하면) "표지 추가하기" 인라인 액션으로 ISBN 재검색 유도(막다른 골목 금지). 이유: T4의 정체성이 "이 색이 이 책 표지에서 나왔다"는 바이럴 순간 — 표지 없는데 단색 그라데이션 degrade하면 그 약속이 거짓이 되고 T1/T3와 시각 구분도 안 됨. (`card-editor.md §7` 미결 2 → 해소)
- **인용구 목록 위치: 별도 탭 X. 서재 탭 안의 "책 ↔ 인용구" 세그먼트 뷰.** 4탭(홈/서재/＋/나) 유지 — DECISIONS 2026-05-10의 "친구 0명일 때 빈 탭이 cold-start 함정" 회피 원칙과 정합. 책↔인용구는 같은 데이터의 두 단면. 홈 피드("내 인용 — 최근순", 시간순 흐름)와 역할 구분: 서재>인용구 = 무드·책 단위 *탐색*(다시 보기). 세그먼트 전환 시 각 뷰 스크롤 위치 보존(`StatefulShellRoute` state). (`quote-list.md §1` 결정 대기 → 해소: (b)안 채택)
- **인용 중심 AI(차별화 ⑤): V1 출시 메시지·앱 내 어디에도 "AI"라는 단어를 쓰지 않음. "곧 출시" 약속도 안 함.** 이유: Fable이 2025.01 AI 연말 요약 인종차별 문구로 AI 전면 폐기한 사건(competitor §2.4) — 1인 개발자가 "곧" 약속을 깔면 그 사고 책임을 떠안음. 짧은 한국어 인용구는 AI 품질 빈약 → "곧 나온다" 했는데 품질 나쁘면 신뢰 손상이 더 큼. V1 viral은 ①②④가 담당(AI는 필수 카드 아님). V1.5에 넣을 때도 "이 인용 영어 번역"·"이 책 핵심 문장 3개"처럼 입출력 좁고 사용자가 항상 결과를 편집하는 기능만(OCR과 동일 원칙).
- **(신규) 홈 `/`의 "받은 카드 함": V1엔 안 넣음. V1 홈 = 순수 "내 인용 피드".** V1.5에 `received_cards`/`received_books` 테이블 1개 + deep link 핸들러 INSERT로 추가. 이유: V1 deep link 수신 흐름은 `deep-link-receive.md` 명세상 "책 상세 + `user_books` 담기"이지 "카드를 내 계정에 복제"가 아님 — "받은 카드"의 영속 저장소가 V1에 없다. follow 타임라인은 V1.5에 같은 피드에 합쳐 진화. `flows.md`/`client-architecture.md`의 `timelineProvider`(follow 의존)·`quotes` INSERT 시 `publish to followers` Realtime은 **코드에 0** — "제거"가 아니라 그 문서들의 해당 절을 "V1.5"로 마킹하는 게 작업. `home_screen.dart` 재작성 시 Realtime 구독 코드 금지(Realtime은 V2 — DECISIONS 2026-05-10).
- **(신규) `quote_repository.listMyQuotes` cursor 시그니처 확정.** 홈·인용 목록·책 상세 셋이 다 호출하므로 한 번만 정의: `listMyQuotes({String? bookId, Set<QuoteMood>? moods, ({DateTime createdAt, String id})? after, int limit = 15})` — cursor-after(created_at + id), offset 금지(DECISIONS 2026-05-10). 누적 상태는 `Notifier<AsyncValue<List<Quote>>>` + `_isLoadingMore` 가드 패턴(`createQuoteController`와 결). `bookSearchPagedProvider`는 README 주석에만 있고 코드에 없으므로 "참고 구현"으로 못 씀 — cursor-pagination은 그룹 1에서 처음 짜는 패턴.

## 2026-05-11 — 오프라인 입력은 "경량 로컬 아웃박스"까지만 (완전 동기화 엔진은 V1.5)

- **결정**: V1 인용구 입력 화면은 오프라인에서도 동작 — 미저장 인용구를 `shared_preferences`(또는 hive)에 **JSON 리스트(아웃박스)**로 들고 있다가, 앱 포그라운드 복귀 / 연결 회복 시 **best-effort flush**(실패 시 그대로 두고 다음 기회 재시도). 책은 온라인으로 골라뒀으면 `book_id`, 아니면 `manual_book_text`(텍스트) 저장 → 온라인 시 재매칭 제안. 홈/서재에 "동기화 대기 N개" 뱃지. `flows.md` Flow F의 **완전 동기화 엔진**(connectivity 상시 감지 + 충돌 해결 + 실시간 publish + 책 재매칭 UI)은 **V1.5**
- **이유**: 출퇴근 독자가 핵심 페르소나 → "지하철에서 쓴 인용구 날아감"은 신뢰 배신, 막아야 함. 근데 막는 데 필요한 건 완전 엔진이 아니라 경량 아웃박스(`drift`/`sqflite` 불필요, 스키마 마이그레이션 0, 단일 기기라 last-write-wins로 충분). 완전 엔진은 별도 서브시스템(M~L)이라 차별화와 시간 경쟁. 게다가 내장 OCR을 뺀 지금 오프라인 캡처 흐름 자체가 이미 반쪽(책 검색은 어차피 온라인 필요)
- **데이터 모델 영향**: `quotes.book_id` nullable(`on delete set null`) + `manual_book_text text` 필드를 V1에 넣어두면 V1.5에 큐 붙일 때 마이그레이션 안 함
- **재검토/축소 트리거**: Stage 2 일정이 빠듯하면 아웃박스를 **2.1로 미루고** V1은 "draft 1건만 로컬 저장(앱 죽으면 복구) + 저장 실패 시 폼 보존 + 재시도 버튼"으로 떨어뜨림 — "여러 건 오프라인 캡처"는 못 하지만 "쓴 거 날아감"은 막힘

## 2026-05-11 — 앱 내장 OCR 안 함, 폰 기능(iOS Live Text 등) + 클립보드 붙여넣기로

- **결정**: V1 인용구 입력은 ① 직접 텍스트 입력 ② **클립보드 붙여넣기 자동 감지** 두 경로만. ML Kit(`google_mlkit_text_recognition`) 등 앱 내장 OCR은 V1에 넣지 않는다. 사용자가 책 사진에서 텍스트를 따올 때는 **OS 기본 기능**(iOS Live Text, Android Google Lens/구글렌즈, 갤럭시 빅스비 비전 등)으로 복사 → 책귀에 붙여넣기. 인용구 입력 화면은 클립보드에 새 텍스트가 있으면 "붙여넣기" 배너를 띄움
- **이유**: ① 내장 OCR은 패키지 추가(`google_mlkit_*` + `image_picker` + 카메라/사진 권한) + 한국어 모델 번들(앱 용량 증가) + 웹 미지원(`kIsWeb` 가드 필요) + 세로쓰기·곡면 책 정확도 한계 + 결과 후처리 코드 → M~L 작업이 통째로 붙는데, 차별화(표지 팔레트·deep link 공유·무드 태그)와 시간 경쟁 ② iOS Live Text·구글렌즈가 이미 OS 레벨에서 한국어 OCR을 잘 함 — 굳이 우리가 다시 만들 이유 없음 ③ `flows.md` Flow B 4.3이 원래 이 방식("폰 기능 + 클립보드")이었음 — 이 결정으로 그 명세가 다시 유효해짐
- **대안 검토**: (a) 내장 OCR 광고 0으로 북모리 차별화 → 거부, 위 비용. 북모리의 진짜 약점은 OCR 없음이 아니라 *OCR마다 광고 게이트*이고, 우리가 OCR 자체를 안 해도 "막다른 골목 없음" 원칙은 지켜짐 (b) V1.5에 내장 OCR 재검토 — 베타에서 "사진→붙여넣기 2단계가 불편" 피드백 누적되면
- **영향**: STAGES Stage 2에서 "사진 촬영 → ML Kit OCR → 결과 편집 UI" 항목 삭제. quotes 테이블의 `source` 컬럼은 `manual` / `clipboard` 2종(`ocr` 제거 또는 V1.5 대비 유지). `pubspec.yaml`에 OCR/카메라 패키지 추가 안 함. `competitor-screen-analysis-2026-05-11.md` §7 결정 #1 = 해소
- **재검토 트리거**: 베타 사용자 다수가 "OS OCR → 붙여넣기"를 번거로워하면 V1.5에 내장 OCR (단 광고 0)

## 2026-05-10 — 카카오 OAuth는 V1.5로 미룸 (개인 앱 + Supabase GoTrue 충돌)

- **결정**: V1 출시까지 인증은 이메일 매직링크 단일. LoginScreen의 카카오 버튼은 비활성 placeholder ("카카오로 시작 (V1.5)"). 코드 인프라(`AuthController.signInWithKakao`, Supabase Dashboard의 Kakao provider 키, `handle_new_user` OAuth 호환 트리거)는 그대로 유지 — V1.5 활성화 시 LoginScreen의 OutlinedButton에 `_signInKakao` 다시 연결만 하면 됨
- **이유**: Supabase GoTrue가 Kakao OAuth 흐름에서 `account_email` scope를 클라이언트 인자와 무관하게 **하드코딩으로 요청**한다 (Supabase issue #36878). 그런데 카카오 **개인 앱**은 비즈니스 인증 없이는 `account_email` scope를 동의항목에 등록할 수 없어 KOE205 ("설정하지 않은 동의 항목") 에러로 실패. 매직링크는 정상 동작
- **대안 검토**:
  - (a) 카카오 "개인 개발자 등록" 우회 → 추가 본인 인증 절차 필요, V1 timeline 흔들기 싫음
  - (b) `kakao_flutter_sdk_user` + `signInWithIdToken`로 GoTrue OAuth 우회 → 30~60분 + 네이티브 설정. V1.5에 평가
  - (c) 매직링크만 → 채택. PLAN의 "이메일 또는 카카오" 명세 준수, 로그인 마찰 적음
- **재검토 트리거**: 베타 사용자 5명 중 2명 이상이 카카오 로그인 명시 요청 시 (b) 도입. 또는 비즈 인증 받게 되는 시점에 (a)
- **현재 상태의 외부 자원**: Kakao Developer Console 앱(ID 1453058)·동의항목·Redirect URI·Supabase Dashboard Kakao provider 키 모두 등록된 채로 둠 — V1.5 활성화 시 재설정 비용 0

## 2026-05-10 — go_router 구조 (`StatefulShellRoute` + auth gate) + 비용 정책

- **결정 (라우터)**: `StatefulShellRoute.indexedStack` 4 슬롯 BottomNav (홈/서재/[+]/내정보), `[+]`는 sentinel이라 `/quote/new` 풀스크린 push. 카드 편집기·인용구 입력은 `parentNavigatorKey: rootKey`로 셸 외부. `/book/:id`만 게스트 미리보기 허용. `/splash` initialLocation으로 cold-start 세션 hydrate 경합 회피
- **결정 (auth gate)**: `redirect` + `GoRouterRefreshStream(supabase.auth.onAuthStateChange)` 패턴. `ref.read`만으로는 로그아웃 후 화면이 안 바뀌는 함정 (QA 자문가가 P0로 지목)
- **이유**: 아키텍트(5탭) vs 기획자(3탭+[+]) 충돌 → 인터뷰 5명 중 timeline 핵심 페르소나 1명뿐, 친구 0명일 때 빈 탭이 cold start 함정. 친구 기능은 `/me` 안 진입점으로 흡수
- **대안**: 평면 `GoRoute` 트리 — 거부 (탭 전환 시 스크롤·검색 입력 상태 손실)
- **비용 영향 (QA 검토 결과 적용 예정)**:
  - 알라딘 API 프록시 Edge Function: Stage 4 → **Stage 1 (책 검색 화면 작업과 동시)**. 키 노출·IP 차단 위험 회피
  - `cached_network_image`: Stage 1 (이미지 렌더 시작 시점)
  - 친구 timeline Realtime 상시 구독 X → pull-to-refresh + 60s 폴링. Realtime은 V2 (200 동시 연결 한도)
  - 무한 스크롤은 `cursor-after` (created_at + id), 페이지 사이즈 15. offset 금지
  - 책 표지는 알라딘 URL 직접 캐시, Supabase Storage 미러링 X
  - 카드 PNG는 클라이언트 로컬에서만 생성, Storage 업로드 X
- **재검토 트리거**: 베타 사용자 50명 돌파 시 친구 탭 BottomNav 승격 검토. 친구 100명 이상이면 Realtime 도입 재검토

## 2026-05-10 — `riverpod_lint` / `custom_lint` 보류

- **결정**: dev_dependencies에서 `riverpod_lint`·`custom_lint` 제외하고 셋업 완료
- **이유**: `flutter_riverpod 3.3.x`가 요구하는 `riverpod 3.2.1`과 `riverpod_lint` 최신 stable이 요구하는 `riverpod 3.1.0` 사이 버전 충돌. Riverpod 생태계에서 린터가 메인 패키지보다 항상 한 박자 늦는 패턴
- **대안**: (a) `flutter_riverpod`을 3.1.x로 다운그레이드 → 거부 (최신 기능 손실), (b) 보류 → 채택
- **재검토 트리거**: `riverpod_lint`이 `riverpod ^3.3` 지원하면 dev_deps에 추가. 분기 1회 확인

## 2026-05-10 — 색 추출은 `palette_generator` 그대로 사용

- **결정**: discontinued된 `palette_generator 0.3.3+7`을 그대로 사용
- **이유**: 디자인 세션 산출물 `docs/design/color-extraction.md`가 이 패키지 API 기반. 셋업 단계에서 알고리즘 재설계 비용 회피. 동작에는 문제 없음
- **대안**: (a) `palette_generator_master` (커뮤니티 포크) — 단일 유지보수자 신뢰도 낮음, (b) `ColorScheme.fromImageProvider` (Flutter 내장) — Vibrant/Muted 버킷 모델 다름, 알고리즘 일부 재설계 필요
- **재검토 트리거**: V1 출시 후, 또는 Flutter 신버전에서 호환 깨질 때 (b) ColorScheme 기반으로 마이그레이션 우선 검토

## 2026-05-10 — Flutter 프로젝트 셋업 파라미터 확정

- **프로젝트 경로**: `C:\GIT\bookquote`
- **패키지명**: `bookquote` (소문자 단일 단어, Dart 식별자 규칙)
- **Bundle ID / Application ID**: `io.github.tgparkk.bookquote`
  - GitHub username `tgparkk` 기반 reverse domain. 개인 도메인 미보유 시 권장되는 안전한 패턴 (`com.sttgp.*` 같이 미소유 도메인 기반은 충돌 위험)
- **타겟 플랫폼**: Android + iOS + Web (Flutter 기본값)
  - Mac 미보유로 iOS 빌드는 추후. 초기 sanity check는 Chrome
- **Flutter 버전**: 3.41.9 (2026-04-29 stable, Dart 3.11.5 — dot shorthand 문법 지원)

## 2026-05-09 — 클라이언트 스택을 RN+Expo+Skia → Flutter+Dart 변경

- **결정**: Flutter (Dart) + Riverpod + freezed + json_serializable + go_router
- **이유**: Skia가 Flutter 엔진에 **내장**되어 있어 카드 외 모든 화면도 픽셀 단위 통제 가능. "전체 화면이 다 독특하고 일관성 있어야" 요구사항·한지영 페르소나(시각 임계점 매우 높음) 충족 용이. 사용자가 폴리글랏이라 Dart 학습 비용 며칠
- **대안**: RN+Expo+Skia (이전 결정) — 카드만 Skia, 그 외 화면은 RN 기본 컴포넌트로 분기 → 화면 일관성 깨짐
- **영향**: TypeScript 친숙도 활용 못함, 대신 Flutter 단일 엔진으로 디자인 일관성 확보. Stage 1+ 모든 후속 결정이 Flutter 전제

## 2026-05-09 — 백엔드 Supabase, 도서 메타 알라딘 OpenAPI

- **백엔드**: `supabase_flutter` 커뮤니티 SDK + Supabase (Postgres + Auth + Storage + Realtime)
- **도서 메타데이터**: 알라딘 OpenAPI (한국 도서 풍부). 보조 교보문고
- **데이터 아키텍처**: Supabase 3-layer (raw / processed / view), RLS-first 권한 모델
- **이미지 호스팅**: 책 표지는 알라딘 CDN URL을 직접 사용. 자체 호스팅 X (저장소 비용·저작권 회피)
- **이유**: 솔로 개발자가 Auth/DB/Storage/Realtime 한 번에 처리 + 한국 시장 정확도

## 2026-05-09 — 디자인 시스템 Ink-Paper-Copper

- **컬러 코어**: `#1C1917` (Ink) × `#FAFAF8` (Paper) × `#B87333` (Copper)
- **카드 템플릿 5종 픽스**: 미니멀 / 따뜻 / 모노 / 표지발췌 / 타이포
- **폰트**: 본문 Pretendard, 인용구 Noto Serif KR, 영문 보조 Libre Baskerville (모두 OFL)
- **토큰 single source of truth**: `lib/core/theme/tokens.dart` (TS·MD 명세는 `docs/design/`)
- **상세**: `docs/design/design-system.md`, `docs/design/tokens.md`

## 2026-05-09 — 앱 이름 "책귀" 픽스

- **결정**: 한국어 앱 이름 "책귀"
- **이유**: 책의 좋은 구절을 듣고/모은다는 결. 짧고 발음 쉬움. 단톡방·인스타에서 입소문 시 검색 가능성
- **영문 표기**: 코드/패키지/도메인에서는 `bookquote` 사용

## 2026-05-09 — 프로젝트 진행 분담

- **본 세션** (planning + coding): Validation, 페르소나·시나리오, 와이어프레임, 코딩, 출시
- **별도 디자인 세션** (`oh-my-claudecode:designer`): 카드 템플릿, 디자인 시스템, 비주얼. 이 세션 산출물은 `docs/design/`로 통합 완료 (2026-05-10)

---

## 열린 결정 (Open / Pending)

다음 항목은 아직 결정 전. 결정되면 위로 옮긴다.

- [ ] 알라딘 OpenAPI 키 발급 — 발급 후 호출 테스트
- [ ] Supabase 프로젝트 생성 — 리전, 테이블 스키마 초기화
- [ ] 회원가입 방법: 이메일 / 카카오 / 둘 다
- [ ] 한국어 only 출발 vs 처음부터 i18n 구조
- [ ] V1 가격 정책 (현재 안: 완전 무료 → V2부터 freemium 4,900원/월)
