<template>
  <Teleport to="body">
    <div v-if="modal.qrScanner" class="modal-backdrop">
      <div class="modal-box">
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-lg font-bold text-gray-900 dark:text-white">
            {{ qrScanTarget === 'Seriennummer' ? 'Seriennummer scannen' : qrScanTarget === 'QR_Code' ? 'QR-Code scannen' : 'QR-Scanner' }}
          </h2>
          <button @click="close" class="icon-btn hover:bg-gray-100 dark:hover:bg-gray-700">
            <i class="ph ph-x text-base"></i>
          </button>
        </div>

        <div id="qr-reader" class="rounded-lg overflow-hidden mb-3"></div>

        <div v-if="qrResult" class="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-700 rounded-lg px-3 py-2 text-sm text-emerald-700 dark:text-emerald-300 mb-2">
          <i class="ph ph-check-circle"></i> Erkannt: {{ qrResult }}
        </div>
        <div v-if="qrError" class="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-700 rounded-lg px-3 py-2 text-sm text-red-600 dark:text-red-400 mb-2">
          {{ qrError }}
        </div>

        <button @click="close" class="btn-secondary w-full justify-center mt-2">Schließen</button>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { nextTick } from 'vue'
import {
  modal, qrResult, qrError, qrScanTarget, form,
  ausruestung, showToast, openAusruestungDetail,
} from '../../store.js'

let scanner = null

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
      // Feld-Modus: gescannten Wert in Formularfeld schreiben
      if (qrScanTarget.value) {
        form.ausruestung[qrScanTarget.value] = decodedText
        showToast(`${qrScanTarget.value === 'QR_Code' ? 'QR-Code' : 'Seriennummer'} übernommen`)
        close()
        return
      }
      // Normal-Modus: Ausrüstung suchen und Detail öffnen
      const found = ausruestung.value.find(a =>
        a.QR_Code === decodedText || a.Seriennummer === decodedText
      )
      if (found) {
        close()
        openAusruestungDetail(found)
        showToast(`Gefunden: ${found.Ausruestungstyp || found.Seriennummer}`)
      } else {
        qrError.value = `Kein Ausrüstungsstück mit QR "${decodedText}" gefunden.`
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

// Startet Scanner wenn Modal geöffnet wird
defineExpose({ start })
</script>
