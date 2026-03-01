<template>
  <div>
    <div class="mb-5">
      <h1 class="text-2xl font-bold text-gray-900 dark:text-white">Statistiken</h1>
      <p class="text-sm text-gray-500 dark:text-gray-400 mt-1">Übersicht & Auswertungen</p>
    </div>
    <div class="grid md:grid-cols-2 gap-6 items-start">
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
  </div>
</template>

<script setup>
import { onMounted, watch, nextTick } from 'vue'
import { ausruestung, pruefungen, waescheListe, typen } from '../store.js'

const chartInstances = {}

function renderCharts() {
  if (typeof Chart === 'undefined') return
  const isDark = document.documentElement.classList.contains('dark')
  const gridColor = isDark ? 'rgba(75,85,99,0.3)' : 'rgba(229,231,235,0.8)'
  const textColor = isDark ? '#9ca3af' : '#6b7280'
  Chart.defaults.color = textColor
  Chart.defaults.borderColor = gridColor

  // Status-Verteilung
  const elStatus = document.getElementById('chartStatusPage')
  if (elStatus) {
    if (chartInstances.chartStatusPage) { try { chartInstances.chartStatusPage.destroy() } catch(e) {} }
    const statusCounts = {}
    ausruestung.value.forEach(a => { statusCounts[a.Status || 'Unbekannt'] = (statusCounts[a.Status || 'Unbekannt'] || 0) + 1 })
    const colorMap = { 'Lager': '#6b7280', 'Ausgegeben': '#3b82f6', 'Reinigung': '#14b8a6', 'In Reparatur': '#f97316', 'Ausgesondert': '#ef4444' }
    chartInstances.chartStatusPage = new Chart(elStatus, {
      type: 'doughnut',
      data: {
        labels: Object.keys(statusCounts),
        datasets: [{ data: Object.values(statusCounts), backgroundColor: Object.keys(statusCounts).map(s => colorMap[s] || '#9ca3af') }]
      },
      options: { responsive: true, aspectRatio: 2.5, plugins: { legend: { position: 'bottom', labels: { padding: 12, font: { size: 11 } } } } }
    })
  }

  // Prüfungen pro Monat
  const elPruef = document.getElementById('chartPruefungenPage')
  if (elPruef) {
    if (chartInstances.chartPruefungenPage) chartInstances.chartPruefungenPage.destroy()
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
    chartInstances.chartPruefungenPage = new Chart(elPruef, {
      type: 'bar',
      data: {
        labels: Object.keys(months).map(m => { const [y,mo] = m.split('-'); return `${mo}/${y.slice(2)}` }),
        datasets: [{ label: 'Prüfungen', data: Object.values(months), backgroundColor: '#f97316', borderRadius: 4 }]
      },
      options: { responsive: true, aspectRatio: 2.5, scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }, plugins: { legend: { display: false } } }
    })
  }

  // Ausrüstung pro Typ-Kategorie
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
      data: {
        labels: Object.keys(typCounts),
        datasets: [{ data: Object.values(typCounts), backgroundColor: colors.slice(0, Object.keys(typCounts).length) }]
      },
      options: { responsive: true, aspectRatio: 2.5, plugins: { legend: { position: 'bottom', labels: { padding: 12, font: { size: 11 } } } } }
    })
  }

  // Wäschen pro Monat
  const elWaeschen = document.getElementById('chartWaeschen')
  if (elWaeschen) {
    if (chartInstances.chartWaeschen) chartInstances.chartWaeschen.destroy()
    const months = {}
    const now = new Date()
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
      months[`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`] = 0
    }
    waescheListe.value.forEach(w => {
      if (!w.Datum) return
      const key = w.Datum.substring(0, 7)
      if (key in months) months[key]++
    })
    chartInstances.chartWaeschen = new Chart(elWaeschen, {
      type: 'bar',
      data: {
        labels: Object.keys(months).map(m => { const [y,mo] = m.split('-'); return `${mo}/${y.slice(2)}` }),
        datasets: [{ label: 'Wäschen', data: Object.values(months), backgroundColor: '#14b8a6', borderRadius: 4 }]
      },
      options: { responsive: true, aspectRatio: 2.5, scales: { y: { beginAtZero: true, ticks: { stepSize: 1 } } }, plugins: { legend: { display: false } } }
    })
  }
}

onMounted(() => nextTick(renderCharts))
watch([ausruestung, pruefungen, waescheListe, typen], () => nextTick(renderCharts), { deep: true })
</script>
