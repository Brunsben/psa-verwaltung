<template>
  <Teleport to="body">
    <div v-if="modal.passwortForm" class="modal-backdrop">
      <div class="modal-box max-w-sm">
        <h2 class="text-lg font-bold mb-5">Passwort ändern</h2>
        <div class="grid gap-3">
          <div>
            <label class="label">Aktuelles Passwort *</label>
            <input v-model="passwortChangeForm.altPasswort" type="password" class="input" placeholder="••••" autocomplete="current-password" />
          </div>
          <div>
            <label class="label">Neues Passwort *</label>
            <input v-model="passwortChangeForm.neuesPasswort" type="password" class="input" placeholder="••••" autocomplete="new-password" />
          </div>
          <div>
            <label class="label">Neues Passwort bestätigen *</label>
            <input v-model="passwortChangeForm.bestaetigung" type="password" class="input" placeholder="••••" autocomplete="new-password" @keyup.enter="savePasswort" />
          </div>
          <div v-if="passwortChangeForm.error" class="text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 rounded-lg px-3 py-2">
            {{ passwortChangeForm.error }}
          </div>
        </div>
        <div class="flex justify-end gap-3 mt-6 pt-4 border-t border-gray-100 dark:border-gray-700">
          <button @click="modal.passwortForm = false" class="btn-secondary">Abbrechen</button>
          <button @click="savePasswort" class="btn-primary">Speichern</button>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { modal, passwortChangeForm, savePasswort } from '../../store.js'
</script>
