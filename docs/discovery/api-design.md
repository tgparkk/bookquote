# API · 서버 함수 설계 (V1)

> ⚠️ **시점 고정 초안 (2026-05-09)** — Expo + `@supabase/supabase-js` + TanStack Query + `supabase gen types` 시절. 실제 구현은 Flutter + `supabase_flutter` + Riverpod이고 Edge Function도 2개(`aladin-search`·`delete-account`) 있다. **현재 DB 스키마·RPC·Edge Function의 단일 진실은 [`../db-schema.md`](../db-schema.md)** + `lib/features/**/data/*_repository.dart`.

**버전**: 0.1 (2026-05-09)
**연계**: `architecture.md` (시스템) · `client-architecture.md` (클라이언트)

---

## 1. 핵심 결정

| 결정 | 선택 |
|---|---|
| 데이터 호출 1차 방식 | **supabase-js 직접 쿼리** + RLS |
| Postgres RPC | V1은 거의 안 씀. 복잡 JOIN은 supabase-js nested select로 |
| Edge Function | V1에는 없음 (architecture.md 7번과 동일) |
| 외부 API (알라딘) | **클라이언트에서 직접 호출** |
| TypeScript 타입 | `supabase gen types`로 자동 생성, 모든 API 함수에 적용 |
| Pagination | Cursor-based (`created_at + id`) |
| API 함수 위치 | `features/<X>/api.ts` 한 파일에 모음 |
| 에러 정규화 | API 함수가 throw, TanStack Query가 잡음 |

---

## 2. 호출 방식의 선택 기준

```
┌────────────────────────────────────────────────────────────┐
│ 클라이언트 (Expo App)                                       │
└────────────────────────────────────────────────────────────┘
       │                              │                  │
       ↓ A                            ↓ B                ↓ C
[supabase-js]                    [Postgres RPC]     [외부 API]
 ├ select / insert /              (.rpc('xxx',       (axios·fetch)
 │ update / delete                 args))            ├ 알라딘
 ├ nested select                  V1 거의 X         └ Naver (V1.5+)
 │ ('quotes(*, books(*))')
 ├ rpc()
 └ realtime
       ↓
[Supabase Postgres]
 ├ tables (RLS)
 └ functions (security definer)
```

**A. supabase-js 직접 쿼리**: 단순 CRUD, RLS로 권한 처리. **V1의 95%가 여기**.

**B. Postgres RPC**: 한 트랜잭션에서 여러 변경, 복잡한 비즈니스 룰, 집계. V1에서 사용 후보:
- `add_book_with_initial_quote(book, quote)` — 인용구 추가하면서 책도 서재에 자동 등록 (한 트랜잭션)
- `get_user_stats(user_id)` — 책 수·인용구 수·최근 활동 한 번에

> 단, `add_book_with_initial_quote`는 클라이언트가 두 번 insert 호출해도 정합성에 큰 문제 없음 (book이 먼저 생기고 quote가 그것을 참조). V1에서 RPC 없이 시작.

**C. 외부 API**: 알라딘 책 검색·메타. 클라이언트에서 직접.

---

## 3. TypeScript 타입 생성

```bash
npx supabase gen types typescript --project-id "<project-ref>" > lib/database.types.ts
```

```typescript
// lib/supabase.ts
import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

export const supabase = createClient<Database>(
  process.env.EXPO_PUBLIC_SUPABASE_URL!,
  process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY!,
);

// 도메인 타입 추출
export type Profile = Database['public']['Tables']['profiles']['Row'];
export type Book = Database['public']['Tables']['books']['Row'];
export type Quote = Database['public']['Tables']['quotes']['Row'];
export type Card = Database['public']['Tables']['cards']['Row'];
```

스키마 변경 시 `gen types` 재실행 → 컴파일 에러로 변경 영향 자동 감지.

---

## 4. Feature별 API 명세

### 4.1 Auth (`features/auth/api.ts`)

```typescript
import { supabase } from '@/lib/supabase';

export async function signInWithKakao() {
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'kakao',
    options: {
      redirectTo: 'quotesapp://auth/callback',
    },
  });
  if (error) throw error;
}

export async function signInWithEmail(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw error;
  return data.session;
}

export async function signUpWithEmail(email: string, password: string, username: string) {
  const { data, error } = await supabase.auth.signUp({
    email, password,
    options: { data: { username } },
  });
  if (error) throw error;
  return data.session;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

export async function fetchProfile(userId: string) {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();
  if (error) throw error;
  return data;
}

export async function updateProfile(userId: string, updates: Partial<Profile>) {
  const { data, error } = await supabase
    .from('profiles')
    .update(updates)
    .eq('id', userId)
    .select()
    .single();
  if (error) throw error;
  return data;
}
```

**Profile 자동 생성**: `auth.users`에 row 생기면 Postgres trigger로 `public.profiles`에 빈 row 자동 생성. 클라이언트 코드 부담 없음.

### 4.2 Books (`features/books/api.ts`)

```typescript
import { supabase } from '@/lib/supabase';
import { aladinClient } from '@/lib/aladin';

// --- 외부 (알라딘) ---
export async function searchBooksOnAladin(query: string) {
  return aladinClient.search(query);  // 책 검색 결과 반환
}

// --- 내부 (Supabase) ---

// 알라딘 결과를 books 테이블에 넣기 (UPSERT by ISBN)
export async function upsertBookFromAladin(aladinBook: AladinBook) {
  const { data, error } = await supabase
    .from('books')
    .upsert({
      isbn: aladinBook.isbn13,
      title: aladinBook.title,
      author: aladinBook.author,
      publisher: aladinBook.publisher,
      cover_url: aladinBook.cover,
    }, { onConflict: 'isbn' })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function fetchBook(bookId: string) {
  const { data, error } = await supabase
    .from('books')
    .select('*')
    .eq('id', bookId)
    .single();
  if (error) throw error;
  return data;
}

export async function fetchUserLibrary(userId: string) {
  const { data, error } = await supabase
    .from('user_books')
    .select(`
      status, category, added_at,
      book:books(*)
    `)
    .eq('user_id', userId)
    .order('added_at', { ascending: false });
  if (error) throw error;
  return data;
}

export async function addBookToLibrary(bookId: string, status: 'reading' | 'finished' | 'want_to_read' = 'reading') {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { error } = await supabase
    .from('user_books')
    .insert({ user_id: user.id, book_id: bookId, status });
  if (error) throw error;
}

export async function updateBookStatus(bookId: string, status: string) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { error } = await supabase
    .from('user_books')
    .update({ status })
    .eq('user_id', user.id)
    .eq('book_id', bookId);
  if (error) throw error;
}
```

`aladinClient`는 `lib/aladin.ts`에서 fetch wrapper로 구현. 키는 `EXPO_PUBLIC_ALADIN_TTBKEY`.

### 4.3 Quotes (`features/quotes/api.ts`)

```typescript
import { supabase } from '@/lib/supabase';

const PAGE_SIZE = 20;

export interface TimelinePage {
  quotes: QuoteWithBookAndAuthor[];
  nextCursor: string | null;
}

export async function fetchTimeline(opts: { cursor?: string | null }): Promise<TimelinePage> {
  let q = supabase
    .from('quotes')
    .select(`
      *,
      book:books(*),
      author:profiles!quotes_user_id_fkey(id, username, display_name, avatar_url)
    `)
    .order('created_at', { ascending: false })
    .order('id', { ascending: false })
    .limit(PAGE_SIZE);

  if (opts.cursor) {
    q = q.lt('created_at', opts.cursor);
  }

  const { data, error } = await q;
  if (error) throw error;

  return {
    quotes: data,
    nextCursor: data.length === PAGE_SIZE ? data[data.length - 1].created_at : null,
  };
}

export async function fetchBookQuotes(bookId: string) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { data, error } = await supabase
    .from('quotes')
    .select('*')
    .eq('user_id', user.id)
    .eq('book_id', bookId)
    .order('page', { ascending: true, nullsFirst: false })
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}

export interface QuoteInput {
  bookId: string;
  text: string;
  page?: number;
  photoUrl?: string;
  tags?: string[];
  visibility: 'public' | 'friends' | 'private';
}

export async function createQuote(input: QuoteInput) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { data, error } = await supabase
    .from('quotes')
    .insert({
      user_id: user.id,
      book_id: input.bookId,
      text: input.text,
      page: input.page,
      photo_url: input.photoUrl,
      tags: input.tags,
      visibility: input.visibility,
    })
    .select(`*, book:books(*)`)
    .single();
  if (error) throw error;
  return data;
}

export async function updateQuote(quoteId: string, updates: Partial<QuoteInput>) {
  const { data, error } = await supabase
    .from('quotes')
    .update({
      text: updates.text,
      page: updates.page,
      tags: updates.tags,
      visibility: updates.visibility,
    })
    .eq('id', quoteId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function deleteQuote(quoteId: string) {
  const { error } = await supabase.from('quotes').delete().eq('id', quoteId);
  if (error) throw error;
}
```

**RLS가 권한을 처리**하므로 `eq('user_id', user.id)`는 update·delete에서 의도 명시 차원. 권한 검증은 DB가 담당.

### 4.4 Cards (`features/cards/api.ts`)

```typescript
export interface CardDesign {
  template: 'minimal' | 'warm' | 'mono' | 'gradient' | 'illustration';
  colors: string[];   // hex codes
  font: string;
  spacing: number;
}

export async function saveCardDesign(quoteId: string, design: CardDesign) {
  const { data, error } = await supabase
    .from('cards')
    .insert({ quote_id: quoteId, template: design.template, design })
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function fetchQuoteCards(quoteId: string) {
  const { data, error } = await supabase
    .from('cards')
    .select('*')
    .eq('quote_id', quoteId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data;
}
```

카드 PNG 자체는 클라이언트에서 합성·디바이스에 저장 → 우리 API에 안 올라감. 위 함수는 디자인 옵션만 jsonb로 저장.

### 4.5 Friends (`features/friends/api.ts`)

```typescript
export async function searchUsers(query: string) {
  const { data, error } = await supabase
    .from('profiles')
    .select('id, username, display_name, avatar_url')
    .or(`username.ilike.%${query}%,display_name.ilike.%${query}%`)
    .eq('is_public', true)
    .limit(20);
  if (error) throw error;
  return data;
}

export async function fetchFollowing(userId: string) {
  const { data, error } = await supabase
    .from('follows')
    .select('following:profiles!follows_following_id_fkey(*)')
    .eq('follower_id', userId);
  if (error) throw error;
  return data.map((r) => r.following);
}

export async function fetchFollowers(userId: string) {
  const { data, error } = await supabase
    .from('follows')
    .select('follower:profiles!follows_follower_id_fkey(*)')
    .eq('following_id', userId);
  if (error) throw error;
  return data.map((r) => r.follower);
}

export async function followUser(targetUserId: string) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { error } = await supabase
    .from('follows')
    .insert({ follower_id: user.id, following_id: targetUserId });
  if (error) throw error;
}

export async function unfollowUser(targetUserId: string) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) throw new Error('Not authenticated');

  const { error } = await supabase
    .from('follows')
    .delete()
    .eq('follower_id', user.id)
    .eq('following_id', targetUserId);
  if (error) throw error;
}
```

---

## 5. Pagination 패턴 (Cursor-based)

**Offset 방식 안 쓰는 이유**: 새 인용구가 timeline 위에 추가되면 page 2를 받을 때 항목이 한 칸씩 밀려 중복 발생.

**Cursor 방식**:
- 정렬 키: `(created_at DESC, id DESC)` — id를 추가해서 동일 시각 tie-break
- 다음 페이지: `WHERE created_at < ${lastSeenCreatedAt}`
- 클라이언트는 `lastSeenCreatedAt`만 들고 있음

`useInfiniteQuery`와 자연스럽게 결합 (`client-architecture.md` 7.A 참조).

---

## 6. 캐시 키 컨벤션 (TanStack Query)

```
[domain, action, ...params]
```

| Key | 의미 |
|---|---|
| `['profile', userId]` | 사용자 프로필 |
| `['userBooks', userId]` | 내 서재 |
| `['book', bookId]` | 책 단건 |
| `['bookSearch', query]` | 알라딘 검색 결과 |
| `['timeline']` | 친구 timeline |
| `['bookQuotes', bookId]` | 특정 책에 내가 모은 인용구 |
| `['quoteCards', quoteId]` | 인용구의 저장된 카드들 |
| `['follows', 'following', userId]` | 누구를 팔로우 |
| `['follows', 'followers', userId]` | 누가 나를 |

**무효화 규칙**: mutation 성공 시 영향 받는 key 모두 invalidate.

```typescript
// useCreateQuote 성공 시
queryClient.invalidateQueries({ queryKey: ['timeline'] });
queryClient.invalidateQueries({ queryKey: ['bookQuotes', newQuote.book_id] });
queryClient.invalidateQueries({ queryKey: ['userBooks'] });
```

---

## 7. 외부 API (알라딘) 호출 패턴

```typescript
// lib/aladin.ts
const ALADIN_BASE = 'https://www.aladin.co.kr/ttb/api';
const TTB_KEY = process.env.EXPO_PUBLIC_ALADIN_TTBKEY!;

export const aladinClient = {
  async search(query: string) {
    const url = new URL(`${ALADIN_BASE}/ItemSearch.aspx`);
    url.searchParams.set('TTBKey', TTB_KEY);
    url.searchParams.set('Query', query);
    url.searchParams.set('QueryType', 'Title');
    url.searchParams.set('SearchTarget', 'Book');
    url.searchParams.set('Output', 'JS');
    url.searchParams.set('Version', '20131101');
    url.searchParams.set('Cover', 'Big');
    url.searchParams.set('MaxResults', '20');

    const res = await fetch(url.toString());
    if (!res.ok) throw new AladinError(`HTTP ${res.status}`);
    const json = await res.json();
    return json.item.map(mapAladinItem);
  },

  async lookupByISBN(isbn: string) {
    const url = new URL(`${ALADIN_BASE}/ItemLookUp.aspx`);
    url.searchParams.set('TTBKey', TTB_KEY);
    url.searchParams.set('ItemId', isbn);
    url.searchParams.set('ItemIdType', 'ISBN13');
    url.searchParams.set('Output', 'JS');
    url.searchParams.set('Cover', 'Big');

    const res = await fetch(url.toString());
    if (!res.ok) throw new AladinError(`HTTP ${res.status}`);
    const json = await res.json();
    return json.item[0] ? mapAladinItem(json.item[0]) : null;
  },
};
```

**Search debounce**: 클라이언트에서 `useDebounce(query, 300)`로 호출 빈도 제한. 알라딘 호출량 보호.

**키 노출 우려**: `EXPO_PUBLIC_*`는 빌드에 포함되어 디컴파일 시 노출됨. 알라딘 TTB Key는 rate-limit이 보호 수단이고 비밀이 아니므로 OK.

---

## 8. 에러 정규화 (F에서 정밀화)

API 함수는 throw로 통일. TanStack Query가 받아서 UI에 전달.

```typescript
// lib/errors.ts
export class ApiError extends Error {
  constructor(public code: string, message: string, public cause?: unknown) {
    super(message);
  }
}

export class AladinError extends ApiError {
  constructor(message: string, cause?: unknown) {
    super('ALADIN_ERROR', message, cause);
  }
}

export class AuthError extends ApiError {
  constructor(message: string) {
    super('AUTH_ERROR', message);
  }
}
```

Supabase 에러는 코드별 분류 (`PGRST116` = no row, `23505` = unique violation 등). 자세한 매핑은 F에서.

---

## 9. RPC가 필요해지는 시점

V1.5 이후 다음 케이스 발생 시 RPC 추가:

| 상황 | RPC 함수 후보 |
|---|---|
| 인용구 추가 시 책이 없으면 자동 등록 (한 트랜잭션) | `add_quote_with_book(book_data, quote_data)` |
| 사용자 통계 (책 수·인용구 수·최근 활동) | `get_user_stats(user_id)` |
| Trending books (최근 7일 가장 많이 인용됨) | `get_trending_books(days, limit)` |
| 친구 추천 (취향 유사도) | `recommend_friends(user_id, limit)` |

V1에서 굳이 RPC로 만들지 않는 이유: 클라이언트 두 번 호출로 동일 결과 달성, 디버깅 쉬움, 스키마와 함수 분리 비용 회피.

---

## 10. Edge Function의 V1 미사용 재확인

`architecture.md` 7번 동일. V1.5+ 도입 후보:

| 케이스 | 함수 | 시점 |
|---|---|---|
| 알라딘 결과 캐싱 | `cached-book-search` | 호출 한도 임박 시 |
| 표지 색 추출 (서버에서 미리) | `extract-cover-palette` | 클라이언트 부담 측정 후 |
| 푸시 알림 발송 | `send-push` | V2 (FCM·APNs 키 보호) |
| 데이터 export (GDPR) | `export-user-data` | 사용자 요청 시 |

---

## 11. 다음 단계

다음 차례:
- **E. 핵심 사용자 플로우 시퀀스 정밀화** — "인용구 추가 → 카드 → 공유" 등 step-by-step
- **F. 에러 처리 철학** — 본 문서 8번 정밀화
- **G. 테스트 전략** — API 함수·hook·E2E 테스트 범위
