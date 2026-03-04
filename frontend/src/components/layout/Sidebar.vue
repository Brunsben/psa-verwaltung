<template>
  <aside :class="['fixed inset-y-0 left-0 z-40 w-56 bg-white dark:bg-gray-900 border-r border-gray-100 dark:border-gray-700 flex flex-col transition-transform duration-300 ease-in-out',
    sidebarOpen ? 'translate-x-0 shadow-2xl' : '-translate-x-full md:translate-x-0']">

    <!-- Logo -->
    <div class="flex items-center gap-3 px-5 py-5 border-b border-gray-100 dark:border-gray-800">
      <span class="text-xl">🔥</span>
      <div>
        <div class="font-bold text-gray-900 dark:text-white text-sm leading-tight">{{ feuerwehrName }}</div>
        <div class="text-xs text-gray-400 dark:text-gray-500">PSA-Verwaltung</div>
      </div>
    </div>

    <!-- Navigation -->
    <nav class="flex-1 py-3 px-3 space-y-0.5">
      <button v-for="p in visiblePages" :key="p.id"
        @click="page = p.id; sidebarOpen = false"
        :class="['w-full flex items-center gap-3 px-3 py-2.5 rounded-lg transition-colors text-sm font-medium text-left',
          page === p.id
            ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'
            : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-100']">
        <span class="nav-icon" v-html="p.icon"></span>
        {{ p.label }}
        <span v-if="p.id === 'warnungen' && warnungen.length"
          class="ml-auto bg-red-500 text-white text-xs font-bold rounded-full px-1.5 py-0.5 leading-none">
          {{ warnungen.length }}
        </span>
      </button>
    </nav>

    <!-- Aktionen unten -->
    <div class="p-3 border-t border-gray-100 dark:border-gray-800 space-y-0.5">
      <!-- QR-Scanner -->
      <button @click="$emit('openQr')"
        class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-100 transition-colors">
        <i class="ph ph-qr-code text-xl flex-shrink-0"></i>
        QR-Scanner
      </button>

      <!-- Dark Mode -->
      <button @click="toggleDark"
        class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-100 transition-colors">
        <i v-if="darkMode" class="ph ph-sun text-xl flex-shrink-0"></i>
        <i v-else class="ph ph-moon text-xl flex-shrink-0"></i>
        {{ darkMode ? 'Helles Design' : 'Dunkles Design' }}
      </button>

      <!-- Benutzer + Logout -->
      <div class="flex items-center gap-2 px-3 py-2 text-xs text-gray-400 dark:text-gray-500 mt-1">
        <i class="ph ph-user-circle text-base"></i>
        <span class="truncate flex-1">{{ currentUser?.Benutzername || '–' }}</span>
        <span v-if="currentUser?.Rolle"
          class="text-xs bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 px-1.5 py-0.5 rounded font-semibold">
          {{ currentUser.Rolle }}
        </span>
      </div>
      <button @click="openPasswortForm"
        class="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-800 hover:text-gray-900 dark:hover:text-gray-100 transition-colors">
        <i class="ph ph-key text-lg flex-shrink-0"></i>
        Passwort ändern
      </button>
      <button @click="doLogout"
        class="w-full flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium text-gray-500 dark:text-gray-400 hover:bg-red-50 dark:hover:bg-red-900/20 hover:text-red-600 dark:hover:text-red-400 transition-colors">
        <i class="ph ph-sign-out text-lg flex-shrink-0"></i>
        Abmelden
      </button>
    </div>
  </aside>

  <!-- Mobile Overlay -->
  <div v-if="sidebarOpen" @click="sidebarOpen = false"
    class="fixed inset-0 bg-black/50 backdrop-blur-sm z-30 md:hidden"></div>
</template>

<script setup>
import {
  page, sidebarOpen, visiblePages, warnungen,
  darkMode, toggleDark, currentUser, doLogout, openPasswortForm, feuerwehrName,
} from '../../store.js'

defineEmits(['openQr'])
</script>
