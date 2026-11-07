// @ts-nocheck
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const BOT_TOKEN = '8515953899:AAHjbB1KONWQ8uwt3COKA3Q-AIuc1omA2XU'
const ADMIN_CHAT_ID = '5416220224'

Deno.serve(async (req) => {
  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    const body = await req.json()
    const callback = body.callback_query
    if (!callback) return new Response('ok')

    const data  = callback.data
    const msgId = callback.message.message_id
    const [action, sellerId] = data.split(':')

    if (action === 'approve') {
      // ✅ 'active' эмес 'approved' — Flutter моделине дал келет
      await supabase
        .from('profiles')
        .update({ seller_status: 'approved' })
        .eq('id', sellerId)

      await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/editMessageText`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: ADMIN_CHAT_ID,
          message_id: msgId,
          text: '✅ Сатуучу активдештирилди!',
        })
      })

   } else if (action === 'reject') {
  // profiles таблицасын жаңылт
  await supabase
    .from('profiles')
    .update({ seller_status: 'rejected' })
    .eq('id', sellerId)

  // ✅ Auth'тан да өчүр
  await supabase.auth.admin.deleteUser(sellerId)

  await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/editMessageText`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      chat_id: ADMIN_CHAT_ID,
      message_id: msgId,
      text: '❌ Сатуучу четке кагылды жана өчүрүлдү!',
    })
  })
}

    await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/answerCallbackQuery`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ callback_query_id: callback.id })
    })

    return new Response('ok')
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 })
  }
})