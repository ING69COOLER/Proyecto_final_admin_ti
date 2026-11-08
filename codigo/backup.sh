#!/usr/bin/env bash
# backup.sh — Respaldo diario de datos y configs de EPA (opcional, puntos extra)
# Instalar en cron: (crontab -e)  ->  0 2 * * * /ruta/backup.sh
set -euo pipefail

DEST="/var/backups/epa"
FECHA="$(date +%Y%m%d-%H%M)"
sudo mkdir -p "$DEST"

sudo tar czf "$DEST/datos-$FECHA.tar.gz" \
  /srv/nfs/epa \
  /srv/samba/epa 2>/dev/null || true

sudo tar czf "$DEST/configs-$FECHA.tar.gz" \
  /etc/ntp.conf /etc/exports /etc/yp.conf \
  /etc/cups/cupsd.conf /etc/samba/smb.conf 2>/dev/null || true

# Conservar solo los últimos 7 respaldos
sudo find "$DEST" -name '*.tar.gz' -mtime +7 -delete
echo "Backup EPA completado: $DEST ($FECHA)"
