# 테스트 전략 (V1)

**버전**: 0.1 (2026-05-09)
**연계**: `flows.md` · `error-handling.md` · `api-design.md`

---

## 1. 핵심 결정

| 결정 | 선택 |
|---|---|
| 단위 테스트 러너 | **Jest** + Expo preset |
| 컴포넌트 테스트 | **React Native Testing Library** (RNTL) |
| 외부 API mocking | **MSW** (Mock Service Worker) |
| Supabase mocking | client을 `lib/supabase.ts` 한 파일에 분리 → 테스트에서 인터페이스 mock |
| RLS 정책 테스트 | **Supabase CLI 로컬 + pgTAP** |
| E2E | **Maestro** (Detox 대신) |
| CI | **GitHub Actions** |
| 커버리지 도구 | Jest 내장 (lcov 출력) |

**왜 Detox 아닌 Maestro**: 솔로 개발자 셋업 비용 1/5. YAML 테스트 정의. iOS·Android 동일 작성. CI 통합 단순.

---

## 2. 테스트 피라미드 (이 앱 기준)

```
       ┌─────┐
       │ E2E │  Maestro: 핵심 플로우 2–3개만 (A, B)
       └─────┘
      ┌────────┐
      │  훅·통합  │  RNTL + MSW: 도메인 hook, 화면 렌더 흐름
      └────────┘
   ┌────────────────┐
   │  단위·API·RLS    │  Jest + pgTAP: 로직, 변환, 권한
   └────────────────┘
```

**비율 목표 (V1 출시 시점)**:
- 단위·API·RLS: 80개
- 훅·통합: 20개
- E2E: 3개

**왜 이 비율**: 모바일 UI 테스트는 flaky하고 유지비 큼. 백엔드 출신이시므로 단위·API에 집중하는 분배가 본인 강점에 맞음.

---

## 3. 무엇을 테스트할 것인가 (우선순위)

| 우선순위 | 영역 | 이유 |
|---|---|---|
| ★★★ | API 함수 (`features/<X>/api.ts`) | 데이터 contract, 깨지면 광범위 영향 |
| ★★★ | Error 변환 (`toAppError`) | 사용자 메시지의 단일 진실 소스 |
| ★★★ | RLS 정책 | 보안의 1차 방어선, 한 번 깨지면 데이터 유출 |
| ★★★ | E2E Flow A·B | 핵심 가치 경로, 회귀 즉시 감지 |
| ★★ | 도메인 hook (`useTimeline`, `useCreateQuote`) | 비즈니스 로직 |
| ★★ | Color extractor (`colorExtractor.ts`) | 카드 차별화의 핵심 로직 |
| ★★ | Sync queue logic (오프라인) | 데이터 유실 위험 |
| ★ | Card renderer (Skia 합성) | 시각적 회귀 — 스냅샷 테스트로 |
| ☆ | 단순 presentational 컴포넌트 | 변경 빈도 높고 flaky |
| ☆ | 라우팅 wiring | Expo Router 자체 신뢰 |

---

## 4. 단위 테스트 (Jest)

### 4.1 API 함수 테스트

**전략**: supabase-js 클라이언트를 mock해서 호출이 올바른 SQL/필터로 가는지 검증.

```typescript
// features/quotes/api.test.ts
import { createQuote, fetchTimeline } from './api';
import { supabase } from '@/lib/supabase';

jest.mock('@/lib/supabase');

describe('createQuote', () => {
  beforeEach(() => {
    jest.mocked(supabase.auth.getUser).mockResolvedValue({
      data: { user: { id: 'user-1' } },
    } as any);
  });

  it('현재 사용자 ID로 quotes에 insert', async () => {
    const insertChain = mockChain({ data: { id: 'q-1', text: '...' }, error: null });
    jest.mocked(supabase.from).mockReturnValue(insertChain);

    await createQuote({
      bookId: 'b-1', text: '인용', visibility: 'public',
    });

    expect(supabase.from).toHaveBeenCalledWith('quotes');
    expect(insertChain.insert).toHaveBeenCalledWith(expect.objectContaining({
      user_id: 'user-1',
      book_id: 'b-1',
      text: '인용',
    }));
  });

  it('Supabase 에러를 그대로 throw', async () => {
    const insertChain = mockChain({ data: null, error: { code: '23505' } });
    jest.mocked(supabase.from).mockReturnValue(insertChain);

    await expect(createQuote({ ... })).rejects.toMatchObject({ code: '23505' });
  });
});
```

`mockChain` 유틸로 `.from().insert().select().single()` 같은 chain 객체를 한 번에:

```typescript
// __tests__/utils/mockChain.ts
export function mockChain(result: { data: any; error: any }) {
  const chain: any = {
    select: jest.fn().mockReturnThis(),
    insert: jest.fn().mockReturnThis(),
    update: jest.fn().mockReturnThis(),
    delete: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    in: jest.fn().mockReturnThis(),
    order: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    single: jest.fn().mockResolvedValue(result),
    then: (cb: any) => Promise.resolve(result).then(cb),
  };
  return chain;
}
```

### 4.2 에러 변환 테스트

```typescript
// lib/supabase-errors.test.ts
import { toAppError } from './supabase-errors';

describe('toAppError', () => {
  it('PostgreSQL unique violation → BIZ_ALREADY_FOLLOWING', () => {
    const err = toAppError({ code: '23505', message: '...' });
    expect(err.code).toBe('BIZ_ALREADY_FOLLOWING');
    expect(err.userMessage).toBe('이미 추가된 항목이에요');
  });

  it('JWT 만료 → AUTH_SESSION_EXPIRED', () => {
    const err = toAppError({ name: 'AuthApiError', message: 'JWT expired' });
    expect(err.code).toBe('AUTH_SESSION_EXPIRED');
  });

  it('알 수 없는 에러 → NETWORK_UNKNOWN, retryable', () => {
    const err = toAppError(new Error('???'));
    expect(err.code).toBe('NETWORK_UNKNOWN');
    expect(err.retryable).toBe(true);
  });
});
```

### 4.3 색 추출 (Color extractor)

```typescript
// features/cards/colorExtractor.test.ts
import { extractPalette } from './colorExtractor';

describe('extractPalette', () => {
  it('한강 작별하지 않는다 표지에서 5개 색 추출', async () => {
    const colors = await extractPalette('./fixtures/cover-becomes.jpg');
    expect(colors).toHaveLength(5);
    expect(colors[0]).toMatch(/^#[0-9a-f]{6}$/i);
  });

  it('이미지 로드 실패 시 기본 팔레트 반환', async () => {
    const colors = await extractPalette('invalid://url');
    expect(colors).toEqual(['#f0e6d2', '#d4c4a4', '#5a4a2a', '#3a2a14', '#ffffff']);
  });
});
```

---

## 5. Hook 테스트 (RNTL + TanStack Query)

```typescript
// features/quotes/hooks/useCreateQuote.test.tsx
import { renderHook, waitFor } from '@testing-library/react-native';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useCreateQuote } from './useCreateQuote';
import * as api from '../api';

jest.mock('../api');

const wrapper = ({ children }) => {
  const client = new QueryClient({ defaultOptions: { mutations: { retry: false } } });
  return <QueryClientProvider client={client}>{children}</QueryClientProvider>;
};

describe('useCreateQuote', () => {
  it('성공 시 timeline 캐시 무효화', async () => {
    jest.mocked(api.createQuote).mockResolvedValue({ id: 'q-1', book_id: 'b-1' } as any);
    const queryClient = new QueryClient();
    const invalidateSpy = jest.spyOn(queryClient, 'invalidateQueries');

    const { result } = renderHook(() => useCreateQuote(), { wrapper });
    result.current.mutate({ bookId: 'b-1', text: '...', visibility: 'public' });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));
    expect(invalidateSpy).toHaveBeenCalledWith({ queryKey: ['timeline'] });
  });
});
```

---

## 6. 컴포넌트 테스트 (선택적, 핵심만)

대부분의 presentational 컴포넌트는 테스트 안 함. 다음만 RNTL로:

- `QuoteCard` — 상태별 렌더 (좋아요·visibility·time formatting)
- `BookCover` — img 로드·에러 분기
- `CardRenderer` (Skia) — 스냅샷 테스트 (시각 회귀 감지)

```typescript
// features/quotes/components/QuoteCard.test.tsx
import { render, screen } from '@testing-library/react-native';
import { QuoteCard } from './QuoteCard';

it('public 인용구 렌더', () => {
  render(<QuoteCard quote={mockQuote({ visibility: 'public' })} />);
  expect(screen.getByText('우리는 누군가의...')).toBeTruthy();
  expect(screen.queryByLabelText('비공개')).toBeNull();
});

it('private 인용구는 자물쇠 아이콘', () => {
  render(<QuoteCard quote={mockQuote({ visibility: 'private' })} />);
  expect(screen.getByLabelText('비공개')).toBeTruthy();
});
```

---

## 7. RLS 정책 테스트 (★ 보안 1차 방어선)

**도구**: Supabase CLI 로컬 (Docker Postgres) + pgTAP

```bash
supabase init
supabase start         # 로컬 Postgres + Auth 서버
supabase db reset      # migrations 적용
supabase test db       # pgTAP 테스트 실행
```

테스트 위치: `supabase/tests/policies/`

```sql
-- supabase/tests/policies/quotes.test.sql
BEGIN;
SELECT plan(4);

-- 사용자 두 명 생성
INSERT INTO auth.users (id, email) VALUES
  ('00000000-0000-0000-0000-000000000001', 'a@example.com'),
  ('00000000-0000-0000-0000-000000000002', 'b@example.com');

-- A가 자기 인용구 작성 (성공해야 함)
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000001';
SELECT lives_ok(
  $$ INSERT INTO quotes (user_id, book_id, text, visibility) VALUES
       ('00000000-0000-0000-0000-000000000001', 'book-1', '인용', 'public') $$,
  'A는 자기 user_id로 insert 가능'
);

-- A가 B의 user_id로 insert 시도 (실패해야 함)
SELECT throws_ok(
  $$ INSERT INTO quotes (user_id, book_id, text, visibility) VALUES
       ('00000000-0000-0000-0000-000000000002', 'book-1', '나쁜', 'public') $$,
  '42501',
  null,
  'A는 다른 사용자의 user_id로 insert 불가'
);

-- B가 A의 인용구 수정 시도 (실패해야 함)
SET request.jwt.claim.sub = '00000000-0000-0000-0000-000000000002';
SELECT lives_ok(
  $$ UPDATE quotes SET text = '바꾸기' WHERE user_id = '00000000-0000-0000-0000-000000000001' $$,
  'UPDATE 자체는 RLS로 0 rows affected (에러는 안 나지만 실제 변경 0건)'
);

SELECT is(
  (SELECT count(*) FROM quotes WHERE text = '바꾸기'),
  0::bigint,
  '실제로 변경되지 않음'
);

SELECT * FROM finish();
ROLLBACK;
```

**모든 테이블의 모든 정책에 대해 최소 1개 테스트**:
- profiles: 자기 프로필 수정만, 다른 사람 조회는 is_public이면
- books: 모두 읽기, insert는 인증된 사용자만 (UPSERT 의도)
- user_books: 자기 것만 CRUD
- quotes: 자기 것 CRUD + visibility 정책
- cards: 본인 quote의 카드만
- follows: 자기가 follower인 row만 CRUD

---

## 8. E2E (Maestro)

**위치**: `.maestro/`

핵심 플로우 3개만:
- `01-onboarding.yaml` — Flow A (가입 → 첫 인용구)
- `02-quote-to-share.yaml` — Flow B (인용구 추가 → 카드 → 공유)
- `03-friend-follow.yaml` — Flow E (친구 추가 → timeline 반영)

```yaml
# .maestro/01-onboarding.yaml
appId: com.yourapp.quotes
---
- launchApp:
    clearState: true
- assertVisible: "책귀"
- tapOn: "이메일로 가입"
- inputText: "test+${RANDOM}@example.com"
- tapOn: "비밀번호"
- inputText: "Test1234!"
- tapOn: "가입하기"
- assertVisible: "아직 인용구가 없어요"
- tapOn: "+ 인용구 추가"
- assertVisible: "책 선택"
- tapOn: "책 선택"
- inputText: "데미안"
- waitForAnimationToEnd
- tapOn: "데미안"
- inputText: "내 안에서 솟아 나오려는 것"
- tapOn: "카드 만들기"
- assertVisible: "공유하기"
```

**왜 회원가입을 이메일로**: Kakao OAuth는 E2E에서 mock 어려움. 이메일 가입을 1급 옵션으로 둔 결정이 테스트 친화적.

**실행**:
```bash
# 로컬
maestro test .maestro/

# CI
maestro test --format junit --output report.xml .maestro/
```

---

## 9. Mock 전략

### 9.1 Supabase 클라이언트

`lib/supabase.ts`를 인터페이스로 분리해서 테스트에서 통째로 mock:

```typescript
// lib/supabase.ts
export const supabase = createClient<Database>(...);
```

```typescript
// __mocks__/lib/supabase.ts
export const supabase = {
  auth: {
    getUser: jest.fn(),
    onAuthStateChange: jest.fn(() => ({ data: { subscription: { unsubscribe: jest.fn() } } })),
  },
  from: jest.fn(),
  channel: jest.fn(() => ({
    on: jest.fn().mockReturnThis(),
    subscribe: jest.fn().mockReturnThis(),
    unsubscribe: jest.fn(),
  })),
};
```

### 9.2 알라딘 API

MSW로 HTTP 응답 mock:

```typescript
// __tests__/setup/msw.ts
import { setupServer } from 'msw/node';
import { http, HttpResponse } from 'msw';

export const server = setupServer(
  http.get('https://www.aladin.co.kr/ttb/api/ItemSearch.aspx', ({ request }) => {
    const url = new URL(request.url);
    const query = url.searchParams.get('Query');

    if (query === 'fail') {
      return new HttpResponse(null, { status: 500 });
    }

    return HttpResponse.json({
      item: [
        { isbn13: '9788954682152', title: '작별하지 않는다', author: '한강', cover: 'https://...' },
      ],
    });
  }),
);
```

```typescript
// jest.setup.ts
beforeAll(() => server.listen());
afterEach(() => server.resetHandlers());
afterAll(() => server.close());
```

---

## 10. CI 셋업 (GitHub Actions)

`.github/workflows/test.yml`:

```yaml
name: Test
on: [pull_request, push]

jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20, cache: 'npm' }
      - run: npm ci
      - run: npm run typecheck
      - run: npm run lint
      - run: npm test -- --coverage
      - uses: codecov/codecov-action@v4

  rls:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
      - run: supabase start
      - run: supabase db reset
      - run: supabase test db

  e2e-android:
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: reactivecircus/android-emulator-runner@v2
        with:
          api-level: 34
          script: |
            npm ci
            eas build --profile preview --platform android --local
            mobiledevice install ./build.apk
            maestro test .maestro/
```

**PR마다**: unit + RLS (빠름)
**main push마다**: + E2E Android (느림)
**iOS E2E**: 로컬에서만 (Mac 필요)

---

## 11. Stage별 테스트 도입 일정

플랜의 Roadmap에 맞춰:

| Stage | 추가할 테스트 |
|---|---|
| 1. 기반 | Jest 셋업, supabase mock 유틸, 첫 API 테스트 (auth, books) |
| 2. 인용구 입력 | Quotes API 테스트, useCreateQuote 훅 테스트 |
| 3. 카드 | Color extractor 단위, CardRenderer 스냅샷 |
| 4. 소셜 | RLS 정책 테스트 (반드시) — 친구·visibility |
| 5. 출시 직전 | Maestro E2E 3개 |
| 출시 후 | 발견된 버그마다 회귀 테스트 추가 (TDD-lite) |

**원칙**: 테스트가 많아서 출시 늦추지 않음. **출시 전 필수**는 (1) RLS 테스트, (2) E2E 3개. 나머지는 점진 추가.

---

## 12. 안티패턴

| 안티패턴 | 왜 나쁜가 | 대신 |
|---|---|---|
| 100% 커버리지 목표 | 테스트 위한 테스트, 유지비 폭증 | 핵심 영역 80%, 나머지 0% OK |
| 모든 컴포넌트 스냅샷 | 디자인 변경마다 수십 개 깨짐 | 시각 회귀가 critical한 것만 |
| 통합 테스트로 단위 책임 검증 | 느리고 디버깅 어려움 | 단위는 단위, 통합은 통합 |
| 테스트에서 실제 Supabase 호출 | flaky, 느림, 데이터 오염 | mock 또는 로컬 Supabase |
| E2E를 회귀 테스트로 사용 | 1개 추가하면 30초씩 늘어남 | E2E는 핵심 플로우만 |
| `any`로 mock 타입 회피 | 타입 안전성 0 | 명시적 mock 시그니처 |
| 테스트 안에서 테스트 함수 호출 | 의존성 사슬, 깨지면 도미노 | 각 테스트 독립 |
| RLS 테스트 생략 | 보안 사고 위험 | 출시 전 필수 |
| Implementation 디테일 테스트 | 리팩터링 못 함 | 행동(behavior) 테스트 |

---

## 13. 시리즈 마무리

본 문서로 V1 설계 시리즈 완료:

```
1. architecture.md           시스템 전체
2. client-architecture.md    클라이언트 구조·상태
3. api-design.md             API·서버 함수
4. flows.md                  사용자 플로우 시퀀스
5. error-handling.md         에러 처리
6. testing-strategy.md       (본 문서)
```

다음 행동:
- 본인이 Stage 0a (Validation) 시작 → 그 결과로 위 설계 문서 업데이트
- 또는 코딩 시작 — Stage 1 첫 커밋부터 위 결정들을 코드로 옮김
- 또는 별도 designer 세션에서 카드 템플릿 5개 정밀 디자인
