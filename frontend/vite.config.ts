import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  base: '/psa/',
  plugins: [
    vue(),
    tailwindcss(),
  ],
  // Vendor-Libs (Chart.js, jsPDF, html5-qrcode) werden als globale
  // window.* Variablen aus public/vendor/ geladen – nicht von Vite gebundled
  build: {
    outDir: 'dist',
    rollupOptions: {
      external: [],
    },
  },
})
