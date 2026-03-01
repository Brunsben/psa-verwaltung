# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is an n8n workflow automation workspace. It uses the **n8n-mcp** MCP server to interact directly with a live n8n instance via MCP tools, and **n8n-skills** for expert guidance on node configuration, expressions, and workflow patterns.

## Connected n8n Instance

- **URL:** `https://n8n.brunsben.org`
- **API Key:** configured in `.mcp.json`
- **API Key expiry:** 2026-03-19 — renew in n8n → Settings → API → Create API Key, then update `.mcp.json`

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

## NocoDB (Feuerwehr Bekleidungsverwaltung)

- **URL (öffentlich):** `https://nocodb.brunsben.org` (via Cloudflare Tunnel)
- **URL (lokal):** `http://10.10.1.238:8181` (Raspberry Pi direkt)
- **API Token:** `y8gqusXb01THwcj2WcAg_04hEfIV-DfgY25INewY` (Header: `xc-token`)
- **API Endpoint:** `https://nocodb.brunsben.org/api/v2/meta/bases/`
- **Base ID:** `pxicv3djlauluse`

| Tabelle | ID |
| - | - |
| Kameraden | `mbfq6ec4y5mroif` |
| Ausruestungstypen | `mv97zr52e65li0f` |
| Ausruestungstuecke | `m6gby0ep5khzyzg` |
| Ausgaben | `m6rtooq3l4fshif` |
| Pruefungen | `mvpg0wcptqd4gk9` |
| Waesche | `m3e70ipbmh7zre0` |
| Normen | `m548rfn3cyooaa7` |
| Benutzer | `mvcs3jnd76tm4ad` |
| Changelog | `mf2aln0bbnynp0m` |

> Cloudflare Tunnel läuft als Systemdienst auf dem Pi (`sudo systemctl status cloudflared`). Startet automatisch nach Neustart.

## Typical Workflow

1. **Search** for relevant nodes: `search_nodes`
2. **Check** node schema before configuring: `get_node`
3. **Validate** before saving: `validate_node` / `validate_workflow`
4. **Auto-fix** common issues: `n8n_autofix_workflow`
5. **Test** after deployment: `n8n_test_workflow`

When creating workflows from scratch, check `search_templates` first — deploying an existing template is faster than building from zero.
