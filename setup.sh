#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "========================================"
echo " 🚀 Starting Monitoring Stack Setup"
echo "========================================"
echo ""

# -----------------------------
# 1️⃣  Load Environment Variables
# -----------------------------
if [ ! -f ".env" ]; then
  echo "❌ ERROR: .env file not found. Please create one before running this script."
  exit 1
fi
source .env

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
mkdir -p \
  secrets \
  data/grafana \
  data/prometheus \
  data/alertmanager

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
# 5️⃣  Prepare Alertmanager Config
# -----------------------------
ALERTMANAGER_TEMPLATE="./alertmanager/alertmanager.yml.template"
ALERTMANAGER_FINAL="./alertmanager/alertmanager.yml"

if [ ! -f "$ALERTMANAGER_TEMPLATE" ]; then
  echo "❌ Missing Alertmanager template: $ALERTMANAGER_TEMPLATE"
  exit 1
fi

echo "📝 Preparing Alertmanager configuration..."
cp "$ALERTMANAGER_TEMPLATE" "$ALERTMANAGER_FINAL"
chmod 600 "$ALERTMANAGER_FINAL"

# -----------------------------
# 6️⃣  Start Docker Stack
# -----------------------------
echo ""
echo "🐳 Starting Docker Compose stack..."
docker-compose up -d --build

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
