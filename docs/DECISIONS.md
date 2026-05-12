# 결정 대장 (Decision Log)

이 프로젝트의 주요 결정사항을 **날짜 역순**으로 기록한다. 한 결정당 한 섹션, 핵심만.
새 결정은 맨 위에 추가한다. 결정을 뒤집을 때는 기존 항목을 수정하지 말고 새 항목으로 추가하면서 어떤 항목을 대체하는지 명시한다.

---

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
