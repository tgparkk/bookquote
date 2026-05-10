// Edge Function: aladin-search
//
// 클라이언트가 알라딘 OpenAPI를 직접 부르지 않고 이 함수를 거치게 한다.
// - 키 노출 방지 (`ALADIN_TTB_KEY`는 Supabase secrets에)
// - JWT 강제로 익명·봇 호출 차단 (5,000/일 한도 보호)
// - 통일된 에러 envelope `{ error: { code, message } }`
//
// 입력:
//   POST /functions/v1/aladin-search
//   { mode: "search", query: string, page?: number, size?: number }
//   { mode: "lookup", isbn:  string }
//
// 출력 (성공):
//   { items: AladinBook[], totalResults, page, size }
// 출력 (실패):
//   { error: { code: AladinErrorCode | "INVALID_INPUT", message } } + HTTP status

import {
  AladinError,
  type SearchResult,
  lookupAladin,
  searchAladin,
} from "../_shared/aladin.ts";
import { corsHeaders } from "../_shared/cors.ts";

interface SearchBody {
  mode: "search";
  query: string;
  page?: number;
  size?: number;
}

interface LookupBody {
  mode: "lookup";
  isbn: string;
}

type RequestBody = SearchBody | LookupBody;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return errorResponse("INVALID_INPUT", "POST만 허용", 405);
  }

  const ttbKey = Deno.env.get("ALADIN_TTB_KEY");
  if (!ttbKey) {
    return errorResponse(
      "UPSTREAM",
      "서버에 ALADIN_TTB_KEY가 설정되지 않았습니다.",
      500,
    );
  }

  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return errorResponse("INVALID_INPUT", "JSON 본문이 잘못됨", 400);
  }

  try {
    const result = await dispatch(body, ttbKey);
    return jsonResponse(result, 200);
  } catch (e) {
    if (e instanceof AladinError) {
      return errorResponse(e.code, e.message, e.status);
    }
    return errorResponse("UPSTREAM", `알 수 없는 오류: ${(e as Error).message}`, 500);
  }
});

async function dispatch(body: RequestBody, ttbKey: string): Promise<SearchResult> {
  if (body.mode === "search") {
    const query = (body.query ?? "").trim();
    if (query.length < 2) {
      throw new AladinError("INVALID_INPUT", "검색어는 최소 2자.", 400);
    }
    const page = sanitizePage(body.page);
    const size = sanitizeSize(body.size);
    return searchAladin({ ttbKey, query, page, size });
  }
  if (body.mode === "lookup") {
    const isbn = (body.isbn ?? "").trim();
    if (!isbn) throw new AladinError("INVALID_INPUT", "ISBN 누락.", 400);
    return lookupAladin({ ttbKey, isbn });
  }
  throw new AladinError("INVALID_INPUT", "mode는 'search' 또는 'lookup'.", 400);
}

function sanitizePage(v: unknown): number {
  const n = Number(v ?? 1);
  if (!Number.isFinite(n) || n < 1) return 1;
  return Math.min(Math.floor(n), 50); // 알라딘은 page 50까지만 의미 있음
}

function sanitizeSize(v: unknown): number {
  const n = Number(v ?? 20);
  if (!Number.isFinite(n) || n < 1) return 20;
  return Math.min(Math.floor(n), 50);
}

function jsonResponse(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorResponse(code: string, message: string, status: number): Response {
  return jsonResponse({ error: { code, message } }, status);
}
