-- ─────────────────────────────────────────────────────────────
--  postgres-food.sql – FoodBot Schema (fw_food)
--
--  Essensanmeldung für die Feuerwehr.
--  Setzt fw_common voraus (members, accounts, auth).
--
--  Aufruf:
--    psql -v jwt_secret="..." -v postgrest_password="..." \
--         -f postgres-common.sql -f postgres-food.sql
-- ─────────────────────────────────────────────────────────────

-- ── Schema ────────────────────────────────────────────────────────────────
CREATE SCHEMA IF NOT EXISTS fw_food;

-- ── Grants ────────────────────────────────────────────────────────────────
GRANT USAGE ON SCHEMA fw_food TO psa_anon;
GRANT USAGE ON SCHEMA fw_food TO psa_user;

-- ── Menüs ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_food.menus (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  datum                 DATE NOT NULL UNIQUE,
  beschreibung          TEXT NOT NULL,
  zwei_menues_aktiv     BOOLEAN NOT NULL DEFAULT false,
  menu1_name            TEXT,
  menu2_name            TEXT,
  anmeldefrist          TEXT DEFAULT '19:45',     -- Format "HH:MM"
  frist_aktiv           BOOLEAN NOT NULL DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_menus_datum ON fw_food.menus(datum);

-- ── Anmeldungen ───────────────────────────────────────────────────────────
-- Verknüpft mit fw_common.members statt eigener User-Tabelle
CREATE TABLE IF NOT EXISTS fw_food.registrations (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id             UUID NOT NULL REFERENCES fw_common.members(id) ON DELETE CASCADE,
  datum                 DATE NOT NULL DEFAULT CURRENT_DATE,
  menu_wahl             INTEGER NOT NULL DEFAULT 1 CHECK (menu_wahl IN (1, 2)),
  created_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE (member_id, datum)
);

CREATE INDEX IF NOT EXISTS idx_reg_datum ON fw_food.registrations(datum);
CREATE INDEX IF NOT EXISTS idx_reg_member_datum ON fw_food.registrations(member_id, datum);

-- ── Gäste (nicht-Mitglieder) ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_food.guests (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  datum                 DATE NOT NULL DEFAULT CURRENT_DATE,
  menu_wahl             INTEGER NOT NULL DEFAULT 1 CHECK (menu_wahl IN (1, 2)),
  anzahl                INTEGER NOT NULL DEFAULT 0,
  UNIQUE (datum, menu_wahl)
);

CREATE INDEX IF NOT EXISTS idx_guests_datum ON fw_food.guests(datum);

-- ── RFID-Karten (Zuordnung Karte → Mitglied) ─────────────────────────────
-- Zentral für alle Apps nutzbar, aber primär vom FoodBot genutzt
CREATE TABLE IF NOT EXISTS fw_food.rfid_cards (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id               TEXT NOT NULL UNIQUE,
  member_id             UUID NOT NULL REFERENCES fw_common.members(id) ON DELETE CASCADE,
  created_at            TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_rfid_card ON fw_food.rfid_cards(card_id);
CREATE INDEX IF NOT EXISTS idx_rfid_member ON fw_food.rfid_cards(member_id);

-- ── Mobile-Tokens (QR-Code-basierte Anmeldung) ───────────────────────────
CREATE TABLE IF NOT EXISTS fw_food.mobile_tokens (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  member_id             UUID NOT NULL UNIQUE REFERENCES fw_common.members(id) ON DELETE CASCADE,
  token                 TEXT NOT NULL UNIQUE,
  created_at            TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mobile_token ON fw_food.mobile_tokens(token);

-- ── Vordefinierte Menüs ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_food.preset_menus (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL UNIQUE,
  sort_order            INTEGER NOT NULL DEFAULT 0
);

-- ── Admin-Log ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fw_food.admin_log (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zeitpunkt             TIMESTAMPTZ NOT NULL DEFAULT now(),
  admin_user            TEXT NOT NULL,
  aktion                TEXT NOT NULL,
  details               TEXT
);

CREATE INDEX IF NOT EXISTS idx_admin_log_zeit ON fw_food.admin_log(zeitpunkt);

-- ── updated_at Trigger ────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS menus_updated_at ON fw_food.menus;
CREATE TRIGGER menus_updated_at
  BEFORE UPDATE ON fw_food.menus
  FOR EACH ROW EXECUTE FUNCTION fw_common.update_timestamp();

-- ── Table Grants ──────────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA fw_food TO psa_user;

-- Anonymer Zugriff: nur Menü lesen + Anmeldung per API
GRANT SELECT ON fw_food.menus TO psa_anon;
GRANT SELECT ON fw_food.registrations TO psa_anon;
GRANT SELECT ON fw_food.guests TO psa_anon;
GRANT SELECT ON fw_food.rfid_cards TO psa_anon;
GRANT SELECT ON fw_food.mobile_tokens TO psa_anon;

-- ── RPC-Funktionen ────────────────────────────────────────────────────────

-- Heutigen Status abrufen (öffentlich)
CREATE OR REPLACE FUNCTION fw_food.today_status()
  RETURNS json LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  m         fw_food.menus;
  reg_count integer;
  guest_sum integer;
BEGIN
  SELECT * INTO m FROM fw_food.menus WHERE datum = CURRENT_DATE;

  SELECT count(*) INTO reg_count
    FROM fw_food.registrations WHERE datum = CURRENT_DATE;

  SELECT coalesce(sum(anzahl), 0) INTO guest_sum
    FROM fw_food.guests WHERE datum = CURRENT_DATE;

  RETURN json_build_object(
    'date',          CURRENT_DATE,
    'menu',          m.beschreibung,
    'zwei_menues',   coalesce(m.zwei_menues_aktiv, false),
    'menu1',         m.menu1_name,
    'menu2',         m.menu2_name,
    'deadline',      m.anmeldefrist,
    'deadline_active', coalesce(m.frist_aktiv, true),
    'registrations', reg_count,
    'guests',        guest_sum,
    'total',         reg_count + guest_sum
  );
END;
$$;

GRANT EXECUTE ON FUNCTION fw_food.today_status() TO psa_anon;

-- Per RFID-Karte an-/abmelden
CREATE OR REPLACE FUNCTION fw_food.register_by_card(p_card_id text, p_menu_wahl integer DEFAULT 1)
  RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_member_id uuid;
  v_member    record;
  v_menu      fw_food.menus;
  v_reg       fw_food.registrations;
  v_name      text;
BEGIN
  -- Karte → Mitglied
  SELECT rc.member_id INTO v_member_id
    FROM fw_food.rfid_cards rc WHERE rc.card_id = p_card_id;
  IF v_member_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Karte nicht registriert');
  END IF;

  SELECT * INTO v_member FROM fw_common.members WHERE id = v_member_id;
  v_name := coalesce(v_member."Vorname", '') || ' ' || coalesce(v_member."Name", '');

  -- Heutiges Menü
  SELECT * INTO v_menu FROM fw_food.menus WHERE datum = CURRENT_DATE;

  -- Frist prüfen
  IF v_menu.frist_aktiv AND v_menu.anmeldefrist IS NOT NULL THEN
    IF CURRENT_TIME > v_menu.anmeldefrist::time THEN
      -- Bestehende Anmeldung? Abmeldung nach Frist erlauben
      SELECT * INTO v_reg FROM fw_food.registrations
        WHERE member_id = v_member_id AND datum = CURRENT_DATE;
      IF NOT FOUND THEN
        RETURN json_build_object('success', false,
          'message', 'Anmeldefrist abgelaufen (' || v_menu.anmeldefrist || ' Uhr)');
      END IF;
    END IF;
  END IF;

  -- Toggle: bereits angemeldet → abmelden
  SELECT * INTO v_reg FROM fw_food.registrations
    WHERE member_id = v_member_id AND datum = CURRENT_DATE;

  IF FOUND THEN
    DELETE FROM fw_food.registrations WHERE id = v_reg.id;
    RETURN json_build_object(
      'success', true, 'registered', false,
      'name', trim(v_name), 'message', trim(v_name) || ' abgemeldet'
    );
  END IF;

  -- Zwei-Menü-Modus: Menüauswahl erforderlich
  IF v_menu.zwei_menues_aktiv AND p_menu_wahl IS NULL THEN
    RETURN json_build_object(
      'success', true, 'need_menu_choice', true,
      'name', trim(v_name),
      'menu1', v_menu.menu1_name, 'menu2', v_menu.menu2_name
    );
  END IF;

  -- Anmelden
  INSERT INTO fw_food.registrations (member_id, datum, menu_wahl)
    VALUES (v_member_id, CURRENT_DATE, coalesce(p_menu_wahl, 1));

  RETURN json_build_object(
    'success', true, 'registered', true,
    'name', trim(v_name), 'message', trim(v_name) || ' angemeldet'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION fw_food.register_by_card(text, integer) TO psa_anon;

-- Per Mobile-Token an-/abmelden
CREATE OR REPLACE FUNCTION fw_food.register_by_token(p_token text, p_menu_wahl integer DEFAULT 1)
  RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_member_id uuid;
BEGIN
  SELECT mt.member_id INTO v_member_id
    FROM fw_food.mobile_tokens mt WHERE mt.token = p_token;
  IF v_member_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Ungültiger Token');
  END IF;

  -- Delegieren an card-basierte Logik (gleiche Logik, anderes Lookup)
  -- Wir erstellen eine temporäre Karten-ID für die interne Verarbeitung
  RETURN fw_food.register_by_member(v_member_id, p_menu_wahl);
END;
$$;

GRANT EXECUTE ON FUNCTION fw_food.register_by_token(text, integer) TO psa_anon;

-- Per Member-ID an-/abmelden (interner Helper)
CREATE OR REPLACE FUNCTION fw_food.register_by_member(p_member_id uuid, p_menu_wahl integer DEFAULT 1)
  RETURNS json LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_member    record;
  v_menu      fw_food.menus;
  v_reg       fw_food.registrations;
  v_name      text;
BEGIN
  SELECT * INTO v_member FROM fw_common.members WHERE id = p_member_id;
  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'Mitglied nicht gefunden');
  END IF;

  v_name := coalesce(v_member."Vorname", '') || ' ' || coalesce(v_member."Name", '');
  SELECT * INTO v_menu FROM fw_food.menus WHERE datum = CURRENT_DATE;

  -- Frist prüfen
  IF v_menu IS NOT NULL AND v_menu.frist_aktiv AND v_menu.anmeldefrist IS NOT NULL THEN
    IF CURRENT_TIME > v_menu.anmeldefrist::time THEN
      SELECT * INTO v_reg FROM fw_food.registrations
        WHERE member_id = p_member_id AND datum = CURRENT_DATE;
      IF NOT FOUND THEN
        RETURN json_build_object('success', false,
          'message', 'Anmeldefrist abgelaufen (' || v_menu.anmeldefrist || ' Uhr)');
      END IF;
    END IF;
  END IF;

  -- Toggle
  SELECT * INTO v_reg FROM fw_food.registrations
    WHERE member_id = p_member_id AND datum = CURRENT_DATE;

  IF FOUND THEN
    DELETE FROM fw_food.registrations WHERE id = v_reg.id;
    RETURN json_build_object(
      'success', true, 'registered', false,
      'name', trim(v_name), 'message', trim(v_name) || ' abgemeldet'
    );
  END IF;

  IF v_menu IS NOT NULL AND v_menu.zwei_menues_aktiv AND p_menu_wahl IS NULL THEN
    RETURN json_build_object(
      'success', true, 'need_menu_choice', true,
      'name', trim(v_name),
      'menu1', v_menu.menu1_name, 'menu2', v_menu.menu2_name
    );
  END IF;

  INSERT INTO fw_food.registrations (member_id, datum, menu_wahl)
    VALUES (p_member_id, CURRENT_DATE, coalesce(p_menu_wahl, 1));

  RETURN json_build_object(
    'success', true, 'registered', true,
    'name', trim(v_name), 'message', trim(v_name) || ' angemeldet'
  );
END;
$$;

GRANT EXECUTE ON FUNCTION fw_food.register_by_member(uuid, integer) TO psa_anon;
