<template>
  <Teleport to="body">
    <div v-if="modal.massenPruefung" class="modal-backdrop">
      <div class="modal-box max-w-md">
        <h2 class="text-lg font-bold mb-1">Massenprüfung erfassen</h2>
        <div class="text-sm text-gray-500 dark:text-gray-400 mb-4">
          {{ selectedIds.length }} Ausrüstungsstück{{ selectedIds.length > 1 ? 'e' : '' }} werden geprüft. Nächstes Prüfdatum wird automatisch berechnet.
        </div>
        <div class="grid gap-3">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label">Datum</label>
              <input v-model="form.massenPruefung.datum" type="date" class="input" />
            </div>
            <div>
              <label class="label">Ergebnis</label>
              <select v-model="form.massenPruefung.ergebnis" class="input">
                <option>Bestanden</option>
                <option>Eingeschränkt</option>
                <option>Nicht bestanden</option>
              </select>
            </div>
          </div>
          <div>
            <label class="label">Prüfer</label>
            <input v-model="form.massenPruefung.pruefer" type="text" class="input" placeholder="Name des Prüfers" />
          </div>
          <div>
            <label class="label">Notizen</label>
            <textarea v-model="form.massenPruefung.notizen" rows="2" class="input resize-none"></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.massenPruefung = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveMassenPruefung" class="btn-primary bg-orange-500 hover:bg-orange-600">
            <i class="ph ph-clipboard-text"></i> {{ selectedIds.length }} Stücke speichern
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, selectedIds, saveMassenPruefung } from '../../store.js'
</script>
