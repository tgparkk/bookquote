# 에러 처리 철학 (V1)

**버전**: 0.1 (2026-05-09)
**연계**: `flows.md` Edge cases · `api-design.md` 8번

---

## 1. 핵심 원칙

| 원칙 | 의미 |
|---|---|
| **Fail loud to dev, graceful to user** | Sentry는 raw 정보, 사용자에게는 친근한 한국어 |
| **에러는 데이터** | 타입이 있는 클래스로 모델링, `Error` raw throw 금지 |
| **사용자 데이터는 절대 잃지 않음** | 로컬 영속화 후 sync. 입력 중 앱 죽어도 복구 가능 |
| **Recovery > Perfection** | 한 번에 잘 처리되지 않아도 retry 경로가 명확하면 OK |
| **모든 async 경계에 명시적 처리** | API 함수 throw, hook에서 잡기, UI에서 표시 |
| **PII 로그 금지** | 인용구 텍스트·이메일은 절대 로그에 안 들어감 |

---

## 2. 에러 6종 분류

| 종류 | 예시 | 사용자 처리 |
|---|---|---|
| **NetworkError** | 오프라인, timeout, DNS 실패 | retry 버튼 + 자동 재시도 |
| **AuthError** | 토큰 만료, 401, 카카오 OAuth 실패 | 로그인 화면으로 |
| **ValidationError** | 빈 필드, 길이 초과, 잘못된 ISBN | 인라인 메시지 |
| **BusinessError** | 이미 팔로우, 중복 책 추가 | 인라인 또는 toast |
| **ExternalApiError** | 알라딘 5xx, rate limit | toast + retry 버튼 |
| **StorageError** | 디스크 가득, 사진 업로드 실패 | toast + 작업 보존 |

---

## 3. 에러 클래스 설계 (`lib/errors.ts`)

```typescript
export type ErrorCode =
  // Network
  | 'NETWORK_OFFLINE' | 'NETWORK_TIMEOUT' | 'NETWORK_UNKNOWN'
  // Auth
  | 'AUTH_SESSION_EXPIRED' | 'AUTH_OAUTH_CANCELED' | 'AUTH_OAUTH_FAILED' | 'AUTH_INVALID_CREDS'
  // Validation
  | 'VAL_REQUIRED' | 'VAL_TOO_LONG' | 'VAL_TOO_SHORT' | 'VAL_INVALID_FORMAT' | 'VAL_USERNAME_TAKEN'
  // Business
  | 'BIZ_ALREADY_FOLLOWING' | 'BIZ_BOOK_ALREADY_IN_LIBRARY' | 'BIZ_QUOTE_NOT_OWNED'
  // External
  | 'EXT_ALADIN_DOWN' | 'EXT_ALADIN_RATE_LIMIT' | 'EXT_ALADIN_NO_RESULTS'
  // Storage
  | 'STORAGE_DISK_FULL' | 'STORAGE_UPLOAD_FAILED' | 'STORAGE_FILE_TOO_LARGE';

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly userMessage: string;     // 사용자에게 노출할 한국어
  readonly retryable: boolean;
  readonly cause?: unknown;

  constructor(code: ErrorCode, userMessage: string, opts: { retryable?: boolean; cause?: unknown } = {}) {
    super(`[${code}] ${userMessage}`);
    this.code = code;
    this.userMessage = userMessage;
    this.retryable = opts.retryable ?? false;
    this.cause = opts.cause;
  }
}

// 헬퍼
export const E = {
  offline: () => new AppError('NETWORK_OFFLINE', '인터넷 연결을 확인해주세요', { retryable: true }),
  sessionExpired: () => new AppError('AUTH_SESSION_EXPIRED', '다시 로그인이 필요해요', { retryable: false }),
  required: (field: string) => new AppError('VAL_REQUIRED', `${field}을(를) 입력해주세요`),
  tooLong: (field: string, max: number) => new AppError('VAL_TOO_LONG', `${field}은(는) ${max}자 이내로 입력해주세요`),
  alreadyFollowing: () => new AppError('BIZ_ALREADY_FOLLOWING', '이미 팔로우하고 있어요'),
  aladinDown: () => new AppError('EXT_ALADIN_DOWN', '책 검색이 일시적으로 안 돼요. 잠시 후 다시 시도해주세요', { retryable: true }),
  // ...
};
```

**왜 enum 대신 union type**: discriminated union이 TypeScript exhaustive check에 유리. switch에서 누락 시 컴파일 에러.

---

## 4. Supabase 에러 → AppError 변환 (`lib/supabase-errors.ts`)

Supabase는 PostgreSQL 에러 코드를 반환. 이를 `AppError`로 매핑:

```typescript
import { PostgrestError } from '@supabase/supabase-js';

export function toAppError(err: unknown): AppError {
  if (err instanceof AppError) return err;

  if (isPostgrestError(err)) {
    switch (err.code) {
      case '23505': // unique_violation
        return new AppError('BIZ_ALREADY_FOLLOWING', '이미 추가된 항목이에요', { cause: err });
      case '23503': // foreign_key_violation
        return new AppError('VAL_INVALID_FORMAT', '참조하는 항목이 없어요', { cause: err });
      case 'PGRST301': // RLS denied
        return new AppError('AUTH_SESSION_EXPIRED', '권한이 없어요. 다시 로그인이 필요할 수 있어요', { cause: err });
      case 'PGRST116': // no rows
        return new AppError('VAL_INVALID_FORMAT', '항목을 찾을 수 없어요', { cause: err });
      default:
        return new AppError('NETWORK_UNKNOWN', '문제가 발생했어요. 잠시 후 다시 시도해주세요', { retryable: true, cause: err });
    }
  }

  if (isAuthError(err)) {
    if (err.message.includes('JWT')) return E.sessionExpired();
    return new AppError('AUTH_INVALID_CREDS', '로그인 정보를 확인해주세요', { cause: err });
  }

  if (isNetworkError(err)) {
    return E.offline();
  }

  return new AppError('NETWORK_UNKNOWN', '알 수 없는 문제가 발생했어요', { retryable: true, cause: err });
}
```

API 함수 끝에 catch 두지 않음. 위로 throw하고 hook에서 한 곳에 정규화:

```typescript
// features/quotes/hooks/useCreateQuote.ts
export function useCreateQuote() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (input) => {
      try {
        return await createQuote(input);
      } catch (err) {
        throw toAppError(err);
      }
    },
    // ...
  });
}
```

또는 더 깔끔하게 wrapper:

```typescript
// lib/api-helpers.ts
export function withErrorMapping<T extends (...args: any[]) => Promise<any>>(fn: T): T {
  return (async (...args) => {
    try { return await fn(...args); }
    catch (err) { throw toAppError(err); }
  }) as T;
}

// 사용
export const createQuote = withErrorMapping(async (input: QuoteInput) => {
  // ...
});
```

---

## 5. UX 표시 패턴 (4가지)

| 표시 방식 | 언제 | 예시 |
|---|---|---|
| **Inline** (input 아래) | 폼 검증 에러 | "인용구는 1000자 이내로" |
| **Toast** (3초) | 일시적·정보성 | "오프라인이에요. 연결되면 자동 저장돼요" |
| **Modal** (block) | 진행 불가 | "다시 로그인이 필요해요" |
| **Empty state** (page) | 데이터 자체 못 가져옴 | "친구를 추가하면 인용구가 보여요" |

`components/ErrorDisplay.tsx`로 표준화:

```tsx
interface ErrorDisplayProps {
  error: AppError;
  onRetry?: () => void;
  variant: 'inline' | 'toast' | 'modal' | 'empty';
}

export function ErrorDisplay({ error, onRetry, variant }: ErrorDisplayProps) {
  const showRetry = error.retryable && onRetry;
  // ...
}
```

---

## 6. 시나리오별 처리

### 6.1 네트워크 끊김 (오프라인)

**자동 처리**:
- TanStack Query: 자동 retry (3회, exponential backoff)
- NetInfo listener: 연결 복구 시 모든 query refetch

**수동 처리** (사용자 행동):
- 인용구 작성 중 → AsyncStorage에 저장 (`flows.md` 8번)
- 책 검색 중 → "오프라인이에요" toast + 검색 비활성

### 6.2 토큰 만료 (AuthError)

```
[Supabase 호출] → 401
  └─ supabase-js: refresh token 자동 시도
       ├─ 성공 → 원래 호출 재시도
       └─ 실패 → onAuthStateChange('SIGNED_OUT')
            └─ authStore.clear() → /(auth)/login 자동 리다이렉트
            └─ Modal: "다시 로그인이 필요해요"
```

`app/_layout.tsx`에서 supabase auth listener 단 한 곳에 등록:

```tsx
useEffect(() => {
  const { data } = supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_OUT') {
      authStore.clear();
      queryClient.clear();
    } else if (event === 'TOKEN_REFRESHED' || event === 'SIGNED_IN') {
      authStore.setSession(session);
    }
  });
  return () => data.subscription.unsubscribe();
}, []);
```

### 6.3 폼 검증 에러

React Hook Form + Zod로 schema 검증:

```typescript
const quoteSchema = z.object({
  text: z.string().min(1, '인용구를 입력해주세요').max(1000, '1000자 이내로 입력해주세요'),
  bookId: z.string().uuid('책을 선택해주세요'),
  page: z.number().int().positive().optional(),
});

const form = useForm<QuoteInput>({
  resolver: zodResolver(quoteSchema),
});
```

서버 검증 실패 시 (예: username 중복):

```typescript
const onSubmit = async (data) => {
  try {
    await mutation.mutateAsync(data);
  } catch (err) {
    if (err instanceof AppError && err.code === 'VAL_USERNAME_TAKEN') {
      form.setError('username', { message: err.userMessage });
    } else {
      // toast로 일반 처리
    }
  }
};
```

### 6.4 알라딘 API 다운

```
[책 검색] → 5xx
  └─ throw E.aladinDown()  // AppError(code='EXT_ALADIN_DOWN', retryable=true)
  └─ TanStack Query: retry 3회 (exponential)
  └─ 모두 실패 → UI에 "책 검색이 일시적으로 안 돼요" + retry 버튼 + "ISBN 직접 입력" 옵션
```

ISBN 직접 입력 UI는 알라딘 검색에 없는 책을 등록하는 정상 경로로 V1부터 제공 (architecture.md 8번에서 명시한 "누락 도서 처리"의 구현).

### 6.5 동기화 충돌 (오프라인 → 온라인)

```
[Sync Worker] processPending() {
  for (const pending of queue) {
    if (pending.book_matched_id) {
      // 이미 책 매칭된 상태
      await createQuote({ ...pending });
    } else {
      // 책 자동 매칭 시도
      const matches = await searchBooksOnAladin(pending.manual_book_text);
      if (matches.length === 1 && confidence > 0.9) {
        await upsertBook(matches[0]);
        await createQuote({ ...pending, bookId: matches[0].id });
      } else {
        // 매칭 실패: 사용자 개입 필요
        notify('책 정보를 직접 선택해주세요', { onPress: () => router.push('/quote/pending') });
      }
    }
  }
}
```

**원칙**: 자동 매칭 실패해도 데이터는 유지. 사용자가 수동 매칭 가능한 화면 제공.

### 6.6 카드 PNG 캡처 실패

```
[viewShot.capture()] → throw
  └─ toast "카드 만들기에 실패했어요. 다시 시도해주세요"
  └─ 디자인 옵션 유지 (form 그대로)
  └─ Sentry 보고 (메모리 부족? Skia 버그?)
```

### 6.7 Realtime 끊김

```
[supabase.channel] → disconnect
  └─ supabase-js 자동 재연결 시도
  └─ 우리는 별도 처리 X. timeline은 다음 query refetch 시 정확해짐
  └─ 사용자에게 알리지 않음 (조용한 자동 복구)
```

### 6.8 사진 업로드 실패 (Supabase Storage)

```
[uploadPhoto] → 5xx 또는 timeout
  └─ retry 3회 (exponential backoff)
  └─ 모두 실패 → "사진 첨부가 안 됐어요. 인용구만 저장할까요?" 다이얼로그
       ├─ "예" → photo_url 없이 createQuote
       └─ "다시 시도" → uploadPhoto 다시
```

**사진 없는 인용구도 valid**: 핵심 가치 보존.

---

## 7. 로깅·관측

### 7.1 도구

- **Sentry** (V1부터): crash, 에러 보고, breadcrumbs
- **PostHog** (V1부터): 사용자 행동, funnel, retention
- **Supabase Logs**: 서버 측 에러 (DB, Edge Function)

### 7.2 무엇을 로그하나

```typescript
// lib/logger.ts
export const logger = {
  error(err: AppError, context?: Record<string, any>) {
    // ❌ 절대 로그 안 함: text, email, photo URL, 카드 디자인 jsonb
    // ✅ 로그함: error code, retryable, screen, user_id (Sentry user context)

    Sentry.captureException(err, {
      tags: { code: err.code, retryable: String(err.retryable) },
      contexts: { app: context },
    });

    posthog.capture('error_shown', {
      error_code: err.code,
      retryable: err.retryable,
      screen: context?.screen,
    });
  },
};
```

### 7.3 PII 정책

| 데이터 | Sentry | PostHog |
|---|---|---|
| user_id (uuid) | ✅ user context | ✅ distinctId |
| 이메일 | ❌ | ❌ |
| 인용구 텍스트 | ❌ | ❌ |
| 책 ID | ✅ tag | ✅ event property |
| 검색어 | ❌ raw 안 됨 | 길이만 (예: query_length) |
| 카드 디자인 | ❌ | template 이름만 |
| 디바이스·OS | ✅ 자동 | ✅ 자동 |

### 7.4 Breadcrumb

Sentry breadcrumb으로 에러 직전 사용자 행동 추적:

```typescript
// API 호출 직전
Sentry.addBreadcrumb({ category: 'api', message: 'fetchTimeline', data: { cursor } });
```

---

## 8. Retry 정책

### 8.1 자동 retry (TanStack Query)

```typescript
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: (failureCount, error) => {
        if (error instanceof AppError && !error.retryable) return false;
        return failureCount < 3;
      },
      retryDelay: (attemptIndex) => Math.min(1000 * 2 ** attemptIndex, 30000),
    },
    mutations: {
      retry: false,  // mutation은 의도적 retry만
    },
  },
});
```

### 8.2 수동 retry

UI에 명시적 [다시 시도] 버튼. 자동 retry 다 실패한 후 사용자에게 통제권.

---

## 9. 안티패턴

| 안티패턴 | 왜 나쁜가 | 대신 |
|---|---|---|
| `try-catch` 안에 silent ignore | 디버깅 불가, 사용자도 모름 | 적어도 logger.error 호출 |
| `catch (e: any)` | 타입 안전성 0 | `catch (e: unknown)` + `toAppError(e)` |
| 에러 메시지를 화면에 raw 노출 | "Network request failed" 같은 비친절 | userMessage 사용 |
| 모든 에러를 toast로 | toast 폭탄, 사용자 무시 | 시나리오별 적정 표시 |
| 에러 없이 무시 | 사용자가 데이터 유실 모름 | 명시적 표시·복구 경로 |
| `console.error`로 끝냄 | 프로덕션에선 안 보임 | logger.error → Sentry |
| API 함수에서 toast 호출 | UI와 결합, 테스트 어려움 | hook에서 처리 |
| 토큰 만료를 화면마다 처리 | 중복·누락 | onAuthStateChange 한 곳 |

---

## 10. 다음 단계

남은 영역:
- **G. 테스트 전략** — API 함수·hook·E2E 테스트 범위, 에러 케이스 커버리지
