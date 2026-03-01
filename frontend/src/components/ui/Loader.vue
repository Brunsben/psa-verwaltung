<template>
  <div v-if="loading" class="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-40">
    <div class="bg-white dark:bg-gray-800 rounded-xl px-6 py-4 shadow-2xl text-gray-600 dark:text-gray-300 text-sm flex items-center gap-3">
      <i class="ph ph-spinner-gap text-xl text-red-600 animate-spin"></i>
      Lade…
    </div>
  </div>
</template>

<script setup>
import { loading } from '../../store.js'
</script>
