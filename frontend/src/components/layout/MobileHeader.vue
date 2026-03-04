<template>
  <header class="md:hidden sticky top-0 z-50 bg-white dark:bg-gray-900 border-b border-gray-100 dark:border-gray-700 px-4 flex items-center gap-3 h-14">
    <button @click="sidebarOpen = true"
      class="p-2 rounded-lg text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors">
      <i class="ph ph-list text-xl"></i>
    </button>
    <span class="font-semibold text-gray-900 dark:text-white text-sm">FF Wietmarschen · PSA</span>
  </header>
</template>

<script setup>
import { sidebarOpen } from '../../store.js'
</script>
