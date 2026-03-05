-- PSA-Verwaltung: Migration – Fotos
-- Ausführen mit:
--   docker exec -i psa_postgres psql -U nocodb nocodb < setup/migration-fotos.sql

-- 1. Beispielfoto pro Ausrüstungstyp
ALTER TABLE pxicv3djlauluse."Ausruestungstypen"
  ADD COLUMN IF NOT EXISTS "Foto" TEXT;

-- 2. Schadensdokumentation (mehrere Fotos pro Ausrüstungsstück)
CREATE TABLE IF NOT EXISTS pxicv3djlauluse."Schadensdokumentation" (
  id                     SERIAL PRIMARY KEY,
  "Ausruestungstueck_Id" INTEGER,
  "Datum"                DATE NOT NULL DEFAULT CURRENT_DATE,
  "Beschreibung"         TEXT,
  "Foto"                 TEXT NOT NULL,
  "Erstellt_Von"         TEXT,
  "Erstellt_Am"          TIMESTAMPTZ DEFAULT NOW(),
  "Ausruestungstyp"      TEXT,
  "Seriennummer"         TEXT
);

GRANT SELECT, INSERT, UPDATE, DELETE
  ON pxicv3djlauluse."Schadensdokumentation" TO psa_anon;
GRANT USAGE, SELECT
  ON SEQUENCE pxicv3djlauluse."Schadensdokumentation_id_seq" TO psa_anon;
GRANT SELECT, INSERT, UPDATE, DELETE
  ON pxicv3djlauluse."Schadensdokumentation" TO psa_auth;
GRANT USAGE, SELECT
  ON SEQUENCE pxicv3djlauluse."Schadensdokumentation_id_seq" TO psa_auth;
