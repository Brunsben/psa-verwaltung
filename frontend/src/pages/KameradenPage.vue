<template>
  <div>
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Kameraden</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ kameraden.length }} gesamt &nbsp;·&nbsp; {{ stats.kameraden }} aktiv</p>
      </div>
      <div class="flex gap-2">
        <button @click="openCsvImport" class="btn-secondary flex items-center gap-1.5 text-sm">
          <i class="ph ph-upload-simple"></i> CSV Import
        </button>
        <button @click="openKameradenForm()" class="btn-primary">+ Neu</button>
      </div>
    </div>

    <div class="flex gap-3 mb-4 flex-wrap items-center">
      <input v-model="filterKameraden" placeholder="Name suchen…"
        class="w-full sm:w-56 border border-gray-200 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-100 dark:placeholder-gray-500
               rounded-lg px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-red-400 focus:border-transparent" />
      <label class="flex items-center gap-2 text-sm text-gray-500 dark:text-gray-400 ml-2 cursor-pointer select-none">
        <input type="checkbox" v-model="filterKameradenNurAktiv" class="accent-red-600" />
        Nur aktive
      </label>
      <span class="text-xs text-gray-400 dark:text-gray-500 ml-auto">{{ kameradenFiltered.length }} angezeigt</span>
    </div>

    <!-- ── Mobile Karten ────────────────────────────────────────── -->
    <div class="md:hidden space-y-2">
      <div v-if="!kameraden.length" class="text-center text-gray-400 dark:text-gray-500 text-sm py-8">Noch keine Kameraden eingetragen</div>
      <div v-for="k in kameradenFiltered" :key="k.Id"
        @click="openKameradenDetail(k)"
        class="bg-white dark:bg-gray-800 rounded-xl border border-gray-100 dark:border-gray-700 p-4 shadow-sm cursor-pointer active:bg-gray-50 dark:active:bg-gray-700/40">
        <div class="flex items-start justify-between gap-2">
          <div class="min-w-0 flex-1">
            <div class="font-semibold text-gray-900 dark:text-white">{{ k.Vorname }} {{ k.Name }}</div>
            <div class="flex items-center gap-2 mt-1">
              <span v-if="k.Dienstgrad" class="text-xs text-gray-500 dark:text-gray-400">{{ k.Dienstgrad }}</span>
              <span :class="k.Aktiv
                ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500'"
                class="px-2 py-0.5 rounded-full text-xs font-semibold">
                {{ k.Aktiv ? 'Aktiv' : 'Inaktiv' }}
              </span>
            </div>
          </div>
          <div class="flex shrink-0 gap-0.5">
            <button @click.stop="openKameradenForm(k)" title="Bearbeiten" class="icon-btn hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 dark:hover:text-blue-400">
              <i class="ph ph-pencil-simple text-base"></i>
            </button>
            <button @click.stop="deleteKamerad(k)" title="Löschen" class="icon-btn hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400">
              <i class="ph ph-trash text-base"></i>
            </button>
          </div>
        </div>
        <dl class="mt-2.5 grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
          <div v-if="k.Jacke_Groesse"><dt class="text-gray-400 dark:text-gray-500">Jacke</dt><dd class="text-gray-700 dark:text-gray-300">{{ k.Jacke_Groesse }}</dd></div>
          <div v-if="k.Hose_Groesse"><dt class="text-gray-400 dark:text-gray-500">Hose</dt><dd class="text-gray-700 dark:text-gray-300">{{ k.Hose_Groesse }}</dd></div>
          <div v-if="k.Stiefel_Groesse"><dt class="text-gray-400 dark:text-gray-500">Stiefel</dt><dd class="text-gray-700 dark:text-gray-300">{{ k.Stiefel_Groesse }}</dd></div>
          <div v-if="k.Handschuh_Groesse"><dt class="text-gray-400 dark:text-gray-500">Handschuh</dt><dd class="text-gray-700 dark:text-gray-300">{{ k.Handschuh_Groesse }}</dd></div>
          <div v-if="k.Hemd_Groesse"><dt class="text-gray-400 dark:text-gray-500">Hemd</dt><dd class="text-gray-700 dark:text-gray-300">{{ k.Hemd_Groesse }}</dd></div>
          <div v-if="k.Poloshirt_Groesse"><dt class="text-gray-400 dark:text-gray-500">Poloshirt</dt><dd class="text-gray-700 dark:text-gray-300">{{ k.Poloshirt_Groesse }}</dd></div>
          <div v-if="k.Fleece_Groesse"><dt class="text-gray-400 dark:text-gray-500">Fleece</dt><dd class="text-gray-700 dark:text-gray-300">{{ k.Fleece_Groesse }}</dd></div>
        </dl>
      </div>
    </div>

    <!-- ── Desktop Tabelle ───────────────────────────────────────── -->
    <div class="hidden md:block bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-gray-100 dark:border-gray-700">
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Name</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Dienstgrad</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Jacke</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Hose</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Stiefel</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Handschuh</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Hemd</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Poloshirt</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Fleece</th>
            <th class="px-4 py-2.5 text-left text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Status</th>
            <th class="px-4 py-2"></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-50 dark:divide-gray-700">
          <tr v-for="k in kameradenFiltered" :key="k.Id"
            @click.stop="openKameradenDetail(k)"
            class="group hover:bg-gray-50 dark:hover:bg-gray-700/40 transition-colors cursor-pointer">
            <td class="px-4 py-2 font-semibold text-gray-800 dark:text-gray-200">{{ k.Vorname }} {{ k.Name }}</td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400 text-xs">{{ k.Dienstgrad || '–' }}</td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400">{{ k.Jacke_Groesse || '–' }}</td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400">{{ k.Hose_Groesse || '–' }}</td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400">{{ k.Stiefel_Groesse || '–' }}</td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400">{{ k.Handschuh_Groesse || '–' }}</td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400">{{ k.Hemd_Groesse || '–' }}</td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400">{{ k.Poloshirt_Groesse || '–' }}</td>
            <td class="px-4 py-2 text-gray-600 dark:text-gray-400">{{ k.Fleece_Groesse || '–' }}</td>
            <td class="px-4 py-2">
              <span :class="k.Aktiv
                ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400'
                : 'bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500'"
                class="px-2 py-0.5 rounded-full text-xs font-semibold">
                {{ k.Aktiv ? 'Aktiv' : 'Inaktiv' }}
              </span>
            </td>
            <td class="px-4 py-2">
              <div class="flex items-center justify-end gap-1 md:opacity-0 md:group-hover:opacity-100 transition-opacity">
                <button @click.stop="openKameradenForm(k)" title="Bearbeiten" class="icon-btn hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 dark:hover:text-blue-400">
                  <i class="ph ph-pencil-simple text-base"></i>
                </button>
                <button @click.stop="deleteKamerad(k)" title="Löschen" class="icon-btn hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400">
                  <i class="ph ph-trash text-base"></i>
                </button>
              </div>
            </td>
          </tr>
          <tr v-if="!kameraden.length">
            <td colspan="11" class="px-4 py-10 text-center text-gray-400 dark:text-gray-500 text-sm">Noch keine Kameraden eingetragen</td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import {
  kameraden, kameradenFiltered, filterKameraden, filterKameradenNurAktiv, stats,
  openKameradenForm, openKameradenDetail, deleteKamerad, openCsvImport,
} from '../store.js'
</script>
