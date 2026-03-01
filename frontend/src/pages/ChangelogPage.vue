<template>
  <div>
    <div class="mb-5">
      <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Änderungsprotokoll</h1>
      <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ changelog.length }} Einträge</p>
    </div>
    <div class="mb-4 flex gap-3 flex-wrap items-center">
      <select v-model="filterChangelog" class="input max-w-xs">
        <option value="">Alle Aktionen</option>
        <option>Erstellt</option>
        <option>Bearbeitet</option>
        <option>Gelöscht</option>
      </select>
    </div>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700">
      <div v-if="changelogFiltered.length" class="divide-y divide-gray-50 dark:divide-gray-700">
        <div v-for="c in changelogFiltered" :key="c.Id" class="px-5 py-3 flex items-start gap-3">
          <i :class="['text-lg flex-shrink-0 mt-0.5',
            c.Aktion === 'Erstellt' ? 'ph ph-plus-circle text-emerald-500' :
            c.Aktion === 'Gelöscht' ? 'ph ph-trash text-red-500' :
            'ph ph-pencil-simple text-blue-500']"></i>
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap">
              <span class="text-sm font-semibold text-gray-800 dark:text-gray-100">{{ c.Tabelle }}</span>
              <span :class="['text-xs px-1.5 py-0.5 rounded font-semibold',
                c.Aktion === 'Erstellt' ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400' :
                c.Aktion === 'Gelöscht' ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400' :
                'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400']">{{ c.Aktion }}</span>
            </div>
            <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{{ c.Details || '' }}</div>
          </div>
          <div class="text-right flex-shrink-0">
            <div class="text-xs text-gray-500 dark:text-gray-400">{{ fmtDate(c.Zeitpunkt) }}</div>
            <div class="text-xs text-gray-400 dark:text-gray-500">{{ c.Benutzer || '–' }}</div>
          </div>
        </div>
      </div>
      <div v-else class="px-5 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">Keine Änderungen protokolliert</div>
    </div>
  </div>
</template>

<script setup>
import { changelog, changelogFiltered, filterChangelog } from '../store.js'
import { fmtDate } from '../utils/formatters.js'
</script>
