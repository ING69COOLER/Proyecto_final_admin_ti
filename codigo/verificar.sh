#!/usr/bin/env bash
# verificar.sh — Chequeo rápido del estado de los 6 servicios EPA (ejecutar en el servidor)
echo "== Verificación de servicios EPA =="

check() { systemctl is-active --quiet "$1" && echo "[OK]   $2 activo" || echo "[FALLA] $2 inactivo"; }

check ntpsec             "NTP (ntpsec)"
check nfs-kernel-server  "NFS"
check ypserv             "NIS (ypserv)"
check cups               "CUPS"
check smbd               "Samba (smbd)"

echo
echo "-- NTP peers --";    ntpq -p 2>/dev/null | tail -n +2 || echo "ntpq no disponible"
echo "-- Exports NFS --";  sudo exportfs -v 2>/dev/null || echo "sin exports"
echo "-- Usuarios NIS --"; ypcat passwd 2>/dev/null | cut -d: -f1 | paste -sd' ' || echo "NIS no responde"
echo "-- Impresoras --";   lpstat -p 2>/dev/null || echo "sin impresoras"
echo "-- Recursos Samba --"; sudo smbstatus --shares 2>/dev/null | head || testparm -s 2>/dev/null | grep '^\['
echo "-- Contenedores Podman --"; podman ps --format '{{.Names}}: {{.Status}}' 2>/dev/null || echo "podman no disponible"
echo "-- Dokploy (Docker) --"; docker ps --format '{{.Names}}: {{.Status}}' 2>/dev/null || echo "docker no disponible"
