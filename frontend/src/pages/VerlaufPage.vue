<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Verlauf</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
          {{ pruefungen.length }} Prüfungen &nbsp;·&nbsp; {{ waescheListe.length }} Wäschen &nbsp;·&nbsp; {{ ausgaben.length }} Ausgaben
        </p>
      </div>
    </div>

    <!-- Tabs + Filter -->
    <div class="flex flex-wrap gap-3 mb-4 items-center">
      <div class="flex bg-gray-100 dark:bg-gray-800 rounded-lg p-1 gap-1">
        <button @click="verlaufTab = 'pruefungen'"
          :class="['px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
            verlaufTab === 'pruefungen'
              ? 'bg-white dark:bg-gray-700 text-red-700 dark:text-red-400 shadow-sm'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100']">
          <i class="ph ph-clipboard-text"></i> Prüfungen ({{ pruefungenFiltered.length }})
        </button>
        <button @click="verlaufTab = 'waesche'"
          :class="['px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
            verlaufTab === 'waesche'
              ? 'bg-white dark:bg-gray-700 text-red-700 dark:text-red-400 shadow-sm'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100']">
          <i class="ph ph-washing-machine"></i> Wäschen ({{ waescheFiltered.length }})
        </button>
        <button @click="verlaufTab = 'ausgaben'"
          :class="['px-3 py-1.5 rounded-md text-sm font-medium transition-colors',
            verlaufTab === 'ausgaben'
              ? 'bg-white dark:bg-gray-700 text-red-700 dark:text-red-400 shadow-sm'
              : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100']">
          <i class="ph ph-sign-out"></i> Ausgaben ({{ ausgabenFiltered.length }})
        </button>
      </div>
      <select v-model="filterVerlaufKamerad"
        class="border border-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100 rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent">
        <option value="">Alle Kameraden</option>
        <option v-for="k in kameradenliste" :key="k.Id" :value="k.label">{{ k.label }}</option>
      </select>
    </div>

    <!-- Prüfungen Tab -->
    <div v-if="verlaufTab === 'pruefungen'" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100 dark:border-gray-700">
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Datum</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Kamerad</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Ausrüstung</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Ergebnis</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Prüfer</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Nächste Prüfung</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50 dark:divide-gray-700">
          <tr v-for="p in pruefungenFiltered" :key="p.Id" class="hover:bg-gray-50 dark:hover:bg-gray-700/40 transition-colors">
            <td class="px-4 py-2.5 font-medium text-gray-800 dark:text-gray-200">{{ fmtDate(p.Datum) }}</td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">{{ p.Kamerad || '–' }}</td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">
              <div class="font-medium text-gray-800 dark:text-gray-200">{{ p.Ausruestungstyp || '–' }}</div>
              <div v-if="p.Seriennummer" class="text-xs text-gray-400 dark:text-gray-500 font-mono mt-0.5">{{ p.Seriennummer }}</div>
            </td>
            <td class="px-4 py-2.5">
              <span :class="p.Ergebnis === 'Bestanden'
                ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400'
                : p.Ergebnis === 'Nicht bestanden'
                ? 'bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400'
                : 'bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400'"
                class="px-2 py-0.5 rounded-full text-xs font-semibold">
                {{ p.Ergebnis || '–' }}
              </span>
            </td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">{{ p.Pruefer || '–' }}</td>
            <td class="px-4 py-2.5 text-gray-500 dark:text-gray-400 text-xs">{{ fmtDate(p.Naechste_Pruefung) }}</td>
          </tr>
          <tr v-if="!pruefungenFiltered.length">
            <td colspan="6" class="px-4 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">
              <div class="font-medium mb-1">Keine Prüfungen vorhanden</div>
              <div class="text-xs">Prüfungen werden beim Erfassen automatisch hier eingetragen</div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Wäschen Tab -->
    <div v-if="verlaufTab === 'waesche'" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100 dark:border-gray-700">
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Datum</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Kamerad</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Ausrüstung</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Art</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Notizen</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50 dark:divide-gray-700">
          <tr v-for="w in waescheFiltered" :key="w.Id" class="hover:bg-gray-50 dark:hover:bg-gray-700/40 transition-colors">
            <td class="px-4 py-2.5 font-medium text-gray-800 dark:text-gray-200">{{ fmtDate(w.Datum) }}</td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">{{ w.Kamerad || '–' }}</td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">
              <div class="font-medium text-gray-800 dark:text-gray-200">{{ w.Ausruestungstyp || '–' }}</div>
              <div v-if="w.Seriennummer" class="text-xs text-gray-400 dark:text-gray-500 font-mono mt-0.5">{{ w.Seriennummer }}</div>
            </td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">{{ w.Waescheart || '–' }}</td>
            <td class="px-4 py-2.5 text-gray-500 dark:text-gray-400 text-xs">{{ w.Notizen || '' }}</td>
          </tr>
          <tr v-if="!waescheFiltered.length">
            <td colspan="5" class="px-4 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">
              <div class="font-medium mb-1">Keine Wäschen vorhanden</div>
              <div class="text-xs">Wäschen werden beim Erfassen automatisch hier eingetragen</div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Ausgaben Tab -->
    <div v-if="verlaufTab === 'ausgaben'" class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100 dark:border-gray-700">
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Ausgabedatum</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Rückgabedatum</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Kamerad</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Ausrüstung</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Notizen</th>
            <th class="px-4 py-2.5 w-10"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50 dark:divide-gray-700">
          <tr v-for="ag in ausgabenFiltered" :key="ag.Id" class="hover:bg-gray-50 dark:hover:bg-gray-700/40 transition-colors">
            <td class="px-4 py-2.5 font-medium text-gray-800 dark:text-gray-200">{{ fmtDate(ag.Ausgabedatum) }}</td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">
              <span v-if="ag.Rueckgabedatum">{{ fmtDate(ag.Rueckgabedatum) }}</span>
              <span v-else class="text-amber-500 dark:text-amber-400 text-xs font-semibold">noch ausgegeben</span>
            </td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">{{ ag.Kamerad || '–' }}</td>
            <td class="px-4 py-2.5 text-gray-600 dark:text-gray-400">
              <div class="font-medium text-gray-800 dark:text-gray-200">{{ ag.Ausruestungstyp || '–' }}</div>
              <div v-if="ag.Seriennummer" class="text-xs text-gray-400 dark:text-gray-500 font-mono mt-0.5">{{ ag.Seriennummer }}</div>
            </td>
            <td class="px-4 py-2.5 text-gray-500 dark:text-gray-400 text-xs">{{ ag.Notizen || '' }}</td>
            <td class="px-4 py-2.5">
              <button v-if="!ag.Rueckgabedatum" @click="openRueckgabe(ag)"
                class="text-xs px-2 py-1 rounded-lg bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400 hover:bg-blue-100 dark:hover:bg-blue-900/40 font-medium whitespace-nowrap transition-colors">
                <i class="ph ph-arrow-u-up-left"></i> Rückgabe
              </button>
            </td>
          </tr>
          <tr v-if="!ausgabenFiltered.length">
            <td colspan="6" class="px-4 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">
              <div class="font-medium mb-1">Keine Ausgaben vorhanden</div>
              <div class="text-xs">Ausgaben werden beim Erfassen automatisch hier eingetragen</div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import {
  pruefungen, waescheListe, ausgaben,
  pruefungenFiltered, waescheFiltered, ausgabenFiltered,
  verlaufTab, filterVerlaufKamerad, kameradenliste,
  openRueckgabe,
} from '../store.js'
import { fmtDate } from '../utils/formatters.js'
</script>
