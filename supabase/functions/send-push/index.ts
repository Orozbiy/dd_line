import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { GoogleAuth } from "npm:google-auth-library@9";

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

    // Алуучунун чыныгы окулбаган билдирүүлөрүн санайбыз
    console.log("STEP4b: counting unread messages for uid=" + uid);
    let unreadBadge = 1;
    try {
      const { data: chatRows } = await sb
        .from("chats")
        .select("id")
        .or(`buyer_id.eq.${uid},seller_id.eq.${uid}`);
      const chatIds = (chatRows ?? []).map((r: any) => r.id as string);
      if (chatIds.length > 0) {
        const { count } = await sb
          .from("messages")
          .select("id", { count: "exact", head: true })
          .in("chat_id", chatIds)
          .eq("is_read", false)
          .neq("sender_id", uid);
        unreadBadge = count ?? 1;
      } else {
        unreadBadge = 0;
      }
    } catch (badgeErr) {
      console.log("STEP4b badge count ката: " + String(badgeErr));
      unreadBadge = 1;
    }
    console.log("STEP4b: unreadBadge=" + unreadBadge);

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
                payload: { aps: { sound: "default" } },
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
  console.log("OAuth: creating GoogleAuth client");
  const auth = new GoogleAuth({
    credentials: sa,
    scopes: ["https://www.googleapis.com/auth/firebase.messaging"],
  });
  const client = await auth.getClient();
  console.log("OAuth: getting access token");
  const tokenRes = await client.getAccessToken();
  console.log("OAuth: token received=" + !!tokenRes.token);
  if (!tokenRes.token) throw new Error("Failed to get access token from GoogleAuth");
  return tokenRes.token;
}
