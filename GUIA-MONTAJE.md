# Guía de Montaje — Infraestructura de TI de EPA E.S.P.

**Universidad del Quindío** — Facultad de Ingeniería de Sistemas y Computación
**Programa:** Ingeniería de Sistemas y Computación
**Curso:** Administración de Infraestructura de TI
**Docente:** Maycol Cárdenas Acevedo
**Estudiante:** Manuel Pineda Varela
**Empresa objeto de estudio:** Empresas Públicas de Armenia E.S.P. (EPA)
**Fecha de entrega:** 8 de noviembre de 2026

---

El presente documento describe el procedimiento secuencial de montaje de la infraestructura.
Los bloques de comandos deben ejecutarse en el orden indicado. Cada punto señalado con
**Captura:** requiere la toma de una evidencia gráfica, que se almacena en `capturas/` con el
nombre señalado.

**Convención de entornos de ejecución:**
- **[HOST]** — estación de trabajo del estudiante (sistema anfitrión), fuera de las máquinas virtuales.
- **[srv-epa]** — sesión dentro de la máquina virtual servidor.
- **[cli-epa]** — sesión dentro de la máquina virtual cliente.

Valores del proyecto: servidor `192.168.101.100`, red `192.168.101.0/24`, dominio NIS
`epa.local`, hostname `srv-epa`.

> **Consideración previa:** en la estación de trabajo debe ejecutarse `ip a` para confirmar
> que la red local corresponda al segmento `192.168.101.x`. En caso de pertenecer a otro
> segmento (por ejemplo `192.168.0.x`), se debe sustituir la dirección `192.168.101.100` por
> una IP libre de la red correspondiente en los pasos siguientes y en el archivo
> `codigo/01-netcfg.yaml`.

---

## FASE 1 — Crear las máquinas virtuales (Multipass)

### 1.1 [HOST] Verificar Multipass y la interfaz de red
```bash
multipass version
multipass networks
```
En este equipo la interfaz es **`enp7s0`** (red `192.168.101.0/24`).

### 1.2 [HOST] Crear el servidor y el cliente
```bash
multipass set local.bridged-network=enp7s0
multipass launch 24.04 --name srv-epa --cpus 2 --memory 4G --disk 40G --bridged
multipass launch 24.04 --name cli-epa --cpus 1 --memory 2G --bridged
multipass list
```
**Captura (`multipass-list.png`):** → salida de `multipass list` con las dos VMs en `Running`.

### 1.3 [HOST] Montar la carpeta del proyecto en el servidor
```bash
multipass mount "/home/ing69cooler/Documentos/Manuel/Semestre VII/Ingenieria/Admin_ti/Proyecto_final_admin_ti" srv-epa:/home/ubuntu/proyecto
```

### 1.4 [srv-epa] Entrar, poner IP fija y hostname
```bash
multipass shell srv-epa
```
Dentro de la VM:
```bash
ip a                                  # ve el nombre de la interfaz bridged (en esta VM: eth1)
cd /home/ubuntu/proyecto
# La interfaz bridged de esta VM es eth1 (ya configurado en codigo/01-netcfg.yaml).
sudo cp codigo/01-netcfg.yaml /etc/netplan/99-static.yaml
sudo chmod 600 /etc/netplan/99-static.yaml
sudo netplan apply
sudo hostnamectl set-hostname srv-epa
sudo apt update && sudo apt upgrade -y
ip a
hostname
```
**Captura (`00-red-hostname.png`):** → `ip a` mostrando `192.168.101.100` y `hostname` = `srv-epa`.

---

## FASE 2 — Servicios Linux (dentro de srv-epa)

> Todos estos comandos corren en **[srv-epa]**, desde `/home/ubuntu/proyecto`.

### 2.1 NTP — servidor de hora
> En Ubuntu 24.04 el paquete `ntp` instala **ntpsec**, cuya configuración está en
> `/etc/ntpsec/ntp.conf` (no en `/etc/ntp.conf`) y su servicio es `ntpsec`.
```bash
cd /home/ubuntu/proyecto
sudo apt install ntp -y
sudo cp codigo/ntp.conf /etc/ntpsec/ntp.conf
sudo systemctl restart ntpsec
ntpq -p
```
**Captura (`01-ntp-ntpq.png`):** → salida de `ntpq -p` (lista de peers; con el tiempo
aparecen `*`/`+` en los seleccionados).

### 2.2 NFS — compartir archivos
```bash
sudo apt install nfs-kernel-server -y
sudo mkdir -p /srv/nfs/epa
sudo chown nobody:nogroup /srv/nfs/epa
echo "Documento de prueba EPA" | sudo tee /srv/nfs/epa/bienvenida.txt
sudo cp codigo/exports /etc/exports
sudo exportfs -ra
sudo systemctl enable --now nfs-kernel-server
sudo exportfs -v
```
*(La captura de NFS se toma desde el cliente, en la Fase 3.)*

### 2.3 NIS — autenticación centralizada
> NIS en Ubuntu 24.04 tiene varias trampas. Ejecuta los comandos **de a uno** (no pegues
> el bloque entero). El dominio es `epa.local`.

**a) Instalar y fijar el dominio:**
```bash
echo "nis nis/domain string epa.local" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install nis -y
printf "epa.local\n" | sudo tee /etc/defaultdomain      # OJO: debe quedar con 'epa.local', no vacío
sudo nisdomainname epa.local
sudo sed -i 's/^NISSERVER=.*/NISSERVER=master/' /etc/default/nis
```

**b) Configurar yp.conf y las redes autorizadas:**
```bash
cd /home/ubuntu/proyecto
sudo cp codigo/yp.conf.server /etc/yp.conf
sudo tee /etc/ypserv.securenets >/dev/null <<EOF
255.0.0.0       127.0.0.0
255.255.255.0   192.168.101.0
255.255.255.0   10.207.235.0
EOF
```

**c) Construir las bases de datos NIS** (pulsa **Ctrl+D** y luego **y**):
```bash
sudo /usr/lib/yp/ypinit -m
```

**d) Crear un usuario centralizado de prueba y arrancar los servicios:**
```bash
sudo useradd -m -s /bin/bash epaadmin
echo "epaadmin:EpaClave123" | sudo chpasswd
cd /var/yp && sudo make && cd -
sudo systemctl enable --now ypserv ypbind
sudo nisdomainname epa.local && sudo systemctl restart ypbind
ypwhich        # debe responder 127.0.0.1
ypcat passwd   # debe listar los usuarios, incluido epaadmin
```
**Captura (`03-nis-ypcat.png`):** → salida de `ypcat passwd` con `epaadmin`.

> **Si `ypwhich` dice «Domain not bound»:** casi siempre `/etc/defaultdomain` quedó vacío.
> Corrígelo: `printf "epa.local\n" | sudo tee /etc/defaultdomain` → `sudo nisdomainname epa.local`
> → `sudo systemctl restart ypbind`.
> Si `apt install nis` falla: `sudo add-apt-repository universe` y reintenta.

### 2.4 CUPS — impresión
```bash
sudo apt install cups printer-driver-cups-pdf -y
sudo usermod -aG lpadmin ubuntu
sudo cp codigo/cupsd.conf /etc/cups/cupsd.conf
sudo systemctl enable --now cups
sudo systemctl restart cups
lpstat -p -d
echo "Factura de prueba EPA" | lp -d PDF
lpstat -o
```
**Captura (`04-cups-web.png`):** → desde tu PC abre `https://192.168.101.100:631` (acepta el aviso
de certificado) → pestaña **Printers**, con la impresora `PDF` listada.

### 2.5 Samba — compartir con Windows/Mac
```bash
sudo apt install samba smbclient -y
sudo groupadd sambashare 2>/dev/null
sudo mkdir -p /srv/samba/epa
sudo chgrp sambashare /srv/samba/epa
sudo chmod 2770 /srv/samba/epa
sudo cp codigo/smb.conf /etc/samba/smb.conf
sudo useradd -M -s /usr/sbin/nologin epauser 2>/dev/null
sudo smbpasswd -a epauser        # te pedirá una clave para el usuario Samba
sudo usermod -aG sambashare epauser
sudo systemctl enable --now smbd nmbd
testparm                          # valida la sintaxis (pulsa Enter)
smbclient -L //192.168.101.100 -U epauser
```
**Captura (`05-samba-windows.png`):** → desde tu PC (o cli-epa): entra al recurso.
- Windows: Explorador → `\\192.168.101.100\epa`
- Mac: Finder → Cmd+K → `smb://192.168.101.100/epa`
- Linux: `smbclient //192.168.101.100/epa -U epauser`

---

## FASE 3 — Pruebas desde el cliente (cli-epa)

> **Nota de red (importante):** en Multipass, dos VMs en modo *bridged* no se comunican
> entre sí por TCP (limitación del hipervisor). Por eso, entre `srv-epa` y `cli-epa` se usa
> la **red privada interna de Multipass** (`10.207.235.0/24`). El servidor en esa red es
> **`10.207.235.83`** (confírmalo con `multipass list`; si cambió, usa el valor que aparezca).
> La IP `192.168.101.100` sigue siendo la del portal/Dokploy (acceso desde tu PC).
> Para que `cli-epa` quede en la LAN se le fijó `192.168.101.101` (archivo
> `codigo/01-netcfg-cliente.yaml`).

### 3.1 [cli-epa] Entrar al cliente
```bash
multipass shell cli-epa
```

### 3.2 [cli-epa] Montar NFS (por la red privada)
```bash
sudo apt install nfs-common -y
sudo mkdir -p /mnt/epa
sudo mount -t nfs 10.207.235.83:/srv/nfs/epa /mnt/epa
df -h | grep epa
cat /mnt/epa/bienvenida.txt
```
**Captura (`02-nfs-montado.png`):** → `df -h | grep epa` y el contenido del archivo montado.

### 3.3 [cli-epa] Autenticarse por NIS (refuerza §2.3)
> Monta antes el proyecto en cli-epa: desde **[HOST]**
> `multipass mount "<ruta>/Proyecto_final_admin_ti" cli-epa:/home/ubuntu/proyecto`
> El servicio del cliente es **`ypbind`** (no `nis`).
```bash
echo "nis nis/domain string epa.local" | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive apt install nis -y
printf "epa.local\n" | sudo tee /etc/defaultdomain
sudo nisdomainname epa.local
printf "domain epa.local server 10.207.235.83\n" | sudo tee /etc/yp.conf
sudo sed -i 's/^passwd:.*/passwd:         files nis/' /etc/nsswitch.conf
sudo sed -i 's/^group:.*/group:          files nis/'  /etc/nsswitch.conf
sudo sed -i 's/^shadow:.*/shadow:         files nis/' /etc/nsswitch.conf
sudo systemctl restart ypbind
ypwhich                  # debe responder 10.207.235.83
ypcat passwd             # lista los usuarios (incluye epaadmin)
getent passwd epaadmin   # resuelve el usuario NIS (prueba de auth centralizada)
```
**Captura (`03-nis-ypcat.png`):** → `ypcat passwd` + `getent passwd epaadmin`.

---

## FASE 4 — Contenedores con Podman (en srv-epa)

> Vuelve a **[srv-epa]** (`multipass shell srv-epa`).

```bash
sudo apt install podman podman-compose -y
cd /home/ubuntu/proyecto/codigo
podman-compose up -d          # construye la imagen y levanta app + PostgreSQL
podman ps
podman volume ls
podman network ls
```
**Captura (`06-podman-ps.png`):** → `podman ps` con `epa-app` y `epa-db` en `Up`.

Probar la app:
```bash
curl http://192.168.101.100:8080/health
curl http://192.168.101.100:8080/api/estado-bd
```
**Captura (`07-podman-app.png`):** → desde tu PC abre `http://192.168.101.100:8080` en el navegador
(se ve el portal EPA) y, aparte, `http://192.168.101.100:8080/health`.

---

## FASE 5 — Publicar el portal con Dokploy + SSL (en srv-epa)

### 5.1 [srv-epa] Instalar Dokploy
```bash
curl -sSL https://dokploy.com/install.sh | sh
```

### 5.2 [HOST] Configurar en el navegador
1. Abre `http://192.168.101.100:3000` y crea tu cuenta de administrador.
2. **Create Project** → nombre `epa`.
3. **Create Application** → Source = tu repositorio Git; carpeta raíz = `codigo/sitio-web/`;
   Build = **Nixpacks** (autodetecta Node.js).
4. **Create Database → PostgreSQL** → conéctala a la app con la variable `DATABASE_URL`
   (ver `codigo/sitio-web/.env.example`).
5. **Domains** → `epa-armenia.duckdns.org` → activa **HTTPS / Let's Encrypt**.

**Captura (`09-dokploy-panel.png`):** → panel de Dokploy con la app y la base de datos en verde.
**Captura (`08-web-https.png`):** → el portal abierto con el **candado HTTPS** en la barra.

> El HTTPS público necesita el subdominio en [duckdns.org](https://www.duckdns.org)
> apuntando a tu IP pública y los puertos 80/443 abiertos en el router. Si no puedes
> abrir el router, muestra el sitio por HTTP y explica el SSL en la presentación.

---

## FASE 6 — Verificación final y entrega

### 6.1 [srv-epa] Chequeo integral
```bash
cd /home/ubuntu/proyecto
bash codigo/verificar.sh
```

### 6.2 (Opcional, puntos extra)
```bash
bash codigo/firewall.sh        # UFW con solo los puertos necesarios
sudo bash codigo/backup.sh     # respaldo manual de prueba
```

### 6.3 Entrega
- [ ] Las 10 capturas en `capturas/` (lista en `capturas/README.md`).
- [ ] Marcar los servicios en `README.md`.
- [ ] Subir todo a un **repositorio Git**.
- [ ] Preparar la **presentación de 15 min** (demo en vivo + decisiones de diseño;
      el costo-beneficio está en `analisis.md`).

---

## Checklist de capturas (10)

| # | Archivo | Dónde |
|---|---------|-------|
| 0 | `multipass-list.png` | Fase 1.2 — VMs corriendo |
| 1 | `00-red-hostname.png` | Fase 1.4 — IP fija + hostname |
| 2 | `01-ntp-ntpq.png` | Fase 2.1 — `ntpq -p` |
| 3 | `02-nfs-montado.png` | Fase 3.2 — NFS montado en cliente |
| 4 | `03-nis-ypcat.png` | Fase 2.3 — `ypcat passwd` |
| 5 | `04-cups-web.png` | Fase 2.4 — panel CUPS :631 |
| 6 | `05-samba-windows.png` | Fase 2.5 — recurso Samba |
| 7 | `06-podman-ps.png` | Fase 4 — `podman ps` |
| 8 | `07-podman-app.png` | Fase 4 — app en :8080 |
| 9 | `08-web-https.png` | Fase 5.2 — portal con HTTPS |
| 10 | `09-dokploy-panel.png` | Fase 5.2 — panel Dokploy |
