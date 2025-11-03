#!/usr/bin/env bash
set -euo pipefail

# ===============================================
# 🧭 Monitoring Stack Setup Script (with Auth)
# ===============================================

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
# 🧹 Clean up previous runs
# -----------------------------
echo "🧹 Cleaning up previous Docker Compose stack..."
sudo docker-compose down -v || true

# -----------------------------
# 🔧 Load Environment Variables
# -----------------------------
if [ ! -f ".env" ]; then
  echo "❌ ERROR: .env file not found. Please create one before running this script."
  exit 1
fi
source .env

# Export alert-related vars for envsubst
export ALERT_SMTP_SMARTHOST ALERT_SMTP_FROM ALERT_SMTP_USER ALERT_SMTP_PASS
export ALERT_EMAIL_TO ALERT_GROUP_WAIT ALERT_GROUP_INTERVAL ALERT_REPEAT_INTERVAL

# -----------------------------
# ✅ Validate Required Variables
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
  BASIC_AUTH_USER
  BASIC_AUTH_PASSWORD
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "❌ Missing required environment variable: $var"
    exit 1
  fi
done
echo "✅ Environment validation complete."

# -----------------------------
# 📁 Prepare Directory Structure
# -----------------------------
echo "📁 Ensuring directory structure..."
rm -rf data secrets nginx/auth
mkdir -p \
  secrets \
  nginx/auth \
  data/grafana \
  data/prometheus \
  data/alertmanager

# Set ownership for data
chown -R 472:472 data/grafana
chown -R 65534:65534 data/prometheus data/alertmanager
chmod 700 secrets || true

# -----------------------------
# 🔐 Generate TLS Certificates
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
    echo "❌ TLS certificates not found:"
    echo "   ${TLS_CRT_PATH}"
    echo "   ${TLS_KEY_PATH}"
    echo "   Please add valid certs or set USE_SELF_SIGNED_TLS=true"
    exit 1
  fi
fi

# -----------------------------
# 🔑 Create Basic Auth File
# -----------------------------
echo "🔑 Configuring Basic Authentication..."
AUTH_FILE="./nginx/auth/monitoring.htpasswd"
chmod 644 "${AUTH_FILE}"

# Install apache2-utils if missing (for htpasswd command)
if ! command -v htpasswd &> /dev/null; then
  echo "📦 Installing apache2-utils..."
  apt-get update -y >/dev/null
  apt-get install -y apache2-utils >/dev/null
fi

htpasswd -bc "${AUTH_FILE}" "${BASIC_AUTH_USER}" "${BASIC_AUTH_PASSWORD}"
# Fix permissions for Docker Nginx access
chmod 644 "${AUTH_FILE}"
chown root:root "${AUTH_FILE}"
chmod 755 ./nginx/auth

echo "✅ Basic auth file created and permissions fixed."

# -----------------------------
# ⚙️ Configure Nginx
# -----------------------------
echo "⚙️ Preparing Nginx monitoring configuration..."
MONITORING_CONF_DIR="./nginx/conf.d"
MONITORING_CONF_FINAL="${MONITORING_CONF_DIR}/monitoring.conf"

if [ "${USE_SELF_SIGNED_TLS}" = "true" ]; then
  cp "${MONITORING_CONF_DIR}/monitoring.tls.conf" "${MONITORING_CONF_FINAL}"
  echo "✅ Nginx configured for TLS monitoring."
else
  cp "${MONITORING_CONF_DIR}/monitoring.nontls.conf" "${MONITORING_CONF_FINAL}"
  echo "✅ Nginx configured for non-TLS monitoring."
fi

# -----------------------------
# 📬 Configure Alertmanager
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
chown 65534:65534 "$ALERTMANAGER_FINAL"

# -----------------------------
# 🐳 Start Docker Stack
# -----------------------------
echo ""
echo "🐳 Starting Docker Compose stack..."
sudo docker-compose up -d --build

# -----------------------------
# 🎉 Done!
# -----------------------------
echo ""
echo "========================================"
echo " ✅ Monitoring Stack is Ready!"
echo "----------------------------------------"
echo " 🌐 Grafana Dashboard: https://${HOSTNAME_MONITOR}:${LISTEN_PORT}/grafana"
echo " 📈 Prometheus:        https://${HOSTNAME_MONITOR}:${LISTEN_PORT}/prometheus"
echo " 🚨 Alertmanager:      https://${HOSTNAME_MONITOR}:${LISTEN_PORT}/alertmanager"
echo " 🧩 Blackbox Exporter: https://${HOSTNAME_MONITOR}:${LISTEN_PORT}/blackbox"
echo "----------------------------------------"
echo " 🔒 Basic Auth User:   ${BASIC_AUTH_USER}"
echo " 🔑 Basic Auth Pass:   ${BASIC_AUTH_PASSWORD}"
echo "========================================"
echo ""
