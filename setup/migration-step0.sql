-- ─────────────────────────────────────────────────────────────
--  migration-step0.sql – Produktions-Migration
--
--  Migriert eine bestehende PSA-Installation (NocoDB-Altlast):
--    1. Erstellt fw_common Schema + Tabellen
--    2. Migriert Kameraden → fw_common.members (UUID)
--    3. Migriert Benutzer → fw_common.accounts (UUID)
--    4. Benennt Schema pxicv3djlauluse → fw_psa um
--    5. Fügt UUID-PKs + FK-Spalten (Kamerad_Id) zu PSA-Tabellen hinzu
--    6. Befüllt FKs basierend auf bestehenden String-Referenzen
--    7. Entfernt alte String-Spalten
--
--  WICHTIG: Vor Ausführung BACKUP machen!
--    ./backup.sh
--
--  Ausführen:
--    docker exec -i nocodb_postgres psql -U nocodb -d nocodb \
--      -f /dev/stdin < setup/migration-step0.sql
--
--  Anschließend:
--    docker compose restart postgrest
-- ─────────────────────────────────────────────────────────────

BEGIN;

-- ══════════════════════════════════════════════════════════════
--  1. VORBEREITUNGEN
-- ══════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ══════════════════════════════════════════════════════════════
--  2. fw_common SCHEMA + TABELLEN
-- ══════════════════════════════════════════════════════════════

CREATE SCHEMA IF NOT EXISTS fw_common;

CREATE TABLE IF NOT EXISTS fw_common.members (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Vorname"           TEXT,
  "Name"              TEXT,
  "Dienstgrad"        TEXT,
  "Email"             TEXT,
  "Jacke_Groesse"     TEXT,
  "Hose_Groesse"      TEXT,
  "Stiefel_Groesse"   TEXT,
  "Handschuh_Groesse" TEXT,
  "Hemd_Groesse"      TEXT,
  "Poloshirt_Groesse" TEXT,
  "Fleece_Groesse"    TEXT,
  "Aktiv"             BOOLEAN NOT NULL DEFAULT true,
  created_at          TIMESTAMPTZ DEFAULT now(),
  updated_at          TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fw_common.accounts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "Benutzername"  TEXT UNIQUE NOT NULL,
  "PIN"           TEXT NOT NULL,
  "Rolle"         TEXT NOT NULL DEFAULT 'User'
                    CHECK ("Rolle" IN ('Admin', 'Kleiderwart', 'User')),
  "Aktiv"         BOOLEAN NOT NULL DEFAULT true,
  "KameradId"     UUID REFERENCES fw_common.members(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS fw_common.login_attempts (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  benutzername   TEXT NOT NULL,
  zeitpunkt      TIMESTAMPTZ NOT NULL DEFAULT now(),
  erfolgreich    BOOLEAN NOT NULL DEFAULT false
);

-- ══════════════════════════════════════════════════════════════
--  3. DATEN MIGRIEREN: Kameraden → fw_common.members
-- ══════════════════════════════════════════════════════════════

-- Temporäre Mapping-Tabelle: alte Integer-ID → neue UUID
CREATE TEMP TABLE _member_map (
  old_id INTEGER PRIMARY KEY,
  new_id UUID NOT NULL
);

INSERT INTO fw_common.members (
  id, "Vorname", "Name", "Dienstgrad", "Email",
  "Jacke_Groesse", "Hose_Groesse", "Stiefel_Groesse",
  "Handschuh_Groesse", "Hemd_Groesse", "Poloshirt_Groesse",
  "Fleece_Groesse", "Aktiv"
)
SELECT
  gen_random_uuid(), "Vorname", "Name", "Dienstgrad", "Email",
  "Jacke_Groesse", "Hose_Groesse", CAST("Stiefel_Groesse" AS TEXT),
  "Handschuh_Groesse", "Hemd_Groesse", "Poloshirt_Groesse",
  "Fleece_Groesse", COALESCE("Aktiv", true)
FROM pxicv3djlauluse."Kameraden";

-- Mapping aufbauen
INSERT INTO _member_map (old_id, new_id)
SELECT k.id, m.id
  FROM pxicv3djlauluse."Kameraden" k
  JOIN fw_common.members m
    ON COALESCE(k."Vorname",'') = COALESCE(m."Vorname",'')
   AND COALESCE(k."Name",'')    = COALESCE(m."Name",'');

-- Auch Name-String → UUID Mapping für FK-Migration
CREATE TEMP TABLE _name_to_uuid (
  full_name TEXT,
  member_id UUID
);
INSERT INTO _name_to_uuid (full_name, member_id)
SELECT COALESCE(k."Vorname",'') || ' ' || COALESCE(k."Name",''), mm.new_id
  FROM pxicv3djlauluse."Kameraden" k
  JOIN _member_map mm ON mm.old_id = k.id;

-- ══════════════════════════════════════════════════════════════
--  4. DATEN MIGRIEREN: Benutzer → fw_common.accounts
-- ══════════════════════════════════════════════════════════════

CREATE TEMP TABLE _account_map (
  old_id INTEGER PRIMARY KEY,
  new_id UUID NOT NULL
);

INSERT INTO fw_common.accounts (
  id, "Benutzername", "PIN", "Rolle", "Aktiv", "KameradId"
)
SELECT
  gen_random_uuid(),
  b."Benutzername",
  b."PIN",
  b."Rolle",
  COALESCE(b."Aktiv", true),
  mm.new_id  -- KameradId: alte Integer-ID → neue Member-UUID
FROM pxicv3djlauluse."Benutzer" b
LEFT JOIN _member_map mm ON mm.old_id = CAST(b."KameradId" AS INTEGER);

INSERT INTO _account_map (old_id, new_id)
SELECT b.id, a.id
  FROM pxicv3djlauluse."Benutzer" b
  JOIN fw_common.accounts a ON a."Benutzername" = b."Benutzername";

-- Login-Attempts migrieren
INSERT INTO fw_common.login_attempts (benutzername, zeitpunkt, erfolgreich)
SELECT benutzername, zeitpunkt, erfolgreich
  FROM pxicv3djlauluse.login_attempts;

-- ══════════════════════════════════════════════════════════════
--  5. SCHEMA UMBENENNEN
-- ══════════════════════════════════════════════════════════════

ALTER SCHEMA pxicv3djlauluse RENAME TO fw_psa;

-- ══════════════════════════════════════════════════════════════
--  6. PSA-TABELLEN: UUID-PKs + FK-Spalten hinzufügen
-- ══════════════════════════════════════════════════════════════

-- Ausrüstungstypen: Integer-ID → UUID
ALTER TABLE fw_psa."Ausruestungstypen"
  ADD COLUMN IF NOT EXISTS new_id UUID DEFAULT gen_random_uuid();
UPDATE fw_psa."Ausruestungstypen" SET new_id = gen_random_uuid() WHERE new_id IS NULL;

-- Ausrüstungsstücke: UUID-PK + Kamerad_Id FK
ALTER TABLE fw_psa."Ausruestungstuecke"
  ADD COLUMN IF NOT EXISTS new_id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS "Kamerad_Id" UUID;
UPDATE fw_psa."Ausruestungstuecke" SET new_id = gen_random_uuid() WHERE new_id IS NULL;

-- FK befüllen: "Kamerad" (String) → Kamerad_Id (UUID)
UPDATE fw_psa."Ausruestungstuecke" a
  SET "Kamerad_Id" = n.member_id
  FROM _name_to_uuid n
  WHERE a."Kamerad" = n.full_name;

-- Ausgaben: UUID-PK + Kamerad_Id FK
ALTER TABLE fw_psa."Ausgaben"
  ADD COLUMN IF NOT EXISTS new_id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS "Kamerad_Id" UUID,
  ADD COLUMN IF NOT EXISTS "Ausruestungstueck_New_Id" UUID;
UPDATE fw_psa."Ausgaben" SET new_id = gen_random_uuid() WHERE new_id IS NULL;

UPDATE fw_psa."Ausgaben" a
  SET "Kamerad_Id" = n.member_id
  FROM _name_to_uuid n
  WHERE a."Kamerad" = n.full_name;

-- Prüfungen: UUID-PK + Kamerad_Id FK
ALTER TABLE fw_psa."Pruefungen"
  ADD COLUMN IF NOT EXISTS new_id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS "Kamerad_Id" UUID,
  ADD COLUMN IF NOT EXISTS "Ausruestungstueck_New_Id" UUID;
UPDATE fw_psa."Pruefungen" SET new_id = gen_random_uuid() WHERE new_id IS NULL;

UPDATE fw_psa."Pruefungen" p
  SET "Kamerad_Id" = n.member_id
  FROM _name_to_uuid n
  WHERE p."Kamerad" = n.full_name;

-- Wäsche: UUID-PK + Kamerad_Id FK
ALTER TABLE fw_psa."Waesche"
  ADD COLUMN IF NOT EXISTS new_id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS "Kamerad_Id" UUID,
  ADD COLUMN IF NOT EXISTS "Ausruestungstueck_New_Id" UUID;
UPDATE fw_psa."Waesche" SET new_id = gen_random_uuid() WHERE new_id IS NULL;

UPDATE fw_psa."Waesche" w
  SET "Kamerad_Id" = n.member_id
  FROM _name_to_uuid n
  WHERE w."Kamerad" = n.full_name;

-- Schadensdokumentation: UUID-PK
ALTER TABLE fw_psa."Schadensdokumentation"
  ADD COLUMN IF NOT EXISTS new_id UUID DEFAULT gen_random_uuid(),
  ADD COLUMN IF NOT EXISTS "Ausruestungstueck_New_Id" UUID;
UPDATE fw_psa."Schadensdokumentation" SET new_id = gen_random_uuid() WHERE new_id IS NULL;

-- Normen: UUID-PK
ALTER TABLE fw_psa."Normen"
  ADD COLUMN IF NOT EXISTS new_id UUID DEFAULT gen_random_uuid();
UPDATE fw_psa."Normen" SET new_id = gen_random_uuid() WHERE new_id IS NULL;

-- Changelog: UUID-PK
ALTER TABLE fw_psa."Changelog"
  ADD COLUMN IF NOT EXISTS new_id UUID DEFAULT gen_random_uuid();
UPDATE fw_psa."Changelog" SET new_id = gen_random_uuid() WHERE new_id IS NULL;

-- ══════════════════════════════════════════════════════════════
--  7. Ausrüstungsstück_Id FK-Referenzen migrieren (Integer → UUID)
-- ══════════════════════════════════════════════════════════════

-- Mapping: alte Ausrüstungsstücke Integer-ID → neue UUID
CREATE TEMP TABLE _ausr_map AS
SELECT id AS old_id, new_id FROM fw_psa."Ausruestungstuecke";

UPDATE fw_psa."Ausgaben" a
  SET "Ausruestungstueck_New_Id" = am.new_id
  FROM _ausr_map am
  WHERE a."Ausruestungstueck_Id" = am.old_id;

UPDATE fw_psa."Pruefungen" p
  SET "Ausruestungstueck_New_Id" = am.new_id
  FROM _ausr_map am
  WHERE p."Ausruestungstueck_Id" = am.old_id;

UPDATE fw_psa."Waesche" w
  SET "Ausruestungstueck_New_Id" = am.new_id
  FROM _ausr_map am
  WHERE w."Ausruestungstueck_Id" = am.old_id;

UPDATE fw_psa."Schadensdokumentation" s
  SET "Ausruestungstueck_New_Id" = am.new_id
  FROM _ausr_map am
  WHERE s."Ausruestungstueck_Id" = am.old_id;

-- ══════════════════════════════════════════════════════════════
--  8. PK-SWAP: Integer-ID → UUID-ID
-- ══════════════════════════════════════════════════════════════

-- Für jede Tabelle: alte PK droppen, neue UUID-Spalte zur PK machen

-- Ausrüstungstypen
ALTER TABLE fw_psa."Ausruestungstypen" DROP CONSTRAINT IF EXISTS "Ausruestungstypen_pkey" CASCADE;
ALTER TABLE fw_psa."Ausruestungstypen" DROP COLUMN id;
ALTER TABLE fw_psa."Ausruestungstypen" RENAME COLUMN new_id TO id;
ALTER TABLE fw_psa."Ausruestungstypen" ADD PRIMARY KEY (id);

-- Ausrüstungsstücke
ALTER TABLE fw_psa."Ausruestungstuecke" DROP CONSTRAINT IF EXISTS "Ausruestungstuecke_pkey" CASCADE;
ALTER TABLE fw_psa."Ausruestungstuecke" DROP COLUMN id;
ALTER TABLE fw_psa."Ausruestungstuecke" RENAME COLUMN new_id TO id;
ALTER TABLE fw_psa."Ausruestungstuecke" ADD PRIMARY KEY (id);
ALTER TABLE fw_psa."Ausruestungstuecke" DROP COLUMN IF EXISTS "Kamerad";
ALTER TABLE fw_psa."Ausruestungstuecke"
  ADD CONSTRAINT ausr_kamerad_fk FOREIGN KEY ("Kamerad_Id") REFERENCES fw_common.members(id) ON DELETE SET NULL;

-- Ausgaben
ALTER TABLE fw_psa."Ausgaben" DROP CONSTRAINT IF EXISTS "Ausgaben_pkey" CASCADE;
ALTER TABLE fw_psa."Ausgaben" DROP COLUMN id;
ALTER TABLE fw_psa."Ausgaben" RENAME COLUMN new_id TO id;
ALTER TABLE fw_psa."Ausgaben" ADD PRIMARY KEY (id);
ALTER TABLE fw_psa."Ausgaben" DROP COLUMN IF EXISTS "Kamerad";
ALTER TABLE fw_psa."Ausgaben" DROP COLUMN IF EXISTS "Ausruestungstueck_Id";
ALTER TABLE fw_psa."Ausgaben" RENAME COLUMN "Ausruestungstueck_New_Id" TO "Ausruestungstueck_Id";
ALTER TABLE fw_psa."Ausgaben"
  ADD CONSTRAINT ausgaben_kamerad_fk FOREIGN KEY ("Kamerad_Id") REFERENCES fw_common.members(id) ON DELETE SET NULL,
  ADD CONSTRAINT ausgaben_ausr_fk FOREIGN KEY ("Ausruestungstueck_Id") REFERENCES fw_psa."Ausruestungstuecke"(id) ON DELETE CASCADE;

-- Prüfungen
ALTER TABLE fw_psa."Pruefungen" DROP CONSTRAINT IF EXISTS "Pruefungen_pkey" CASCADE;
ALTER TABLE fw_psa."Pruefungen" DROP COLUMN id;
ALTER TABLE fw_psa."Pruefungen" RENAME COLUMN new_id TO id;
ALTER TABLE fw_psa."Pruefungen" ADD PRIMARY KEY (id);
ALTER TABLE fw_psa."Pruefungen" DROP COLUMN IF EXISTS "Kamerad";
ALTER TABLE fw_psa."Pruefungen" DROP COLUMN IF EXISTS "Ausruestungstueck_Id";
ALTER TABLE fw_psa."Pruefungen" RENAME COLUMN "Ausruestungstueck_New_Id" TO "Ausruestungstueck_Id";
ALTER TABLE fw_psa."Pruefungen"
  ADD CONSTRAINT pruef_kamerad_fk FOREIGN KEY ("Kamerad_Id") REFERENCES fw_common.members(id) ON DELETE SET NULL,
  ADD CONSTRAINT pruef_ausr_fk FOREIGN KEY ("Ausruestungstueck_Id") REFERENCES fw_psa."Ausruestungstuecke"(id) ON DELETE CASCADE;

-- Wäsche
ALTER TABLE fw_psa."Waesche" DROP CONSTRAINT IF EXISTS "Waesche_pkey" CASCADE;
ALTER TABLE fw_psa."Waesche" DROP COLUMN id;
ALTER TABLE fw_psa."Waesche" RENAME COLUMN new_id TO id;
ALTER TABLE fw_psa."Waesche" ADD PRIMARY KEY (id);
ALTER TABLE fw_psa."Waesche" DROP COLUMN IF EXISTS "Kamerad";
ALTER TABLE fw_psa."Waesche" DROP COLUMN IF EXISTS "Ausruestungstueck_Id";
ALTER TABLE fw_psa."Waesche" RENAME COLUMN "Ausruestungstueck_New_Id" TO "Ausruestungstueck_Id";
ALTER TABLE fw_psa."Waesche"
  ADD CONSTRAINT waesche_kamerad_fk FOREIGN KEY ("Kamerad_Id") REFERENCES fw_common.members(id) ON DELETE SET NULL,
  ADD CONSTRAINT waesche_ausr_fk FOREIGN KEY ("Ausruestungstueck_Id") REFERENCES fw_psa."Ausruestungstuecke"(id) ON DELETE CASCADE;

-- Normen
ALTER TABLE fw_psa."Normen" DROP CONSTRAINT IF EXISTS "Normen_pkey" CASCADE;
ALTER TABLE fw_psa."Normen" DROP COLUMN id;
ALTER TABLE fw_psa."Normen" RENAME COLUMN new_id TO id;
ALTER TABLE fw_psa."Normen" ADD PRIMARY KEY (id);

-- Schadensdokumentation
ALTER TABLE fw_psa."Schadensdokumentation" DROP CONSTRAINT IF EXISTS "Schadensdokumentation_pkey" CASCADE;
ALTER TABLE fw_psa."Schadensdokumentation" DROP COLUMN id;
ALTER TABLE fw_psa."Schadensdokumentation" RENAME COLUMN new_id TO id;
ALTER TABLE fw_psa."Schadensdokumentation" ADD PRIMARY KEY (id);
ALTER TABLE fw_psa."Schadensdokumentation" DROP COLUMN IF EXISTS "Ausruestungstueck_Id";
ALTER TABLE fw_psa."Schadensdokumentation" RENAME COLUMN "Ausruestungstueck_New_Id" TO "Ausruestungstueck_Id";
ALTER TABLE fw_psa."Schadensdokumentation"
  ADD CONSTRAINT schaden_ausr_fk FOREIGN KEY ("Ausruestungstueck_Id") REFERENCES fw_psa."Ausruestungstuecke"(id) ON DELETE CASCADE;

-- Changelog
ALTER TABLE fw_psa."Changelog" DROP CONSTRAINT IF EXISTS "Changelog_pkey" CASCADE;
ALTER TABLE fw_psa."Changelog" DROP COLUMN id;
ALTER TABLE fw_psa."Changelog" RENAME COLUMN new_id TO id;
ALTER TABLE fw_psa."Changelog" ADD PRIMARY KEY (id);

-- ══════════════════════════════════════════════════════════════
--  9. ALTE TABELLEN ENTFERNEN
-- ══════════════════════════════════════════════════════════════

DROP TABLE IF EXISTS fw_psa."Kameraden" CASCADE;
DROP TABLE IF EXISTS fw_psa."Benutzer" CASCADE;
DROP TABLE IF EXISTS fw_psa.login_attempts CASCADE;

-- Alte Sequences entfernen (NocoDB-Altlast)
DROP SEQUENCE IF EXISTS fw_psa."Kameraden_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Benutzer_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Ausruestungstypen_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Ausruestungstuecke_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Ausgaben_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Pruefungen_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Waesche_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Normen_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Schadensdokumentation_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa."Changelog_id_seq" CASCADE;
DROP SEQUENCE IF EXISTS fw_psa.login_attempts_id_seq CASCADE;

-- Alte Funktionen entfernen (jetzt in fw_common)
DROP FUNCTION IF EXISTS fw_psa.authenticate(text, text) CASCADE;
DROP FUNCTION IF EXISTS fw_psa.is_initialized() CASCADE;
DROP FUNCTION IF EXISTS fw_psa.create_admin(text, text) CASCADE;
DROP FUNCTION IF EXISTS fw_psa.change_password(text, text) CASCADE;
DROP FUNCTION IF EXISTS fw_psa.jwt_sign(json) CASCADE;
DROP FUNCTION IF EXISTS fw_psa.url_encode(bytea) CASCADE;
DROP FUNCTION IF EXISTS fw_psa.hash_pin_trigger() CASCADE;
DROP FUNCTION IF EXISTS fw_psa.current_app_role() CASCADE;
DROP FUNCTION IF EXISTS fw_psa.current_kamerad_id() CASCADE;
DROP FUNCTION IF EXISTS fw_psa.current_kamerad_name() CASCADE;

-- ══════════════════════════════════════════════════════════════
--  10. GRANTS NEU SETZEN
-- ══════════════════════════════════════════════════════════════

GRANT USAGE ON SCHEMA fw_common TO psa_anon;
GRANT USAGE ON SCHEMA fw_common TO psa_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fw_common TO psa_user;

GRANT USAGE ON SCHEMA fw_psa TO psa_anon;
GRANT USAGE ON SCHEMA fw_psa TO psa_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fw_psa TO psa_user;

COMMIT;

-- ══════════════════════════════════════════════════════════════
--  FERTIG! Nächste Schritte:
--    1. postgres-common.sql ausführen (Auth-Funktionen neu erstellen)
--    2. postgres-jwt-lockdown.sql ausführen (RLS-Policies neu setzen)
--    3. docker compose restart postgrest
-- ══════════════════════════════════════════════════════════════
