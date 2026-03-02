// ── PostgREST API-Layer ───────────────────────────────────────────────────────
// Ersetzt NocoDB. PostgREST liefert direkt aus PostgreSQL.
// Schema: pxicv3djlauluse (NocoDB-Schema-Name, bleibt unverändert).
// Kein xc-token mehr nötig – nginx schützt den Endpunkt.
//
// PK-Mapping: PostgreSQL speichert "id" (lowercase), store.js erwartet "Id" (Großbuchstabe).
// getAll() und post() mappen automatisch: { ...r, Id: r.id }

const API = window.CONFIG.api  // '/api'

// Kompatibilitäts-Exports – store.js prüft TABLES.Benutzer etc.
export const TABLES = {
  Kameraden: true, Ausruestungstypen: true, Ausruestungstuecke: true,
  Ausgaben: true, Pruefungen: true, Waesche: true, Normen: true,
  Benutzer: true, Changelog: true,
}
export const T = name => name  // Tabellenname = PostgREST-Endpunkt

/**
 * Basis-Fetch-Wrapper mit Error-Handling.
 */
export async function api(method, path, body, extraHeaders = {}) {
  const headers = { 'Content-Type': 'application/json', ...extraHeaders }
  const r = await fetch(path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  })
  if (!r.ok) {
    const err = await r.json().catch(() => ({}))
    throw new Error(`${r.status}: ${err.message || err.hint || JSON.stringify(err)}`)
  }
  if (r.status === 204) return null
  return r.json()
}

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
