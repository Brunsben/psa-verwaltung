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
            <p v-if="duplikatWarnung" class="text-xs text-orange-600 dark:text-orange-400 mt-1">⚠ {{ duplikatWarnung }}</p>
          </div>
          <div>
            <label class="label">Größe</label>
            <input v-model="form.ausruestung.Groesse" class="input" list="groesse-list" placeholder="z. B. XL, 52, 52K, 42/170 …" />
            <datalist id="groesse-list">
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
import { modal, form, typen, ausruestung, kameradenliste, saveAusruestung, autoFillAusruestungDaten, autoFillLebensdauer } from '../../store.js'

// Duplikat-Warnung: gleiche Seriennummer + gleicher Typ (anderes Stück)
const duplikatWarnung = computed(() => {
  const sn  = String(form.ausruestung.Seriennummer || '').trim()
  const typ = form.ausruestung.Ausruestungstyp
  if (!sn || !typ) return null
  const existing = ausruestung.value.find(a =>
    a.Seriennummer === sn &&
    a.Ausruestungstyp === typ &&
    a.Id !== form.ausruestung.Id
  )
  return existing ? `Seriennummer bereits für diesen Typ vorhanden` : null
})

// Vorhandene Größen des gleichen Typs als Vorschläge – dynamisch, selbstbauend
const groesseOptions = computed(() => {
  const typ = form.ausruestung.Ausruestungstyp
  if (!typ) return []
  const sizes = new Set(
    ausruestung.value
      .filter(a => a.Ausruestungstyp === typ && a.Groesse)
      .map(a => String(a.Groesse).trim())
  )
  return [...sizes].sort((a, b) => {
    const na = parseFloat(a), nb = parseFloat(b)
    if (!isNaN(na) && !isNaN(nb)) return na - nb
    return a.localeCompare(b, 'de')
  })
})
</script>
