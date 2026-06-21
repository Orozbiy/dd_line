// @ts-ignore
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// @ts-ignore
Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      // @ts-ignore
      Deno.env.get('SUPABASE_URL')!,
      // @ts-ignore
      Deno.env.get('SERVICE_ROLE_KEY')!,
    );

    const { data: products, error: fetchError } = await supabase
      .from('buyer_keys')
      .select('product_id')
      .order('product_id');

    if (fetchError) {
      return new Response(JSON.stringify({ error: fetchError.message }), {
        status: 500,
        headers: corsHeaders,
      });
    }

    const uniqueIds = [...new Set((products ?? []).map((r: any) => r.product_id))];

    if (uniqueIds.length === 0) {
      return new Response(JSON.stringify({ success: true, updated: 0 }), {
        status: 200,
        headers: corsHeaders,
      });
    }

    let updated = 0;
    for (const productId of uniqueIds) {
      const { error } = await supabase.rpc('refresh_buyer_rankings', {
        p_product_id: productId,
      });
      if (!error) updated++;
    }

    console.log(`✅ refresh-rankings: ${updated}/${uniqueIds.length} товар жаңыланды`);

    return new Response(
      JSON.stringify({ success: true, updated, total: uniqueIds.length }),
      { status: 200, headers: corsHeaders },
    );
  } catch (e) {
    console.error('❌ refresh-rankings ката:', e);
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: corsHeaders,
    });
  }
});