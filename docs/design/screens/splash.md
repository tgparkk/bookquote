# 화면 설계 — 스플래시 `/splash` (이미 구현 — 역정리 + 개선 권고)

> 그룹 3. 입력 근거: `lib/app/splash_screen.dart`(코드 기준 사실), `competitor-screen-analysis §5.8`, DECISIONS 2026-05-10(`/splash` initialLocation). **현행 ≠ 권고는 §7의 "수정/보강 항목"으로 분리.**

## 1. 목적 / 진입·이탈 / 라우트
- **목적**: cold-start 시 Supabase SDK가 SecureStorage에서 세션을 hydrate하는 동안(수십~수백 ms) `_redirect`가 null session 보고 `/auth/login`으로 잘못 튀는 걸 막는 게이트. hydrate 끝나면 로그인 여부 따라 분기.
- **라우트**: `GoRouter`의 `initialLocation: '/splash'`. `_redirect`에서 `loc == '/splash'`면 무조건 `return null`(자체 라우팅, 무한 루프 방지).
- **진입**: 앱 콜드스타트(항상 여기서 시작). **이탈**: `_resolve()` → `context.go('/')` (로그인됨) 또는 `/auth/login` (미로그인).

## 2. 와이어프레임
```
┌─────────────────────────┐
│                         │
│        (책귀)            │  ← 권고: 워드마크. 현행은 없음
│         ◌               │  CircularProgressIndicator(color: accent500), 중앙
│                         │
└─────────────────────────┘
```

## 3. 상태 (코드 기준)
| 상태 | 처리 | 심각도 |
|---|---|---|
| `isSupabaseReady == false` | `addPostFrameCallback`으로 다음 프레임에 `_resolve()` → `/auth/login` (키 미주입 빌드/테스트 방어) | 낮음 |
| `isSupabaseReady == true` | `Timer(500ms, _resolve)` 안전망 + `ref.listen(authStateProvider)` 첫 `whenData` 이벤트 시 `_resolve()`(타이머보다 빠르면 즉시) | 낮음 |
| `_resolve()` | `_resolved` 가드(1회만) + `mounted` 체크 → `loggedIn = isSupabaseReady && supabase.auth.currentSession != null` → `context.go(loggedIn ? '/' : '/auth/login')` | — |
| (개선) hydrate가 500ms 초과 | 안전망이 먼저 발화 → 미로그인으로 잘못 판단 → `/auth/login`으로 → 직후 hydrate 완료 → `onAuthStateChange`로 `_redirect` 재실행 → `/`로 복귀. **사용자에게 로그인 화면 깜빡임** | 중간 (개선 항목) |
| (개선) deep link 콜드스타트 | `getInitialLink`로 들어온 deep link payload를 스플래시가 인지·보존하는 경로 없음 — `/` 또는 `/auth/login`만 | 중간 (개선 항목) |

## 4. 인터랙션
- 사용자 인터랙션 없음(transient). `_resolved` 가드로 타이머·이벤트 race 시 1회만 `context.go`.

## 5. 토큰 매핑
- 배경 `AppColors.secondary200` · `CircularProgressIndicator(color: AppColors.accent500)` · (권고) 워드마크 `AppFonts.quote` 또는 로고, `AppColors.primary900`.

## 6. 재사용 / 신규
- 재사용: `isSupabaseReady`(`supabase_init.dart`), `authStateProvider`(`auth_state_provider.dart`), `tokens.dart`. 신규: (개선) 워드마크 위젯, deep link pending payload 인지(handler 일반화와 함께).

## 7. 엣지 / 접근성 + 수정·보강 항목
**교차 관심사**: ⑦ `/splash`는 인증 분기 *전*이라 가드 대상 아님(자체). ② deep link payload 보존(개선 시).
**양호(유지)**: `_resolved` 가드 · `isSupabaseReady` 분기 · `ref.listen`으로 이벤트 우선.
**수정·보강 권고 (현행 ≠ 권고)**:
- ① **500ms 안전망이 느린 기기에서 로그인 화면 깜빡임 유발** — 안전망 값 재검토(commit `231aaaa "debug logs around session hydrate"`의 로그로 실제 hydrate 시간 측정 후 조정), 또는 첫 SIGNED_IN/INITIAL 이벤트를 더 신뢰. V1 출시 후 실측 권장.
- ② **deep link cold start payload 보존 경로 없음** — `deep-link-receive.md §6`의 handler 일반화와 함께 보강(pending deep link → 로그인 게이트 통과 후 소비).
- ③ **브랜딩 0** — 콜드스타트 첫 인상에 "책귀" 워드마크 추가(차분한 톤, 과한 애니메이션 X).
**접근성**: transient라 스크린리더 영향 미미 — `Semantics(label: '로딩 중')` 정도.

## 변경 이력
- 2026-05-12 역정리 초안 (코드 기준 + Phase B 가상 팀 — 개선 3건 식별).
