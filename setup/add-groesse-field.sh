#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  add-groesse-field.sh
#  Fügt das Feld "Groesse" zur Ausrüstungsstücke-Tabelle hinzu.
#  Verwendung: bash add-groesse-field.sh
#  Voraussetzung: .env mit XC_TOKEN, .nocodb_table_ids vorhanden
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# .env laden
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

TOKEN="${XC_TOKEN:-}"
BASE_URL="${NOCODB_URL:-http://localhost:8181}"

if [ -z "$TOKEN" ]; then
  echo "❌ Fehler: XC_TOKEN ist nicht gesetzt (setup/.env fehlt oder leer)."
  exit 1
fi

# Tabellen-ID lesen
IDS_FILE="$SCRIPT_DIR/.nocodb_table_ids"
if [ ! -f "$IDS_FILE" ]; then
  echo "❌ .nocodb_table_ids nicht gefunden. Führe zuerst nocodb-setup.sh aus."
  exit 1
fi

TABLE_ID=$(grep "^Ausruestungstuecke=" "$IDS_FILE" | cut -d= -f2)
if [ -z "$TABLE_ID" ]; then
  echo "❌ Ausruestungstuecke-ID nicht in .nocodb_table_ids gefunden."
  exit 1
fi

echo "📋 Tabelle Ausruestungstuecke: $TABLE_ID"
echo "🔧 Füge Feld 'Groesse' hinzu..."

RESP=$(curl -s -w "\n%{http_code}" -X POST \
  "$BASE_URL/api/v2/meta/tables/$TABLE_ID/fields" \
  -H "xc-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Groesse", "uidt": "SingleLineText"}')

HTTP_CODE=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | head -n -1)

if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "201" ]; then
  echo "✅ Feld 'Groesse' erfolgreich angelegt."
elif echo "$BODY" | grep -qi "already exist\|duplicate\|existing"; then
  echo "ℹ️  Feld 'Groesse' existiert bereits – keine Änderung nötig."
else
  echo "❌ Fehler (HTTP $HTTP_CODE):"
  echo "$BODY"
  exit 1
fi

echo ""
echo "🚀 Fertig! Starte das Frontend neu, damit Änderungen übernommen werden:"
echo "   cd setup && docker compose restart frontend"
