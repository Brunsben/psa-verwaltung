<template>
  <Teleport to="body">
    <div v-if="modal.benutzerForm" class="modal-backdrop">
      <div class="modal-box">
        <h2 class="text-lg font-bold mb-5">{{ form.benutzer.Id ? 'Benutzer bearbeiten' : 'Neuer Benutzer' }}</h2>
        <div class="grid grid-cols-2 gap-3">
          <div class="col-span-2">
            <label class="label">Benutzername *</label>
            <input v-model="form.benutzer.Benutzername" class="input" placeholder="max.mustermann" autocomplete="off" />
          </div>
          <div class="col-span-2">
            <label class="label">Passwort {{ form.benutzer.Id ? '(leer = unverändert)' : '*' }}</label>
            <input v-model="form.benutzer.PIN" class="input" :placeholder="form.benutzer.Id ? 'Leer lassen = unverändert' : 'Mind. 6 Zeichen'" type="password" autocomplete="new-password" />
          </div>
          <div>
            <label class="label">Rolle</label>
            <select v-model="form.benutzer.Rolle" class="input">
              <option>Admin</option>
              <option>Kleiderwart</option>
              <option>User</option>
            </select>
          </div>
          <div class="flex items-center gap-2 mt-5">
            <input type="checkbox" v-model="form.benutzer.Aktiv" id="benutzerAktiv" class="w-4 h-4 accent-red-600" />
            <label for="benutzerAktiv" class="label mb-0">Aktiv</label>
          </div>
          <div class="col-span-2">
            <label class="label">Verknüpfter Kamerad</label>
            <select v-model="form.benutzer.KameradId" class="input">
              <option value="">– Kein Kamerad –</option>
              <option v-for="k in kameraden" :key="k.Id" :value="String(k.Id)">{{ k.Vorname }} {{ k.Name }}</option>
            </select>
            <p class="text-xs text-gray-400 mt-1">Für Rolle "User": zeigt nur die eigene Ausrüstung</p>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.benutzerForm = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveBenutzer" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, kameraden, saveBenutzer } from '../../store.js'
</script>
