# Nexus by Fabisstore — V18

Nexus is a Windows desktop communication app backed by Supabase.

## V18 scope
- Private text chat with image/video/file attachments
- Community text channels
- Community voice channels
- Microphone and camera controls
- Screen sharing through WebRTC
- Voice/video rooms using Supabase Realtime signaling
- Community editing
- Create/edit/delete community channels
- Community accent-color design
- Supabase storage for media

## Supabase setup
Run `supabase-v18.sql` once in Supabase SQL Editor. It creates the media bucket/policies and the RPCs used by community/channel management.

The existing Nexus SQL setup from earlier versions remains required.

## Start
`npm install` then `npm start`.

## Important deployment note
WebRTC uses STUN for direct peer connections. Production worldwide calling should additionally use a TURN server for users behind restrictive NAT/firewalls. The UI is wired for microphone, camera and screen sharing, but a real two-device call still needs end-to-end network testing before a production release is honestly certified.

## Windows installer
The package already contains electron-builder configuration for a normal NSIS installer (`Nexus-Setup-<version>.exe`). A Windows build environment is required to produce the final installer artifact.


## Nexus Plus V23
Nexus Plus ist eine einmalige Zahlung von 5,00 €. Es gibt kein Monats- oder Jahresabo. Nach bestätigter Stripe-Zahlung wird `profiles.nexus_plus` serverseitig aktiviert. Nexus Office ist anschließend im Konto verfügbar.

Für die Live-Zahlung müssen die Supabase Edge Functions unter `supabase/functions/` deployed und die dort genannten Stripe/Supabase Secrets gesetzt werden. Die App enthält keine geheimen Stripe-Schlüssel.

Vor dem ersten Plus-Test: `supabase-v23.sql` im Supabase SQL Editor ausführen.
