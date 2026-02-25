#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  configure-frontend.sh
#  Liest die NocoDB-Tabellen-IDs aus .nocodb_table_ids und
#  schreibt sie in frontend/config.js (keine Änderung an index.html).
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDS_FILE="$SCRIPT_DIR/.nocodb_table_ids"
CONFIG_JS="$SCRIPT_DIR/../frontend/config.js"

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

echo "🔧 Erstelle frontend/config.js..."
echo "   BASE_ID:              $BASE_ID"
echo "   Kameraden:            $ID_Kameraden"
echo "   Ausruestungstypen:    $ID_Ausruestungstypen"
echo "   Ausruestungstuecke:   $ID_Ausruestungstuecke"
echo "   Ausgaben:             $ID_Ausgaben"
echo "   Pruefungen:           $ID_Pruefungen"
echo "   Waesche:              $ID_Waesche"

cat > "$CONFIG_JS" << EOF
// PSA-Verwaltung – Laufzeitkonfiguration
// Automatisch erzeugt von setup/configure-frontend.sh
// Nicht in Git einchecken (.gitignore).
// Token wird serverseitig von nginx injiziert – NICHT hier speichern!

window.CONFIG = {
  api: '/api/v1/db/data/noco/$BASE_ID',
  tables: {
    Kameraden:          '$ID_Kameraden',
    Ausruestungstypen:  '$ID_Ausruestungstypen',
    Ausruestungstuecke: '$ID_Ausruestungstuecke',
    Ausgaben:           '$ID_Ausgaben',
    Pruefungen:         '$ID_Pruefungen',
    Waesche:            '$ID_Waesche',
  }
};
EOF

echo "✅ frontend/config.js erstellt."
echo ""
echo "🚀 Starte nginx neu, um die Änderungen zu übernehmen:"
echo "   cd setup && docker compose restart frontend"
