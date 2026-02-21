#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  install.sh – PSA-Verwaltung Installationsskript
#  Getestet mit: Docker 24+, NocoDB 0.301.x, Ubuntu/Debian/Raspberry Pi OS
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
echo "║   Installationsskript                            ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── Voraussetzungen prüfen ─────────────────────────────────
echo "🔍 Prüfe Voraussetzungen..."

check_cmd() {
  if ! command -v "$1" &> /dev/null; then
    echo "❌ '$1' ist nicht installiert. Bitte installieren und erneut versuchen."
    exit 1
  fi
  echo "   ✓ $1"
}

check_cmd docker
check_cmd curl
check_cmd python3

# Docker Compose (entweder als Plugin oder standalone)
if docker compose version &>/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  echo "❌ 'docker compose' nicht gefunden. Installiere Docker Desktop oder das Compose-Plugin."
  exit 1
fi
echo "   ✓ $COMPOSE"

# envsubst für nginx.conf
if ! command -v envsubst &>/dev/null; then
  echo "⚠️  'envsubst' nicht gefunden (gettext-Paket)."
  echo "   Installiere mit: sudo apt install gettext-base"
  exit 1
fi
echo "   ✓ envsubst"
echo ""

# ── .env erzeugen ─────────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  echo "ℹ️  .env existiert bereits – wird nicht überschrieben."
else
  echo "📝 Erstelle .env aus Vorlage..."
  cp "$ENV_EXAMPLE" "$ENV_FILE"

  # Passwörter und Secrets automatisch generieren
  PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 || true)
  SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 48 | head -n 1 || true)

  sed -i "s|change-me-strong-password|$PW|g" "$ENV_FILE"
  sed -i "s|change-me-random-secret-at-least-32-chars|$SECRET|g" "$ENV_FILE"

  echo "✅ .env erstellt (Passwörter automatisch generiert)"
  echo ""
  echo "⚠️  WICHTIG: Trage nach der NocoDB-Einrichtung den API-Token ein:"
  echo "   $ENV_FILE → XC_TOKEN=..."
fi

# .env laden
set -a; source "$ENV_FILE"; set +a

# ── nginx.conf generieren ─────────────────────────────────
echo ""
echo "🔧 Generiere nginx.conf..."
if [ -z "$XC_TOKEN" ] || [ "$XC_TOKEN" = "your-nocodb-api-token-here" ]; then
  echo "ℹ️  XC_TOKEN noch nicht gesetzt – nginx.conf wird mit Platzhalter erstellt."
  echo "   Führe dieses Skript erneut aus, nachdem du den Token in .env eingetragen hast."
  XC_TOKEN="PLACEHOLDER_TOKEN"
fi
envsubst '${XC_TOKEN}' < "$NGINX_TEMPLATE" > "$NGINX_CONF"
echo "✅ nginx.conf generiert"

# ── Docker Compose starten ────────────────────────────────
echo ""
echo "🐳 Starte Docker-Container..."
cd "$SCRIPT_DIR"
$COMPOSE up -d

echo ""
echo "⏳ Warte auf NocoDB (kann 30–60 Sekunden dauern)..."
for i in $(seq 1 30); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8181/api/v1/health 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ]; then
    echo "✅ NocoDB ist bereit!"
    break
  fi
  printf "."
  sleep 3
done

echo ""
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   ✅ Installation abgeschlossen!                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "🌐 NocoDB UI:  http://$(hostname -I | awk '{print $1}'):8181"
echo "🌐 PSA-App:    http://$(hostname -I | awk '{print $1}'):8182"
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo ""
echo "1. Öffne die NocoDB UI und erstelle ein Admin-Konto"
echo "2. Erstelle einen API-Token:"
echo "   Klicke auf dein Profilbild → Team & Settings → API Tokens"
echo "3. Trage den Token in .env ein:"
echo "   nano $ENV_FILE"
echo "   → XC_TOKEN=dein-token-hier"
echo "4. Generiere nginx.conf neu und starte die App neu:"
echo "   cd $SCRIPT_DIR && bash install.sh"
echo "5. Erstelle die Datenbank-Tabellen:"
echo "   bash $SCRIPT_DIR/nocodb-setup.sh"
echo "6. Aktualisiere die Frontend-Konfiguration:"
echo "   bash $SCRIPT_DIR/configure-frontend.sh"
echo "   $COMPOSE restart frontend"
echo ""
