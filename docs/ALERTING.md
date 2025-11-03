# Alerting Configuration Guide

This guide explains how to configure alerting in the monitoring stack.

## Alert Types

### System Alerts
- **InstanceDown**: Service is unreachable
- **HostHighCPU**: CPU usage exceeds 90%
- **HostHighMemoryUsage**: Memory usage exceeds 85%
- **LowDiskSpace**: Disk space below 10%

### Container Alerts
- **ContainerHighCPU**: Container CPU usage >90%
- **ContainerHighMemory**: Container memory usage >90%
- **ContainerRestartingFrequently**: Container restarting multiple times

### Security Alerts
- **CertificateExpiringSoon**: Certificate expiring within 7 days
- **CertificateExpired**: Certificate has expired
- **HighFailedHTTPRequests**: High rate of failed requests
- **HighProcessCount**: Unusual number of processes
- **HighNetworkConnections**: Unusual network connections
- **ContainerRunningAsRoot**: Container running as root user
- **UnusualMemoryGrowth**: Unusual memory consumption
- **HighIOWait**: High I/O wait time

### Monitoring Stack Alerts
- **PrometheusDown**: Prometheus is down
- **AlertmanagerDown**: Alertmanager is down
- **GrafanaDown**: Grafana is down
- **LokiDown**: Loki is down

## Alert Configuration

### Prometheus Alert Rules
Alert rules are defined in:
- `prometheus/rules.yml`: System and container alerts
- `prometheus/security-rules.yml`: Security alerts

### Alert Severity Levels
- **Critical**: Immediate action required
- **Warning**: Monitor and plan action

### Alert Timing
- **Evaluation Interval**: 30 seconds
- **Scrape Interval**: 15 seconds

## Alertmanager Configuration

### Email Alerts
Configure SMTP settings in `.env`:
```bash
ALERT_SMTP_SMARTHOST=smtp.gmail.com:587
ALERT_SMTP_FROM=monitoring@example.com
ALERT_SMTP_USER=monitoring@example.com
ALERT_SMTP_PASS=your_password
ALERT_EMAIL_TO=alerts@example.com
```

### Alert Timing
- **Group Wait**: 30s (wait before sending first alert)
- **Group Interval**: 5m (wait between alert groups)
- **Repeat Interval**: 3h (repeat alerts every 3 hours)

### Alert Routing
Alerts are grouped by:
- Alert name
- Instance

## Advanced Alerting (Future)

### Slack Integration
To enable Slack notifications, add to Alertmanager config:
```yaml
receivers:
  - name: 'slack-notifications'
    slack_configs:
      - api_url: '${ALERT_SLACK_WEBHOOK_URL}'
        channel: '#alerts'
```

### PagerDuty Integration
```yaml
receivers:
  - name: 'pagerduty-notifications'
    pagerduty_configs:
      - service_key: '${ALERT_PAGERDUTY_INTEGRATION_KEY}'
```

### Multiple Recipients
You can configure multiple receivers and route different alerts to different channels.

## Customizing Alert Thresholds

### Environment Variables
Some security alert thresholds can be configured via `.env`:
- `CERT_EXPIRY_DAYS`: Certificate expiration warning (default: 7)
- `HIGH_PROCESS_THRESHOLD`: Process count threshold (default: 500)
- `HIGH_CONNECTION_THRESHOLD`: Network connection threshold (default: 1000)
- `MEMORY_GROWTH_THRESHOLD`: Memory growth threshold (default: 100000000)
- `IO_WAIT_THRESHOLD`: I/O wait threshold (default: 50)

### Modifying Alert Rules
Edit `prometheus/rules.yml` or `prometheus/security-rules.yml` to customize alerts.

After modifying rules, reload Prometheus:
```bash
docker exec prometheus kill -HUP 1
```

## Alert Inhibition

Alert inhibition prevents alert storms by suppressing certain alerts when others are firing.

Example: If Prometheus is down, don't alert about all other services being down.

## Alert Grouping

Related alerts are grouped together:
- Alerts with the same name and instance are grouped
- Alerts are sent together in one notification

## Testing Alerts

### Trigger a Test Alert
You can manually trigger alerts using Prometheus query:
```promql
up{job="prometheus"} == 0
```

### Silence Alerts
Use Alertmanager UI to silence alerts:
- Access at `/alertmanager`
- Click "Silence" button
- Set duration and labels

## Best Practices

1. **Tune Thresholds**: Adjust thresholds based on your environment
2. **Avoid Alert Fatigue**: Don't send too many alerts
3. **Escalation**: Use different channels for different severities
4. **Documentation**: Document alert runbooks
5. **Testing**: Regularly test alert delivery
6. **Monitoring**: Monitor alert delivery itself

