-- ─────────────────────────────────────────────────────────────
--  migration-app-permissions.sql
--
--  Fügt die app_permissions-Tabelle zu fw_common hinzu und
--  migriert bestehende Admin-Accounts als Berechtigungen
--  für alle drei Apps.
--
--  Einmalig auf dem Server ausführen:
--    docker exec -i nocodb_postgres psql -U nocodb -d nocodb < migration-app-permissions.sql
-- ─────────────────────────────────────────────────────────────

-- 1. Tabelle erstellen (idempotent)
CREATE TABLE IF NOT EXISTS fw_common.app_permissions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id  UUID NOT NULL REFERENCES fw_common.accounts(id) ON DELETE CASCADE,
  app         TEXT NOT NULL CHECK (app IN ('psa', 'food', 'fk')),
  rolle       TEXT NOT NULL DEFAULT 'User'
                CHECK (rolle IN ('Admin', 'Kleiderwart', 'User')),
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (account_id, app)
);

-- 2. Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON fw_common.app_permissions TO psa_user;

-- 3. Migration: Bestehende Nicht-User-Accounts → app_permissions für alle Apps
-- Wer bisher "Admin" war, wird jetzt in allen drei Apps Admin.
-- Wer "Kleiderwart" war, wird in PSA Kleiderwart, in Food/FK User.
INSERT INTO fw_common.app_permissions (account_id, app, rolle)
SELECT a.id, apps.app,
  CASE
    WHEN a."Rolle" = 'Admin' THEN 'Admin'
    WHEN a."Rolle" = 'Kleiderwart' AND apps.app = 'psa' THEN 'Kleiderwart'
    ELSE 'User'
  END
FROM fw_common.accounts a
CROSS JOIN (VALUES ('psa'), ('food'), ('fk')) AS apps(app)
WHERE a."Rolle" != 'User'
ON CONFLICT (account_id, app) DO NOTHING;

-- 4. Hilfsfunktion: App-Rolle ermitteln
CREATE OR REPLACE FUNCTION fw_common.get_app_role(p_account_id uuid, p_app text)
  RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT coalesce(
    (SELECT rolle FROM fw_common.app_permissions WHERE account_id = p_account_id AND app = p_app),
    (SELECT "Rolle" FROM fw_common.accounts WHERE id = p_account_id)
  );
$$;

GRANT EXECUTE ON FUNCTION fw_common.get_app_role(uuid, text) TO psa_user;

-- 5. authenticate()-Funktion aktualisieren (app_permissions ins JWT aufnehmen)
CREATE OR REPLACE FUNCTION fw_common.authenticate(benutzername text, pin text)
  RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  u          record;
  token      text;
  fail_count integer;
  psa_role   text;
  perms      json;
BEGIN
  -- Brute-Force-Schutz
  SELECT count(*) INTO fail_count
    FROM fw_common.login_attempts la
   WHERE lower(la.benutzername) = lower(authenticate.benutzername)
     AND la.zeitpunkt > now() - interval '15 minutes'
     AND la.erfolgreich = false;
  IF fail_count >= 5 THEN
    RAISE EXCEPTION 'Zu viele Fehlversuche – Account für 15 Minuten gesperrt'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Benutzer mit bcrypt-Vergleich
  SELECT *
    INTO u
    FROM fw_common.accounts
   WHERE lower("Benutzername") = lower(authenticate.benutzername)
     AND "PIN" = crypt(authenticate.pin, "PIN")
     AND "Aktiv" = true
   LIMIT 1;

  IF NOT FOUND THEN
    INSERT INTO fw_common.login_attempts (benutzername, erfolgreich)
      VALUES (lower(authenticate.benutzername), false);
    RAISE EXCEPTION 'Benutzername oder Passwort falsch'
      USING ERRCODE = 'invalid_password';
  END IF;

  -- Erfolg protokollieren + alte Einträge bereinigen
  INSERT INTO fw_common.login_attempts (benutzername, erfolgreich)
    VALUES (lower(authenticate.benutzername), true);
  DELETE FROM fw_common.login_attempts
    WHERE zeitpunkt < now() - interval '24 hours';

  -- PSA-Rolle mit Fallback
  SELECT coalesce(ap.rolle, u."Rolle") INTO psa_role
    FROM fw_common.accounts a
    LEFT JOIN fw_common.app_permissions ap ON ap.account_id = a.id AND ap.app = 'psa'
   WHERE a.id = u.id;

  -- Alle App-Berechtigungen als JSON
  SELECT coalesce(json_object_agg(ap.app, ap.rolle), '{}'::json) INTO perms
    FROM fw_common.app_permissions ap
   WHERE ap.account_id = u.id;

  token := fw_common.jwt_sign(json_build_object(
    'role', 'psa_user',
    'sub',  u."Benutzername",
    'app_role', psa_role,
    'app_permissions', perms,
    'kamerad_id', u."KameradId",
    'iat',  extract(epoch from now())::integer,
    'exp',  extract(epoch from now() + interval '8 hours')::integer
  ));
  RETURN json_build_object(
    'token', token,
    'user',  json_build_object(
      'Id',          u.id,
      'Benutzername', u."Benutzername",
      'Rolle',        u."Rolle",
      'KameradId',    u."KameradId",
      'app_permissions', perms
    )
  );
END;
$$;

-- ─────────────────────────────────────────────────────────────
-- Fertig! Danach PostgREST neustarten:
--   docker compose restart postgrest
-- ─────────────────────────────────────────────────────────────
