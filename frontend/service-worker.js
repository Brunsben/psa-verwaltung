// PSA-Verwaltung Service Worker – Offline-Cache
const CACHE_NAME = 'psa-v3';
const ASSETS = [
  '/',
  '/index.html',
  '/config.js',
  '/vendor/tailwind.cdn.js',
  '/vendor/vue.global.prod.js',
  '/manifest.json',
];

// Install: statische Assets cachen
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

// Activate: alte Caches löschen
self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys().then(keys =>
      Promise.all(keys.filter(k => k !== CACHE_NAME).map(k => caches.delete(k)))
    )
  );
  self.clients.claim();
});

// Fetch: Network-first für API, Cache-first für Assets
self.addEventListener('fetch', e => {
  const url = new URL(e.request.url);

  // API-Calls immer über Netzwerk
  if (url.pathname.startsWith('/api/')) {
    e.respondWith(
      fetch(e.request).catch(() =>
        new Response(JSON.stringify({ error: 'Offline' }), {
          status: 503,
          headers: { 'Content-Type': 'application/json' },
        })
      )
    );
    return;
  }

  // Statische Assets: Cache-first, dann Netzwerk
  e.respondWith(
    caches.match(e.request).then(cached => {
      const networkFetch = fetch(e.request).then(response => {
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        }
        return response;
      }).catch(() => cached);
      return cached || networkFetch;
    })
  );
});
