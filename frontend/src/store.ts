// ── Zentraler App-Store ───────────────────────────────────────────────────────
// Alle reaktiven Zustände, Computed-Properties und Datenmethoden werden hier
// als Modul-Level-Singletons definiert und exportiert.
// Komponenten importieren nur was sie brauchen.

import { ref, reactive, computed } from 'vue'
import { getAll, post, patch, del, TABLES,
         authenticate, isInitialized, createAdmin,
         setJwt, clearJwt, authRpc } from './api/index.js'
import { fmtDate, todayStr } from './utils/formatters.js'
import type { Kamerad, Ausruestungstyp, Ausruestungstueck, Ausgabe, Pruefung, Waesche, Norm, Benutzer, ChangelogEntry, AppUser, CsvRow, AusruestungCsvRow, GroesseKatEntry, Warnung, Schadensdokumentation } from './types/index.js'

// ── UI-Zustand ─────────────────────────────────────────────────────────────
export const page        = ref('dashboard')
export const sidebarOpen = ref(false)
export const loading     = ref(false)
export const toast       = reactive({ show: false, msg: '', type: 'ok' })
export const isOffline        = ref(false)
export const offlineTimestamp = ref<number | null>(null)

export function showToast(msg: string, type = 'ok') {
  toast.msg = msg; toast.type = type; toast.show = true
  setTimeout(() => { toast.show = false }, 3000)
}

export async function load(fn: () => Promise<void>) {
  if (isOffline.value) { showToast('Nicht möglich: App ist offline', 'error'); return }
  loading.value = true
  try { await fn() }
  catch (e) { showToast(e instanceof Error ? e.message : String(e), 'error') }
  finally { loading.value = false }
}

// ── Dark Mode ──────────────────────────────────────────────────────────────
export const darkMode = ref(document.documentElement.classList.contains('dark'))
export function toggleDark() {
  darkMode.value = !darkMode.value
  document.documentElement.classList.toggle('dark', darkMode.value)
  localStorage.setItem('darkMode', String(darkMode.value))
}

// ── Auth ───────────────────────────────────────────────────────────────────
function safeJsonParse<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key)
    return raw ? JSON.parse(raw) as T : fallback
  } catch { return fallback }
}

export const loggedIn    = ref(!!localStorage.getItem('psa_jwt'))
export const currentUser = ref<AppUser | null>(safeJsonParse('psa_user', null))

// Bei abgelaufenem JWT automatisch ausloggen
window.addEventListener('psa:unauthorized', () => {
  clearJwt()
  localStorage.removeItem('psa_user')
  loggedIn.value    = false
  currentUser.value = null
  showToast('Sitzung abgelaufen – bitte neu anmelden', 'error')
})
export const loginForm   = reactive({ username: '', pin: '', error: '' })
export const needsSetup  = ref(false)
export const setupForm   = reactive({ username: '', pin: '', pinConfirm: '', error: '' })

export const feuerwehrName = window.CONFIG.feuerwehrName || 'FF Wietmarschen'

export const userRole      = computed(() => (currentUser.value?.Rolle || '').toLowerCase())
export const isAdmin       = computed(() => userRole.value === 'admin')
export const isKleiderwart = computed(() => ['admin', 'kleiderwart'].includes(userRole.value))
export const canEdit       = computed(() => isKleiderwart.value)
export const myKameradId   = computed(() => userRole.value !== 'user' ? null : currentUser.value?.KameradId || null)
export const myKameradName = computed(() => {
  if (!myKameradId.value) return null
  const k = kameraden.value.find(k => String(k.Id) === String(myKameradId.value))
  return k ? `${k.Vorname} ${k.Name}` : null
})

// ── Dienstgrade (FwVO Niedersachsen) ──────────────────────────────────────
export const DIENSTGRADE = [
  'Feuerwehrmann-Anwärter/in (FM-A)', 'Feuerwehrmann/-frau (FM)',
  'Oberfeuerwehrmann/-frau (OFM)', 'Hauptfeuerwehrmann/-frau (HFM)',
  'Erster Hauptfeuerwehrmann/-frau (EHFM)',
  'Brandmeister/in (BM)', 'Oberbrandmeister/in (OBM)',
  'Hauptbrandmeister/in (HBM)', 'Erster Hauptbrandmeister/in (EHBM)',
  'Brandinspektor/in (BrI)', 'Oberbrandinspektor/in (OBrI)',
  'Hauptbrandinspektor/in (HBrI)', 'Erster Hauptbrandinspektor/in (EHBrI)',
  'Gemeinde-/Stadtbrandinspektor/in (GemBrI/StBrI)',
  'Abschnittsbrandinspektor/in (ABrI)', 'Erster Abschnittsbrandinspektor/in (EABrI)',
  'Kreisbrandinspektor/in (KBrI)', 'Erster Kreisbrandinspektor/in (EKBrI)',
  'Regierungsbrandinspektor/in (RegBrI)',
]

// ── Seitennavigation ───────────────────────────────────────────────────────
export const pages = [
  { id: 'dashboard',       label: 'Dashboard',       iconClass: 'ph ph-gauge',                   roles: ['Admin','Kleiderwart'] },
  { id: 'mein-dashboard',  label: 'Mein Dashboard',  iconClass: 'ph ph-house',                   roles: ['User'] },
  { id: 'kameraden',       label: 'Kameraden',       iconClass: 'ph ph-users-three',             roles: ['Admin','Kleiderwart'] },
  { id: 'ausruestung',     label: 'Ausrüstung',      iconClass: 'ph ph-t-shirt',                 roles: ['Admin','Kleiderwart','User'] },
  { id: 'typen',           label: 'Typen',           iconClass: 'ph ph-tag',                     roles: ['Admin','Kleiderwart'] },
  { id: 'verlauf',         label: 'Verlauf',         iconClass: 'ph ph-clock-counter-clockwise', roles: ['Admin','Kleiderwart','User'] },
  { id: 'normen',          label: 'Normen',          iconClass: 'ph ph-seal-check',              roles: ['Admin','Kleiderwart'] },
  { id: 'warnungen',       label: 'Warnungen',       iconClass: 'ph ph-bell-ringing',            roles: ['Admin','Kleiderwart'] },
  { id: 'statistiken',     label: 'Statistiken',     iconClass: 'ph ph-chart-bar',               roles: ['Admin','Kleiderwart'] },
  { id: 'changelog',       label: 'Changelog',       iconClass: 'ph ph-clock-counter-clockwise', roles: ['Admin','Kleiderwart'] },
  { id: 'benutzer',        label: 'Benutzer',        iconClass: 'ph ph-user-gear',               roles: ['Admin'] },
]
export const visiblePages = computed(() => {
  const role = (currentUser.value?.Rolle || '').toLowerCase()
  if (!role) return pages.filter(p => p.id !== 'benutzer')
  return pages.filter(p => !p.roles || p.roles.some(r => r.toLowerCase() === role))
})

// ── Datenkollektionen ──────────────────────────────────────────────────────
export const kameraden    = ref<Kamerad[]>([])
export const ausruestung  = ref<Ausruestungstueck[]>([])
export const typen        = ref<Ausruestungstyp[]>([])
export const ausgaben     = ref<Ausgabe[]>([])
export const pruefungen   = ref<Pruefung[]>([])
export const waescheListe = ref<Waesche[]>([])
export const normen                = ref<Norm[]>([])
export const changelog             = ref<ChangelogEntry[]>([])
export const benutzer              = ref<Benutzer[]>([])
export const schadensdokumentation = ref<Schadensdokumentation[]>([])

// ── Offline ────────────────────────────────────────────────────────────────
export function saveOfflineSnapshot() {
  try {
    localStorage.setItem('psa_offline_data', JSON.stringify({
      timestamp: Date.now(),
      data: {
        kameraden: kameraden.value, ausruestung: ausruestung.value,
        typen: typen.value, ausgaben: ausgaben.value,
        pruefungen: pruefungen.value, waescheListe: waescheListe.value,
        normen: normen.value, changelog: changelog.value, benutzer: benutzer.value,
      }
    }))
  } catch(e) {}
}

export function loadOfflineSnapshot() {
  try {
    const raw = localStorage.getItem('psa_offline_data')
    if (!raw) return false
    const snap = JSON.parse(raw)
    kameraden.value    = snap.data.kameraden    || []
    ausruestung.value  = snap.data.ausruestung  || []
    typen.value        = snap.data.typen        || []
    ausgaben.value     = snap.data.ausgaben     || []
    pruefungen.value   = snap.data.pruefungen   || []
    waescheListe.value = snap.data.waescheListe || []
    normen.value       = snap.data.normen       || []
    changelog.value    = snap.data.changelog    || []
    benutzer.value     = snap.data.benutzer     || []
    isOffline.value         = true
    offlineTimestamp.value  = snap.timestamp
    return true
  } catch(e) { return false }
}

// ── Filter & Sortierung ────────────────────────────────────────────────────
export const filterKameraden         = ref('')
export const filterKameradenNurAktiv = ref(false)
export const filterTyp               = ref('')
export const filterVerlaufKamerad    = ref('')
export const verlaufTab              = ref('pruefungen')
export const filterAusruestung       = ref('')
export const filterStatus            = ref('')
export const filterChangelog         = ref('')
export const filterNormKategorie     = ref('')
export const sortAusruestung         = reactive({ field: '', dir: 'asc' })

export function sortBy(field: string) {
  if (sortAusruestung.field === field) {
    sortAusruestung.dir = sortAusruestung.dir === 'asc' ? 'desc' : 'asc'
  } else {
    sortAusruestung.field = field
    sortAusruestung.dir   = 'asc'
  }
}

// ── Modal-Zustand ──────────────────────────────────────────────────────────
export const modal = reactive({
  kameradenForm: false, ausruestungForm: false,
  typForm: false, ausgabe: false, pruefung: false, waesche: false,
  kameradenDetail: false, normenForm: false, massenWaesche: false,
  massenPruefung: false, rueckgabe: false, ausruestungDetail: false,
  csvImport: false, ausruestungCsvImport: false, qrScanner: false, benutzerForm: false, passwortForm: false, schaden: false,
})

// ── Formular-Zustand ───────────────────────────────────────────────────────
// eslint-disable-next-line @typescript-eslint/no-explicit-any
type AnyForm = Record<string, any>
export const form = reactive({
  kamerad:         {} as AnyForm,
  ausruestung:     {} as AnyForm,
  typ:             {} as AnyForm,
  aktion:          {} as AnyForm,
  ausgabe:         {} as AnyForm,
  pruefung:        {} as AnyForm,
  waesche:         {} as AnyForm,
  norm:            {} as AnyForm,
  massenWaesche:   {} as AnyForm,
  massenPruefung:  {} as AnyForm,
  rueckgabe:       {} as AnyForm,
  rueckgabeAusgabe: null as Ausgabe | null,
  csvImport:           { rows: [] as CsvRow[], fileName: '' },
  ausruestungCsv:      { rows: [] as AusruestungCsvRow[], fileName: '' },
  benutzer:        { Id: null, Benutzername: '', PIN: '', Rolle: 'Kleiderwart', Aktiv: true, KameradId: '' } as AnyForm,
  schaden:         {} as AnyForm,
})

// ── Detail-Navigation ──────────────────────────────────────────────────────
export const selectedKamerad     = ref<Partial<Kamerad>>({})
export const selectedIds         = ref<number[]>([])
export const selectedAusruestung = ref<Ausruestungstueck | null>(null)
export const detailFromKamerad   = ref<Kamerad | null>(null)
export const qrResult            = ref('')
export const qrError             = ref('')
// Wenn gesetzt, füllt der QR-Scanner dieses Feld in form.ausruestung (statt Ausrüstung zu suchen)
export const qrScanTarget        = ref<string | null>(null)

export function openQrForField(field: 'QR_Code' | 'Seriennummer') {
  qrScanTarget.value = field
  qrResult.value     = ''
  qrError.value      = ''
  modal.qrScanner    = true
}

// ── Datum-Schwellwerte (einmalig berechnet) ────────────────────────────────
const _today = new Date()
const _in30  = new Date(_today); _in30.setDate(_today.getDate() + 30)
const _in180 = new Date(_today); _in180.setDate(_today.getDate() + 180)

// ── Computed: Kameraden ────────────────────────────────────────────────────
export const kameradenliste = computed(() =>
  kameraden.value.filter(k => k.Aktiv)
    .map(k => ({ Id: k.Id, label: `${k.Vorname} ${k.Name}` }))
)

export const kameradenFiltered = computed(() => {
  let list = kameraden.value
  if (filterKameradenNurAktiv.value) list = list.filter(k => k.Aktiv)
  if (filterKameraden.value) {
    const q = filterKameraden.value.toLowerCase()
    list = list.filter(k => (`${k.Vorname} ${k.Name}`).toLowerCase().includes(q))
  }
  return list
})

// ── Computed: Typen & Normen ───────────────────────────────────────────────
export const typenKategorien = computed(() =>
  [...new Set(typen.value.map(t => t.Typ).filter(Boolean))].sort()
)

export const normenKategorien = computed(() =>
  [...new Set(normen.value.map(n => n.Ausruestungstyp_Kategorie).filter(Boolean))].sort()
)

export const normenFiltered = computed(() => {
  let list = [...normen.value].sort((a, b) =>
    (a.Ausruestungstyp_Kategorie || '').localeCompare(b.Ausruestungstyp_Kategorie || '') ||
    (a.Bezeichnung || '').localeCompare(b.Bezeichnung || '')
  )
  if (filterNormKategorie.value) list = list.filter(n => n.Ausruestungstyp_Kategorie === filterNormKategorie.value)
  return list
})

export const normenFuerAktuellenTyp = computed(() =>
  normen.value.filter(n => n.Ausruestungstyp_Kategorie === form.typ.Typ)
)

export function normenFuerTyp(kategorie: string) {
  return normen.value.filter(n => n.Ausruestungstyp_Kategorie === kategorie)
}

// ── Computed: Ausrüstung ───────────────────────────────────────────────────
export const ausruestungFiltered = computed(() => {
  let list = myKameradName.value
    ? ausruestung.value.filter(a => a.Kamerad === myKameradName.value)
    : ausruestung.value
  if (filterStatus.value === 'Prüfung fällig') {
    list = list.filter(a => a.Naechste_Pruefung && new Date(a.Naechste_Pruefung) <= _in30)
  } else if (filterStatus.value) {
    list = list.filter(a => a.Status === filterStatus.value)
  }
  if (filterTyp.value) {
    list = list.filter(a => {
      const typ = typen.value.find(t => t.Bezeichnung === a.Ausruestungstyp)
      return typ?.Typ === filterTyp.value
    })
  }
  if (filterAusruestung.value) {
    const q = filterAusruestung.value.toLowerCase()
    list = list.filter(a =>
      (a.Seriennummer || '').toLowerCase().includes(q) ||
      (a.Ausruestungstyp || '').toLowerCase().includes(q) ||
      (a.Kamerad || '').toLowerCase().includes(q)
    )
  }
  if (sortAusruestung.field) {
    const f = sortAusruestung.field
    const d = sortAusruestung.dir === 'asc' ? 1 : -1
    list = [...list].sort((a, b) =>
      ((a as AnyForm)[f] ?? '').toString().localeCompare(((b as AnyForm)[f] ?? '').toString(), 'de') * d
    )
  }
  return list
})

// ── Computed: Ausgaben / Prüfungen / Wäsche ────────────────────────────────
export const ausgabenFiltered = computed(() =>
  [...ausgaben.value]
    .sort((a, b) => new Date(b.Ausgabedatum || 0).getTime() - new Date(a.Ausgabedatum || 0).getTime())
    .filter(ag => {
      if (myKameradName.value) return ag.Kamerad === myKameradName.value
      return !filterVerlaufKamerad.value || ag.Kamerad === filterVerlaufKamerad.value
    })
)

export const pruefungenByAusruestung = computed(() => {
  const map = new Map()
  pruefungen.value.forEach(p => {
    if (!p.Ausruestungstueck_Id) return
    if (!map.has(p.Ausruestungstueck_Id)) map.set(p.Ausruestungstueck_Id, [])
    map.get(p.Ausruestungstueck_Id).push(p)
  })
  return map
})

export const waescheByAusruestung = computed(() => {
  const map = new Map()
  waescheListe.value.forEach(w => {
    if (!w.Ausruestungstueck_Id) return
    if (!map.has(w.Ausruestungstueck_Id)) map.set(w.Ausruestungstueck_Id, [])
    map.get(w.Ausruestungstueck_Id).push(w)
  })
  return map
})

export const ausgabenByAusruestung = computed(() => {
  const map = new Map()
  ausgaben.value.forEach(ag => {
    if (!ag.Ausruestungstueck_Id) return
    if (!map.has(ag.Ausruestungstueck_Id)) map.set(ag.Ausruestungstueck_Id, [])
    map.get(ag.Ausruestungstueck_Id).push(ag)
  })
  return map
})

export const schadensByAusruestung = computed(() => {
  const map = new Map<number, Schadensdokumentation[]>()
  schadensdokumentation.value.forEach(s => {
    if (!s.Ausruestungstueck_Id) return
    if (!map.has(s.Ausruestungstueck_Id)) map.set(s.Ausruestungstueck_Id, [])
    map.get(s.Ausruestungstueck_Id)!.push(s)
  })
  return map
})

export const pruefungenFiltered = computed(() => {
  let list = [...pruefungen.value].sort((a, b) => new Date(b.Datum || 0).getTime() - new Date(a.Datum || 0).getTime())
  if (myKameradName.value) list = list.filter(p => p.Kamerad === myKameradName.value)
  else if (filterVerlaufKamerad.value) list = list.filter(p => p.Kamerad === filterVerlaufKamerad.value)
  return list
})

export const waescheFiltered = computed(() => {
  let list = [...waescheListe.value].sort((a, b) => new Date(b.Datum || 0).getTime() - new Date(a.Datum || 0).getTime())
  if (myKameradName.value) list = list.filter(w => w.Kamerad === myKameradName.value)
  else if (filterVerlaufKamerad.value) list = list.filter(w => w.Kamerad === filterVerlaufKamerad.value)
  return list
})

export const changelogFiltered = computed(() => {
  let list = [...changelog.value].sort((a, b) => new Date(b.Zeitpunkt || 0).getTime() - new Date(a.Zeitpunkt || 0).getTime())
  if (filterChangelog.value) list = list.filter(c => c.Aktion === filterChangelog.value)
  return list
})

// ── Computed: Backup-Status ────────────────────────────────────────────────
export const backupEntries = computed(() =>
  [...changelog.value]
    .filter(c => c.Tabelle === 'Backup')
    .sort((a, b) => new Date(b.Zeitpunkt || 0).getTime() - new Date(a.Zeitpunkt || 0).getTime())
    .slice(0, 10)
)

// ── Computed: Stats & Warnungen ────────────────────────────────────────────
export const stats = computed(() => ({
  kameraden:       kameraden.value.filter(k => k.Aktiv).length,
  ausruestung:     ausruestung.value.length,
  ausgegeben:      ausruestung.value.filter(a => a.Status === 'Ausgegeben').length,
  pruefungFaellig: ausruestung.value.filter(a => a.Naechste_Pruefung && new Date(a.Naechste_Pruefung) <= _in30).length,
}))

export const warnungen = computed(() => {
  const w: Warnung[] = []
  ausruestung.value.forEach(a => {
    if (a.Naechste_Pruefung) {
      const d = new Date(a.Naechste_Pruefung)
      if (d < _today) {
        w.push({ id: `p-${a.Id}`, prio: 'rot', ausruestungId: a.Id,
          titel: `Prüfung überfällig: ${a.Ausruestungstyp||'?'} (${a.Seriennummer||''})`,
          detail: `Kamerad: ${a.Kamerad||'–'} · Fällig: ${fmtDate(a.Naechste_Pruefung)}` })
      } else if (d <= _in30) {
        w.push({ id: `p2-${a.Id}`, prio: 'orange', ausruestungId: a.Id,
          titel: `Prüfung bald fällig: ${a.Ausruestungstyp||'?'} (${a.Seriennummer||''})`,
          detail: `Kamerad: ${a.Kamerad||'–'} · Fällig: ${fmtDate(a.Naechste_Pruefung)}` })
      }
    }
    if (a.Lebensende_Datum) {
      const d = new Date(a.Lebensende_Datum)
      if (d < _today) {
        w.push({ id: `l-${a.Id}`, prio: 'rot', ausruestungId: a.Id,
          titel: `Lebensende überschritten: ${a.Ausruestungstyp||'?'} (${a.Seriennummer||''})`,
          detail: `Kamerad: ${a.Kamerad||'–'} · Lebensende: ${fmtDate(a.Lebensende_Datum)}` })
      } else if (d <= _in180) {
        w.push({ id: `l2-${a.Id}`, prio: 'gelb', ausruestungId: a.Id,
          titel: `Lebensende in < 6 Monaten: ${a.Ausruestungstyp||'?'} (${a.Seriennummer||''})`,
          detail: `Kamerad: ${a.Kamerad||'–'} · Lebensende: ${fmtDate(a.Lebensende_Datum)}` })
      }
    }
    const wi = waeschenInfo(a.Id, a.Ausruestungstyp)
    if (wi) {
      if (wi.count >= wi.max) {
        w.push({ id: `wmax-${a.Id}`, prio: 'rot', ausruestungId: a.Id,
          titel: `Waschzyklus-Limit erreicht: ${a.Ausruestungstyp||'?'} (${a.Seriennummer||''})`,
          detail: `Kamerad: ${a.Kamerad||'–'} · ${wi.count}/${wi.max} Wäschen` })
      } else if (wi.count / wi.max >= 0.9) {
        w.push({ id: `wbald-${a.Id}`, prio: 'orange', ausruestungId: a.Id,
          titel: `Waschzyklus-Limit fast erreicht: ${a.Ausruestungstyp||'?'} (${a.Seriennummer||''})`,
          detail: `Kamerad: ${a.Kamerad||'–'} · ${wi.count}/${wi.max} Wäschen (${wi.max - wi.count} verbleibend)` })
      }
    }
    // Größen-Abweichung: Ausrüstungsgröße ≠ hinterlegte Kamerad-Größe
    if (a.Kamerad && a.Groesse && a.Status === 'Ausgegeben') {
      const k = kameraden.value.find(x => `${x.Vorname} ${x.Name}` === a.Kamerad)
      if (k) {
        const typ = typen.value.find(t => t.Bezeichnung === a.Ausruestungstyp)
        const entry = typ?.Typ ? GROESSE_KAT_MAP[typ.Typ] : undefined
        if (entry) {
          const kGroesse = k[entry.field] ? String(k[entry.field]) : ''
          const aGroesse = String(a.Groesse).trim()
          if (kGroesse && kGroesse.toLowerCase() !== aGroesse.toLowerCase()) {
            w.push({ id: `gr-${a.Id}`, prio: 'gelb', ausruestungId: a.Id,
              titel: `Größe passt nicht: ${a.Ausruestungstyp||'?'} (${a.Seriennummer||''})`,
              detail: `Kamerad: ${a.Kamerad} · Stück: ${aGroesse} · Erwartet: ${kGroesse}` })
          }
        }
      }
    }
  })
  const prioOrder: Record<string, number> = { rot: 0, orange: 1, gelb: 2 }
  return w.sort((a, b) => prioOrder[a.prio] - prioOrder[b.prio])
})

// ── Computed: Multi-Select ─────────────────────────────────────────────────
export const alleAusgewaehlt = computed(() =>
  ausruestungFiltered.value.length > 0 &&
  ausruestungFiltered.value.every(a => selectedIds.value.includes(a.Id))
)

// ── Größen-Mapping (Typ-Kategorie → Kamerad-Feld) ─────────────────────────
export const GROESSE_KAT_MAP: Record<string, GroesseKatEntry> = {
  'Jacke':            { label: 'Jacke',        field: 'Jacke_Groesse' },
  'Hose':             { label: 'Hose',         field: 'Hose_Groesse' },
  'Stiefel':          { label: 'Stiefel (EU)', field: 'Stiefel_Groesse' },
  'Handschuh':        { label: 'Handschuh',    field: 'Handschuh_Groesse' },
  'Hemd':             { label: 'Hemd',         field: 'Hemd_Groesse' },
  'Poloshirt':        { label: 'Poloshirt',    field: 'Poloshirt_Groesse' },
  'Fleece/Softshell': { label: 'Fleece',       field: 'Fleece_Groesse' },
}

// ── Computed: Größen-Hinweis (Ausgabe-Formular) ────────────────────────────
export const ausruestungGroesseHint = computed(() => {
  if (!form.ausgabe.kamerad) return null
  const k = kameraden.value.find(x => `${x.Vorname} ${x.Name}` === form.ausgabe.kamerad)
  if (!k) return null
  const typ = typen.value.find(t => t.Bezeichnung === form.aktion.Ausruestungstyp)
  const entry = typ?.Typ ? GROESSE_KAT_MAP[typ.Typ] : undefined
  if (!entry) return null
  const kGroesse = k[entry.field] ? String(k[entry.field]) : ''
  const ausrGroesse = form.aktion?.Groesse ? String(form.aktion.Groesse).trim() : ''
  const mismatch = !!(kGroesse && ausrGroesse && kGroesse.toLowerCase() !== ausrGroesse.toLowerCase())
  return { label: entry.label, val: kGroesse, mismatch }
})

// ── Helper-Funktionen ──────────────────────────────────────────────────────
export function waeschenInfo(ausruestungId: number, ausruestungstyp: string | null) {
  const typ = typen.value.find(t => t.Bezeichnung === ausruestungstyp)
  if (!typ?.Max_Waeschen) return null
  const count = (waescheByAusruestung.value.get(ausruestungId) || []).length
  return { count, max: typ.Max_Waeschen }
}

export function ausruestungFuerKamerad(k: Kamerad) {
  const label = `${k.Vorname} ${k.Name}`
  return ausruestung.value.filter(a => a.Kamerad === label)
}

export function letzteAktion(ausruestungId: number, typ: string) {
  const list: (Pruefung | Waesche)[] = (typ === 'pruefung'
    ? pruefungenByAusruestung.value.get(ausruestungId)
    : waescheByAusruestung.value.get(ausruestungId)) || []
  if (!list.length) return null
  return list.reduce((a, b) => new Date(a.Datum!) > new Date(b.Datum!) ? a : b)
}

export function kameradenGroessen(k: Kamerad) {
  return [
    { label: 'Jacke',     wert: k.Jacke_Groesse },
    { label: 'Hose',      wert: k.Hose_Groesse },
    { label: 'Stiefel',   wert: k.Stiefel_Groesse },
    { label: 'Handschuh', wert: k.Handschuh_Groesse },
    { label: 'Hemd',      wert: k.Hemd_Groesse },
    { label: 'Poloshirt', wert: k.Poloshirt_Groesse },
    { label: 'Fleece',    wert: k.Fleece_Groesse },
  ]
}

export function toggleSelect(id: number) {
  const idx = selectedIds.value.indexOf(id)
  if (idx === -1) selectedIds.value.push(id)
  else selectedIds.value.splice(idx, 1)
}

export function toggleAlle() {
  if (alleAusgewaehlt.value) selectedIds.value = []
  else selectedIds.value = ausruestungFiltered.value.map(a => a.Id)
}

// ── Audit-Log ──────────────────────────────────────────────────────────────
export async function logChange(tabelle: string, aktion: string, details: string | null) {
  if (!TABLES.Changelog) return
  try {
    await post('Changelog', {
      Tabelle:   tabelle,
      Aktion:    aktion,
      Details:   details,
      Benutzer:  currentUser.value?.Benutzername || '–',
      Zeitpunkt: new Date().toISOString(),
    })
  } catch (e) {
    console.warn('Changelog-Eintrag fehlgeschlagen:', e)
  }
}

// ── Alle Daten laden ───────────────────────────────────────────────────────
export async function fetchAll(renderChartsCallback?: (() => void) | null) {
  loading.value = true
  try {
    // Nicht eingeloggt: nur First-Run prüfen, keine Daten laden
    if (!loggedIn.value) {
      try {
        const initialized = await isInitialized()
        needsSetup.value = !initialized
      } catch(e) {
        // Offline oder Verbindungsfehler – Login-Screen zeigen
      }
      loading.value = false
      return
    }

    const results = await Promise.allSettled([
      getAll('Kameraden'),
      getAll('Ausruestungstuecke'),
      getAll('Ausruestungstypen'),
      getAll('Ausgaben'),
      getAll('Pruefungen'),
      getAll('Waesche'),
      getAll('Normen'),
      TABLES.Changelog ? getAll('Changelog') : Promise.resolve([]),
      TABLES.Benutzer  ? getAll('Benutzer')  : Promise.resolve([]),
      getAll('Schadensdokumentation'),
    ])
    const val = (i: number) => { const r = results[i]; return r.status === 'fulfilled' ? r.value : [] }
    kameraden.value             = val(0) as unknown as Kamerad[]
    ausruestung.value           = val(1) as unknown as Ausruestungstueck[]
    typen.value                 = val(2) as unknown as Ausruestungstyp[]
    ausgaben.value              = val(3) as unknown as Ausgabe[]
    pruefungen.value            = val(4) as unknown as Pruefung[]
    waescheListe.value          = val(5) as unknown as Waesche[]
    normen.value                = val(6) as unknown as Norm[]
    changelog.value             = val(7) as unknown as ChangelogEntry[]
    benutzer.value              = val(8) as unknown as Benutzer[]
    schadensdokumentation.value = val(9) as unknown as Schadensdokumentation[]
    isOffline.value    = false
    saveOfflineSnapshot()
    if (renderChartsCallback) {
      import('vue').then(({ nextTick }) => nextTick(renderChartsCallback))
    }
  } catch(e) {
    if (!loadOfflineSnapshot()) {
      showToast('Verbindung fehlgeschlagen und kein Offline-Cache vorhanden', 'error')
    } else {
      showToast('Offline – zeige zwischengespeicherte Daten', 'error')
    }
  } finally {
    loading.value = false
  }
}

// ── Auth-Aktionen ──────────────────────────────────────────────────────────
export async function doLogin() {
  loginForm.error = ''
  if (!loginForm.username || !loginForm.pin) {
    loginForm.error = 'Bitte Benutzername und Passwort eingeben.'
    return
  }
  await load(async () => {
    const result = await authenticate(loginForm.username, loginForm.pin)
    setJwt(result.token)
    currentUser.value = result.user
    localStorage.setItem('psa_user', JSON.stringify(result.user))
    loggedIn.value     = true
    page.value         = (result.user.Rolle || '').toLowerCase() === 'user' ? 'mein-dashboard' : 'dashboard'
    loginForm.username = ''
    loginForm.pin      = ''
    await fetchAll()
  })
}

export async function doSetup() {
  setupForm.error = ''
  if (!setupForm.username.trim() || !setupForm.pin.trim()) {
    setupForm.error = 'Bitte Benutzername und Passwort eingeben.'
    return
  }
  if (setupForm.pin.length < 6) {
    setupForm.error = 'Passwort muss mindestens 6 Zeichen haben.'
    return
  }
  if (setupForm.pin !== setupForm.pinConfirm) {
    setupForm.error = 'Passwörter stimmen nicht überein.'
    return
  }
  await load(async () => {
    const result = await createAdmin(setupForm.username.trim(), setupForm.pin.trim())
    setJwt(result.token)
    currentUser.value    = result.user
    localStorage.setItem('psa_user', JSON.stringify(result.user))
    needsSetup.value     = false
    loggedIn.value       = true
    setupForm.username   = ''
    setupForm.pin        = ''
    setupForm.pinConfirm = ''
    await fetchAll()
  })
}

export function doLogout() {
  clearJwt()
  localStorage.removeItem('psa_user')
  loggedIn.value     = false
  currentUser.value  = null
  page.value         = 'dashboard'
}

// ── Kameraden-Aktionen ─────────────────────────────────────────────────────
export function openKameradenForm(k: Partial<Kamerad> = {}) {
  form.kamerad = { Aktiv: true, ...k }
  modal.kameradenForm = true
}

export function openKameradenDetail(k: Kamerad) {
  selectedKamerad.value = k
  modal.kameradenDetail = true
}

export async function saveKamerad() {
  if (!form.kamerad.Name?.trim() || !form.kamerad.Vorname?.trim()) {
    showToast('"Name" und "Vorname" sind Pflichtfelder', 'error'); return
  }
  await load(async () => {
    const { Id } = form.kamerad
    const oldK     = Id ? kameraden.value.find(k => k.Id === Id) : null
    const oldLabel = oldK ? `${oldK.Vorname} ${oldK.Name}` : null
    const newLabel = `${form.kamerad.Vorname} ${form.kamerad.Name}`
    const payload = {
      Vorname:           form.kamerad.Vorname           || null,
      Name:              form.kamerad.Name              || null,
      Dienstgrad:        form.kamerad.Dienstgrad        || null,
      Email:             form.kamerad.Email             || null,
      Jacke_Groesse:     form.kamerad.Jacke_Groesse     || null,
      Hose_Groesse:      form.kamerad.Hose_Groesse      || null,
      Stiefel_Groesse:   form.kamerad.Stiefel_Groesse   || null,
      Handschuh_Groesse: form.kamerad.Handschuh_Groesse || null,
      Hemd_Groesse:      form.kamerad.Hemd_Groesse      || null,
      Poloshirt_Groesse: form.kamerad.Poloshirt_Groesse || null,
      Fleece_Groesse:    form.kamerad.Fleece_Groesse    || null,
      Aktiv:             form.kamerad.Aktiv             ?? true,
    }
    if (Id) await patch('Kameraden', Id, payload)
    else    await post('Kameraden', payload)
    if (Id && oldLabel && oldLabel !== newLabel) {
      const affected = ausruestung.value.filter(a => a.Kamerad === oldLabel)
      await Promise.all(affected.map(a => patch('Ausruestungstuecke', a.Id, { Kamerad: newLabel })))
      if (affected.length) showToast(`${affected.length} Ausrüstungsstück${affected.length > 1 ? 'e' : ''} aktualisiert`)
    }
    modal.kameradenForm = false
    showToast('Kamerad gespeichert')
    logChange('Kameraden', Id ? 'Bearbeitet' : 'Erstellt', newLabel)
    await fetchAll()
  })
}

export async function deleteKamerad(k: Kamerad) {
  const label    = `${k.Vorname} ${k.Name}`
  const assigned = ausruestung.value.filter(a => a.Kamerad === label).length
  const msg = assigned
    ? `${label} hat noch ${assigned} zugewiesene${assigned > 1 ? ' Ausrüstungsstücke' : 's Ausrüstungsstück'}. Trotzdem löschen?`
    : `${label} wirklich löschen?`
  if (!confirm(msg)) return
  await load(async () => {
    await del('Kameraden', k.Id)
    showToast('Gelöscht')
    logChange('Kameraden', 'Gelöscht', label)
    await fetchAll()
  })
}

// ── CSV-Import ─────────────────────────────────────────────────────────────
export function downloadBeispielCSV() {
  const header = 'Vorname;Name;Dienstgrad;Jacke_Groesse;Hose_Groesse;Stiefel_Groesse;Handschuh_Groesse;Hemd_Groesse;Poloshirt_Groesse;Fleece_Groesse;Aktiv'
  const rows   = [
    'Max;Mustermann;Hauptfeuerwehrmann;52;52;42;9;40/41;L;L;ja',
    'Anna;Musterfrau;Feuerwehrfrau;40;38;37;7;36/37;S;S;ja',
  ]
  const csv  = '\uFEFF' + [header, ...rows].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url  = URL.createObjectURL(blob)
  const a    = document.createElement('a')
  a.href = url; a.download = 'kameraden_vorlage.csv'; a.click()
  URL.revokeObjectURL(url)
}

export function openCsvImport() {
  form.csvImport = { rows: [], fileName: '' }
  modal.csvImport = true
}

export function onCsvFile(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  form.csvImport.fileName = file.name
  const reader = new FileReader()
  reader.onload = (e: ProgressEvent<FileReader>) => {
    const text  = (e.target!.result as string).replace(/\r\n/g, '\n').replace(/\r/g, '\n')
    const lines = text.split('\n').filter(l => l.trim())
    if (lines.length < 2) { showToast('CSV hat keine Datenzeilen', 'error'); return }
    const delim   = lines[0].includes(';') ? ';' : ','
    const headers = lines[0].split(delim).map(h => h.trim().replace(/^"|"$/g, ''))
    const rows: CsvRow[] = []
    for (let i = 1; i < lines.length; i++) {
      const vals = lines[i].split(delim).map(v => v.trim().replace(/^"|"$/g, ''))
      const row: Record<string, string | boolean> = {}
      headers.forEach((h, idx) => { row[h] = vals[idx] ?? '' })
      const _Vorname = String(row.Vorname || row.vorname || '')
      const _Name    = String(row.Name    || row.name    || '')
      row._Vorname   = _Vorname
      row._Name      = _Name
      row._error     = (!_Vorname || !_Name) ? 'Vorname und Name sind Pflichtfelder' : ''
      row._duplicate = !row._error && kameraden.value.some(k =>
        k.Vorname?.toLowerCase() === _Vorname.toLowerCase() &&
        k.Name?.toLowerCase()    === _Name.toLowerCase()
      )
      rows.push(row as CsvRow)
    }
    form.csvImport.rows = rows
    if (!rows.length) showToast('Keine Zeilen gefunden', 'error')
  }
  reader.readAsText(file, 'UTF-8')
  ;(event.target as HTMLInputElement).value = ''
}

export async function importKameraden() {
  const valid      = form.csvImport.rows.filter(r => !r._error)
  const duplicates = valid.filter(r => r._duplicate)
  if (!valid.length) { showToast('Keine gültigen Zeilen zum Importieren', 'error'); return }
  if (duplicates.length) {
    const namen = duplicates.map(r => `${r._Vorname} ${r._Name}`).join(', ')
    const ok = confirm(`${duplicates.length} Kamerad${duplicates.length !== 1 ? 'en' : ''} bereits vorhanden:\n${namen}\n\nTrotzdem importieren (Duplikate anlegen)?`)
    if (!ok) return
  }
  await load(async () => {
    for (const row of valid) {
      const aktivRaw = String(row.Aktiv || row.aktiv || 'ja').toLowerCase().trim()
      const aktiv    = !['nein', '0', 'false', 'falsch', 'no'].includes(aktivRaw)
      await post('Kameraden', {
        Vorname:           row._Vorname,
        Name:              row._Name,
        Dienstgrad:        row.Dienstgrad    || null,
        Jacke_Groesse:     row.Jacke_Groesse || null,
        Hose_Groesse:      row.Hose_Groesse  || null,
        Stiefel_Groesse:   row.Stiefel_Groesse ? Number(row.Stiefel_Groesse) : null,
        Handschuh_Groesse: row.Handschuh_Groesse || null,
        Hemd_Groesse:      row.Hemd_Groesse  || null,
        Poloshirt_Groesse: row.Poloshirt_Groesse || null,
        Fleece_Groesse:    row.Fleece_Groesse || null,
        Aktiv:             aktiv,
      })
    }
    modal.csvImport = false
    showToast(`${valid.length} Kamerad${valid.length !== 1 ? 'en' : ''} importiert`)
    await fetchAll()
  })
}

// ── Ausrüstung CSV-Import ──────────────────────────────────────────────────
export function downloadAusruestungBeispielCSV() {
  const header = 'Ausruestungstyp;Seriennummer;Kamerad;Status;Groesse;Naechste_Pruefung;Kaufdatum;Notizen'
  const rows   = [
    'Feuerschutzhaube Typ 1;SN-001;;Lager;M;2026-12-01;;',
    'Feuerschutzhose Typ 2;SN-002;Max Mustermann;Ausgegeben;52;2026-06-15;2024-01-01;',
  ]
  const csv  = '\uFEFF' + [header, ...rows].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url  = URL.createObjectURL(blob)
  const a    = document.createElement('a')
  a.href = url; a.download = 'ausruestung_vorlage.csv'; a.click()
  URL.revokeObjectURL(url)
}

export function openAusruestungCsvImport() {
  form.ausruestungCsv = { rows: [], fileName: '' }
  modal.ausruestungCsvImport = true
}

export function onAusruestungCsvFile(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  form.ausruestungCsv.fileName = file.name
  const reader = new FileReader()
  reader.onload = (e: ProgressEvent<FileReader>) => {
    const text  = (e.target!.result as string).replace(/\r\n/g, '\n').replace(/\r/g, '\n')
    const lines = text.split('\n').filter(l => l.trim())
    if (lines.length < 2) { showToast('CSV hat keine Datenzeilen', 'error'); return }
    const delim   = lines[0].includes(';') ? ';' : ','
    const headers = lines[0].split(delim).map(h => h.trim().replace(/^"|"$/g, ''))
    const bekannteTypen = typen.value.map(t => (t.Bezeichnung || '').toLowerCase())
    const rows: AusruestungCsvRow[] = []
    for (let i = 1; i < lines.length; i++) {
      const vals = lines[i].split(delim).map(v => v.trim().replace(/^"|"$/g, ''))
      const row: Record<string, string | boolean> = {}
      headers.forEach((h, idx) => { row[h] = vals[idx] ?? '' })
      const _Typ = String(row.Ausruestungstyp || row.ausruestungstyp || '')
      row._Typ = _Typ
      if (!_Typ) {
        row._error = 'Ausruestungstyp ist Pflichtfeld'
      } else if (!bekannteTypen.includes(_Typ.toLowerCase())) {
        row._error = `Unbekannter Typ: "${_Typ}"`
      } else {
        row._error = ''
      }
      const sn = String(row.Seriennummer || '')
      row._duplicate = !row._error && !!sn && ausruestung.value.some(a =>
        a.Seriennummer === sn &&
        (a.Ausruestungstyp || '').toLowerCase() === _Typ.toLowerCase()
      )
      rows.push(row as AusruestungCsvRow)
    }
    form.ausruestungCsv.rows = rows
    if (!rows.length) showToast('Keine Zeilen gefunden', 'error')
  }
  reader.readAsText(file, 'UTF-8')
  ;(event.target as HTMLInputElement).value = ''
}

function parseDateCsv(val: string): string | null {
  if (!val) return null
  // DD.MM.YYYY → YYYY-MM-DD
  const de = val.match(/^(\d{1,2})\.(\d{1,2})\.(\d{4})$/)
  if (de) return `${de[3]}-${de[2].padStart(2, '0')}-${de[1].padStart(2, '0')}`
  // already YYYY-MM-DD
  if (/^\d{4}-\d{2}-\d{2}$/.test(val)) return val
  return null
}

export async function importAusruestung() {
  const valid      = form.ausruestungCsv.rows.filter(r => !r._error)
  const duplicates = valid.filter(r => r._duplicate)
  if (!valid.length) { showToast('Keine gültigen Zeilen zum Importieren', 'error'); return }
  if (duplicates.length) {
    const sns = duplicates.map(r => `${r._Typ} / ${r.Seriennummer}`).join(', ')
    const ok = confirm(`${duplicates.length} mögliche Duplikate (Seriennummer+Typ bereits vorhanden):\n${sns}\n\nTrotzdem importieren?`)
    if (!ok) return
  }
  await load(async () => {
    const statusWerte = ['Lager', 'Ausgegeben', 'Reinigung', 'In Reparatur', 'Ausgesondert']
    for (const row of valid) {
      const typMatch = typen.value.find(t => (t.Bezeichnung || '').toLowerCase() === (row._Typ as string).toLowerCase())
      const status   = String(row.Status || '')
      await post('Ausruestungstuecke', {
        Ausruestungstyp:  typMatch?.Bezeichnung || row._Typ,
        Seriennummer:     row.Seriennummer || null,
        Kamerad:          row.Kamerad || null,
        Status:           statusWerte.includes(status) ? status : 'Lager',
        Groesse:          row.Groesse || null,
        Naechste_Pruefung: parseDateCsv(String(row.Naechste_Pruefung || '')),
        Kaufdatum:         parseDateCsv(String(row.Kaufdatum || '')),
        Notizen:           row.Notizen || null,
      })
    }
    modal.ausruestungCsvImport = false
    showToast(`${valid.length} Ausrüstungsstück${valid.length !== 1 ? 'e' : ''} importiert`)
    await fetchAll()
  })
}

// ── Ausrüstung-Aktionen ────────────────────────────────────────────────────
export function openAusruestungForm(a: Partial<Ausruestungstueck> = {}) {
  form.ausruestung = { Status: 'Lager', ...a, Ausruestungstyp: a.Ausruestungstyp || '', Kamerad: a.Kamerad || '' }
  modal.ausruestungForm = true
}

export function openAusruestungDetail(a: Ausruestungstueck, fromKamerad: Kamerad | null = null) {
  selectedAusruestung.value = a
  detailFromKamerad.value   = fromKamerad
  modal.ausruestungDetail   = true
}

export function autoFillAusruestungDaten() {
  const typ = typen.value.find(t => t.Bezeichnung === form.ausruestung.Ausruestungstyp)
  if (!typ) return
  if (form.ausruestung.Herstellungsdatum && typ.Max_Lebensdauer_Jahre) {
    const d = new Date(form.ausruestung.Herstellungsdatum)
    d.setFullYear(d.getFullYear() + typ.Max_Lebensdauer_Jahre)
    form.ausruestung.Lebensende_Datum = d.toISOString().split('T')[0]
  }
  if (typ.Pruefintervall_Monate && !form.ausruestung.Naechste_Pruefung) {
    const d = new Date()
    d.setMonth(d.getMonth() + typ.Pruefintervall_Monate)
    form.ausruestung.Naechste_Pruefung = d.toISOString().split('T')[0]
  }
}

export function autoFillLebensdauer() {
  const typ = typen.value.find(t => t.Bezeichnung === form.ausruestung.Ausruestungstyp)
  if (!typ || !typ.Max_Lebensdauer_Jahre || !form.ausruestung.Herstellungsdatum) return
  const d = new Date(form.ausruestung.Herstellungsdatum)
  d.setFullYear(d.getFullYear() + typ.Max_Lebensdauer_Jahre)
  form.ausruestung.Lebensende_Datum = d.toISOString().split('T')[0]
}

export async function saveAusruestung() {
  if (!form.ausruestung.Ausruestungstyp?.trim()) {
    showToast('"Typ" ist ein Pflichtfeld', 'error'); return
  }
  await load(async () => {
    const { Id } = form.ausruestung
    const oldKamerad = Id ? (ausruestung.value.find(x => x.Id === Id)?.Kamerad || '') : ''
    const newKamerad = form.ausruestung.Kamerad || ''
    const payload = {
      Ausruestungstyp:   form.ausruestung.Ausruestungstyp  || null,
      Kamerad:           form.ausruestung.Kamerad           || null,
      Seriennummer:      form.ausruestung.Seriennummer      || null,
      Groesse:           form.ausruestung.Groesse           || null,
      QR_Code:           form.ausruestung.QR_Code           || null,
      Herstellungsdatum: form.ausruestung.Herstellungsdatum || null,
      Lebensende_Datum:  form.ausruestung.Lebensende_Datum  || null,
      Naechste_Pruefung: form.ausruestung.Naechste_Pruefung || null,
      Status:            form.ausruestung.Status            || 'Lager',
      Notizen:           form.ausruestung.Notizen           || null,
    }
    let savedId = Id
    if (Id) await patch('Ausruestungstuecke', Id, payload)
    else { const r = await post('Ausruestungstuecke', payload); savedId = r?.Id || null }
    if (newKamerad !== oldKamerad) {
      await post('Ausgaben', {
        Ausgabedatum:         todayStr(),
        Kamerad:              newKamerad || null,
        Ausruestungstyp:      form.ausruestung.Ausruestungstyp || null,
        Seriennummer:         form.ausruestung.Seriennummer    || null,
        Ausruestungstueck_Id: savedId || null,
      })
    }
    modal.ausruestungForm = false
    showToast('Ausrüstung gespeichert')
    logChange('Ausrüstung', Id ? 'Bearbeitet' : 'Erstellt', `${form.ausruestung.Ausruestungstyp} (${form.ausruestung.Seriennummer})`)
    await fetchAll()
  })
}

export async function deleteAusruestung(a: Ausruestungstueck) {
  if (!confirm(`Ausrüstungsstück "${a.Seriennummer || a.Id}" wirklich löschen?`)) return
  await load(async () => {
    await del('Ausruestungstuecke', a.Id)
    showToast('Gelöscht')
    logChange('Ausrüstung', 'Gelöscht', `${a.Ausruestungstyp} (${a.Seriennummer})`)
    await fetchAll()
  })
}

export async function quickStatus(item: Ausruestungstueck, newStatus: string) {
  if (item.Status === newStatus) return
  await load(async () => {
    await patch('Ausruestungstuecke', item.Id, { Status: newStatus })
    item.Status = newStatus
    showToast(`Status → ${newStatus}`)
  })
}

// ── Ausgabe / Rückgabe ─────────────────────────────────────────────────────
export function openAusgabe(a: Ausruestungstueck) {
  form.aktion  = a
  form.ausgabe = { datum: todayStr(), kamerad: a.Kamerad || '', notizen: '' }
  modal.ausgabe = true
}

export async function saveAusgabe() {
  if (!form.ausgabe.kamerad?.trim()) { showToast('"Kamerad" ist ein Pflichtfeld', 'error'); return }
  await load(async () => {
    await patch('Ausruestungstuecke', form.aktion.Id, { Kamerad: form.ausgabe.kamerad, Status: 'Ausgegeben' })
    await post('Ausgaben', {
      Ausgabedatum:         form.ausgabe.datum,
      Kamerad:              form.ausgabe.kamerad,
      Notizen:              form.ausgabe.notizen || null,
      Ausruestungstyp:      form.aktion.Ausruestungstyp,
      Seriennummer:         form.aktion.Seriennummer,
      Ausruestungstueck_Id: form.aktion.Id,
    })
    modal.ausgabe = false
    showToast('Ausgabe gespeichert')
    logChange('Ausgaben', 'Ausgegeben', `${form.aktion.Ausruestungstyp} → ${form.ausgabe.kamerad}`)
    await fetchAll()
  })
}

export function openRueckgabe(ag: Ausgabe) {
  form.rueckgabeAusgabe = ag
  form.rueckgabe = { datum: todayStr() }
  modal.rueckgabe = true
}

export async function saveRueckgabe() {
  await load(async () => {
    const ag = form.rueckgabeAusgabe
    if (ag) await patch('Ausgaben', ag.Id, { Rueckgabedatum: form.rueckgabe.datum })
    const ausrStueck = ausruestung.value.find(a => a.Id === ag?.Ausruestungstueck_Id)
    if (ausrStueck) await patch('Ausruestungstuecke', ausrStueck.Id, { Kamerad: null, Status: 'Lager' })
    modal.rueckgabe = false
    showToast('Rückgabe gespeichert')
    logChange('Ausgaben', 'Zurückgegeben', ag?.Ausruestungstyp || '?')
    await fetchAll()
  })
}

// ── Prüfungen ──────────────────────────────────────────────────────────────
export function openPruefung(a: Ausruestungstueck) {
  form.aktion  = a
  form.pruefung = {
    datum:    todayStr(),
    ergebnis: 'Bestanden',
    pruefer:  currentUser.value?.Benutzername || '',
    notizen:  '',
    foto:     null,
    naechste: '',
  }
  recalcNaechstePruefung()
  modal.pruefung = true
}

export function recalcNaechstePruefung() {
  const typ = typen.value.find(t => t.Bezeichnung === form.aktion.Ausruestungstyp)
  if (!typ?.Pruefintervall_Monate) return
  const d = new Date(form.pruefung.datum || todayStr())
  d.setMonth(d.getMonth() + typ.Pruefintervall_Monate)
  form.pruefung.naechste = d.toISOString().split('T')[0]
}

// Generische Foto-Upload-Funktion (800px, JPEG 70%)
export function onFotoUpload(event: Event, callback: (dataUrl: string) => void) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = (e: ProgressEvent<FileReader>) => {
    const img = new Image()
    img.src = e.target!.result as string
    img.onload = () => {
      const canvas = document.createElement('canvas')
      const MAX = 800
      let w = img.width, h = img.height
      if (w > MAX) { h = h * MAX / w; w = MAX }
      canvas.width = w; canvas.height = h
      canvas.getContext('2d')!.drawImage(img, 0, 0, w, h)
      callback(canvas.toDataURL('image/jpeg', 0.7))
    }
  }
  reader.readAsDataURL(file)
}

export function onPruefungFoto(event: Event) {
  onFotoUpload(event, (url) => { form.pruefung.foto = url })
}

// ── Schadensdokumentation ──────────────────────────────────────────────────
export function openSchaden(a: Ausruestungstueck) {
  form.aktion = a
  form.schaden = { datum: todayStr(), beschreibung: '', foto: null }
  modal.schaden = true
}

export async function saveSchaden() {
  if (!form.schaden.foto) { showToast('Bitte ein Foto aufnehmen', 'error'); return }
  await load(async () => {
    await post('Schadensdokumentation', {
      Datum:                 form.schaden.datum,
      Beschreibung:          form.schaden.beschreibung || null,
      Foto:                  form.schaden.foto,
      Erstellt_Von:          currentUser.value?.Benutzername || null,
      Ausruestungstueck_Id:  form.aktion.Id,
      Ausruestungstyp:       form.aktion.Ausruestungstyp || null,
      Seriennummer:          form.aktion.Seriennummer    || null,
    })
    modal.schaden = false
    showToast('Schaden dokumentiert')
    logChange('Schadensdokumentation', 'Erstellt', `${form.aktion.Ausruestungstyp} – ${form.schaden.beschreibung || 'Foto'}`)
    await fetchAll()
  })
}

export async function deleteSchaden(s: Schadensdokumentation) {
  if (!confirm('Diesen Schadenseintrag wirklich löschen?')) return
  await load(async () => {
    await del('Schadensdokumentation', s.Id)
    showToast('Eintrag gelöscht')
    await fetchAll()
  })
}

export async function savePruefung() {
  if (!form.pruefung.datum?.trim()) { showToast('"Datum" ist ein Pflichtfeld', 'error'); return }
  await load(async () => {
    await post('Pruefungen', {
      Datum:                form.pruefung.datum,
      Ergebnis:             form.pruefung.ergebnis,
      Pruefer:              form.pruefung.pruefer            || null,
      Naechste_Pruefung:    form.pruefung.naechste           || null,
      Notizen:              form.pruefung.notizen            || null,
      Foto:                 form.pruefung.foto               || null,
      Ausruestungstueck_Id: form.aktion.Id,
      Kamerad:              form.aktion.Kamerad              || null,
      Ausruestungstyp:      form.aktion.Ausruestungstyp      || null,
      Seriennummer:         form.aktion.Seriennummer         || null,
    })
    if (form.pruefung.naechste) {
      await patch('Ausruestungstuecke', form.aktion.Id, { Naechste_Pruefung: form.pruefung.naechste })
    }
    modal.pruefung = false
    showToast('Prüfung gespeichert')
    logChange('Prüfungen', 'Geprüft', `${form.aktion.Ausruestungstyp} – ${form.pruefung.ergebnis}`)
    await fetchAll()
  })
}

// ── Wäsche ─────────────────────────────────────────────────────────────────
export function openWaesche(a: Ausruestungstueck) {
  form.aktion = a
  form.waesche = { datum: todayStr(), art: 'Normal', notizen: '' }
  modal.waesche = true
}

export async function saveWaesche() {
  if (!form.waesche.datum?.trim()) { showToast('"Datum" ist ein Pflichtfeld', 'error'); return }
  await load(async () => {
    await post('Waesche', {
      Datum:                form.waesche.datum,
      Waescheart:           form.waesche.art               || null,
      Notizen:              form.waesche.notizen            || null,
      Ausruestungstueck_Id: form.aktion.Id,
      Kamerad:              form.aktion.Kamerad             || null,
      Ausruestungstyp:      form.aktion.Ausruestungstyp     || null,
      Seriennummer:         form.aktion.Seriennummer        || null,
    })
    modal.waesche = false
    showToast('Wäsche gespeichert')
    logChange('Wäsche', 'Gewaschen', form.aktion.Ausruestungstyp || '?')
    await fetchAll()
  })
}

// ── Massenwäsche / Massenprüfung ───────────────────────────────────────────
export function openMassenWaesche() {
  form.massenWaesche = { datum: todayStr(), art: 'Normal', notizen: '' }
  modal.massenWaesche = true
}

export async function saveMassenWaesche() {
  if (!selectedIds.value.length) { showToast('Keine Ausrüstungsstücke ausgewählt', 'error'); return }
  await load(async () => {
    const selected = ausruestung.value.filter(a => selectedIds.value.includes(a.Id))
    for (const a of selected) {
      await post('Waesche', {
        Datum:                form.massenWaesche.datum,
        Waescheart:           form.massenWaesche.art       || null,
        Notizen:              form.massenWaesche.notizen   || null,
        Ausruestungstueck_Id: a.Id,
        Kamerad:              a.Kamerad                    || null,
        Ausruestungstyp:      a.Ausruestungstyp            || null,
        Seriennummer:         a.Seriennummer               || null,
      })
    }
    modal.massenWaesche  = false
    selectedIds.value    = []
    showToast(`${selected.length} Wäschen gespeichert`)
    logChange('Wäsche', 'Massenwäsche', `${selected.length} Stücke`)
    await fetchAll()
  })
}

export function openMassenPruefung() {
  form.massenPruefung = { datum: todayStr(), ergebnis: 'Bestanden', pruefer: currentUser.value?.Benutzername || '', notizen: '', naechste: '' }
  modal.massenPruefung = true
}

export async function saveMassenPruefung() {
  if (!selectedIds.value.length) { showToast('Keine Ausrüstungsstücke ausgewählt', 'error'); return }
  await load(async () => {
    const selected = ausruestung.value.filter(a => selectedIds.value.includes(a.Id))
    for (const a of selected) {
      // Typ-spezifisches nächstes Prüfdatum berechnen
      const typ = typen.value.find(t => t.Bezeichnung === a.Ausruestungstyp)
      let naechste = form.massenPruefung.naechste || null
      if (!naechste && typ?.Pruefintervall_Monate) {
        const d = new Date(form.massenPruefung.datum)
        d.setMonth(d.getMonth() + typ.Pruefintervall_Monate)
        naechste = d.toISOString().split('T')[0]
      }
      await post('Pruefungen', {
        Datum:                form.massenPruefung.datum,
        Ergebnis:             form.massenPruefung.ergebnis,
        Pruefer:              form.massenPruefung.pruefer   || null,
        Naechste_Pruefung:    naechste,
        Notizen:              form.massenPruefung.notizen   || null,
        Ausruestungstueck_Id: a.Id,
        Kamerad:              a.Kamerad                     || null,
        Ausruestungstyp:      a.Ausruestungstyp             || null,
        Seriennummer:         a.Seriennummer                || null,
      })
      if (naechste) await patch('Ausruestungstuecke', a.Id, { Naechste_Pruefung: naechste })
    }
    modal.massenPruefung = false
    selectedIds.value    = []
    showToast(`${selected.length} Prüfungen gespeichert`)
    logChange('Prüfungen', 'Massenprüfung', `${selected.length} Stücke`)
    await fetchAll()
  })
}

// ── Typen CRUD ─────────────────────────────────────────────────────────────
export function openTypenForm(t: Partial<Ausruestungstyp> = {}) {
  form.typ = { ...t, _normWahl: '', _normHinweis: '' }
  modal.typForm = true
}

export function onTypChange() {
  form.typ._normWahl    = ''
  form.typ._normHinweis = ''
  form.typ.Norm         = ''
}

export function onNormSelected() {
  const wahl = form.typ._normWahl
  if (!wahl || wahl === '__frei__') {
    if (wahl !== '__frei__') form.typ.Norm = ''
    form.typ._normHinweis = ''
    return
  }
  const n = normenFuerAktuellenTyp.value.find(x => x.Bezeichnung === wahl)
  if (n) {
    form.typ.Norm = n.Bezeichnung
    if (n.Pruefintervall_Monate) form.typ.Pruefintervall_Monate = n.Pruefintervall_Monate
    if (n.Max_Lebensdauer_Jahre) form.typ.Max_Lebensdauer_Jahre = n.Max_Lebensdauer_Jahre
    if (n.Max_Waeschen)          form.typ.Max_Waeschen          = n.Max_Waeschen
    form.typ._normHinweis = n.Beschreibung || ''
  }
}

export async function saveTyp() {
  if (!form.typ.Bezeichnung?.trim() || !form.typ.Typ?.trim()) {
    showToast('"Bezeichnung" und "Typ/Kategorie" sind Pflichtfelder', 'error'); return
  }
  await load(async () => {
    const { Id } = form.typ
    const oldBez = Id ? (typen.value.find(t => t.Id === Id)?.Bezeichnung || '') : ''
    const payload = {
      Typ:                   form.typ.Typ                  || null,
      Bezeichnung:           form.typ.Bezeichnung          || null,
      Hersteller:            form.typ.Hersteller           || null,
      Norm:                  form.typ.Norm                 || null,
      Max_Lebensdauer_Jahre: form.typ.Max_Lebensdauer_Jahre ? Number(form.typ.Max_Lebensdauer_Jahre) : null,
      Pruefintervall_Monate: form.typ.Pruefintervall_Monate ? Number(form.typ.Pruefintervall_Monate) : null,
      Max_Waeschen:          form.typ.Max_Waeschen          ? Number(form.typ.Max_Waeschen)          : null,
      Beschreibung:          form.typ.Beschreibung          || null,
      Foto:                  form.typ.Foto                  || null,
    }
    if (Id) await patch('Ausruestungstypen', Id, payload)
    else    await post('Ausruestungstypen', payload)
    // Kaskade: Ausrüstungseinträge bei Namensänderung aktualisieren
    if (Id && oldBez && oldBez !== form.typ.Bezeichnung) {
      const affected = ausruestung.value.filter(a => a.Ausruestungstyp === oldBez)
      await Promise.all(affected.map(a => patch('Ausruestungstuecke', a.Id, { Ausruestungstyp: form.typ.Bezeichnung })))
    }
    modal.typForm = false
    showToast('Typ gespeichert')
    logChange('Typen', Id ? 'Bearbeitet' : 'Erstellt', form.typ.Bezeichnung)
    await fetchAll()
  })
}

export async function deleteTyp(t: Ausruestungstyp) {
  const inUse = ausruestung.value.filter(a => a.Ausruestungstyp === t.Bezeichnung).length
  if (inUse) { showToast(`Typ wird von ${inUse} Ausrüstungsstück${inUse > 1 ? 'en' : ''} verwendet`, 'error'); return }
  if (!confirm(`Typ "${t.Bezeichnung}" wirklich löschen?`)) return
  await load(async () => {
    await del('Ausruestungstypen', t.Id)
    showToast('Typ gelöscht')
    logChange('Typen', 'Gelöscht', t.Bezeichnung)
    await fetchAll()
  })
}

// ── Normen CRUD ────────────────────────────────────────────────────────────
export function openNormenForm(n: Partial<Norm> = {}) {
  form.norm = { ...n }
  modal.normenForm = true
}

export async function saveNorm() {
  if (!form.norm.Bezeichnung?.trim()) { showToast('"Bezeichnung" ist ein Pflichtfeld', 'error'); return }
  await load(async () => {
    const { Id } = form.norm
    const payload = {
      Bezeichnung:               form.norm.Bezeichnung               || null,
      Ausruestungstyp_Kategorie: form.norm.Ausruestungstyp_Kategorie || null,
      Pruefintervall_Monate:     form.norm.Pruefintervall_Monate     ? Number(form.norm.Pruefintervall_Monate) : null,
      Max_Lebensdauer_Jahre:     form.norm.Max_Lebensdauer_Jahre     ? Number(form.norm.Max_Lebensdauer_Jahre) : null,
      Max_Waeschen:              form.norm.Max_Waeschen              ? Number(form.norm.Max_Waeschen)          : null,
      Beschreibung:              form.norm.Beschreibung              || null,
    }
    if (Id) await patch('Normen', Id, payload)
    else    await post('Normen', payload)
    modal.normenForm = false
    showToast('Norm gespeichert')
    logChange('Normen', Id ? 'Bearbeitet' : 'Erstellt', form.norm.Bezeichnung)
    await fetchAll()
  })
}

export async function deleteNorm(n: Norm) {
  if (!confirm(`Norm "${n.Bezeichnung}" wirklich löschen?`)) return
  await load(async () => {
    await del('Normen', n.Id)
    showToast('Norm gelöscht')
    logChange('Normen', 'Gelöscht', n.Bezeichnung)
    await fetchAll()
  })
}

// ── Benutzer CRUD ──────────────────────────────────────────────────────────
export function openBenutzerForm(b: Benutzer | null = null) {
  if (b) {
    Object.assign(form.benutzer, { Id: b.Id, Benutzername: b.Benutzername, PIN: '', Rolle: b.Rolle || 'Kleiderwart', Aktiv: b.Aktiv !== false, KameradId: b.KameradId || '' })
  } else {
    Object.assign(form.benutzer, { Id: null, Benutzername: '', PIN: '', Rolle: 'Kleiderwart', Aktiv: true, KameradId: '' })
  }
  modal.benutzerForm = true
}

export async function saveBenutzer() {
  const isEdit = !!form.benutzer.Id
  if (!form.benutzer.Benutzername?.trim()) {
    showToast('Benutzername ist ein Pflichtfeld', 'error'); return
  }
  if (!isEdit && !form.benutzer.PIN?.trim()) {
    showToast('Passwort ist ein Pflichtfeld für neue Benutzer', 'error'); return
  }
  if (form.benutzer.PIN?.trim() && form.benutzer.PIN.trim().length < 6) {
    showToast('Passwort muss mindestens 6 Zeichen haben', 'error'); return
  }
  await load(async () => {
    const payload: Record<string, unknown> = {
      Benutzername: form.benutzer.Benutzername.trim(),
      Rolle:        form.benutzer.Rolle,
      Aktiv:        form.benutzer.Aktiv,
      KameradId:    form.benutzer.KameradId || null,
    }
    if (form.benutzer.PIN?.trim()) {
      payload.PIN = form.benutzer.PIN.trim()
    }
    if (form.benutzer.Id) {
      await patch('Benutzer', form.benutzer.Id, payload)
      const idx = benutzer.value.findIndex(b => b.Id === form.benutzer.Id)
      if (idx >= 0) benutzer.value[idx] = { ...benutzer.value[idx], ...payload }
      logChange('Benutzer', 'Bearbeitet', String(payload.Benutzername))
    } else {
      const created = await post('Benutzer', payload)
      benutzer.value.push(created as unknown as Benutzer)
      logChange('Benutzer', 'Erstellt', String(payload.Benutzername))
    }
    modal.benutzerForm = false
    showToast('Benutzer gespeichert')
  })
}

// ── Passwort selbst ändern ─────────────────────────────────────────────────
export const passwortChangeForm = reactive({ altPasswort: '', neuesPasswort: '', bestaetigung: '', error: '' })

export function openPasswortForm() {
  passwortChangeForm.altPasswort   = ''
  passwortChangeForm.neuesPasswort = ''
  passwortChangeForm.bestaetigung  = ''
  passwortChangeForm.error         = ''
  modal.passwortForm = true
}

export async function savePasswort() {
  passwortChangeForm.error = ''
  if (!passwortChangeForm.altPasswort || !passwortChangeForm.neuesPasswort) {
    passwortChangeForm.error = 'Bitte alle Felder ausfüllen.'; return
  }
  if (passwortChangeForm.neuesPasswort !== passwortChangeForm.bestaetigung) {
    passwortChangeForm.error = 'Passwörter stimmen nicht überein.'; return
  }
  if (passwortChangeForm.neuesPasswort.length < 6) {
    passwortChangeForm.error = 'Passwort muss mindestens 6 Zeichen haben.'; return
  }
  await load(async () => {
    await authRpc('change_password', {
      alt_pin: passwortChangeForm.altPasswort,
      neues_pin: passwortChangeForm.neuesPasswort.trim(),
    })
    modal.passwortForm = false
    showToast('Passwort geändert')
  })
}

export async function deleteBenutzer(b: Benutzer) {
  if (b.Id === currentUser.value?.Id) { showToast('Eigenen Account nicht löschbar', 'error'); return }
  if (!confirm(`Benutzer "${b.Benutzername}" wirklich löschen?`)) return
  await load(async () => {
    await del('Benutzer', b.Id)
    benutzer.value = benutzer.value.filter(u => u.Id !== b.Id)
    logChange('Benutzer', 'Gelöscht', b.Benutzername)
    showToast('Benutzer gelöscht')
  })
}
