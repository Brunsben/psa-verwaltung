<template>
  <Teleport to="body">
    <div v-if="modal.schaden" class="modal-backdrop">
      <div class="modal-box">
        <h2 class="text-lg font-bold mb-5">Schaden dokumentieren</h2>
        <div class="space-y-3">
          <div>
            <label class="label">Datum</label>
            <input v-model="form.schaden.datum" type="date" class="input" />
          </div>
          <div>
            <label class="label">Beschreibung (optional)</label>
            <textarea v-model="form.schaden.beschreibung" rows="2" class="input resize-none"
              placeholder="z. B. Riss im Ärmel, fehlender Klettverschluss …"></textarea>
          </div>
          <div>
            <label class="label">Foto <span class="text-red-500">*</span></label>
            <div class="flex gap-2">
              <label class="btn-secondary cursor-pointer text-sm flex items-center gap-1.5">
                <i class="ph ph-camera"></i> Foto aufnehmen
                <input type="file" accept="image/*" capture="environment"
                  @change="e => onFotoUpload(e, url => form.schaden.foto = url)" class="hidden" />
              </label>
              <label class="btn-secondary cursor-pointer text-sm flex items-center gap-1.5">
                <i class="ph ph-image"></i> Datei wählen
                <input type="file" accept="image/*"
                  @change="e => onFotoUpload(e, url => form.schaden.foto = url)" class="hidden" />
              </label>
            </div>
            <div v-if="form.schaden.foto" class="mt-2 relative">
              <img :src="form.schaden.foto"
                class="w-full max-h-48 object-cover rounded-lg border border-gray-200 dark:border-gray-600" />
              <button @click="form.schaden.foto = null"
                class="absolute top-1 right-1 bg-red-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-700">
                <i class="ph ph-x"></i>
              </button>
            </div>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.schaden = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveSchaden" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, saveSchaden, onFotoUpload } from '../../store.js'
</script>
