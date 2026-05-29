// Edge Function: enrich-book-page-count
//
// 책 등록(upsert_book) 직후 클라이언트가 fire-and-forget으로 부른다.
// ISBN13으로 Aladin ItemLookUp(`subInfo.itemPage`) → 실패 시 Google Books v1
// (`fields=items(volumeInfo/pageCount)`) 순으로 조회해 받은 페이지 수로
// `public.books.page_count`를 UPDATE.
//
// Aladin 우선 이유: 한국 단행본(특히 민음사 세계문학전집 같은 단편집)은 Google
// Books DB에 ISBN 매칭이 약하거나 pageCount 필드가 빈 경우가 많음. Aladin은
// 국내 책 메타가 가장 충실. PR29 backfill 함수가 같은 순서를 검증함.
//
// 권한: SERVICE_ROLE_KEY로 books.update 수행.
//
// 환경변수:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, ALADIN_TTB_KEY
//
// 입력:
//   POST /functions/v1/enrich-book-page-count
//   { bookId: uuid, isbn13: string }
//
// 출력:
//   { ok: true, pageCount?: number, src?: 'aladin'|'google', skipped?: 'already_set'|'not_found' }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

interface RequestBody {
  bookId: string;
  isbn13: string;
}

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ALADIN_TTB_KEY = Deno.env.get("ALADIN_TTB_KEY")!;

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

  let pageCount = await fetchAladinPageCount(isbn13);
  let src: "aladin" | "google" = "aladin";
  if (pageCount == null) {
    pageCount = await fetchGoogleBooksPageCount(isbn13);
    src = "google";
  }
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

  return jsonResponse({ ok: true, pageCount, src }, 200);
});

async function fetchAladinPageCount(isbn13: string): Promise<number | null> {
  const url =
    "https://www.aladin.co.kr/ttb/api/ItemLookUp.aspx?" +
    new URLSearchParams({
      ttbkey: ALADIN_TTB_KEY,
      ItemId: isbn13,
      ItemIdType: "ISBN13",
      SearchTarget: "Book",
      output: "JS",
      Version: "20131101",
      OptResult: "subInfo",
    }).toString();
  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), 4000);
  try {
    const resp = await fetch(url, { signal: ctrl.signal });
    if (!resp.ok) return null;
    const text = await resp.text();
    const parsed = JSON.parse(text);
    const raw = parsed?.item?.[0]?.subInfo?.itemPage;
    return validPageCount(raw);
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

async function fetchGoogleBooksPageCount(isbn13: string): Promise<number | null> {
  const url =
    "https://www.googleapis.com/books/v1/volumes" +
    `?q=isbn:${encodeURIComponent(isbn13)}` +
    "&fields=items(volumeInfo/pageCount)&maxResults=1";
  const ctrl = new AbortController();
  const timeout = setTimeout(() => ctrl.abort(), 4000);
  try {
    const resp = await fetch(url, { signal: ctrl.signal });
    if (!resp.ok) return null;
    const parsed = await resp.json();
    const raw = parsed?.items?.[0]?.volumeInfo?.pageCount;
    return validPageCount(raw);
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
}

function validPageCount(raw: unknown): number | null {
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
