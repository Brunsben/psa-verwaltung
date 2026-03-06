-- ─────────────────────────────────────────────────────────────
--  postgres-common.sql – Feuerwehr Shared Schema (fw_common)
--
--  Zentrale Mitglieder- und Kontoverwaltung für alle Feuerwehr-Apps.
--  Muss VOR postgres-init.sql ausgeführt werden.
--
--  Aufruf durch install.sh automatisch.
-- ─────────────────────────────────────────────────────────────

-- ── Schema ────────────────────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS fw_common;

-- ── pgcrypto für HMAC-SHA256 JWT-Signing + bcrypt ─────────────────────────
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Rollen (idempotent) ───────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'psa_anon') THEN
    CREATE ROLE psa_anon NOLOGIN;
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'psa_auth') THEN
    CREATE ROLE psa_auth NOINHERIT LOGIN PASSWORD :'postgrest_password';
  END IF;
END $$;

ALTER ROLE psa_auth PASSWORD :'postgrest_password';

DO $$ BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'psa_user') THEN
    CREATE ROLE psa_user NOLOGIN;
  END IF;
END $$;

GRANT psa_anon TO psa_auth;
GRANT psa_user TO psa_auth;

-- ── Mitglieder (zentral für alle Apps) ────────────────────────────────────
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

-- ── Benutzerkonten (zentral für alle Apps) ────────────────────────────────
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

-- ── Brute-Force-Schutz ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_common.login_attempts (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  benutzername   TEXT NOT NULL,
  zeitpunkt      TIMESTAMPTZ NOT NULL DEFAULT now(),
  erfolgreich    BOOLEAN NOT NULL DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_login_attempts_user_time
  ON fw_common.login_attempts(benutzername, zeitpunkt);

-- ── App-Berechtigungen (pro App eigene Rolle) ─────────────────────────────
-- Erlaubt pro Benutzer unterschiedliche Rollen in jeder App.
-- Wenn kein Eintrag für eine App existiert, wird accounts."Rolle" als Fallback verwendet.
CREATE TABLE IF NOT EXISTS fw_common.app_permissions (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_id  UUID NOT NULL REFERENCES fw_common.accounts(id) ON DELETE CASCADE,
  app         TEXT NOT NULL CHECK (app IN ('psa', 'food', 'fk')),
  rolle       TEXT NOT NULL DEFAULT 'User'
                CHECK (rolle IN ('Admin', 'Kleiderwart', 'User')),
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE (account_id, app)
);

-- ── Schema-Grants ─────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA fw_common TO psa_anon;
GRANT USAGE ON SCHEMA fw_common TO psa_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fw_common TO psa_user;

-- ── PIN-Hashing Trigger ──────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fw_common.hash_pin_trigger()
  RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW."PIN" IS NOT NULL AND NEW."PIN" !~ '^\$2[ab]\$' THEN
    IF length(NEW."PIN") < 6 THEN
      RAISE EXCEPTION 'Passwort muss mindestens 6 Zeichen haben'
        USING ERRCODE = 'check_violation';
    END IF;
    NEW."PIN" := crypt(NEW."PIN", gen_salt('bf'));
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS hash_pin ON fw_common.accounts;
CREATE TRIGGER hash_pin
  BEFORE INSERT OR UPDATE OF "PIN" ON fw_common.accounts
  FOR EACH ROW EXECUTE FUNCTION fw_common.hash_pin_trigger();

-- ── updated_at Trigger für members ────────────────────────────────────────
CREATE OR REPLACE FUNCTION fw_common.update_timestamp()
  RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS members_updated_at ON fw_common.members;
CREATE TRIGGER members_updated_at
  BEFORE UPDATE ON fw_common.members
  FOR EACH ROW EXECUTE FUNCTION fw_common.update_timestamp();

-- ── JWT-Hilfsfunktionen ──────────────────────────────────────────────────

-- JWT-Secret in psa_auth-Rolle speichern
ALTER ROLE psa_auth SET "app.jwt_secret" = :'jwt_secret';

-- Base64URL-Encoding
CREATE OR REPLACE FUNCTION fw_common.url_encode(data bytea)
  RETURNS text LANGUAGE sql IMMUTABLE CALLED ON NULL INPUT AS $$
  SELECT translate(encode(data, 'base64'), E'+/=\n', '-_');
$$;

-- JWT signieren (HMAC-SHA256)
CREATE OR REPLACE FUNCTION fw_common.jwt_sign(payload json)
  RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  header text;
  body   text;
  secret text;
  sig    text;
BEGIN
  header := fw_common.url_encode(convert_to('{"alg":"HS256","typ":"JWT"}', 'utf8'));
  body   := fw_common.url_encode(convert_to(payload::text, 'utf8'));
  secret := current_setting('app.jwt_secret', true);
  IF secret IS NULL OR secret = '' THEN
    RAISE EXCEPTION 'JWT-Secret nicht konfiguriert (app.jwt_secret)';
  END IF;
  sig := fw_common.url_encode(
    hmac(convert_to(header || '.' || body, 'utf8'),
         convert_to(secret, 'utf8'), 'sha256')
  );
  RETURN header || '.' || body || '.' || sig;
END;
$$;

-- ── Authentifizierung ────────────────────────────────────────────────────

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

  -- App-spezifische Rolle ermitteln (Fallback: accounts."Rolle")
  SELECT coalesce(ap.rolle, u."Rolle") INTO psa_role
    FROM fw_common.accounts a
    LEFT JOIN fw_common.app_permissions ap ON ap.account_id = a.id AND ap.app = 'psa'
   WHERE a.id = u.id;

  -- Alle App-Berechtigungen als JSON-Objekt {"psa":"Admin","fk":"Admin","food":"User"}
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

-- ── First-Run-Check ──────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fw_common.is_initialized()
  RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS (SELECT 1 FROM fw_common.accounts);
$$;

-- ── Ersten Admin anlegen ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fw_common.create_admin(benutzername text, pin text)
  RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  u     record;
  token text;
BEGIN
  IF EXISTS (SELECT 1 FROM fw_common.accounts) THEN
    RAISE EXCEPTION 'Bereits initialisiert – Admin-Account existiert bereits'
      USING ERRCODE = 'check_violation';
  END IF;
  IF length(pin) < 6 THEN
    RAISE EXCEPTION 'Passwort muss mindestens 6 Zeichen haben'
      USING ERRCODE = 'check_violation';
  END IF;
  INSERT INTO fw_common.accounts
    ("Benutzername", "PIN", "Rolle", "Aktiv")
  VALUES
    (create_admin.benutzername, create_admin.pin, 'Admin', true)
  RETURNING * INTO u;
  token := fw_common.jwt_sign(json_build_object(
    'role', 'psa_user',
    'sub',  u."Benutzername",
    'app_role', 'Admin',
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
      'KameradId',    u."KameradId"
    )
  );
END;
$$;

-- ── Passwort ändern (authentifiziert) ────────────────────────────────────

CREATE OR REPLACE FUNCTION fw_common.change_password(alt_pin text, neues_pin text)
  RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  u record;
  username text;
BEGIN
  username := current_setting('request.jwt.claim.sub', true);
  IF username IS NULL OR username = '' THEN
    RAISE EXCEPTION 'Nicht authentifiziert'
      USING ERRCODE = 'insufficient_privilege';
  END IF;
  IF length(neues_pin) < 6 THEN
    RAISE EXCEPTION 'Neues Passwort muss mindestens 6 Zeichen haben'
      USING ERRCODE = 'check_violation';
  END IF;
  SELECT * INTO u
    FROM fw_common.accounts
   WHERE lower("Benutzername") = lower(username)
     AND "PIN" = crypt(alt_pin, "PIN")
     AND "Aktiv" = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Aktuelles Passwort ist falsch'
      USING ERRCODE = 'invalid_password';
  END IF;
  UPDATE fw_common.accounts
    SET "PIN" = crypt(neues_pin, gen_salt('bf'))
  WHERE id = u.id;
END;
$$;

-- ── RLS-Hilfsfunktionen ──────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fw_common.current_app_role()
  RETURNS text LANGUAGE sql STABLE AS $$
  SELECT coalesce(current_setting('request.jwt.claim.app_role', true), '');
$$;

CREATE OR REPLACE FUNCTION fw_common.current_kamerad_id()
  RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT CASE
    WHEN current_setting('request.jwt.claim.kamerad_id', true) IS NOT NULL
     AND current_setting('request.jwt.claim.kamerad_id', true) != ''
     AND current_setting('request.jwt.claim.kamerad_id', true) != 'null'
    THEN CAST(current_setting('request.jwt.claim.kamerad_id', true) AS uuid)
    ELSE NULL
  END;
$$;

-- ── Anonyme Zugriffe (Login, First-Run) ──────────────────────────────────
GRANT EXECUTE ON FUNCTION fw_common.authenticate(text, text) TO psa_anon;
GRANT EXECUTE ON FUNCTION fw_common.is_initialized() TO psa_anon;
GRANT EXECUTE ON FUNCTION fw_common.create_admin(text, text) TO psa_anon;

-- Authentifizierte Zugriffe
GRANT EXECUTE ON FUNCTION fw_common.change_password(text, text) TO psa_user;

-- login_attempts: kein direkter Zugriff
REVOKE ALL ON fw_common.login_attempts FROM psa_user;
REVOKE ALL ON fw_common.login_attempts FROM psa_anon;

-- ── Hilfsfunktion: App-Rolle ermitteln ───────────────────────────────────
-- Kann von jeder App genutzt werden, um die Rolle eines Accounts für eine
-- bestimmte App zu ermitteln (mit Fallback auf accounts."Rolle").

CREATE OR REPLACE FUNCTION fw_common.get_app_role(p_account_id uuid, p_app text)
  RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT coalesce(
    (SELECT rolle FROM fw_common.app_permissions WHERE account_id = p_account_id AND app = p_app),
    (SELECT "Rolle" FROM fw_common.accounts WHERE id = p_account_id)
  );
$$;

GRANT EXECUTE ON FUNCTION fw_common.get_app_role(uuid, text) TO psa_user;

-- ── Migration: Bestehende Admin-Accounts → app_permissions ───────────────
-- Einmalig ausführen: Kopiert die bestehende accounts."Rolle" als Berechtigung
-- für alle drei Apps, damit keine Berechtigungen verloren gehen.
-- (Idempotent — INSERT ON CONFLICT DO NOTHING)

-- INSERT INTO fw_common.app_permissions (account_id, app, rolle)
-- SELECT id, app, "Rolle"
--   FROM fw_common.accounts
--   CROSS JOIN (VALUES ('psa'), ('food'), ('fk')) AS apps(app)
--  WHERE "Rolle" != 'User'
-- ON CONFLICT (account_id, app) DO NOTHING;
