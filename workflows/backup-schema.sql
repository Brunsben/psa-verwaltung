-- ─────────────────────────────────────────────────────────────
--  PSA-Verwaltung – Backup-Schema (MySQL / All-Inkl)
--  Ziel-Datenbank: d0465143 (phpMyAdmin auf All-Inkl)
--
--  Dieses Schema bildet die NocoDB-Tabellen auf dem Raspberry Pi
--  als MySQL-Backup ab. Spalten sind synchron mit nocodb-setup.sh.
--
--  Letzte Synchronisation: 2026-02-25
-- ─────────────────────────────────────────────────────────────

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ─── 1. Kameraden ────────────────────────────────────────────
-- Synchron mit: nocodb-setup.sh Tabelle "Kameraden"
CREATE TABLE IF NOT EXISTS kameraden (
  Id INT PRIMARY KEY AUTO_INCREMENT,
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  Name VARCHAR(100) NOT NULL,
  Vorname VARCHAR(100) NOT NULL,
  Email VARCHAR(255) DEFAULT NULL COMMENT 'Optional – für Prüfungs-Reminder per n8n',
  Jacke_Groesse VARCHAR(20) DEFAULT NULL,
  Hose_Groesse VARCHAR(20) DEFAULT NULL,
  Stiefel_Groesse INT DEFAULT NULL,
  Handschuh_Groesse VARCHAR(20) DEFAULT NULL,
  Aktiv TINYINT(1) DEFAULT 1,
  INDEX idx_aktiv (Aktiv),
  INDEX idx_name (Name, Vorname)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Feuerwehrkameraden mit Konfektionsgrößen';

-- ─── 2. Ausrüstungstypen ────────────────────────────────────
-- Synchron mit: nocodb-setup.sh Tabelle "Ausruestungstypen"
CREATE TABLE IF NOT EXISTS ausruestungstypen (
  Id INT PRIMARY KEY AUTO_INCREMENT,
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  Typ VARCHAR(100) NOT NULL COMMENT 'z.B. Jacke, Hose, Stiefel, Helm',
  Bezeichnung VARCHAR(255) NOT NULL,
  Hersteller VARCHAR(255) DEFAULT NULL,
  Norm VARCHAR(100) DEFAULT NULL COMMENT 'z.B. DIN EN 469, DIN EN 15090',
  Max_Lebensdauer_Jahre INT DEFAULT NULL,
  Pruefintervall_Monate INT DEFAULT NULL,
  Max_Waeschen INT DEFAULT NULL COMMENT 'Maximale Waschzyklen laut Hersteller',
  Beschreibung TEXT DEFAULT NULL,
  INDEX idx_typ (Typ),
  INDEX idx_norm (Norm)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ausrüstungskategorien mit Normen und Prüfintervallen';

-- ─── 3. Ausrüstungsstücke ───────────────────────────────────
-- Synchron mit: nocodb-setup.sh Tabelle "Ausruestungstuecke"
CREATE TABLE IF NOT EXISTS ausruestungstuecke (
  Id INT PRIMARY KEY AUTO_INCREMENT,
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  Ausruestungstyp VARCHAR(255) DEFAULT NULL COMMENT 'Referenz auf ausruestungstypen.Bezeichnung',
  Kamerad VARCHAR(255) DEFAULT NULL COMMENT 'Referenz auf kameraden (Name Vorname)',
  Seriennummer VARCHAR(100) DEFAULT NULL,
  QR_Code VARCHAR(255) DEFAULT NULL,
  Herstellungsdatum DATE DEFAULT NULL,
  Lebensende_Datum DATE DEFAULT NULL,
  Naechste_Pruefung DATE DEFAULT NULL,
  Status VARCHAR(50) DEFAULT 'Aktiv' COMMENT 'Aktiv, Ausgesondert, In Reparatur, Gesperrt',
  Notizen TEXT DEFAULT NULL,
  INDEX idx_status (Status),
  INDEX idx_naechste_pruefung (Naechste_Pruefung),
  INDEX idx_kamerad (Kamerad),
  INDEX idx_seriennummer (Seriennummer),
  INDEX idx_lebensende (Lebensende_Datum)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Einzelne Ausrüstungsstücke mit Zuweisung und Prüfstatus';

-- ─── 4. Ausgaben ─────────────────────────────────────────────
-- Synchron mit: nocodb-setup.sh Tabelle "Ausgaben"
-- Hinweis: NocoDB speichert Ausruestungstueck_Id, Kamerad, Ausruestungstyp,
--          Seriennummer als denormalisierte Felder (Lookup/Rollup).
CREATE TABLE IF NOT EXISTS ausgaben (
  Id INT PRIMARY KEY AUTO_INCREMENT,
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  Ausgabedatum DATE NOT NULL,
  Rueckgabedatum DATE DEFAULT NULL,
  Notizen TEXT DEFAULT NULL,
  Ausruestungstueck_Id INT DEFAULT NULL,
  Kamerad VARCHAR(255) DEFAULT NULL,
  Ausruestungstyp VARCHAR(255) DEFAULT NULL,
  Seriennummer VARCHAR(100) DEFAULT NULL,
  INDEX idx_ausgabe_datum (Ausgabedatum),
  INDEX idx_ausgabe_kamerad (Kamerad),
  INDEX idx_ausgabe_stueck (Ausruestungstueck_Id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Ausgabe-/Rückgabe-Protokoll für Ausrüstungsstücke';

-- ─── 5. Prüfungen ────────────────────────────────────────────
-- Synchron mit: nocodb-setup.sh Tabelle "Pruefungen"
CREATE TABLE IF NOT EXISTS pruefungen (
  Id INT PRIMARY KEY AUTO_INCREMENT,
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  Datum DATE NOT NULL,
  Ergebnis VARCHAR(50) DEFAULT NULL COMMENT 'Bestanden, Nicht bestanden, Bedingt bestanden',
  Pruefer VARCHAR(255) DEFAULT NULL,
  Naechste_Pruefung DATE DEFAULT NULL,
  Notizen TEXT DEFAULT NULL,
  Ausruestungstueck_Id INT DEFAULT NULL,
  Kamerad VARCHAR(255) DEFAULT NULL,
  Ausruestungstyp VARCHAR(255) DEFAULT NULL,
  Seriennummer VARCHAR(100) DEFAULT NULL,
  INDEX idx_pruef_datum (Datum),
  INDEX idx_pruef_naechste (Naechste_Pruefung),
  INDEX idx_pruef_ergebnis (Ergebnis),
  INDEX idx_pruef_stueck (Ausruestungstueck_Id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Prüfprotokolle mit Ergebnis und nächstem Termin';

-- ─── 6. Wäsche ───────────────────────────────────────────────
-- Synchron mit: nocodb-setup.sh Tabelle "Waesche"
CREATE TABLE IF NOT EXISTS waesche (
  Id INT PRIMARY KEY AUTO_INCREMENT,
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  Datum DATE NOT NULL,
  Waescheart VARCHAR(50) DEFAULT NULL COMMENT 'Industriewäsche, Handwäsche, Imprägnierung',
  Notizen TEXT DEFAULT NULL,
  Ausruestungstueck_Id INT DEFAULT NULL,
  Kamerad VARCHAR(255) DEFAULT NULL,
  Ausruestungstyp VARCHAR(255) DEFAULT NULL,
  Seriennummer VARCHAR(100) DEFAULT NULL,
  INDEX idx_waesche_datum (Datum),
  INDEX idx_waesche_stueck (Ausruestungstueck_Id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Waschprotokoll – relevant für Max_Waeschen Tracking';

-- ─── 7. Normen ────────────────────────────────────────────────
-- Synchron mit: nocodb-setup.sh Tabelle "Normen"
CREATE TABLE IF NOT EXISTS normen (
  Id INT PRIMARY KEY AUTO_INCREMENT,
  CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
  UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  Bezeichnung VARCHAR(255) NOT NULL COMMENT 'z.B. DIN EN 443:2008, DIN EN 469:2020',
  Beschreibung TEXT DEFAULT NULL,
  Pruefintervall_Monate INT DEFAULT NULL,
  Max_Lebensdauer_Jahre INT DEFAULT NULL,
  Ausruestungstyp_Kategorie VARCHAR(100) DEFAULT NULL COMMENT 'z.B. Helm, Jacke, Hose, Stiefel, Handschuh',
  Max_Waeschen INT DEFAULT NULL COMMENT 'Maximale Waschzyklen laut Norm',
  INDEX idx_norm_kategorie (Ausruestungstyp_Kategorie),
  INDEX idx_norm_bezeichnung (Bezeichnung)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='DIN-Normen für Ausrüstungstypen mit Prüf- und Lebensdauer-Vorgaben';

SET FOREIGN_KEY_CHECKS = 1;

-- ─────────────────────────────────────────────────────────────
--  Nützliche Views für Auswertungen
-- ─────────────────────────────────────────────────────────────

-- Überfällige Prüfungen (Dashboard-Warnung)
CREATE OR REPLACE VIEW v_ueberfaellige_pruefungen AS
SELECT
  a.Id,
  a.Seriennummer,
  a.Ausruestungstyp,
  a.Kamerad,
  a.Naechste_Pruefung,
  DATEDIFF(CURDATE(), a.Naechste_Pruefung) AS Tage_ueberfaellig
FROM ausruestungstuecke a
WHERE a.Status = 'Aktiv'
  AND a.Naechste_Pruefung < CURDATE()
ORDER BY a.Naechste_Pruefung ASC;

-- Ausrüstung nahe Lebensende (≤ 90 Tage)
CREATE OR REPLACE VIEW v_lebensende_bald AS
SELECT
  a.Id,
  a.Seriennummer,
  a.Ausruestungstyp,
  a.Kamerad,
  a.Lebensende_Datum,
  DATEDIFF(a.Lebensende_Datum, CURDATE()) AS Tage_verbleibend
FROM ausruestungstuecke a
WHERE a.Status = 'Aktiv'
  AND a.Lebensende_Datum IS NOT NULL
  AND a.Lebensende_Datum <= DATE_ADD(CURDATE(), INTERVAL 90 DAY)
ORDER BY a.Lebensende_Datum ASC;

-- Waschzähler pro Ausrüstungsstück
CREATE OR REPLACE VIEW v_waschzaehler AS
SELECT
  w.Ausruestungstueck_Id,
  w.Seriennummer,
  w.Ausruestungstyp,
  COUNT(*) AS Anzahl_Waeschen,
  MAX(w.Datum) AS Letzte_Waesche
FROM waesche w
WHERE w.Ausruestungstueck_Id IS NOT NULL
GROUP BY w.Ausruestungstueck_Id, w.Seriennummer, w.Ausruestungstyp;
