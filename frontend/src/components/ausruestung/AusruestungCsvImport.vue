<template>
  <Teleport to="body">
    <div v-if="modal.ausruestungCsvImport" class="modal-backdrop">
      <div class="modal-box" style="max-width: 56rem;">
        <div class="flex items-center justify-between mb-5">
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">Ausrüstung importieren (CSV)</h2>
          <button @click="modal.ausruestungCsvImport = false" class="icon-btn"><i class="ph ph-x text-xl"></i></button>
        </div>

        <!-- Upload + Beispiel -->
        <div class="flex gap-3 mb-4 flex-wrap items-center">
          <label class="btn-primary cursor-pointer flex items-center gap-2 text-sm">
            <i class="ph ph-upload-simple"></i> CSV-Datei wählen
            <input type="file" accept=".csv,.txt" @change="onAusruestungCsvFile" class="hidden" />
          </label>
          <button @click="downloadAusruestungBeispielCSV" class="btn-secondary flex items-center gap-2 text-sm">
            <i class="ph ph-download-simple"></i> Beispieldatei
          </button>
          <span v-if="form.ausruestungCsv.fileName" class="text-sm text-gray-500 dark:text-gray-400 italic">{{ form.ausruestungCsv.fileName }}</span>
        </div>

        <!-- Hinweis -->
        <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-3 text-xs text-blue-700 dark:text-blue-300 mb-4 leading-relaxed">
          <strong>Format:</strong> Semikolon (<code>;</code>) oder Komma (<code>,</code>) als Trennzeichen, erste Zeile = Spaltentitel.<br>
          <strong>Pflicht:</strong> <code>Ausruestungstyp</code> (muss exakt einem vorhandenen Typ entsprechen) &nbsp;·&nbsp;
          <strong>Optional:</strong> <code>Seriennummer</code>, <code>Kamerad</code>, <code>Status</code> (Lager/Ausgegeben/Reinigung/In Reparatur/Ausgesondert),
          <code>Groesse</code>, <code>Naechste_Pruefung</code> (TT.MM.JJJJ), <code>Kaufdatum</code>, <code>Notizen</code>
        </div>

        <!-- Vorschau-Tabelle -->
        <div v-if="form.ausruestungCsv.rows.length">
          <div class="flex items-center gap-3 mb-2 flex-wrap">
            <span class="text-sm font-medium text-gray-700 dark:text-gray-300">
              Vorschau: {{ validCount }} gültige / {{ form.ausruestungCsv.rows.length }} Zeilen gesamt
            </span>
            <span v-if="form.ausruestungCsv.rows.some(r => r._error)"
              class="text-xs text-red-600 dark:text-red-400">(Zeilen mit ✗ werden übersprungen)</span>
            <span v-if="form.ausruestungCsv.rows.some(r => r._duplicate)"
              class="text-xs text-orange-600 dark:text-orange-400 font-medium">
              ⚠ {{ form.ausruestungCsv.rows.filter(r => r._duplicate).length }} mögliche Duplikate
            </span>
          </div>
          <div class="overflow-auto max-h-64 rounded-lg border border-gray-200 dark:border-gray-700">
            <table class="w-full text-xs">
              <thead class="bg-gray-50 dark:bg-gray-700/50 sticky top-0">
                <tr>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold w-8"></th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Ausrüstungstyp</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Seriennummer</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Kamerad</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Status</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Größe</th>
                  <th class="px-3 py-2 text-left text-gray-400 font-semibold">Nächste Prüfung</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 dark:divide-gray-700">
                <tr v-for="(row, i) in form.ausruestungCsv.rows" :key="i"
                  :class="row._error ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'
                    : row._duplicate ? 'bg-orange-50 dark:bg-orange-900/20 text-gray-700 dark:text-gray-300'
                    : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300'">
                  <td class="px-3 py-1.5 text-center font-bold" :title="row._error || (row._duplicate ? 'Mögliches Duplikat (Seriennr. + Typ bereits vorhanden)' : '')">
                    <span v-if="row._error">✗</span>
                    <span v-else-if="row._duplicate" class="text-orange-500">⚠</span>
                    <span v-else>✓</span>
                  </td>
                  <td class="px-3 py-1.5">{{ row._Typ || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Seriennummer || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Kamerad || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Status || 'Lager' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Groesse || '—' }}</td>
                  <td class="px-3 py-1.5 text-gray-400">{{ row.Naechste_Pruefung || '—' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="flex justify-between gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.ausruestungCsvImport = false" class="btn-secondary">Abbrechen</button>
          <button @click="importAusruestung" :disabled="!validCount" class="btn-primary">
            <i class="ph ph-cloud-arrow-up mr-1.5"></i>
            {{ validCount }} Stück{{ validCount !== 1 ? 'e' : '' }} importieren
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed } from 'vue'
import { modal, form, onAusruestungCsvFile, downloadAusruestungBeispielCSV, importAusruestung } from '../../store.js'

const validCount = computed(() => form.ausruestungCsv.rows.filter(r => !r._error).length)
</script>
