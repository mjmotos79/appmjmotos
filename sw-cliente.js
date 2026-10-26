/* O QUE É: o "porteiro" do app do CLIENTE. Guarda a tela, a logo e as fontes para o app abrir rápido.
   Os dados da moto (Supabase) nunca ficam guardados: o cliente sempre vê a situação de agora.
   Ao publicar versão nova, troque o número em V. */
const V='mjm-cli-v7';
const SHELL=['./','./index.html','./manifest-cliente.json','./logo.png','./logo-3d.png','./icone-192.png','./icone-512.png'];
self.addEventListener('install',e=>{e.waitUntil((async()=>{const c=await caches.open(V);
 await Promise.all(SHELL.map(u=>c.add(u).catch(()=>{})));self.skipWaiting()})())});
self.addEventListener('activate',e=>e.waitUntil((async()=>{
 for(const k of await caches.keys())if(k!==V)await caches.delete(k);await self.clients.claim()})()));
self.addEventListener('fetch',e=>{
 const r=e.request;if(r.method!=='GET')return;const u=new URL(r.url);
 if(u.hostname.endsWith('supabase.co')||u.pathname.includes('/celular/')||u.pathname.includes('/downloads/')||u.pathname.endsWith('/instalar.html'))return;
 const meu=u.origin===location.origin;
 if(!meu&&!/(^|\.)fonts\.(googleapis|gstatic)\.com$/.test(u.hostname))return;
 e.respondWith((async()=>{const c=await caches.open(V);
  const hit=await c.match(r,{ignoreSearch:meu});
  const net=fetch(r).then(x=>{if(x&&(x.ok||x.type==='opaque'))c.put(r,x.clone());return x}).catch(()=>null);
  if(hit){e.waitUntil(net);return hit}
  if(r.mode==='navigate'){const i=await c.match('./index.html');if(i)return(await net)||i}
  return(await net)||new Response('Sem internet',{status:503})})())});
