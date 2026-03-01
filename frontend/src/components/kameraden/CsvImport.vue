<template>
  <Teleport to="body">
    <div v-if="modal.csvImport" class="modal-backdrop">
      <div class="modal-box" style="max-width: 56rem;">
        <div class="flex items-center justify-between mb-5">
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">Kameraden importieren (CSV)</h2>
          <button @click="modal.csvImport = false" class="icon-btn"><i class="ph ph-x text-xl"></i></button>
        </div>

        <!-- Upload + Beispiel -->
        <div class="flex gap-3 mb-4 flex-wrap items-center">
          <label class="btn-primary cursor-pointer flex items-center gap-2 text-sm">
            <i class="ph ph-upload-simple"></i> CSV-Datei wählen
            <input type="file" accept=".csv,.txt" @change="onCsvFile" class="hidden" />
          </label>
          <button @click="downloadBeispielCSV" class="btn-secondary flex items-center gap-2 text-sm">
            <i class="ph ph-download-simple"></i> Beispieldatei
          </button>
          <span v-if="form.csvImport.fileName" class="text-sm text-gray-500 dark:text-gray-400 italic">{{ form.csvImport.fileName }}</span>
        </div>

        <!-- Hinweis -->
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 text-xs text-blue-700 dark:text-blue-300 mb-4 leading-relaxed">
          <strong>Format:</strong> Semikolon (<code>;</code>) oder Komma (<code>,</code>) als Trennzeichen, erste Zeile = Spaltentitel.<br>
          <strong>Pflicht:</strong> <code>Vorname</code>, <code>Name</code> &nbsp;·&nbsp;
          <strong>Optional:</strong> <code>Dienstgrad</code>, <code>Jacke_Groesse</code>, <code>Hose_Groesse</code>, <code>Stiefel_Groesse</code>, <code>Handschuh_Groesse</code>, <code>Hemd_Groesse</code>, <code>Poloshirt_Groesse</code>, <code>Fleece_Groesse</code>, <code>Aktiv</code> (ja/nein)
        </div>

        <!-- Vorschau-Tabelle -->
        <div v-if="form.csvImport.rows.length">
          <div class="flex items-center gap-3 mb-2 flex-wrap">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
              Vorschau: {{ form.csvImport.rows.filter(r => !r._error).length }} gültige /
              {{ form.csvImport.rows.length }} Zeilen gesamt
            </span>
            <span v-if="form.csvImport.rows.some(r => r._error)"
              class="text-xs text-red-600 dark:text-red-400">(Zeilen mit ✗ werden übersprungen)</span>
            <span v-if="form.csvImport.rows.some(r => r._duplicate)"
              class="text-xs text-orange-600 dark:text-orange-400 font-medium">
              ⚠ {{ form.csvImport.rows.filter(r => r._duplicate).length }} mögliche Dublette(n)
            </span>
          </div>
          <div class="overflow-auto max-h-64 rounded-lg border border-gray-200 dark:border-gray-700">
            <table class="w-full text-xs">
              <thead class="bg-gray-50 dark:bg-gray-700/50 sticky top-0">
                <tr>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold w-8"></th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Vorname</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Name</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Dienstgrad</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Jacke</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Hose</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Stiefel</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Handschuh</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Aktiv</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-700">
                <tr v-for="(row, i) in form.csvImport.rows" :key="i"
                  :class="row._error ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'
                    : row._duplicate ? 'bg-orange-50 dark:bg-orange-900/20 text-gray-700 dark:text-gray-300'
                    : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300'">
                  <td class="px-3 py-1.5 text-center font-bold" :title="row._error || (row._duplicate ? 'Mögliche Dublette' : '')">
                    <span v-if="row._error">✗</span>
                    <span v-else-if="row._duplicate" class="text-orange-500">⚠</span>
                    <span v-else>✓</span>
                  </td>
                  <td class="px-3 py-1.5">{{ row._Vorname || '—' }}</td>
                  <td class="px-3 py-1.5">{{ row._Name || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Dienstgrad || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Jacke_Groesse || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Hose_Groesse || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Stiefel_Groesse || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Handschuh_Groesse || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Aktiv || 'ja' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="flex justify-between gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.csvImport = false" class="btn-secondary">Abbrechen</button>
          <button @click="importKameraden"
            :disabled="!validCount"
            class="btn-primary">
            <i class="ph ph-cloud-arrow-up mr-1.5"></i>
            {{ validCount }} Kamerad{{ validCount !== 1 ? 'en' : '' }} importieren
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed } from 'vue'
import { modal, form, importKameraden, onCsvFile, downloadBeispielCSV } from '../../store.js'

const validCount = computed(() => form.csvImport.rows.filter(r => !r._error).length)
</script>
