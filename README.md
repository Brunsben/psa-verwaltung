# PSA-Verwaltung – Freiwillige Feuerwehr

Webbasierte Verwaltungssoftware für persönliche Schutzausrüstung (PSA) bei Freiwilligen Feuerwehren. Verwaltet Ausrüstungsstücke, Kameraden, Prüftermine, Ausgaben, Wäschen und DIN-Normen – läuft komplett selbst gehostet auf einem Raspberry Pi oder jedem Linux-Server.

## Features

- **Dashboard** mit Statistiken, Diagrammen und Warnungen (überfällige Prüfungen, Lebensende, Wäschlimit)
- **Kameraden** – Konfektionsgrößen für Jacke, Hose, Stiefel, Handschuh, Hemd, Poloshirt, Fleece
- **Ausrüstung** – Seriennummer, QR-Code, Größe, Status, Lebensende, nächste Prüfung
- **Ausrüstungstypen** – mit Norm, Prüfintervall, Lebensdauer, max. Wäschen
- **Normen** – DIN-Normen-Bibliothek (EN 469, EN 15090, EN 659 etc.)
- **Prüfungen, Ausgaben, Wäschen** erfassen und nachverfolgen
- **QR-Code**-Scanner zum schnellen Auffinden von Ausrüstungsstücken
- **CSV-Export** der Ausrüstungsliste
- **Dark / Light Mode**, Filterfunktion, Sortierfunktion
- **n8n-Automatisierung**: wöchentliche Prüfungs- und Wäschlimit-Reminder per E-Mail, Lebensende-Warnung, tägliches MySQL-Backup

## Architektur

```text
Browser → nginx (Port 8182)
                │
                ├── /          → Vue 3 SPA (Vite-Build, dist/)
                └── /api/      → NocoDB (Port 8181, API-Token wird server-seitig ergänzt)
                                        │
                                        └── PostgreSQL 17
```

**Docker Compose** mit 3 Containern: `nocodb`, `postgres`, `frontend` (nginx mit Vite-Build).
Das Frontend wird beim Deployment via `docker compose up --build` gebaut (Node 22 → nginx:1.28-alpine).

## Voraussetzungen

| Software | Mindestversion |
| --- | --- |
| Docker | 24+ |
| Docker Compose Plugin | v2 (`docker compose`) |
| `curl` | beliebig |
| `python3` | 3.6+ |
| `envsubst` | (Paket `gettext-base`) |

Auf **Raspberry Pi OS / Ubuntu / Debian**:

```bash
sudo apt update && sudo apt install -y curl python3 gettext-base
# Docker: https://docs.docker.com/engine/install/
```

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/Brunsben/psa-verwaltung.git
cd psa-verwaltung
```

### 2. Installationsskript ausführen

```bash
cd setup
bash install.sh
```

Das Skript erledigt alles automatisch:

1. Prüft alle Voraussetzungen
2. Erzeugt `.env` mit zufällig generierten Passwörtern
3. Startet alle Docker-Container (inkl. Frontend-Build)
4. Wartet bis NocoDB bereit ist
5. **Fragt interaktiv nach dem API-Token** (einmaliger manueller Schritt)
6. Erstellt alle 9 Datenbank-Tabellen
7. Schreibt die Konfiguration in `frontend/config.js`

> **Einziger manueller Schritt:** Das Skript pausiert und zeigt die NocoDB-URL an.
> Öffne diese, erstelle ein Admin-Konto, erzeuge einen API-Token und füge ihn im Terminal ein.

Die App ist danach erreichbar unter `http://SERVER-IP:8182`.

## Datenbanktabellen

| Tabelle | Inhalt |
| --- | --- |
| Kameraden | Feuerwehrangehörige mit Konfektionsgrößen |
| Ausruestungstypen | PSA-Kategorien mit Norm, Prüfintervall, Lebensdauer |
| Ausruestungstuecke | Einzelne Ausrüstungsstücke mit QR-Code und Größe |
| Ausgaben | Ausgabe- und Rückgabeprotokoll |
| Pruefungen | Prüfprotokolle mit Ergebnis und nächstem Termin |
| Waesche | Waschzyklen pro Ausrüstungsstück |
| Normen | DIN-Normen-Bibliothek |
| Benutzer | Benutzerkonten (PIN-Authentifizierung) |
| Changelog | Audit-Log aller Änderungen |

## Updates

```bash
git pull
cd setup
./configure-frontend.sh   # config.js aktualisieren (falls neue Tabellen)
docker compose up -d --build
```

> **Wichtig:** `docker compose restart` reicht nicht – das Frontend muss neu gebaut werden.

## n8n-Automatisierung

Im Verzeichnis `workflows/` liegen vier n8n-Workflows:

| Datei | Trigger | Funktion |
| --- | --- | --- |
| `psa-pruefungs-reminder-woechentlich.json` | Mo 07:00 | E-Mail bei Prüfungen ≤ 30 Tage |
| `psa-waeschlimit-reminder.json` | Mo 07:00 | E-Mail bei ≥ 90 % Wäschlimit |
| `psa-lebensende-warnung.json` | Mo 08:00 | E-Mail bei Lebensende ≤ 180 Tage |
| `psa-backup-mysql.json` | täglich 02:00 | Vollbackup NocoDB → MySQL |

Import in n8n über **Workflow → Import from file**.

## Verzeichnisstruktur

```text
psa-verwaltung/
├── frontend/
│   ├── src/                    # Vue 3 SFCs (store.js, App.vue, pages/, components/)
│   ├── public/                 # Statische Assets (vendor/, icons/, manifest.json)
│   ├── Dockerfile              # Multi-stage Build: Node 22 → nginx:1.28
│   ├── vite.config.js
│   └── package.json
├── setup/
│   ├── docker-compose.yml      # Container-Konfiguration
│   ├── nginx.conf.template     # nginx mit XC_TOKEN-Injection
│   ├── .env.example            # Vorlage für Umgebungsvariablen
│   ├── install.sh              # Hauptinstallationsskript
│   ├── nocodb-setup.sh         # Erstellt NocoDB-Tabellen via API
│   ├── configure-frontend.sh   # Schreibt Table-IDs in config.js
│   ├── add-groesse-field.sh    # Migration: Groesse-Spalte ergänzen
│   └── add-normen.sh           # Befüllt Normen-Tabelle mit Feuerwehr-PSA-Normen
├── workflows/
│   ├── psa-pruefungs-reminder-woechentlich.json
│   ├── psa-waeschlimit-reminder.json
│   ├── psa-lebensende-warnung.json
│   ├── psa-backup-mysql.json
│   └── backup-schema.sql       # MySQL-Schema für Backup-Datenbank
└── README.md
```

## Lizenz

MIT – Frei verwendbar und anpassbar.
