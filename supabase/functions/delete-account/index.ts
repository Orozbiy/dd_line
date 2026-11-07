import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

/**
 * DELETE ACCOUNT Edge Function
 *
 * Колдонуучунун аккаунтун коопсуз жок кылуу.
 * Supabase Service Role Key менен иштейт — клиенттен эмес, серверден.
 *
 * Коопсуздук:
 * - JWT токен аркылуу аутентификация (Authorization header)
 * - Колдонуучу өзүнүн аккаунтун гана жок кыла алат
 * - Бардык колдонуучу дайындары (products, chats, favorites, push_tokens, profiles) жок кылынат
 * - Auth аккаунт толугу менен жок кылынат
 */

Deno.serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. JWT токенден колдонуучуну аныктоо
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Authorization header жок' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Колдонуучунун Supabase клиенти — JWT менен
    const supabaseUser = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      {
        global: { headers: { Authorization: authHeader } },
      }
    );

    const { data: { user }, error: userError } = await supabaseUser.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Колдонуучу табылган жок' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const userId = user.id;

    // 2. Service Role менен admin клиент — дайындарды жок кылуу үчүн
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SERVICE_ROLE_KEY')!,
    );

    // 3. Колдонуучунун бардык дайындарын жок кылуу (тартиби маанилүү — FK constraints)

    // 3a. Push токендерди жок кылуу
    await supabaseAdmin.from('push_tokens').delete().eq('user_id', userId);

    // 3b. Чат билдирүүлөрүн жок кылуу (жиберүүчү же алуучу катары)
    await supabaseAdmin.from('messages').delete().or(`sender_id.eq.${userId},receiver_id.eq.${userId}`);

    // 3c. Чат бөлмөлөрүн жок кылуу
    await supabaseAdmin.from('chat_rooms').delete().or(`user1_id.eq.${userId},user2_id.eq.${userId}`);

    // 3d. Сүйүктүүлөрдү жок кылуу
    await supabaseAdmin.from('favorites').delete().eq('user_id', userId);

    // 3e. Товарларды жок кылуу (сатуучу болсо)
    await supabaseAdmin.from('products').delete().eq('seller_id', userId);

    // 3f. Контейнерлерди жок кылуу (сатуучу болсо)
    await supabaseAdmin.from('containers').delete().eq('seller_id', userId);

    // 3g. Сунуштарды/даттанууларды жок кылуу
    await supabaseAdmin.from('complaints_suggestions').delete().eq('user_id', userId);

    // 3h. Профилди жок кылуу
    await supabaseAdmin.from('profiles').delete().eq('id', userId);

    // 4. Auth аккаунтту толугу менен жок кылуу
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(userId);
    if (deleteError) {
      return new Response(JSON.stringify({ error: `Auth жок кылууда ката: ${deleteError.message}` }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });

  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
