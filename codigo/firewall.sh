#!/usr/bin/env bash
# firewall.sh — Abre solo los puertos de los servicios EPA (opcional, puntos extra)
set -euo pipefail

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow 22/tcp       # SSH
sudo ufw allow 80,443/tcp   # Web (Dokploy/Traefik)
sudo ufw allow 3000/tcp     # Panel Dokploy
sudo ufw allow 123/udp      # NTP
sudo ufw allow 2049/tcp     # NFS
sudo ufw allow 111          # RPC (NIS/NFS)
sudo ufw allow 631/tcp      # CUPS
sudo ufw allow samba        # Samba (139,445)
sudo ufw allow 5432/tcp     # PostgreSQL (si se accede desde la red)

sudo ufw --force enable
sudo ufw status verbose
