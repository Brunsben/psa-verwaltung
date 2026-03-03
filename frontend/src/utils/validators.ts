// ── Validierungs-Utilities ───────────────────────────────────────────────────

/**
 * Prüft ob alle Pflichtfelder ausgefüllt sind.
 * @param pairs - Wertepaare [wert, feldname]
 * @param showToast - Toast-Funktion für Fehlermeldung
 * @returns true wenn alle Felder gültig
 */
export function validateFields(
  pairs: [unknown, string][],
  showToast: (msg: string, type?: string) => void,
): boolean {
  for (const [val, label] of pairs) {
    if (!val && val !== 0) {
      showToast(`Pflichtfeld fehlt: ${label}`, 'error')
      return false
    }
  }
  return true
}
