/* CyberGaeco: rede primeiro (pega sempre a versão nova), cache como reserva para funcionar sem internet */
const C = 'cybergaeco-1795222597';
const ARQ = ['./', './index.html', './slides.html', './manifest.webmanifest', './manifest-slides.webmanifest', './icon-192.png', './icon-512.png'];
self.addEventListener('install', e => { self.skipWaiting(); e.waitUntil(caches.open(C).then(c => c.addAll(ARQ)).catch(() => {})); });
self.addEventListener('activate', e => { e.waitUntil(self.clients.claim()); });
self.addEventListener('fetch', e => {
  if (e.request.method !== 'GET') return;
  e.respondWith(
    Promise.race([fetch(e.request, { cache: 'no-store' }), new Promise((_, rej) => setTimeout(() => rej('lento'), 6000))])
      .then(r => { if (r && r.ok) { const cp = r.clone(); caches.open(C).then(c => c.put(e.request, cp)); } return r; })
      .catch(() => caches.match(e.request, { ignoreSearch: true }).then(r => r || caches.match('./index.html')))
  );
});
