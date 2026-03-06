# CLAUDE.md — Feuerwehr-Apps Projektstatus

Zentrale Wissensdatei für alle drei Feuerwehr-Apps der OF Wietmarschen. Enthält Architektur, erledigte Arbeiten, offene Aufgaben und den Unifikationsplan.

---

## Feuerwehr-Apps Übersicht

| App | Repo | Tech-Stack | DB | Auth | Port | Deployment |
|-----|------|------------|----|------|------|------------|
| **PSA-Verwaltung** | `Brunsben/psa-verwaltung` | Vue 3, Vite, Tailwind 4, TypeScript | PostgreSQL 17 | JWT (PostgREST) | 8182 | Docker Compose (4 Container) |
| **FoodBot** | `Brunsben/FoodBot` | Flask 3.0, Gunicorn, Jinja2, pyserial | SQLite (SQLAlchemy) | Session (Single PW) | 8183 | Docker (1 Container) |
| **Führerscheinkontrolle** | `Brunsben/FK-App` | Next.js 16, React 19, TypeScript, shadcn/ui | SQLite (Drizzle ORM) | NextAuth v5, bcrypt | 3000 | Systemd (kein Docker) |

**Gemeinsam:** Raspberry Pi, Cloudflare Tunnel, Feuerwehr-Rot `#dc2626`

---

## Git-Referenzpunkte

### Tag `pre-unification` (6. März 2026)
Letzter funktionierender Stand **vor** der Multi-App-Unifikation. Jederzeit zurückkehren mit `git checkout pre-unification`.

| Repo | Commit | Branch |
|------|--------|--------|
| PSA-Verwaltung | `d817540` | `main` |
| FoodBot | `fc1ef6e` | `main` |
| Führerscheinkontrolle | `2e9c72b` | `main` |

### Aktiver Entwicklungsbranch
Alle Unifikations-Arbeiten laufen auf **`feature/unification`** (in allen 3 Repos). Merge auf `main` erst wenn stabil.

---

## Architektur-Entscheidungen (bestätigt)

1. **Schema-Umbenennung** — `pxicv3djlauluse` → `fw_psa` (NocoDB-Altlast bereinigen)
2. **UUIDs statt Integer-IDs** — Alle Primärschlüssel werden `uuid DEFAULT gen_random_uuid()` (kollisionsfrei über Schemas hinweg)
3. **Flask bleibt RFID-Proxy** — FoodBot-Backend bleibt Flask für ELATEC TWN4 Hardware-Anbindung (pyserial), bekommt aber JWT-Auth-Middleware
4. **Shared PostgreSQL** — Ein DB-Server, vier Schemas: `fw_common`, `fw_psa`, `fw_food`, `fw_fuehrerschein`
5. **Repos bleiben getrennt** — Jede App ist eigenständig lauffähig, Portal als viertes Repo

---

## Infrastruktur

### Raspberry Pi (10.10.1.238)
- **Docker:** PSA (4 Container), FoodBot (1 Container), Portal (geplant)
- **Systemd:** Führerscheinkontrolle (Next.js), Cloudflare Tunnel
- **Cloudflare Tunnel:** `psa.ofwietmarschen.org`, `food.ofwietmarschen.org`, `fk.ofwietmarschen.org`

### Ziel-Architektur (nach Unifikation)
```
nginx (Reverse Proxy)
├── /           → Portal (Vue 3 SPA)
├── /psa/       → PSA-Frontend + PostgREST API
├── /food/      → FoodBot-Frontend + Flask API
└── /fk/        → FK-Frontend + Next.js API

PostgreSQL 17
├── fw_common          (members, accounts, auth)
├── fw_psa             (Ausrüstung, Prüfungen, etc.)
├── fw_food            (Bestellungen, Rezepte, etc.)
└── fw_fuehrerschein   (Kontrollen, Uploads, etc.)
```

### Docker-Netzwerk (geplant)
```
fw-network (bridge)
├── postgres       (shared, Port 5432 intern)
├── postgrest      (fw_common + fw_psa)
├── psa-frontend   (nginx, Port 8182)
├── foodbot        (Flask/Gunicorn, Port 8183)
├── fk-app         (Next.js, Port 3000)
└── portal         (nginx, Port 80/443)
```

---

## n8n Integration

- **URL:** konfiguriert in `.mcp.json`
- **MCP-Tools:** `n8n_list_workflows`, `n8n_get_workflow`, `n8n_create_workflow`, `n8n_update_partial_workflow`, `n8n_test_workflow`, `search_nodes`, `get_node`, etc.
- **Skills:** `~/.claude/skills/` — n8n-mcp-tools-expert, n8n-workflow-patterns, n8n-node-configuration, n8n-expression-syntax, n8n-validation-expert, n8n-code-javascript, n8n-code-python
- **Relevante Workflows:** Backup, Prüfungs-Reminder, Wäsch-Limit, Lebensende-Warnung (siehe `workflows/`)

---

## PSA-Verwaltung — API-Referenz

- **API:** `https://psa.ofwietmarschen.org/api/{tabelle}` (extern), `http://10.10.1.238:8182/api/{tabelle}` (intern)
- **Auth:** JWT-basiert (`psa_anon` → nur Login-RPCs, `psa_user` → Daten mit RLS)
- **Schema:** `pxicv3djlauluse` (wird zu `fw_psa`, siehe Schritt 0)

| Tabelle | Endpunkt |
|---------|----------|
| Kameraden | `/api/Kameraden` |
| Ausruestungstypen | `/api/Ausruestungstypen` |
| Ausruestungstuecke | `/api/Ausruestungstuecke` |
| Ausgaben | `/api/Ausgaben` |
| Pruefungen | `/api/Pruefungen` |
| Waesche | `/api/Waesche` |
| Normen | `/api/Normen` |
| Benutzer | `/api/Benutzer` |
| Changelog | `/api/Changelog` |
| Schadensdokumentation | `/api/Schadensdokumentation` |

**Filter:** `?Feld=op.Wert` (z.B. `?Status=neq.Ausgesondert&Naechste_Pruefung=lte.2026-12-31`)

**RPC-Funktionen:**

| Funktion | Auth | Beschreibung |
|----------|------|-------------|
| `POST /api/rpc/authenticate` | anon | Login → JWT-Token |
| `POST /api/rpc/is_initialized` | anon | Prüft ob Admin existiert |
| `POST /api/rpc/create_admin` | anon | Ersteinrichtung (nur wenn leer) |
| `POST /api/rpc/change_password` | JWT | Eigenes Passwort ändern |

**JWT-Claims:** `role` (psa_user), `sub` (Benutzername), `app_role` (Admin/Kleiderwart/User), `kamerad_id` (für User-RLS)

---

## Security-Architektur (März 2026) ✅

### Umgesetzt (Commit `d817540`)
1. **Bcrypt-PIN-Hashing** — Trigger `hash_pin` auf `Benutzer`, pgcrypto `crypt()/gen_salt('bf')` → `postgres-init.sql`
2. **Brute-Force-Schutz** — `login_attempts` Tabelle, 5 Fehlversuche/15 Min → Sperre → `postgres-init.sql`
3. **JWT-Lockdown automatisiert** — `install.sh` führt `postgres-jwt-lockdown.sql` automatisch aus
4. **Row-Level Security (RLS)** — Alle 10 Tabellen, Admin/Kleiderwart: voll, User: eigene Daten → `postgres-jwt-lockdown.sql`
5. **CSP + Permissions-Policy** — Header in `nginx.conf.template`
6. **PIN-Mindestlänge ≥6** — Server (Trigger + RPCs) + Client (`store.ts`)
7. **change_password RPC** — Statt direktem PATCH auf Benutzer → `postgres-init.sql`, `api/index.ts`
8. **v-html eliminiert** — Sidebar Icons per `:class`-Binding → `Sidebar.vue`, `store.ts`
9. **safeJsonParse** — try/catch für localStorage → `store.ts`

### ⚠️ Noch offen (Produktion)
1. **Klartext-PINs migrieren** — Einmalig auf dem Server:
   ```sql
   docker exec -i nocodb_postgres psql -U nocodb -d nocodb -c "
     UPDATE pxicv3djlauluse.\"Benutzer\"
        SET \"PIN\" = crypt(\"PIN\", gen_salt('bf'))
      WHERE \"PIN\" NOT LIKE '\$2a\$%' AND \"PIN\" NOT LIKE '\$2b\$%';
   "
   ```
2. **PostgREST neustarten** nach DB-Änderungen: `cd setup && docker compose restart postgrest`
3. **n8n-Workflows prüfen** — Backup, Prüfungs-Reminder etc. brauchen ggf. JWT-Token
4. **Testen:** Login, Passwort ändern, Benutzer CRUD, RLS User-Rolle
5. **Optional:** JWT in httpOnly-Cookie statt localStorage

---

## Unifikationsplan

### Schritt 0 — DB-Fundament & PSA-Normalisierung ✅
- [x] `fw_common`-Schema erstellen: `members`-Tabelle (UUID, Vorname, Name, Dienstgrad, etc.), `accounts`-Tabelle (UUID, username, PIN, role, member_id FK), Auth-Funktionen → neue Datei `setup/postgres-common.sql`
- [x] Schema umbenennen `pxicv3djlauluse` → `fw_psa` → ~87 Stellen in 5 Dateien: `postgres-init.sql` (~38×), `postgres-jwt-lockdown.sql` (~40×), `docker-compose.yml` (1×), `migration-fotos.sql` (6×), `README.md` (2-3×)
- [x] UUID-Migration: Integer-IDs → UUID → 12 Interfaces in `types/index.ts` (`id: number` → `id: string`), API-Layer `api/index.ts` (4 CRUD-Funktionen), alle SQL-Tabellen
- [x] FK-Normalisierung: Denormalisierte String-Referenzen (`"Vorname Name"`) → `Kamerad_Id` UUID-FK → ~80 Stellen in `store.ts`, 8 Vue-Komponenten, `pdf.ts` (Commit `9e299aa`)
- [x] PostgREST Resource Embedding konfigurieren (JOINs über FKs statt Client-seitige Zuordnung)
- [x] `docker-compose.yml` anpassen: `PGRST_DB_SCHEMAS: "fw_common,fw_psa"`

### Schritt 1 — Portal-Landingpage ✅
- [x] Portal-SPA erstellen (Vue 3, Vite, Tailwind 4) → `portal/` Verzeichnis mit App-Kacheln, Health-Checks, Dark Mode, Uhr
- [x] Master `docker-compose.portal.yml` für alle Services (fw-network, shared PostgreSQL)
- [x] nginx Reverse-Proxy: `/` → Portal, `/psa/` → PSA, `/food/` → FoodBot, `/fk/` → FK (+ WebSocket für RFID)
- [x] Cloudflare Tunnel Doku (siehe unten)
- [x] App-Kacheln mit Status-Badges (online/offline via Health-Checks, 60s Intervall)

### Schritt 2 — FoodBot modernisieren
- [ ] Jinja2-Templates → Tailwind CSS
- [ ] SQLite → PostgreSQL (`fw_food`-Schema), SQLAlchemy-Models anpassen
- [ ] Flask JWT-Auth-Middleware (Token aus `fw_common.accounts` validieren)
- [ ] Docker-Container in fw-network einbinden
- [ ] RFID-WebSocket-Endpunkt für Hardware-Proxy

### Schritt 3 — Führerscheinkontrolle containerisieren
- [ ] Dockerfile + docker-compose Service erstellen
- [ ] SQLite → PostgreSQL (`fw_fuehrerschein`-Schema), Drizzle `pg-core` statt `better-sqlite3`
- [ ] NextAuth → JWT-Validierung gegen `fw_common`
- [ ] Verschlüsselte Uploads auf Shared Volume migrieren

### Schritt 4 — FoodBot Vue 3 Frontend
- [ ] Jinja2 SSR → Vue 3 SPA (analog PSA-Frontend)
- [ ] Flask → reine REST-API + RFID-WebSocket-Proxy
- [ ] Geteilte UI-Komponenten mit Portal extrahieren

---

## Bekannte Eigenheiten

- **NocoDB-Altlast:** PSA-Tabellen haben deutsch-gemischte Spaltennamen (`Naechste_Pruefung`, `Ausruestungstuecke_Id`) und denormalisierte String-Referenzen statt FKs
- **PostgREST-Schema:** Frontend-Code referenziert das Schema **nicht** direkt (nur Backend-SQL-Dateien betroffen)
- **Cloudflare Tunnel:** Systemd-Service `cloudflared`, Konfiguration in `/etc/cloudflare/`. Umstellung auf Portal: `cloudflared tunnel route dns fw-tunnel fw.ofwietmarschen.org` → Service-URL auf `http://localhost:8180` (Portal-Port) ändern in `/etc/cloudflare/config.yml`, dann `sudo systemctl restart cloudflared`
- **FoodBot RFID:** ELATEC TWN4 Multitech via pyserial an `/dev/ttyUSB0`, Flask dient als Hardware-Proxy
