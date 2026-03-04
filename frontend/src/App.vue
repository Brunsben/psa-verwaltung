<template>
  <div>
    <!-- Login Screen -->
    <div v-if="!loggedIn && !needsSetup" class="fixed inset-0 z-50 bg-gray-50 dark:bg-gray-900 flex items-center justify-center p-4">
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl p-8 w-full max-w-sm border border-gray-100 dark:border-gray-700">
        <div class="text-center mb-6">
          <span class="text-4xl">🔥</span>
          <h1 class="text-xl font-bold text-gray-900 dark:text-white mt-2">FF Wietmarschen</h1>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">PSA-Verwaltung</p>
        </div>
        <div class="grid gap-3">
          <div>
            <label class="label">Benutzername</label>
            <input v-model="loginForm.username" class="input" placeholder="Benutzername" @keyup.enter="doLogin" autocomplete="username" />
          </div>
          <div>
            <label class="label">Passwort</label>
            <input v-model="loginForm.pin" type="password" class="input" placeholder="••••" @keyup.enter="doLogin" autocomplete="current-password" />
          </div>
          <div v-if="loginForm.error" class="text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 rounded-lg px-3 py-2">
            {{ loginForm.error }}
          </div>
          <button @click="doLogin" class="btn-primary w-full justify-center mt-2" :disabled="loading">
            <i class="ph ph-sign-in"></i> Anmelden
          </button>
        </div>
      </div>
    </div>

    <!-- Ersteinrichtung (leere Benutzer-Tabelle) -->
    <div v-else-if="needsSetup" class="fixed inset-0 z-50 bg-gray-50 dark:bg-gray-900 flex items-center justify-center p-4">
      <div class="bg-white dark:bg-gray-800 rounded-2xl shadow-2xl p-8 w-full max-w-sm border border-gray-100 dark:border-gray-700">
        <div class="text-center mb-6">
          <span class="text-4xl">🔥</span>
          <h1 class="text-xl font-bold text-gray-900 dark:text-white mt-2">PSA-Verwaltung</h1>
          <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">Ersteinrichtung</p>
        </div>
        <p class="text-sm text-blue-700 dark:text-blue-300 bg-blue-50 dark:bg-blue-900/20 rounded-lg px-3 py-2 mb-4">
          Noch kein Benutzer-Account vorhanden.<br>Lege jetzt den ersten Admin-Account an.
        </p>
        <div class="grid gap-3">
          <div>
            <label class="label">Benutzername</label>
            <input v-model="setupForm.username" class="input" placeholder="z.B. admin" @keyup.enter="doSetup" autocomplete="username" />
          </div>
          <div>
            <label class="label">Passwort</label>
            <input v-model="setupForm.pin" type="password" class="input" placeholder="••••" @keyup.enter="doSetup" autocomplete="new-password" />
          </div>
          <div>
            <label class="label">Passwort bestätigen</label>
            <input v-model="setupForm.pinConfirm" type="password" class="input" placeholder="••••" @keyup.enter="doSetup" autocomplete="new-password" />
          </div>
          <div v-if="setupForm.error" class="text-sm text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 rounded-lg px-3 py-2">
            {{ setupForm.error }}
          </div>
          <button @click="doSetup" class="btn-primary w-full justify-center mt-2" :disabled="loading">
            <i class="ph ph-user-plus"></i> Admin-Account anlegen
          </button>
        </div>
      </div>
    </div>

    <!-- App Shell (nach Login) -->
    <template v-if="loggedIn">
      <!-- Sidebar -->
      <Sidebar @openQr="openQrScanner" />

      <!-- Mobile Header -->
      <MobileHeader />

      <!-- Offline Banner -->
      <OfflineBanner />

      <!-- PWA Install Banner -->
      <PwaInstallBanner />

      <!-- Hauptinhalt -->
      <main :class="['content-main min-h-screen bg-gray-50 dark:bg-gray-900 md:pl-56 transition-all overflow-x-hidden']">
        <div class="px-4 py-6 max-w-7xl">
          <Transition name="fade" mode="out-in" @enter="onPageEnter">
            <component :is="currentPageComponent" :key="page" />
          </Transition>
        </div>
      </main>

      <!-- Feature-Modals -->
      <KameradenForm />
      <KameradenDetail />
      <CsvImport />
      <AusruestungForm />
      <AusruestungDetail />
      <AusgabeForm />
      <RueckgabeForm />
      <PruefungForm />
      <WaescheForm />
      <MassenWaesche />
      <MassenPruefung />
      <TypenForm />
      <NormenForm />
      <BenutzerForm />
      <QrScanner ref="qrScannerRef" />
    </template>

    <!-- Globale UI-Elemente -->
    <Toast />
    <Loader />
  </div>
</template>

<script setup>
import { ref, computed, nextTick, onMounted } from 'vue'
import { page, loggedIn, loginForm, loading, doLogin,
         needsSetup, setupForm, doSetup,
         modal, fetchAll } from './store.js'

// Layout
import Sidebar from './components/layout/Sidebar.vue'
import MobileHeader from './components/layout/MobileHeader.vue'
import OfflineBanner from './components/layout/OfflineBanner.vue'
import PwaInstallBanner from './components/layout/PwaInstallBanner.vue'
import Toast from './components/ui/Toast.vue'
import Loader from './components/ui/Loader.vue'

// Feature-Modals
import KameradenForm from './components/kameraden/KameradenForm.vue'
import KameradenDetail from './components/kameraden/KameradenDetail.vue'
import CsvImport from './components/kameraden/CsvImport.vue'
import AusruestungForm from './components/ausruestung/AusruestungForm.vue'
import AusruestungDetail from './components/ausruestung/AusruestungDetail.vue'
import AusgabeForm from './components/ausruestung/AusgabeForm.vue'
import RueckgabeForm from './components/ausruestung/RueckgabeForm.vue'
import PruefungForm from './components/ausruestung/PruefungForm.vue'
import WaescheForm from './components/ausruestung/WaescheForm.vue'
import MassenWaesche from './components/ausruestung/MassenWaesche.vue'
import MassenPruefung from './components/ausruestung/MassenPruefung.vue'
import TypenForm from './components/typen/TypenForm.vue'
import NormenForm from './components/normen/NormenForm.vue'
import BenutzerForm from './components/benutzer/BenutzerForm.vue'
import QrScanner from './components/qr/QrScanner.vue'

// Pages
import DashboardPage from './pages/DashboardPage.vue'
import WarnungenPage from './pages/WarnungenPage.vue'
import KameradenPage from './pages/KameradenPage.vue'
import AusruestungPage from './pages/AusruestungPage.vue'
import TypenPage from './pages/TypenPage.vue'
import VerlaufPage from './pages/VerlaufPage.vue'
import NormenPage from './pages/NormenPage.vue'
import StatistikenPage from './pages/StatistikenPage.vue'
import ChangelogPage from './pages/ChangelogPage.vue'
import BenutzerPage from './pages/BenutzerPage.vue'

const pageComponents = {
  dashboard: DashboardPage,
  warnungen: WarnungenPage,
  kameraden: KameradenPage,
  ausruestung: AusruestungPage,
  typen: TypenPage,
  verlauf: VerlaufPage,
  normen: NormenPage,
  statistiken: StatistikenPage,
  changelog: ChangelogPage,
  benutzer: BenutzerPage,
}

const currentPageComponent = computed(() => pageComponents[page.value] || DashboardPage)

// QR-Scanner
const qrScannerRef = ref(null)
function openQrScanner() {
  modal.qrScanner = true
  nextTick(() => qrScannerRef.value?.start())
}

// Page-Transition callback (Charts rendern nach Transition)
function onPageEnter() {
  // StatistikenPage und WarnungenPage haben eigene onMounted/watch – nichts nötig
}

onMounted(fetchAll)
</script>
