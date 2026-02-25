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
bash setup/install.sh
```

Das Skript erledigt alles automatisch:

1. Prüft alle Voraussetzungen
2. Erzeugt `.env` mit zufällig generierten Passwörtern
3. Startet alle Docker-Container
4. Wartet bis NocoDB bereit ist
5. **Fragt interaktiv nach dem API-Token** (einmaliger manueller Schritt)
6. Erstellt alle 6 Datenbank-Tabellen
7. Schreibt die Konfiguration in `frontend/config.js`

> **Einziger manueller Schritt:** Das Skript pausiert und zeigt die NocoDB-URL an.
> Öffne diese, erstelle ein Admin-Konto, erzeuge einen API-Token und füge ihn im Terminal ein.

Die App ist danach erreichbar unter `http://SERVER-IP:8182`.

---

## Tabellen manuell anlegen

Falls `nocodb-setup.sh` nicht funktioniert, erstelle die Tabellen in der NocoDB UI:

### Kameraden
| Spalte | Typ |
|---|---|
| Name | Single Line Text |
| Vorname | Single Line Text |
| Email | Email |
| Jacke_Groesse | Single Line Text |
| Hose_Groesse | Single Line Text |
| Stiefel_Groesse | Number |
| Handschuh_Groesse | Single Line Text |
| Hemd_Groesse | Single Line Text |
| Poloshirt_Groesse | Single Line Text |
| Fleece_Groesse | Single Line Text |
| Dienstgrad | Single Line Text |
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
| Max_Waeschen | Number |
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
| Ausruestungstueck_Id | Number |
| Kamerad | Single Line Text |
| Ausruestungstyp | Single Line Text |
| Seriennummer | Single Line Text |

### Pruefungen
| Spalte | Typ |
|---|---|
| Datum | Date |
| Ergebnis | Single Line Text |
| Pruefer | Single Line Text |
| Naechste_Pruefung | Date |
| Notizen | Long Text |
| Ausruestungstueck_Id | Number |
| Kamerad | Single Line Text |
| Ausruestungstyp | Single Line Text |
| Seriennummer | Single Line Text |

### Waesche
| Spalte | Typ |
|---|---|
| Datum | Date |
| Waescheart | Single Line Text |
| Notizen | Long Text |
| Ausruestungstueck_Id | Number |
| Kamerad | Single Line Text |
| Ausruestungstyp | Single Line Text |
| Seriennummer | Single Line Text |

### Normen
| Spalte | Typ |
|---|---|
| Bezeichnung | Single Line Text |
| Beschreibung | Long Text |
| Pruefintervall_Monate | Number |
| Max_Lebensdauer_Jahre | Number |
| Ausruestungstyp_Kategorie | Single Line Text |
| Max_Waeschen | Number |

### Danach: `configure-frontend.sh` ausführen

```bash
bash setup/configure-frontend.sh
```

Das Skript liest die IDs aus `setup/.nocodb_table_ids` (automatisch von `nocodb-setup.sh` erstellt)
und schreibt sie in `frontend/config.js`. nginx muss dafür nicht neu gestartet werden.

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
