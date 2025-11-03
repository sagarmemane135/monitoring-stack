# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2024-01-XX

### Added
- **Log Aggregation**: Loki and Promtail integration for centralized log management
  - Automatic Docker container log collection
  - System log collection (syslog, auth.log, kernel logs)
  - Zero-configuration log aggregation
  - Pre-configured Loki datasource in Grafana
  - Log retention policies (default: 30 days)

- **Security Enhancements**:
  - Security alert rules (certificate expiration, network anomalies, container security)
  - Security headers in Nginx (HSTS, CSP, X-Frame-Options, etc.)
  - Security dashboard for SOC analysts
  - Enhanced TLS configuration with modern ciphers
  - Security-focused alerting rules

- **Comprehensive Dashboards** (9 pre-built dashboards):
  - Monitoring Stack Overview
  - Linux Server Dashboard
  - Container Dashboard
  - Network Dashboard
  - Storage Dashboard
  - Security Dashboard
  - Alert Overview Dashboard
  - Executive Summary Dashboard
  - Logs Dashboard

- **Automation Scripts**:
  - `scripts/backup.sh`: Automated backup for all monitoring data
  - `scripts/restore.sh`: Restore from backup with validation
  - `scripts/health-check.sh`: Comprehensive health validation

- **Documentation**:
  - Security guide (`docs/SECURITY.md`)
  - Backup & Restore guide (`docs/BACKUP_RESTORE.md`)
  - Alerting guide (`docs/ALERTING.md`)

### Changed
- Enhanced `docker-compose.yml` with Loki and Promtail services
- Updated Prometheus configuration to include security rules
- Improved Nginx configuration with security headers
- Updated setup script to support new services
- Enhanced README with all new features
- Resource limits and CPU quotas for all services

### Fixed
- Enhanced `.gitignore` for better file management
- Improved log collection reliability
- Better error handling in configurations

## [1.0.0] - Initial Release

### Added
- Core monitoring stack with Prometheus, Grafana, Alertmanager
- Node Exporter and cAdvisor for metrics collection
- Blackbox Exporter for endpoint monitoring
- Nginx reverse proxy with TLS support
- Basic authentication
- Email alerting via SMTP
- Pre-configured monitoring dashboard

