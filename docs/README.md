# 책귀 — 문서

책의 좋은 구절을 카드로 만들어 SNS·단톡방에 공유하는 모바일 퍼스트 앱.

이 폴더는 프로젝트의 모든 비코드 산출물을 모은 곳이다. 코드는 `../lib/`, 디자인 토큰의 single source of truth는 `../lib/core/theme/tokens.dart`.

---

## 빠르게 시작

처음 보는 사람은 이 순서로:

1. **[PLAN.md](PLAN.md)** — 프로젝트가 무엇이고 왜 만드는지 (마스터 플랜, 14–21주)
2. **[STAGES.md](STAGES.md)** — 지금 어디까지 왔고 다음에 뭘 할지 (체크리스트)
3. **[DECISIONS.md](DECISIONS.md)** — 주요 결정사항을 왜 그렇게 정했는지 (날짜 역순)

## 폴더 구조

| 경로 | 내용 |
|---|---|
| [PLAN.md](PLAN.md) | 마스터 플랜 — 컨셉, MVP 범위, 스택, 로드맵, GTM |
| [STAGES.md](STAGES.md) | Stage 0a/0b/1~5 진행 체크리스트 |
| [DECISIONS.md](DECISIONS.md) | 결정 대장 (날짜 역순 단일 파일) |
| [discovery/](discovery/) | Validation 단계 산출물 — 인터뷰, 경쟁사 평가, 아키텍처 초안, 랜딩페이지 |
| [design/](design/) | 디자인 시스템·토큰·카드 템플릿 5종·색추출 알고리즘·mockup |

## discovery/ 주요 문서

- [discovery/README.md](discovery/README.md) — Validation 단계 자체 README
- [discovery/virtual-interviews-2026-05-09.md](discovery/virtual-interviews-2026-05-09.md) — 가상 페르소나 5명 인터뷰 종합
- [discovery/real-interview-guide.md](discovery/real-interview-guide.md) — 실제 사용자 인터뷰 가이드 v2
- [discovery/competitor-evaluation.md](discovery/competitor-evaluation.md) — Goodreads/Readwise/Letterboxd/북적북적/Tezza 평가
- [discovery/bookstagram-analysis.md](discovery/bookstagram-analysis.md) — #책스타그램 카드 분석
- [discovery/architecture.md](discovery/architecture.md), [client-architecture.md](discovery/client-architecture.md), [api-design.md](discovery/api-design.md) — 시스템·클라이언트·API 초안
- [discovery/flows.md](discovery/flows.md), [error-handling.md](discovery/error-handling.md), [testing-strategy.md](discovery/testing-strategy.md) — 사용자 흐름·오류·테스트 전략
- [discovery/design-brief-for-designer-session.md](discovery/design-brief-for-designer-session.md) — 디자인 세션에 넘긴 브리프
- [discovery/landing-page/](discovery/landing-page/) — 사전등록 페이지 (미배포)

## design/ 주요 문서

- [design/design-system.md](design/design-system.md) — Ink-Paper-Copper 시스템 전체 설명
- [design/tokens.md](design/tokens.md) — 토큰 명세 (한국어 설명)
- [design/tokens.ts](design/tokens.ts) — TypeScript 원본 (참고용)
- [design/color-extraction.md](design/color-extraction.md) — 책 표지 → 5색 팔레트 추출 알고리즘
- [design/templates/](design/templates/) — 카드 템플릿 5종 (미니멀·따뜻·모노·표지발췌·타이포)
- [design/mockups/all-templates.html](design/mockups/all-templates.html) — 5종 비교 mockup (브라우저에서 열기)

> **주의**: `tokens.dart`는 이 폴더에 없다. 코드 single source of truth는 `lib/core/theme/tokens.dart`. `tokens.md`·`tokens.ts`는 명세·참고용으로만 보존.

## 문서 유지 원칙

- **결정**은 `DECISIONS.md`에 새 항목으로 추가 (기존 항목 수정 X). 뒤집힌 결정은 무엇을 대체하는지 명시
- **Stage 진행**은 `STAGES.md`의 체크박스 갱신
- **discovery/design 산출물**은 시점 고정. 내용이 진부해지면 `// 진부함` 같은 표시 대신 새 파일을 만들어 위에서 참조
- 새 결정·진행이 영구 가치가 있다고 판단되면 메모리(`MEMORY.md`)가 아니라 이 폴더에 기록 (메모리는 휘발성, 협업자가 못 봄)
