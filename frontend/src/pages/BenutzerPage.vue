<template>
  <div>
    <div class="mb-5 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Benutzerverwaltung</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ benutzer.length }} Benutzer</p>
      </div>
      <button @click="openBenutzerForm()" class="btn-primary shrink-0">+ Neu</button>
    </div>
    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-x-auto">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 dark:bg-gray-700/50 text-xs text-gray-500 dark:text-gray-400 uppercase tracking-wide">
          <tr>
            <th class="px-4 py-3 text-left">Benutzername</th>
            <th class="px-4 py-3 text-left">Rolle</th>
            <th class="px-4 py-3 text-left">Kamerad</th>
            <th class="px-4 py-3 text-left">Status</th>
            <th class="px-4 py-3 text-right">Aktionen</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100 dark:divide-gray-700">
          <tr v-if="!benutzer.length">
            <td colspan="5" class="px-4 py-8 text-center text-gray-400 dark:text-gray-500">Keine Benutzer vorhanden</td>
          </tr>
          <tr v-for="b in benutzer" :key="b.Id" class="group hover:bg-gray-50 dark:hover:bg-gray-700/40 transition-colors">
            <td class="px-4 py-3 font-medium text-gray-900 dark:text-white">
              {{ b.Benutzername }}
              <span v-if="b.Id === currentUser?.Id" class="ml-1 text-xs text-gray-400">(du)</span>
            </td>
            <td class="px-4 py-3">
              <span :class="['px-2 py-0.5 rounded-full text-xs font-semibold',
                b.Rolle === 'Admin' ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400' :
                b.Rolle === 'Kleiderwart' ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400' :
                'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300']">
                {{ b.Rolle || '–' }}
              </span>
            </td>
            <td class="px-4 py-3 text-gray-500 dark:text-gray-400">
              {{ b.KameradId ? (kameraden.find(k => k.Id == b.KameradId)?.Vorname + ' ' + kameraden.find(k => k.Id == b.KameradId)?.Name || 'ID: ' + b.KameradId) : '–' }}
            </td>
            <td class="px-4 py-3">
              <span :class="['px-2 py-0.5 rounded-full text-xs font-semibold', b.Aktiv !== false ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400' : 'bg-gray-100 dark:bg-gray-700 text-gray-500']">
                {{ b.Aktiv !== false ? 'Aktiv' : 'Inaktiv' }}
              </span>
            </td>
            <td class="px-4 py-3 text-right">
              <div class="flex items-center justify-end gap-1 md:opacity-0 md:group-hover:opacity-100 transition-opacity">
                <button @click="openBenutzerForm(b)" title="Bearbeiten" class="icon-btn hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 dark:hover:text-blue-400">
                  <i class="ph ph-pencil-simple text-base"></i>
                </button>
                <button @click="deleteBenutzer(b)" :disabled="b.Id === currentUser?.Id" title="Löschen"
                  class="icon-btn hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400 disabled:opacity-30 disabled:cursor-not-allowed">
                  <i class="ph ph-trash text-base"></i>
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { benutzer, kameraden, currentUser, openBenutzerForm, deleteBenutzer } from '../store.js'
</script>
