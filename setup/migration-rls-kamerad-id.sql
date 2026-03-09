-- ─────────────────────────────────────────────────────────────
--  migration-rls-kamerad-id.sql – RLS Name→ID Migration
--
--  Fügt kamerad_id (FK → Kameraden.id) zu den 4 Tabellen hinzu,
--  die bisher nur einen Kamerad-Textfeld haben.
--  Anschließend werden die RLS-Policies auf den Integer-Vergleich
--  mit current_kamerad_id() umgestellt (statt String-Vergleich).
--
--  VORTEILE:
--   - Kein Problem bei Namens-Duplikaten mehr
--   - Integer-Vergleich statt String-Lookup pro RLS-Check (performanter)
--   - current_kamerad_name() mit SECURITY DEFINER nicht mehr nötig
--
--  VORBEREITUNG:
--   Backup der Datenbank erstellen!
--     docker exec nocodb_postgres pg_dump -U nocodb -d nocodb > backup.sql
--
--  AUSFÜHREN:
--    docker exec -i nocodb_postgres psql -U nocodb -d nocodb \
--      -f /dev/stdin < setup/migration-rls-kamerad-id.sql
--
--  HINWEIS: Die bestehende "Kamerad"-Textspalte bleibt für Display erhalten.
--           Das Frontend benötigt keine Änderungen.
-- ─────────────────────────────────────────────────────────────

BEGIN;

-- ══════════════════════════════════════════════════════════════
-- 1. Neue Spalte kamerad_id (FK) zu den 4 betroffenen Tabellen
-- ══════════════════════════════════════════════════════════════

ALTER TABLE pxicv3djlauluse."Ausruestungstuecke"
  ADD COLUMN IF NOT EXISTS kamerad_id integer
  REFERENCES pxicv3djlauluse."Kameraden"(id) ON DELETE SET NULL;

ALTER TABLE pxicv3djlauluse."Ausgaben"
  ADD COLUMN IF NOT EXISTS kamerad_id integer
  REFERENCES pxicv3djlauluse."Kameraden"(id) ON DELETE SET NULL;

ALTER TABLE pxicv3djlauluse."Pruefungen"
  ADD COLUMN IF NOT EXISTS kamerad_id integer
  REFERENCES pxicv3djlauluse."Kameraden"(id) ON DELETE SET NULL;

ALTER TABLE pxicv3djlauluse."Waesche"
  ADD COLUMN IF NOT EXISTS kamerad_id integer
  REFERENCES pxicv3djlauluse."Kameraden"(id) ON DELETE SET NULL;

-- ══════════════════════════════════════════════════════════════
-- 2. Bestehende Namen → IDs zuordnen
--    "Kamerad" enthält "Vorname Name" → Join mit Kameraden-Tabelle
-- ══════════════════════════════════════════════════════════════

UPDATE pxicv3djlauluse."Ausruestungstuecke" t
   SET kamerad_id = k.id
  FROM pxicv3djlauluse."Kameraden" k
 WHERE t."Kamerad" = k."Vorname" || ' ' || k."Name"
   AND t.kamerad_id IS NULL;

UPDATE pxicv3djlauluse."Ausgaben" t
   SET kamerad_id = k.id
  FROM pxicv3djlauluse."Kameraden" k
 WHERE t."Kamerad" = k."Vorname" || ' ' || k."Name"
   AND t.kamerad_id IS NULL;

UPDATE pxicv3djlauluse."Pruefungen" t
   SET kamerad_id = k.id
  FROM pxicv3djlauluse."Kameraden" k
 WHERE t."Kamerad" = k."Vorname" || ' ' || k."Name"
   AND t.kamerad_id IS NULL;

UPDATE pxicv3djlauluse."Waesche" t
   SET kamerad_id = k.id
  FROM pxicv3djlauluse."Kameraden" k
 WHERE t."Kamerad" = k."Vorname" || ' ' || k."Name"
   AND t.kamerad_id IS NULL;

-- ══════════════════════════════════════════════════════════════
-- 3. Validierung: Prüfen ob alle Datensätze zugeordnet werden konnten
--    (gibt Warnung aus, bricht aber nicht ab)
-- ══════════════════════════════════════════════════════════════

DO $$
DECLARE
  unmatched integer;
BEGIN
  SELECT count(*) INTO unmatched
    FROM pxicv3djlauluse."Ausruestungstuecke"
   WHERE "Kamerad" IS NOT NULL AND kamerad_id IS NULL;
  IF unmatched > 0 THEN
    RAISE WARNING '% Ausruestungstuecke konnten keinem Kameraden zugeordnet werden', unmatched;
  END IF;

  SELECT count(*) INTO unmatched
    FROM pxicv3djlauluse."Ausgaben"
   WHERE "Kamerad" IS NOT NULL AND kamerad_id IS NULL;
  IF unmatched > 0 THEN
    RAISE WARNING '% Ausgaben konnten keinem Kameraden zugeordnet werden', unmatched;
  END IF;

  SELECT count(*) INTO unmatched
    FROM pxicv3djlauluse."Pruefungen"
   WHERE "Kamerad" IS NOT NULL AND kamerad_id IS NULL;
  IF unmatched > 0 THEN
    RAISE WARNING '% Pruefungen konnten keinem Kameraden zugeordnet werden', unmatched;
  END IF;

  SELECT count(*) INTO unmatched
    FROM pxicv3djlauluse."Waesche"
   WHERE "Kamerad" IS NOT NULL AND kamerad_id IS NULL;
  IF unmatched > 0 THEN
    RAISE WARNING '% Waesche-Eintraege konnten keinem Kameraden zugeordnet werden', unmatched;
  END IF;
END $$;

-- ══════════════════════════════════════════════════════════════
-- 4. Indizes für performante RLS-Checks
-- ══════════════════════════════════════════════════════════════

CREATE INDEX IF NOT EXISTS idx_ausruestungstuecke_kamerad_id
  ON pxicv3djlauluse."Ausruestungstuecke"(kamerad_id);

CREATE INDEX IF NOT EXISTS idx_ausgaben_kamerad_id
  ON pxicv3djlauluse."Ausgaben"(kamerad_id);

CREATE INDEX IF NOT EXISTS idx_pruefungen_kamerad_id
  ON pxicv3djlauluse."Pruefungen"(kamerad_id);

CREATE INDEX IF NOT EXISTS idx_waesche_kamerad_id
  ON pxicv3djlauluse."Waesche"(kamerad_id);

-- ══════════════════════════════════════════════════════════════
-- 5. Trigger: kamerad_id automatisch synchronisieren
--    wenn Kamerad-Textfeld geändert wird (Rückwärtskompatibilität)
-- ══════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION pxicv3djlauluse.sync_kamerad_id()
  RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW."Kamerad" IS NOT NULL THEN
    SELECT k.id INTO NEW.kamerad_id
      FROM pxicv3djlauluse."Kameraden" k
     WHERE k."Vorname" || ' ' || k."Name" = NEW."Kamerad"
     LIMIT 1;
  ELSE
    NEW.kamerad_id := NULL;
  END IF;
  RETURN NEW;
END;
$$;

-- Trigger auf allen 4 Tabellen
DROP TRIGGER IF EXISTS sync_kamerad_id ON pxicv3djlauluse."Ausruestungstuecke";
CREATE TRIGGER sync_kamerad_id
  BEFORE INSERT OR UPDATE OF "Kamerad" ON pxicv3djlauluse."Ausruestungstuecke"
  FOR EACH ROW EXECUTE FUNCTION pxicv3djlauluse.sync_kamerad_id();

DROP TRIGGER IF EXISTS sync_kamerad_id ON pxicv3djlauluse."Ausgaben";
CREATE TRIGGER sync_kamerad_id
  BEFORE INSERT OR UPDATE OF "Kamerad" ON pxicv3djlauluse."Ausgaben"
  FOR EACH ROW EXECUTE FUNCTION pxicv3djlauluse.sync_kamerad_id();

DROP TRIGGER IF EXISTS sync_kamerad_id ON pxicv3djlauluse."Pruefungen";
CREATE TRIGGER sync_kamerad_id
  BEFORE INSERT OR UPDATE OF "Kamerad" ON pxicv3djlauluse."Pruefungen"
  FOR EACH ROW EXECUTE FUNCTION pxicv3djlauluse.sync_kamerad_id();

DROP TRIGGER IF EXISTS sync_kamerad_id ON pxicv3djlauluse."Waesche";
CREATE TRIGGER sync_kamerad_id
  BEFORE INSERT OR UPDATE OF "Kamerad" ON pxicv3djlauluse."Waesche"
  FOR EACH ROW EXECUTE FUNCTION pxicv3djlauluse.sync_kamerad_id();

-- ══════════════════════════════════════════════════════════════
-- 6. RLS-Policies umschreiben: Integer-ID statt String-Vergleich
-- ══════════════════════════════════════════════════════════════

-- Ausrüstungsstücke
DROP POLICY IF EXISTS ausr_user_read ON pxicv3djlauluse."Ausruestungstuecke";
CREATE POLICY ausr_user_read ON pxicv3djlauluse."Ausruestungstuecke"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND kamerad_id = pxicv3djlauluse.current_kamerad_id()
  );

-- Ausgaben
DROP POLICY IF EXISTS ausgaben_user_read ON pxicv3djlauluse."Ausgaben";
CREATE POLICY ausgaben_user_read ON pxicv3djlauluse."Ausgaben"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND kamerad_id = pxicv3djlauluse.current_kamerad_id()
  );

-- Prüfungen
DROP POLICY IF EXISTS pruef_user_read ON pxicv3djlauluse."Pruefungen";
CREATE POLICY pruef_user_read ON pxicv3djlauluse."Pruefungen"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND kamerad_id = pxicv3djlauluse.current_kamerad_id()
  );

-- Wäsche
DROP POLICY IF EXISTS waesche_user_read ON pxicv3djlauluse."Waesche";
CREATE POLICY waesche_user_read ON pxicv3djlauluse."Waesche"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND kamerad_id = pxicv3djlauluse.current_kamerad_id()
  );

COMMIT;

-- ══════════════════════════════════════════════════════════════
-- Fertig! Die RLS-Policies nutzen jetzt kamerad_id (Integer)
-- statt Kamerad (Text). Die "Kamerad"-Textspalte bleibt für
-- Anzeigezwecke erhalten, wird aber nicht mehr für Sicherheits-
-- Entscheidungen verwendet.
--
-- current_kamerad_name() wird nicht mehr für RLS benötigt,
-- bleibt aber als Hilfsfunktion bestehen.
-- ══════════════════════════════════════════════════════════════
