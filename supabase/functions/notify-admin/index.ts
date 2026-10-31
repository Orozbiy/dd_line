// @ts-nocheck
const BOT_TOKEN = '8515953899:AAHjbB1KONWQ8uwt3COKA3Q-AIuc1omA2XU'
const ADMIN_CHAT_ID = '5416220224'

Deno.serve(async (req) => {
  try {
    const { sellerName, phone, shopName, container, sellerId } = await req.json()

    const text = `🆕 Жаңы сатуучу катталды!\n\n👤 Аты: ${sellerName}\n📞 Телефон: ${phone}\n🏪 Дүкөн: ${shopName}\n📍 Контейнер: ${container}\n🆔 ID: ${sellerId}`

    await fetch(`https://api.telegram.org/bot${BOT_TOKEN}/sendMessage`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        chat_id: ADMIN_CHAT_ID,
        text,
        reply_markup: {
          inline_keyboard: [[
            { text: '✅ Активдештирүү', callback_data: `approve:${sellerId}` },
            { text: '❌ Четке кагуу',   callback_data: `reject:${sellerId}`  }
          ]]
        }
      })
    })

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' }
    })
  } catch (e) {
    return new Response(JSON.stringify({ error: e.message }), { status: 500 })
  }
})