<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Ausrüstungstypen</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ typen.length }} Typen definiert</p>
      </div>
      <button @click="openTypenForm()" class="btn-primary">+ Neu</button>
    </div>

    <div class="grid md:grid-cols-2 gap-4">
      <div v-for="t in typen" :key="t.Id"
        class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-5 hover:shadow-md transition-shadow">
        <div class="flex justify-between items-start">
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap">
              <span v-if="t.Typ" class="text-xs bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 px-2 py-0.5 rounded-full font-semibold">{{ t.Typ }}</span>
              <span class="font-bold text-gray-800 dark:text-gray-100">{{ t.Bezeichnung }}</span>
            </div>
            <div class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ t.Hersteller || '–' }}</div>
            <div v-if="t.Norm" class="text-xs text-gray-400 dark:text-gray-500 mt-0.5 font-mono">{{ t.Norm }}</div>
          </div>
          <div class="flex gap-1 ml-4 flex-shrink-0">
            <button @click="openTypenForm(t)" title="Bearbeiten" class="icon-btn hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 dark:hover:text-blue-400">
              <i class="ph ph-pencil-simple text-base"></i>
            </button>
            <button @click="deleteTyp(t)" title="Löschen" class="icon-btn hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400">
              <i class="ph ph-trash text-base"></i>
            </button>
          </div>
        </div>
        <div class="mt-3 pt-3 border-t border-gray-100 dark:border-gray-700 flex gap-5 text-xs text-gray-500 dark:text-gray-400 flex-wrap">
          <span><i class="ph ph-hourglass"></i> <strong class="text-gray-700 dark:text-gray-300">{{ t.Max_Lebensdauer_Jahre || '–' }}</strong> J. Lebensdauer</span>
          <span><i class="ph ph-magnifying-glass"></i> <strong class="text-gray-700 dark:text-gray-300">{{ t.Pruefintervall_Monate || '–' }}</strong> Mon. Prüfintervall</span>
          <span v-if="t.Max_Waeschen"><i class="ph ph-washing-machine"></i> max. <strong class="text-gray-700 dark:text-gray-300">{{ t.Max_Waeschen }}</strong> Wäschen</span>
          <span v-if="t.Typ && normenFuerTyp(t.Typ).length" class="text-blue-500 dark:text-blue-400">
            <i class="ph ph-seal-check"></i> <strong>{{ normenFuerTyp(t.Typ).length }}</strong> Norm{{ normenFuerTyp(t.Typ).length > 1 ? 'en' : '' }}
          </span>
        </div>
        <div v-if="t.Beschreibung" class="mt-2 text-xs text-gray-400 dark:text-gray-500 italic">{{ t.Beschreibung }}</div>
      </div>
      <div v-if="!typen.length" class="col-span-2 text-center text-gray-400 dark:text-gray-500 text-sm py-10">
        Noch keine Typen angelegt
      </div>
    </div>
  </div>
</template>

<script setup>
import { typen, openTypenForm, deleteTyp, normenFuerTyp } from '../store.js'
</script>
