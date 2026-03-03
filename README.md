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
                └── /api/      → PostgREST (Port 3000, Docker-intern)
                                        │
                                        └── PostgreSQL 17
```

**Docker Compose** mit 3 Containern: `postgrest`, `postgres`, `frontend` (nginx mit Vite-Build).
Das Frontend wird beim Deployment via `docker compose up --build` gebaut (Node 22 → nginx:1.28-alpine).

## Voraussetzungen

| Software | Mindestversion |
| --- | --- |
| Docker | 24+ |
| Docker Compose Plugin | v2 (`docker compose`) |
| `curl` | beliebig |

Auf **Raspberry Pi OS / Ubuntu / Debian**:

```bash
sudo apt update && sudo apt install -y curl
# Docker: https://docs.docker.com/engine/install/
```

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/Brunsben/psa-verwaltung.git
cd psa-verwaltung
```

### 2. Umgebungsvariablen anlegen

```bash
cp setup/.env.example setup/.env
# .env bearbeiten: POSTGRES_PASSWORD und POSTGREST_DB_PASSWORD setzen
```

### 3. PostgreSQL-Rollen anlegen (einmalig)

```bash
cd setup
docker compose up -d postgres
docker exec nocodb_postgres psql -U nocodb -d nocodb \
  -c "CREATE ROLE psa_anon NOLOGIN;" \
  -c "GRANT USAGE ON SCHEMA pxicv3djlauluse TO psa_anon;" \
  -c "GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA pxicv3djlauluse TO psa_anon;" \
  -c "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA pxicv3djlauluse TO psa_anon;" \
  -c "CREATE ROLE psa_auth NOINHERIT LOGIN PASSWORD 'DEIN_PASSWORT';" \
  -c "GRANT psa_anon TO psa_auth;"
```

### 4. Frontend konfigurieren und starten

```bash
./configure-frontend.sh
docker compose up -d --build
```

Die App ist danach erreichbar unter `http://SERVER-IP:8182`.
Beim ersten Aufruf wird ein Admin-Account angelegt.

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
./configure-frontend.sh
docker compose up -d --build
```

> **Hinweis:** Nach einem Deployment den Cloudflare Cache leeren falls die App via Cloudflare Tunnel erreichbar ist (Dashboard → Domain → Caching → Purge Everything).

## n8n-Automatisierung

Im Verzeichnis `workflows/` liegen n8n-Workflows:

| Datei | Trigger | Funktion |
| --- | --- | --- |
| `psa-pruefungs-reminder-woechentlich.json` | Mo 07:00 | E-Mail bei Prüfungen ≤ 30 Tage |
| `psa-pruefungs-reminder-pro-kamerad.json` | Mo 07:30 | Prüfungs-Reminder je Kamerad |
| `psa-waeschlimit-reminder.json` | Mo 07:00 | E-Mail bei ≥ 90 % Wäschlimit |
| `psa-lebensende-warnung.json` | Mo 08:00 | E-Mail bei Lebensende ≤ 180 Tage |
| `psa-backup-mysql.json` | täglich 02:00 | Vollbackup PostgreSQL → MySQL |
| `psa-backup-fehler-benachrichtigung.json` | Error-Trigger | E-Mail bei Backup-Fehler |

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
│   ├── docker-compose.yml      # Container-Konfiguration (postgrest, postgres, frontend)
│   ├── nginx.conf.template     # nginx-Konfiguration
│   ├── .env.example            # Vorlage für Umgebungsvariablen
│   ├── install.sh              # Installationsskript
│   ├── configure-frontend.sh   # Schreibt frontend/config.js
│   └── nginx-ratelimit.conf    # Rate-Limiting-Konfiguration
├── workflows/
│   ├── psa-pruefungs-reminder-woechentlich.json
│   ├── psa-pruefungs-reminder-pro-kamerad.json
│   ├── psa-waeschlimit-reminder.json
│   ├── psa-lebensende-warnung.json
│   ├── psa-backup-mysql.json
│   ├── psa-backup-fehler-benachrichtigung.json
│   └── backup-schema.sql       # MySQL-Schema für Backup-Datenbank
└── README.md
```

## Lizenz

MIT – Frei verwendbar und anpassbar.
