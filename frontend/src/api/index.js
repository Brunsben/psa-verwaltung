// ── NocoDB API-Layer ─────────────────────────────────────────────────────────
// Alle HTTP-Aufrufe gehen über diese Funktionen.
// config.js wird zur Laufzeit von nginx bereitgestellt (XC_TOKEN server-seitig injiziert).

const API    = window.CONFIG.api
const TABLES = window.CONFIG.tables
export const T = (name) => TABLES[name] || name

/**
 * Basis-Fetch-Wrapper mit Error-Handling.
 */
export async function api(method, path, body) {
  const headers = { 'Content-Type': 'application/json' }
  if (window.CONFIG?.token) headers['xc-token'] = window.CONFIG.token
  const r = await fetch(path, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  })
  if (!r.ok) {
    const err = await r.json().catch(() => ({}))
    throw new Error(`${r.status}: ${err.message || err.msg || JSON.stringify(err)}`)
  }
  if (r.status === 204) return null
  return r.json()
}

/**
 * Lädt alle Seiten einer Tabelle (NocoDB-Pagination, 100 pro Seite).
 */
export async function getAll(table, query = '') {
  const PAGE_SIZE = 100
  let offset = 0
  let all = []
  while (true) {
    const r = await api('GET', `${API}/${T(table)}?limit=${PAGE_SIZE}&offset=${offset}${query}`)
    const list = r.list || []
    all = all.concat(list)
    if (all.length >= (r.pageInfo?.totalRows ?? list.length) || list.length < PAGE_SIZE) break
    offset += PAGE_SIZE
  }
  return all
}

export const post  = (table, body)       => api('POST',   `${API}/${T(table)}`, body)
export const patch = (table, id, body)   => api('PATCH',  `${API}/${T(table)}/${id}`, body)
export const del   = (table, id)         => api('DELETE', `${API}/${T(table)}/${id}`)

export { API, TABLES }
