<template>
  <Teleport to="body">
    <div v-if="modal.pruefung" class="modal-backdrop">
      <div class="modal-box max-w-md">
        <h2 class="text-lg font-bold mb-1">Prüfung erfassen</h2>
        <div class="text-sm text-gray-500 dark:text-gray-400 mb-5">{{ form.aktion.Seriennummer }} – {{ form.aktion.Ausruestungstyp }}</div>
        <div class="grid gap-3">
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label">Datum</label>
              <input v-model="form.pruefung.datum" type="date" class="input" @change="recalcNaechstePruefung" />
            </div>
            <div>
              <label class="label">Ergebnis</label>
              <select v-model="form.pruefung.ergebnis" class="input">
                <option>Bestanden</option>
                <option>Nicht bestanden</option>
                <option>Eingeschränkt</option>
              </select>
            </div>
          </div>
          <div>
            <label class="label">Prüfer</label>
            <input v-model="form.pruefung.pruefer" class="input" placeholder="Name des Prüfers" />
          </div>
          <div>
            <label class="label">Nächste Prüfung</label>
            <input v-model="form.pruefung.naechste" type="date" class="input" />
          </div>
          <div>
            <label class="label">Notizen</label>
            <textarea v-model="form.pruefung.notizen" rows="2" class="input resize-none"></textarea>
          </div>
          <div>
            <label class="label">Foto (optional)</label>
            <div class="flex gap-2">
              <label class="btn-secondary cursor-pointer flex items-center gap-1.5 text-xs flex-1 justify-center">
                <i class="ph ph-camera"></i> Foto aufnehmen
                <input type="file" accept="image/*" capture="environment" @change="onPruefungFoto" class="hidden" />
              </label>
              <label class="btn-secondary cursor-pointer flex items-center gap-1.5 text-xs flex-1 justify-center">
                <i class="ph ph-image"></i> Datei wählen
                <input type="file" accept="image/*" @change="onPruefungFoto" class="hidden" />
              </label>
            </div>
            <div v-if="form.pruefung.foto" class="mt-2 relative">
              <img :src="form.pruefung.foto" class="w-full max-h-40 object-cover rounded-lg border border-gray-200 dark:border-gray-600" />
              <button @click="form.pruefung.foto = ''" class="absolute top-1 right-1 bg-red-600 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs hover:bg-red-700">
                <i class="ph ph-x"></i>
              </button>
            </div>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.pruefung = false" class="btn-secondary">Abbrechen</button>
          <button @click="savePruefung" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, savePruefung, recalcNaechstePruefung, onPruefungFoto } from '../../store.js'
</script>
