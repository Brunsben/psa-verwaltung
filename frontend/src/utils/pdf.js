// ── PDF & CSV Export ─────────────────────────────────────────────────────────
import { fmtDate, typLabel, todayStr } from './formatters.js'

/**
 * Exportiert einen PSA-Nachweis als PDF für einen Kameraden.
 * @param {Object} kamerad
 * @param {Object} store - { pruefungen, ausruestung, typen, kameradenGroessen, ausruestungFuerKamerad, showToast }
 */
export function exportPDF(kamerad, store) {
  if (typeof window.jspdf === 'undefined') {
    store.showToast('PDF-Bibliothek nicht geladen', 'error')
    return
  }
  const { jsPDF } = window.jspdf
  const doc = new jsPDF()
  const label = `${kamerad.Vorname} ${kamerad.Name}`
  let y = 20

  // Header
  doc.setFontSize(18)
  doc.setTextColor(220, 38, 38)
  doc.text('PSA-Nachweis', 14, y)
  doc.setFontSize(10)
  doc.setTextColor(107, 114, 128)
  doc.text('FF Wietmarschen', 14, y + 7)
  y += 20

  // Kamerad-Info
  doc.setFontSize(14)
  doc.setTextColor(17, 24, 39)
  doc.text(label, 14, y)
  y += 7
  doc.setFontSize(9)
  doc.setTextColor(107, 114, 128)
  if (kamerad.Dienstgrad) { doc.text(`Dienstgrad: ${kamerad.Dienstgrad}`, 14, y); y += 5 }
  doc.text(`Status: ${kamerad.Aktiv ? 'Aktiv' : 'Inaktiv'}`, 14, y)
  y += 5
  doc.text(`Erstellt am: ${new Date().toLocaleDateString('de-DE')}`, 14, y)
  y += 10

  // Größen
  doc.setFontSize(11)
  doc.setTextColor(17, 24, 39)
  doc.text('Größen', 14, y)
  y += 6
  doc.setFontSize(8)
  doc.setTextColor(75, 85, 99)
  const groessen = store.kameradenGroessen(kamerad)
  const gText = groessen.map(g => `${g.label}: ${g.wert || '–'}`).join('  ·  ')
  doc.text(gText, 14, y)
  y += 10

  // Zugewiesene Ausrüstung
  doc.setFontSize(11)
  doc.setTextColor(17, 24, 39)
  doc.text('Zugewiesene Ausrüstung', 14, y)
  y += 7

  const zugewiesen = store.ausruestungFuerKamerad(kamerad)
  if (zugewiesen.length) {
    doc.setFontSize(8)
    doc.setTextColor(107, 114, 128)
    doc.text('Typ', 14, y)
    doc.text('Seriennr.', 60, y)
    doc.text('Status', 100, y)
    doc.text('Nächste Prüfung', 130, y)
    doc.text('Lebensende', 170, y)
    y += 1
    doc.setDrawColor(229, 231, 235)
    doc.line(14, y, 196, y)
    y += 4
    doc.setTextColor(55, 65, 81)
    zugewiesen.forEach(a => {
      if (y > 275) { doc.addPage(); y = 20 }
      doc.text(typLabel(a.Ausruestungstyp, store.typen.value).substring(0, 25), 14, y)
      doc.text(a.Seriennummer || '–', 60, y)
      doc.text(a.Status || '–', 100, y)
      doc.text(a.Naechste_Pruefung ? fmtDate(a.Naechste_Pruefung) : '–', 130, y)
      doc.text(a.Lebensende_Datum ? fmtDate(a.Lebensende_Datum) : '–', 170, y)
      y += 5
    })
  } else {
    doc.setFontSize(8)
    doc.setTextColor(156, 163, 175)
    doc.text('Keine Ausrüstung zugeordnet', 14, y)
    y += 5
  }
  y += 5

  // Letzte Prüfungen
  if (y > 250) { doc.addPage(); y = 20 }
  doc.setFontSize(11)
  doc.setTextColor(17, 24, 39)
  doc.text('Letzte Prüfungen', 14, y)
  y += 7

  const kamPruefungen = store.pruefungen.value
    .filter(p => p.Kamerad === label)
    .sort((a, b) => new Date(b.Datum || 0) - new Date(a.Datum || 0))
    .slice(0, 10)

  if (kamPruefungen.length) {
    doc.setFontSize(8)
    doc.setTextColor(107, 114, 128)
    doc.text('Datum', 14, y)
    doc.text('Ausrüstung', 40, y)
    doc.text('Ergebnis', 100, y)
    doc.text('Prüfer', 130, y)
    y += 1
    doc.line(14, y, 196, y)
    y += 4
    doc.setTextColor(55, 65, 81)
    kamPruefungen.forEach(p => {
      if (y > 275) { doc.addPage(); y = 20 }
      doc.text(fmtDate(p.Datum), 14, y)
      doc.text((p.Ausruestungstyp || '–').substring(0, 30), 40, y)
      doc.text(p.Ergebnis || '–', 100, y)
      doc.text(p.Pruefer || '–', 130, y)
      y += 5
    })
  }

  // Footer
  doc.setFontSize(7)
  doc.setTextColor(156, 163, 175)
  doc.text(`PSA-Verwaltung · FF Wietmarschen · ${new Date().toLocaleDateString('de-DE')} ${new Date().toLocaleTimeString('de-DE')}`, 14, 290)

  doc.save(`PSA-Nachweis_${label.replace(/\s+/g, '_')}_${todayStr()}.pdf`)
  store.showToast('PDF erstellt')
}

/**
 * Exportiert die aktuelle Ausrüstungsliste als CSV.
 * @param {Array} list - Gefilterte Ausrüstungsliste
 * @param {Array} typen - Für typLabel
 * @param {Function} showToast
 */
export function exportCSV(list, typen, showToast) {
  const header = 'Seriennummer;Typ;Kamerad;Status;Nächste Prüfung;Lebensende;Notizen'
  const rows = list.map(a =>
    [
      a.Seriennummer || '',
      typLabel(a.Ausruestungstyp, typen),
      a.Kamerad || '',
      a.Status || '',
      fmtDate(a.Naechste_Pruefung),
      fmtDate(a.Lebensende_Datum),
      (a.Notizen || '').replace(/"/g, '""'),
    ].map(v => `"${v}"`).join(';')
  )
  const csv  = '\uFEFF' + [header, ...rows].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url  = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href     = url
  link.download = `ausruestung_${todayStr()}.csv`
  link.click()
  URL.revokeObjectURL(url)
  showToast('CSV exportiert')
}
