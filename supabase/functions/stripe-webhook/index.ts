import Stripe from 'npm:stripe@18.5.0';
import { createClient } from 'npm:@supabase/supabase-js@2.57.0';

Deno.serve(async (req) => {
  const signature = req.headers.get('Stripe-Signature');
  const body = await req.text();
  if (!signature) return new Response('Missing Stripe-Signature', { status: 400 });
  try {
    const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2025-07-30.basil' });
    const event = await stripe.webhooks.constructEventAsync(body, signature, Deno.env.get('STRIPE_WEBHOOK_SECRET')!);
    if (event.type === 'checkout.session.completed') {
      const session = event.data.object as Stripe.Checkout.Session;
      const userId = session.client_reference_id || session.metadata?.user_id;
      const isFiveEuro = session.amount_total === 500 && session.currency === 'eur';
      const isNexusPlus = session.metadata?.product === 'nexus_plus' || (!!session.payment_link && isFiveEuro);
      if (session.payment_status === 'paid' && userId && isFiveEuro && isNexusPlus) {
        const admin = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
        await admin.rpc('grant_nexus_plus', { p_user_id: userId });
      }
    }
    return new Response(JSON.stringify({ received: true }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  } catch (e) {
    return new Response(`Webhook error: ${String(e?.message || e)}`, { status: 400 });
  }
});
