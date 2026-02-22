#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  install.sh – PSA-Verwaltung Installationsskript
#  Alles in einem Durchlauf: Container starten, Token eingeben,
#  Tabellen anlegen, Frontend konfigurieren.
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"
NGINX_TEMPLATE="$SCRIPT_DIR/nginx.conf.template"
NGINX_CONF="$SCRIPT_DIR/nginx.conf"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   PSA-Verwaltung – FF Wietmarschen               ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Voraussetzungen prüfen ─────────────────────────────────
echo "🔍 Prüfe Voraussetzungen..."

check_cmd() {
  if ! command -v "$1" &> /dev/null; then
    echo "❌ '$1' fehlt. Bitte installieren und erneut versuchen."
    exit 1
  fi
  echo "   ✓ $1"
}

check_cmd docker
check_cmd curl
check_cmd python3

if docker compose version &>/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  echo "❌ 'docker compose' nicht gefunden."
  exit 1
fi
echo "   ✓ $COMPOSE"

if ! command -v envsubst &>/dev/null; then
  echo "❌ 'envsubst' fehlt. Installiere mit: sudo apt install gettext-base"
  exit 1
fi
echo "   ✓ envsubst"
echo ""

# ── .env erzeugen ─────────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  echo "ℹ️  .env existiert – wird nicht überschrieben."
else
  echo "📝 Erstelle .env..."
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 || true)
  SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 48 | head -n 1 || true)
  sed -i "s|change-me-strong-password|$PW|g" "$ENV_FILE"
  sed -i "s|change-me-random-secret-at-least-32-chars|$SECRET|g" "$ENV_FILE"
  echo "✅ .env erstellt"
fi

# .env laden
set -a; source "$ENV_FILE"; set +a

# ── Docker-Container starten ──────────────────────────────
echo ""
echo "🐳 Starte Docker-Container..."
cd "$SCRIPT_DIR"
XC_TOKEN="${XC_TOKEN:-PLACEHOLDER_TOKEN}" envsubst '${XC_TOKEN}' < "$NGINX_TEMPLATE" > "$NGINX_CONF"
$COMPOSE up -d

# ── Warten auf NocoDB ─────────────────────────────────────
echo ""
echo "⏳ Warte auf NocoDB..."
for i in $(seq 1 40); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8181/api/v1/health 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ]; then
    echo "✅ NocoDB bereit"
    break
  fi
  printf "."
  sleep 3
done
echo ""

SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

# ── API-Token einrichten ──────────────────────────────────
set -a; source "$ENV_FILE"; set +a  # neu laden, falls Token inzwischen gesetzt

if [ -z "$XC_TOKEN" ] || [ "$XC_TOKEN" = "your-nocodb-api-token-here" ]; then
  echo ""
  echo "┌─────────────────────────────────────────────────────┐"
  echo "│  Schritt: NocoDB einrichten                         │"
  echo "├─────────────────────────────────────────────────────┤"
  echo "│  1. Öffne:  http://$SERVER_IP:8181                  │"
  echo "│  2. Erstelle ein Admin-Konto (E-Mail + Passwort)    │"
  echo "│  3. Klicke rechts oben auf dein Profilbild          │"
  echo "│     → Team & Settings → API Tokens → Token erstellen│"
  echo "│  4. Kopiere den Token und füge ihn hier ein.        │"
  echo "└─────────────────────────────────────────────────────┘"
  echo ""
  printf "🔑 NocoDB API-Token: "
  read -r XC_TOKEN_INPUT

  if [ -z "$XC_TOKEN_INPUT" ]; then
    echo "❌ Kein Token eingegeben. Abbruch."
    echo "   Starte das Skript erneut, wenn du einen Token hast."
    exit 1
  fi

  # Token in .env speichern
  sed -i "s|XC_TOKEN=.*|XC_TOKEN=$XC_TOKEN_INPUT|g" "$ENV_FILE"
  XC_TOKEN="$XC_TOKEN_INPUT"
  echo "✅ Token gespeichert"
else
  echo "ℹ️  XC_TOKEN bereits in .env vorhanden – Token-Schritt übersprungen."
fi

# ── nginx.conf mit echtem Token neu generieren ────────────
echo ""
echo "🔧 Aktualisiere nginx.conf..."
XC_TOKEN="$XC_TOKEN" envsubst '${XC_TOKEN}' < "$NGINX_TEMPLATE" > "$NGINX_CONF"
$COMPOSE restart frontend
echo "✅ nginx neugestartet"

# ── NocoDB-Tabellen anlegen ───────────────────────────────
IDS_FILE="$SCRIPT_DIR/.nocodb_table_ids"

if [ -f "$IDS_FILE" ] && grep -q "BASE_ID=" "$IDS_FILE"; then
  echo ""
  echo "ℹ️  Tabellen-IDs gefunden – nocodb-setup übersprungen."
else
  echo ""
  echo "📋 Erstelle Datenbank-Tabellen..."
  bash "$SCRIPT_DIR/nocodb-setup.sh"
fi

# ── Frontend konfigurieren ────────────────────────────────
echo ""
echo "⚙️  Konfiguriere Frontend..."
bash "$SCRIPT_DIR/configure-frontend.sh"

# ── Fertig ────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   ✅ Installation abgeschlossen!                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "🌐 PSA-App:   http://$SERVER_IP:8182"
echo "🌐 NocoDB UI: http://$SERVER_IP:8181"
echo ""
