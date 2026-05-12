# 화면 설계 — 로그인 `/auth/login` (이미 구현 — 역정리 + 개선 권고)

> 그룹 3. 입력 근거: `lib/features/auth/login_screen.dart`, `lib/features/auth/auth_controller.dart`(코드 기준), DECISIONS 2026-05-10(카카오 OAuth V1.5). 게스트 라우트.

## 1. 목적 / 진입·이탈 / 라우트
- **목적**: 이메일 매직링크로 가입·로그인 통합(`shouldCreateUser: true` — 신규/기존 구분 안 함). 카카오는 V1.5 placeholder.
- **라우트**: `GoRoute(path: '/auth/login')`. `_redirect`에서 `isAuthPath`(`loc.startsWith('/auth') || loc == '/callback'`)면 게스트 허용. 보호 라우트에서 미로그인 진입 시 `/auth/login?from=${Uri.encodeComponent(loc)}`로 옴.
- **진입**: 스플래시(미로그인) / 보호 라우트 redirect(`?from=` 보존) / 로그아웃 후. **이탈**: 매직링크 전송 → `_SentNotice` 화면(같은 라우트, state 전환) / 매직링크 클릭 → `/auth/callback` → 세션 → `_redirect`가 `from ?? '/'`로.

## 2. 와이어프레임
```
[ 입력 화면 ]                          [ _SentNotice (전송 후) ]
┌─────────────────────────┐            ┌─────────────────────────┐
│  책귀                    │            │  ✉ 메일을 보냈어요        │
│  좋은 구절을 모으세요     │            │  sttgpark@gmail.com 로    │
│  ┌─────────────────────┐ │            │  로그인 링크를 보냈어요.  │
│  │ 이메일               │ │            │  메일함을 확인해주세요.   │
│  └─────────────────────┘ │            │                          │
│  ┌─────────────────────┐ │            │  (권고 추가:)             │
│  │   로그인 링크 받기   │ │            │  · "메일이 안 와요?" 안내 │
│  └─────────────────────┘ │            │  · [다른 이메일로 다시]   │
│  ─────────────────────── │            └─────────────────────────┘
│  ⊗ 카카오로 시작 (곧)    │ ← 비활성 placeholder (DECISIONS 2026-05-10)
└─────────────────────────┘
```

## 3. 상태 (코드 기준)
| 상태 | 처리 | 심각도 |
|---|---|---|
| 입력 | `_emailController` + `_formKey`. validator: 빈값 "이메일을 입력해주세요." / `!contains('@') || !contains('.')` "올바른 이메일 주소를 입력해주세요." (느슨) | — |
| 전송 중 | `authControllerProvider`(`AsyncNotifierProvider<AuthController, void>`).isLoading → 버튼 비활성. `sendMagicLink`은 `isSupabaseReady` 아니면 `AuthException('Supabase 환경 미설정')` throw, 아니면 `AsyncValue.guard(supabase.auth.signInWithOtp(email, emailRedirectTo: _redirectUrl(), shouldCreateUser: true))` | 낮음 |
| 전송 성공 | `state.when(data:)` → `_linkSent = true` → `_SentNotice` | — |
| 전송 실패 | `state.when(error:)` → `ScaffoldMessenger.showSnackBar(authErrorMessage(e))`. `authErrorMessage`: rate limit → "메일을 너무 자주 요청했어요…" / invalid email → "올바른 이메일 주소…" / `kDebugMode`면 raw / 그 외 "문제가 발생했어요…" | 중간 |
| `_redirectUrl()` | `kIsWeb`면 `'${Uri.base.origin}/auth/callback'`, 아니면 `'io.github.tgparkk.bookquote://auth/callback'` | — |
| 카카오 버튼 | `OutlinedButton.icon(onPressed: null, ...)` — 비활성. `AuthController.signInWithKakao`는 존재하나 호출처 없음(DECISIONS — KOE205) | — |

## 4. 인터랙션
- "로그인 링크 받기": 폼 validate → `sendMagicLink(email, redirectTo: _redirectUrl())` → 성공 시 `_SentNotice`. 로그인 성공 후 화면 전환은 `GoRouterRefreshStream(onAuthStateChange)` → `_redirect` 재평가 → `from ?? '/'`.
- (개선) `_SentNotice`에서 빠져나갈 길 추가, 재전송 쿨다운 안내.

## 5. 토큰 매핑
- 배경 `AppColors.secondary200` · 워드마크 `AppFonts.quote`/로고 `AppColors.primary900` · 이메일 입력 `AppTheme.inputDecorationTheme`(filled, 포커스 `accent500`) · "로그인 링크 받기" `ElevatedButton`(`AppColors.accent500` 배경) · 카카오 버튼 `OutlinedButton`(비활성 — `primary300`) · `_SentNotice` 아이콘 `accent500`/텍스트 `primary700`.

## 6. 재사용 / 신규
- 재사용: `authControllerProvider`(`auth_controller.dart`), `isSupabaseReady`, `_redirectUrl` 패턴, `tokens.dart`. 신규(개선): `_SentNotice`에 [다른 이메일로 다시 보내기] 버튼 + "메일이 안 와요?" 안내 + 재전송 쿨다운(30s) 표시.

## 7. 엣지 / 접근성 + 수정·보강 항목
**교차 관심사**: ⑦ 게스트 라우트 · ② `?from=` 보존(아래 ③) · ③ PII = `kDebugMode`에서만 raw error 노출(준수) · ⑥ 에러 = Toast(일관).
**양호(유지)**: 카카오 비활성 placeholder(코드 주석에 KOE205 사유·우회책 기록됨) · 에러 Toast 분기 · `shouldCreateUser: true` 가입 통합.
**수정·보강 권고 (현행 ≠ 권고)**:
- ① **이메일 검증 약함** — `a@b.` 같은 garbage 통과. `\S+@\S+\.\S+` 정도로 강화(RFC 수준은 과함). `VAL_INVALID_FORMAT` Inline.
- ② **매직링크 재전송 출구 없음** — `_linkSent` 후 `_SentNotice`만 영구 표시 → 이메일 오타면 갇힘(앱 재시작밖에). `[다른 이메일로 다시 보내기]` 텍스트 버튼(→ `setState(_linkSent = false)`) + "메일이 안 와요?" 안내(스팸함·1분 대기) + 재전송 쿨다운(30s). 막다른 골목 성향.
- ③ **`?from=` 미보존(매직링크 흐름)** — `_redirectUrl()`이 항상 `/auth/callback`만, `?from=`을 안 실음. 콜백 URL에 `from`이 없으면 로그인 후 `_redirect`가 항상 `/`로 → `/quote/new`에서 시작한 흐름이 원래 화면으로 복귀 못 함. `from`을 매직링크 redirectTo 쿼리에 실거나 로컬(`shared_preferences`)에 보존 → 콜백 후 소비. (`deep-link-receive.md §6`·`auth-callback.md`와 같은 작업.)
- ④ **카카오 버튼이 첫 화면에 시각 무게 큼** — 매직링크가 메인인데 비활성 버튼이 무게 가져감. 더 작게/하단으로, 문구를 "카카오로 시작 (곧 지원)" — "V1.5" 같은 내부 용어 노출 X.
- ⑤ **에러가 SnackBar뿐** — 사용자가 놓치면 이유 모름. 폼 위 inline 에러 영역 추가(`error-handling.md` Inline 분류) 또는 버튼 라벨 일시 변경 병행.
**접근성**: 이메일 필드 `label: '이메일 주소'`, 키보드 `TextInputType.emailAddress`. 버튼 라벨 명확. 카카오 비활성 버튼 semantics `'카카오로 시작, 아직 사용할 수 없는 기능'`. `_SentNotice`는 `Semantics(liveRegion: true)`로 전송 완료를 스크린리더에 알림.

## 변경 이력
- 2026-05-12 역정리 초안 (코드 기준 + Phase B 가상 팀 — 개선 5건). 카카오 비활성은 의도된 결정(유지).
