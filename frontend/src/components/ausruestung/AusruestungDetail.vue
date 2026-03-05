<template>
  <Teleport to="body">
    <div v-if="modal.ausruestungDetail && selectedAusruestung" class="modal-backdrop" @click.self="modal.ausruestungDetail = false">
      <div class="modal-box" style="max-width:42rem;max-height:85vh;overflow-y:auto">
        <div class="flex items-start justify-between mb-4">
          <div class="flex items-start gap-3 min-w-0 flex-1">
            <img v-if="typFoto" :src="typFoto"
              class="w-16 h-16 object-cover rounded-lg border border-gray-200 dark:border-gray-600 shrink-0 cursor-pointer hover:opacity-90"
              @click="window.open(typFoto, '_blank')" title="Beispielfoto vergrößern" />
            <div class="min-w-0">
              <h2 class="text-lg font-bold text-gray-900 dark:text-white">
                {{ selectedAusruestung.Ausruestungstyp || 'Ausrüstungsstück' }}
              </h2>
              <div class="text-sm text-gray-500 dark:text-gray-400 mt-0.5 font-mono">{{ selectedAusruestung.Seriennummer || '–' }}</div>
            </div>
          </div>
          <span :class="statusBadge(selectedAusruestung.Status)" class="shrink-0 ml-2">{{ selectedAusruestung.Status }}</span>
        </div>

        <!-- Info-Grid -->
        <div class="grid grid-cols-2 md:grid-cols-3 gap-3 mb-5 text-sm">
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
            <div class="text-xs text-gray-400 dark:text-gray-500 mb-0.5">Kamerad</div>
            <div class="font-medium text-gray-800 dark:text-gray-100">{{ selectedAusruestung.Kamerad || '–' }}</div>
          </div>
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
            <div class="text-xs text-gray-400 dark:text-gray-500 mb-0.5">Herstellungsdatum</div>
            <div class="font-medium text-gray-800 dark:text-gray-100">{{ fmtDate(selectedAusruestung.Herstellungsdatum) || '–' }}</div>
          </div>
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
            <div class="text-xs text-gray-400 dark:text-gray-500 mb-0.5">Lebensende</div>
            <div class="font-medium" :class="selectedAusruestung.Lebensende_Datum && new Date(selectedAusruestung.Lebensende_Datum) < new Date() ? 'text-red-600 dark:text-red-400' : 'text-gray-800 dark:text-gray-100'">
              {{ fmtDate(selectedAusruestung.Lebensende_Datum) || '–' }}
            </div>
          </div>
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
            <div class="text-xs text-gray-400 dark:text-gray-500 mb-0.5">Nächste Prüfung</div>
            <template v-for="rel in [fmtDateRel(selectedAusruestung.Naechste_Pruefung)]">
              <div v-if="rel" :class="[rel.cls, 'font-semibold text-sm']">{{ rel.label }}</div>
              <div v-else class="font-medium text-gray-800 dark:text-gray-100">–</div>
            </template>
          </div>
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
            <div class="text-xs text-gray-400 dark:text-gray-500 mb-0.5">Wäschen</div>
            <template v-if="waeschenInfo(selectedAusruestung.Id, selectedAusruestung.Ausruestungstyp)" v-for="wi in [waeschenInfo(selectedAusruestung.Id, selectedAusruestung.Ausruestungstyp)]">
              <div class="font-semibold text-sm" :class="wi.count >= wi.max ? 'text-red-600 dark:text-red-400' : wi.count / wi.max >= 0.9 ? 'text-orange-500' : 'text-gray-800 dark:text-gray-100'">{{ wi.count }} / {{ wi.max }}</div>
            </template>
            <div v-else class="font-medium text-gray-800 dark:text-gray-100">{{ (waescheByAusruestung.get(selectedAusruestung.Id) || []).length }}</div>
          </div>
          <div class="bg-gray-50 dark:bg-gray-700/50 rounded-lg p-3">
            <div class="text-xs text-gray-400 dark:text-gray-500 mb-0.5">QR-Code</div>
            <div class="font-mono text-xs text-gray-600 dark:text-gray-300 break-all">{{ selectedAusruestung.QR_Code || '–' }}</div>
          </div>
        </div>

        <!-- Ausgaben-History -->
        <div class="mb-4">
          <h3 class="text-sm font-semibold text-gray-600 dark:text-gray-300 mb-2 flex items-center gap-1.5">
            <i class="ph ph-sign-out"></i> Ausgaben
            <span class="text-xs font-normal text-gray-400">({{ (ausgabenByAusruestung.get(selectedAusruestung.Id) || []).length }})</span>
          </h3>
          <div v-if="(ausgabenByAusruestung.get(selectedAusruestung.Id) || []).length" class="space-y-1.5">
            <div v-for="ag in [...(ausgabenByAusruestung.get(selectedAusruestung.Id) || [])].sort((a,b) => new Date(b.Ausgabedatum||0) - new Date(a.Ausgabedatum||0))"
              :key="ag.Id" class="flex items-center gap-3 text-sm bg-gray-50 dark:bg-gray-700/40 rounded-lg px-3 py-2">
              <i class="ph ph-sign-out text-blue-500 flex-shrink-0"></i>
              <span class="text-gray-500 dark:text-gray-400 w-20 flex-shrink-0">{{ fmtDate(ag.Ausgabedatum) }}</span>
              <span class="font-medium text-gray-800 dark:text-gray-100">{{ ag.Kamerad || '–' }}</span>
              <span v-if="ag.Rueckgabedatum" class="ml-auto text-xs text-gray-400">zurück {{ fmtDate(ag.Rueckgabedatum) }}</span>
              <span v-else class="ml-auto text-xs text-amber-500 font-semibold">noch ausgegeben</span>
            </div>
          </div>
          <div v-else class="text-xs text-gray-400 dark:text-gray-500 pl-1">Keine Ausgaben</div>
        </div>

        <!-- Prüfungs-History -->
        <div class="mb-4">
          <h3 class="text-sm font-semibold text-gray-600 dark:text-gray-300 mb-2 flex items-center gap-1.5">
            <i class="ph ph-clipboard-text"></i> Prüfungen
            <span class="text-xs font-normal text-gray-400">({{ (pruefungenByAusruestung.get(selectedAusruestung.Id) || []).length }})</span>
          </h3>
          <div v-if="(pruefungenByAusruestung.get(selectedAusruestung.Id) || []).length" class="space-y-1.5">
            <div v-for="p in [...(pruefungenByAusruestung.get(selectedAusruestung.Id) || [])].sort((a,b) => new Date(b.Datum||0) - new Date(a.Datum||0))"
              :key="p.Id" class="text-sm bg-gray-50 dark:bg-gray-700/40 rounded-lg px-3 py-2">
              <div class="flex items-center gap-3">
                <i class="ph ph-clipboard-text flex-shrink-0" :class="p.Ergebnis === 'Bestanden' ? 'text-emerald-500' : p.Ergebnis === 'Nicht bestanden' ? 'text-red-500' : 'text-orange-500'"></i>
                <span class="text-gray-500 dark:text-gray-400 w-20 flex-shrink-0">{{ fmtDate(p.Datum) }}</span>
                <span class="font-medium" :class="p.Ergebnis === 'Bestanden' ? 'text-emerald-700 dark:text-emerald-400' : p.Ergebnis === 'Nicht bestanden' ? 'text-red-600 dark:text-red-400' : 'text-orange-600 dark:text-orange-400'">{{ p.Ergebnis }}</span>
                <span class="text-gray-500 dark:text-gray-400">{{ p.Pruefer || '' }}</span>
                <span v-if="p.Notizen" class="ml-auto text-xs text-gray-400 truncate max-w-32">{{ p.Notizen }}</span>
              </div>
              <div v-if="p.Foto" class="mt-1.5">
                <img :src="p.Foto" class="w-full max-h-24 object-cover rounded-lg border border-gray-200 dark:border-gray-600 cursor-pointer hover:opacity-90" @click="window.open(p.Foto, '_blank')" title="Foto vergrößern" />
              </div>
            </div>
          </div>
          <div v-else class="text-xs text-gray-400 dark:text-gray-500 pl-1">Keine Prüfungen</div>
        </div>

        <!-- Schadens-History -->
        <div class="mb-4">
          <h3 class="text-sm font-semibold text-gray-600 dark:text-gray-300 mb-2 flex items-center justify-between gap-1.5">
            <span class="flex items-center gap-1.5">
              <i class="ph ph-warning"></i> Schäden
              <span class="text-xs font-normal text-gray-400">({{ (schadensByAusruestung.get(selectedAusruestung.Id) || []).length }})</span>
            </span>
            <button v-if="canEdit" @click="openSchaden(selectedAusruestung)"
              class="icon-btn text-xs hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400 px-2 py-1 rounded-lg">
              <i class="ph ph-plus mr-0.5"></i> Schaden dokumentieren
            </button>
          </h3>
          <div v-if="(schadensByAusruestung.get(selectedAusruestung.Id) || []).length" class="space-y-2">
            <div v-for="s in [...(schadensByAusruestung.get(selectedAusruestung.Id) || [])].sort((a,b) => new Date(b.Datum||0) - new Date(a.Datum||0))"
              :key="s.Id" class="text-sm bg-gray-50 dark:bg-gray-700/40 rounded-lg px-3 py-2">
              <div class="flex items-center gap-3">
                <i class="ph ph-warning text-red-500 flex-shrink-0"></i>
                <span class="text-gray-500 dark:text-gray-400 w-20 flex-shrink-0">{{ fmtDate(s.Datum) }}</span>
                <span class="font-medium text-gray-800 dark:text-gray-100 flex-1">{{ s.Beschreibung || 'Schaden dokumentiert' }}</span>
                <span class="text-xs text-gray-400">{{ s.Erstellt_Von || '' }}</span>
                <button v-if="canEdit" @click="deleteSchaden(s)"
                  class="icon-btn hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400 shrink-0">
                  <i class="ph ph-trash text-sm"></i>
                </button>
              </div>
              <div v-if="s.Foto" class="mt-1.5">
                <img :src="s.Foto"
                  class="w-full max-h-40 object-cover rounded-lg border border-gray-200 dark:border-gray-600 cursor-pointer hover:opacity-90"
                  @click="window.open(s.Foto, '_blank')" title="Foto vergrößern" />
              </div>
            </div>
          </div>
          <div v-else class="text-xs text-gray-400 dark:text-gray-500 pl-1">Keine Schäden dokumentiert</div>
        </div>

        <!-- Wäsche-History -->
        <div class="mb-5">
          <h3 class="text-sm font-semibold text-gray-600 dark:text-gray-300 mb-2 flex items-center gap-1.5">
            <i class="ph ph-washing-machine"></i> Wäschen
            <span class="text-xs font-normal text-gray-400">({{ (waescheByAusruestung.get(selectedAusruestung.Id) || []).length }})</span>
          </h3>
          <div v-if="(waescheByAusruestung.get(selectedAusruestung.Id) || []).length" class="space-y-1.5">
            <div v-for="w in [...(waescheByAusruestung.get(selectedAusruestung.Id) || [])].sort((a,b) => new Date(b.Datum||0) - new Date(a.Datum||0))"
              :key="w.Id" class="flex items-center gap-3 text-sm bg-gray-50 dark:bg-gray-700/40 rounded-lg px-3 py-2">
              <i class="ph ph-washing-machine text-teal-500 flex-shrink-0"></i>
              <span class="text-gray-500 dark:text-gray-400 w-20 flex-shrink-0">{{ fmtDate(w.Datum) }}</span>
              <span class="font-medium text-gray-800 dark:text-gray-100">{{ w.Waescheart || 'Normal' }}</span>
              <span v-if="w.Notizen" class="ml-auto text-xs text-gray-400 truncate max-w-40">{{ w.Notizen }}</span>
            </div>
          </div>
          <div v-else class="text-xs text-gray-400 dark:text-gray-500 pl-1">Keine Wäschen</div>
        </div>

        <div class="flex justify-between gap-3 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button v-if="detailFromKamerad"
            @click="modal.ausruestungDetail = false; selectedKamerad.value = detailFromKamerad.value; modal.kameradenDetail = true"
            class="btn-secondary flex items-center gap-1.5">
            <i class="ph ph-arrow-left"></i> {{ detailFromKamerad.Vorname }} {{ detailFromKamerad.Name }}
          </button>
          <div v-else></div>
          <div class="flex gap-2">
            <button @click="openAusruestungForm(selectedAusruestung); modal.ausruestungDetail = false" class="btn-secondary">Bearbeiten</button>
            <button @click="modal.ausruestungDetail = false" class="btn-primary">Schließen</button>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed } from 'vue'
import {
  modal, selectedAusruestung, detailFromKamerad, selectedKamerad,
  ausgabenByAusruestung, pruefungenByAusruestung, waescheByAusruestung,
  schadensByAusruestung, waeschenInfo, openAusruestungForm,
  openSchaden, deleteSchaden, canEdit, typen,
} from '../../store.js'
import { fmtDate, fmtDateRel, statusBadge } from '../../utils/formatters.js'

const typFoto = computed(() =>
  typen.value.find(t => t.Bezeichnung === selectedAusruestung.value?.Ausruestungstyp)?.Foto || null
)
</script>
