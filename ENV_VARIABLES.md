# Environment Variables Reference

Complete reference of all environment variables used in the monitoring stack.

## Required Variables

These variables are **required** and will be validated by `setup.sh`:

### General Settings
- `HOSTNAME_MONITOR` - Domain or IP where the monitoring stack is accessible (e.g., `monitor.example.com`)
- `LISTEN_PORT` - Port for Nginx to listen on (default: `443`)
- `USE_SELF_SIGNED_TLS` - Generate self-signed certificates automatically (`true`/`false`)

### Authentication
- `BASIC_AUTH_USER` - Username for Basic Auth (Nginx protection for Prometheus, Alertmanager, etc.)
- `BASIC_AUTH_PASSWORD` - Password for Basic Auth (use strong password)
- `GF_SECURITY_ADMIN_USER` - Grafana admin username
- `GF_SECURITY_ADMIN_PASSWORD` - Grafana admin password (use strong password)

### Email/SMTP Configuration
- `ALERT_SMTP_SMARTHOST` - SMTP server (e.g., `smtp.gmail.com:587`)
- `ALERT_SMTP_FROM` - Email address that sends alerts (e.g., `monitoring@example.com`)
- `ALERT_SMTP_USER` - SMTP username (usually same as FROM)
- `ALERT_SMTP_PASS` - SMTP password (for Gmail, use App Password)
- `ALERT_EMAIL_TO` - Email address to receive alerts

### TLS Certificate Paths (when USE_SELF_SIGNED_TLS=false)
- `TLS_CRT_PATH` - Path to TLS certificate (default: `./secrets/tls.crt`)
- `TLS_KEY_PATH` - Path to TLS private key (default: `./secrets/tls.key`)

## Optional Variables

### Alertmanager Timing
- `ALERT_GROUP_WAIT` - Wait before sending first alert (default: `30s`)
- `ALERT_GROUP_INTERVAL` - Wait between alert groups (default: `5m`)
- `ALERT_REPEAT_INTERVAL` - Repeat alerts interval (default: `3h`)

### Loki Configuration
- `LOKI_RETENTION_HOURS` - Log retention period (default: `720h` = 30 days)
- `LOKI_MAX_QUERY_LENGTH` - Maximum query length (default: `721h`)
- `LOKI_MAX_QUERY_PARALLELISM` - Maximum query parallelism (default: `32`)
- `LOKI_INGESTION_RATE_MB` - Ingestion rate limit in MB/s (default: `16`)
- `LOKI_INGESTION_BURST_SIZE_MB` - Ingestion burst size in MB (default: `32`)
- `LOKI_CACHE_SIZE_MB` - Cache size for query results in MB (default: `100`)

### Nginx Configuration
- `USE_TLS` - Enable TLS/HTTPS (default: `true`)

### Security Alert Thresholds (Optional - used in Prometheus rules)
These are currently hardcoded in `prometheus/security-rules.yml` but can be customized:
- `CERT_EXPIRY_DAYS` - Certificate expiration warning (default: `7`)
- `HIGH_PROCESS_THRESHOLD` - Process count threshold (default: `500`)
- `HIGH_CONNECTION_THRESHOLD` - Network connection threshold (default: `1000`)
- `MEMORY_GROWTH_THRESHOLD` - Memory growth threshold in bytes (default: `100000000`)
- `IO_WAIT_THRESHOLD` - I/O wait threshold percentage (default: `50`)

### Advanced Features (Future)
- `ENABLE_OAUTH2` - Enable OAuth2 proxy (default: `false`)
- `ENABLE_AUTO_CERTS` - Enable automatic certificate management (default: `false`)

### Advanced Alerting (Optional)
- `ALERT_SLACK_WEBHOOK_URL` - Slack webhook URL for alerts
- `ALERT_PAGERDUTY_INTEGRATION_KEY` - PagerDuty integration key
- `ALERT_DISCORD_WEBHOOK_URL` - Discord webhook URL
- `ALERT_TEAMS_WEBHOOK_URL` - Microsoft Teams webhook URL

### IP Whitelisting (Optional)
- `ALLOWED_IPS` - Comma-separated list of IPs/networks to allow access

## Variable Usage in Codebase

### docker-compose.yml
Uses:
- `HOSTNAME_MONITOR`
- `LISTEN_PORT`
- `USE_TLS`
- `GF_SECURITY_ADMIN_USER`
- `GF_SECURITY_ADMIN_PASSWORD`

### setup.sh
Validates and uses:
- All required variables listed above
- `TLS_CRT_PATH` and `TLS_KEY_PATH` (when USE_SELF_SIGNED_TLS=false)

### alertmanager/alertmanager.yml.template
Uses (via envsubst):
- `ALERT_SMTP_SMARTHOST`
- `ALERT_SMTP_FROM`
- `ALERT_SMTP_USER`
- `ALERT_SMTP_PASS`
- `ALERT_EMAIL_TO`
- `ALERT_GROUP_WAIT`
- `ALERT_GROUP_INTERVAL`
- `ALERT_REPEAT_INTERVAL`

### loki/loki-config.yml
Uses (via environment variable substitution):
- `LOKI_RETENTION_HOURS`
- `LOKI_MAX_QUERY_LENGTH`
- `LOKI_MAX_QUERY_PARALLELISM`
- `LOKI_INGESTION_RATE_MB`
- `LOKI_INGESTION_BURST_SIZE_MB`
- `LOKI_CACHE_SIZE_MB`

### nginx/conf.d/*.conf
Uses (via environment variable substitution):
- `HOSTNAME_MONITOR`

## Setup Instructions

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` with your actual values:
   ```bash
   nano .env  # or use your preferred editor
   ```

3. Minimum required changes:
   - `HOSTNAME_MONITOR` - Set to your domain or IP
   - `BASIC_AUTH_PASSWORD` - Use a strong password
   - `GF_SECURITY_ADMIN_PASSWORD` - Use a strong password
   - `ALERT_SMTP_*` - Configure your SMTP settings
   - `ALERT_EMAIL_TO` - Set where alerts should be sent

4. Run setup script:
   ```bash
   ./setup.sh
   ```

5. Start the stack:
   ```bash
   docker-compose up -d
   ```

## Gmail SMTP Setup

For Gmail SMTP, you need to:

1. Enable 2-Factor Authentication on your Google account
2. Generate an App Password:
   - Go to: https://myaccount.google.com/apppasswords
   - Select "Mail" and your device
   - Generate and copy the App Password
3. Use the App Password for `ALERT_SMTP_PASS`
4. Use `smtp.gmail.com:587` for `ALERT_SMTP_SMARTHOST`

## Example .env Configuration

```bash
# Minimal working configuration
HOSTNAME_MONITOR=monitor.example.com
LISTEN_PORT=443
USE_TLS=true
USE_SELF_SIGNED_TLS=true

BASIC_AUTH_USER=admin
BASIC_AUTH_PASSWORD=your_strong_password_here
GF_SECURITY_ADMIN_USER=admin
GF_SECURITY_ADMIN_PASSWORD=your_strong_password_here

ALERT_SMTP_SMARTHOST=smtp.gmail.com:587
ALERT_SMTP_FROM=monitoring@example.com
ALERT_SMTP_USER=monitoring@example.com
ALERT_SMTP_PASS=your_gmail_app_password
ALERT_EMAIL_TO=alerts@example.com

ALERT_GROUP_WAIT=30s
ALERT_GROUP_INTERVAL=5m
ALERT_REPEAT_INTERVAL=3h
```

