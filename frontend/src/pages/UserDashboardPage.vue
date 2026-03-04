<template>
  <div>
    <!-- Header -->
    <div class="mb-7">
      <h1 class="text-2xl font-bold text-gray-900 dark:text-white">
        Moin, {{ vorname }}!
      </h1>
      <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">
        {{ ausruestungFiltered.length }} Ausrüstungsstück{{ ausruestungFiltered.length !== 1 ? 'e' : '' }} zugewiesen
        <template v-if="faelligeItems.length">
          &nbsp;·&nbsp;
          <span class="text-orange-500 dark:text-orange-400 font-medium">{{ faelligeItems.length }} Prüfung{{ faelligeItems.length !== 1 ? 'en' : '' }} fällig</span>
        </template>
      </p>
    </div>

    <!-- Fällige Prüfungen -->
    <div v-if="faelligeItems.length" class="mb-6">
      <h2 class="text-base font-semibold mb-3 text-gray-700 dark:text-gray-300">Prüfungen fällig (≤ 30 Tage)</h2>
      <div class="space-y-2">
        <div v-for="a in faelligeItems" :key="a.Id"
          @click="openAusruestungDetail(a)"
          class="flex items-start gap-3 bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700 border-l-4 cursor-pointer hover:shadow-md transition-shadow"
          :class="fmtDateRel(a.Naechste_Pruefung)?.cls === 'text-red-600 dark:text-red-400' ? 'border-l-red-500' : fmtDateRel(a.Naechste_Pruefung)?.cls === 'text-orange-500 dark:text-orange-400' ? 'border-l-orange-400' : 'border-l-yellow-400'">
          <div class="flex-1 min-w-0">
            <div class="font-semibold text-sm text-gray-900 dark:text-white">{{ typLabel(a.Ausruestungstyp, typen) }}</div>
            <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{{ a.Seriennummer || '–' }}</div>
          </div>
          <div v-if="fmtDateRel(a.Naechste_Pruefung)" class="text-right shrink-0">
            <div :class="['text-xs font-semibold', fmtDateRel(a.Naechste_Pruefung)?.cls]">{{ fmtDateRel(a.Naechste_Pruefung)?.label }}</div>
            <div class="text-xs text-gray-400">{{ fmtDateRel(a.Naechste_Pruefung)?.sub }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Zugewiesene Ausrüstung -->
    <div class="mb-6">
      <h2 class="text-base font-semibold mb-3 text-gray-700 dark:text-gray-300">
        Meine Ausrüstung
        <span class="ml-2 text-xs font-normal text-gray-400">({{ ausruestungFiltered.length }})</span>
      </h2>
      <div v-if="!ausruestungFiltered.length" class="bg-gray-50 dark:bg-gray-800 rounded-xl p-6 text-center text-gray-400 text-sm">
        Noch keine Ausrüstung zugewiesen
      </div>
      <div v-else class="space-y-2">
        <div v-for="a in ausruestungFiltered" :key="a.Id"
          @click="openAusruestungDetail(a)"
          class="bg-white dark:bg-gray-800 rounded-xl border border-gray-100 dark:border-gray-700 p-4 shadow-sm cursor-pointer hover:shadow-md transition-shadow">
          <div class="flex items-start justify-between gap-2">
            <div class="min-w-0 flex-1">
              <div class="font-semibold text-sm text-gray-900 dark:text-white">{{ typLabel(a.Ausruestungstyp, typen) }}</div>
              <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                {{ a.Seriennummer || '–' }}
                <template v-if="a.Groesse"> · Größe {{ a.Groesse }}</template>
              </div>
            </div>
            <span :class="[statusBadge(a.Status), 'shrink-0 text-xs px-2 py-0.5 rounded-full font-medium']">{{ a.Status || '–' }}</span>
          </div>
          <dl v-if="a.Naechste_Pruefung" class="mt-2 grid grid-cols-2 gap-x-4 gap-y-1 text-xs">
            <div>
              <dt class="text-gray-400">Nächste Prüfung</dt>
              <dd v-if="fmtDateRel(a.Naechste_Pruefung)" :class="['font-medium', fmtDateRel(a.Naechste_Pruefung)?.cls]">
                {{ fmtDateRel(a.Naechste_Pruefung)?.label }}
              </dd>
              <dd v-else class="text-gray-700 dark:text-gray-300">{{ fmtDate(a.Naechste_Pruefung) }}</dd>
            </div>
          </dl>
        </div>
      </div>
    </div>

    <!-- Letzte Aktivität -->
    <div v-if="letzteAktivitaet.length">
      <h2 class="text-base font-semibold mb-3 text-gray-700 dark:text-gray-300">Letzte Aktivität</h2>
      <div class="space-y-1.5">
        <div v-for="item in letzteAktivitaet" :key="item.key"
          class="flex items-center gap-3 bg-white dark:bg-gray-800 rounded-xl px-4 py-3 shadow-sm border border-gray-100 dark:border-gray-700">
          <div :class="['w-7 h-7 rounded-lg flex items-center justify-center shrink-0', item.iconBg]">
            <i :class="[item.icon, 'text-sm', item.iconColor]"></i>
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm text-gray-800 dark:text-gray-200 truncate">{{ item.label }}</div>
            <div class="text-xs text-gray-400">{{ item.typ }}</div>
          </div>
          <div class="text-xs text-gray-400 shrink-0">{{ fmtDate(item.datum) }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { ausruestungFiltered, pruefungenFiltered, waescheFiltered, typen, currentUser, myKameradName, openAusruestungDetail } from '../store.js'
import { fmtDate, fmtDateRel, statusBadge, typLabel } from '../utils/formatters.js'

const vorname = computed(() => {
  if (myKameradName.value) return myKameradName.value.split(' ')[0]
  return currentUser.value?.Benutzername || ''
})

const today   = new Date(); today.setHours(0, 0, 0, 0)
const in30    = new Date(today); in30.setDate(today.getDate() + 30)

const faelligeItems = computed(() =>
  ausruestungFiltered.value
    .filter(a => {
      if (!a.Naechste_Pruefung) return false
      const d = new Date(a.Naechste_Pruefung)
      return d <= in30
    })
    .sort((a, b) => new Date(a.Naechste_Pruefung || 0).getTime() - new Date(b.Naechste_Pruefung || 0).getTime())
)

const letzteAktivitaet = computed(() => {
  const items = []
  for (const p of pruefungenFiltered.value.slice(0, 10)) {
    items.push({
      key: `p-${p.Id}`,
      datum: p.Datum,
      label: `Prüfung: ${p.Ergebnis || '–'}`,
      typ: p.Ausruestungstyp || '–',
      icon: 'ph ph-clipboard-text',
      iconBg: 'bg-orange-50 dark:bg-orange-900/20',
      iconColor: 'text-orange-500 dark:text-orange-400',
    })
  }
  for (const w of waescheFiltered.value.slice(0, 10)) {
    items.push({
      key: `w-${w.Id}`,
      datum: w.Datum,
      label: 'Wäsche durchgeführt',
      typ: w.Ausruestungstyp || '–',
      icon: 'ph ph-washing-machine',
      iconBg: 'bg-teal-50 dark:bg-teal-900/20',
      iconColor: 'text-teal-500 dark:text-teal-400',
    })
  }
  return items
    .sort((a, b) => new Date(b.datum || 0).getTime() - new Date(a.datum || 0).getTime())
    .slice(0, 8)
})
</script>
