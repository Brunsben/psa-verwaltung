// PSA-Verwaltung Service Worker – Offline-Cache
const CACHE_NAME = 'psa-v6';

// Nur schwere Vendor-Dateien cachen (ändern sich nie)
const VENDOR_ASSETS = [
  '/vendor/tailwind.min.css',
  '/vendor/vue.global.prod.js',
  '/vendor/chart.umd.min.js',
  '/vendor/phosphor/style.css',
  '/vendor/phosphor/Phosphor.woff2',
  '/manifest.json',
];

// Install: Vendor-Assets vorladen
self.addEventListener('install', e => {
  e.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(VENDOR_ASSETS))
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

// Fetch-Strategie:
// - API: immer Netzwerk
// - index.html + config.js: immer Netzwerk (damit Updates sofort wirken)
// - Vendor-Dateien: Cache-first (ändern sich nicht)
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

  // index.html und config.js: Network-first (immer aktuell)
  if (url.pathname === '/' || url.pathname === '/index.html' || url.pathname.startsWith('/config.js')) {
    e.respondWith(
      fetch(e.request).catch(() => caches.match(e.request))
    );
    return;
  }

  // Vendor-Dateien: Cache-first, dann Netzwerk
  e.respondWith(
    caches.match(e.request).then(cached => {
      if (cached) return cached;
      return fetch(e.request).then(response => {
        if (response.ok) {
          const clone = response.clone();
          caches.open(CACHE_NAME).then(cache => cache.put(e.request, clone));
        }
        return response;
      });
    })
  );
});
