# 화면 설계 — 인증 콜백 `/auth/callback` · `/callback` (이미 구현 — 역정리 + 개선 권고)

> 그룹 3. 입력 근거: `lib/features/auth/auth_callback_screen.dart`, `lib/app/deep_link_handler.dart`, `lib/app/router.dart`(코드 기준). 게스트 라우트. transient(매직링크 클릭 직후 잠깐).

## 1. 목적 / 진입·이탈 / 라우트
- **목적**: 매직링크 클릭 → JWT 교환이 끝날 때까지 잠깐 보여주는 로딩 화면. 세션이 올라오면 `_redirect`가 적절한 곳으로 보냄. 세션 자체는 이 화면이 교환하지 않음(아래).
- **라우트**: `/auth/callback`(웹) + `/callback`(모바일 — Dart URI 파서가 `io.github.tgparkk.bookquote://auth/callback?code=...`를 `host=auth, path=/callback`으로 쪼개므로 둘 다 `AuthCallbackScreen`에 매핑, commit `bee0404`). `_redirect`의 `isAuthPath`에 둘 다 포함.
- **진입**: 매직링크 URL(`?code=...`). **이탈**: 세션 올라옴 → `_redirect`가 `isAuthPath && loggedIn` → `from ?? '/'` / 10초 타임아웃 → `/auth/login`.

## 2. 와이어프레임
```
┌─────────────────────────┐
│                         │
│         ◌               │  CircularProgressIndicator(color: accent500)
│      로그인 중…          │
│                         │  (권고: 8초+ 경과 시 "조금 더 걸리고 있어요…" / 12초에
│                         │   "링크에 문제가 있는 것 같아요 [다시 로그인]")
└─────────────────────────┘
```

## 3. 상태 (코드 기준)
| 상태 | 처리 | 심각도 |
|---|---|---|
| `isSupabaseReady == false` | 다음 프레임에 `context.go('/auth/login')` (키 미주입 빌드 방어) | 낮음 |
| `isSupabaseReady == true` | `Timer(10s, () { if (mounted) context.go('/auth/login'); })` — 10초 안전망. `dispose`에서 `_timeout?.cancel()` | — |
| 세션 교환 (웹) | `Supabase.initialize`의 `detectSessionInUri`가 URL `?code=` 자동 감지·교환 → `SIGNED_IN` 이벤트 → `_redirect`가 `from ?? '/'`로 | — |
| 세션 교환 (모바일) | `DeepLinkHandler`가 `app_links` 스트림 받아 `supabase.auth.getSessionFromUrl(uri)`. handler `_handle(uri)`: `uri.path.startsWith('/auth/callback')` 또는 `uri.host == 'auth'` 또는 `uri.toString().contains('code=')` 아니면 무시. 맞으면 `getSessionFromUrl` try/catch(실패 시 `debugPrint`만) | — |
| 10초 경과 | 세션 안 옴 → `/auth/login`. **이유 안내 없음** — 만료된/이미 쓴 링크인지 느린 네트워크인지 구분 X | 중간 (개선) |
| `DeepLinkHandler.start()` | `kIsWeb`이면 no-op, `!isSupabaseReady`면 return, 중복 시작 방지. `getInitialLink()`(콜드스타트) + `uriLinkStream.listen(_handle)` | — |

## 4. 인터랙션
- 사용자 인터랙션 없음(transient). (개선) 8초+ 경과 시 "취소하고 로그인으로" 텍스트 버튼.

## 5. 토큰 매핑
- 배경 `AppColors.secondary200` · `CircularProgressIndicator(color: AppColors.accent500)` · "로그인 중…" `AppFonts.ui` `AppFontSize.base`(15) `AppColors.primary500`.

## 6. 재사용 / 신규
- 재사용: `isSupabaseReady`, `DeepLinkHandler`(`deep_link_handler.dart`), `supabase.auth.getSessionFromUrl`, `tokens.dart`. 신규(개선): 8초+ 경과 단계 카피 + "취소하고 로그인으로" 버튼. `DeepLinkHandler` 일반화(`book/...` 등 비-auth URI도 dispatch — `deep-link-receive.md §6`).

## 7. 엣지 / 접근성 + 수정·보강 항목
**교차 관심사**: ⑦ 게스트 라우트(`isAuthPath`) · ② deep link payload 보존(아래 ②).
**양호(유지)**: 웹/모바일 양쪽 처리 · `isSupabaseReady` 분기 · `_callback` 별도 라우트(URI 파싱 함정 회피) · `_timeout` cancel on dispose.
**수정·보강 권고 (현행 ≠ 권고)**:
- ① **타임아웃/실패 시 사유 안내 없음** — 만료된/이미 쓴 매직링크면 `/auth/login?error=link_expired` → 로그인 화면이 "링크가 만료됐거나 이미 사용됐어요. 새 링크를 보내드릴게요" 표시. 또는 콜백 화면에서 8초+ 경과 시 "조금 더 걸리고 있어요…" → 12초에 "링크에 문제가 있는 것 같아요 [다시 로그인]".
- ② **`from`/deep link payload 손실** — `/callback` URL에 `from`이나 책 id 같은 비-auth 쿼리가 같이 와도 안 챙김 → 받는 사람이 deep link로 책 카드를 받았는데 콜백 경유로 들어오면 책 정보 날아감. 콜백 화면이 URL의 비-auth 쿼리를 보존 → 세션 올라온 뒤 `redirect`가 그 경로로. (`login.md` ③·`deep-link-receive.md §6`과 같은 작업.)
- ③ **`DeepLinkHandler` 미일반화** — `/auth/callback`만 처리, `book/...` 등은 무시 → `deep-link-receive.md`의 받는 사람 흐름이 V1엔 동작 안 함. handler를 "URI dispatcher"로: auth code면 `getSessionFromUrl`, 아니면 `router.go(path+query)`. 콜드스타트 미로그인 시 pending 보관 → 로그인 후 소비.
- ④ **PKCE 교환 실패가 `debugPrint`로만** — release에서 진단 불가. Sentry breadcrumb(PII 없이 — code만, 실제 토큰·이메일은 X) 추가 권장.
- (개선) transient 화면이라 ①~④ 외 진행 표시는 현행대로 둬도 OK(정상 케이스 <1초).
**접근성**: `Semantics(label: '로그인 처리 중')`. transient라 영향 미미.

## 변경 이력
- 2026-05-12 역정리 초안 (코드 기준 + Phase B 가상 팀 — 개선 4건). `/callback` 별도 라우트는 의도된 함정 회피(유지).
