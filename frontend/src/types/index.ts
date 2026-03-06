// ── Domain-Typen (PSA-Verwaltung) ──────────────────────────────────────────
// Datenbankentitäten mit PostgreSQL-Spaltennamen.
// PK: `id` (UUID als string) → wird in getAll() auf `Id` gemappt.

export interface Kamerad {
  id: string
  Id: string
  Vorname: string | null
  Name: string | null
  Dienstgrad: string | null
  Email: string | null
  Jacke_Groesse: string | null
  Hose_Groesse: string | null
  Stiefel_Groesse: string | null
  Handschuh_Groesse: string | null
  Hemd_Groesse: string | null
  Poloshirt_Groesse: string | null
  Fleece_Groesse: string | null
  Aktiv: boolean
}

export interface Ausruestungstyp {
  id: string
  Id: string
  Bezeichnung: string | null
  Typ: string | null
  Pruefintervall_Monate: number | null
  Max_Lebensdauer_Jahre: number | null
  Max_Waeschen: number | null
  Norm: string | null
  Foto: string | null
}

export interface Ausruestungstueck {
  id: string
  Id: string
  Ausruestungstyp: string | null
  Seriennummer: string | null
  Kamerad_Id: string | null
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
  id: string
  Id: string
  Ausruestungstueck_Id: string | null
  Ausruestungstyp: string | null
  Kamerad_Id: string | null
  Ausgabedatum: string | null
  Rueckgabedatum: string | null
  Notizen: string | null
}

export interface Pruefung {
  id: string
  Id: string
  Ausruestungstueck_Id: string | null
  Ausruestungstyp: string | null
  Kamerad_Id: string | null
  Datum: string | null
  Ergebnis: string | null
  Pruefer: string | null
  Naechste_Pruefung: string | null
  Notizen: string | null
  Foto: string | null
}

export interface Schadensdokumentation {
  id: string
  Id: string
  Ausruestungstueck_Id: string | null
  Datum: string | null
  Beschreibung: string | null
  Foto: string | null
  Erstellt_Von: string | null
  Erstellt_Am: string | null
  Ausruestungstyp: string | null
  Seriennummer: string | null
}

export interface Waesche {
  id: string
  Id: string
  Ausruestungstueck_Id: string | null
  Ausruestungstyp: string | null
  Kamerad_Id: string | null
  Datum: string | null
  Notizen: string | null
}

export interface Norm {
  id: string
  Id: string
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
  id: string
  Id: string
  Benutzername: string
  PIN: string
  Rolle: 'Admin' | 'Kleiderwart' | 'User'
  Aktiv: boolean
  KameradId: string | null
}

export interface ChangelogEntry {
  id: string
  Id: string
  Tabelle: string | null
  Aktion: string | null
  Details: string | null
  Benutzer: string | null
  Zeitpunkt: string | null
}

// Benutzer-Objekt aus dem JWT-Token (kein PIN, kein Aktiv)
export interface AppUser {
  Id: string
  Benutzername: string
  Rolle: 'Admin' | 'Kleiderwart' | 'User'
  KameradId: string | null
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
  ausruestungId: string
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
