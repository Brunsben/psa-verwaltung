<template>
  <Teleport to="body">
    <div v-if="modal.kameradenForm" class="modal-backdrop">
      <div class="modal-box">
        <h2 class="text-lg font-bold mb-5">{{ form.kamerad.Id ? 'Kamerad bearbeiten' : 'Neuer Kamerad' }}</h2>
        <div class="grid grid-cols-2 gap-3">
          <div>
            <label class="label">Vorname</label>
            <input v-model="form.kamerad.Vorname" class="input" placeholder="Max" />
          </div>
          <div>
            <label class="label">Name</label>
            <input v-model="form.kamerad.Name" class="input" placeholder="Mustermann" />
          </div>
          <div>
            <label class="label">Dienstgrad</label>
            <select v-model="form.kamerad.Dienstgrad" class="input">
              <option value="">– Bitte wählen –</option>
              <option v-for="dg in DIENSTGRADE" :key="dg" :value="dg">{{ dg }}</option>
            </select>
          </div>
          <div>
            <label class="label">E-Mail</label>
            <input v-model="form.kamerad.Email" type="email" class="input" placeholder="max@feuerwehr.de" />
          </div>
          <div>
            <label class="label">Jacke</label>
            <input v-model="form.kamerad.Jacke_Groesse" placeholder="z.B. 52" class="input" />
          </div>
          <div>
            <label class="label">Hose</label>
            <input v-model="form.kamerad.Hose_Groesse" placeholder="z.B. 52" class="input" />
          </div>
          <div>
            <label class="label">Stiefel (EU)</label>
            <input v-model="form.kamerad.Stiefel_Groesse" type="number" class="input" />
          </div>
          <div>
            <label class="label">Handschuh</label>
            <input v-model="form.kamerad.Handschuh_Groesse" placeholder="z.B. 9" class="input" />
          </div>
          <div>
            <label class="label">Hemd</label>
            <input v-model="form.kamerad.Hemd_Groesse" placeholder="z.B. 40/41" class="input" />
          </div>
          <div>
            <label class="label">Poloshirt</label>
            <input v-model="form.kamerad.Poloshirt_Groesse" placeholder="z.B. L" class="input" />
          </div>
          <div>
            <label class="label">Fleece/Softshell</label>
            <input v-model="form.kamerad.Fleece_Groesse" placeholder="z.B. L" class="input" />
          </div>
          <div class="col-span-2 flex items-center gap-2 mt-1">
            <input type="checkbox" v-model="form.kamerad.Aktiv" id="aktiv" class="w-4 h-4 accent-red-600 cursor-pointer" />
            <label for="aktiv" class="text-sm text-gray-700 dark:text-gray-300 cursor-pointer">Aktives Mitglied</label>
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.kameradenForm = false" class="btn-secondary">Abbrechen</button>
          <button @click="saveKamerad" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, form, DIENSTGRADE, saveKamerad } from '../../store.js'
</script>
