import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

if (!window.CONFIG) {
  document.body.innerHTML = '<div style="padding:2rem;font-family:sans-serif;color:#dc2626">' +
    '<h1>Konfiguration fehlt</h1>' +
    '<p>config.js nicht geladen. Bitte <code>setup/configure-frontend.sh</code> ausführen.</p>' +
    '</div>'
  throw new Error('config.js nicht geladen.')
}

createApp(App).mount('#app')

// Service Worker registrieren (PWA Offline-Support)
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js').catch(() => {
      // Kein Fehler werfen – App funktioniert auch ohne SW
    })
  })
}
