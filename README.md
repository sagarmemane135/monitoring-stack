
---

# 🧠 Linux Server Monitoring Stack (Docker-Based)

A **complete, production-ready, enterprise-grade monitoring stack** for Linux servers running multiple applications.
Built with **Prometheus, Alertmanager, Grafana, Loki, Node Exporter, cAdvisor, and Nginx** — all containerized and fully integrated with security hardening and SOC features.

---

## 🚀 Features

* **Full monitoring pipeline** (Prometheus → Alertmanager → Grafana)
* **Log aggregation** with Loki and Promtail (unified logs + metrics)
* **Security hardening** with security headers, TLS, and security alerts
* **SOC features** with security dashboards and audit logging
* **Nginx reverse proxy** exposing only port `443` with security headers
* **Dynamic app routing** via `default.conf` (user apps)
* **Pre-configured monitoring routes** via `monitoring.conf`
* **Multi-channel alerts** via Email (Slack, PagerDuty, Discord, Teams ready)
* **Persistent storage** with automated backup scripts
* **Optional TLS** (self-signed or custom certificates)
* **Security monitoring** with certificate expiration, process anomalies, and network alerts
* **Zero downtime reloads**
* **Everything managed with Docker Compose**

---

## 📁 Directory Structure

```
project-root/
├── docker-compose.yml
├── .env
├── nginx/
│   ├── nginx.conf
│   └── conf.d/
│       ├── default.conf        # user routes (editable)
│       └── monitoring.conf     # monitoring routes (do not edit)
├── prometheus/
│   ├── prometheus.yml
│   ├── rules.yml
│   └── security-rules.yml          # NEW: Security alerts
├── alertmanager/
│   └── alertmanager.yml.template
├── loki/
│   └── loki-config.yml             # NEW: Loki configuration
├── promtail/
│   └── promtail-config.yml         # NEW: Log shipper config
├── scripts/
│   ├── backup.sh                   # NEW: Backup automation
│   ├── restore.sh                  # NEW: Restore automation
│   └── health-check.sh             # NEW: Health validation
├── docs/
│   ├── SECURITY.md                 # NEW: Security guide
│   ├── BACKUP_RESTORE.md          # NEW: Backup procedures
│   └── ALERTING.md                # NEW: Alerting guide
├── data/
│   ├── grafana/
│   ├── prometheus/
│   └── alertmanager/
├── secrets/                    # optional: TLS and password secrets
│   ├── tls.crt
│   ├── tls.key
│   └── smtp_pass
└── README.md
```

---

## ⚙️ Environment Configuration (`.env`)

Copy and edit the example below:

```bash
# ===== General Settings =====
DOMAIN=monitor.example.com

# ===== TLS Configuration =====
# Set to "true" to use self-signed certs automatically
USE_SELF_SIGNED_TLS=true

# ===== SMTP / Email Alerts =====
ALERT_SMTP_SMARTHOST=smtp.gmail.com:587
ALERT_SMTP_FROM=monitoring@gmail.com
ALERT_SMTP_USER=monitoring@gmail.com
ALERT_SMTP_PASS=your_app_password_here
ALERT_EMAIL_TO=alerts@example.com

# ===== Alertmanager Timing (optional) =====
ALERT_GROUP_WAIT=30s
ALERT_GROUP_INTERVAL=5m
ALERT_REPEAT_INTERVAL=3h
```

> ⚠️ Add `.env` to `.gitignore` — never commit credentials.

---

## 🔐 TLS Setup Options

| Option                      | Description                                             |
| --------------------------- | ------------------------------------------------------- |
| `USE_SELF_SIGNED_TLS=true`  | Generates a self-signed certificate at first run        |
| `USE_SELF_SIGNED_TLS=false` | Expects valid `tls.crt` and `tls.key` under `./secrets` |

If using real certificates (e.g., from Let’s Encrypt):

```bash
mkdir -p secrets
cp /etc/letsencrypt/live/yourdomain/fullchain.pem secrets/tls.crt
cp /etc/letsencrypt/live/yourdomain/privkey.pem secrets/tls.key
```

---

## 🧩 Service Overview

| Service           | Port | Purpose                                 | Persistent Data       |
| ----------------- | ---- | --------------------------------------- | --------------------- |
| **Nginx**         | 443  | Reverse proxy for all apps & dashboards | none                  |
| **Prometheus**    | 9090 | Time-series metrics collection          | `./data/prometheus`   |
| **Grafana**       | 3000 | Dashboards and visualization            | `./data/grafana`      |
| **Alertmanager**  | 9093 | Alert routing and notifications         | `./data/alertmanager` |
| **Loki**          | 3100 | Log aggregation                         | `./data/loki`         |
| **Promtail**      | 9080 | Log shipper                             | none                  |
| **Node Exporter** | 9100 | Host-level metrics                      | none                  |
| **cAdvisor**      | 8080 | Container metrics                       | none                  |

---

## 🌐 Routing Rules

| Config File       | Routes                                        | Editable |
| ----------------- | --------------------------------------------- | -------- |
| `default.conf`    | `/app1/`, `/api/`, etc. (user apps)           | ✅ Yes    |
| `monitoring.conf` | `/grafana/`, `/prometheus/`, `/alertmanager/` | 🚫 No    |
| `nginx.conf`      | Global settings                               | ✅ Yes    |

Example user route in `nginx/conf.d/default.conf`:

```nginx
location /app1/ {
  proxy_pass http://host.docker.internal:8001/;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
}
```

---

## 📬 Email Alerting

Email notifications are handled by **Alertmanager** using values from `.env`.

**Supported providers:**

* Gmail (recommended, via App Password)
* Outlook / Office365
* Any custom SMTP server

Alerts are sent to `ALERT_EMAIL_TO` when thresholds defined in `prometheus/rules.yml` are exceeded.

---

## 🧠 How to Run

### 1️⃣ Clone the repo

```bash
git clone https://github.com/your-org/monitoring-stack.git
cd monitoring-stack
```

### 2️⃣ Configure environment

```bash
cp .env.example .env
# then edit .env with your SMTP and domain details
```

### 3️⃣ Start the stack

```bash
docker-compose up -d
```

If `USE_SELF_SIGNED_TLS=true`, the script will generate certs automatically and start Nginx with HTTPS.

### 4️⃣ Access the dashboards

| Service      | URL                                         |
| ------------ | ------------------------------------------- |
| Grafana      | `https://monitor.example.com/grafana/`      |
| Prometheus   | `https://monitor.example.com/prometheus/`   |
| Alertmanager | `https://monitor.example.com/alertmanager/` |
| Loki         | `https://monitor.example.com/loki`          |

### 5️⃣ Stop or restart

```bash
docker-compose down
docker-compose up -d
```

---

## 🔐 Security Features

* **Security Headers**: HSTS, X-Frame-Options, CSP, and more configured in Nginx
* **Security Alerts**: Certificate expiration, failed requests, process anomalies, network alerts
* **Security Dashboards**: Pre-built SOC dashboard for security analysts
* **Audit Logging**: Comprehensive logging of all system activities
* **TLS Hardening**: TLS 1.3 only, strong ciphers, certificate monitoring

## 📝 Log Aggregation

* **Loki Integration**: Centralized log aggregation (fully configured, no setup needed)
* **Promtail**: Automatic log collection from Docker containers, system logs, and auth logs
* **Unified Queries**: Query logs and metrics together in Grafana
* **Log Retention**: Configurable retention policies (default: 30 days)
* **Security Log Monitoring**: Failed logins, sudo attempts, SSH access automatically collected
* **Zero Configuration**: Works out of the box - all log sources pre-configured

## 🚨 Enhanced Alerting

* **Security Alerts**: Certificate expiration, network anomalies, container security
* **Multi-Channel Ready**: Email configured, Slack/PagerDuty/Discord ready
* **Alert Routing**: Route alerts by severity and service
* **Self-Monitoring**: Alerts when monitoring stack components fail
* **Alert Inhibition**: Prevents alert storms

## 🧩 Extending the Stack

| Add-on                         | Purpose                 | How                                    |
| ------------------------------ | ----------------------- | -------------------------------------- |
| **Slack / Discord alerts**    | Receive alerts via chat | Extend `alertmanager.yml` (see `docs/ALERTING.md`) |
| **PagerDuty / Opsgenie**      | On-call management      | Configure in Alertmanager (see `docs/ALERTING.md`) |
| **Let's Encrypt auto-renewal** | Real cert management    | Add `certbot` container or Traefik     |
| **Multi-server metrics**       | Central monitoring      | Add scrape targets in `prometheus.yml` |

---

## 🧰 Maintenance Commands

| Action                     | Command                                       |
| -------------------------- | --------------------------------------------- |
| Reload Prometheus config   | `docker exec prometheus kill -HUP 1`          |
| Reload Alertmanager config | `docker exec alertmanager kill -HUP 1`        |
| Reload Nginx config        | `docker exec nginx-proxy nginx -s reload`     |
| View logs                  | `docker-compose logs -f`                      |
| Update images              | `docker-compose pull && docker-compose up -d` |
| Backup stack              | `./scripts/backup.sh`                         |
| Restore from backup        | `./scripts/restore.sh <backup-name>`          |
| Health check               | `./scripts/health-check.sh`                   |

---

## 🧩 Troubleshooting

| Problem                            | Fix                                                        |
| ---------------------------------- | ---------------------------------------------------------- |
| `nginx` fails due to missing certs | Set `USE_SELF_SIGNED_TLS=true`                             |
| No emails received                 | Check Gmail App Password and SMTP values                   |
| Grafana login                      | Default user: `admin`, password: `admin`                   |
| Metrics missing                    | Verify exporters (`node_exporter`, `cadvisor`) are running |
| 502 on routes                      | Ensure internal container names match in Nginx config      |

---

## 📚 Documentation

* **[Security Guide](docs/SECURITY.md)**: Security best practices and hardening
* **[Backup & Restore](docs/BACKUP_RESTORE.md)**: Backup automation and restore procedures
* **[Alerting Guide](docs/ALERTING.md)**: Alert configuration and customization

## 📊 Pre-built Dashboards

The stack includes **8 comprehensive dashboards** ready to use:

| Dashboard | Description |
|-----------|-------------|
| **Monitoring Stack Overview** | Complete system overview with CPU, memory, disk, and containers |
| **Linux Server Dashboard** | Detailed Linux server metrics - CPU, memory, disk, network, processes |
| **Container Dashboard** | Docker container performance, resource usage, and I/O |
| **Network Dashboard** | Network traffic, connections, errors, and TCP states |
| **Storage Dashboard** | Disk usage, I/O performance, inodes, and filesystem details |
| **Security Dashboard** | SOC-focused security metrics, alerts, and threat detection |
| **Alert Overview Dashboard** | All active alerts, alert history, and categorization |
| **Executive Summary** | High-level business metrics and system health at a glance |
| **Logs Dashboard** | Centralized log viewer with filtering, search, and statistics |

All dashboards are **pre-configured** and **automatically loaded** - no configuration needed!

## 🏁 Summary

✅ Production-ready, enterprise-grade monitoring setup
✅ Security hardened with security headers and security alerts
✅ Log aggregation with Loki and Promtail (zero configuration needed)
✅ SOC-ready with security dashboards and audit logging
✅ 8 pre-built comprehensive dashboards
✅ All metrics, logs, and dashboards behind a single HTTPS endpoint
✅ Self-healing and persistent with automated backups
✅ Modular — easy to extend with additional features

---

