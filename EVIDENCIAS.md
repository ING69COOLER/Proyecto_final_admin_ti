# Evidencias de Funcionamiento — Infraestructura de TI de EPA E.S.P.

**Universidad del Quindío** — Facultad de Ingeniería de Sistemas y Computación
**Programa:** Ingeniería de Sistemas y Computación
**Curso:** Administración de Infraestructura de TI
**Docente:** Maycol Cárdenas Acevedo
**Estudiante:** Manuel Pineda Varela
**Empresa objeto de estudio:** Empresas Públicas de Armenia E.S.P. (EPA)
**Fecha de entrega:** 8 de noviembre de 2026

---

Este documento reúne las evidencias gráficas de cada servicio implementado y verificado,
organizadas por fase. Cada imagen se conserva en su carpeta correspondiente (`capturas/fase1`
a `capturas/fase6`).

---

## Fase 1 — Virtualización con Multipass

### 1.1 Versión de Multipass e interfaces de red
![Versión e interfaces de Multipass](capturas/fase1/1-multipass-version.png)
Multipass 1.17.0 instalado; interfaz física `enp7s0` disponible para el modo bridged.

### 1.2 Máquinas virtuales creadas
![Máquinas virtuales en ejecución](capturas/fase1/2-multipass-list.png)
VMs `srv-epa` (servidor) y `cli-epa` (cliente) en estado Running.

### 1.3 IP fija y hostname del servidor
![IP fija y hostname](capturas/fase1/3-ip-hostname.png)
Hostname `srv-epa`; interfaz `eth1` con IP fija 192.168.101.100/24 (LAN) y `eth0` en la red
privada de Multipass.

---

## Fase 2 — Servicios Linux

### 2.1 NTP — Sincronización de tiempo
![Salida de ntpq -p](capturas/fase2/1-ntp-ntpq.png)
Servidor NTP (ntpsec) sincronizado; el peer `*gps.jd.ntp.br` aparece seleccionado y se usan
los pools de Colombia y Sudamérica.

### 2.2 NIS — Autenticación centralizada (servidor)
![NIS en el servidor](capturas/fase2/2-nis-servidor.png)
`ypcat passwd` y `getent passwd epaadmin` en el servidor: el usuario centralizado `epaadmin`
está publicado en el dominio `epa.local`.

### 2.3 CUPS — Impresión
![Panel web de CUPS en el puerto 631](capturas/fase2/3-cups-web.png)
Panel web de CUPS 2.4.7 accesible en `https://192.168.101.100:631`; cola de impresión `PDF`
configurada.

### 2.4 Samba — Compartición para Windows/Mac
![Recurso Samba epa](capturas/fase2/4-samba.png)
Recurso `epa` (`/srv/samba/epa`) visible y accesible con el usuario `epauser`; aparece en el
listado `smbclient -L`.

---

## Fase 3 — Pruebas desde el cliente

### 3.1 NFS — Montaje en el cliente
![NFS montado en cli-epa](capturas/fase3/1-nfs-cliente.png)
`cli-epa` monta `10.207.235.83:/srv/nfs/epa` en `/mnt/epa` y lee el archivo compartido.

### 3.2 NIS — Autenticación desde el cliente
![NIS en el cliente](capturas/fase3/2-nis-cliente.png)
`cli-epa` enlaza al servidor (`ypwhich` devuelve `10.207.235.83`) y resuelve por NIS al
usuario `epaadmin`, que no existe localmente: prueba de autenticación centralizada.

---

## Fase 4 — Contenedores con Podman

### 4.1 Contenedores y volumen
![podman ps y volúmenes](capturas/fase4/1-podman-ps.png)
`epa-app` (puerto 8080 a 3000) y `epa-db` (PostgreSQL) en ejecución; volumen `codigo_epa-datos`
para la persistencia.

### 4.2 Red de contenedores
![podman network](capturas/fase4/2-podman-red.png)
Red `codigo_epa-net` que conecta la aplicación con la base de datos.

### 4.3 Aplicación y base de datos conectadas
![App EPA en el puerto 8080 con la base de datos conectada](capturas/fase4/3-podman-app-bd.png)
El portal responde en el puerto 8080, `/health` devuelve el estado y `/api/estado-bd` confirma
`{"bd":"conectada"}`: app y PostgreSQL funcionando en Podman.

---

## Fase 5 — Despliegue con Dokploy (PaaS)

### 5.1 Instalación de Dokploy
![Instalación de Dokploy](capturas/fase5/1-dokploy-install.png)
Instalación de Dokploy v0.31.0 sobre la VM servidor.

### 5.2 Configuración del servidor Dokploy
![Registro del administrador en Dokploy](capturas/fase5/2-dokploy-registro.png)
Creación de la cuenta administradora del panel de Dokploy.

### 5.3 Creación de la base de datos PostgreSQL
![Creación de la base de datos en Dokploy](capturas/fase5/3-dokploy-db.png)
Base de datos PostgreSQL `admin_ti` creada desde Dokploy para la aplicación.

### 5.4 Proyecto desplegado
![Panel de Dokploy](capturas/fase5/4-dokploy-panel.png)
Aplicación `front` (portal EPA) y base de datos `databse` (PostgreSQL) desplegadas y activas.

### 5.5 Portal institucional publicado
![Portal EPA](capturas/fase5/5-portal-web.png)
Sitio institucional de EPA servido en `epa-armenia.duckdns.org`.

### 5.6 Endpoint de estado (JSON)
![health](capturas/fase5/6-web-health.png)
`/health` devuelve el estado del servicio en formato JSON.

### 5.7 Conexión a la base de datos
![api/estado-bd](capturas/fase5/7-web-estado-bd.png)
`/api/estado-bd` confirma la conexión a PostgreSQL (`{"bd":"conectada"}`).

---

## Fase 6 — Verificación integral y extras

### 6.1 Chequeo de servicios (parte 1)
![verificar.sh, servicios](capturas/fase6/1-verificar-1.png)
`verificar.sh`: NTP, NFS, CUPS y Samba activos; peers NTP, exports NFS (ambas subredes),
usuarios NIS (`ubuntu epaadmin nobody`) e impresora `PDF`.

> Nota: la versión de la captura marcaba «NIS inactivo» porque el script consultaba el
> servicio `nis`; en Ubuntu 24.04 son `ypserv`/`ypbind`. El script ya fue corregido y los
> usuarios NIS listados en la misma captura confirman que el servicio opera correctamente.

### 6.2 Chequeo de servicios (parte 2)
![verificar.sh, contenedores](capturas/fase6/2-verificar-2.png)
Contenedores de Podman y de Dokploy (Traefik, aplicación y bases de datos) en ejecución.

### 6.3 Firewall (UFW) y respaldo automático
![UFW y backup](capturas/fase6/3-firewall-backup.png)
Reglas de UFW con solo los puertos de los servicios y respaldo generado por `backup.sh`
(puntos extra).

---

## Resumen de cumplimiento

| Servicio | Evidencia | Estado |
|---|---|---|
| Multipass (VMs) | 1.1 a 1.3 | Implementado |
| NTP | 2.1 | Implementado |
| NFS | 3.1 | Implementado |
| NIS | 2.2 y 3.2 | Implementado |
| CUPS | 2.3 | Implementado |
| Samba | 2.4 | Implementado |
| Podman (app y BD) | 4.1 a 4.3 | Implementado |
| Dokploy, Web y BD | 5.1 a 5.5 | Implementado |
| Firewall y Backup (extra) | 6.3 | Implementado |
