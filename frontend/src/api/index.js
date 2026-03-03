// ── PostgREST API-Layer ────────────────────────────────────────────────────
// Ersetzt NocoDB. PostgREST liefert direkt aus PostgreSQL.
// JWT-Authentifizierung: Token via /rpc/authenticate, gesendet als Bearer-Header.
//
// PK-Mapping: PostgreSQL speichert "id" (lowercase), store.js erwartet "Id".
// getAll() und post() mappen automatisch: { ...r, Id: r.id }

const API = window.CONFIG.api  // '/api'

// Kompatibilitäts-Exports – store.js prüft TABLES.Benutzer etc.
export const TABLES = {
  Kameraden: true, Ausruestungstypen: true, Ausruestungstuecke: true,
  Ausgaben: true, Pruefungen: true, Waesche: true, Normen: true,
  Benutzer: true, Changelog: true,
}
export const T = name => name  // Tabellenname = PostgREST-Endpunkt

// ── JWT-Token-Verwaltung ──────────────────────────────────────────────────
export const getJwt   = ()      => localStorage.getItem('psa_jwt')
export const setJwt   = token   => localStorage.setItem('psa_jwt', token)
export const clearJwt = ()      => localStorage.removeItem('psa_jwt')

function authHeader() {
  const token = getJwt()
  return token ? { Authorization: `Bearer ${token}` } : {}
}

/**
 * Basis-Fetch-Wrapper mit Error-Handling und JWT-Injection.
 * Bei 401 (abgelaufenes Token): clearJwt + psa:unauthorized-Event.
 */
export async function api(method, path, body, extraHeaders = {}) {
  const headers = {
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
    const err = await r.json().catch(() => ({}))
    throw new Error(`${r.status}: ${err.message || err.hint || JSON.stringify(err)}`)
  }
  if (r.status === 204) return null
  return r.json()
}

/**
 * Ruft eine PostgREST-RPC-Funktion auf (ohne Auth-Header, für Login/First-Run).
 */
export async function rpc(name, params = {}) {
  const r = await fetch(`${API}/rpc/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(params),
  })
  if (!r.ok) {
    const err = await r.json().catch(() => ({}))
    throw new Error(err.message || err.hint || `${r.status}`)
  }
  if (r.status === 204) return null
  return r.json()
}

// ── Auth-Funktionen (via PostgreSQL-Funktionen) ───────────────────────────

/** Login: gibt { token, user } zurück */
export async function authenticate(benutzername, pin) {
  return rpc('authenticate', { benutzername, pin })
}

/** Prüft ob bereits ein Admin-Account existiert */
export async function isInitialized() {
  return rpc('is_initialized', {})
}

/** Ersten Admin anlegen: gibt { token, user } zurück */
export async function createAdmin(benutzername, pin) {
  return rpc('create_admin', { benutzername, pin })
}

// ── Datenzugriff ──────────────────────────────────────────────────────────

/**
 * Lädt alle Datensätze einer Tabelle (limit 10000, sortiert nach id).
 * Mappt id → Id für Kompatibilität mit store.js.
 */
export async function getAll(table) {
  const records = await api('GET', `${API}/${table}?limit=10000&order=id.asc`)
  return records.map(r => ({ ...r, Id: r.id }))
}

/**
 * Legt einen neuen Datensatz an.
 * Prefer: return=representation → PostgREST gibt angelegten Datensatz zurück.
 * Mappt id → Id.
 */
export const post = async (table, body) => {
  const result = await api('POST', `${API}/${table}`, body, {
    'Prefer': 'return=representation',
  })
  const record = Array.isArray(result) ? result[0] : result
  return record ? { ...record, Id: record.id } : record
}

/**
 * Aktualisiert einen Datensatz (per id-Filter statt Pfad-Segment).
 */
export const patch = (table, id, body) =>
  api('PATCH', `${API}/${table}?id=eq.${id}`, body, {
    'Prefer': 'return=representation',
  })

/**
 * Löscht einen Datensatz (per id-Filter).
 */
export const del = (table, id) =>
  api('DELETE', `${API}/${table}?id=eq.${id}`)

export { API }
