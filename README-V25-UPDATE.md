# Nexus V25 – Update

## Enthalten
- Nexus Plus ist serverseitig gesperrt, bis `profiles.nexus_plus = true` gesetzt wurde.
- Kleiner Nexus-Plus-Bereich auf der Startseite.
- Nexus Office nur bei aktivem Plus.
- Live-Stripe-Payment-Link mit `client_reference_id` pro eingeloggtem Nutzer.
- Gruppenchat-Oberfläche + Supabase-RPC/RLS.
- Bekannte Profil-, Storage- und Chat-Grundlagen aus den vorherigen Versionen beibehalten.

## Supabase
1. `supabase-v25.sql` im Supabase SQL Editor ausführen.
2. Stripe Edge Functions/Secrets aus dem bisherigen Projekt bereitstellen.
3. Stripe Webhook auf `stripe-webhook` für `checkout.session.completed` setzen.

## Wichtig
Die Freischaltung darf ausschließlich serverseitig nach bestätigter Stripe-Zahlung erfolgen. Die Oberfläche allein gewährt keinen Plus-Zugriff.
