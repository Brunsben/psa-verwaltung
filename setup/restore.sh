#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  restore.sh – PostgreSQL-Datenbank aus Backup wiederherstellen
#  Verwendung: bash setup/restore.sh [backup-datei.sql.gz]
#  Ohne Argument: listet vorhandene Backups und fragt interaktiv.
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
BACKUP_DIR="$SCRIPT_DIR/backups"

# Datenbankname aus .env lesen
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi
DB_USER="${POSTGRES_USER:-nocodb}"
DB_NAME="${POSTGRES_DB:-nocodb}"

# ── Backup-Datei bestimmen ────────────────────────────────
if [ -n "$1" ]; then
  BACKUP_FILE="$1"
else
  echo "📂 Vorhandene Backups:"
  if ! ls "$BACKUP_DIR"/*.sql.gz 2>/dev/null; then
    echo "   Keine Backups gefunden in $BACKUP_DIR"
    exit 1
  fi
  echo ""
  printf "Backup-Datei eingeben (vollständiger Pfad oder Dateiname in backups/): "
  read -r INPUT
  if [ -f "$INPUT" ]; then
    BACKUP_FILE="$INPUT"
  elif [ -f "$BACKUP_DIR/$INPUT" ]; then
    BACKUP_FILE="$BACKUP_DIR/$INPUT"
  else
    echo "❌ Datei nicht gefunden: $INPUT"
    exit 1
  fi
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "❌ Backup-Datei nicht gefunden: $BACKUP_FILE"
  exit 1
fi

# ── Sicherheitsabfrage ────────────────────────────────────
echo ""
echo "⚠️  ACHTUNG: Die aktuelle Datenbank '$DB_NAME' wird vollständig überschrieben!"
echo "   Backup: $BACKUP_FILE"
echo ""
printf "Jetzt wiederherstellen? (ja/nein): "
read -r CONFIRM
if [ "$CONFIRM" != "ja" ]; then
  echo "Abgebrochen."
  exit 0
fi

# ── Prüfen ob Container läuft ─────────────────────────────
if ! docker ps --filter "name=nocodb_postgres" --filter "status=running" -q | grep -q .; then
  echo "❌ Container 'nocodb_postgres' läuft nicht. Starte erst mit: docker compose up -d"
  exit 1
fi

echo ""
echo "🔄 Stelle Datenbank wieder her..."

# PostgREST stoppen damit keine aktiven Verbindungen die Wiederherstellung blockieren
docker stop psa_postgrest 2>/dev/null || true

# Datenbank löschen und neu anlegen
docker exec nocodb_postgres psql -U "$DB_USER" -c "DROP DATABASE IF EXISTS $DB_NAME;" postgres
docker exec nocodb_postgres psql -U "$DB_USER" -c "CREATE DATABASE $DB_NAME;" postgres

# Backup einspielen
gunzip -c "$BACKUP_FILE" | docker exec -i nocodb_postgres psql -U "$DB_USER" "$DB_NAME"

echo "✅ Datenbank wiederhergestellt"

# PostgREST wieder starten
docker start psa_postgrest
echo "✅ PostgREST gestartet"
echo ""
echo "🌐 App verfügbar unter: http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'localhost'):8182"
