-- ─────────────────────────────────────────────────────────────
--  postgres-init.sql – PSA-Verwaltung
--  Legt PostgreSQL-Rollen für PostgREST an (idempotent).
--
--  Aufruf durch install.sh automatisch.
--  Manuell (Passwort als psql-Variable übergeben):
--    docker exec -i nocodb_postgres psql -U nocodb -d nocodb \
--      -v postgrest_password='DEIN_PASSWORT' -f /dev/stdin < postgres-init.sql
-- ─────────────────────────────────────────────────────────────

-- Anon-Rolle (für PostgREST-Zugriff ohne JWT)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'psa_anon') THEN
    CREATE ROLE psa_anon NOLOGIN;
  END IF;
END
$$;

-- Authenticator-Rolle (PostgREST verbindet sich damit)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'psa_auth') THEN
    CREATE ROLE psa_auth NOINHERIT LOGIN PASSWORD :'postgrest_password';
  END IF;
END
$$;

-- Passwort aktualisieren (falls Rolle bereits existiert)
ALTER ROLE psa_auth PASSWORD :'postgrest_password';

-- Rollen-Hierarchie
GRANT psa_anon TO psa_auth;

-- Zugriff auf Schema und Tabellen
GRANT USAGE ON SCHEMA pxicv3djlauluse TO psa_anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pxicv3djlauluse TO psa_anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pxicv3djlauluse TO psa_anon;

-- ── JWT-Authentifizierung ──────────────────────────────────────────────────

-- pgcrypto für HMAC-SHA256 JWT-Signing
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Brute-Force-Schutz: Login-Versuche protokollieren ─────────────────────
CREATE TABLE IF NOT EXISTS pxicv3djlauluse.login_attempts (
  id serial PRIMARY KEY,
  benutzername text NOT NULL,
  zeitpunkt timestamptz NOT NULL DEFAULT now(),
  erfolgreich boolean NOT NULL DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_login_attempts_user_time
  ON pxicv3djlauluse.login_attempts(benutzername, zeitpunkt);

-- ── PIN-Hashing: Trigger hasht PINs automatisch bei INSERT/UPDATE ─────────
CREATE OR REPLACE FUNCTION pxicv3djlauluse.hash_pin_trigger()
  RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  -- Nur hashen wenn PIN gesetzt und noch nicht gehasht (bcrypt-Prefix $2a$ oder $2b$)
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

-- Trigger nur anlegen wenn Benutzer-Tabelle existiert (idempotent)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'pxicv3djlauluse' AND table_name = 'Benutzer'
  ) THEN
    DROP TRIGGER IF EXISTS hash_pin ON pxicv3djlauluse."Benutzer";
    CREATE TRIGGER hash_pin
      BEFORE INSERT OR UPDATE OF "PIN" ON pxicv3djlauluse."Benutzer"
      FOR EACH ROW EXECUTE FUNCTION pxicv3djlauluse.hash_pin_trigger();
  END IF;
END
$$;

-- psa_user Rolle (authentifizierte Zugriffe via JWT)
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'psa_user') THEN
    CREATE ROLE psa_user NOLOGIN;
  END IF;
END
$$;
GRANT psa_user TO psa_auth;
GRANT USAGE ON SCHEMA pxicv3djlauluse TO psa_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pxicv3djlauluse TO psa_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pxicv3djlauluse TO psa_user;

-- JWT-Secret in psa_auth-Rolle speichern (übereinstimmend mit PGRST_JWT_SECRET)
ALTER ROLE psa_auth SET "app.jwt_secret" = :'jwt_secret';

-- Base64URL-Encoding Hilfsfunktion
CREATE OR REPLACE FUNCTION pxicv3djlauluse.url_encode(data bytea)
  RETURNS text LANGUAGE sql IMMUTABLE CALLED ON NULL INPUT AS $$
  SELECT translate(encode(data, 'base64'), E'+/=\n', '-_');
$$;

-- JWT signieren (HMAC-SHA256)
CREATE OR REPLACE FUNCTION pxicv3djlauluse.jwt_sign(payload json)
  RETURNS text LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  header text;
  body   text;
  secret text;
  sig    text;
BEGIN
  header := pxicv3djlauluse.url_encode(
    convert_to('{"alg":"HS256","typ":"JWT"}', 'utf8')
  );
  body := pxicv3djlauluse.url_encode(
    convert_to(payload::text, 'utf8')
  );
  secret := current_setting('app.jwt_secret', true);
  IF secret IS NULL OR secret = '' THEN
    RAISE EXCEPTION 'JWT-Secret nicht konfiguriert (app.jwt_secret)';
  END IF;
  sig := pxicv3djlauluse.url_encode(
    hmac(
      convert_to(header || '.' || body, 'utf8'),
      convert_to(secret, 'utf8'),
      'sha256'
    )
  );
  RETURN header || '.' || body || '.' || sig;
END;
$$;

-- Benutzer authentifizieren → JWT zurückgeben (bcrypt + Brute-Force-Schutz)
CREATE OR REPLACE FUNCTION pxicv3djlauluse.authenticate(benutzername text, pin text)
  RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  u          record;
  token      text;
  fail_count integer;
BEGIN
  -- Brute-Force-Schutz: Fehlversuche der letzten 15 Minuten prüfen
  SELECT count(*) INTO fail_count
    FROM pxicv3djlauluse.login_attempts la
   WHERE lower(la.benutzername) = lower(authenticate.benutzername)
     AND la.zeitpunkt > now() - interval '15 minutes'
     AND la.erfolgreich = false;
  IF fail_count >= 5 THEN
    RAISE EXCEPTION 'Zu viele Fehlversuche – Account für 15 Minuten gesperrt'
      USING ERRCODE = 'check_violation';
  END IF;

  -- Benutzer mit bcrypt-Vergleich suchen
  SELECT *
    INTO u
    FROM pxicv3djlauluse."Benutzer"
   WHERE lower("Benutzername") = lower(authenticate.benutzername)
     AND "PIN" = crypt(authenticate.pin, "PIN")
     AND "Aktiv" = true
   LIMIT 1;

  IF NOT FOUND THEN
    -- Fehlversuch protokollieren
    INSERT INTO pxicv3djlauluse.login_attempts (benutzername, erfolgreich)
      VALUES (lower(authenticate.benutzername), false);
    RAISE EXCEPTION 'Benutzername oder Passwort falsch'
      USING ERRCODE = 'invalid_password';
  END IF;

  -- Erfolgreichen Login protokollieren + alte Einträge bereinigen
  INSERT INTO pxicv3djlauluse.login_attempts (benutzername, erfolgreich)
    VALUES (lower(authenticate.benutzername), true);
  DELETE FROM pxicv3djlauluse.login_attempts
    WHERE zeitpunkt < now() - interval '24 hours';

  token := pxicv3djlauluse.jwt_sign(json_build_object(
    'role', 'psa_user',
    'sub',  u."Benutzername",
    'app_role', u."Rolle",
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

-- Prüfen ob bereits ein Admin-Account angelegt wurde (First-Run-Erkennung)
CREATE OR REPLACE FUNCTION pxicv3djlauluse.is_initialized()
  RETURNS boolean LANGUAGE sql SECURITY DEFINER AS $$
  SELECT EXISTS (SELECT 1 FROM pxicv3djlauluse."Benutzer");
$$;

-- Ersten Admin-Account anlegen (nur wenn noch keine Benutzer existieren)
-- PIN-Hashing erfolgt durch hash_pin Trigger automatisch
CREATE OR REPLACE FUNCTION pxicv3djlauluse.create_admin(benutzername text, pin text)
  RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  u     record;
  token text;
BEGIN
  IF EXISTS (SELECT 1 FROM pxicv3djlauluse."Benutzer") THEN
    RAISE EXCEPTION 'Bereits initialisiert – Admin-Account existiert bereits'
      USING ERRCODE = 'check_violation';
  END IF;
  IF length(pin) < 6 THEN
    RAISE EXCEPTION 'Passwort muss mindestens 6 Zeichen haben'
      USING ERRCODE = 'check_violation';
  END IF;
  INSERT INTO pxicv3djlauluse."Benutzer"
    ("Benutzername", "PIN", "Rolle", "Aktiv")
  VALUES
    (create_admin.benutzername, create_admin.pin, 'Admin', true)
  RETURNING * INTO u;
  token := pxicv3djlauluse.jwt_sign(json_build_object(
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

-- ── Passwort selbst ändern (sicherer als direkter PATCH auf Benutzer) ──────
CREATE OR REPLACE FUNCTION pxicv3djlauluse.change_password(alt_pin text, neues_pin text)
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
    FROM pxicv3djlauluse."Benutzer"
   WHERE lower("Benutzername") = lower(username)
     AND "PIN" = crypt(alt_pin, "PIN")
     AND "Aktiv" = true;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Aktuelles Passwort ist falsch'
      USING ERRCODE = 'invalid_password';
  END IF;
  -- Direkt hashen (Trigger würde auch greifen, aber explizit ist sicherer)
  UPDATE pxicv3djlauluse."Benutzer"
    SET "PIN" = crypt(neues_pin, gen_salt('bf'))
  WHERE id = u.id;
END;
$$;

-- ── RLS-Hilfsfunktionen ───────────────────────────────────────────────────

-- Aktuelle Benutzer-Rolle aus JWT-Claims lesen
CREATE OR REPLACE FUNCTION pxicv3djlauluse.current_app_role()
  RETURNS text LANGUAGE sql STABLE AS $$
  SELECT coalesce(current_setting('request.jwt.claim.app_role', true), '');
$$;

-- Aktuelle KameradId aus JWT-Claims lesen (sicher gecastet)
CREATE OR REPLACE FUNCTION pxicv3djlauluse.current_kamerad_id()
  RETURNS integer LANGUAGE sql STABLE AS $$
  SELECT CASE
    WHEN current_setting('request.jwt.claim.kamerad_id', true) IS NOT NULL
     AND current_setting('request.jwt.claim.kamerad_id', true) != ''
     AND current_setting('request.jwt.claim.kamerad_id', true) != 'null'
    THEN CAST(current_setting('request.jwt.claim.kamerad_id', true) AS integer)
    ELSE NULL
  END;
$$;

-- Aktueller Kamerad-Name (für Tabellen die per Name verknüpft sind)
CREATE OR REPLACE FUNCTION pxicv3djlauluse.current_kamerad_name()
  RETURNS text LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT k."Vorname" || ' ' || k."Name"
    FROM pxicv3djlauluse."Kameraden" k
    JOIN pxicv3djlauluse."Benutzer" b
      ON k.id = CAST(b."KameradId" AS integer)
   WHERE lower(b."Benutzername") = lower(
      current_setting('request.jwt.claim.sub', true)
    )
   LIMIT 1;
$$;

-- Zugriffsrechte für anonyme Aufrufe (Login + First-Run-Check)
GRANT EXECUTE ON FUNCTION pxicv3djlauluse.authenticate(text, text) TO psa_anon;
GRANT EXECUTE ON FUNCTION pxicv3djlauluse.is_initialized() TO psa_anon;
GRANT EXECUTE ON FUNCTION pxicv3djlauluse.create_admin(text, text) TO psa_anon;

-- Zugriffsrechte für authentifizierte Aufrufe
GRANT EXECUTE ON FUNCTION pxicv3djlauluse.change_password(text, text) TO psa_user;

-- login_attempts: kein direkter Zugriff (nur über authenticate())
REVOKE ALL ON pxicv3djlauluse.login_attempts FROM psa_user;
REVOKE ALL ON pxicv3djlauluse.login_attempts FROM psa_anon;
