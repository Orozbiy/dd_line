// @ts-nocheck
// Чат билдирүүсү үчүн push жөнөтөт (FCM v1).
// Керектүү secrets:
//   FCM_SERVICE_ACCOUNT = Firebase service-account JSON (толугу менен)
//   SERVICE_ROLE_KEY    = Supabase service role key
// Чакыруу: supabase.functions.invoke('send-push', body: {receiverUid, title, body, chatId})

const PROJECT_ID = 'dd-online-web'
const CORS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === 'string' ? new TextEncoder().encode(data) : data
  let s = ''
  for (const b of bytes) s += String.fromCharCode(b)
  return btoa(s).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
}

async function getAccessToken(sa: any): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const claim = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }))
  const pem = sa.private_key
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0))
  const key = await crypto.subtle.importKey(
    'pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign'])
  const sig = new Uint8Array(await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(`${header}.${claim}`)))
  const jwt = `${header}.${claim}.${b64url(sig)}`
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const j = await res.json()
  if (!j.access_token) throw new Error('oauth: ' + JSON.stringify(j))
  return j.access_token
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS })
  const json = (obj: any, status = 200) =>
    new Response(JSON.stringify(obj), { status, headers: { ...CORS, 'Content-Type': 'application/json' } })

  try {
    const url = Deno.env.get('SUPABASE_URL')!
    const serviceKey = Deno.env.get('SERVICE_ROLE_KEY')!
    const authHeader = req.headers.get('Authorization') ?? ''

    // 1) Чакырган колдонуучуну текшерүү
    const uRes = await fetch(`${url}/auth/v1/user`, {
      headers: { Authorization: authHeader, apikey: serviceKey },
    })
    if (!uRes.ok) return json({ error: 'unauthorized' }, 401)
    const caller = await uRes.json()

    const { receiverUid, title, body, chatId } = await req.json()
    if (!receiverUid || !chatId) return json({ error: 'bad request' }, 400)

    const rest = (path: string) =>
      fetch(`${url}/rest/v1/${path}`, {
        headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
      }).then((r) => r.json())

    // 2) Чат катышуучулары гана (чакыруучу жана алуучу ушул чаттын экөөнүн бири)
    const chats = await rest(`chats?id=eq.${encodeURIComponent(chatId)}&select=buyer_id,seller_id`)
    const chat = Array.isArray(chats) ? chats[0] : null
    if (!chat) return json({ error: 'chat not found' }, 404)
    const members = [chat.buyer_id, chat.seller_id]
    if (!members.includes(caller.id) || !members.includes(receiverUid) || caller.id === receiverUid) {
      return json({ error: 'forbidden' }, 403)
    }

    // 3) Токендер
    const rows = await rest(`push_tokens?user_id=eq.${receiverUid}&select=token`)
    const tokens = (Array.isArray(rows) ? rows : []).map((r: any) => r.token).filter(Boolean)
    if (tokens.length === 0) return json({ sent: 0, reason: 'no tokens' })

    const sa = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT')!)
    const accessToken = await getAccessToken(sa)

    let sent = 0
    for (const token of tokens) {
      const res = await fetch(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: {
            token,
            notification: { title, body },
            android: {
              priority: 'high',
              notification: {
                channel_id: 'chat_messages',
                sound: 'default',
                default_vibrate_timings: true,
                notification_priority: 'PRIORITY_MAX',
                visibility: 'PUBLIC',
                click_action: 'FLUTTER_NOTIFICATION_CLICK',
              },
            },
            apns: {
              payload: { aps: { sound: 'default', badge: 1, 'content-available': 1 } },
              headers: { 'apns-priority': '10' },
            },
            data: {
              chatId: String(chatId),
              type: 'chat_message',
              senderName: String(title ?? ''),
              title: String(title ?? ''),
              body: String(body ?? ''),
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
          },
        }),
      })
      if (res.ok) {
        sent++
      } else {
        const txt = await res.text()
        if (res.status === 404 || txt.includes('UNREGISTERED')) {
          await fetch(`${url}/rest/v1/push_tokens?token=eq.${encodeURIComponent(token)}`, {
            method: 'DELETE',
            headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
          })
        }
      }
    }
    return json({ sent })
  } catch (e) {
    return json({ error: String(e?.message ?? e) }, 500)
  }
})
