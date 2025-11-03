#!/usr/bin/env bash
set -euo pipefail

# ================================================
# Monitoring Stack Restore Script
# ================================================

if [ $# -lt 1 ]; then
  echo "Usage: $0 <backup-name>"
  echo "Example: $0 monitoring-stack-backup-20240101_120000"
  exit 1
fi

BACKUP_DIR="${BACKUP_DIR:-./backups}"
BACKUP_NAME="$1"
BACKUP_FILE="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
TEMP_DIR=$(mktemp -d)

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "❌ Backup file not found: ${BACKUP_FILE}"
  exit 1
fi

echo ""
echo "========================================"
echo " 🔄 Starting Restore"
echo "========================================"
echo ""

# Extract backup
echo "📦 Extracting backup..."
tar -xzf "${BACKUP_FILE}" -C "${TEMP_DIR}"

# Stop services
echo "🛑 Stopping monitoring stack..."
docker-compose down || true

# Restore Prometheus data
if [ -f "${TEMP_DIR}/${BACKUP_NAME}/prometheus.tar.gz" ]; then
  echo "📊 Restoring Prometheus data..."
  rm -rf ./data/prometheus
  mkdir -p ./data/prometheus
  tar -xzf "${TEMP_DIR}/${BACKUP_NAME}/prometheus.tar.gz" -C ./data
  chown -R 65534:65534 ./data/prometheus || true
  echo "✅ Prometheus restore complete"
fi

# Restore Grafana data
if [ -f "${TEMP_DIR}/${BACKUP_NAME}/grafana.tar.gz" ]; then
  echo "📈 Restoring Grafana data..."
  rm -rf ./data/grafana
  mkdir -p ./data/grafana
  tar -xzf "${TEMP_DIR}/${BACKUP_NAME}/grafana.tar.gz" -C ./data
  chown -R 472:472 ./data/grafana || true
  echo "✅ Grafana restore complete"
fi

# Restore Alertmanager data
if [ -f "${TEMP_DIR}/${BACKUP_NAME}/alertmanager.tar.gz" ]; then
  echo "🚨 Restoring Alertmanager data..."
  rm -rf ./data/alertmanager
  mkdir -p ./data/alertmanager
  tar -xzf "${TEMP_DIR}/${BACKUP_NAME}/alertmanager.tar.gz" -C ./data
  chown -R 65534:65534 ./data/alertmanager || true
  echo "✅ Alertmanager restore complete"
fi

# Restore Loki data
if [ -f "${TEMP_DIR}/${BACKUP_NAME}/loki.tar.gz" ]; then
  echo "📝 Restoring Loki data..."
  rm -rf ./data/loki
  mkdir -p ./data/loki
  tar -xzf "${TEMP_DIR}/${BACKUP_NAME}/loki.tar.gz" -C ./data
  echo "✅ Loki restore complete"
fi

# Restore configurations (optional, prompts user)
echo ""
read -p "Do you want to restore configuration files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "⚙️  Restoring configuration files..."
  if [ -d "${TEMP_DIR}/${BACKUP_NAME}/configs" ]; then
    cp -r "${TEMP_DIR}/${BACKUP_NAME}/configs/"* ./
    echo "✅ Configuration restore complete"
    echo "⚠️  Please review configuration files before starting services"
  fi
fi

# Cleanup
rm -rf "${TEMP_DIR}"

echo ""
echo "========================================"
echo " ✅ Restore Complete!"
echo "----------------------------------------"
echo " ⚠️  Review configurations if restored"
echo " 🚀 Start services with: docker-compose up -d"
echo "========================================"
echo ""

