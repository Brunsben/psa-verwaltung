<template>
  <div v-if="isOffline"
    class="sticky top-0 z-40 bg-amber-50 dark:bg-amber-900/30 border-b border-amber-200 dark:border-amber-700 px-4 py-2 flex items-center justify-center gap-2 text-amber-800 dark:text-amber-300 text-sm">
    <i class="ph ph-wifi-slash"></i>
    <span>Offline – Daten vom {{ offlineTimestamp ? new Date(offlineTimestamp).toLocaleString('de-DE') : '?' }}. Änderungen nicht möglich.</span>
  </div>
</template>

<script setup>
import { isOffline, offlineTimestamp } from '../../store.js'
</script>
