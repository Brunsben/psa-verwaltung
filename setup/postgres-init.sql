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

-- Benutzer authentifizieren → JWT zurückgeben
CREATE OR REPLACE FUNCTION pxicv3djlauluse.authenticate(benutzername text, pin text)
  RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  u     record;
  token text;
BEGIN
  SELECT *
    INTO u
    FROM pxicv3djlauluse."Benutzer"
   WHERE lower("Benutzername") = lower(authenticate.benutzername)
     AND "PIN" = authenticate.pin
     AND "Aktiv" = true
   LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Benutzername oder Passwort falsch'
      USING ERRCODE = 'invalid_password';
  END IF;
  token := pxicv3djlauluse.jwt_sign(json_build_object(
    'role', 'psa_user',
    'sub',  u."Benutzername",
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
  INSERT INTO pxicv3djlauluse."Benutzer"
    ("Benutzername", "PIN", "Rolle", "Aktiv")
  VALUES
    (create_admin.benutzername, create_admin.pin, 'Admin', true)
  RETURNING * INTO u;
  token := pxicv3djlauluse.jwt_sign(json_build_object(
    'role', 'psa_user',
    'sub',  u."Benutzername",
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

-- Zugriffsrechte für anonyme Aufrufe (Login + First-Run-Check)
GRANT EXECUTE ON FUNCTION pxicv3djlauluse.authenticate(text, text) TO psa_anon;
GRANT EXECUTE ON FUNCTION pxicv3djlauluse.is_initialized() TO psa_anon;
GRANT EXECUTE ON FUNCTION pxicv3djlauluse.create_admin(text, text) TO psa_anon;
