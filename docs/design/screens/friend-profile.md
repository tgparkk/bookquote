# 화면 설계 — 친구 프로필 `/u/:userId` (⏳ PR18-C 신규)

> 신규 그룹 4(소셜). 입력 근거: DECISIONS 2026-05-17 "친구 서재 탐험 V1.0 합류", `db-schema.md §2.5 follows`. **친구 서재 탐험의 유일한 풀스크린** — 다른 진입점(Me 친구찾기·책 상세 친구 미니리스트·카드 deep link sender 배너)은 모두 이 화면으로 모임. 본인 프로필 진입은 `/me`로 redirect — 이 화면은 *남의 서재 read-only* 만.

## 1. 목적 / 진입·이탈 / 라우트
- **목적**: 친구의 공개 서재(공개 책 + 공개 인용구) read-only 탐험. 잠금 인용구(`is_private=true`)는 RLS가 hard exclude — 클라이언트 코드에 fallback 없음(DB가 막음 = 신뢰의 단일 출처). [팔로우/언팔로우] 1탭. 그 외 액션 X — 인용구 [카드 만들기]·[삭제]·[수정]·공유 모두 **숨김**(남의 데이터).
- **라우트**: top-level `GoRoute(path: '/u/:userId')`. **인증 필수**(`_redirect`가 비로그인이면 `/auth/login?from=/u/:userId`로). 셸 밖 풀스크린. `:userId`는 `auth.users.id` UUID. 본인 진입 차단도 **라우터 `_redirect` 단계**에서 처리 — `auth.uid() == :userId`면 즉시 `/me`로 redirect(1프레임 흰 화면 깜박임 회피, 2026-05-18 결정). 닉네임 미설정/의심 패턴(`.`·`_`·email local-part) 사용자가 진입 시 `_NicknameGateView` 풀스크린 노출(PR18-B/C 게이트).
- **진입**: ① Me "친구 찾기" → 검색 결과 ListTile 탭 ② 책 상세 "이 책을 담은 친구 N명" → 시트 미니리스트 → 탭 ③ 카드 deep link sender 배너 → [이 사람 서재 ▸] 탭 ④ 친구 프로필 자신의 팔로잉/팔로워 카운트 → 카운트 시트 → 탭(친구의 친구). **이탈**: 책 카드 탭 → `/book/:id`(친구 컨텍스트 사라짐 — V1은 단순 그 책 화면, V1.5에 "이 책의 친구 인용구도 보기" 보강 검토) / 인용구 카드 탭 → 인라인 펼침(공유 버튼 없음) / [팔로우/언팔로우] → 상태 토글, 화면 유지 / `←` → push 스택(deep link 콜드스타트로 스택 비면 `context.go('/')`).

## 2. 와이어프레임

**공개 프로필 (`is_library_public=true`)**
```
┌─────────────────────────────────────────┐
│ ←  지윤                              ⋮   │  AppBar — ⋮ V1.5(신고/차단). V1엔 ⋮ 자체 숨김
├─────────────────────────────────────────┤
│   ┌──┐                                   │  헤더 — 64×64 아바타(없으면 이니셜)
│   │지 │  지윤                            │  display_name headlineSmall primary900
│   └──┘  팔로워 12 · 팔로잉 5             │  카운트 bodySmall primary500 (탭=시트로 리스트)
│         ┌─────────────────┐              │
│         │   ＋ 팔로우      │              │  accent500 FilledButton 36dp. 팔로잉 중이면
│         └─────────────────┘              │  "✓ 팔로잉" OutlinedButton(탭=언팔로우 확인)
├─────────────────────────────────────────┤
│ 지윤님의 서재   [ 책 23 ] [ 인용구 47 ] │  세그먼트(library.md와 같은 톤). 카운트는
├─────────────────────────────────────────┤  잠금 제외(RLS가 거른 N).
│  (책 탭) library.md의 _BookList 그대로  │
│  미드나잇 라이브러리       [3구절]       │  "N구절" 배지는 친구의 공개 인용구 카운트 only
│  ...                                     │
│                                          │
│  (인용구 탭) quote-list.md의 무드 칩    │
│  + 카드 목록. 카드 액션은:               │
│  ┌─────────────────────────────────────┐│  접힘 / 펼침 모두 카드 우상단 액션 X
│  │ "가장 깊은 밤에 가장 빛나는 별이…"   ││  ([공유]·[카드 만들기]·[삭제] 모두 숨김)
│  │  📕 미드나잇 라이브러리 p.132 · 위로 ││  대신 펼침 시 [📕 책 보기 ▸]만(/book/:id로)
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

**비공개 프로필 (`is_library_public=false`) — "잠긴 서재"**
```
┌─────────────────────────────────────────┐
│ ←  지윤                                   │
├─────────────────────────────────────────┤
│   ┌──┐  지윤                              │  헤더 + 팔로우 버튼은 그대로 표시 가능
│   │지 │  팔로워 12 · 팔로잉 5             │  (팔로우는 공개 여부와 무관 — 트위터식)
│   └──┘  ┌─────────────────┐               │
│         │   ＋ 팔로우      │               │
│         └─────────────────┘               │
├─────────────────────────────────────────┤
│                                          │
│             🔒                            │  primary400 큰 아이콘
│                                          │
│        이 서재는 비공개예요               │  headlineSmall primary600
│   지윤님이 공개 설정을 켜면 보여요        │  bodyMedium primary500
│                                          │
└─────────────────────────────────────────┘
```

**본인 진입 시** — 화면 빌드 직전 `context.go('/me')` redirect. 깜박임 회피 위해 build 시점이 아니라 `initState`/`didChangeDependencies`에서 검사.

## 3. 상태 (PR18-C 신규)
| 상태 | 처리 | 심각도 |
|---|---|---|
| 로딩: 프로필 | `friendProfileProvider(userId)` (`FutureProvider.autoDispose<Profile>`) | 낮음 |
| 로딩: 책·인용구 | 각각 `friendBooksProvider(userId)`·`friendQuoteFeedProvider(userId)` (notifier · cursor-after). 세그먼트 미선택 탭은 lazy | 낮음 |
| 미로그인 | 라우터 가드가 `/auth/login?from=/u/:userId`로 — 도달 가능성 0 | — |
| 비공개 프로필 | profile.is_library_public=false → 헤더 그대로, body는 "잠긴 서재" 빈상태. `FollowState`에 따라 카피 분기(팔로우 전: "공개 설정을 켜면 보여요" / 팔로잉 중: "팔로우 요청을 보냈어요. 서재가 공개되면 여기서 볼 수 있어요"). | — |
| 본인 진입 | 라우터 `_redirect`에서 `auth.uid() == userId` 검사 → `/me`로 redirect (1프레임 흰 화면 회피, 2026-05-18 결정) | — |
| 닉네임 미설정/의심 | `display_name`이 email local-part 패턴(`.`/`_` 포함)이거나 비어있으면 본 화면 진입 봉쇄 → `_NicknameGateView` 풀스크린 노출 (PR18-B/C 게이트) | — |
| 공개인데 빈 서재 | books·quotes 둘 다 0 → "아직 공개한 책이 없어요" 빈상태 | 낮음 |
| 팔로우 토글 중 | 낙관적 업데이트 — 버튼 즉시 토글, 실패 시 rollback + SnackBar "팔로우에 실패했어요" | 낮음 |
| 에러 (네트워크) | `_ErrorView` userMessage + [다시 시도](`ref.invalidate(friendProfileProvider(userId))`). raw `$error` 노출 X (library.md 기준) | 중간 |
| 존재하지 않는 userId | profile fetch가 `PGRST116`(0 row) → "사용자를 찾을 수 없어요" 빈상태 + [홈으로] | 낮음 |

## 4. 인터랙션
- **세그먼트 [책 ↔ 인용구]** — library.md `_SegmentHeader` 재사용. 각 탭 스크롤 위치 보존(친구 프로필도 `StatefulShellRoute` 외 풀스크린이라 화면 state로 보관). 카운트는 RLS가 거른 후 수치 — 잠금 인용구 제외.
- **[팔로우] 버튼** — accent500. 탭 즉시 낙관 토글(`follow_repository.follow(userId)` → 비활성/회색 200ms 후 "✓ 팔로잉"). 실패 시 rollback + SnackBar. 본인 자신은 진입 redirect라 도달 X.
- **[✓ 팔로잉] 버튼** — OutlinedButton. 탭 시 확인 다이얼로그 "지윤님 팔로우를 끊을까요?"([취소]/[언팔로우]). 우발 클릭 방지 — 트위터·인스타도 같은 패턴.
- **책 카드 탭** → `/book/:id`(친구 컨텍스트 sender·friendOnly 쿼리 안 붙임 — V1 단순). 책 상세에서 "이 책을 담은 친구 N명"엔 *이 친구도 포함*되므로 다시 돌아오기 가능.
- **인용구 카드 탭** → 인라인 펼침. 펼침 액션 1개만 = **[📕 책 보기 ▸]**(인용구에 `book_id` 있을 때만, manual_book_text only면 disabled). [공유]·[카드 만들기]·[삭제]·[수정] 전부 숨김(권한·UX 둘 다).
- **헤더 팔로워/팔로잉 카운트 탭** → 시트로 리스트(아바타+display_name+팔로우 상태 칩). 탭 시 또 다른 `/u/:uid`. 무한 깊이 OK(stack은 누적).
- **pull-to-refresh** → `ref.invalidate(friendProfileProvider(userId))` + 책·인용구 둘 다 invalidate.

## 5. 토큰 매핑
- 배경 `AppColors.secondary50` · AppBar `AppTheme.appBarTheme`(display_name `AppFonts.ui` w600 17 `primary900`)
- 헤더 아바타 64×64 `BookCover` 스타일 X(`CircleAvatar` `accent200` 배경 + 이니셜 1자 `primary900`). avatar_url 있으면 `cached_network_image`.
- display_name `AppFonts.ui` w600 `AppFontSize.lg`(18) `primary900` · 팔로워/팔로잉 카운트 `AppFontSize.sm`(13) `primary500`(탭 가능 영역 ≥44dp)
- [＋ 팔로우] `FilledButton.icon` `accent500`/`secondary50` 36dp · [✓ 팔로잉] `OutlinedButton.icon` border `primary300`/text `primary700`
- 세그먼트: library.md와 동일(`SegmentedButton` 선택 `primary900`/`secondary50`)
- 비공개 빈상태: 🔒 아이콘 48 `primary400` · 텍스트 `primary600`/`primary500` · 중앙 정렬
- 책 카드: `_BookRow` 재사용 (library.md) · 인용구 카드: `quote_list_card` 재사용 with `readOnly:true` prop(액션 숨김)
- [📕 책 보기 ▸] `TextButton.icon` `accent700` · `AppRadius.md`
- 잠금 인용구는 *카드 자체가 안 나옴*(RLS에서 거름) — 시각 토큰 불필요

## 6. 재사용 / 신규
- **재사용**:
  - `_BookRow` (library.md) — 그대로 표시. "N구절" 배지는 친구 공개 인용구 카운트 (PR18-D에서 책 단위 카운트 RPC)
  - `quote_list_card` (quote-list.md) — `readOnly` prop 추가(액션 숨김)
  - `_SegmentHeader` (library.md) — segments label만 "책 N · 인용구 N"으로
  - `_ErrorView` (library.md) — userMessage 매핑 + [다시 시도]
  - `BookCover`·`CircleAvatar`·`cached_network_image`
- **신규** (PR18-C):
  - `lib/features/profile/friend_profile_screen.dart` — 본 화면 ConsumerStatefulWidget
  - `lib/features/profile/state/friend_providers.dart` — `friendProfileProvider(userId)` + `friendBooksProvider(userId)` + `friendQuoteFeedProvider(userId)` (notifier · cursor-after)
  - `follow_repository`(PR18-B)에 `follow/unfollow/isFollowing/listFollowing/listFollowers` 메서드
  - `quote_repository.listFriendQuotesWithBook(userId, cursor)` — `from quotes where user_id = :userId` 단순 쿼리(RLS가 게이트)
  - `book_repository.listFriendBooks(userId)` — 동일 패턴
  - `profile_repository.getById(userId)` — `profiles` 단순 select
  - `_FollowButton` 위젯 — 낙관 토글 + rollback. `FollowState` enum 소비.
  - `FollowState` enum(`notFollowing`/`following`/`pending`/`failed`) — 비공개 빈상태 카피·버튼 라벨 분기에 공통 사용
  - `_LockedLibraryView` — 비공개 빈상태. `FollowState` 받아 카피 분기(2026-05-18 designer 결정).
  - `_NicknameGateView` — 닉네임 미설정/email local-part 의심 패턴 시 풀스크린 봉쇄 (PR18-B/C 게이트). [내 닉네임 설정하기 →] 1버튼 → `/me`로 이동.
  - `_FollowersSheet` — 헤더 카운트 탭 시트

## 7. 엣지 / 접근성 + 보안 점검 (PR18-E 침투 테스트로 회귀 가드)

**보안 핵심 (잠금 인용구 노출 사고 = 신뢰 파괴 1순위)**:
- ① **잠금 인용구는 RLS가 거름** — 클라이언트 쿼리는 `from quotes where user_id = :userId` 단순. `quotes_friends_read` 정책의 `quotes.is_private = false` 게이트가 DB 단에서 0 row 응답. 클라이언트에 fallback 코드 X(있으면 분기 버그 위험).
- ② **비공개 프로필** — RLS 정책에 `is_library_public=true` AND. 토글 OFF면 친구가 와도 책·인용구 0 row → "잠긴 서재" 빈상태. 단 *프로필 자체*는 read 가능(display_name 검색·팔로우 버튼 노출 필요).
- ③ **팔로우 안 한 사용자** — 정책의 `auth.uid() in (select follower_id ...)` 게이트. 비팔로워가 직접 URL `/u/:userId` 쳐도 책·인용구 0 row. 화면 = "잠긴 서재" 빈상태 (UX는 비공개와 동일하게 — 누가 누구 팔로우 안 했는지 explicit 신호 X).
- ④ **본인 진입** — `auth.uid() == :userId` redirect `/me`. 본인 잠금 인용구가 친구 화면 흐름에 잘못 노출되는 코드 경로 자체를 차단. 침투 테스트로 RLS 단독 회귀 가드.
- ⑤ **닉네임 본명 노출** — `display_name`이 가입 시 이메일 local-part(`handle_new_user_oauth`). 본명/직장 이메일이면 본명 노출. **PR18-B prerequisite** = Me에 "공개 닉네임" 편집 다이얼로그 + `is_library_public=true` 토글 ON 가기 전 강제 확인.
- ⑥ **카드 deep link sender 위변조** — `?sender=<uid>` URL에 박혀있어 변조 가능. 단 우리는 sender_uid로 권한 결정 안 함(공개 프로필 여부는 RLS가 결정). 표시만 — "지윤님이 보낸 카드"가 잘못 표시될 수 있으나 데이터 누수 X.
- ⑦ **자기 자신 follow** — DB CHECK `follower_id <> followee_id` + 화면 본인 진입 redirect로 이중 차단.
- ⑧ **존재하지 않는 userId** — `profiles.getById` PGRST116 → "사용자를 찾을 수 없어요" 빈상태. 404 페이지 별도 X.

**UX 엣지**:
- 친구 0명에서 친구 프로필 직접 URL 진입은 가능 — 그래도 화면 동작(팔로우 버튼이 첫 follow 진입점)
- pull-to-refresh 중 [팔로우] 탭 — 낙관 토글 그대로, refresh 끝나면 final state로 정합화
- 친구 인용구 무한스크롤 중 친구가 새 인용구 추가 — Realtime 없음(V1.5+), pull-to-refresh로만 갱신
- 친구가 갑자기 `is_library_public=false` 토글 — 다음 fetch에서 "잠긴 서재" 빈상태. UI 캐시는 invalidate로 정리.
- 친구가 잠금 토글한 *기존* 공개 인용구 — 다음 fetch에서 해당 카드 사라짐(소리 없이). 정상 동작.
- 비공개 프로필이지만 팔로워/팔로잉 카운트는 공개? — V1: **공개**(트위터식, 카운트가 social proof). V1.5에 "카운트도 비공개" 옵션 검토.

**접근성**:
- 헤더 아바타 `Semantics(label: '지윤 프로필 사진')`. 팔로우 버튼 `Tooltip + Semantics(label: '지윤 팔로우')`.
- 비공개 빈상태 🔒는 장식 + 텍스트 둘 다 — 색만으로 의미 전달 X.
- 책 카드 ≥48dp tap target 유지. 인용구 카드 펼침 액션도 ≥44dp.
- 인용구 카드의 `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.15)` — 무드 칩·메타 줄바꿈 회귀 방지 (PR14-D 패턴 일관).
- 헤더 팔로워/팔로잉 카운트는 *링크처럼 보이게* 색 강조(`primary700`) + Semantics `button`.

## 변경 이력
- 2026-05-19 **PR18-C 본 구현 완료** — 마이그레이션 1(`20260519120000_follows_public_read.sql`: `follows` SELECT RLS 확장 — 두 endpoint 모두 공개 프로필이면 누구나 read, 카운트·시트 노출 가능) + 화면(`friend_profile_screen.dart`) + providers(`friend_providers.dart`) + repo 메서드 4종(`ProfileRepository.getById` · `FollowRepository.listFollowing/listFollowers/countFollowing/countFollowers` · `BookRepository.listFriendBooks` · `QuoteRepository.listFriendQuotesWithBook`). `quote_list_card.dart`에 `readOnly`/`onOpenBook` prop 추가. router `/u/:userId` GoRoute + 본인 진입 redirect `_redirect`. `friend_search_screen.dart` ListTile `onTap` → `/u/:userId`. 신규 테스트 12개(readOnly 3 + friend_profile 9). flutter analyze clean, 239/239 통과. release APK 빌드 검증.
- 2026-05-18 P0/P1 흡수 — DECISIONS 2026-05-18 "친구 서재 탐험 P0/P1 흡수"에 따른 갱신. ① 본인 진입 redirect를 라우터 `_redirect`로 끌어올림(initState → 라우터 가드, 1프레임 깜박임 회피) ② 닉네임 미설정/의심 패턴 사용자 풀스크린 게이트 `_NicknameGateView` 신규(PR18-B/C 강제 게이트) ③ 비공개 빈상태에 `FollowState` enum 분기 카피(팔로우 전 vs 팔로잉 다른 문구 — designer 인지 부조화 회피). ④ §3 상태 표에 게이트·FollowState 분기 row 추가.
- 2026-05-17 초안 — DECISIONS 2026-05-17 "친구 서재 탐험 V1.0 합류" 결정 직후. PR18-C 본 구현 전 7섹션 명세 + 보안 침투 가드 8건 명시.
