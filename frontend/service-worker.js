// PSA-Verwaltung Service Worker – Offline-Cache
const CACHE_NAME = 'psa-v10';

// Vendor-Dateien vorladen (ändern sich nie, kein Inhaltshash im Namen)
const VENDOR_ASSETS = [
  '/vendor/chart.umd.min.js',
  '/vendor/jspdf.umd.min.js',
  '/vendor/html5-qrcode.min.js',
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
// - API:              immer Netzwerk
// - Navigation (HTML): Network-first → deckt alle SPA-Routen ab
// - config.js:        Network-first
// - /assets/ (Vite):  Cache-first (Inhaltshash im Namen → unveränderlich)
// - Vendor-Dateien:   Cache-first
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

  // Navigation (alle HTML-Seiten der SPA): Network-first
  // Stellt sicher dass index.html immer frisch geladen wird,
  // auch für Routen wie /kameraden, /ausruestung etc.
  if (e.request.mode === 'navigate') {
    e.respondWith(
      fetch(e.request).catch(() => caches.match('/index.html'))
    );
    return;
  }

  // config.js: Network-first (Laufzeitkonfiguration)
  if (url.pathname === '/config.js') {
    e.respondWith(
      fetch(e.request).catch(() => caches.match(e.request))
    );
    return;
  }

  // Cache-first für alles andere (Vite-Bundles, Vendor-Dateien)
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
