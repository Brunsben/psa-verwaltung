-- ─────────────────────────────────────────────────────────────
--  postgres-jwt-lockdown.sql – Tabellenzugriff für psa_anon entfernen
--
--  WICHTIG: Erst ausführen, nachdem JWT-Authentifizierung erfolgreich getestet!
--  Nach diesem Script können Tabellen nur noch mit gültigem JWT abgerufen werden.
--
--  Ausführen auf dem Pi:
--    docker exec -i nocodb_postgres psql -U nocodb -d nocodb \
--      -f /dev/stdin < setup/postgres-jwt-lockdown.sql
-- ─────────────────────────────────────────────────────────────

-- Direkten Tabellenzugriff für anonyme Anfragen entfernen
REVOKE SELECT, INSERT, UPDATE, DELETE
  ON ALL TABLES IN SCHEMA pxicv3djlauluse FROM psa_anon;

REVOKE USAGE, SELECT
  ON ALL SEQUENCES IN SCHEMA pxicv3djlauluse FROM psa_anon;

-- psa_anon behält weiterhin USAGE auf dem Schema (für /rpc/-Aufrufe nötig)
-- und EXECUTE auf den drei RPC-Funktionen (authenticate, is_initialized, create_admin).
-- Diese nutzen SECURITY DEFINER → greifen intern als Funktionseigentümer zu.
