# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an n8n workflow automation workspace. It uses the **n8n-mcp** MCP server to interact directly with a live n8n instance via MCP tools, and **n8n-skills** for expert guidance on node configuration, expressions, and workflow patterns.

## Connected n8n Instance

- **URL:** configured in `.mcp.json` (your n8n instance URL)
- **API Key:** configured in `.mcp.json`
- **API Key expiry:** renew in n8n → Settings → API → Create API Key, then update `.mcp.json`

## MCP Tools Available

The `n8n-mcp` server provides direct access to the n8n instance:

| Tool | Purpose |
|------|---------|
| `n8n_list_workflows` | List all workflows |
| `n8n_get_workflow` | Get a workflow by ID |
| `n8n_create_workflow` | Create a new workflow |
| `n8n_update_partial_workflow` | Incrementally update a workflow |
| `n8n_update_full_workflow` | Replace a workflow entirely |
| `n8n_delete_workflow` | Delete a workflow |
| `n8n_test_workflow` | Trigger/test a workflow |
| `n8n_executions` | List or inspect executions |
| `n8n_validate_workflow` | Validate workflow before deploying |
| `n8n_autofix_workflow` | Auto-fix common validation errors |
| `search_nodes` | Search n8n nodes by keyword |
| `get_node` | Get node schema and docs |
| `search_templates` | Find workflow templates |
| `n8n_deploy_template` | Deploy a template directly to n8n |
| `validate_node` | Validate a single node config |
| `n8n_health_check` | Check MCP server + n8n connectivity |

Always prefer `n8n_update_partial_workflow` over full updates when modifying existing workflows.

## Installed Skills

Located in `~/.claude/skills/`:

- **`/n8n-mcp-tools-expert`** — Which MCP tool to use and how (start here for tool selection)
- **`/n8n-workflow-patterns`** — Architectural patterns for webhook, scheduled, AI agent, and API workflows
- **`/n8n-node-configuration`** — Required fields and property dependencies per node type
- **`/n8n-expression-syntax`** — `{{ }}` syntax, `$json`, `$node`, `$input`, etc.
- **`/n8n-validation-expert`** — Interpreting and fixing validation errors
- **`/n8n-code-javascript`** — JavaScript in Code nodes (`$input`, `$helpers`, DateTime)
- **`/n8n-code-python`** — Python in Code nodes and its limitations

## PSA-Verwaltung (PostgREST)

- **API:** `http://10.10.1.238:8182/api/{tabelle}` (intern), `https://psa.ofwietmarschen.org/api/{tabelle}` (extern)
- **Auth:** JWT-basiert (PostgREST validiert Bearer-Token, `psa_anon` hat nur Zugriff auf Login-RPC-Funktionen)
- **Schema:** `pxicv3djlauluse` (PostgreSQL-Schema)

| Tabelle | PostgREST-Endpunkt |
| - | - |
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
| login_attempts | (kein Direktzugriff, nur über `authenticate()`) |

**Filter-Syntax:** `?Feld=op.Wert` (z.B. `?Status=neq.Ausgesondert&Naechste_Pruefung=lte.2026-12-31`)

**RPC-Funktionen:**
| Funktion | Auth | Beschreibung |
| - | - | - |
| `POST /api/rpc/authenticate` | anon | Login → JWT-Token |
| `POST /api/rpc/is_initialized` | anon | Prüft ob Admin existiert |
| `POST /api/rpc/create_admin` | anon | Ersteinrichtung (nur wenn leer) |
| `POST /api/rpc/change_password` | JWT | Eigenes Passwort ändern |

**JWT-Claims:**
- `role`: immer `psa_user` (PostgREST-Rolle)
- `sub`: Benutzername
- `app_role`: `Admin` / `Kleiderwart` / `User` (anwendungsbezogen)
- `kamerad_id`: verknüpfte Kameraden-ID (für User-Rolle)

> Cloudflare Tunnel läuft als Systemdienst auf dem Pi (`sudo systemctl status cloudflared`). Startet automatisch nach Neustart.

## Security-Architektur (Stand: März 2026)

### ✅ Umgesetzt
1. **Bcrypt-PIN-Hashing** — Trigger `hash_pin` auf `Benutzer` hasht PINs automatisch bei INSERT/UPDATE (`pgcrypto crypt()/gen_salt('bf')`). Bestehende Klartext-PINs müssen einmalig migriert werden (siehe unten).
2. **Brute-Force-Schutz** — Tabelle `login_attempts` zählt Fehlversuche. Nach 5 Fehlern in 15 Min → Account temporär gesperrt. `authenticate()` bereinigt Einträge >24h.
3. **JWT-Lockdown automatisiert** — `install.sh` führt `postgres-jwt-lockdown.sql` automatisch aus. Kein manueller Schritt mehr nötig.
4. **Row-Level Security (RLS)** — Auf allen Tabellen aktiv. Admin/Kleiderwart: voller Zugriff. User: nur eigene Daten. Hilfsfunktionen: `current_app_role()`, `current_kamerad_id()`, `current_kamerad_name()`.
5. **Content-Security-Policy** — CSP + Permissions-Policy Header in `nginx.conf.template`.
6. **PIN-Mindestanforderungen** — ≥6 Zeichen, Server (Trigger + RPC-Funktionen) + Client (`store.ts`).
7. **Sichere Passwortänderung** — `change_password()` RPC statt direktem PATCH auf Benutzer-Tabelle.
8. **v-html eliminiert** — Icons in Sidebar per `:class`-Binding statt `v-html`.
9. **JSON.parse abgesichert** — `safeJsonParse()` mit try/catch für localStorage.

### ⚠️ Noch zu erledigen (nach Deployment)
1. **Bestehende Klartext-PINs migrieren** — Einmalig auf dem Server ausführen:
   ```sql
   docker exec -i nocodb_postgres psql -U nocodb -d nocodb -c "
     UPDATE pxicv3djlauluse.\"Benutzer\"
        SET \"PIN\" = crypt(\"PIN\", gen_salt('bf'))
      WHERE \"PIN\" NOT LIKE '\$2a\$%' AND \"PIN\" NOT LIKE '\$2b\$%';
   "
   ```
2. **PostgREST neustarten** nach DB-Änderungen: `cd setup && docker compose restart postgrest`
3. **n8n-Workflows prüfen** — Workflows die direkt auf die DB oder API zugreifen müssen evtl. JWT-Token mitschicken (betrifft: Backup, Prüfungs-Reminder, Wäsch-Limit etc.)
4. **Testen**: Login, Passwort ändern, Benutzer anlegen/bearbeiten, RLS für User-Rolle
5. **Optional: JWT in httpOnly-Cookie** statt localStorage (erfordert PostgREST-Proxy-Anpassung)

## Typical Workflow

1. **Search** for relevant nodes: `search_nodes`
2. **Check** node schema before configuring: `get_node`
3. **Validate** before saving: `validate_node` / `validate_workflow`
4. **Auto-fix** common issues: `n8n_autofix_workflow`
5. **Test** after deployment: `n8n_test_workflow`

When creating workflows from scratch, check `search_templates` first — deploying an existing template is faster than building from zero.
