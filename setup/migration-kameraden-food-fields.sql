-- ══════════════════════════════════════════════════════════════
-- Migration: Personalnummer + KartenID für Kameraden
-- Zentrale Mitgliederdaten für FoodBot und andere Apps
-- ══════════════════════════════════════════════════════════════

BEGIN;

-- Neue Spalten hinzufügen
ALTER TABLE pxicv3djlauluse."Kameraden"
  ADD COLUMN IF NOT EXISTS "Personalnummer" TEXT,
  ADD COLUMN IF NOT EXISTS "KartenID" TEXT;

-- Unique-Constraints (nur für nicht-NULL-Werte)
CREATE UNIQUE INDEX IF NOT EXISTS idx_kameraden_personalnummer
  ON pxicv3djlauluse."Kameraden" ("Personalnummer")
  WHERE "Personalnummer" IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_kameraden_karten_id
  ON pxicv3djlauluse."Kameraden" ("KartenID")
  WHERE "KartenID" IS NOT NULL;

COMMIT;
