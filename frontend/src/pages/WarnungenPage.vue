<template>
  <div>
    <div class="flex items-center justify-between mb-5">
      <div>
        <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Warnungen</h1>
        <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ warnungen.length }} aktive Meldung{{ warnungen.length !== 1 ? 'en' : '' }}</p>
      </div>
    </div>
    <div v-if="warnungen.length" class="space-y-2">
      <div v-for="w in warnungen" :key="w.id"
        @click="openAusruestungDetail(ausruestung.find(a => a.Id === w.ausruestungId))"
        :class="['flex items-start gap-3 bg-white dark:bg-gray-800 rounded-xl p-4 shadow-sm border border-gray-100 dark:border-gray-700 border-l-4 cursor-pointer hover:shadow-md transition-shadow',
          w.prio === 'rot' ? 'border-l-red-500' : w.prio === 'orange' ? 'border-l-orange-400' : 'border-l-yellow-400']">
        <i :class="['text-xl flex-shrink-0 mt-0.5',
          w.prio === 'rot' ? 'ph ph-warning-circle text-red-500' : w.prio === 'orange' ? 'ph ph-warning text-orange-400' : 'ph ph-clock text-yellow-500']"></i>
        <div class="flex-1 min-w-0">
          <div class="font-semibold text-sm text-gray-800 dark:text-gray-100">{{ w.titel }}</div>
          <div class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{{ w.detail }}</div>
        </div>
        <i class="ph ph-arrow-right text-gray-300 dark:text-gray-600 flex-shrink-0 self-center"></i>
      </div>
    </div>
    <div v-else class="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800 rounded-xl p-6 text-emerald-700 dark:text-emerald-400 text-sm flex items-center gap-3">
      <i class="ph ph-check-circle text-2xl"></i>
      <div>
        <div class="font-semibold">Alles in Ordnung</div>
        <div class="text-xs mt-0.5 opacity-75">Keine Prüfungen, Lebensdaten oder Waschlimits überfällig.</div>
      </div>
    </div>

    <!-- Mini-Charts -->
    <div v-if="ausruestung.length" class="mt-6 grid md:grid-cols-2 gap-6">
      <div class="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
        <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Status-Verteilung</h3>
        <canvas id="chartStatus" height="200"></canvas>
      </div>
      <div class="bg-white dark:bg-gray-800 rounded-xl p-5 shadow-sm border border-gray-100 dark:border-gray-700">
        <h3 class="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">Prüfungen (letzte 12 Monate)</h3>
        <canvas id="chartPruefungen" height="200"></canvas>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, watch, nextTick } from 'vue'
import { warnungen, ausruestung, pruefungen } from '../store.js'
import { openAusruestungDetail } from '../store.js'

const chartInstances = {}

function renderCharts() {
  if (typeof Chart === 'undefined') return
  const isDark = document.documentElement.classList.contains('dark')
  const gridColor = isDark ? 'rgba(75,85,99,0.3)' : 'rgba(229,231,235,0.8)'
  const textColor = isDark ? '#9ca3af' : '#6b7280'
  Chart.defaults.color = textColor
  Chart.defaults.borderColor = gridColor

  // Status-Verteilung
  const elStatus = document.getElementById('chartStatus')
  if (elStatus) {
    if (chartInstances.chartStatus) { try { chartInstances.chartStatus.destroy() } catch(e) {} }
    const statusCounts = {}
    ausruestung.value.forEach(a => { statusCounts[a.Status || 'Unbekannt'] = (statusCounts[a.Status || 'Unbekannt'] || 0) + 1 })
    const colorMap = { 'Lager': '#6b7280', 'Ausgegeben': '#3b82f6', 'Reinigung': '#14b8a6', 'In Reparatur': '#f97316', 'Ausgesondert': '#ef4444' }
    chartInstances.chartStatus = new Chart(elStatus, {
      type: 'doughnut',
      data: {
        labels: Object.keys(statusCounts),
        datasets: [{ data: Object.values(statusCounts), backgroundColor: Object.keys(statusCounts).map(s => colorMap[s] || '#9ca3af') }]
      },
      options: { responsive: true, aspectRatio: 2.5, plugins: { legend: { position: 'bottom', labels: { padding: 12, font: { size: 11 } } } } }
    })
  }

  // Prüfungen pro Monat
  const elPruef = document.getElementById('chartPruefungen')
  if (elPruef) {
    if (chartInstances.chartPruefungen) chartInstances.chartPruefungen.destroy()
    const months = {}
    const now = new Date()
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      months[`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`] = 0
    }
    pruefungen.value.forEach(p => {
      if (!p.Datum) return
      const key = p.Datum.substring(0, 7)
      if (key in months) months[key]++
    })
    chartInstances.chartPruefungen = new Chart(elPruef, {
      type: 'bar',
      data: {
        labels: Object.keys(months).map(m => { const [y,mo] = m.split('-'); return `${mo}/${y.slice(2)}` }),
        datasets: [{ label: 'Prüfungen', data: Object.values(months), backgroundColor: '#f97316', borderRadius: 4 }]
      },
      options: { responsive: true, aspectRatio: 2.5, scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }, plugins: { legend: { display: false } } }
    })
  }
}

onMounted(() => nextTick(renderCharts))
watch([ausruestung, pruefungen], () => nextTick(renderCharts), { deep: true })
</script>
