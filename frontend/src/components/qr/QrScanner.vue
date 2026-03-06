<template>
  <Teleport to="body">
    <div v-if="modal.qrScanner" class="modal-backdrop">
      <div class="modal-box overflow-y-auto max-h-[90dvh]">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">
            {{ qrScanTarget === 'Seriennummer' ? 'Seriennummer scannen' : qrScanTarget === 'QR_Code' ? 'QR-Code scannen' : 'QR-Scanner' }}
          </h2>
          <button @click="close" class="icon-btn hover:bg-gray-100 dark:hover:bg-gray-700">
            <i class="ph ph-x text-base"></i>
          </button>
        </div>

        <!-- Kamera (ausgeblendet sobald Normal-Modus-Ergebnis vorliegt) -->
        <div id="qr-reader" class="rounded-lg overflow-hidden mb-3"
          :class="{ 'hidden': !!qrResult && !qrScanTarget }"></div>

        <!-- Feld-Modus: Bestätigung -->
        <div v-if="qrResult && qrScanTarget"
          class="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-700 rounded-lg px-3 py-2 text-sm text-emerald-700 dark:text-emerald-300 mb-2">
          <i class="ph ph-check-circle"></i> Übernommen: {{ qrResult }}
        </div>

        <!-- Normal-Modus: Ergebnisse nach dem Scan -->
        <template v-if="qrResult && !qrScanTarget">
          <div class="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-700 rounded-lg px-3 py-2 text-sm text-emerald-700 dark:text-emerald-300 mb-3">
            <i class="ph ph-check-circle"></i> Gescannt: <span class="font-mono break-all">{{ qrResult }}</span>
          </div>

          <!-- Treffer-Liste -->
          <div v-if="scanResults.length" class="space-y-2 mb-3">
            <div v-for="a in scanResults" :key="a.Id"
              class="bg-gray-50 dark:bg-gray-700/50 rounded-xl border border-gray-100 dark:border-gray-600 p-3">
              <div class="flex items-start justify-between gap-2">
                <div class="min-w-0 flex-1">
                  <div class="font-semibold text-sm text-gray-900 dark:text-white truncate">{{ typLabel(a.Ausruestungstyp, typen) }}</div>
                  <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                    {{ a.Seriennummer || '–' }}<template v-if="kameradName(a.Kamerad_Id)"> · {{ kameradName(a.Kamerad_Id) }}</template>
                  </div>
                </div>
                <span :class="[statusBadge(a.Status), 'shrink-0 text-xs px-2 py-0.5 rounded-full font-medium']">{{ a.Status || '–' }}</span>
              </div>
              <div class="flex gap-0.5 mt-2">
                <button @click="doDetail(a)" title="Details" class="icon-btn hover:text-teal-600 hover:bg-teal-50 dark:hover:bg-teal-900/20 dark:hover:text-teal-400">
                  <i class="ph ph-eye text-base"></i>
                </button>
                <template v-if="canEdit">
                  <button @click="doAusgabe(a)" title="Ausgabe / Rückgabe" class="icon-btn hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 dark:hover:text-blue-400">
                    <i class="ph ph-arrows-left-right text-base"></i>
                  </button>
                  <button @click="doPruefung(a)" title="Prüfung erfassen" class="icon-btn hover:text-orange-500 hover:bg-orange-50 dark:hover:bg-orange-900/20 dark:hover:text-orange-400">
                    <i class="ph ph-clipboard-text text-base"></i>
                  </button>
                  <button @click="doWaesche(a)" title="Wäsche erfassen" class="icon-btn hover:text-teal-600 hover:bg-teal-50 dark:hover:bg-teal-900/20 dark:hover:text-teal-400">
                    <i class="ph ph-washing-machine text-base"></i>
                  </button>
                  <button @click="doEdit(a)" title="Bearbeiten" class="icon-btn hover:text-gray-700 hover:bg-gray-100 dark:hover:bg-gray-600 dark:hover:text-gray-200">
                    <i class="ph ph-pencil-simple text-base"></i>
                  </button>
                  <button @click="doDelete(a)" title="Löschen" class="icon-btn hover:text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 dark:hover:text-red-400">
                    <i class="ph ph-trash text-base"></i>
                  </button>
                </template>
              </div>
            </div>
          </div>
          <p v-else class="text-sm text-gray-500 dark:text-gray-400 text-center py-2 mb-3">
            Kein Ausrüstungsstück mit diesem Code gefunden.
          </p>

          <!-- Neues Stück anlegen -->
          <button v-if="canEdit" @click="doNewWithCode"
            class="btn-secondary w-full justify-center text-sm mb-2">
            <i class="ph ph-plus mr-1.5"></i> Neues Ausrüstungsstück mit diesem Code anlegen
          </button>
        </template>

        <div v-if="qrError"
          class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg px-3 py-2 text-sm text-red-600 dark:text-red-400 mb-2">
          {{ qrError }}
        </div>

        <button @click="close" class="btn-secondary w-full justify-center mt-2">Schließen</button>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed, nextTick } from 'vue'
import {
  modal, qrResult, qrError, qrScanTarget, form, ausruestung, typen,
  showToast, canEdit, kameradName,
  openAusruestungDetail, openAusruestungForm,
  openAusgabe, openPruefung, openWaesche, deleteAusruestung,
} from '../../store.js'
import { typLabel, statusBadge } from '../../utils/formatters.js'

let scanner = null

// Alle Ausrüstungsstücke die den gescannten Code (QR oder Seriennummer) tragen
const scanResults = computed(() => {
  if (!qrResult.value || qrScanTarget.value) return []
  const code = qrResult.value
  return ausruestung.value.filter(a => a.QR_Code === code || a.Seriennummer === code)
})

async function start() {
  qrResult.value = ''
  qrError.value  = ''
  await nextTick()
  if (typeof Html5Qrcode === 'undefined') {
    qrError.value = 'QR-Scanner-Bibliothek nicht geladen.'
    return
  }
  scanner = new Html5Qrcode('qr-reader')
  scanner.start(
    { facingMode: 'environment' },
    { fps: 10, qrbox: { width: 250, height: 250 } },
    (decodedText) => {
      qrResult.value = decodedText
      // Feld-Modus: Wert in Formularfeld schreiben und schließen
      if (qrScanTarget.value) {
        form.ausruestung[qrScanTarget.value] = decodedText
        showToast(`${qrScanTarget.value === 'QR_Code' ? 'QR-Code' : 'Seriennummer'} übernommen`)
        close()
        return
      }
      // Normal-Modus: Scanner stoppen, Ergebnisliste anzeigen
      if (scanner) {
        scanner.stop().catch(() => {})
        scanner = null
      }
    },
    () => {} // kein QR im Frame – ignorieren
  ).catch(err => {
    qrError.value = 'Kamera konnte nicht gestartet werden: ' + (err.message || err)
  })
}

async function close() {
  if (scanner) {
    try { await scanner.stop() } catch(e) {}
    scanner = null
  }
  modal.qrScanner    = false
  qrResult.value     = ''
  qrError.value      = ''
  qrScanTarget.value = null
}

// Action-Handler: Scanner schließen, dann Aktion öffnen
function doDetail(a)   { close(); openAusruestungDetail(a) }
function doAusgabe(a)  { close(); openAusgabe(a) }
function doPruefung(a) { close(); openPruefung(a) }
function doWaesche(a)  { close(); openWaesche(a) }
function doEdit(a)     { close(); openAusruestungForm(a) }
async function doDelete(a) { close(); await deleteAusruestung(a) }

function doNewWithCode() {
  const code = qrResult.value
  close()
  openAusruestungForm({ QR_Code: code })
}

defineExpose({ start })
</script>
