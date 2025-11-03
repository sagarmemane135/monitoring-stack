
---

# 🧠 Linux Server Monitoring Stack (Docker-Based)

A **complete, production-ready monitoring stack** for Linux servers running multiple applications.
Built with **Prometheus, Alertmanager, Grafana, Node Exporter, cAdvisor, and Nginx** — all containerized and fully integrated.

---

## 🚀 Features

* **Full monitoring pipeline** (Prometheus → Alertmanager → Grafana)
* **Nginx reverse proxy** exposing only port `443`
* **Dynamic app routing** via `default.conf` (user apps)
* **Pre-configured monitoring routes** via `monitoring.conf`
* **Email alerts** via Gmail or any SMTP provider (using `.env` variables)
* **Persistent storage** (data saved in current folder)
* **Optional TLS** (self-signed or custom certificates)
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
│   └── rules.yml
├── alertmanager/
│   └── alertmanager.yml
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

### 5️⃣ Stop or restart

```bash
docker-compose down
docker-compose up -d
```

---

## 🧩 Extending the Stack

| Add-on                         | Purpose                 | How                                    |
| ------------------------------ | ----------------------- | -------------------------------------- |
| **Slack / Telegram alerts**    | Receive alerts via chat | Extend `alertmanager.yml`              |
| **Loki / Promtail**            | Log aggregation         | Add to `docker-compose.yml`            |
| **Let’s Encrypt auto-renewal** | Real cert management    | Add `certbot` container or Traefik     |
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

## 🏁 Summary

✅ Production-ready monitoring setup
✅ All metrics and dashboards behind a single HTTPS endpoint
✅ Self-healing and persistent
✅ Modular — easy to extend with logs, alerts, or app routing

---

