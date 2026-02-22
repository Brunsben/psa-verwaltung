#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  backup.sh – PostgreSQL-Datenbank sichern
#  Speichert einen komprimierten pg_dump in setup/backups/.
#  Behält die letzten 7 Backups, ältere werden automatisch gelöscht.
#
#  Manuell ausführen:  bash setup/backup.sh
#  Automatisch (Cron): crontab -e
#    0 2 * * * /pfad/zu/psa-verwaltung/setup/backup.sh >> /var/log/psa-backup.log 2>&1
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"
BACKUP_DIR="$SCRIPT_DIR/backups"

mkdir -p "$BACKUP_DIR"

# Datenbankname aus .env lesen (Fallback: nocodb)
if [ -f "$ENV_FILE" ]; then
  set -a; source "$ENV_FILE"; set +a
fi
DB_USER="${POSTGRES_USER:-nocodb}"
DB_NAME="${POSTGRES_DB:-nocodb}"

# Prüfen ob Container läuft
if ! docker ps --filter "name=nocodb_postgres" --filter "status=running" -q | grep -q .; then
  echo "❌ Container 'nocodb_postgres' läuft nicht."
  exit 1
fi

FILENAME="$BACKUP_DIR/psa_backup_$(date +%Y%m%d_%H%M%S).sql.gz"
echo "📦 Erstelle Backup: $FILENAME"

docker exec nocodb_postgres pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$FILENAME"

SIZE=$(du -sh "$FILENAME" | cut -f1)
echo "✅ Backup fertig ($SIZE)"

# Nur die letzten 7 Backups behalten
COUNT=$(ls "$BACKUP_DIR"/*.sql.gz 2>/dev/null | wc -l)
if [ "$COUNT" -gt 7 ]; then
  ls -t "$BACKUP_DIR"/*.sql.gz | tail -n +8 | xargs rm -f
  echo "🗑  Alte Backups bereinigt (behalte 7 neueste)"
fi

echo ""
echo "Vorhandene Backups:"
ls -lh "$BACKUP_DIR"/*.sql.gz 2>/dev/null | awk '{print "  " $5 "  " $9}'
