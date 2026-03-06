-- PSA-Verwaltung: Migration – Fotos (Legacy)
-- HINWEIS: Für Neuinstallationen sind diese Tabellen bereits in postgres-init.sql.
-- Dieses Skript nur für bestehende Installationen vor fw_psa-Migration.
--
-- Ausführen mit:
--   docker exec -i psa_postgres psql -U nocodb nocodb < setup/migration-fotos.sql

-- 1. Beispielfoto pro Ausrüstungstyp
ALTER TABLE fw_psa."Ausruestungstypen"
  ADD COLUMN IF NOT EXISTS "Foto" TEXT;

-- 2. Schadensdokumentation (bereits in postgres-init.sql für Neuinstallationen)
-- Nur für Alt-Migrationen:
CREATE TABLE IF NOT EXISTS fw_psa."Schadensdokumentation" (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Ausruestungstueck_Id" UUID REFERENCES fw_psa."Ausruestungstuecke"(id),
  "Datum"                DATE NOT NULL DEFAULT CURRENT_DATE,
  "Beschreibung"         TEXT,
  "Foto"                 TEXT NOT NULL,
  "Erstellt_Von"         TEXT,
  "Erstellt_Am"          TIMESTAMPTZ DEFAULT NOW(),
  "Ausruestungstyp"      TEXT,
  "Seriennummer"         TEXT
);

GRANT SELECT, INSERT, UPDATE, DELETE
  ON fw_psa."Schadensdokumentation" TO psa_user;
