<template>
  <Teleport to="body">
    <div v-if="modal.massenWaesche" class="modal-backdrop">
      <div class="modal-box max-w-md">
        <h2 class="text-lg font-bold mb-1">Massenwäsche erfassen</h2>
        <div class="text-sm text-gray-500 dark:text-gray-400 mb-4">
          {{ selectedIds.length }} Ausrüstungsstück{{ selectedIds.length > 1 ? 'e' : '' }} werden als gewaschen markiert.
        </div>
        <div class="grid gap-3">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label">Datum</label>
              <input v-model="form.massenWaesche.datum" type="date" class="input" />
            </div>
            <div>
              <label class="label">Art</label>
              <select v-model="form.massenWaesche.art" class="input">
                <option>Normal</option>
                <option>Spezialreinigung</option>
                <option>Dekontamination</option>
              </select>
            </div>
          </div>
          <div>
            <label class="label">Notizen</label>
            <textarea v-model="form.massenWaesche.notizen" rows="2" class="input resize-none"></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.massenWaesche = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveMassenWaesche" class="btn-primary">
            <i class="ph ph-washing-machine"></i> {{ selectedIds.length }} Stücke speichern
          </button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, selectedIds, saveMassenWaesche } from '../../store.js'
</script>
