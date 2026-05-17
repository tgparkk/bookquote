# 화면 설계 — Me `/me` (계정·내보내기·약관·탈퇴)

> 그룹 2 · Stage 2 (일부 출시 블로커). 입력 근거: `competitor-screen-analysis §5.6`, Phase B 가상 팀 협의. 차별화 ③(데이터 주권) 일부.

---

## 1. 목적 / 진입·이탈 / 라우트

- **목적**: 내 데이터 요약·내보내기, 설정, 정보(스토어 심사 필수 링크), 계정 관리(탈퇴·로그아웃). **"친구 찾기"는 ⏳ PR18-B에서 V1.0 활성화 예정**(DECISIONS 2026-05-17 친구 서재 탐험 V1.0 합류 — 이전 V1.5 미룸 결정 부분 뒤집음). 함께 신규 섹션 **"내 프로필 공개"**(`profiles.is_library_public` 토글 + "공개 닉네임" 편집 — `is_library_public=true` 가기 전 닉네임 확인 강제).
- **라우트**: `StatefulShellBranch[3]` `GoRoute(path: '/me')`(BottomNav 4번째 슬롯 — sentinel `[2]` 다음). 인증 가드. 현행 `MeScreen`(ConsumerWidget — 이메일 + 친구찾기 stub + 로그아웃) → 섹션형 `ListView`로 확장.
- **진입**: BottomNav [나] 탭. **이탈**: 내 데이터 → `/library` / `/library?tab=quotes` / 외부 링크(약관·개인정보·문의 — `url_launcher`) / 탈퇴 다이얼로그 → `/auth/login` / 로그아웃 → `redirect`가 `/auth/login`으로.

> **⚠️ 출시 블로커**: ① in-app 계정 삭제(Apple Guideline 5.1.1(v) + Google Play 둘 다 요구 — 외부 웹폼 대체 불가) ② 개인정보처리방침·이용약관 링크(스토어 등록 폼 + 앱 내 둘 다 필요). V1 출시 전 RPC/Edge Function·URL 확보 필수 — STAGES Stage 5에 to-do.

---

## 2. 레이아웃 와이어프레임

```
┌─────────────────────────────────────────┐
│ 내 정보                                  │  AppBar
├─────────────────────────────────────────┤
│  ┌──┐  sttgpark@gmail.com               │  프로필 — 이니셜 원 아바타 + 이메일 + "로그인됨"
│  │S │  로그인됨                          │  (세션 로딩 중 "확인 중…" / 미로그인 "로그인 정보 없음")
│  └──┘                                    │
├─────────────────────────────────────────┤
│  내 데이터                                │  ── 섹션 헤더 (labelMedium, wide letterSpacing)
│  📝  인용구            128개          ▸  │  → /library?tab=quotes
│  📚  서재              23권           ▸  │  → /library
│  ⬇   Markdown으로 내보내기            ▸  │  → 내보내기 (차별화 ③)
├─────────────────────────────────────────┤
│  설정                                     │  ──
│  🌗  다크 모드          시스템 설정       │  V1 = 시스템 따라가기(읽기 전용 표시). V1.5 토글
│  🔔  알림              곧 추가될 기능     │  비활성 (V1.5)
├─────────────────────────────────────────┤
│  정보                                     │  ──
│  ℹ   앱 버전            1.0.0 (12)        │  탭 비활성
│  ✉   문의하기                         ▸  │  mailto: 또는 폼
│  📄  이용약관                         ▸  │  외부 링크 (심사 필수)
│  🔒  개인정보처리방침                  ▸  │  외부 링크 (심사 필수)
├─────────────────────────────────────────┤
│       ┌─────────────────────────┐        │
│       │       로그아웃           │        │  OutlinedButton — 로딩 중 "로그아웃 중…"(현행 유지)
│       └─────────────────────────┘        │  ※ 아웃박스 대기 N개면 경고 다이얼로그 먼저
│                                          │
│  회원 탈퇴                            ▸  │  맨 아래, 작게, semanticError 텍스트 — 2단계 확인
└─────────────────────────────────────────┘
```

**⏳ PR18-B 갱신**: "친구 찾기" ListTile은 V1.0에 **활성화**(DECISIONS 2026-05-17). 현행의 빈 `onTap: () {}` → 친구 검색 시트(`showFriendSearchSheet` — `profiles.display_name` `ilike` 검색 → 결과 ListTile 탭 → `/u/:userId`). 같은 섹션에 신규 ListTile 2개: ① **"내 프로필 공개"** trailing `Switch` (`profiles.is_library_public`. ON 가기 전 "공개 닉네임" 확인 다이얼로그 강제 — 본명 노출 사고 차단) ② **"공개 닉네임"** trailing 현재 `display_name` + `›` (탭=편집 다이얼로그). "팔로잉 N · 팔로워 N" 카운트 행은 "내 데이터" 섹션에 합류(인용구·서재 카운트 옆). 이전 "숨김 사유"(미완성 인상)는 PR18-C·D로 진입 후 풀스크린·책상세 한 줄까지 함께 출시되므로 해소.

---

## 3. 상태

| 상태 | 트리거 | 처리 | 표시 | 심각도 |
|---|---|---|---|---|
| 로딩: 세션 결정 전 | `/me` mount (보통 splash가 흡수해 도달 시 결정됨) | 프로필 영역만 "확인 중…" placeholder, 나머지 섹션 즉시 | Inline (영역) | 낮음 |
| 로딩: 내 데이터 카운트 | 인용구/책 count fetch (`CountOption.exact, head:true` — `listMyLibrary` limit 50으로 `.length` 쓰면 부정확) | trailing "…" → 숫자. 실패 시 "—" + 탭은 동작 | Inline (trailing) | 낮음 |
| 미로그인 표시 (도달 시) | `session == null` (라우터 가드 우회·로그아웃 직후 프레임) | "로그인 정보 없음" + [로그인하기] 버튼, 내 데이터 섹션 숨김 | Inline | 낮음 |
| 프로필 trigger 미생성 | `flows.md §3.4` (드물게) | "프로필 생성 중…" 안내 + 재시도. 이메일은 세션에서 읽으니 항상 보임 | Inline | 낮음 |
| 로딩: 로그아웃 | `authControllerProvider.isLoading` | 버튼 "로그아웃 중…" + 비활성 (현행 그대로) | Inline 버튼 | 낮음 |
| **경고: 아웃박스 대기 중 로그아웃** | `quote_outbox.pending().isNotEmpty` | **Modal** "아직 동기화 안 된 인용구 N개가 있어요. 로그아웃하면 이 기기에서 사라질 수 있어요." → [그래도 로그아웃] / [취소]. 데이터 유실 방지(8원칙 ②) | Modal | **높음** |
| 로그아웃 실패 — 네트워크 | `signOut()` AsyncError | **로컬 세션은 그래도 클리어**(`signOut(scope: local)` fallback) → "오프라인이지만 이 기기에선 로그아웃됐어요" Toast. `onAuthStateChange(SIGNED_OUT)` → `/auth/login` | Toast | 중간 |
| 로딩: Markdown 내보내기 | "내보내기" 탭 | "내보내는 중…" → `listMyQuotes()` 전체 fetch → `.md` 문자열(책별 그룹 + 메타) → `share_plus`로 파일 공유. 인용구 0개면 "내보낼 인용구가 없어요" | Inline → OS 시트 | 중간 |
| 에러: 내보내기 실패(quotes fetch / 디스크) | NetworkError / StorageError | "인용구를 불러오지 못해 내보내기를 못 했어요" + [다시 시도]. 부분 fetch면 "일부만 가져왔어요 — 그래도 내보낼까요?" | Toast → 재시도 | 중간 |
| 에러: 외부 링크 열기 실패 | `canLaunchUrl == false` | "브라우저를 열 수 없어요" Toast + URL 텍스트를 길게 눌러 복사 가능하게(최후 출구). 크래시 금지 | Toast | 낮음 |
| 탈퇴: 1단계 | "회원 탈퇴" 탭 | Modal "탈퇴하면 인용구·서재·카드가 모두 삭제되고 복구할 수 없어요. (먼저 Markdown으로 내보내기를 권해요)" → [내보내고 탈퇴] / [계속] / [취소] | Modal | 높음 |
| 탈퇴: 2단계 | [계속] 후 | 두 번째 Modal — "탈퇴합니다" 타이핑 또는 이메일 일부 재입력 마찰 → [탈퇴] / [취소] | Modal | 높음 |
| 탈퇴: 진행 중 | 2단계 확정 | 전체 dim + "탈퇴 처리 중…". Edge Function `delete-account`(JWT로 호출자 검증 → service_role로 `auth.admin.deleteUser` — 클라이언트에서 직접 불가). cascade로 `quotes`·`user_books`·`cards`·`profiles` 자동 삭제(`on delete cascade auth.users`). 완료 → `signOut` → `/auth/login` + "탈퇴가 완료됐어요" | Modal-lite | 높음 |
| 탈퇴: 실패 | RPC 5xx/네트워크 | "탈퇴 처리에 실패했어요. 잠시 후 다시 시도해주세요" + [다시 시도]. 세션 유지(중간 상태 방지) | Toast → 재시도 | 중간 |
| 다크모드 토글 | (V1.5) 설정 토글 | V1은 trailing "시스템 설정" 텍스트만(읽기 전용). `tokens.dart`가 라이트 팔레트만이라 다크 전용 토큰이 없음 → 다크모드 토글은 V1.5(다크 테마 정의가 별도 디자인 작업) | (V1.5) | 낮음 |
| 오프라인 | `connectivity_plus` | 계정 정보는 세션/캐시에서 즉시. 카운트는 stale. 로그아웃은 로컬 클리어로 동작. 내보내기·탈퇴·외부 링크는 "연결이 필요해요" 안내 후 비활성/시도 시 위 에러 | 배너 + 부분 비활성 | 중간 |
| 권한 거부 | 해당 없음 | Me는 권한 요청 0 (내보내기 = `share_plus`, 권한 불필요) | — | — |

---

## 4. 인터랙션

- 섹션형 `ListView` + `ListTile`. 섹션 사이 `Divider(height: AppSpacing.s8)` + 섹션 헤더(`textTheme.labelMedium` / `AppLetterSpacing.wide`).
- **프로필 아바타**: 이메일 첫 글자 이니셜을 `AppColors.accent100` 원 안에 `accent700` 텍스트(이미지 아바타 없음 — 매직링크라 프로필 사진 개념 없음). 탭 무동작(V1).
- **내 데이터**: "인용구 N개" → `context.go('/library?tab=quotes')` / "서재 N권" → `context.go('/library')` / "Markdown으로 내보내기" → 전체 인용구를 책별 그룹 + 메타로 `.md` 생성 → `share_plus`.
- **다크모드**: V1 = trailing "시스템 설정" 텍스트(읽기 전용). V1.5에 `[시스템/라이트/다크]` 세그먼트 + `themeProvider` + `darkTheme`.
- **알림 / 친구 찾기**: 알림 = trailing "곧 추가될 기능" + `enabled: false`. **친구 찾기 = ⏳ PR18-B 활성화** — 빈 콜백 제거하고 `showFriendSearchSheet` 연결(`display_name` `ilike` 검색 + 결과 ListTile → `/u/:userId`). 같은 PR에서 "내 프로필 공개" Switch + "공개 닉네임" 편집 ListTile 추가.
- **정보 링크**: `url_launcher`로 외부. 약관·개인정보처리방침 = 호스팅된 정적 페이지(GitHub Pages/Notion 등) — 스토어 심사 필수, V1 출시 전 URL 확보. 문의 = `mailto:` 또는 간단 폼.
- **앱 버전**: `package_info_plus`로 `"$version ($buildNumber)"`. (7연속 탭 → 디버그 — 선택, V1 불필요.)
- **로그아웃**: 현행 `ref.read(authControllerProvider.notifier).signOut()` 유지 — 단 **앞에 아웃박스 체크 다이얼로그 추가**(§3). 성공 시 `redirect`가 `/auth/login`으로.
- **회원 탈퇴**: 2단계 확인(Modal → 확인 입력) → Edge Function 호출 → `signOut`. Apple·Google 둘 다 in-app 계정 삭제 요구 — V1 출시 블로커.
- **이메일 표시**: `Text(email, maxLines: 1, overflow: TextOverflow.ellipsis)` — 현행 코드는 오버플로 처리 없음(긴 이메일 시 RenderFlex overflow 노란줄 가능 — 수정 항목).

### 현행 코드와의 차이
| 현행 `me_screen.dart` | 그룹 2 설계 |
|---|---|
| `Text(session?.user.email ?? '로그인 정보 없음')` | 프로필 영역(이니셜 아바타 + 이메일 + "로그인됨"/"확인 중…"/"로그인 정보 없음"), 오버플로 처리 |
| `ListTile('친구 찾기', onTap: () {})` ← 빈 콜백 | **⏳ PR18-B 활성화** — `showFriendSearchSheet` 연결 + "내 프로필 공개" Switch + "공개 닉네임" 편집 |
| `OutlinedButton.icon(... signOut())` 즉시 실행 | 같은 버튼 + 앞에 아웃박스 대기 시 경고 Modal |
| 로딩 상태 = `isLoading` → "로그아웃 중…" | 그대로 유지 |
| (없음) | "내 데이터"·"설정"·"정보" 3섹션 + Markdown export + 약관·개인정보·버전·문의 + 회원 탈퇴 2단계 |
| `Text('계정', headlineSmall)` | 섹션 헤더 = `labelMedium` + `AppLetterSpacing.wide`(작은 캡션) |

---

## 5. 토큰 매핑

| 영역 | 토큰 |
|---|---|
| 화면 배경 | `AppColors.secondary200` |
| AppBar | `AppTheme.appBarTheme` — 타이틀 `AppFonts.ui` w600 `AppFontSize.md`(17) `AppColors.primary900` |
| 프로필 아바타 | 원 `AppColors.accent100` 배경 / 이니셜 `AppColors.accent700` `AppFonts.ui` w600 18 / 지름 48 |
| 프로필 이메일 | `bodyMedium` `AppColors.primary800` · "로그인됨" `AppFontSize.xs`(11) `AppColors.primary400` |
| 섹션 헤더 | `textTheme.labelMedium` 또는 `AppFonts.ui` w600 `AppFontSize.xs`(11) `AppColors.primary400` `AppLetterSpacing.wide`(0.05) · 위 패딩 `AppSpacing.s8`(32), 아래 `AppSpacing.s2`(8) |
| ListTile 아이콘 | `AppColors.primary500`, size 22 |
| ListTile 타이틀 | `AppFonts.ui` `AppFontSize.base`(15) `AppColors.primary800` |
| ListTile trailing 값 | `AppFonts.ui` `AppFontSize.sm`(13) `AppColors.primary400` · "곧 추가될 기능" `AppColors.primary300` |
| ListTile 비활성 | 아이콘·텍스트 `AppColors.primary300` |
| Divider(섹션 구분) | `Divider(height: AppSpacing.s8, color: AppColors.primary100)` |
| 로그아웃 버튼 | `OutlinedButton` — border `AppColors.primary300` / 텍스트 `AppColors.primary700` / `AppRadius.sm`(4) |
| 회원 탈퇴 행 | 텍스트 `AppColors.semanticError` `AppFontSize.sm`(13) — 맨 아래, 시각 분리 |
| 경고/탈퇴 Modal | `AlertDialog` — 강조 액션 `AppColors.semanticError`, 취소 `AppColors.primary500` |
| Toast | `AppTheme.snackBarTheme` |

---

## 6. 재사용 / 신규

**재사용**: `currentSessionProvider`(`auth_state_provider.dart`), `authControllerProvider`(`auth_controller.dart` — `signOut`, `isLoading`), `myLibraryProvider`(서재 카운트 — 단 limit 50이라 정확 count는 별도 쿼리), `tokens.dart`.

**신규**: `lib/features/me/me_screen.dart` 확장(섹션형 ListView), `lib/features/me/presentation/widgets/me_section.dart`(섹션 헤더+타일 묶음), `lib/features/me/data/markdown_exporter.dart`(인용구 → `.md` 문자열, 책별 그룹+메타), `lib/features/account/account_deletion.dart`(2단계 확인 + Edge Function 호출), `supabase/functions/delete-account/`(Edge Function — JWT 검증 + `auth.admin.deleteUser`), `quote_repository`/`book_repository`에 count 쿼리(`CountOption.exact, head:true`) 추가. `pubspec.yaml`: `url_launcher`, `package_info_plus` 추가(`share_plus`는 `card-share.md`에서 이미 추가).

---

## 7. 엣지 / 접근성

**교차 관심사 (공통 8원칙)**: ① 오프라인=1급(카운트 stale, 링크/탈퇴 비활성) ② 데이터 유실 금지(로그아웃 전 아웃박스 경고 + export 권유) ③ PII 로그 금지(이메일은 화면에만, 미전송) ④ 막다른 골목 금지(비활성 기능은 "곧" 라벨 — 빈 onTap 금지) ⑤ 해당 없음 ⑥ 에러 표시 일관성(Modal=탈퇴/세션, Toast=링크/export) ⑦ 인증 가드 ⑧ 해당 없음.

| 엣지 | 심각도 | 처리 |
|---|---|---|
| 이메일 매우 김 | 낮음 | 1줄 말줄임(현행 미처리 — 수정) |
| 인용구 0개인데 export 탭 | 낮음 | "내보낼 인용구가 없어요" Toast |
| 약관 URL 미확보 채로 출시 | **높음** | 출시 블로커(스토어 리젝) — STAGES에 to-do |
| 탈퇴 중 네트워크 끊김 | 중간 | "처리에 실패했어요. 연결 후 다시" + 상태 롤백 |
| 다른 기기에서 이미 탈퇴된 계정 | 낮음 | 로그아웃 → `/auth/login` |
| `cards` 테이블 만들 때 `on delete cascade` 누락 | 중간 | 탈퇴 시 orphan — Stage 3 마이그레이션 체크리스트에 박을 것 |

**접근성**: ListTile ≥48dp(기본 충족). 비활성 타일 semantics `'$title, 아직 사용할 수 없는 기능'`. 카운트 trailing `'인용구 128개'`. 회원 탈퇴 행 `'회원 탈퇴, 되돌릴 수 없는 작업'`. 색만으로 위험 표시 X(텍스트 "되돌릴 수 없어요" 병기). 다크모드는 V1 시스템 따름.

---

## 변경 이력
- 2026-05-12 초안 (매니저 종합 — competitor-screen-analysis §5.6 + Phase B 가상 팀). 출시 블로커: in-app 계정 삭제·약관/개인정보 링크. 친구 찾기 = 숨김, 다크모드 토글 = V1.5.
- 2026-05-17 친구 찾기 V1.0 활성화 결정 반영 (DECISIONS 2026-05-17 "친구 서재 탐험 V1.0 합류"). 5군데 갱신: §1 목적, §2 와이어프레임 메모, §4 알림/친구찾기 행, §4 현행 코드 비교 표, 신규 섹션 "내 프로필 공개" Switch + "공개 닉네임" 편집 ListTile + "팔로잉/팔로워" 카운트 합류. 본명 노출 사고 차단을 위해 `is_library_public=true` 토글 ON 가기 전 닉네임 확인 강제(prerequisite). 세부 = `friend-profile.md`, RLS = `db-schema.md §2.5`.
