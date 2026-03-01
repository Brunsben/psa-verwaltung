<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Ausrüstung</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ ausruestung.length }} Stücke &nbsp;·&nbsp; {{ stats.ausgegeben }} ausgegeben</p>
      </div>
      <button @click="openAusruestungForm()" class="btn-primary">+ Neu</button>
    </div>

    <!-- Filter + Export -->
    <div class="flex gap-3 mb-4 flex-wrap items-center">
      <input v-model="filterAusruestung" placeholder="Suche…"
        class="border border-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100 dark:placeholder-gray-500
               rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent"
        style="width:12rem" />
      <select v-model="filterTyp"
        class="border border-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100
               rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent">
        <option value="">Alle Typen</option>
        <option v-for="kat in typenKategorien" :key="kat" :value="kat">{{ kat }}</option>
      </select>
      <select v-model="filterStatus"
        class="border border-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100
               rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent">
        <option value="">Alle Status</option>
        <option>Lager</option><option>Ausgegeben</option>
        <option>Reinigung</option><option>In Reparatur</option><option>Ausgesondert</option>
        <option value="Prüfung fällig">Prüfung fällig (≤30 Tage)</option>
      </select>
      <button @click="onExportCSV" class="btn-secondary ml-auto text-xs">↓ CSV Export</button>
    </div>

    <!-- Massenauswahl-Aktionsleiste -->
    <div v-if="selectedIds.length" class="mb-3 flex items-center gap-3 bg-teal-50 dark:bg-teal-900/20 border border-teal-200 dark:border-teal-800 rounded-xl px-4 py-2.5">
      <span class="text-sm font-semibold text-teal-700 dark:text-teal-400">{{ selectedIds.length }} ausgewählt</span>
      <button @click="openMassenWaesche" class="btn-primary bg-teal-600 hover:bg-teal-700 text-sm py-1.5">
        <i class="ph ph-washing-machine"></i> Massenwäsche
      </button>
      <button @click="openMassenPruefung" class="btn-primary bg-orange-500 hover:bg-orange-600 text-sm py-1.5">
        <i class="ph ph-clipboard-text"></i> Massenprüfung
      </button>
      <button @click="selectedIds = []" class="btn-secondary text-xs py-1.5">Auswahl aufheben</button>
    </div>

    <div class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100 dark:border-gray-700">
            <th class="px-3 py-2.5 w-8">
              <input type="checkbox" :checked="alleAusgewaehlt" @change="toggleAlle" class="accent-teal-600 cursor-pointer" />
            </th>
            <th @click="sortBy('Seriennummer')" class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider cursor-pointer select-none hover:text-gray-600 dark:hover:text-gray-300">Seriennr. <span v-if="sortAusruestung.field==='Seriennummer'">{{ sortAusruestung.dir==='asc' ? '↑' : '↓' }}</span></th>
            <th @click="sortBy('Ausruestungstyp')" class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider cursor-pointer select-none hover:text-gray-600 dark:hover:text-gray-300">Typ <span v-if="sortAusruestung.field==='Ausruestungstyp'">{{ sortAusruestung.dir==='asc' ? '↑' : '↓' }}</span></th>
            <th @click="sortBy('Kamerad')" class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider cursor-pointer select-none hover:text-gray-600 dark:hover:text-gray-300">Kamerad <span v-if="sortAusruestung.field==='Kamerad'">{{ sortAusruestung.dir==='asc' ? '↑' : '↓' }}</span></th>
            <th @click="sortBy('Status')" class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider cursor-pointer select-none hover:text-gray-600 dark:hover:text-gray-300">Status <span v-if="sortAusruestung.field==='Status'">{{ sortAusruestung.dir==='asc' ? '↑' : '↓' }}</span></th>
            <th @click="sortBy('Naechste_Pruefung')" class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider cursor-pointer select-none hover:text-gray-600 dark:hover:text-gray-300">Nächste Prüfung <span v-if="sortAusruestung.field==='Naechste_Pruefung'">{{ sortAusruestung.dir==='asc' ? '↑' : '↓' }}</span></th>
            <th @click="sortBy('Lebensende_Datum')" class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider cursor-pointer select-none hover:text-gray-600 dark:hover:text-gray-300">Lebensende <span v-if="sortAusruestung.field==='Lebensende_Datum'">{{ sortAusruestung.dir==='asc' ? '↑' : '↓' }}</span></th>
            <th class="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50 dark:divide-gray-700">
          <tr v-for="a in ausruestungFiltered" :key="a.Id" :class="['group hover:bg-gray-50 dark:hover:bg-gray-700/40 transition-colors', selectedIds.includes(a.Id) ? 'bg-teal-50/60 dark:bg-teal-900/10' : '']">
            <td class="px-3 py-2">
              <input type="checkbox" :checked="selectedIds.includes(a.Id)" @change="toggleSelect(a.Id)" class="accent-teal-600 cursor-pointer" />
            </td>
            <td class="px-4 py-2 font-mono text-xs text-gray-500 dark:text-gray-400">{{ a.Seriennummer || '–' }}</td>
            <td class="px-4 py-2 font-medium text-gray-800 dark:text-gray-200">
              {{ typLabel(a.Ausruestungstyp, typen) }}
              <template v-if="waeschenInfo(a.Id, a.Ausruestungstyp)" v-for="wi in [waeschenInfo(a.Id, a.Ausruestungstyp)]">
                <div :class="['text-xs mt-0.5 font-semibold', wi.count >= wi.max ? 'text-red-500 dark:text-red-400' : wi.count / wi.max >= 0.9 ? 'text-orange-500 dark:text-orange-400' : 'text-gray-400 dark:text-gray-500']">
                  <i class="ph ph-washing-machine"></i> {{ wi.count }}/{{ wi.max }}
                </div>
              </template>
            </td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400">{{ a.Kamerad || '–' }}</td>
            <td class="px-4 py-2">
              <select :value="a.Status" @change="quickStatus(a, $event.target.value)"
                :class="statusBadge(a.Status)"
                class="cursor-pointer border-0 appearance-none focus:outline-none focus:ring-1 focus:ring-red-400 pr-3"
                title="Status ändern">
                <option>Lager</option><option>Ausgegeben</option>
                <option>Reinigung</option><option>In Reparatur</option><option>Ausgesondert</option>
              </select>
            </td>
            <td class="px-4 py-2">
              <template v-for="rel in [fmtDateRel(a.Naechste_Pruefung)]">
                <span v-if="!rel" class="text-gray-400 dark:text-gray-500 text-xs">–</span>
                <template v-else>
                  <div :class="[rel.cls, 'text-xs font-semibold leading-tight']">{{ rel.label }}</div>
                  <div v-if="rel.sub" class="text-xs text-gray-400 dark:text-gray-500 leading-tight">{{ rel.sub }}</div>
                </template>
              </template>
            </td>
            <td class="px-4 py-2">
              <template v-for="rel in [fmtDateRel(a.Lebensende_Datum)]">
                <span v-if="!rel" class="text-gray-400 dark:text-gray-500 text-xs">–</span>
                <template v-else>
                  <div :class="[rel.cls, 'text-xs font-semibold leading-tight']">{{ rel.label }}</div>
                  <div v-if="rel.sub" class="text-xs text-gray-400 dark:text-gray-500 leading-tight">{{ rel.sub }}</div>
                </template>
              </template>
            </td>
            <td class="px-4 py-2">
              <div class="flex items-center justify-end gap-0.5 opacity-0 group-hover:opacity-100 transition-opacity">
                <button @click="openAusruestungDetail(a)" title="Detail / History" class="icon-btn hover:text-purple-600 hover:bg-purple-50 dark:hover:bg-purple-900/20 dark:hover:text-purple-400">
                  <i class="ph ph-list-magnifying-glass text-base"></i>
                </button>
                <button @click="openAusgabe(a)" title="Ausgabe / Rückgabe" class="icon-btn hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 dark:hover:text-blue-400">
                  <i class="ph ph-sign-out text-base"></i>
                </button>
                <button @click="openPruefung(a)" title="Prüfung erfassen" class="icon-btn hover:text-orange-500 hover:bg-orange-50 dark:hover:bg-orange-900/20 dark:hover:text-orange-400">
                  <i class="ph ph-clipboard-text text-base"></i>
                </button>
                <button @click="openWaesche(a)" title="Wäsche erfassen" class="icon-btn hover:text-teal-600 hover:bg-teal-50 dark:hover:bg-teal-900/20 dark:hover:text-teal-400">
                  <i class="ph ph-washing-machine text-base"></i>
                </button>
                <button @click="openAusruestungForm(a)" title="Bearbeiten" class="icon-btn hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 dark:hover:text-blue-400">
                  <i class="ph ph-pencil-simple text-base"></i>
                </button>
                <button @click="deleteAusruestung(a)" title="Löschen" class="icon-btn hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400">
                  <i class="ph ph-trash text-base"></i>
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="!ausruestungFiltered.length">
            <td colspan="8" class="px-4 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">Keine Ausrüstung gefunden</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import {
  ausruestung, ausruestungFiltered, typen, typenKategorien, stats,
  filterAusruestung, filterTyp, filterStatus,
  selectedIds, sortAusruestung, alleAusgewaehlt,
  sortBy, toggleAlle, toggleSelect, waeschenInfo, quickStatus,
  openAusruestungForm, openAusruestungDetail, deleteAusruestung,
  openAusgabe, openPruefung, openWaesche,
  openMassenWaesche, openMassenPruefung, showToast,
} from '../store.js'
import { fmtDateRel, statusBadge, typLabel } from '../utils/formatters.js'
import { exportCSV } from '../utils/pdf.js'

function onExportCSV() {
  exportCSV(ausruestungFiltered.value, typen.value, showToast)
}
</script>
