Deno.serve(async (req) => {
  const url = new URL(req.url);
  const ok = url.searchParams.get('payment') === 'success';
  return new Response(`<!doctype html><html lang="de"><meta charset="utf-8"><title>Nexus Plus</title><style>body{font-family:Segoe UI,Arial;background:#071018;color:#effcff;text-align:center;padding:70px}div{max-width:620px;margin:auto;background:#0b141e;border:1px solid #20404c;border-radius:20px;padding:35px}h1{color:#20ddff}p{color:#9db0ba}</style><div><h1>${ok ? 'Zahlung erfolgreich' : 'Zahlung abgebrochen'}</h1><p>${ok ? 'Dein Nexus Plus wird nach der Zahlungsbestätigung automatisch freigeschaltet. Kehre jetzt zu Nexus zurück und klicke auf „Status prüfen“.' : 'Die Zahlung wurde abgebrochen. Du kannst Nexus Plus später erneut öffnen.'}</p></div></html>`, { headers: { 'Content-Type': 'text/html; charset=utf-8' } });
});
