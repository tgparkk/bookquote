// Edge Function: delete-account
//
// 호출자 본인 계정을 영구 삭제한다 (in-app 계정 삭제 — Apple Guideline 5.1.1(v) +
// Google Play 둘 다 요구. 클라이언트는 `auth.admin.deleteUser`를 직접 못 부르므로
// service_role 키를 가진 이 함수가 대행한다).
//
// 흐름:
//   1. Authorization 헤더의 JWT로 호출자(user)를 확인 (게이트웨이가 JWT 서명은 이미 검증).
//   2. service_role 클라이언트로 `auth.admin.deleteUser(user.id)`.
//      → auth.users 삭제 시 quotes·user_books·profiles가 `on delete cascade`로 함께 삭제.
//
// 입력:  POST /functions/v1/delete-account   (본문 없음, Authorization: Bearer <user JWT>)
// 출력:  성공 { ok: true } / 실패 { error: { code, message } } + HTTP status
//
// 환경 변수(Edge Function에 자동 주입): SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return errorResponse("INVALID_INPUT", "POST만 허용", 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return errorResponse("UNAUTHORIZED", "로그인이 필요해요.", 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceKey) {
    return errorResponse("CONFIG", "서버 설정이 누락됐어요.", 500);
  }

  // 1. 호출자 확인
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: { user }, error: userErr } = await userClient.auth.getUser();
  if (userErr || !user) {
    return errorResponse("UNAUTHORIZED", "세션이 유효하지 않아요.", 401);
  }

  // 2. service_role로 삭제 (cascade가 데이터 정리)
  const admin = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { error: delErr } = await admin.auth.admin.deleteUser(user.id);
  if (delErr) {
    return errorResponse("DELETE_FAILED", delErr.message, 500);
  }

  return jsonResponse({ ok: true }, 200);
});

function jsonResponse(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorResponse(code: string, message: string, status: number): Response {
  return jsonResponse({ error: { code, message } }, status);
}
