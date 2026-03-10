-- migration-changelog-policy.sql
-- Verschaerft die Changelog INSERT-Policy: Benutzer duerfen nur Eintraege
-- mit ihrem eigenen Namen einfuegen (verhindert Spoofing).
-- Admins/Kleiderwarte duerfen weiterhin fuer andere eintragen.
--
-- Ausfuehren: cat setup/migration-changelog-policy.sql | docker compose exec -T postgres psql -U nocodb -d nocodb
-- Bereits angewendet auf Produktion am 2025-07-03.

BEGIN;

DROP POLICY IF EXISTS changelog_insert ON pxicv3djlauluse."Changelog";
CREATE POLICY changelog_insert ON pxicv3djlauluse."Changelog"
  FOR INSERT TO psa_user
  WITH CHECK (
    "Benutzer" = current_setting('request.jwt.claim.sub', true)
    OR pxicv3djlauluse.current_app_role() IN ('Admin', 'Kleiderwart')
  );

COMMIT;
