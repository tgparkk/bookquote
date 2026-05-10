# 결정 대장 (Decision Log)

이 프로젝트의 주요 결정사항을 **날짜 역순**으로 기록한다. 한 결정당 한 섹션, 핵심만.
새 결정은 맨 위에 추가한다. 결정을 뒤집을 때는 기존 항목을 수정하지 말고 새 항목으로 추가하면서 어떤 항목을 대체하는지 명시한다.

---

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
