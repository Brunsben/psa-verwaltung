#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  configure-frontend.sh
#  Liest die NocoDB-Tabellen-IDs aus .nocodb_table_ids und
#  schreibt sie in frontend/index.html
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDS_FILE="$SCRIPT_DIR/.nocodb_table_ids"
INDEX_HTML="$SCRIPT_DIR/../frontend/index.html"

if [ ! -f "$IDS_FILE" ]; then
  echo "❌ Tabellen-IDs nicht gefunden. Führe zuerst nocodb-setup.sh aus."
  exit 1
fi

# IDs lesen
BASE_ID=$(grep "^BASE_ID=" "$IDS_FILE" | cut -d= -f2)
ID_Kameraden=$(grep "^Kameraden=" "$IDS_FILE" | cut -d= -f2)
ID_Ausruestungstypen=$(grep "^Ausruestungstypen=" "$IDS_FILE" | cut -d= -f2)
ID_Ausruestungstuecke=$(grep "^Ausruestungstuecke=" "$IDS_FILE" | cut -d= -f2)
ID_Ausgaben=$(grep "^Ausgaben=" "$IDS_FILE" | cut -d= -f2)
ID_Pruefungen=$(grep "^Pruefungen=" "$IDS_FILE" | cut -d= -f2)
ID_Waesche=$(grep "^Waesche=" "$IDS_FILE" | cut -d= -f2)

if [ -z "$BASE_ID" ]; then
  echo "❌ BASE_ID fehlt in $IDS_FILE"
  exit 1
fi

echo "🔧 Aktualisiere frontend/index.html..."
echo "   BASE_ID:              $BASE_ID"
echo "   Kameraden:            $ID_Kameraden"
echo "   Ausruestungstypen:    $ID_Ausruestungstypen"
echo "   Ausruestungstuecke:   $ID_Ausruestungstuecke"
echo "   Ausgaben:             $ID_Ausgaben"
echo "   Pruefungen:           $ID_Pruefungen"
echo "   Waesche:              $ID_Waesche"

# API-Pfad ersetzen
sed -i "s|/api/v1/db/data/noco/[^']*|/api/v1/db/data/noco/$BASE_ID|g" "$INDEX_HTML"

# Tabellen-IDs ersetzen (jeweils den Wert nach dem ':')
[ -n "$ID_Kameraden" ]          && sed -i "s|Kameraden:          '[^']*'|Kameraden:          '$ID_Kameraden'|g" "$INDEX_HTML"
[ -n "$ID_Ausruestungstypen" ]  && sed -i "s|Ausruestungstypen:  '[^']*'|Ausruestungstypen:  '$ID_Ausruestungstypen'|g" "$INDEX_HTML"
[ -n "$ID_Ausruestungstuecke" ] && sed -i "s|Ausruestungstuecke: '[^']*'|Ausruestungstuecke: '$ID_Ausruestungstuecke'|g" "$INDEX_HTML"
[ -n "$ID_Ausgaben" ]           && sed -i "s|Ausgaben:           '[^']*'|Ausgaben:           '$ID_Ausgaben'|g" "$INDEX_HTML"
[ -n "$ID_Pruefungen" ]         && sed -i "s|Pruefungen:         '[^']*'|Pruefungen:         '$ID_Pruefungen'|g" "$INDEX_HTML"
[ -n "$ID_Waesche" ]            && sed -i "s|Waesche:            '[^']*'|Waesche:            '$ID_Waesche'|g" "$INDEX_HTML"

echo "✅ frontend/index.html aktualisiert."
echo ""
echo "🚀 Starte nginx neu, um die Änderungen zu übernehmen:"
echo "   cd setup && docker compose restart frontend"
