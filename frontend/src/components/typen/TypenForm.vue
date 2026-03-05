<template>
  <Teleport to="body">
    <div v-if="modal.typForm" class="modal-backdrop">
      <div class="modal-box">
        <h2 class="text-lg font-bold mb-5">{{ form.typ.Id ? 'Typ bearbeiten' : 'Neuer Typ' }}</h2>
        <div class="grid gap-3">
          <div>
            <label class="label">Kategorie</label>
            <input v-model="form.typ.Typ" class="input" list="typ-kat-list"
              placeholder="z.B. Jacke, Helm, Flammschutzhaube …" @change="onTypChange" />
            <datalist id="typ-kat-list">
              <option v-for="k in typenKategorien" :key="k" :value="k" />
            </datalist>
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="label">Bezeichnung / Modell</label>
              <input v-model="form.typ.Bezeichnung" class="input" placeholder="z.B. F130" />
            </div>
            <div>
              <label class="label">Hersteller</label>
              <input v-model="form.typ.Hersteller" class="input" placeholder="z.B. Schubert" />
            </div>
          </div>
          <div>
            <label class="label">Norm</label>
            <div v-if="normenFuerAktuellenTyp.length">
              <select v-model="form.typ._normWahl" class="input" @change="onNormSelected">
                <option value="">– Norm wählen –</option>
                <option v-for="n in normenFuerAktuellenTyp" :key="n.Id" :value="n.Bezeichnung">{{ n.Bezeichnung }}</option>
                <option value="__frei__">Freie Eingabe…</option>
              </select>
              <input v-if="form.typ._normWahl === '__frei__'" v-model="form.typ.Norm" class="input mt-2" placeholder="Norm eingeben…" />
              <div v-if="form.typ._normHinweis" class="text-xs text-amber-600 dark:text-amber-400 mt-1.5 bg-amber-50 dark:bg-amber-900/20 p-2 rounded-lg">
                ℹ️ {{ form.typ._normHinweis }}
              </div>
            </div>
            <input v-else v-model="form.typ.Norm" class="input" placeholder="z.B. DIN EN 469" />
          </div>
          <div class="grid grid-cols-3 gap-3">
            <div>
              <label class="label">Max. Lebensdauer (Jahre)</label>
              <input v-model.number="form.typ.Max_Lebensdauer_Jahre" type="number" class="input" />
            </div>
            <div>
              <label class="label">Prüfintervall (Monate)</label>
              <input v-model.number="form.typ.Pruefintervall_Monate" type="number" class="input" />
            </div>
            <div>
              <label class="label">Max. Wäschen</label>
              <input v-model.number="form.typ.Max_Waeschen" type="number" class="input" placeholder="z.B. 50" />
            </div>
          </div>
          <div>
            <label class="label">Beschreibung</label>
            <textarea v-model="form.typ.Beschreibung" rows="2" class="input resize-none"></textarea>
          </div>
          <div>
            <label class="label">Beispielfoto (optional)</label>
            <div class="flex gap-2">
              <label class="btn-secondary cursor-pointer text-sm flex items-center gap-1.5">
                <i class="ph ph-camera"></i> Foto aufnehmen
                <input type="file" accept="image/*" capture="environment"
                  @change="e => onFotoUpload(e, url => form.typ.Foto = url)" class="hidden" />
              </label>
              <label class="btn-secondary cursor-pointer text-sm flex items-center gap-1.5">
                <i class="ph ph-image"></i> Datei wählen
                <input type="file" accept="image/*"
                  @change="e => onFotoUpload(e, url => form.typ.Foto = url)" class="hidden" />
              </label>
            </div>
            <div v-if="form.typ.Foto" class="mt-2 relative">
              <img :src="form.typ.Foto"
                class="w-full max-h-40 object-cover rounded-lg border border-gray-200 dark:border-gray-600" />
              <button @click="form.typ.Foto = null"
                class="absolute top-1 right-1 bg-red-600 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-700">
                <i class="ph ph-x"></i>
              </button>
            </div>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.typForm = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveTyp" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, typenKategorien, normenFuerAktuellenTyp, onTypChange, onNormSelected, saveTyp, onFotoUpload } from '../../store.js'
</script>
