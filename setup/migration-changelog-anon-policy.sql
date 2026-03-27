-- Policy für n8n-Backup: Erlaubt psa_anon INSERT auf Changelog, aber NUR mit Benutzer='n8n-auto'
DROP POLICY IF EXISTS changelog_anon_insert ON pxicv3djlauluse."Changelog";

CREATE POLICY changelog_anon_insert ON pxicv3djlauluse."Changelog" FOR
INSERT
    TO psa_anon WITH CHECK ("Benutzer" = 'n8n-auto');

-- Auch SELECT für psa_anon (Backup braucht Lese-Zugriff)
DROP POLICY IF EXISTS changelog_anon_select ON pxicv3djlauluse."Changelog";

CREATE POLICY changelog_anon_select ON pxicv3djlauluse."Changelog" FOR
SELECT
    TO psa_anon USING (true);