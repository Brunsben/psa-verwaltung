-- PSA-Verwaltung Backup Schema
-- In All-Inkl phpMyAdmin auf Datenbank d0465143 ausführen

CREATE TABLE IF NOT EXISTS kameraden (
  Id INT PRIMARY KEY,
  CreatedAt DATETIME,
  UpdatedAt DATETIME,
  Name VARCHAR(255),
  Vorname VARCHAR(255),
  Email VARCHAR(255),
  Jacke_Groesse VARCHAR(255),
  Hose_Groesse VARCHAR(255),
  Stiefel_Groesse INT,
  Handschuh_Groesse VARCHAR(255),
  Aktiv TINYINT(1) DEFAULT 0,
  Hemd_Groesse VARCHAR(255),
  Poloshirt_Groesse VARCHAR(255),
  Fleece_Groesse VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ausruestungstypen (
  Id INT PRIMARY KEY,
  CreatedAt DATETIME,
  UpdatedAt DATETIME,
  Bezeichnung VARCHAR(255),
  Norm VARCHAR(255),
  Max_Lebensdauer_Jahre INT,
  Pruefintervall_Monate INT,
  Beschreibung TEXT,
  Typ VARCHAR(100),
  Hersteller VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ausruestungstuecke (
  Id INT PRIMARY KEY,
  CreatedAt DATETIME,
  UpdatedAt DATETIME,
  Seriennummer VARCHAR(255),
  QR_Code VARCHAR(255),
  Herstellungsdatum DATE,
  Lebensende_Datum DATE,
  Status VARCHAR(100),
  Notizen TEXT,
  Kamerad VARCHAR(255),
  Naechste_Pruefung DATE,
  Ausruestungstyp VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS ausgaben (
  Id INT PRIMARY KEY,
  CreatedAt DATETIME,
  UpdatedAt DATETIME,
  Ausgabedatum DATE,
  Rueckgabedatum DATE,
  Notizen TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS pruefungen (
  Id INT PRIMARY KEY,
  CreatedAt DATETIME,
  UpdatedAt DATETIME,
  Datum DATE,
  Ergebnis VARCHAR(100),
  Pruefer VARCHAR(255),
  Naechste_Pruefung DATE,
  Notizen TEXT,
  Ausruestungstueck_Id INT,
  Kamerad VARCHAR(255),
  Ausruestungstyp VARCHAR(255),
  Seriennummer VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS normen (
  Id INT PRIMARY KEY,
  CreatedAt DATETIME,
  UpdatedAt DATETIME,
  Bezeichnung VARCHAR(255),
  Beschreibung TEXT,
  Pruefintervall_Monate INT,
  Max_Lebensdauer_Jahre INT,
  Ausruestungstyp_Kategorie VARCHAR(100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS waesche (
  Id INT PRIMARY KEY,
  CreatedAt DATETIME,
  UpdatedAt DATETIME,
  Datum DATE,
  Waescheart VARCHAR(100),
  Notizen TEXT,
  Ausruestungstueck_Id INT,
  Kamerad VARCHAR(255),
  Ausruestungstyp VARCHAR(255),
  Seriennummer VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
