# PSA-Verwaltung – Freiwillige Feuerwehr

Webbasierte Verwaltungssoftware für persönliche Schutzausrüstung (PSA) bei Freiwilligen Feuerwehren. Verwaltet Ausrüstungsstücke, Kameraden, Prüftermine, Ausgaben und Wäschen – läuft komplett selbst gehostet auf einem Raspberry Pi oder jedem Linux-Server.

## Features

- **Dashboard** mit Statistiken und Warnungen (überfällige Prüfungen, Lebensende)
- **Kameraden** – Größenangaben für Jacke, Hose, Stiefel, Handschuh
- **Ausrüstung** – Seriennummer, QR-Code, Status, Lebensende, nächste Prüfung
- **Ausrüstungstypen** – mit Norm (DIN EN 469 etc.) und Prüfintervallen
- **Prüfungen, Ausgaben, Wäschen** erfassen
- **Dark / Light Mode** (wird gespeichert)
- **Filterfunktion** nach Status und Freitext

## Architektur

```
Browser → nginx (Port 8182)
                │
                ├── /          → frontend/index.html (Vue.js 3, Tailwind CSS)
                └── /api/      → NocoDB (Port 8181, API-Token wird server-seitig ergänzt)
                                        │
                                        └── PostgreSQL 15
```

Alles läuft per **Docker Compose** ohne Build-Schritt. Die gesamte Frontend-Logik steckt in einer einzigen `frontend/index.html`.

## Voraussetzungen

| Software | Mindestversion |
|---|---|
| Docker | 24+ |
| Docker Compose Plugin | v2 (`docker compose`) |
| `curl` | beliebig |
| `python3` | 3.6+ |
| `envsubst` | (Paket `gettext-base`) |

Auf **Raspberry Pi OS / Ubuntu / Debian** installierst du die fehlenden Pakete mit:

```bash
sudo apt update && sudo apt install -y curl python3 gettext-base
# Docker: https://docs.docker.com/engine/install/
```

## Installation

### 1. Repository klonen

```bash
git clone https://github.com/DEIN-USERNAME/psa-verwaltung.git
cd psa-verwaltung
```

### 2. Installationsskript ausführen

```bash
cd setup
bash install.sh
```

Das Skript:
- Prüft alle Voraussetzungen
- Erzeugt `.env` mit automatisch generierten Passwörtern
- Generiert `nginx.conf` aus dem Template
- Startet alle Docker-Container

### 3. NocoDB einrichten

Öffne die NocoDB-Oberfläche (Standard: `http://SERVER-IP:8181`) und:

1. Erstelle ein **Admin-Konto**
2. Gehe zu **Profilbild → Team & Settings → API Tokens**
3. Erstelle einen neuen Token und kopiere ihn

### 4. API-Token eintragen

```bash
nano setup/.env
# XC_TOKEN=dein-token-hier
```

Danach nginx.conf neu generieren und Container neu starten:

```bash
cd setup
bash install.sh          # generiert nginx.conf neu
docker compose restart frontend
```

### 5. Datenbank-Tabellen erstellen

```bash
bash setup/nocodb-setup.sh
```

Das Skript erstellt alle 6 Tabellen in NocoDB. Sollte das Skript mit deiner NocoDB-Version nicht funktionieren, erstelle die Tabellen manuell (siehe Abschnitt **Tabellen manuell anlegen**).

### 6. Frontend konfigurieren

Nach der Tabellenerstellung:

```bash
bash setup/configure-frontend.sh
docker compose -f setup/docker-compose.yml restart frontend
```

Die App ist jetzt erreichbar unter `http://SERVER-IP:8182`.

---

## Tabellen manuell anlegen

Falls `nocodb-setup.sh` nicht funktioniert, erstelle die Tabellen in der NocoDB UI:

### Kameraden
| Spalte | Typ |
|---|---|
| Name | Single Line Text |
| Vorname | Single Line Text |
| Jacke_Groesse | Single Line Text |
| Hose_Groesse | Single Line Text |
| Stiefel_Groesse | Number |
| Handschuh_Groesse | Single Line Text |
| Aktiv | Checkbox |

### Ausruestungstypen
| Spalte | Typ |
|---|---|
| Typ | Single Line Text |
| Bezeichnung | Single Line Text |
| Hersteller | Single Line Text |
| Norm | Single Line Text |
| Max_Lebensdauer_Jahre | Number |
| Pruefintervall_Monate | Number |
| Beschreibung | Long Text |

### Ausruestungstuecke
| Spalte | Typ |
|---|---|
| Ausruestungstyp | Single Line Text |
| Kamerad | Single Line Text |
| Seriennummer | Single Line Text |
| QR_Code | Single Line Text |
| Herstellungsdatum | Date |
| Lebensende_Datum | Date |
| Naechste_Pruefung | Date |
| Status | Single Line Text |
| Notizen | Long Text |

### Ausgaben
| Spalte | Typ |
|---|---|
| Ausgabedatum | Date |
| Rueckgabedatum | Date |
| Notizen | Long Text |

### Pruefungen
| Spalte | Typ |
|---|---|
| Datum | Date |
| Ergebnis | Single Line Text |
| Pruefer | Single Line Text |
| Naechste_Pruefung | Date |
| Notizen | Long Text |

### Waesche
| Spalte | Typ |
|---|---|
| Datum | Date |
| Waescheart | Single Line Text |
| Notizen | Long Text |

### Danach: IDs in `frontend/index.html` eintragen

Öffne in der NocoDB-URL die Tabelle. Die Projekt-ID (Base-ID) und Tabellen-ID stehen in der URL:

```
http://SERVER:8181/nc/BASE-ID/TABLE-ID
```

Trage die Werte in `frontend/index.html` ein:

```javascript
const API = '/api/v1/db/data/noco/DEINE-BASE-ID';

const TABLES = {
  Kameraden:          'TABELLEN-ID-KAMERADEN',
  Ausruestungstypen:  'TABELLEN-ID-TYPEN',
  Ausruestungstuecke: 'TABELLEN-ID-STUECKE',
  Ausgaben:           'TABELLEN-ID-AUSGABEN',
  Pruefungen:         'TABELLEN-ID-PRUEFUNGEN',
  Waesche:            'TABELLEN-ID-WAESCHE',
};
```

---

## Cloudflare Tunnel (optional)

Um die App von außen erreichbar zu machen, ohne Ports freizugeben:

```bash
# Cloudflare Tunnel installieren (einmalig)
curl -L https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared focal main' | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update && sudo apt install cloudflared

# Tunnel anlegen und Routes konfigurieren in der Cloudflare-Oberfläche
```

---

## Verzeichnisstruktur

```
psa-verwaltung/
├── frontend/
│   └── index.html          # Komplette Single-Page-App (Vue.js 3 + Tailwind)
├── setup/
│   ├── docker-compose.yml  # Container-Konfiguration (liest .env)
│   ├── nginx.conf.template # nginx-Konfiguration mit ${XC_TOKEN}-Platzhalter
│   ├── .env.example        # Vorlage für Umgebungsvariablen
│   ├── install.sh          # Hauptinstallationsskript
│   ├── nocodb-setup.sh     # Erstellt NocoDB-Tabellen via API
│   └── configure-frontend.sh # Schreibt IDs in index.html
└── README.md
```

## Updates

```bash
git pull
cd setup && docker compose pull
docker compose up -d
```

## Lizenz

MIT – Frei verwendbar und anpassbar.
