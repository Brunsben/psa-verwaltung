-- ─────────────────────────────────────────────────────────────
--  postgres-init.sql – PSA-Verwaltung Schema (fw_psa)
--
--  Legt PSA-spezifische Tabellen an (Ausrüstung, Prüfungen, etc.)
--  Setzt voraus: postgres-common.sql wurde bereits ausgeführt
--     (fw_common Schema, Rollen psa_anon/psa_auth/psa_user).
--
--  Aufruf durch install.sh automatisch.
-- ─────────────────────────────────────────────────────────────

-- ── Schema ────────────────────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS fw_psa;

-- ── Ausrüstungstypen ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_psa."Ausruestungstypen" (
  id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Bezeichnung"            TEXT,
  "Typ"                    TEXT,
  "Pruefintervall_Monate"  INTEGER,
  "Max_Lebensdauer_Jahre"  INTEGER,
  "Max_Waeschen"           INTEGER,
  "Norm"                   TEXT,
  "Foto"                   TEXT
);

-- ── Ausrüstungsstücke ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_psa."Ausruestungstuecke" (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Ausruestungstyp"     TEXT,
  "Seriennummer"        TEXT,
  "Kamerad_Id"          UUID REFERENCES fw_common.members(id) ON DELETE SET NULL,
  "Status"              TEXT DEFAULT 'Lager',
  "Kaufdatum"           DATE,
  "Herstellungsdatum"   DATE,
  "Naechste_Pruefung"   DATE,
  "Letzte_Pruefung"     DATE,
  "Lebensende_Datum"    DATE,
  "QR_Code"             TEXT,
  "Waesche_Anzahl"      INTEGER DEFAULT 0,
  "Groesse"             TEXT,
  "Notizen"             TEXT
);

-- ── Ausgaben (Zuweisungen) ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_psa."Ausgaben" (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Ausruestungstueck_Id" UUID REFERENCES fw_psa."Ausruestungstuecke"(id) ON DELETE CASCADE,
  "Ausruestungstyp"      TEXT,
  "Kamerad_Id"           UUID REFERENCES fw_common.members(id) ON DELETE SET NULL,
  "Ausgabedatum"         DATE,
  "Rueckgabedatum"       DATE,
  "Notizen"              TEXT
);

-- ── Prüfungen ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_psa."Pruefungen" (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Ausruestungstueck_Id" UUID REFERENCES fw_psa."Ausruestungstuecke"(id) ON DELETE CASCADE,
  "Ausruestungstyp"      TEXT,
  "Kamerad_Id"           UUID REFERENCES fw_common.members(id) ON DELETE SET NULL,
  "Datum"                DATE,
  "Ergebnis"             TEXT,
  "Pruefer"              TEXT,
  "Naechste_Pruefung"    DATE,
  "Notizen"              TEXT,
  "Foto"                 TEXT
);

-- ── Wäsche ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_psa."Waesche" (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Ausruestungstueck_Id" UUID REFERENCES fw_psa."Ausruestungstuecke"(id) ON DELETE CASCADE,
  "Ausruestungstyp"      TEXT,
  "Kamerad_Id"           UUID REFERENCES fw_common.members(id) ON DELETE SET NULL,
  "Datum"                DATE,
  "Notizen"              TEXT
);

-- ── Normen ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_psa."Normen" (
  id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Bezeichnung"               TEXT,
  "Ausruestungstyp_Kategorie" TEXT,
  "Normbezeichnung"           TEXT,
  "URL"                       TEXT,
  "Pruefintervall_Monate"     INTEGER,
  "Max_Lebensdauer_Jahre"     INTEGER,
  "Max_Waeschen"              INTEGER,
  "Beschreibung"              TEXT
);

-- ── Schadensdokumentation ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_psa."Schadensdokumentation" (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Ausruestungstueck_Id" UUID REFERENCES fw_psa."Ausruestungstuecke"(id) ON DELETE CASCADE,
  "Datum"                DATE NOT NULL DEFAULT CURRENT_DATE,
  "Beschreibung"         TEXT,
  "Foto"                 TEXT NOT NULL,
  "Erstellt_Von"         TEXT,
  "Erstellt_Am"          TIMESTAMPTZ DEFAULT now(),
  "Ausruestungstyp"      TEXT,
  "Seriennummer"         TEXT
);

-- ── Changelog ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_psa."Changelog" (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Tabelle"   TEXT,
  "Aktion"    TEXT,
  "Details"   TEXT,
  "Benutzer"  TEXT,
  "Zeitpunkt" TIMESTAMPTZ DEFAULT now()
);

-- ── Schema-Grants ─────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA fw_psa TO psa_anon;
GRANT USAGE ON SCHEMA fw_psa TO psa_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fw_psa TO psa_user;
