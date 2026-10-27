/* O QUE É: o "porteiro" do app. Guarda no celular os arquivos do app (tela, logo, fontes, biblioteca do Supabase).
   PARA QUE SERVE: o app abre mesmo sem internet. Quando você publicar uma versão nova, troque o número em V para o celular atualizar. */
const V='mjm-v11';
const SHELL=['./','./index.html','./manifest.json','./logo.png','./icone-192.png','./icone-512.png'];
const EXT=['https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js',
 'https://fonts.googleapis.com/css2?family=Barlow:wght@400;500;600&family=Barlow+Condensed:ital,wght@1,700;1,800&display=swap'];
self.addEventListener('install',e=>{e.waitUntil((async()=>{const c=await caches.open(V);
 await Promise.all(SHELL.map(u=>c.add(u).catch(()=>{})));
 await Promise.all(EXT.map(u=>fetch(u,{mode:'no-cors'}).then(r=>c.put(u,r)).catch(()=>{})));
 self.skipWaiting()})())});
self.addEventListener('activate',e=>e.waitUntil((async()=>{
 for(const k of await caches.keys())if(k!==V)await caches.delete(k);await self.clients.claim()})()));
self.addEventListener('fetch',e=>{
 const r=e.request;if(r.method!=='GET')return;const u=new URL(r.url);
 if(u.hostname.endsWith('supabase.co'))return; /* dados nunca passam pelo cache do porteiro */
 const meu=u.origin===location.origin;
 if(!meu&&!/(^|\.)jsdelivr\.net$|(^|\.)fonts\.(googleapis|gstatic)\.com$/.test(u.hostname))return;
 e.respondWith((async()=>{const c=await caches.open(V);
  /* a TELA (html) tenta primeiro a internet: assim, versão nova no Netlify aparece na hora, sem reinstalar. Sem internet, usa a guardada. */
  if(meu&&(r.mode==='navigate'||/\.html$|\/$/.test(u.pathname))){
   try{const x=await fetch(r,{cache:'no-store'});if(x&&x.ok){c.put(r,x.clone());return x}}catch{}
   return(await c.match(r,{ignoreSearch:true}))||(await c.match('./index.html'))||new Response('Sem internet',{status:503})}
  let hit=await c.match(r,{ignoreSearch:meu});
  if(!hit&&r.mode==='navigate')hit=await c.match('./index.html');
  const net=fetch(r).then(x=>{if(x&&(x.ok||x.type==='opaque'))c.put(r,x.clone());return x}).catch(()=>null);
  if(hit){e.waitUntil(net);return hit}
  return(await net)||new Response('Sem internet',{status:503})})())});
