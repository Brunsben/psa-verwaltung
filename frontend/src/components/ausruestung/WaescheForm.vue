<template>
  <Teleport to="body">
    <div v-if="modal.waesche" class="modal-backdrop">
      <div class="modal-box max-w-md">
        <h2 class="text-lg font-bold mb-1">Wäsche erfassen</h2>
        <div class="text-sm text-gray-500 dark:text-gray-400 mb-3">{{ form.aktion.Seriennummer }} – {{ form.aktion.Ausruestungstyp }}</div>

        <!-- Wäschezähler -->
        <template v-if="wi">
          <div class="flex items-center gap-2 text-sm px-3 py-2 rounded-lg mb-4"
            :class="wi.count + 1 >= wi.max
              ? 'bg-red-50 dark:bg-red-900/20 text-red-700 dark:text-red-400'
              : wi.count + 1 >= wi.max * 0.9
                ? 'bg-orange-50 dark:bg-orange-900/20 text-orange-700 dark:text-orange-400'
                : 'bg-gray-50 dark:bg-gray-700/50 text-gray-600 dark:text-gray-400'">
            <i class="ph ph-washing-machine"></i>
            <span>Dies wird Wäsche <strong>{{ wi.count + 1 }}</strong> von max. {{ wi.max }}</span>
            <span v-if="wi.count + 1 >= wi.max" class="ml-auto font-semibold">⚠ Limit erreicht!</span>
            <span v-else-if="wi.count + 1 >= wi.max * 0.9" class="ml-auto font-semibold">Limit fast erreicht</span>
          </div>
        </template>

        <div class="grid gap-3">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label">Datum</label>
              <input v-model="form.waesche.datum" type="date" class="input" />
            </div>
            <div>
              <label class="label">Art</label>
              <select v-model="form.waesche.art" class="input">
                <option>Normal</option>
                <option>Spezialreinigung</option>
                <option>Dekontamination</option>
              </select>
            </div>
          </div>
          <div>
            <label class="label">Notizen</label>
            <textarea v-model="form.waesche.notizen" rows="2" class="input resize-none"></textarea>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.waesche = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveWaesche" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed } from 'vue'
import { modal, form, saveWaesche, waeschenInfo } from '../../store.js'

const wi = computed(() => waeschenInfo(form.aktion.Id, form.aktion.Ausruestungstyp))
</script>
