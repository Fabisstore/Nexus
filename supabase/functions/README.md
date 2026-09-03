# Nexus Plus Zahlungsfunktionen

Diese drei Edge Functions gehören zusammen:
- create-nexus-plus-checkout: erstellt eine Stripe Checkout Session für eine einmalige Zahlung von 5,00 €.
- stripe-webhook: bestätigt die Zahlung und setzt `profiles.nexus_plus = true`.
- payment-return: zeigt nach Stripe eine einfache Rückmeldung.

Benötigte Supabase Secrets:
- STRIPE_SECRET_KEY
- STRIPE_WEBHOOK_SECRET
- SUPABASE_SERVICE_ROLE_KEY
- NEXUS_PUBLIC_RETURN_URL (optional; sonst wird die payment-return Function verwendet)

Stripe Webhook Event: `checkout.session.completed`.
