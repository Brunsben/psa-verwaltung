<template>
  <div>
    <div class="mb-5">
      <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Statistiken</h1>
      <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">Übersicht & Auswertungen</p>
    </div>

    <!-- ── Charts ──────────────────────────────────────────────────────────── -->
    <div class="grid md:grid-cols-2 gap-6 items-start mb-8">
      <div class="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
        <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Status-Verteilung</h3>
        <canvas id="chartStatusPage"></canvas>
      </div>
      <div class="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
        <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Prüfungen pro Monat</h3>
        <canvas id="chartPruefungenPage"></canvas>
      </div>
      <div class="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
        <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Ausrüstung pro Typ-Kategorie</h3>
        <canvas id="chartTypen"></canvas>
      </div>
      <div class="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
        <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Wäschen pro Monat</h3>
        <canvas id="chartWaeschen"></canvas>
      </div>
    </div>

    <!-- ── Bestandsübersicht nach Größe ────────────────────────────────────── -->
    <div>
      <h2 class="text-base font-semibold text-gray-700 dark:text-gray-300 mb-4">
        Bestandsübersicht nach Größe
      </h2>

      <div v-if="!groesseStats.length" class="text-sm text-gray-400 dark:text-gray-500 py-6 text-center">
        Noch keine Ausrüstungsstücke erfasst.
      </div>

      <div class="grid md:grid-cols-2 xl:grid-cols-3 gap-4">
        <div v-for="stat in groesseStats" :key="stat.bezeichnung"
          class="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">

          <!-- Card Header -->
          <div class="px-4 py-3 border-b border-gray-100 dark:border-gray-700 flex items-center justify-between">
            <div class="min-w-0">
              <div class="flex items-center gap-2 flex-wrap">
                <span v-if="stat.typ" class="text-xs bg-red-100 dark:bg-red-900/30 text-red-700 dark:text-red-400 px-1.5 py-0.5 rounded-full font-semibold flex-shrink-0">
                  {{ stat.typ }}
                </span>
                <span class="font-semibold text-sm text-gray-800 dark:text-gray-100 truncate">{{ stat.bezeichnung }}</span>
              </div>
            </div>
            <span class="text-xs text-gray-400 dark:text-gray-500 flex-shrink-0 ml-2">{{ stat.gesamt }} Stk.</span>
          </div>

          <!-- Size Table (wenn Größen-Mapping vorhanden) -->
          <div v-if="stat.hatGroessen" class="text-sm">
            <table class="w-full">
              <thead>
                <tr class="text-xs text-gray-400 dark:text-gray-500 bg-gray-50 dark:bg-gray-700/40">
                  <th class="px-4 py-1.5 text-left font-semibold">Größe</th>
                  <th class="px-3 py-1.5 text-center font-semibold">Lager</th>
                  <th class="px-3 py-1.5 text-center font-semibold">Ausgeg.</th>
                  <th class="px-3 py-1.5 text-center font-semibold">Sonst.</th>
                  <th class="px-3 py-1.5 text-center font-semibold">Gesamt</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-50 dark:divide-gray-700">
                <tr v-for="row in stat.sizes" :key="row.size"
                  class="hover:bg-gray-50 dark:hover:bg-gray-700/30 transition-colors">
                  <td class="px-4 py-2 font-semibold text-gray-800 dark:text-gray-200">
                    {{ row.size }}
                    <span v-if="row.size === '–'" class="text-xs font-normal text-gray-400">(keine Größe)</span>
                  </td>
                  <td class="px-3 py-2 text-center">
                    <span v-if="row.lager" class="font-semibold text-gray-700 dark:text-gray-200">{{ row.lager }}</span>
                    <span v-else class="text-gray-300 dark:text-gray-600">–</span>
                  </td>
                  <td class="px-3 py-2 text-center">
                    <span v-if="row.ausgegeben" class="font-semibold text-blue-600 dark:text-blue-400">{{ row.ausgegeben }}</span>
                    <span v-else class="text-gray-300 dark:text-gray-600">–</span>
                  </td>
                  <td class="px-3 py-2 text-center">
                    <span v-if="row.sonstige" class="font-semibold text-orange-500 dark:text-orange-400">{{ row.sonstige }}</span>
                    <span v-else class="text-gray-300 dark:text-gray-600">–</span>
                  </td>
                  <td class="px-3 py-2 text-center font-semibold text-gray-600 dark:text-gray-300">{{ row.gesamt }}</td>
                </tr>
              </tbody>
              <!-- Summenzeile -->
              <tfoot>
                <tr class="border-t border-gray-200 dark:border-gray-600 bg-gray-50 dark:bg-gray-700/40 text-xs font-semibold text-gray-500 dark:text-gray-400">
                  <td class="px-4 py-1.5">Gesamt</td>
                  <td class="px-3 py-1.5 text-center text-gray-700 dark:text-gray-200">{{ stat.sizes.reduce((s, r) => s + r.lager, 0) || '–' }}</td>
                  <td class="px-3 py-1.5 text-center text-blue-600 dark:text-blue-400">{{ stat.sizes.reduce((s, r) => s + r.ausgegeben, 0) || '–' }}</td>
                  <td class="px-3 py-1.5 text-center text-orange-500 dark:text-orange-400">{{ stat.sizes.reduce((s, r) => s + r.sonstige, 0) || '–' }}</td>
                  <td class="px-3 py-1.5 text-center text-gray-700 dark:text-gray-200">{{ stat.gesamt }}</td>
                </tr>
              </tfoot>
            </table>
          </div>

          <!-- Ohne Größen-Mapping: einfache Statusübersicht -->
          <div v-else class="px-4 py-3 flex gap-6 text-sm">
            <div class="text-center">
              <div class="text-lg font-bold text-gray-700 dark:text-gray-200">{{ stat.statusCounts.lager || 0 }}</div>
              <div class="text-xs text-gray-400">Lager</div>
            </div>
            <div class="text-center">
              <div class="text-lg font-bold text-blue-600 dark:text-blue-400">{{ stat.statusCounts.ausgegeben || 0 }}</div>
              <div class="text-xs text-gray-400">Ausgegeben</div>
            </div>
            <div v-if="stat.statusCounts.sonstige" class="text-center">
              <div class="text-lg font-bold text-orange-500 dark:text-orange-400">{{ stat.statusCounts.sonstige }}</div>
              <div class="text-xs text-gray-400">Sonstige</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, watch, nextTick } from 'vue'
import { ausruestung, pruefungen, waescheListe, typen } from '../store.js'

// ── Bestandsübersicht berechnen ──────────────────────────────────────────────
const groesseStats = computed(() => {
  const byTyp = {}
  ausruestung.value.forEach(a => {
    if (!a.Ausruestungstyp) return
    if (!byTyp[a.Ausruestungstyp]) byTyp[a.Ausruestungstyp] = []
    byTyp[a.Ausruestungstyp].push(a)
  })

  return Object.entries(byTyp)
    .sort(([a], [b]) => a.localeCompare(b, 'de'))
    .map(([bezeichnung, stuecke]) => {
      const typ = typen.value.find(t => t.Bezeichnung === bezeichnung)
      const sizeMap = {}
      const statusCounts = { lager: 0, ausgegeben: 0, sonstige: 0 }
      let anyGroesse = false

      stuecke.forEach(a => {
        if (a.Status === 'Lager') statusCounts.lager++
        else if (a.Status === 'Ausgegeben') statusCounts.ausgegeben++
        else statusCounts.sonstige++

        const size = a.Groesse ? String(a.Groesse).trim() : '–'
        if (size !== '–') anyGroesse = true

        if (!sizeMap[size]) sizeMap[size] = { gesamt: 0, lager: 0, ausgegeben: 0, sonstige: 0 }
        sizeMap[size].gesamt++
        if (a.Status === 'Lager') sizeMap[size].lager++
        else if (a.Status === 'Ausgegeben') sizeMap[size].ausgegeben++
        else sizeMap[size].sonstige++
      })

      const sizes = Object.entries(sizeMap)
        .sort(([a], [b]) => {
          if (a === '–') return 1
          if (b === '–') return -1
          const numA = parseFloat(a), numB = parseFloat(b)
          if (!isNaN(numA) && !isNaN(numB)) return numA - numB
          return a.localeCompare(b, 'de')
        })
        .map(([size, counts]) => ({ size, ...counts }))

      return { bezeichnung, typ: typ?.Typ || '', gesamt: stuecke.length, hatGroessen: anyGroesse, sizes, statusCounts }
    })
})

// ── Chart.js ─────────────────────────────────────────────────────────────────
const chartInstances = {}

function renderCharts() {
  if (typeof Chart === 'undefined') return
  const isDark = document.documentElement.classList.contains('dark')
  const gridColor = isDark ? 'rgba(75,85,99,0.3)' : 'rgba(229,231,235,0.8)'
  const textColor = isDark ? '#9ca3af' : '#6b7280'
  Chart.defaults.color = textColor
  Chart.defaults.borderColor = gridColor

  const elStatus = document.getElementById('chartStatusPage')
  if (elStatus) {
    if (chartInstances.chartStatusPage) { try { chartInstances.chartStatusPage.destroy() } catch(e) {} }
    const statusCounts = {}
    ausruestung.value.forEach(a => { statusCounts[a.Status || 'Unbekannt'] = (statusCounts[a.Status || 'Unbekannt'] || 0) + 1 })
    const colorMap = { 'Lager': '#6b7280', 'Ausgegeben': '#3b82f6', 'Reinigung': '#14b8a6', 'In Reparatur': '#f97316', 'Ausgesondert': '#ef4444' }
    chartInstances.chartStatusPage = new Chart(elStatus, {
      type: 'doughnut',
      data: { labels: Object.keys(statusCounts), datasets: [{ data: Object.values(statusCounts), backgroundColor: Object.keys(statusCounts).map(s => colorMap[s] || '#9ca3af') }] },
      options: { responsive: true, aspectRatio: 2.5, plugins: { legend: { position: 'bottom', labels: { padding: 12, font: { size: 11 } } } } }
    })
  }

  const elPruef = document.getElementById('chartPruefungenPage')
  if (elPruef) {
    if (chartInstances.chartPruefungenPage) chartInstances.chartPruefungenPage.destroy()
    const months = {}
    const now = new Date()
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      months[`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`] = 0
    }
    pruefungen.value.forEach(p => { if (!p.Datum) return; const key = p.Datum.substring(0, 7); if (key in months) months[key]++ })
    chartInstances.chartPruefungenPage = new Chart(elPruef, {
      type: 'bar',
      data: { labels: Object.keys(months).map(m => { const [y,mo] = m.split('-'); return `${mo}/${y.slice(2)}` }), datasets: [{ label: 'Prüfungen', data: Object.values(months), backgroundColor: '#f97316', borderRadius: 4 }] },
      options: { responsive: true, aspectRatio: 2.5, scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }, plugins: { legend: { display: false } } }
    })
  }

  const elTypen = document.getElementById('chartTypen')
  if (elTypen) {
    if (chartInstances.chartTypen) chartInstances.chartTypen.destroy()
    const typCounts = {}
    ausruestung.value.forEach(a => {
      const typ = typen.value.find(t => t.Bezeichnung === a.Ausruestungstyp)
      const kat = typ?.Typ || 'Sonstige'
      typCounts[kat] = (typCounts[kat] || 0) + 1
    })
    const colors = ['#ef4444','#3b82f6','#14b8a6','#f97316','#8b5cf6','#ec4899','#6b7280','#eab308']
    chartInstances.chartTypen = new Chart(elTypen, {
      type: 'pie',
      data: { labels: Object.keys(typCounts), datasets: [{ data: Object.values(typCounts), backgroundColor: colors.slice(0, Object.keys(typCounts).length) }] },
      options: { responsive: true, aspectRatio: 2.5, plugins: { legend: { position: 'bottom', labels: { padding: 12, font: { size: 11 } } } } }
    })
  }

  const elWaeschen = document.getElementById('chartWaeschen')
  if (elWaeschen) {
    if (chartInstances.chartWaeschen) chartInstances.chartWaeschen.destroy()
    const months = {}
    const now = new Date()
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      months[`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`] = 0
    }
    waescheListe.value.forEach(w => { if (!w.Datum) return; const key = w.Datum.substring(0, 7); if (key in months) months[key]++ })
    chartInstances.chartWaeschen = new Chart(elWaeschen, {
      type: 'bar',
      data: { labels: Object.keys(months).map(m => { const [y,mo] = m.split('-'); return `${mo}/${y.slice(2)}` }), datasets: [{ label: 'Wäschen', data: Object.values(months), backgroundColor: '#14b8a6', borderRadius: 4 }] },
      options: { responsive: true, aspectRatio: 2.5, scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }, plugins: { legend: { display: false } } }
    })
  }
}

onMounted(() => nextTick(renderCharts))
watch([ausruestung, pruefungen, waescheListe, typen], () => nextTick(renderCharts), { deep: true })
</script>
