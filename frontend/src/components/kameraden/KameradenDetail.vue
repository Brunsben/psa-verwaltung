<template>
  <Teleport to="body">
    <div v-if="modal.kameradenDetail" class="modal-backdrop" @click.self="modal.kameradenDetail = false">
      <div class="modal-box" style="max-width: 54rem;">

        <!-- Print-Header (nur beim Drucken sichtbar) -->
        <div class="print-title">PSA-Nachweis – {{ selectedKamerad.Vorname }} {{ selectedKamerad.Name }}</div>

        <!-- Header -->
        <div class="flex items-start justify-between mb-5 no-print">
          <div>
            <h2 class="text-xl font-bold text-gray-900 dark:text-white">{{ selectedKamerad.Vorname }} {{ selectedKamerad.Name }}</h2>
            <div v-if="selectedKamerad.Dienstgrad" class="text-sm text-gray-500 dark:text-gray-400 mt-0.5">{{ selectedKamerad.Dienstgrad }}</div>
            <span :class="selectedKamerad.Aktiv
              ? 'bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400'
              : 'bg-gray-100 dark:bg-gray-700 text-gray-400 dark:text-gray-500'"
              class="inline-block mt-1 px-2 py-0.5 rounded-full text-xs font-semibold">
              {{ selectedKamerad.Aktiv ? 'Aktiv' : 'Inaktiv' }}
            </span>
          </div>
          <div class="flex gap-2">
            <button @click="onExportPDF" class="btn-secondary text-xs no-print">
              <i class="ph ph-file-pdf text-base"></i> PDF Export
            </button>
            <button @click="window.print()" class="btn-secondary text-xs no-print">
              <i class="ph ph-printer text-base"></i> Drucken
            </button>
          </div>
        </div>

        <!-- Größen -->
        <div class="mb-5">
          <h3 class="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-3">Größen</h3>
          <div class="grid grid-cols-4 sm:grid-cols-7 gap-2">
            <div v-for="g in kameradenGroessen(selectedKamerad)" :key="g.label"
              class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-2.5 text-center border border-gray-100 dark:border-gray-600">
              <div class="text-xs text-gray-400 dark:text-gray-500 mb-0.5">{{ g.label }}</div>
              <div class="font-bold text-gray-800 dark:text-gray-100 text-sm">{{ g.wert || '–' }}</div>
            </div>
          </div>
        </div>

        <!-- Ausrüstung -->
        <div>
          <h3 class="text-xs font-semibold text-gray-400 dark:text-gray-500 uppercase tracking-wider mb-3">
            Zugewiesene Ausrüstung ({{ ausruestungFuerKamerad(selectedKamerad).length }})
          </h3>
          <div v-if="ausruestungFuerKamerad(selectedKamerad).length" class="space-y-2">
            <div v-for="a in ausruestungFuerKamerad(selectedKamerad)" :key="a.Id"
              @click="openAusruestungDetail(a, selectedKamerad)"
              class="bg-gray-50 dark:bg-gray-700/40 rounded-xl p-4 border border-gray-100 dark:border-gray-600 cursor-pointer hover:border-purple-300 dark:hover:border-purple-600 hover:bg-purple-50 dark:hover:bg-purple-900/10 transition-colors">
              <div class="flex items-start justify-between gap-3">
                <div class="flex-1 min-w-0">
                  <div class="flex items-center gap-2 flex-wrap mb-2">
                    <span class="font-semibold text-gray-800 dark:text-gray-100 text-sm">{{ typLabel(a.Ausruestungstyp, typen) }}</span>
                    <span v-if="a.Seriennummer" class="text-xs font-mono text-gray-400 bg-gray-100 dark:bg-gray-700 px-1.5 py-0.5 rounded">{{ a.Seriennummer }}</span>
                    <span :class="statusBadge(a.Status)">{{ a.Status }}</span>
                  </div>
                  <div class="grid grid-cols-1 sm:grid-cols-2 gap-1.5 text-xs">
                    <div class="flex items-center gap-2">
                      <span class="text-gray-400 w-28 flex-shrink-0">Letzte Prüfung:</span>
                      <span v-if="letzteAktion(a.Id, 'pruefung')" class="font-medium text-gray-700 dark:text-gray-300">
                        {{ fmtDate(letzteAktion(a.Id, 'pruefung').Datum) }}
                        <span :class="letzteAktion(a.Id, 'pruefung').Ergebnis === 'Bestanden' ? 'text-emerald-600' : 'text-red-600'">
                          · {{ letzteAktion(a.Id, 'pruefung').Ergebnis }}
                        </span>
                      </span>
                      <span v-else class="text-gray-400 italic">nicht erfasst</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="text-gray-400 w-28 flex-shrink-0">Letzte Wäsche:</span>
                      <span v-if="letzteAktion(a.Id, 'waesche')" class="font-medium text-gray-700 dark:text-gray-300">
                        {{ fmtDate(letzteAktion(a.Id, 'waesche').Datum) }}
                        <span class="text-gray-400">· {{ letzteAktion(a.Id, 'waesche').Waescheart }}</span>
                      </span>
                      <span v-else class="text-gray-400 italic">nicht erfasst</span>
                    </div>
                    <div v-if="waeschenInfo(a.Id, a.Ausruestungstyp)" class="flex items-center gap-2">
                      <span class="text-gray-400 w-28 flex-shrink-0">Wäschen gesamt:</span>
                      <span :class="['font-medium',
                        waeschenInfo(a.Id, a.Ausruestungstyp).count >= waeschenInfo(a.Id, a.Ausruestungstyp).max ? 'text-red-600'
                        : waeschenInfo(a.Id, a.Ausruestungstyp).count / waeschenInfo(a.Id, a.Ausruestungstyp).max >= 0.9 ? 'text-orange-500'
                        : 'text-gray-700 dark:text-gray-300']">
                        {{ waeschenInfo(a.Id, a.Ausruestungstyp).count }}/{{ waeschenInfo(a.Id, a.Ausruestungstyp).max }}
                      </span>
                    </div>
                    <div v-if="a.Naechste_Pruefung" class="flex items-center gap-2">
                      <span class="text-gray-400 w-28 flex-shrink-0">Nächste Prüfung:</span>
                      <span :class="fmtDateRel(a.Naechste_Pruefung)?.cls || 'text-gray-600'" class="font-medium">
                        {{ fmtDate(a.Naechste_Pruefung) }}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <div v-else class="text-sm text-gray-400 text-center py-6 bg-gray-50 dark:bg-gray-700/30 rounded-xl">
            Keine Ausrüstung zugeordnet
          </div>
        </div>

        <div class="flex justify-between gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700 no-print">
          <button @click="openKameradenForm(selectedKamerad); modal.kameradenDetail = false" class="btn-secondary">
            Bearbeiten
          </button>
          <button @click="modal.kameradenDetail = false" class="btn-primary">Schließen</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import {
  modal, selectedKamerad, typen,
  ausruestungFuerKamerad, kameradenGroessen, letzteAktion, waeschenInfo,
  openAusruestungDetail, openKameradenForm, showToast, pruefungen, ausruestung,
} from '../../store.js'
import { fmtDate, fmtDateRel, typLabel, statusBadge } from '../../utils/formatters.js'
import { exportPDF } from '../../utils/pdf.js'

function onExportPDF() {
  exportPDF(selectedKamerad.value, {
    pruefungen, ausruestung, typen,
    kameradenGroessen,
    ausruestungFuerKamerad,
    showToast,
  })
}
</script>
