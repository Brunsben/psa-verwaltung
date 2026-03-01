<template>
  <Teleport to="body">
    <div v-if="modal.rueckgabe" class="modal-backdrop">
      <div class="modal-box max-w-sm">
        <h2 class="text-lg font-bold mb-1">Rückgabe erfassen</h2>
        <div class="text-sm text-gray-500 dark:text-gray-400 mb-5">
          {{ form.rueckgabeAusgabe?.Ausruestungstyp }} – {{ form.rueckgabeAusgabe?.Seriennummer }}<br>
          <span class="text-xs">Kamerad: {{ form.rueckgabeAusgabe?.Kamerad || '–' }}</span>
        </div>
        <div>
          <label class="label">Rückgabedatum</label>
          <input v-model="form.rueckgabe.datum" type="date" class="input" />
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.rueckgabe = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveRueckgabe" class="btn-primary">
            <i class="ph ph-arrow-u-up-left"></i> Rückgabe speichern
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, saveRueckgabe } from '../../store.js'
</script>
