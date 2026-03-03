// ── Formatter-Utilities ──────────────────────────────────────────────────────
import type { Ausruestungstyp } from '../types/index.js'

export function todayStr(): string {
  return new Date().toISOString().slice(0, 10)
}

export function fmtDate(d: string | null | undefined): string {
  if (!d) return '–'
  return new Date(d).toLocaleDateString('de-DE')
}

export interface DateRelResult {
  label: string
  sub: string
  cls: string
}

/**
 * Gibt ein Objekt { label, sub, cls } für Datumsanzeigen zurück, oder null.
 * Genutzt z.B. für Prüfungs- und Lebensende-Datum in der Ausrüstungstabelle.
 */
export function fmtDateRel(d: string | null | undefined): DateRelResult | null {
  if (!d) return null
  const today    = new Date()
  const date     = new Date(d)
  const diffDays = Math.round((date.getTime() - today.getTime()) / 86400000)
  if (diffDays < 0) {
    const abs = Math.abs(diffDays)
    return { label: 'Überfällig', sub: abs === 1 ? '1 Tag' : `${abs} Tage`, cls: 'text-red-600 dark:text-red-400' }
  }
  if (diffDays === 0) return { label: 'Heute', sub: 'fällig', cls: 'text-red-600 dark:text-red-400' }
  if (diffDays <= 30) return { label: `${diffDays} Tage`, sub: fmtDate(d), cls: 'text-orange-500 dark:text-orange-400' }
  const months = Math.round(diffDays / 30.5)
  if (months < 24)   return { label: `${months} Mon.`, sub: fmtDate(d), cls: diffDays <= 180 ? 'text-yellow-600 dark:text-yellow-400' : 'text-gray-600 dark:text-gray-300' }
  const years  = Math.round(diffDays / 365)
  return { label: `${years} J.`, sub: fmtDate(d), cls: 'text-gray-500 dark:text-gray-400' }
}

export function datePriority(d: string | null | undefined): string {
  if (!d) return ''
  const diff = Math.ceil((new Date(d).getTime() - new Date().getTime()) / 86400000)
  if (diff < 0)    return 'text-red-600 dark:text-red-400 font-semibold'
  if (diff <= 30)  return 'text-orange-500 dark:text-orange-400 font-semibold'
  if (diff <= 180) return 'text-yellow-600 dark:text-yellow-400'
  return ''
}

export function statusBadge(s: string): string {
  const map: Record<string, string> = {
    'Lager':        'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-300',
    'Ausgegeben':   'bg-blue-100 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300',
    'Wäsche':       'bg-yellow-100 dark:bg-yellow-900/40 text-yellow-700 dark:text-yellow-300',
    'Prüfung':      'bg-orange-100 dark:bg-orange-900/40 text-orange-700 dark:text-orange-300',
    'Defekt':       'bg-red-100 dark:bg-red-900/40 text-red-700 dark:text-red-300',
    'Ausgemustert': 'bg-gray-200 dark:bg-gray-600 text-gray-500 dark:text-gray-400 line-through',
  }
  return map[s] || 'bg-gray-100 text-gray-500'
}

export function typLabel(bezeichnung: string | null | undefined, typen: Ausruestungstyp[]): string {
  const typ = typen.find(t => t.Bezeichnung === bezeichnung)
  if (!typ) return bezeichnung || '–'
  return typ.Typ ? `${typ.Typ} · ${bezeichnung}` : bezeichnung || '–'
}
