/// <reference types="vite/client" />

// Globale Typen für Vendor-Bibliotheken (werden als <script> in index.html geladen)
declare global {
  interface Window {
    CONFIG: { api: string }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    jspdf: { jsPDF: new (...args: any[]) => any }
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Chart: new (...args: any[]) => any
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Html5Qrcode: new (...args: any[]) => any
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    Html5QrcodeScanner: new (...args: any[]) => any
  }
}

export {}
