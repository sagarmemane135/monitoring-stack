#!/usr/bin/env bash
set -euo pipefail

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo: sudo ./setup.sh"
  exit 1
fi

echo ""
echo "========================================"
echo " 🚀 Starting Monitoring Stack Setup"
echo "========================================"
echo ""

# -----------------------------
# 0️⃣  Clean up previous runs (optional, but good for development)
# -----------------------------
echo "🧹 Cleaning up previous Docker Compose stack..."
sudo docker-compose down -v || true # Use || true to prevent script from exiting if no stack is running

# -----------------------------
# 1️⃣  Load Environment Variables
# -----------------------------
if [ ! -f ".env" ]; then
  echo "❌ ERROR: .env file not found. Please create one before running this script."
  exit 1
fi
source .env

# Export Alertmanager-related variables for envsubst
export ALERT_SMTP_SMARTHOST
export ALERT_SMTP_FROM
export ALERT_SMTP_USER
export ALERT_SMTP_PASS
export ALERT_EMAIL_TO
export ALERT_GROUP_WAIT
export ALERT_GROUP_INTERVAL
export ALERT_REPEAT_INTERVAL

# -----------------------------
# 2️⃣  Verify Required Variables
# -----------------------------
echo "🔍 Validating environment variables..."

required_vars=(
  HOSTNAME_MONITOR
  ALERT_SMTP_SMARTHOST
  ALERT_SMTP_FROM
  ALERT_SMTP_USER
  ALERT_SMTP_PASS
  ALERT_EMAIL_TO
  GF_SECURITY_ADMIN_USER
  GF_SECURITY_ADMIN_PASSWORD
  LISTEN_PORT
  USE_SELF_SIGNED_TLS
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "❌ Missing required environment variable: $var"
    exit 1
  fi
done
echo "✅ Environment validation complete."

# -----------------------------
# 3️⃣  Ensure Folder Structure
# -----------------------------
echo "📁 Ensuring directory structure..."
# Clean up previous data and secrets for a fresh start
rm -rf data secrets
mkdir -p \
  secrets \
  data/grafana \
  data/prometheus \
  data/alertmanager

# Set ownership for persistent data volumes
# Grafana runs as user 472
chown -R 472:472 data/grafana
# Prometheus and Alertmanager often run as nobody (65534)
chown -R 65534:65534 data/prometheus data/alertmanager

# Protect sensitive files
chmod 700 secrets || true

# -----------------------------
# 4️⃣  Handle TLS Certificates
# -----------------------------
if [ "${USE_SELF_SIGNED_TLS}" = "true" ]; then
  if [ ! -f "${TLS_CRT_PATH}" ] || [ ! -f "${TLS_KEY_PATH}" ]; then
    echo "🔐 Generating self-signed TLS certificates..."
    openssl req -x509 -nodes -days 365 \
      -newkey rsa:2048 \
      -keyout "${TLS_KEY_PATH}" \
      -out "${TLS_CRT_PATH}" \
      -subj "/CN=${HOSTNAME_MONITOR:-localhost}"
    echo "✅ Self-signed certificates created at ${TLS_CRT_PATH} and ${TLS_KEY_PATH}"
  else
    echo "✅ Found existing TLS certificates. Skipping generation."
  fi
else
  echo "🔒 Using provided TLS certificates..."
  if [ ! -f "${TLS_CRT_PATH}" ] || [ ! -f "${TLS_KEY_PATH}" ]; then
    echo "❌ TLS certificates not found at:"
    echo "   - ${TLS_CRT_PATH}"
    echo "   - ${TLS_KEY_PATH}"
    echo "   Please add valid certs or set USE_SELF_SIGNED_TLS=true"
    exit 1
  fi
fi

# -----------------------------
# 5️⃣  Prepare Nginx Monitoring Config
# -----------------------------
echo "⚙️ Preparing Nginx monitoring configuration..."
MONITORING_CONF_DIR="./nginx/conf.d"
MONITORING_CONF_FINAL="${MONITORING_CONF_DIR}/monitoring.conf"

# Ensure monitoring.conf is a file, not a directory
if [ -d "${MONITORING_CONF_FINAL}" ]; then
  rmdir "${MONITORING_CONF_FINAL}"
elif [ -f "${MONITORING_CONF_FINAL}" ]; then
  rm "${MONITORING_CONF_FINAL}"
fi

# Ensure monitoring.conf is a file, not a directory, and remove it if it exists
if [ -d "${MONITORING_CONF_FINAL}" ]; then
  rmdir "${MONITORING_CONF_FINAL}" || true
elif [ -f "${MONITORING_CONF_FINAL}" ]; then
  rm "${MONITORING_CONF_FINAL}" || true
fi

if [ "${USE_SELF_SIGNED_TLS}" = "true" ]; then
  cp "${MONITORING_CONF_DIR}/monitoring.tls.conf" "${MONITORING_CONF_FINAL}"
  echo "✅ Nginx configured for TLS monitoring."
else
  cp "${MONITORING_CONF_DIR}/monitoring.nontls.conf" "${MONITORING_CONF_FINAL}"
  echo "✅ Nginx configured for non-TLS monitoring."
fi

# -----------------------------
# 6️⃣  Prepare Alertmanager Config
# -----------------------------
ALERTMANAGER_TEMPLATE="./alertmanager/alertmanager.yml.template"
ALERTMANAGER_FINAL="./alertmanager/alertmanager.yml"

if [ ! -f "$ALERTMANAGER_TEMPLATE" ]; then
  echo "❌ Missing Alertmanager template: $ALERTMANAGER_TEMPLATE"
  exit 1
fi

echo "📝 Preparing Alertmanager configuration..."
envsubst < "$ALERTMANAGER_TEMPLATE" > "$ALERTMANAGER_FINAL"
chmod 600 "$ALERTMANAGER_FINAL"
# Set ownership for Alertmanager config file to match container user (nobody:65534)
chown 65534:65534 "$ALERTMANAGER_FINAL"

# -----------------------------
# 6️⃣  Start Docker Stack
# -----------------------------
echo ""
echo "🐳 Starting Docker Compose stack..."
sudo docker-compose up -d --build

# -----------------------------
# 7️⃣  Post-Setup Information
# -----------------------------
echo ""
echo "========================================"
echo " ✅ Monitoring Stack is Ready!"
echo "----------------------------------------"
echo " 🌐 Grafana Dashboard: https://${HOSTNAME_MONITOR}:${LISTEN_PORT}/grafana"
echo " 📈 Prometheus:        https://${HOSTNAME_MONITOR}:${LISTEN_PORT}/prometheus"
echo " 🚨 Alertmanager:      https://${HOSTNAME_MONITOR}:${LISTEN_PORT}/alertmanager"
echo "========================================"
echo ""
