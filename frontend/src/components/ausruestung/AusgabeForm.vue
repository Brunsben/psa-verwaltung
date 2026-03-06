<template>
  <Teleport to="body">
    <div v-if="modal.ausgabe" class="modal-backdrop">
      <div class="modal-box max-w-md">
        <h2 class="text-lg font-bold mb-1">Ausgabe erfassen</h2>
        <div class="text-sm text-gray-500 dark:text-gray-400 mb-5">{{ form.aktion.Seriennummer }} – {{ form.aktion.Ausruestungstyp }}</div>
        <div class="grid gap-3">
          <div>
            <label class="label">Kamerad</label>
            <select v-model="form.ausgabe.Kamerad_Id" class="input">
              <option value="">– Rückgabe (kein Kamerad) –</option>
              <option v-for="k in kameradenliste" :key="k.Id" :value="k.Id">{{ k.label }}</option>
            </select>
            <div v-if="ausruestungGroesseHint" class="mt-1.5 flex items-center gap-1.5 text-xs px-3 py-1.5 rounded-lg"
              :class="ausruestungGroesseHint.mismatch
                ? 'bg-orange-50 dark:bg-orange-900/20 text-orange-700 dark:text-orange-300 border border-orange-200 dark:border-orange-800'
                : 'bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300'">
              <i :class="ausruestungGroesseHint.mismatch ? 'ph ph-warning text-sm flex-shrink-0' : 'ph ph-info text-sm flex-shrink-0'"></i>
              <span v-if="ausruestungGroesseHint.mismatch">
                ⚠ Größe weicht ab! Bekannt ({{ ausruestungGroesseHint.label }}): <strong>{{ ausruestungGroesseHint.val || '–' }}</strong>
              </span>
              <span v-else>
                Bekannte Größe ({{ ausruestungGroesseHint.label }}): <strong>{{ ausruestungGroesseHint.val || '–' }}</strong>
              </span>
            </div>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label">Ausgabedatum</label>
              <input v-model="form.ausgabe.datum" type="date" class="input" />
            </div>
          </div>
          <div>
            <label class="label">Notizen</label>
            <textarea v-model="form.ausgabe.notizen" rows="2" class="input resize-none"></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.ausgabe = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveAusgabe" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, kameradenliste, ausruestungGroesseHint, saveAusgabe } from '../../store.js'
</script>
