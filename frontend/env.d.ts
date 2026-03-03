/// <reference types="vite/client" />

// Globale Typen für Vendor-Bibliotheken (werden als <script> in index.html geladen)
declare const Chart: unknown
declare const jspdf: unknown
declare const Html5Qrcode: unknown
declare const Html5QrcodeScanner: unknown

// Runtime-Konfiguration (config.js, generiert durch configure-frontend.sh)
interface Window {
  CONFIG: {
    api: string
  }
}
