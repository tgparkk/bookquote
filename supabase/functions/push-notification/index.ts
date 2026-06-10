// PR-PC: notifications insert → FCM 푸시 발송 Edge Function.
//
// 트리거: public.notifications INSERT Database Webhook (POST { type, record }).
// 동작: 수신자 푸시 prefs 확인 → device_tokens 조회 → 메시지 구성(actor 비공개면
//       익명) → FCM HTTP v1 /messages:send (서비스계정 OAuth2) → stale 토큰 정리.
//
// 보안: verify_jwt=false로 배포하고(웹훅은 사용자 JWT 없음) 공유 시크릿 헤더
//       x-webhook-secret == WEBHOOK_SECRET로 게이트.
//
// 필요한 Edge secret:
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (기본 주입)
//   FCM_SERVICE_ACCOUNT  — Firebase 서비스계정 JSON 전체(문자열)
//   WEBHOOK_SECRET       — 웹훅 인증용 임의 문자열(웹훅 헤더와 일치)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_SERVICE_ACCOUNT = Deno.env.get("FCM_SERVICE_ACCOUNT")!;
const WEBHOOK_SECRET = Deno.env.get("WEBHOOK_SECRET") ?? "";

interface NotificationRecord {
  id: string;
  recipient_id: string;
  actor_id: string;
  type: "quote_like" | "review_like" | "follow";
  quote_id: string | null;
  review_id: string | null;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
}

const PREF_COLUMN: Record<NotificationRecord["type"], string> = {
  quote_like: "push_quote_like",
  review_like: "push_review_like",
  follow: "push_follow",
};

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "POST only" }, 405);
  }
  // 공유 시크릿 게이트.
  if (!WEBHOOK_SECRET || req.headers.get("x-webhook-secret") !== WEBHOOK_SECRET) {
    return json({ error: "unauthorized" }, 401);
  }

  let record: NotificationRecord;
  try {
    const body = await req.json();
    record = body.record ?? body;
  } catch {
    return json({ error: "bad payload" }, 400);
  }
  if (!record?.recipient_id || !record?.type) {
    return json({ error: "missing fields" }, 400);
  }

  const admin = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // 1) 수신자 푸시 prefs.
  const { data: prefs } = await admin
    .from("profiles")
    .select("push_enabled, push_quote_like, push_review_like, push_follow")
    .eq("id", record.recipient_id)
    .maybeSingle();
  if (!prefs || prefs.push_enabled !== true) {
    return json({ skipped: "push disabled" }, 200);
  }
  if (prefs[PREF_COLUMN[record.type] as keyof typeof prefs] !== true) {
    return json({ skipped: "type disabled" }, 200);
  }

  // 2) 수신자 디바이스 토큰.
  const { data: tokenRows } = await admin
    .from("device_tokens")
    .select("token")
    .eq("user_id", record.recipient_id);
  const tokens = (tokenRows ?? []).map((r) => r.token as string);
  if (tokens.length === 0) {
    return json({ skipped: "no tokens" }, 200);
  }

  // 3) actor 표시 이름(비공개 프로필이면 익명).
  const { data: actor } = await admin
    .from("profiles")
    .select("display_name, is_library_public")
    .eq("id", record.actor_id)
    .maybeSingle();
  const actorName = actor?.is_library_public && actor?.display_name
    ? actor.display_name as string
    : "누군가";

  // 4) 라우트(탭 목적지) — 좋아요는 책 상세, 팔로우는 작성자 프로필.
  const route = await resolveRoute(admin, record);
  const body = messageBody(record.type, actorName);

  // 5) FCM 발송.
  const sa = JSON.parse(FCM_SERVICE_ACCOUNT) as ServiceAccount;
  const accessToken = await getAccessToken(sa);
  const endpoint =
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

  let sent = 0;
  const stale: string[] = [];
  for (const token of tokens) {
    const resp = await fetch(endpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title: "책글귀", body },
          data: { route, type: record.type, notification_id: record.id },
          android: { priority: "high" },
        },
      }),
    });
    if (resp.ok) {
      sent++;
    } else if (resp.status === 404 || resp.status === 400) {
      // UNREGISTERED(404) / invalid(400) → stale 토큰 정리.
      stale.push(token);
    }
  }
  if (stale.length > 0) {
    await admin.from("device_tokens").delete().in("token", stale);
  }

  return json({ sent, stale: stale.length, total: tokens.length }, 200);
});

function messageBody(type: NotificationRecord["type"], name: string): string {
  switch (type) {
    case "quote_like":
      return `${name}님이 회원님의 인용구를 좋아해요`;
    case "review_like":
      return `${name}님이 회원님의 후기를 좋아해요`;
    case "follow":
      return `${name}님이 회원님을 팔로우했어요`;
  }
}

async function resolveRoute(
  // deno-lint-ignore no-explicit-any
  admin: any,
  record: NotificationRecord,
): Promise<string> {
  if (record.type === "follow") return `/u/${record.actor_id}`;
  if (record.quote_id) {
    const { data } = await admin
      .from("quotes").select("book_id").eq("id", record.quote_id).maybeSingle();
    if (data?.book_id) return `/book/${data.book_id}`;
  }
  if (record.review_id) {
    const { data } = await admin
      .from("book_reviews").select("book_id").eq("id", record.review_id).maybeSingle();
    if (data?.book_id) return `/book/${data.book_id}`;
  }
  return "/notifications";
}

// ── 서비스계정 → FCM OAuth2 액세스 토큰 (RS256 JWT) ──────────
async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const claim = {
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };
  const enc = (o: unknown) => b64url(new TextEncoder().encode(JSON.stringify(o)));
  const unsigned = `${enc(header)}.${enc(claim)}`;

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${b64url(new Uint8Array(sig))}`;

  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!resp.ok) {
    throw new Error(`oauth token failed: ${resp.status} ${await resp.text()}`);
  }
  const { access_token } = await resp.json();
  return access_token as string;
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes.buffer;
}

function b64url(bytes: Uint8Array): string {
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function json(data: unknown, status: number): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
