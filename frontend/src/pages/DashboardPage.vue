<template>
  <div>
    <div class="mb-7">
      <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Dashboard</h1>
      <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
        <span v-if="warnungen.length" class="text-orange-500 dark:text-orange-400 font-medium">{{ warnungen.length }} Meldung{{ warnungen.length > 1 ? 'en' : '' }}</span>
        <span v-else class="text-emerald-600 dark:text-emerald-400 font-medium">Alles in Ordnung</span>
        &nbsp;·&nbsp;{{ stats.kameraden }} aktive Kameraden
      </p>
    </div>

    <!-- Statistik-Kacheln -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <div @click="page = 'kameraden'"
        class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700 flex items-center justify-between gap-2 cursor-pointer hover:shadow-md hover:border-red-200 dark:hover:border-red-800 transition-all">
        <div class="min-w-0">
          <div class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.kameraden }}</div>
          <div class="text-xs font-medium text-gray-500 dark:text-gray-400 mt-0.5 truncate">Kameraden aktiv</div>
        </div>
        <div class="w-9 h-9 rounded-xl bg-red-50 dark:bg-red-900/20 flex items-center justify-center flex-shrink-0">
          <i class="ph ph-users-three text-lg text-red-500 dark:text-red-400"></i>
        </div>
      </div>
      <div @click="page = 'ausruestung'; filterStatus = ''"
        class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700 flex items-center justify-between gap-2 cursor-pointer hover:shadow-md hover:border-blue-200 dark:hover:border-blue-800 transition-all">
        <div class="min-w-0">
          <div class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.ausruestung }}</div>
          <div class="text-xs font-medium text-gray-500 dark:text-gray-400 mt-0.5 truncate">Ausrüstungsstücke</div>
        </div>
        <div class="w-9 h-9 rounded-xl bg-blue-50 dark:bg-blue-900/20 flex items-center justify-center flex-shrink-0">
          <i class="ph ph-t-shirt text-lg text-blue-500 dark:text-blue-400"></i>
        </div>
      </div>
      <div @click="page = 'ausruestung'; filterStatus = 'Prüfung fällig'"
        class="bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700 flex items-center justify-between gap-2 cursor-pointer hover:shadow-md hover:border-orange-200 dark:hover:border-orange-800 transition-all">
        <div class="min-w-0">
          <div class="text-2xl font-bold text-gray-900 dark:text-white">{{ stats.pruefungFaellig }}</div>
          <div class="text-xs font-medium text-gray-500 dark:text-gray-400 mt-0.5 truncate">Prüfungen ≤ 30 Tage</div>
        </div>
        <div class="w-9 h-9 rounded-xl bg-orange-50 dark:bg-orange-900/20 flex items-center justify-center flex-shrink-0">
          <i class="ph ph-warning text-lg text-orange-500 dark:text-orange-400"></i>
        </div>
      </div>
      <div @click="page = 'warnungen'"
        :class="['rounded-xl p-4 shadow-sm border flex items-center justify-between gap-2 cursor-pointer hover:shadow-md transition-all',
          warnungen.length > 0 ? 'bg-white dark:bg-gray-800 border-gray-100 dark:border-gray-700 hover:border-red-200 dark:hover:border-red-800' : 'bg-white dark:bg-gray-800 border-gray-100 dark:border-gray-700 hover:border-green-200 dark:hover:border-green-800']">
        <div class="min-w-0">
          <div :class="warnungen.length > 0 ? 'text-2xl font-bold text-red-600 dark:text-red-400' : 'text-2xl font-bold text-green-600 dark:text-green-400'">{{ warnungen.length }}</div>
          <div class="text-xs font-medium text-gray-500 dark:text-gray-400 mt-0.5 truncate">Aktive Warnungen</div>
        </div>
        <div :class="warnungen.length > 0 ? 'w-9 h-9 rounded-xl bg-red-50 dark:bg-red-900/20 flex items-center justify-center flex-shrink-0' : 'w-9 h-9 rounded-xl bg-green-50 dark:bg-green-900/20 flex items-center justify-center flex-shrink-0'">
          <i :class="warnungen.length > 0 ? 'ph ph-bell-ringing text-lg text-red-500 dark:text-red-400' : 'ph ph-check-circle text-lg text-green-500 dark:text-green-400'"></i>
        </div>
      </div>
    </div>

    <!-- Warnungen -->
    <div v-if="warnungen.length" class="mb-6">
      <h2 class="text-base font-semibold mb-3 text-gray-700 dark:text-gray-300">Handlungsbedarf</h2>
      <div class="space-y-2">
        <div v-for="w in warnungen" :key="w.id"
          :class="['flex items-start gap-3 bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700 border-l-4',
            w.prio === 'rot' ? 'border-l-red-500' : w.prio === 'orange' ? 'border-l-orange-400' : 'border-l-yellow-400']">
          <span class="text-lg flex-shrink-0">{{ w.prio === 'rot' ? '🔴' : w.prio === 'orange' ? '🟠' : '🟡' }}</span>
          <div>
            <div class="font-semibold text-sm text-gray-800 dark:text-gray-100">{{ w.titel }}</div>
            <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{{ w.detail }}</div>
          </div>
        </div>
      </div>
    </div>
    <div v-else class="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800 rounded-xl p-4 text-emerald-700 dark:text-emerald-400 text-sm flex items-center gap-2">
      <i class="ph ph-check-circle text-lg"></i>
      Keine dringenden Meldungen
    </div>
  </div>
</template>

<script setup>
import { page, warnungen, stats, filterStatus } from '../store.js'
</script>
