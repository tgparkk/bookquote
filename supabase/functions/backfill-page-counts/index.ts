// PR29 일회성 백필: page_count가 NULL인 모든 책에 대해 Aladin → Google Books 순으로
// 페이지 수를 조회해 books.page_count 채운다.
//
// 권한: service_role 키로 호출. verify_jwt 기본 true라 service_role JWT 필요.
// 알라딘 일별 5,000건 한도라 books.limit 안전 cap. 호출 간 100ms sleep으로 rate 보호.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ALADIN_TTB_KEY = Deno.env.get("ALADIN_TTB_KEY")!;

interface BookRow {
  id: string;
  isbn13: string;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return jsonResponse({ error: "POST only" }, 405);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const { data: books, error } = await admin
    .from("books")
    .select("id, isbn13")
    .is("page_count", null)
    .limit(500);
  if (error) return jsonResponse({ error: error.message }, 500);

  let aladinHit = 0;
  let googleHit = 0;
  let miss = 0;
  const details: Array<{ isbn13: string; pageCount: number | null; src: string }> = [];

  for (const book of (books ?? []) as BookRow[]) {
    let pageCount: number | null = null;
    let src = "miss";

    pageCount = await fetchAladinPageCount(book.isbn13);
    if (pageCount != null) {
      aladinHit++;
      src = "aladin";
    } else {
      pageCount = await fetchGoogleBooksPageCount(book.isbn13);
      if (pageCount != null) {
        googleHit++;
        src = "google";
      } else {
        miss++;
      }
    }

    details.push({ isbn13: book.isbn13, pageCount, src });

    if (pageCount != null) {
      await admin
        .from("books")
        .update({ page_count: pageCount })
        .eq("id", book.id)
        .is("page_count", null);
    }
    await sleep(100);
  }

  return jsonResponse({
    total: books?.length ?? 0,
    aladinHit,
    googleHit,
    miss,
    details,
  }, 200);
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

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function jsonResponse(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}
