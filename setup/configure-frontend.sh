#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  configure-frontend.sh
#  Schreibt die minimale Laufzeitkonfiguration in frontend/config.js.
#  (PostgREST: keine BASE_ID oder Tabellen-IDs mehr nötig)
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_JS="$SCRIPT_DIR/../frontend/config.js"

echo "🔧 Erstelle frontend/config.js..."

cat > "$CONFIG_JS" << 'EOF'
// PSA-Verwaltung – Laufzeitkonfiguration
// Automatisch erzeugt von setup/configure-frontend.sh
// Nicht in Git einchecken (.gitignore).
window.CONFIG = {
  api: '/api',
};
EOF

echo "✅ frontend/config.js erstellt."
echo ""
echo "🚀 Starte nginx neu, um die Änderungen zu übernehmen:"
echo "   cd setup && docker compose restart frontend"
