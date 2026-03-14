import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

if (!window.CONFIG) {
  const errDiv = document.createElement('div')
  errDiv.style.cssText = 'padding:2rem;font-family:sans-serif;color:#dc2626'
  const h1 = document.createElement('h1')
  h1.textContent = 'Konfiguration fehlt'
  const p = document.createElement('p')
  p.textContent = 'config.js nicht geladen. Bitte setup/configure-frontend.sh ausführen.'
  errDiv.append(h1, p)
  document.body.replaceChildren(errDiv)
  throw new Error('config.js nicht geladen.')
}

createApp(App).mount('#app')

// Service Worker registrieren (PWA Offline-Support)
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    const base = import.meta.env.BASE_URL || '/';
    navigator.serviceWorker.register(`${base}service-worker.js`).catch(() => {
      // Kein Fehler werfen – App funktioniert auch ohne SW
    })
  })
}
