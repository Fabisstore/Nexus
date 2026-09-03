# Nexus – Windows Installer & Updates

## Einmalige Einrichtung

1. Dieses Projekt in ein GitHub-Repository namens `Nexus` unter dem Konto `Fabisstore` hochladen.
2. GitHub Actions aktiv lassen.
3. Einen Tag wie `v0.4.0` veröffentlichen.
4. Der Workflow baut auf einem echten Windows-Runner den NSIS-Installer und veröffentlicht ihn als GitHub Release.

## Für Nutzer

Die Datei `Nexus-Setup-0.4.0.exe` wird einmal installiert. Danach ist Nexus normal über Startmenü/Desktop erreichbar.

## Updates

Für eine neue Version die Versionsnummer in `package.json` erhöhen und einen Tag mit `v` davor veröffentlichen, z.B. `v0.4.1`.
GitHub baut daraus automatisch einen neuen Release.
Installierte Nexus-Versionen prüfen automatisch auf Updates. Bei einem verfügbaren Update kann die App den Download starten und nach Bestätigung neu starten.

## Hinweis

Der Installer kann hier nicht lokal erzeugt werden, weil diese Entwicklungsumgebung kein Windows-Buildsystem besitzt. Der GitHub-Windows-Runner übernimmt genau diesen Schritt.


## V23 – Nexus Plus
1. In Supabase zuerst `supabase-v23.sql` komplett ausführen.
2. Die drei Edge Functions aus `supabase/functions/` bereitstellen.
3. In Supabase Secrets setzen: `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `SUPABASE_SERVICE_ROLE_KEY`.
4. In Stripe einen Webhook auf `.../functions/v1/stripe-webhook` anlegen und `checkout.session.completed` aktivieren.
5. Danach die V23-Dateien ins GitHub-Repository hochladen und den Windows-Build starten.

Die Zahlungsbestätigung erfolgt serverseitig über den Stripe-Webhook; ein bloßes Klicken auf „Status prüfen“ schaltet Plus nicht frei.
