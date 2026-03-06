// ── PostgREST API-Layer ────────────────────────────────────────────────────
// Ersetzt NocoDB. PostgREST liefert direkt aus PostgreSQL.
// JWT-Authentifizierung: Token via /rpc/authenticate, gesendet als Bearer-Header.
//
// PK-Mapping: PostgreSQL speichert "id" (lowercase), store.js erwartet "Id".
// getAll() und post() mappen automatisch: { ...r, Id: r.id }

import type { AuthResult } from '../types/index.js'

const API = window.CONFIG.api  // '/api'

// Kompatibilitäts-Exports – store.js prüft TABLES.Benutzer etc.
export const TABLES = {
  members: true, Ausruestungstypen: true, Ausruestungstuecke: true,
  Ausgaben: true, Pruefungen: true, Waesche: true, Normen: true,
  accounts: true, Changelog: true,
} as const

export const T = (name: string): string => name

// ── JWT-Token-Verwaltung ──────────────────────────────────────────────────
export const getJwt   = (): string | null => localStorage.getItem('psa_jwt') || localStorage.getItem('fw_jwt')
export const setJwt   = (token: string): void => { localStorage.setItem('psa_jwt', token) }
export const clearJwt = (): void => { localStorage.removeItem('psa_jwt') }

function authHeader(): Record<string, string> {
  const token = getJwt()
  return token ? { Authorization: `Bearer ${token}` } : {}
}

/**
 * Basis-Fetch-Wrapper mit Error-Handling und JWT-Injection.
 * Bei 401 (abgelaufenes Token): clearJwt + psa:unauthorized-Event.
 */
export async function api(
  method: string,
  path: string,
  body?: unknown,
  extraHeaders: Record<string, string> = {},
): Promise<unknown> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...authHeader(),
    ...extraHeaders,
  }
  const r = await fetch(path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  })
  if (r.status === 401) {
    clearJwt()
    window.dispatchEvent(new CustomEvent('psa:unauthorized'))
    throw new Error('401: Sitzung abgelaufen – bitte neu anmelden')
  }
  if (!r.ok) {
    const err = await r.json().catch(() => ({})) as { message?: string; hint?: string }
    throw new Error(`${r.status}: ${err.message || err.hint || JSON.stringify(err)}`)
  }
  if (r.status === 204) return null
  return r.json()
}

/**
 * Ruft eine PostgREST-RPC-Funktion auf (ohne Auth-Header, für Login/First-Run).
 */
export async function rpc(name: string, params: Record<string, unknown> = {}): Promise<unknown> {
  const r = await fetch(`${API}/rpc/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(params),
  })
  if (!r.ok) {
    const err = await r.json().catch(() => ({})) as { message?: string; hint?: string }
    throw new Error(err.message || err.hint || `${r.status}`)
  }
  if (r.status === 204) return null
  return r.json()
}

/**
 * Ruft eine PostgREST-RPC-Funktion auf (mit Auth-Header, für authentifizierte Aktionen).
 */
export async function authRpc(name: string, params: Record<string, unknown> = {}): Promise<unknown> {
  return api('POST', `${API}/rpc/${name}`, params)
}

// ── Auth-Funktionen (via PostgreSQL-Funktionen) ───────────────────────────

/** Login: gibt { token, user } zurück */
export async function authenticate(benutzername: string, pin: string): Promise<AuthResult> {
  return rpc('authenticate', { benutzername, pin }) as Promise<AuthResult>
}

/** Prüft ob bereits ein Admin-Account existiert */
export async function isInitialized(): Promise<boolean> {
  return rpc('is_initialized', {}) as Promise<boolean>
}

/** Ersten Admin anlegen: gibt { token, user } zurück */
export async function createAdmin(benutzername: string, pin: string): Promise<AuthResult> {
  return rpc('create_admin', { benutzername, pin }) as Promise<AuthResult>
}

// ── Datenzugriff ──────────────────────────────────────────────────────────

/**
 * Lädt alle Datensätze einer Tabelle (limit 10000, sortiert nach id).
 * Mappt id → Id für Kompatibilität mit store.
 */
export async function getAll<T extends Record<string, unknown> = Record<string, unknown>>(
  table: string,
): Promise<(T & { Id: string })[]> {
  const records = await api('GET', `${API}/${table}?limit=10000&order=id.asc`) as (T & { id: string })[]
  return records.map(r => ({ ...r, Id: r.id }))
}

/**
 * Legt einen neuen Datensatz an.
 * Prefer: return=representation → PostgREST gibt angelegten Datensatz zurück.
 * Mappt id → Id.
 */
export const post = async (
  table: string,
  body: Record<string, unknown>,
): Promise<(Record<string, unknown> & { Id: string }) | null> => {
  const result = await api('POST', `${API}/${table}`, body, {
    'Prefer': 'return=representation',
  }) as (Record<string, unknown> & { id: string })[] | null
  const record = Array.isArray(result) ? result[0] : result
  return record ? { ...record, Id: record.id } : null
}

/**
 * Aktualisiert einen Datensatz (per id-Filter statt Pfad-Segment).
 */
export const patch = (table: string, id: string, body: Record<string, unknown>): Promise<unknown> =>
  api('PATCH', `${API}/${table}?id=eq.${id}`, body, {
    'Prefer': 'return=representation',
  })

/**
 * Löscht einen Datensatz (per id-Filter).
 */
export const del = (table: string, id: string): Promise<unknown> =>
  api('DELETE', `${API}/${table}?id=eq.${id}`)

export { API }
