<template>
  <div v-if="show"
    class="sticky top-0 z-40 bg-blue-50 dark:bg-blue-900/30 border-b border-blue-200 dark:border-blue-700 px-4 py-2 flex items-center justify-between gap-3 text-blue-800 dark:text-blue-300 text-sm">
    <div class="flex items-center gap-2">
      <i class="ph ph-device-mobile text-base"></i>
      <span>App installieren für schnellen Zugriff vom Homescreen</span>
    </div>
    <div class="flex items-center gap-2 shrink-0">
      <button @click="install" class="px-3 py-1 rounded-lg bg-blue-600 text-white text-xs font-semibold hover:bg-blue-700 transition-colors">
        Installieren
      </button>
      <button @click="dismiss" class="icon-btn hover:text-blue-600 hover:bg-blue-100 dark:hover:bg-blue-900/40" title="Schließen">
        <i class="ph ph-x text-sm"></i>
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const show = ref(false)
let deferredPrompt = null

onMounted(() => {
  if (localStorage.getItem('pwa-install-dismissed')) return
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault()
    deferredPrompt = e
    show.value = true
  })
})

function install() {
  if (!deferredPrompt) return
  deferredPrompt.prompt()
  deferredPrompt.userChoice.then(() => {
    deferredPrompt = null
    show.value = false
  })
}

function dismiss() {
  show.value = false
  localStorage.setItem('pwa-install-dismissed', '1')
}
</script>
