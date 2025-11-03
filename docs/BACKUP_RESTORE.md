# Backup and Restore Procedures

This document describes how to backup and restore the monitoring stack.

## Automated Backups

### Scheduled Backups
Use cron or a scheduled task to run backups automatically:

```bash
# Daily backup at 2 AM
0 2 * * * /path/to/monitoring-stack/scripts/backup.sh
```

### Manual Backups
Run the backup script manually:

```bash
./scripts/backup.sh
```

### Backup Location
Backups are stored in `./backups/` by default. You can override this:

```bash
BACKUP_DIR=/path/to/backups ./scripts/backup.sh
```

### Cleanup Old Backups
To automatically clean up backups older than 7 days:

```bash
CLEANUP_OLD_BACKUPS=true ./scripts/backup.sh
```

## What Gets Backed Up

### Data Volumes
- **Prometheus**: Metrics and time-series data
- **Grafana**: Dashboards, users, preferences
- **Alertmanager**: Alert state and history
- **Loki**: Log data (if enabled)

### Configuration Files
- All Prometheus configuration files
- Grafana provisioning files
- Alertmanager configuration
- Nginx configuration
- Docker Compose file
- Setup script

## Restore Procedures

### Full Restore
To restore from a backup:

```bash
./scripts/restore.sh monitoring-stack-backup-20240101_120000
```

### Selective Restore
The restore script allows you to choose whether to restore configuration files.

### Restore Steps
1. Stop the monitoring stack
2. Extract backup files
3. Restore data volumes
4. Optionally restore configuration files
5. Start the stack

## Backup Verification

### Verify Backup Integrity
```bash
tar -tzf backups/monitoring-stack-backup-*.tar.gz
```

### Test Restore
Regularly test restore procedures to ensure backups are valid.

## Backup Storage

### Local Storage
- Store backups on a separate disk if possible
- Use RAID for redundancy

### Remote Storage
For production, consider:
- **S3**: AWS S3 or compatible storage
- **Azure Blob**: Azure storage
- **Google Cloud Storage**: GCS buckets
- **SFTP/SCP**: Secure file transfer
- **NFS**: Network file system

### Backup Rotation
- Keep daily backups for 7 days
- Keep weekly backups for 4 weeks
- Keep monthly backups for 12 months

## Best Practices

1. **Regular Backups**: Run backups daily
2. **Verify Backups**: Test restore procedures regularly
3. **Off-site Storage**: Store backups off-site
4. **Encryption**: Encrypt sensitive backups
5. **Automation**: Use cron or scheduled tasks
6. **Monitoring**: Monitor backup success/failure
7. **Documentation**: Document restore procedures

## Backup Script Customization

### Environment Variables
- `BACKUP_DIR`: Backup storage location
- `CLEANUP_OLD_BACKUPS`: Auto-cleanup flag

### Adding Custom Backups
Edit `scripts/backup.sh` to add custom backup targets.

## Restore Troubleshooting

### Permission Issues
If you encounter permission issues:
```bash
sudo chown -R 472:472 data/grafana
sudo chown -R 65534:65534 data/prometheus data/alertmanager
```

### Missing Directories
The restore script creates necessary directories automatically.

### Configuration Conflicts
If configuration conflicts occur, restore configuration files separately or manually merge changes.

