# Análisis y Diseño de Infraestructura de TI — EPA E.S.P.

**Universidad del Quindío** — Facultad de Ingeniería de Sistemas y Computación
**Programa:** Ingeniería de Sistemas y Computación
**Curso:** Administración de Infraestructura de TI
**Docente:** Maycol Cárdenas Acevedo
**Estudiante:** Manuel Pineda Varela
**Empresa objeto de estudio:** Empresas Públicas de Armenia E.S.P. (EPA) — servicios públicos domiciliarios (acueducto, alcantarillado y aseo), Armenia, Quindío
**Fecha de entrega:** 8 de noviembre de 2026

---

## 1. Contexto de la empresa

EPA E.S.P. presta servicios de acueducto, alcantarillado y aseo en el municipio de
Armenia. Opera con una sede administrativa y personal técnico en campo (operarios de
redes, lecturistas, laboratorio de calidad de agua). Su operación diaria depende de:

- Gestión de usuarios y suscriptores del servicio.
- Documentación técnica compartida: planos de redes, actas, informes de laboratorio.
- Impresión masiva de facturas y reportes.
- Un sitio institucional para trámites y transparencia (PQRS, tarifas, noticias).

El director de TI solicita **centralizar** la gestión de servicios sobre un servidor
local, en lugar de mantener cada servicio disperso en equipos individuales. Esto reduce
costos de licenciamiento, mejora la seguridad (un solo punto de control de usuarios) y
facilita el respaldo de la información.

## 2. Necesidades identificadas y justificación de cada servicio

| Necesidad de la empresa | Servicio propuesto | Justificación |
|---|---|---|
| Portal institucional para usuarios (PQRS, tarifas, transparencia) | **Web (Nginx) + SSL** sobre Dokploy | EPA debe cumplir la Ley 1712 de transparencia. Un sitio HTTPS centraliza la información pública y da imagen institucional confiable. |
| Hora unificada en todos los equipos (facturación, logs, auditoría) | **NTP** | Los registros de lectura, facturación y auditoría deben tener marcas de tiempo consistentes. Sin sincronización, los logs no son confiables para investigaciones. |
| Compartir planos y documentos técnicos entre equipos Linux | **NFS** | Los operarios y el área de redes trabajan en estaciones Linux; NFS da acceso nativo y de bajo overhead a un repositorio común de planos y actas. |
| Un solo usuario/clave por empleado para todos los servicios | **NIS** | Centraliza la autenticación. Un empleado nuevo o retirado se gestiona una sola vez, no equipo por equipo. Reduce errores y riesgos de seguridad. |
| Impresión compartida de facturas y reportes | **CUPS** | Evita comprar una impresora por puesto. Una cola central administra prioridades e historial de impresión de facturas. |
| Compartir carpetas con personal administrativo (Windows) | **Samba** | El área administrativa usa Windows/Mac. Samba expone carpetas compartidas accesibles desde esos sistemas sin software adicional. |
| Almacenar datos del portal (PQRS, suscriptores) | **Base de datos (PostgreSQL)** | El sitio web necesita persistir formularios de PQRS y consultas. PostgreSQL es robusto y gratuito. |
| Probar y empaquetar la app antes de publicarla | **Contenedores con Podman** | El portal y su base de datos se construyen y prueban como contenedores (imágenes reproducibles, aislamiento, volúmenes para persistencia) antes de pasar a producción. |

### Plataforma tecnológica (temas del curso)

La solución integra las tres herramientas vistas en el curso, cada una en su rol natural:

- **Multipass** — hipervisor que crea las máquinas virtuales (servidor `srv-epa` y cliente `cli-epa`).
- **Podman** — motor de contenedores *daemonless/rootless*; corre el portal EPA + PostgreSQL como entorno interno/dev con `podman-compose`.
- **Dokploy** — plataforma PaaS (Docker Swarm + Traefik) que publica el portal con Git + Let's Encrypt (SSL) y una base de datos administrada.

## 3. Tabla de requisitos técnicos

| # | Servicio | IP servidor | Puerto | Protocolo | Tipo |
|---|----------|-------------|--------|-----------|------|
| 1 | Web (Nginx/Dokploy) | 192.168.101.100 | 80 / 443 | HTTP/HTTPS (TCP) | Aplicación web |
| 2 | NTP | 192.168.101.100 | 123 | NTP (UDP) | Sincronización de tiempo |
| 3 | NFS | 192.168.101.100 | 2049 | NFS (TCP) | Archivos (Linux) |
| 4 | NIS | 192.168.101.100 | 111 + dinámico | RPC/Sun RPC (TCP/UDP) | Autenticación |
| 5 | CUPS | 192.168.101.100 | 631 | IPP/HTTP (TCP) | Impresión |
| 6 | Samba | 192.168.101.100 | 139 / 445 | SMB/CIFS (TCP) | Archivos (Windows/Mac) |
| 7 | PostgreSQL | 192.168.101.100 | 5432 | PostgreSQL (TCP) | Base de datos |
| 8 | App interna (Podman) | 192.168.101.100 | 8080 | HTTP (TCP) | Contenedor web (dev/intranet) |

**Parámetros de red del proyecto:**

- **Servidor:** `srv-epa` — `192.168.101.100` (IP fija, modo bridged)
- **Red local:** `192.168.101.0/24`
- **Dominio NIS:** `epa.local`
- **Dominio web público:** `epa-armenia.duckdns.org` (DNS dinámico gratuito)
- **SO servidor:** Ubuntu Server 24.04 LTS (VM, 2 vCPU / 4 GB RAM / 40 GB disco)
- **Hipervisor:** Multipass · **Contenedores:** Podman · **PaaS:** Dokploy

## 4. Diagrama de arquitectura

Ver [`diagrama.mmd`](diagrama.mmd). Resumen:

- La **red local (192.168.101.0/24)** entra a **Dokploy/Traefik**, que publica el sitio
  web, el backend/API y el panel de administración con SSL.
- El **servidor Linux `srv-epa`** expone los servicios tradicionales: NTP, NFS, NIS,
  CUPS y Samba.
- Los **clientes Linux** montan NFS y se autentican por NIS; los **clientes
  Windows/Mac** acceden por Samba y a la impresora compartida por CUPS.

## 5. Análisis costo-beneficio

| Alternativa | Costo | Observación |
|---|---|---|
| Servidor local (esta propuesta) | Hardware existente + software libre (0 licencias) | Control total, sin costo mensual, requiere administración propia. |
| Nube pública (AWS/Azure) | ~USD 40–80/mes por VM equivalente + tráfico | Escalable, pero costo recurrente y dependencia de internet para servicios internos. |
| Un servicio por equipo (sin centralizar) | Bajo inicial, alto mantenimiento | Inviable para gestión de usuarios y respaldos; es el problema que se busca resolver. |

**Conclusión:** para una operación de una sede como EPA, centralizar en un servidor
local con software libre (Dokploy + servicios Linux) ofrece el mejor balance:
cero licenciamiento, control total de los datos de suscriptores y cumplimiento de
transparencia, con un único punto de administración y respaldo.
