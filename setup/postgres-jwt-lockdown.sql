-- ─────────────────────────────────────────────────────────────
--  postgres-jwt-lockdown.sql – Sicherheits-Lockdown
--
--  1. Tabellenzugriff für psa_anon entfernen
--  2. Row-Level Security (RLS) aktivieren
--
--  WICHTIG: Erst ausführen, nachdem JWT-Authentifizierung erfolgreich getestet!
--
--  Ausführen auf dem Pi:
--    docker exec -i nocodb_postgres psql -U nocodb -d nocodb \
--      -f /dev/stdin < setup/postgres-jwt-lockdown.sql
-- ─────────────────────────────────────────────────────────────

-- ── Anonymen Zugriff entfernen ────────────────────────────────────────────

REVOKE SELECT, INSERT, UPDATE, DELETE
  ON ALL TABLES IN SCHEMA pxicv3djlauluse FROM psa_anon;

REVOKE USAGE, SELECT
  ON ALL SEQUENCES IN SCHEMA pxicv3djlauluse FROM psa_anon;

-- psa_anon behält USAGE auf Schema (für /rpc/-Aufrufe nötig)
-- und EXECUTE auf authenticate, is_initialized, create_admin.
-- Diese nutzen SECURITY DEFINER → greifen intern als Funktionseigentümer zu.

-- ── Row-Level Security aktivieren ─────────────────────────────────────────
-- Admin/Kleiderwart: voller Zugriff auf alle Tabellen
-- User: nur eigene Daten (gefiltert über JWT-Claims app_role, kamerad_id)
--
-- Hilfsfunktionen (aus postgres-init.sql):
--   pxicv3djlauluse.current_app_role()      → 'Admin'|'Kleiderwart'|'User'
--   pxicv3djlauluse.current_kamerad_id()     → integer|NULL
--   pxicv3djlauluse.current_kamerad_name()   → 'Vorname Name'|NULL
--
-- HINWEIS: Die Migration setup/migration-rls-kamerad-id.sql ersetzt die
-- hier definierten user_read-Policies (ausr, ausgaben, pruef, waesche)
-- durch kamerad_id-basierte Integer-Vergleiche statt Kamerad-Textvergleiche.
-- Nach Ausführung der Migration sind diese Policies überschrieben.

-- ── Kameraden ─────────────────────────────────────────────────────────────
ALTER TABLE pxicv3djlauluse."Kameraden" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS kameraden_admin ON pxicv3djlauluse."Kameraden";
CREATE POLICY kameraden_admin ON pxicv3djlauluse."Kameraden"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS kameraden_user_read ON pxicv3djlauluse."Kameraden";
CREATE POLICY kameraden_user_read ON pxicv3djlauluse."Kameraden"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND id = pxicv3djlauluse.current_kamerad_id()
  );

-- ── Ausrüstungstypen (Referenzdaten: alle dürfen lesen) ──────────────────
ALTER TABLE pxicv3djlauluse."Ausruestungstypen" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS typen_read ON pxicv3djlauluse."Ausruestungstypen";
CREATE POLICY typen_read ON pxicv3djlauluse."Ausruestungstypen"
  FOR SELECT TO psa_user USING (true);

DROP POLICY IF EXISTS typen_admin ON pxicv3djlauluse."Ausruestungstypen";
CREATE POLICY typen_admin ON pxicv3djlauluse."Ausruestungstypen"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

-- ── Ausrüstungsstücke ────────────────────────────────────────────────────
ALTER TABLE pxicv3djlauluse."Ausruestungstuecke" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ausr_admin ON pxicv3djlauluse."Ausruestungstuecke";
CREATE POLICY ausr_admin ON pxicv3djlauluse."Ausruestungstuecke"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS ausr_user_read ON pxicv3djlauluse."Ausruestungstuecke";
CREATE POLICY ausr_user_read ON pxicv3djlauluse."Ausruestungstuecke"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND "Kamerad" = pxicv3djlauluse.current_kamerad_name()
  );

-- ── Ausgaben ──────────────────────────────────────────────────────────────
ALTER TABLE pxicv3djlauluse."Ausgaben" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ausgaben_admin ON pxicv3djlauluse."Ausgaben";
CREATE POLICY ausgaben_admin ON pxicv3djlauluse."Ausgaben"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS ausgaben_user_read ON pxicv3djlauluse."Ausgaben";
CREATE POLICY ausgaben_user_read ON pxicv3djlauluse."Ausgaben"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND "Kamerad" = pxicv3djlauluse.current_kamerad_name()
  );

-- ── Prüfungen ─────────────────────────────────────────────────────────────
ALTER TABLE pxicv3djlauluse."Pruefungen" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pruef_admin ON pxicv3djlauluse."Pruefungen";
CREATE POLICY pruef_admin ON pxicv3djlauluse."Pruefungen"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS pruef_user_read ON pxicv3djlauluse."Pruefungen";
CREATE POLICY pruef_user_read ON pxicv3djlauluse."Pruefungen"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND "Kamerad" = pxicv3djlauluse.current_kamerad_name()
  );

-- ── Wäsche ────────────────────────────────────────────────────────────────
ALTER TABLE pxicv3djlauluse."Waesche" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS waesche_admin ON pxicv3djlauluse."Waesche";
CREATE POLICY waesche_admin ON pxicv3djlauluse."Waesche"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS waesche_user_read ON pxicv3djlauluse."Waesche";
CREATE POLICY waesche_user_read ON pxicv3djlauluse."Waesche"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND "Kamerad" = pxicv3djlauluse.current_kamerad_name()
  );

-- ── Normen (Referenzdaten: alle dürfen lesen) ────────────────────────────
ALTER TABLE pxicv3djlauluse."Normen" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS normen_read ON pxicv3djlauluse."Normen";
CREATE POLICY normen_read ON pxicv3djlauluse."Normen"
  FOR SELECT TO psa_user USING (true);

DROP POLICY IF EXISTS normen_admin ON pxicv3djlauluse."Normen";
CREATE POLICY normen_admin ON pxicv3djlauluse."Normen"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

-- ── Benutzer (nur Admin hat vollen Zugriff) ──────────────────────────────
ALTER TABLE pxicv3djlauluse."Benutzer" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS benutzer_admin ON pxicv3djlauluse."Benutzer";
CREATE POLICY benutzer_admin ON pxicv3djlauluse."Benutzer"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() = 'Admin')
  WITH CHECK (pxicv3djlauluse.current_app_role() = 'Admin');

-- ── Changelog (Admin/Kleiderwart lesen, alle dürfen schreiben) ───────────
ALTER TABLE pxicv3djlauluse."Changelog" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS changelog_admin ON pxicv3djlauluse."Changelog";
CREATE POLICY changelog_admin ON pxicv3djlauluse."Changelog"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS changelog_insert ON pxicv3djlauluse."Changelog";
CREATE POLICY changelog_insert ON pxicv3djlauluse."Changelog"
  FOR INSERT TO psa_user
  WITH CHECK (true);

-- ── Schadensdokumentation ─────────────────────────────────────────────────
ALTER TABLE pxicv3djlauluse."Schadensdokumentation" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS schaden_admin ON pxicv3djlauluse."Schadensdokumentation";
CREATE POLICY schaden_admin ON pxicv3djlauluse."Schadensdokumentation"
  FOR ALL TO psa_user
  USING (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS schaden_user_read ON pxicv3djlauluse."Schadensdokumentation";
CREATE POLICY schaden_user_read ON pxicv3djlauluse."Schadensdokumentation"
  FOR SELECT TO psa_user
  USING (
    pxicv3djlauluse.current_app_role() = 'User'
    AND "Erstellt_Von" = current_setting('request.jwt.claim.sub', true)
  );

DROP POLICY IF EXISTS schaden_user_insert ON pxicv3djlauluse."Schadensdokumentation";
CREATE POLICY schaden_user_insert ON pxicv3djlauluse."Schadensdokumentation"
  FOR INSERT TO psa_user
  WITH CHECK (pxicv3djlauluse.current_app_role() = 'User');

-- ── login_attempts: kein direkter Zugriff ─────────────────────────────────
ALTER TABLE pxicv3djlauluse.login_attempts ENABLE ROW LEVEL SECURITY;
-- Keine Policies = kein Zugriff für psa_user/psa_anon
-- authenticate() ist SECURITY DEFINER und bypassed RLS als Table-Owner
