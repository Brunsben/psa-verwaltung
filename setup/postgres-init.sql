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
