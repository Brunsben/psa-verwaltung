#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  install.sh – PSA-Verwaltung Installationsskript
#  Startet alle Container, legt PostgreSQL-Rollen an,
#  konfiguriert das Frontend.
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"

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

if docker compose version &>/dev/null 2>&1; then
  COMPOSE="docker compose"
elif command -v docker-compose &>/dev/null; then
  COMPOSE="docker-compose"
else
  echo "❌ 'docker compose' nicht gefunden."
  exit 1
fi
echo "   ✓ $COMPOSE"
echo ""

# ── .env erzeugen ─────────────────────────────────────────
if [ -f "$ENV_FILE" ]; then
  echo "ℹ️  .env existiert – wird nicht überschrieben."
else
  echo "📝 Erstelle .env mit zufälligen Passwörtern..."
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  PW=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 || true)
  PW_REST=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1 || true)
  sed -i "s|change-me-strong-password|$PW|g" "$ENV_FILE"
  sed -i "s|change-me-postgrest-password|$PW_REST|g" "$ENV_FILE"
  echo "✅ .env erstellt"
fi

# .env laden
set -a; source "$ENV_FILE"; set +a

# ── nginx.conf erzeugen ────────────────────────────────────
cp "$SCRIPT_DIR/nginx.conf.template" "$SCRIPT_DIR/nginx.conf"

# ── PostgreSQL starten und warten ─────────────────────────
echo ""
echo "🐳 Starte PostgreSQL..."
cd "$SCRIPT_DIR"
$COMPOSE up -d postgres

echo "⏳ Warte auf PostgreSQL..."
for i in $(seq 1 30); do
  if $COMPOSE exec -T postgres pg_isready -U "${POSTGRES_USER:-nocodb}" &>/dev/null; then
    echo "✅ PostgreSQL bereit"
    break
  fi
  printf "."
  sleep 2
done
echo ""

# ── PostgreSQL-Rollen anlegen ──────────────────────────────
echo "🔑 Lege PostgreSQL-Rollen an..."
$COMPOSE exec -T postgres psql \
  -U "${POSTGRES_USER:-nocodb}" \
  -d "${POSTGRES_DB:-nocodb}" \
  -v "postgrest_password=${POSTGREST_DB_PASSWORD}" \
  -f /dev/stdin < "$SCRIPT_DIR/postgres-init.sql"
echo "✅ Rollen angelegt"

# ── Alle Container starten ────────────────────────────────
echo ""
echo "🚀 Starte alle Container (Frontend-Build dauert ~30s)..."
$COMPOSE up -d --build

# ── Warten auf Frontend ───────────────────────────────────
echo "⏳ Warte auf Frontend..."
for i in $(seq 1 40); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8182/ 2>/dev/null || echo "000")
  if [ "$STATUS" = "200" ]; then
    echo "✅ Frontend bereit"
    break
  fi
  printf "."
  sleep 3
done
echo ""

# ── Frontend konfigurieren ────────────────────────────────
echo "⚙️  Konfiguriere Frontend..."
bash "$SCRIPT_DIR/configure-frontend.sh"
$COMPOSE restart frontend

# ── Fertig ────────────────────────────────────────────────
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")
echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║   ✅ Installation abgeschlossen!                 ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "🌐 PSA-App: http://$SERVER_IP:8182"
echo ""
echo "   Beim ersten Aufruf Admin-Account anlegen."
echo ""
