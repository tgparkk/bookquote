// Edge Function: enrich-book-page-count
//
// 책 등록(upsert_book) 직후 클라이언트가 fire-and-forget으로 부른다.
// ISBN13으로 Google Books v1 (`fields=items(volumeInfo/pageCount)`)을 조회해
// 받은 페이지 수로 `public.books.page_count`를 UPDATE.
//
// 서버 사이드 호출이므로 클라이언트의 INTERNET 권한·rate limit·키 관리 부담 없음.
// 응답은 success/skip만 반환 — 클라이언트는 결과를 무시한다(이미 fire-and-forget).
// Google Books가 pageCount를 주지 못한 책은 `books.page_count`가 NULL로 남아
// UI에서 "두께 미수집" 섹션에 표시된다(사용자가 수동 입력 가능).
//
// 권한: SERVICE_ROLE_KEY로 books.update 수행 (books RLS의 authenticated update
// 정책 우회는 불필요하지만 어떤 user_id에서도 실행 가능하도록).
//
// 입력:
//   POST /functions/v1/enrich-book-page-count
//   { bookId: uuid, isbn13: string }
//
// 출력:
//   { ok: true, pageCount?: number, skipped?: 'already_set'|'not_found' }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

interface RequestBody {
  bookId: string;
  isbn13: string;
}

interface GoogleBooksVolume {
  volumeInfo?: { pageCount?: number };
}

interface GoogleBooksResponse {
  items?: GoogleBooksVolume[];
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: { code: "INVALID_INPUT", message: "POST만 허용" } }, 405);
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: { code: "INVALID_INPUT", message: "JSON 본문 잘못됨" } }, 400);
  }

  const bookId = body.bookId?.trim();
  const isbn13 = body.isbn13?.trim();
  if (!bookId || !isbn13 || isbn13.length !== 13) {
    return jsonResponse({ error: { code: "INVALID_INPUT", message: "bookId/isbn13 필수" } }, 400);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // 이미 채워진 책이면 호출 자체를 절약. 외부 API 호출 안 함.
  const { data: current, error: readErr } = await admin
    .from("books")
    .select("page_count")
    .eq("id", bookId)
    .maybeSingle();
  if (readErr) {
    return jsonResponse({ error: { code: "DB_READ", message: readErr.message } }, 500);
  }
  if (current?.page_count != null) {
    return jsonResponse({ ok: true, skipped: "already_set" }, 200);
  }

  const pageCount = await fetchGoogleBooksPageCount(isbn13);
  if (pageCount == null) {
    return jsonResponse({ ok: true, skipped: "not_found" }, 200);
  }

  const { error: updErr } = await admin
    .from("books")
    .update({ page_count: pageCount })
    .eq("id", bookId)
    .is("page_count", null);
  if (updErr) {
    return jsonResponse({ error: { code: "DB_WRITE", message: updErr.message } }, 500);
  }

  return jsonResponse({ ok: true, pageCount }, 200);
});

async function fetchGoogleBooksPageCount(isbn13: string): Promise<number | null> {
  const url =
    `https://www.googleapis.com/books/v1/volumes` +
    `?q=isbn:${encodeURIComponent(isbn13)}` +
    `&fields=items(volumeInfo/pageCount)` +
    `&maxResults=1`;
  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), 4000);
  let resp: Response;
  try {
    resp = await fetch(url, { signal: ctrl.signal });
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
  if (!resp.ok) return null;

  let parsed: GoogleBooksResponse;
  try {
    parsed = await resp.json();
  } catch {
    return null;
  }
  const raw = parsed.items?.[0]?.volumeInfo?.pageCount;
  if (typeof raw !== "number" || !Number.isFinite(raw) || raw <= 0 || raw >= 10000) {
    return null;
  }
  return Math.floor(raw);
}

function jsonResponse(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
