# Proyecto Final — Infraestructura de TI para EPA E.S.P.

**Universidad del Quindío** — Facultad de Ingeniería de Sistemas y Computación\
**Programa:** Ingeniería de Sistemas y Computación\
**Curso:** Administración de Infraestructura de TI\
**Docente:** Maycol Cárdenas Acevedo\
**Empresa objeto de estudio:** Empresas Públicas de Armenia E.S.P. (EPA)\
**Fecha de entrega:** 8 de noviembre de 2026

**Integrantes:**
Santiago Solarte Trujillo\
Manuel Pineda Varela

---

El presente repositorio contiene la implementación de los servicios de infraestructura de
tecnologías de la información para **Empresas Públicas de Armenia E.S.P. (EPA)**, integrando
los tres ejes temáticos del curso —**Multipass** (virtualización), **Podman**
(contenedorización) y **Dokploy** (plataforma como servicio)— junto con los servicios
Linux tradicionales requeridos.

---

## Estructura del repositorio

```
proyecto-final/
├── analisis.md          # Análisis de necesidades, tabla de requisitos, costo-beneficio
├── diagrama.mmd         # Diagrama de arquitectura (Mermaid)
├── documentacion.md     # Documentación técnica: instalación, verificación, solución de problemas
├── GUIA-MONTAJE.md      # Guía secuencial de montaje con puntos de captura
├── EVIDENCIAS.md        # Galería de capturas de todos los servicios funcionando
├── README.md            # Este archivo
├── capturas/            # Screenshots (fase1..fase6 + nombres descriptivos)
└── codigo/              # Configuraciones y scripts propios
    ├── 01-netcfg.yaml   # IP fija (Netplan)
    ├── ntp.conf         # Servidor NTP
    ├── exports          # NFS
    ├── yp.conf.server   # NIS (servidor)
    ├── yp.conf.client   # NIS (cliente)
    ├── cupsd.conf       # CUPS
    ├── smb.conf         # Samba
    ├── firewall.sh      # UFW (opcional)
    ├── backup.sh        # Respaldo diario (opcional)
    ├── verificar.sh     # Chequeo de los servicios
    ├── podman-compose.yml  # App EPA + PostgreSQL con Podman (contenedores)
    └── sitio-web/       # App Node.js/Express del portal EPA
        ├── package.json
        ├── Containerfile    # Imagen (Podman / Docker / Dokploy)
        ├── src/index.js     # Servidor Express (/, /health, /info, /api/estado-bd)
        └── public/index.html
```

## Parámetros de red

| Parámetro | Valor |
|---|---|
| Servidor | `srv-epa` — `192.168.101.100` (IP fija, bridged) |
| Red local | `192.168.101.0/24` |
| Dominio NIS | `epa.local` |
| Dominio web | `epa-armenia.duckdns.org` |
| SO | Ubuntu Server 24.04 LTS (2 vCPU / 4 GB / 40 GB) |
| Hipervisor | Multipass (VM `srv-epa` servidor + `cli-epa` cliente, bridged) |
| Contenedores | Podman + Podman Compose |
| PaaS | Dokploy (Docker Swarm + Traefik) |

## Servicios implementados

| # | Servicio | Puerto | Tema | Estado |
|---|----------|--------|------|--------|
| 1 | NTP | 123 | Linux | Sí |
| 2 | NFS | 2049 | Linux | Sí |
| 3 | NIS | 111 | Linux | Sí |
| 4 | CUPS | 631 | Linux | Sí |
| 5 | Samba | 445 | Linux | Sí |
| 6 | App EPA + PostgreSQL (contenedores) | 8080 | Podman | Sí |
| 7 | Portal EPA + BD | 80/443 | Dokploy | Sí |

> Las VMs corren sobre **Multipass**. Todos los servicios fueron implementados y
> verificados; las evidencias gráficas están en **[EVIDENCIAS.md](EVIDENCIAS.md)** y
> embebidas en [documentacion.md](documentacion.md).

## Puesta en marcha rápida

> Para el procedimiento completo, secuencial y con los puntos de captura señalados,
> consúltese la **[Guía de Montaje](GUIA-MONTAJE.md)**.

1. Crear las VMs con **Multipass** y configurar IP fija (ver [documentacion.md](documentacion.md) §0).
2. Copiar los archivos de [`codigo/`](codigo/) a sus rutas e instalar los servicios Linux
   (secciones 1–5 de [documentacion.md](documentacion.md)).
3. Levantar la app + BD con **Podman** (§6):

   ```bash
   cd codigo && podman-compose up -d
   ```

4. Publicar el portal con **Dokploy** + SSL (§7).
5. Verificar todo:

   ```bash
   bash codigo/verificar.sh
   ```

6. Tomar las capturas y guardarlas en [`capturas/`](capturas/).

## Cronograma (4 semanas)

- **Semana 1:** Análisis y diagrama → `analisis.md` + `diagrama.mmd`
- **Semana 2:** Virtualización (Multipass) + Dokploy base + NTP + SSL
- **Semana 3:** Servicios Linux (NFS, NIS, CUPS, Samba) + contenedores Podman
- **Semana 4:** Documentación final + presentación

## Recursos

- [Documentación Multipass](https://canonical.com/multipass/docs)
- [Documentación Podman](https://docs.podman.io)
- [Documentación Dokploy](https://docs.dokploy.com)
- [DuckDNS (DNS dinámico gratis)](https://www.duckdns.org)
