#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  nocodb-setup.sh – Erstellt alle Tabellen in NocoDB
#  Verwendung: ./nocodb-setup.sh
#  Voraussetzung: .env muss XC_TOKEN und BASE_URL enthalten
# ─────────────────────────────────────────────────────────────
set -e

# Konfiguration aus .env laden (falls vorhanden)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$SCRIPT_DIR/.env" ]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

TOKEN="${XC_TOKEN:-}"
BASE_URL="${NOCODB_URL:-http://localhost:8181}"

if [ -z "$TOKEN" ]; then
  echo "❌ Fehler: XC_TOKEN ist nicht gesetzt."
  echo "   Trage ihn in setup/.env ein (siehe .env.example)."
  exit 1
fi

echo "🔌 Teste Verbindung zu NocoDB ($BASE_URL)..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "xc-token: $TOKEN" "$BASE_URL/api/v1/meta/bases/")
if [ "$STATUS" != "200" ]; then
  echo "❌ Fehler: Token ungültig oder NocoDB nicht erreichbar (HTTP $STATUS)"
  echo "   Stelle sicher dass NocoDB läuft: docker compose up -d"
  exit 1
fi
echo "✅ Verbindung OK"

echo ""
echo "📁 Erstelle Base 'Feuerwehr PSA-Verwaltung'..."
BASE_RESP=$(curl -s -X POST "$BASE_URL/api/v1/meta/bases/" \
  -H "xc-token: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Feuerwehr PSA-Verwaltung"}')

BASE_ID=$(echo "$BASE_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('id',''))" 2>/dev/null)

if [ -z "$BASE_ID" ]; then
  echo "⚠️  Suche vorhandene Base..."
  BASES=$(curl -s -H "xc-token: $TOKEN" "$BASE_URL/api/v1/meta/bases/")
  BASE_ID=$(echo "$BASES" | python3 -c "
import sys,json
d=json.load(sys.stdin)
for b in d.get('list',[]):
    if b.get('title')=='Feuerwehr PSA-Verwaltung':
        print(b['id'])
        break
" 2>/dev/null)
fi

if [ -z "$BASE_ID" ]; then
  echo "❌ Base konnte nicht erstellt/gefunden werden."
  echo "   Antwort: $BASE_RESP"
  exit 1
fi
echo "✅ Base ID: $BASE_ID"

# Hilfsfunktion: Tabelle erstellen
IDS_FILE="$SCRIPT_DIR/.nocodb_table_ids"
> "$IDS_FILE"

create_table() {
  local NAME="$1"
  local COLUMNS="$2"
  echo ""
  echo "📋 Erstelle Tabelle: $NAME ..."
  RESP=$(curl -s -X POST "$BASE_URL/api/v1/meta/bases/$BASE_ID/tables" \
    -H "xc-token: $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"title\": \"$NAME\", \"columns\": $COLUMNS}")
  ID=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('id','FEHLER'))" 2>/dev/null)
  if [[ "$ID" == "FEHLER" ]] || [ -z "$ID" ]; then
    echo "❌ Fehler bei '$NAME': $RESP"
  else
    echo "✅ $NAME (ID: $ID)"
    echo "$NAME=$ID" >> "$IDS_FILE"
  fi
}

# ─── Tabelle 1: Kameraden ─────────────────────────────────────────────────
create_table "Kameraden" '[
  {"title": "Name",              "uidt": "SingleLineText"},
  {"title": "Vorname",           "uidt": "SingleLineText"},
  {"title": "Jacke_Groesse",     "uidt": "SingleLineText"},
  {"title": "Hose_Groesse",      "uidt": "SingleLineText"},
  {"title": "Stiefel_Groesse",   "uidt": "Number"},
  {"title": "Handschuh_Groesse", "uidt": "SingleLineText"},
  {"title": "Aktiv",             "uidt": "Checkbox"}
]'

# ─── Tabelle 2: Ausruestungstypen ─────────────────────────────────────────
create_table "Ausruestungstypen" '[
  {"title": "Typ",                    "uidt": "SingleLineText"},
  {"title": "Bezeichnung",            "uidt": "SingleLineText"},
  {"title": "Hersteller",             "uidt": "SingleLineText"},
  {"title": "Norm",                   "uidt": "SingleLineText"},
  {"title": "Max_Lebensdauer_Jahre",  "uidt": "Number"},
  {"title": "Pruefintervall_Monate",  "uidt": "Number"},
  {"title": "Beschreibung",           "uidt": "LongText"}
]'

# ─── Tabelle 3: Ausruestungstuecke ────────────────────────────────────────
create_table "Ausruestungstuecke" '[
  {"title": "Ausruestungstyp",   "uidt": "SingleLineText"},
  {"title": "Kamerad",           "uidt": "SingleLineText"},
  {"title": "Seriennummer",      "uidt": "SingleLineText"},
  {"title": "QR_Code",           "uidt": "SingleLineText"},
  {"title": "Herstellungsdatum", "uidt": "Date"},
  {"title": "Lebensende_Datum",  "uidt": "Date"},
  {"title": "Naechste_Pruefung", "uidt": "Date"},
  {"title": "Status",            "uidt": "SingleLineText"},
  {"title": "Notizen",           "uidt": "LongText"}
]'

# ─── Tabelle 4: Ausgaben ──────────────────────────────────────────────────
create_table "Ausgaben" '[
  {"title": "Ausgabedatum",   "uidt": "Date"},
  {"title": "Rueckgabedatum", "uidt": "Date"},
  {"title": "Notizen",        "uidt": "LongText"}
]'

# ─── Tabelle 5: Pruefungen ────────────────────────────────────────────────
create_table "Pruefungen" '[
  {"title": "Datum",             "uidt": "Date"},
  {"title": "Ergebnis",          "uidt": "SingleLineText"},
  {"title": "Pruefer",           "uidt": "SingleLineText"},
  {"title": "Naechste_Pruefung", "uidt": "Date"},
  {"title": "Notizen",           "uidt": "LongText"}
]'

# ─── Tabelle 6: Waesche ───────────────────────────────────────────────────
create_table "Waesche" '[
  {"title": "Datum",      "uidt": "Date"},
  {"title": "Waescheart", "uidt": "SingleLineText"},
  {"title": "Notizen",    "uidt": "LongText"}
]'

echo ""
echo "════════════════════════════════════════════════"
echo "🎉 Tabellen erstellt! Base-ID: $BASE_ID"
echo ""
echo "Tabellen-IDs:"
cat "$IDS_FILE"
echo ""
echo "BASE_ID=$BASE_ID" >> "$IDS_FILE"
echo "════════════════════════════════════════════════"
echo ""
echo "➡️  Nächster Schritt: frontend/index.html aktualisieren"
echo "   Führe aus: ./configure-frontend.sh"
