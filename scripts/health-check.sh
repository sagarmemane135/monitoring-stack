#!/usr/bin/env bash
set -euo pipefail

# ================================================
# Monitoring Stack Health Check Script
# ================================================

echo ""
echo "========================================"
echo " 🔍 Health Check"
echo "========================================"
echo ""

EXIT_CODE=0

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running"
  EXIT_CODE=1
else
  echo "✅ Docker is running"
fi

# Check containers
services=(
  "prometheus"
  "alertmanager"
  "grafana"
  "nginx-proxy"
  "node-exporter"
  "cadvisor"
  "blackbox-exporter"
  "loki"
  "promtail"
)

for service in "${services[@]}"; do
  if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
    STATUS=$(docker inspect --format='{{.State.Status}}' "${service}" 2>/dev/null || echo "not_found")
    if [ "${STATUS}" = "running" ]; then
      echo "✅ ${service} is running"
    else
      echo "⚠️  ${service} status: ${STATUS}"
      EXIT_CODE=1
    fi
  else
    echo "⚠️  ${service} is not running"
    EXIT_CODE=1
  fi
done

# Check health endpoints
echo ""
echo "🔍 Checking service health endpoints..."

check_health() {
  local service=$1
  local url=$2
  
  if curl -sf "${url}" > /dev/null 2>&1; then
    echo "✅ ${service} health check passed"
    return 0
  else
    echo "❌ ${service} health check failed"
    return 1
  fi
}

# Check if services are accessible
if [ -f ".env" ]; then
  source .env
  HOST="${HOSTNAME_MONITOR:-localhost}"
  PORT="${LISTEN_PORT:-443}"
  PROTOCOL="https"
  
  # Try to check Grafana (requires auth, so just check if it responds)
  if curl -sf -k "${PROTOCOL}://${HOST}:${PORT}/grafana/api/health" > /dev/null 2>&1; then
    echo "✅ Grafana is accessible"
  else
    echo "⚠️  Grafana health check failed (may require authentication)"
  fi
fi

# Check disk space
echo ""
echo "💾 Checking disk space..."
DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "${DISK_USAGE}" -gt 90 ]; then
  echo "❌ Disk usage is ${DISK_USAGE}% (critical)"
  EXIT_CODE=1
elif [ "${DISK_USAGE}" -gt 80 ]; then
  echo "⚠️  Disk usage is ${DISK_USAGE}% (warning)"
else
  echo "✅ Disk usage is ${DISK_USAGE}%"
fi

# Check data directory sizes
echo ""
echo "📊 Data directory sizes:"
if [ -d "./data" ]; then
  du -sh ./data/* 2>/dev/null | while read size dir; do
    echo "  ${size} - ${dir}"
  done
fi

echo ""
echo "========================================"
if [ ${EXIT_CODE} -eq 0 ]; then
  echo " ✅ All health checks passed"
else
  echo " ⚠️  Some health checks failed"
fi
echo "========================================"
echo ""

exit ${EXIT_CODE}

