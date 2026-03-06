-- ─────────────────────────────────────────────────────────────
--  postgres-jwt-lockdown.sql – Sicherheits-Lockdown
--
--  1. Tabellenzugriff für psa_anon entfernen
--  2. Row-Level Security (RLS) aktivieren
--
--  WICHTIG: Erst ausführen, nachdem JWT-Authentifizierung erfolgreich getestet!
-- ─────────────────────────────────────────────────────────────

-- ── Anonymen Zugriff entfernen ────────────────────────────────────────────

REVOKE SELECT, INSERT, UPDATE, DELETE
  ON ALL TABLES IN SCHEMA fw_common FROM psa_anon;
REVOKE SELECT, INSERT, UPDATE, DELETE
  ON ALL TABLES IN SCHEMA fw_psa FROM psa_anon;

-- psa_anon behält USAGE auf Schemas (für /rpc/-Aufrufe nötig)

-- ══════════════════════════════════════════════════════════════
--  fw_common RLS
-- ══════════════════════════════════════════════════════════════

-- ── members ───────────────────────────────────────────────────────────────
ALTER TABLE fw_common.members ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS members_admin ON fw_common.members;
CREATE POLICY members_admin ON fw_common.members
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS members_user_read ON fw_common.members;
CREATE POLICY members_user_read ON fw_common.members
  FOR SELECT TO psa_user
  USING (
    fw_common.current_app_role() = 'User'
    AND id = fw_common.current_kamerad_id()
  );

-- ── accounts (nur Admin) ─────────────────────────────────────────────────
ALTER TABLE fw_common.accounts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS accounts_admin ON fw_common.accounts;
CREATE POLICY accounts_admin ON fw_common.accounts
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() = 'Admin')
  WITH CHECK (fw_common.current_app_role() = 'Admin');

-- ── login_attempts: kein direkter Zugriff ─────────────────────────────────
ALTER TABLE fw_common.login_attempts ENABLE ROW LEVEL SECURITY;

-- ══════════════════════════════════════════════════════════════
--  fw_psa RLS
-- ══════════════════════════════════════════════════════════════

-- ── Ausrüstungstypen (Referenzdaten: alle dürfen lesen) ──────────────────
ALTER TABLE fw_psa."Ausruestungstypen" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS typen_read ON fw_psa."Ausruestungstypen";
CREATE POLICY typen_read ON fw_psa."Ausruestungstypen"
  FOR SELECT TO psa_user USING (true);

DROP POLICY IF EXISTS typen_admin ON fw_psa."Ausruestungstypen";
CREATE POLICY typen_admin ON fw_psa."Ausruestungstypen"
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

-- ── Ausrüstungsstücke ────────────────────────────────────────────────────
ALTER TABLE fw_psa."Ausruestungstuecke" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ausr_admin ON fw_psa."Ausruestungstuecke";
CREATE POLICY ausr_admin ON fw_psa."Ausruestungstuecke"
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS ausr_user_read ON fw_psa."Ausruestungstuecke";
CREATE POLICY ausr_user_read ON fw_psa."Ausruestungstuecke"
  FOR SELECT TO psa_user
  USING (
    fw_common.current_app_role() = 'User'
    AND "Kamerad_Id" = fw_common.current_kamerad_id()
  );

-- ── Ausgaben ──────────────────────────────────────────────────────────────
ALTER TABLE fw_psa."Ausgaben" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS ausgaben_admin ON fw_psa."Ausgaben";
CREATE POLICY ausgaben_admin ON fw_psa."Ausgaben"
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS ausgaben_user_read ON fw_psa."Ausgaben";
CREATE POLICY ausgaben_user_read ON fw_psa."Ausgaben"
  FOR SELECT TO psa_user
  USING (
    fw_common.current_app_role() = 'User'
    AND "Kamerad_Id" = fw_common.current_kamerad_id()
  );

-- ── Prüfungen ─────────────────────────────────────────────────────────────
ALTER TABLE fw_psa."Pruefungen" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS pruef_admin ON fw_psa."Pruefungen";
CREATE POLICY pruef_admin ON fw_psa."Pruefungen"
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS pruef_user_read ON fw_psa."Pruefungen";
CREATE POLICY pruef_user_read ON fw_psa."Pruefungen"
  FOR SELECT TO psa_user
  USING (
    fw_common.current_app_role() = 'User'
    AND "Kamerad_Id" = fw_common.current_kamerad_id()
  );

-- ── Wäsche ────────────────────────────────────────────────────────────────
ALTER TABLE fw_psa."Waesche" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS waesche_admin ON fw_psa."Waesche";
CREATE POLICY waesche_admin ON fw_psa."Waesche"
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS waesche_user_read ON fw_psa."Waesche";
CREATE POLICY waesche_user_read ON fw_psa."Waesche"
  FOR SELECT TO psa_user
  USING (
    fw_common.current_app_role() = 'User'
    AND "Kamerad_Id" = fw_common.current_kamerad_id()
  );

-- ── Normen (Referenzdaten: alle dürfen lesen) ────────────────────────────
ALTER TABLE fw_psa."Normen" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS normen_read ON fw_psa."Normen";
CREATE POLICY normen_read ON fw_psa."Normen"
  FOR SELECT TO psa_user USING (true);

DROP POLICY IF EXISTS normen_admin ON fw_psa."Normen";
CREATE POLICY normen_admin ON fw_psa."Normen"
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

-- ── Changelog (Admin/Kleiderwart lesen, alle dürfen schreiben) ───────────
ALTER TABLE fw_psa."Changelog" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS changelog_admin ON fw_psa."Changelog";
CREATE POLICY changelog_admin ON fw_psa."Changelog"
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS changelog_insert ON fw_psa."Changelog";
CREATE POLICY changelog_insert ON fw_psa."Changelog"
  FOR INSERT TO psa_user
  WITH CHECK (true);

-- ── Schadensdokumentation ─────────────────────────────────────────────────
ALTER TABLE fw_psa."Schadensdokumentation" ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS schaden_admin ON fw_psa."Schadensdokumentation";
CREATE POLICY schaden_admin ON fw_psa."Schadensdokumentation"
  FOR ALL TO psa_user
  USING (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'))
  WITH CHECK (fw_common.current_app_role() IN ('Admin', 'Kleiderwart'));

DROP POLICY IF EXISTS schaden_user_read ON fw_psa."Schadensdokumentation";
CREATE POLICY schaden_user_read ON fw_psa."Schadensdokumentation"
  FOR SELECT TO psa_user
  USING (
    fw_common.current_app_role() = 'User'
    AND "Erstellt_Von" = current_setting('request.jwt.claim.sub', true)
  );

DROP POLICY IF EXISTS schaden_user_insert ON fw_psa."Schadensdokumentation";
CREATE POLICY schaden_user_insert ON fw_psa."Schadensdokumentation"
  FOR INSERT TO psa_user
  WITH CHECK (fw_common.current_app_role() = 'User');
