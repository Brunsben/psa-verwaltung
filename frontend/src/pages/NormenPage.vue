<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Normen</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ normen.length }} Normen hinterlegt</p>
      </div>
      <button @click="openNormenForm()" class="btn-primary">+ Neu</button>
    </div>

    <div class="mb-4">
      <select v-model="filterNormKategorie" class="input max-w-xs">
        <option value="">Alle Kategorien</option>
        <option v-for="k in normenKategorien" :key="k" :value="k">{{ k }}</option>
      </select>
    </div>

    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-x-auto">
      <table class="w-full text-sm">
        <thead class="bg-gray-50 dark:bg-gray-700/50">
          <tr>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Norm</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Kategorie</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Prüfintervall</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Lebensdauer</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Max. Wäschen</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Beschreibung</th>
            <th class="px-4 py-2.5"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50 dark:divide-gray-700">
          <tr v-for="n in normenFiltered" :key="n.Id" class="hover:bg-gray-50 dark:hover:bg-gray-700/40 transition-colors">
            <td class="px-4 py-3 font-mono font-medium text-gray-800 dark:text-gray-200">{{ n.Bezeichnung }}</td>
            <td class="px-4 py-3">
              <span v-if="n.Ausruestungstyp_Kategorie" class="text-xs bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 px-2 py-0.5 rounded-full font-semibold">{{ n.Ausruestungstyp_Kategorie }}</span>
              <span v-else class="text-gray-400">–</span>
            </td>
            <td class="px-4 py-3 text-gray-600 dark:text-gray-400">{{ n.Pruefintervall_Monate ? n.Pruefintervall_Monate + ' Mon.' : '–' }}</td>
            <td class="px-4 py-3 text-gray-600 dark:text-gray-400">{{ n.Max_Lebensdauer_Jahre ? n.Max_Lebensdauer_Jahre + ' J.' : '–' }}</td>
            <td class="px-4 py-3 text-gray-600 dark:text-gray-400">{{ n.Max_Waeschen ? n.Max_Waeschen + 'x' : '–' }}</td>
            <td class="px-4 py-3 text-gray-500 dark:text-gray-400 text-xs max-w-xs">
              <span class="line-clamp-3" :title="n.Beschreibung || ''">{{ n.Beschreibung || '' }}</span>
            </td>
            <td class="px-4 py-3">
              <div class="flex gap-1 justify-end">
                <button @click="openNormenForm(n)" title="Bearbeiten" class="icon-btn hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 dark:hover:text-blue-400">
                  <i class="ph ph-pencil-simple text-base"></i>
                </button>
                <button @click="deleteNorm(n)" title="Löschen" class="icon-btn hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400">
                  <i class="ph ph-trash text-base"></i>
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="!normenFiltered.length">
            <td colspan="7" class="px-4 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">Keine Normen vorhanden</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { normen, normenFiltered, normenKategorien, filterNormKategorie, openNormenForm, deleteNorm } from '../store.js'
</script>
