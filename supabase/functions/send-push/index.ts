import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });
  try {
    console.log("STEP1: parsing body");
    const b = await req.json();
    const uid = b.receiver_uid ?? b.receiverUid;
    const title = b.title;
    const body = b.body;
    const chatId = b.chat_id ?? b.chatId ?? "";
    console.log("STEP2: uid=" + uid);

    const sb = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    console.log("STEP3: querying push_tokens");
    const { data: tokens, error: tokErr } = await sb
      .from("push_tokens")
      .select("token")
      .eq("user_id", uid);
    console.log("STEP4: tokens=" + JSON.stringify(tokens) + " err=" + JSON.stringify(tokErr));

    if (!tokens || tokens.length === 0)
      return new Response(JSON.stringify({ sent: 0, reason: "no tokens" }), {
        status: 200,
        headers: { ...CORS, "Content-Type": "application/json" },
      });

    console.log("STEP5: parsing FCM_SERVICE_ACCOUNT");
    const raw = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (!raw) throw new Error("FCM_SERVICE_ACCOUNT not set");
    const sa = JSON.parse(raw);
    console.log("STEP6: project_id=" + sa.project_id);

    console.log("STEP7: getting OAuth token");
    const accessToken = await getAccessToken(sa);
    console.log("STEP8: got OAuth token");

    let success = 0;
    for (const { token } of tokens) {
      console.log("STEP9: sending FCM token=" + token.substring(0, 20));
      const res = await fetch(
        `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: "Bearer " + accessToken,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token,
              notification: { title, body },
              android: {
                priority: "high",
                notification: {
                  channel_id: "chat_messages",
                  sound: "default",
                  notification_priority: "PRIORITY_MAX",
                  default_vibrate_timings: true,
                },
              },
              apns: {
                payload: { aps: { sound: "default", badge: 1 } },
                headers: { "apns-priority": "10" },
              },
              data: {
                chatId,
                type: "chat_message",
                title: title ?? "",
                body: body ?? "",
                click_action: "FLUTTER_NOTIFICATION_CLICK",
              },
            },
          }),
        }
      );
      const rt = await res.text();
      console.log("STEP10: FCM status=" + res.status + " body=" + rt.substring(0, 300));
      if (res.ok) success++;
    }

    return new Response(JSON.stringify({ sent: success }), {
      status: 200,
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error("ERR: " + String(e));
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...CORS, "Content-Type": "application/json" },
    });
  }
});

async function getAccessToken(sa: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iss: sa.client_email,
    sub: sa.client_email,
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
  };
  const enc = new TextEncoder();
  const b64 = (s: string) =>
    btoa(s).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
  const h = b64(JSON.stringify(header));
  const p = b64(JSON.stringify(payload));
  const keyData = sa.private_key
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");
  const binaryKey = Uint8Array.from(atob(keyData), (c) => c.charCodeAt(0));
  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", cryptoKey, enc.encode(h + "." + p))
  );
  const s = b64(String.fromCharCode(...sig));
  const jwt = h + "." + p + "." + s;

  console.log("OAuth: calling google token endpoint");
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      "grant_type=urn:ietf:params:oauth2:grant-type:jwt-bearer&assertion=" + jwt,
  });
  const j = await res.json();
  console.log("OAuth: response=" + JSON.stringify(j).substring(0, 150));
  if (!j.access_token) throw new Error("oauth error: " + JSON.stringify(j));
  return j.access_token;
}
