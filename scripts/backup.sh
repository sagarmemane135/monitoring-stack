#!/usr/bin/env bash
set -euo pipefail

# ================================================
# Monitoring Stack Backup Script
# ================================================

BACKUP_DIR="${BACKUP_DIR:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="monitoring-stack-backup-${TIMESTAMP}"
BACKUP_PATH="${BACKUP_DIR}/${BACKUP_NAME}"

echo ""
echo "========================================"
echo " 🔄 Starting Backup"
echo "========================================"
echo ""

# Create backup directory
mkdir -p "${BACKUP_PATH}"

# Load environment variables if .env exists
if [ -f ".env" ]; then
  source .env
fi

# Backup Prometheus data
if [ -d "./data/prometheus" ]; then
  echo "📊 Backing up Prometheus data..."
  tar -czf "${BACKUP_PATH}/prometheus.tar.gz" -C ./data prometheus || true
  echo "✅ Prometheus backup complete"
fi

# Backup Grafana data
if [ -d "./data/grafana" ]; then
  echo "📈 Backing up Grafana data..."
  tar -czf "${BACKUP_PATH}/grafana.tar.gz" -C ./data grafana || true
  echo "✅ Grafana backup complete"
fi

# Backup Alertmanager data
if [ -d "./data/alertmanager" ]; then
  echo "🚨 Backing up Alertmanager data..."
  tar -czf "${BACKUP_PATH}/alertmanager.tar.gz" -C ./data alertmanager || true
  echo "✅ Alertmanager backup complete"
fi

# Backup Loki data (if exists)
if [ -d "./data/loki" ]; then
  echo "📝 Backing up Loki data..."
  tar -czf "${BACKUP_PATH}/loki.tar.gz" -C ./data loki || true
  echo "✅ Loki backup complete"
fi

# Backup configuration files
echo "⚙️  Backing up configuration files..."
mkdir -p "${BACKUP_PATH}/configs"
cp -r ./prometheus "${BACKUP_PATH}/configs/" || true
cp -r ./grafana "${BACKUP_PATH}/configs/" || true
cp -r ./alertmanager "${BACKUP_PATH}/configs/" || true
cp -r ./nginx "${BACKUP_PATH}/configs/" || true
cp -r ./blackbox-exporter "${BACKUP_PATH}/configs/" || true
cp -r ./loki "${BACKUP_PATH}/configs/" 2>/dev/null || true
cp -r ./promtail "${BACKUP_PATH}/configs/" 2>/dev/null || true
cp docker-compose.yml "${BACKUP_PATH}/configs/" || true
cp setup.sh "${BACKUP_PATH}/configs/" || true
echo "✅ Configuration backup complete"

# Create backup manifest
cat > "${BACKUP_PATH}/backup-manifest.txt" <<EOF
Monitoring Stack Backup
=======================
Timestamp: ${TIMESTAMP}
Backup Date: $(date)
Hostname: $(hostname)

Contents:
- Prometheus data
- Grafana data
- Alertmanager data
- Loki data (if exists)
- All configuration files

To restore:
./scripts/restore.sh ${BACKUP_NAME}
EOF

# Compress entire backup
echo "📦 Compressing backup..."
cd "${BACKUP_DIR}"
tar -czf "${BACKUP_NAME}.tar.gz" "${BACKUP_NAME}"
cd - > /dev/null
rm -rf "${BACKUP_PATH}"

# Calculate backup size
BACKUP_SIZE=$(du -h "${BACKUP_DIR}/${BACKUP_NAME}.tar.gz" | cut -f1)

echo ""
echo "========================================"
echo " ✅ Backup Complete!"
echo "----------------------------------------"
echo " 📦 Backup file: ${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
echo " 📊 Size: ${BACKUP_SIZE}"
echo "========================================"
echo ""

# Optional: Cleanup old backups (keep last 7 days)
if [ "${CLEANUP_OLD_BACKUPS:-false}" = "true" ]; then
  echo "🧹 Cleaning up old backups (keeping last 7 days)..."
  find "${BACKUP_DIR}" -name "monitoring-stack-backup-*.tar.gz" -mtime +7 -delete || true
  echo "✅ Cleanup complete"
fi

