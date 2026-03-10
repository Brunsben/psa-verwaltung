// ── Domain-Typen (PSA-Verwaltung) ──────────────────────────────────────────
// Alle Datenbankentitäten mit PostgreSQL-Spaltennamen.
// PK: `id` (PostgreSQL) → wird in getAll() auf `Id` gemappt.

export interface Kamerad {
  id: number
  Id: number
  Vorname: string | null
  Name: string | null
  Dienstgrad: string | null
  Email: string | null
  Personalnummer: string | null
  KartenID: string | null
  Jacke_Groesse: string | null
  Hose_Groesse: string | null
  Stiefel_Groesse: string | number | null
  Handschuh_Groesse: string | null
  Hemd_Groesse: string | null
  Poloshirt_Groesse: string | null
  Fleece_Groesse: string | null
  Aktiv: boolean
}

export interface Ausruestungstyp {
  id: number
  Id: number
  Bezeichnung: string | null
  Typ: string | null
  Pruefintervall_Monate: number | null
  Max_Lebensdauer_Jahre: number | null
  Max_Waeschen: number | null
  Norm: string | null
  Foto: string | null
}

export interface Ausruestungstueck {
  id: number
  Id: number
  Ausruestungstyp: string | null
  Seriennummer: string | null
  Kamerad: string | null
  Status: string | null
  Kaufdatum: string | null
  Herstellungsdatum: string | null
  Naechste_Pruefung: string | null
  Letzte_Pruefung: string | null
  Lebensende_Datum: string | null
  QR_Code: string | null
  Waesche_Anzahl: number | null
  Groesse: string | null
  Notizen: string | null
}

export interface Ausgabe {
  id: number
  Id: number
  Ausruestungstueck_Id: number | null
  Ausruestungstyp: string | null
  Kamerad: string | null
  Ausgabedatum: string | null
  Rueckgabedatum: string | null
  Notizen: string | null
}

export interface Pruefung {
  id: number
  Id: number
  Ausruestungstueck_Id: number | null
  Ausruestungstyp: string | null
  Kamerad: string | null
  Datum: string | null
  Ergebnis: string | null
  Pruefer: string | null
  Naechste_Pruefung: string | null
  Notizen: string | null
  Foto: string | null
}

export interface Schadensdokumentation {
  id: number
  Id: number
  Ausruestungstueck_Id: number | null
  Datum: string | null
  Beschreibung: string | null
  Foto: string | null
  Erstellt_Von: string | null
  Erstellt_Am: string | null
  Ausruestungstyp: string | null
  Seriennummer: string | null
}

export interface Waesche {
  id: number
  Id: number
  Ausruestungstueck_Id: number | null
  Ausruestungstyp: string | null
  Kamerad: string | null
  Datum: string | null
  Notizen: string | null
}

export interface Norm {
  id: number
  Id: number
  Bezeichnung: string | null
  Ausruestungstyp_Kategorie: string | null
  Normbezeichnung: string | null
  URL: string | null
  Pruefintervall_Monate: number | null
  Max_Lebensdauer_Jahre: number | null
  Max_Waeschen: number | null
  Beschreibung: string | null
}

export interface Benutzer {
  id: number
  Id: number
  Benutzername: string
  PIN: string
  Rolle: 'Admin' | 'Kleiderwart' | 'User'
  Aktiv: boolean
  KameradId: number | null
}

export interface ChangelogEntry {
  id: number
  Id: number
  Tabelle: string | null
  Aktion: string | null
  Details: string | null
  Benutzer: string | null
  Zeitpunkt: string | null
}

// Benutzer-Objekt aus dem JWT-Token (kein PIN, kein Aktiv)
export interface AppUser {
  Id: number
  Benutzername: string
  Rolle: 'Admin' | 'Kleiderwart' | 'User'
  KameradId: number | null
}

// Ergebnis des /rpc/authenticate und /rpc/create_admin Aufrufs
export interface AuthResult {
  token: string
  user: AppUser
}

// Größen-Kategorie-Mapping (Typ → Kamerad-Feld)
export interface GroesseKatEntry {
  label: string
  field: keyof Pick<Kamerad,
    'Jacke_Groesse' | 'Hose_Groesse' | 'Stiefel_Groesse' |
    'Handschuh_Groesse' | 'Hemd_Groesse' | 'Poloshirt_Groesse' | 'Fleece_Groesse'>
}

// Warnung (generiert durch warnungen-Computed)
export interface Warnung {
  id: string
  prio: 'rot' | 'orange' | 'gelb'
  ausruestungId: number
  titel: string
  detail: string
}

// CSV-Import Zeile (Kameraden)
export interface CsvRow extends Record<string, string | boolean> {
  _Vorname: string
  _Name: string
  _error: string
  _duplicate: boolean
}

// CSV-Import Zeile (Ausrüstung)
export interface AusruestungCsvRow extends Record<string, string | boolean> {
  _Typ: string
  _error: string
  _duplicate: boolean
}
