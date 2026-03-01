<template>
  <Teleport to="body">
    <div v-if="modal.ausruestungForm" class="modal-backdrop">
      <div class="modal-box">
        <h2 class="text-lg font-bold mb-5">{{ form.ausruestung.Id ? 'Ausrüstung bearbeiten' : 'Neues Ausrüstungsstück' }}</h2>
        <div class="grid grid-cols-2 gap-3">
          <div class="col-span-2">
            <label class="label">Typ</label>
            <select v-model="form.ausruestung.Ausruestungstyp" class="input" @change="autoFillAusruestungDaten">
              <option value="">– Typ wählen –</option>
              <option v-for="t in typen" :key="t.Id" :value="t.Bezeichnung">
                {{ t.Typ ? t.Typ + ': ' : '' }}{{ t.Bezeichnung }}{{ t.Hersteller ? ' – ' + t.Hersteller : '' }}
              </option>
            </select>
          </div>
          <div class="col-span-2">
            <label class="label">Kamerad</label>
            <select v-model="form.ausruestung.Kamerad" class="input">
              <option value="">– (kein / Lager) –</option>
              <option v-for="k in kameradenliste" :key="k.Id" :value="k.label">{{ k.label }}</option>
            </select>
          </div>
          <div>
            <label class="label">Seriennummer</label>
            <input v-model="form.ausruestung.Seriennummer" class="input" />
          </div>
          <div>
            <label class="label">Größe</label>
            <input v-model="form.ausruestung.Groesse" class="input" :list="groesseListId" :placeholder="groessePlaceholder" />
            <datalist v-if="groesseOptions.length" :id="groesseListId">
              <option v-for="o in groesseOptions" :key="o" :value="o" />
            </datalist>
          </div>
          <div>
            <label class="label">QR-Code</label>
            <input v-model="form.ausruestung.QR_Code" class="input" />
          </div>
          <div>
            <label class="label">Herstellungsdatum</label>
            <input v-model="form.ausruestung.Herstellungsdatum" type="date" class="input" @change="autoFillLebensdauer" />
          </div>
          <div>
            <label class="label">Lebensende</label>
            <input v-model="form.ausruestung.Lebensende_Datum" type="date" class="input" />
          </div>
          <div>
            <label class="label">Nächste Prüfung</label>
            <input v-model="form.ausruestung.Naechste_Pruefung" type="date" class="input" />
          </div>
          <div>
            <label class="label">Status</label>
            <select v-model="form.ausruestung.Status" class="input">
              <option>Lager</option>
              <option>Ausgegeben</option>
              <option>Reinigung</option>
              <option>In Reparatur</option>
              <option>Ausgesondert</option>
            </select>
          </div>
          <div class="col-span-2">
            <label class="label">Notizen</label>
            <textarea v-model="form.ausruestung.Notizen" rows="2" class="input resize-none"></textarea>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.ausruestungForm = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveAusruestung" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { computed } from 'vue'
import { modal, form, typen, kameradenliste, saveAusruestung, autoFillAusruestungDaten, autoFillLebensdauer } from '../../store.js'

const GROESSE_OPTIONEN = {
  'Jacke':            { label: 'Jacke',       options: ['XS','S','M','L','XL','XXL','3XL','44','46','48','50','52','54','56','58','60','62','64'] },
  'Hose':             { label: 'Hose',        options: ['XS','S','M','L','XL','XXL','3XL','44','46','48','50','52','54','56','58','60','62','64'] },
  'Stiefel':          { label: 'Stiefel (EU)',options: ['36','37','38','39','40','41','42','43','44','45','46','47','48'] },
  'Handschuh':        { label: 'Handschuh',   options: ['6','7','8','9','10','11','12','XS','S','M','L','XL','XXL'] },
  'Hemd':             { label: 'Hemd',        options: ['XS','S','M','L','XL','XXL','3XL'] },
  'Poloshirt':        { label: 'Poloshirt',   options: ['XS','S','M','L','XL','XXL','3XL'] },
  'Fleece/Softshell': { label: 'Fleece',      options: ['XS','S','M','L','XL','XXL','3XL'] },
}

const currentTypKat = computed(() => {
  const t = typen.value.find(t => t.Bezeichnung === form.ausruestung.Ausruestungstyp)
  return t?.Typ || ''
})

const groesseListId = 'groesse-list'
const groesseOptions = computed(() => GROESSE_OPTIONEN[currentTypKat.value]?.options || [])
const groessePlaceholder = computed(() => {
  const entry = GROESSE_OPTIONEN[currentTypKat.value]
  return entry ? `z. B. M, L, 44 (${entry.label})` : 'z. B. M, 44, 42'
})
</script>
