/// <reference types="vite/client" />

interface PsaConfig {
  api: string
  feuerwehrName?: string
}

interface Window {
  CONFIG: PsaConfig
  jspdf: typeof import('jspdf')
  Chart: typeof import('chart.js')
  Html5Qrcode: unknown
  Html5QrcodeScanner: unknown
}
