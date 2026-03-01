// ── Validierungs-Utilities ───────────────────────────────────────────────────

/**
 * Prüft ob alle Pflichtfelder ausgefüllt sind.
 * @param {Array<[value, label]>} pairs - Wertepaare [wert, feldname]
 * @param {Function} showToast - Toast-Funktion für Fehlermeldung
 * @returns {boolean} true wenn alle Felder gültig
 */
export function validateFields(pairs, showToast) {
  for (const [val, label] of pairs) {
    if (!val && val !== 0) {
      showToast(`Pflichtfeld fehlt: ${label}`, 'error')
      return false
    }
  }
  return true
}
