-- ─────────────────────────────────────────────────────────────
--  postgres-fk.sql – Führerscheinkontrolle Schema (fw_fuehrerschein)
--
--  Tabellen für die Führerscheinkontrolle-App.
--  Setzt voraus: fw_common (postgres-common.sql)
--
--  Aufruf:
--    psql -v postgrest_password="..." -v jwt_secret="..." \
--         -f postgres-common.sql -f postgres-fk.sql
-- ─────────────────────────────────────────────────────────────

-- ── Schema ────────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS fw_fuehrerschein;

-- ── fw_common.members Erweiterungen ──────────────────────────
-- Telefon und Geburtsdatum sind allgemeine Mitgliederdaten.
-- Falls die Spalten schon existieren, ignorieren.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'fw_common' AND table_name = 'members' AND column_name = 'Telefon'
  ) THEN
    ALTER TABLE fw_common.members ADD COLUMN "Telefon" TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'fw_common' AND table_name = 'members' AND column_name = 'Geburtsdatum'
  ) THEN
    ALTER TABLE fw_common.members ADD COLUMN "Geburtsdatum" TEXT;
  END IF;
END $$;

-- ── Mitglieder-Profile (FK-spezifisch) ──────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.member_profiles (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id             UUID NOT NULL UNIQUE
                          REFERENCES fw_common.members(id) ON DELETE CASCADE,
  consent_given         BOOLEAN NOT NULL DEFAULT false,
  must_change_password  BOOLEAN NOT NULL DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

-- ── Führerscheinklassen ─────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.license_classes (
  id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code                            TEXT NOT NULL UNIQUE,
  name                            TEXT NOT NULL,
  description                     TEXT,
  is_expiring                     BOOLEAN NOT NULL DEFAULT false,
  default_check_interval_months   INTEGER NOT NULL DEFAULT 6,
  default_validity_years          INTEGER,
  sort_order                      INTEGER NOT NULL DEFAULT 0
);

-- ── Mitglieder-Führerscheinklassen ──────────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.member_licenses (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id             UUID NOT NULL
                          REFERENCES fw_common.members(id) ON DELETE CASCADE,
  license_class_id      UUID NOT NULL
                          REFERENCES fw_fuehrerschein.license_classes(id),
  issue_date            TEXT,
  expiry_date           TEXT,
  check_interval_months INTEGER NOT NULL DEFAULT 6,
  notes                 TEXT,
  restriction_188       BOOLEAN NOT NULL DEFAULT false,
  created_at            TIMESTAMPTZ DEFAULT now()
);

-- ── Kontrollprotokoll ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.license_checks (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id             UUID NOT NULL
                          REFERENCES fw_common.members(id) ON DELETE CASCADE,
  checked_by_member_id  UUID
                          REFERENCES fw_common.members(id),
  check_date            TEXT NOT NULL,
  check_type            TEXT NOT NULL
                          CHECK (check_type IN ('photo_upload', 'in_person')),
  result                TEXT NOT NULL DEFAULT 'pending'
                          CHECK (result IN ('pending', 'approved', 'rejected')),
  rejection_reason      TEXT,
  next_check_due        TEXT,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT now()
);

-- ── Hochgeladene Dateien (verschlüsselt) ────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.uploaded_files (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  check_id          UUID NOT NULL
                      REFERENCES fw_fuehrerschein.license_checks(id) ON DELETE CASCADE,
  member_id         UUID NOT NULL
                      REFERENCES fw_common.members(id) ON DELETE CASCADE,
  file_path         TEXT NOT NULL,
  original_filename TEXT NOT NULL,
  mime_type         TEXT NOT NULL,
  file_size         INTEGER,
  side              TEXT NOT NULL CHECK (side IN ('front', 'back')),
  auto_delete_after TEXT,
  uploaded_at       TIMESTAMPTZ DEFAULT now()
);

-- ── DSGVO-Einwilligungen ────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.consent_records (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id       UUID NOT NULL
                    REFERENCES fw_common.members(id) ON DELETE CASCADE,
  consent_type    TEXT NOT NULL
                    CHECK (consent_type IN ('data_processing', 'email_notifications', 'photo_upload')),
  given           BOOLEAN NOT NULL DEFAULT false,
  given_at        TEXT,
  withdrawn_at    TEXT,
  policy_version  TEXT NOT NULL,
  method          TEXT NOT NULL DEFAULT 'web_form',
  ip_address      TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- ── Benachrichtigungs-Log ───────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.notifications_log (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id     UUID NOT NULL
                  REFERENCES fw_common.members(id) ON DELETE CASCADE,
  type          TEXT NOT NULL
                  CHECK (type IN (
                    'check_reminder_4w', 'check_reminder_1w', 'check_overdue',
                    'license_expiry_3m', 'license_expiry_1m', 'license_expired',
                    'admin_summary'
                  )),
  subject       TEXT,
  sent_at       TIMESTAMPTZ DEFAULT now(),
  status        TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('sent', 'failed', 'pending')),
  error_message TEXT
);

-- ── Audit-Log ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.audit_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id   UUID REFERENCES fw_common.members(id),
  action      TEXT NOT NULL,
  entity_type TEXT,
  entity_id   TEXT,
  details     TEXT,
  ip_address  TEXT,
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ── App-Einstellungen ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_fuehrerschein.app_settings (
  key        TEXT PRIMARY KEY,
  value      TEXT NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ── Indizes ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_fk_member_licenses_member
  ON fw_fuehrerschein.member_licenses(member_id);
CREATE INDEX IF NOT EXISTS idx_fk_license_checks_member
  ON fw_fuehrerschein.license_checks(member_id);
CREATE INDEX IF NOT EXISTS idx_fk_license_checks_next_due
  ON fw_fuehrerschein.license_checks(next_check_due);
CREATE INDEX IF NOT EXISTS idx_fk_uploaded_files_check
  ON fw_fuehrerschein.uploaded_files(check_id);
CREATE INDEX IF NOT EXISTS idx_fk_uploaded_files_auto_delete
  ON fw_fuehrerschein.uploaded_files(auto_delete_after);
CREATE INDEX IF NOT EXISTS idx_fk_consent_records_member
  ON fw_fuehrerschein.consent_records(member_id);
CREATE INDEX IF NOT EXISTS idx_fk_audit_log_member
  ON fw_fuehrerschein.audit_log(member_id);
CREATE INDEX IF NOT EXISTS idx_fk_audit_log_created
  ON fw_fuehrerschein.audit_log(created_at);

-- ── updated_at Trigger ──────────────────────────────────────
-- Nutzt fw_common.update_timestamp() (bereits vorhanden)
DROP TRIGGER IF EXISTS fk_profiles_updated_at ON fw_fuehrerschein.member_profiles;
CREATE TRIGGER fk_profiles_updated_at
  BEFORE UPDATE ON fw_fuehrerschein.member_profiles
  FOR EACH ROW EXECUTE FUNCTION fw_common.update_timestamp();

-- ── Grants ──────────────────────────────────────────────────
GRANT USAGE ON SCHEMA fw_fuehrerschein TO psa_user;
GRANT USAGE ON SCHEMA fw_fuehrerschein TO psa_anon;

GRANT SELECT, INSERT, UPDATE, DELETE
  ON ALL TABLES IN SCHEMA fw_fuehrerschein TO psa_user;

-- Anon darf nur Führerscheinklassen lesen (für öffentliche Info)
GRANT SELECT ON fw_fuehrerschein.license_classes TO psa_anon;

-- ── Standard-Führerscheinklassen ────────────────────────────
INSERT INTO fw_fuehrerschein.license_classes (code, name, description, is_expiring, default_check_interval_months, default_validity_years, sort_order)
VALUES
  ('AM',    'Klasse AM',    'Kleinkrafträder, Fahrräder mit Hilfsmotor', false, 6, NULL, 1),
  ('A1',    'Klasse A1',    'Leichtkrafträder bis 125 cm³',              false, 6, NULL, 2),
  ('A2',    'Klasse A2',    'Krafträder bis 35 kW',                      false, 6, NULL, 3),
  ('A',     'Klasse A',     'Krafträder ohne Leistungsbegrenzung',       false, 6, NULL, 4),
  ('B',     'Klasse B',     'Kfz bis 3.500 kg, bis 8 Personen + Fahrer', false, 6, NULL, 5),
  ('BE',    'Klasse BE',    'B + Anhänger > 750 kg',                      false, 6, NULL, 6),
  ('C1',    'Klasse C1',    'Kfz 3.500–7.500 kg',                        true,  6, 5,    7),
  ('C1E',   'Klasse C1E',   'C1 + Anhänger > 750 kg',                    true,  6, 5,    8),
  ('C',     'Klasse C',     'Kfz über 3.500 kg (unbegrenzt)',             true,  6, 5,    9),
  ('CE',    'Klasse CE',    'C + Anhänger > 750 kg',                      true,  6, 5,   10),
  ('L',     'Klasse L',     'Land-/forstwirtschaftliche Zugmaschinen bis 40 km/h', false, 6, NULL, 11),
  ('T',     'Klasse T',     'Land-/forstwirtschaftliche Zugmaschinen bis 60 km/h', false, 6, NULL, 12),
  ('3_ALT', 'Klasse 3 (alt)', 'Alt-FS vor 1999: B, BE, C1, C1E + CE beschränkt (befristet bis 50. Lj.)', true, 6, NULL, 13),
  ('FF',    'Feuerwehrführerschein (Nds.)', 'Sonderfahrberechtigung gem. §2 Abs. 16 StVG / Nds.', false, 0, NULL, 14)
ON CONFLICT (code) DO NOTHING;

-- ── Standard-Einstellungen ──────────────────────────────────
INSERT INTO fw_fuehrerschein.app_settings (key, value)
VALUES
  ('check_interval_months', '6'),
  ('reminder_weeks_before', '4'),
  ('reminder_weeks_before_2', '1'),
  ('license_expiry_warning_months', '3'),
  ('photo_auto_delete_days', '30'),
  ('privacy_policy_version', '1.0'),
  ('fire_department_name', 'Freiwillige Feuerwehr')
ON CONFLICT (key) DO NOTHING;
