<template>
  <Teleport to="body">
    <div v-if="modal.normenForm" class="modal-backdrop">
      <div class="modal-box max-w-lg">
        <h2 class="text-lg font-bold mb-5">{{ form.norm.Id ? 'Norm bearbeiten' : 'Neue Norm' }}</h2>
        <div class="grid gap-3">
          <div>
            <label class="label">Normbezeichnung *</label>
            <input v-model="form.norm.Bezeichnung" class="input font-mono" placeholder="z.B. DIN EN 469:2020" />
          </div>
          <div>
            <label class="label">Kategorie (Ausrüstungstyp)</label>
            <input v-model="form.norm.Ausruestungstyp_Kategorie" class="input" list="norm-kat-list"
              placeholder="z.B. Jacke, Helm, Flammschutzhaube …" />
            <datalist id="norm-kat-list">
              <option v-for="k in typenKategorien" :key="k" :value="k" />
            </datalist>
          </div>
          <div class="grid grid-cols-3 gap-3">
            <div>
              <label class="label">Prüfintervall (Monate)</label>
              <input v-model.number="form.norm.Pruefintervall_Monate" type="number" min="1" class="input" placeholder="12" />
            </div>
            <div>
              <label class="label">Max. Lebensdauer (Jahre)</label>
              <input v-model.number="form.norm.Max_Lebensdauer_Jahre" type="number" min="1" class="input" placeholder="10" />
            </div>
            <div>
              <label class="label">Max. Wäschen</label>
              <input v-model.number="form.norm.Max_Waeschen" type="number" min="1" class="input" placeholder="50" />
            </div>
          </div>
          <div>
            <label class="label">Beschreibung / Hinweis</label>
            <textarea v-model="form.norm.Beschreibung" rows="3" class="input resize-none" placeholder="Geltungsbereich, Besonderheiten..."></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-5 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.normenForm = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveNorm" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, typenKategorien, saveNorm } from '../../store.js'
</script>
