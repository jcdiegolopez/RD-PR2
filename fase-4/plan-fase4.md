# Plan final de la Fase 4 · Terranova

**Entrega: 13 de noviembre de 2026.** Diagrama: [`diagrama-fase4.drawio`](diagrama-fase4.drawio).

Este plan parte de lo que ya existe en Azure (Fase 3) y agrega lo que piden el enunciado de la Fase 4, el caso 4 del documento del proyecto y el profesor.

> La salida de cada paso se guarda como evidencia en `fase-4/evidencia/`.
> Los valores entre `<...>` (contraseñas, dominio, IP del admin) se completan al aplicar. Las contraseñas van en `fase-4/credenciales-fase4.txt`, no en este archivo.

---

## 0. Estado de partida (10 de noviembre)

| Qué | Estado |
|---|---|
| Suscripción actual (de Joel) | Azure for Students. **No se puede pasar a pago desde el portal**: por el tipo de contrato, solo Microsoft puede hacerlo con una solicitud a soporte (caso abierto). No da tiempo para el 13 |
| Decisión | **Suscripción nueva de pago por uso y reconstruir todo desde cero.** La suscripción vieja queda apagada como respaldo, con la Fase 3 funcionando y su evidencia |
| Qué se reutiliza | Los scripts y configuraciones de la Fase 3 (`fase-3/config/`), los firewalls finales (`fase-4/config/`), el script que crea Azure (`fase-4/infra/01-azure.sh`) y el de LDAP (`fase-4/infra/setup-ldap.sh`) |
| Qué cambia | IP pública nueva (perfiles `.ovpn` nuevos), CA y certificados de VPN nuevos, llave SSH y contraseñas nuevas |
| **Avance 10 nov** | **Pasos 0 y 1 hechos.** Suscripción `terranova-fase4` (`016952af-f2ae-4f99-9a34-17441b3f5130`), pago por uso, cuota Basv2 10 aprobada, presupuesto de $20/mes con alertas. Red y 4 VMs creadas con `01-azure.sh` (salida en `evidencia/01-azure-creacion.txt`). **IP pública de fw-vpn: 52.159.123.60**. Acceso SSH: `fase-4/ssh-config` con la llave `~/.ssh/terranova` |
| **Avance 10 nov (noche)** | **Pasos 2 y 3 hechos, y BIND9 del paso 4.2.** Fase 3 reconstruida con contraseñas, CA y perfiles nuevos (`credenciales-fase4.txt`, `vpn-perfiles/`). Regresión completa igual a la Fase 3: ACL por grupo desde las 4 VPN (`evidencia/06`), SSH con LDAP por grupo (`evidencia/07`), nadie hacia TI (`evidencia/08`). DNS interno funcionando desde la VPN (no para Visitantes) |
| **Avance 10 nov (noche, Fase 4)** | **Hechos los pasos 4, 5b (sin HTTPS), 7, 8 y 9.** SSH sin root en fw-vpn y srv-web. srv-web sirve la página por el DNAT: `http://52.159.123.60` abre desde Internet sin VPN; la DMZ no llega a nada interno (`evidencia/10`). SNMPv3 en las 4 VMs, v2c rechazado (`evidencia/11`). Prometheus + snmp_exporter 0.31.0 + Grafana 13.3 en srv-planos; Grafana abre desde TI y no desde Arquitectos (`evidencia/12`). Carpeta de planos con permisos por grupo y NFS (`evidencia/13`). Blender oficial (snap 5.3.0) instalado; el render de prueba quedó a medias al apagar (`evidencia/14`). **VMs apagadas (desasignadas) al cierre del 10 nov.** |

### Pendiente (al 10 nov, noche)

| # | Qué | Quién | Detalle |
|---|---|---|---|
| 1 | **Dominio** | Jose Pablo | Conseguirlo (Student Pack → Namecheap `.me`, o comprarlo) y crear los registros A `@` y `www` → **52.159.123.60**. Bloquea el HTTPS |
| 2 | **HTTPS** (paso 6) | Jose Pablo | Con el dominio resolviendo: `server_name` en `config/nginx-terranova.conf` y Certbot con `--redirect` |
| 3 | **Render del condominio** | Fabian | Encender srv-planos y srv-render y correr `infra/setup-render-blender.sh` (ya corregido; ~4 min) |
| 4 | **Subir la página pública** | Jose Pablo | `web/index.html` está hecho pero srv-web todavía tiene la página provisional. Copiar `web/` con el render en `web/img/condominio.png`. Revisar si los datos de los proyectos (inventados) se dejan así |
| 5 | **Acceso del equipo** (paso 0.4) | Diego López | Rol Contributor sobre `rg-redes-proyecto` para cada integrante |
| 6 | **Capturas** | Todos | Fase 3 y Fase 4 (pruebas de la sección 5), con las VMs encendidas |
| 7 | **Reporte final** | Fabian | Fases 1–3 + sección de Fase 4 (decisiones, implementación, pruebas, costos, problemas) |
| 8 | **Diagrama** | Fabian | `diagrama-fase4.drawio` ya refleja lo implementado; exportar a PNG |
| 9 | **Presentación y guion de la demo** | Todos | Presentación ejecutiva y guía de demo como `demo-fase3.md` |
| 10 | **Push** | Diego López | `git push` (el modo automático lo bloquea) |

Costo con las VMs apagadas: discos e IP pública, unos $13 al mes. Encender las 4 VMs suma unos $0.10 por hora.

---

## 1. Qué hay que cumplir

### Enunciado de la Fase 4 y caso 4

| Requisito | Fuente | Cómo lo cumplimos | Dónde |
|---|---|---|---|
| Servidor web **público** con la información de los proyectos | Fase 4 y caso 4 | Página estática con los 2 edificios y el condominio, con renders | **srv-web** (nueva, DMZ) |
| **Dominio público** de la inmobiliaria | Fase 4, caso 4 y profesor | `terranova-inmobiliaria.me` (u otro), registro A hacia la IP pública de fw-vpn | Registrador |
| **HTTPS** y redirección de http a https | Fase 4 y caso 4 | Certbot (Let's Encrypt) con `--redirect` | srv-web |
| **DMZ** con los servicios públicos | Fase 4, caso 4 y profesor | srv-web en la subred DMZ; Internet entra solo por el firewall (DNAT) y la DMZ no puede iniciar conexiones hacia adentro | fw-vpn + Azure |
| Cambios al firewall | Fase 4 | DNAT 80/443, reglas de la DMZ, rutas de la DMZ por fw-vpn | fw-vpn |
| **SNMP** | Fase 4 | SNMPv3 (autenticación y cifrado) en las 4 VMs | las 4 VMs |
| *Extra 10%:* gráficas de SNMP solo para TI | Fase 4 | Prometheus + snmp_exporter + Grafana, accesible solo desde la VPN de TI | srv-planos |
| VPN | Fase 4, caso 4 y profesor | Ya existe (4 instancias con LDAP) | fw-vpn |
| **Zona interna de DNS** | **Caso 4** (faltaba) | BIND9 con la zona `terranova.local` | fw-vpn |
| Servidor que **almacene planos y renders** | Caso 4 | Carpeta `/srv/planos` con permisos por grupo de LDAP; acceso por SFTP | srv-planos |
| **Instancia de renderización** | Caso 4 | Blender en modo consola; los renders se guardan en srv-planos | srv-render |
| Arquitectos → render y planos; Ingenieros → solo planos; TI → todo; nadie → TI | Caso 4 | Ya existe (Fase 3). Se mantiene | fw-vpn + NSG |
| Hardening | Caso 4 | Firewall en srv-web; `PermitRootLogin no` en fw-vpn; se cierra el 445 de la Fase 2 que nadie usa | todas |
| Diagrama, **reporte final con todas las fases**, presentación y demo | Fase 4 | Sobre el informe de la Fase 2 y `fase-3/reporte-fase3.md` | — |

### Lo que pidió el profesor ("parte pública")

| Pedido | Cómo se cumple |
|---|---|
| VPN | Ya existe (Fase 3). En la demo: un trabajador desde casa entra a planos por la VPN |
| Crear la subred DMZ | Existe desde la Fase 2 (10.0.0.0/28). Se le agregan srv-web, la ruta `rt-dmz` y el NSG nuevo |
| Que se pueda acceder a los proyectos desde Internet | La página pública muestra los 2 edificios y el condominio con renders hechos en srv-render. Los **archivos** (planos) siguen solo por VPN: srv-planos no se expone a Internet |
| Dominio de inmobiliaria | Un dominio con el nombre de la inmobiliaria |
| Página pública en la DMZ | srv-web en 10.0.0.4, detrás de fw-vpn |

### Las dos páginas web

| | Página pública | Intranet |
|---|---|---|
| Requisito de | Fase 4, caso 4 y profesor | Enunciado de la Fase 3 |
| Dónde | srv-web (DMZ, 10.0.0.4) | srv-render (Servidores, 10.0.0.37) |
| Para quién | Clientes y compradores | Empleados |
| Cómo se entra | `https://<dominio>`, **sin VPN** | `http://intranet.terranova.local`, **solo con VPN** (Arquitectos, Ingenieros, TI) |
| Estado | Por hacer (paso 5) | Hecha en la Fase 3 |

**Fuera de alcance** (no lo piden ni la Fase 4 ni el caso 4; va al reporte como trabajo futuro): Samba, Blob Storage, LDAPS, un certificado de VPN por usuario.

---

## 2. Cómo queda la red

| VM | Subred | IP | Tamaño | Servicios |
|---|---|---|---|---|
| fw-vpn | Firewall 10.0.0.16/28 | 10.0.0.20 (IP pública estática nueva) | B2ats_v2 (2 vCPU, 1 GiB) | nftables (ACL, NAT, **DNAT**), OpenVPN ×4, chrony, **BIND9**, **snmpd** |
| **srv-web** (nueva) | **DMZ 10.0.0.0/28** | **10.0.0.4**, sin IP pública | B2ats_v2 (2 vCPU, 1 GiB) | **nginx + Certbot**, snmpd |
| srv-planos | Servidores 10.0.0.32/28 | 10.0.0.36 | **B2als_v2 (2 vCPU, 4 GiB)** | OpenLDAP, **carpeta de planos**, **NFS para renders**, **Prometheus + Grafana**, snmpd |
| srv-render | Servidores 10.0.0.32/28 | 10.0.0.37 | **B2als_v2 (2 vCPU, 4 GiB)** | intranet (nginx), **Blender**, snmpd |

**Cuota necesaria:** 4 VMs × 2 vCPU = **8**.
**Por qué srv-planos y srv-render son B2als_v2:** con 1 GiB no caben LDAP + Prometheus + Grafana, ni un render de Blender. B2als_v2 tiene las mismas 2 vCPU (no gasta más cuota) y 4 GiB.

### Decisión: la web entra por el firewall (DNAT), no con IP propia

En la Fase 1 se diseñó srv-web con su propia IP pública. Se cambia a DNAT por tres razones (van en el reporte):
1. La Fase 4 pide modificar el firewall para los nuevos requerimientos: con DNAT, todo el tráfico público pasa por fw-vpn.
2. Una sola puerta de entrada y ninguna VM interna con IP pública; la DMZ queda aislada por la regla `dmz-hacia-interno`.
3. Una IP pública menos (~$3.65/mes).

Costo: más configuración, y si fw-vpn se apaga, la web se cae. Plan B en la sección 7.

El dominio funciona igual: su registro A apunta a la IP de fw-vpn. La redirección de http a https la hace nginx en srv-web; el firewall solo reenvía 80 y 443. Certbot valida el dominio por el puerto 80 a través del DNAT.

### Recorrido de una visita a la página web

```
Celular ──► https://<dominio>  (DNS público: A → <IP-PUBLICA-FW>)
        ──► fw-vpn: DNAT 443 → 10.0.0.4
        ──► srv-web (DMZ) responde ──► ruta de la DMZ: 0.0.0.0/0 → fw-vpn ──► celular
```

### Nombres internos (zona `terranova.local`)

| Nombre | IP |
|---|---|
| fw.terranova.local · ntp · dns · vpn | 10.0.0.20 |
| web.terranova.local | 10.0.0.4 |
| planos.terranova.local · ldap · grafana | 10.0.0.36 |
| render.terranova.local · intranet | 10.0.0.37 |

### Rutas

| Tabla | Destino | Siguiente salto | Para qué | Estado |
|---|---|---|---|---|
| rt-servidores | 10.10.0.0/16 | 10.0.0.20 | Respuestas a la VPN | Existe |
| rt-servidores | 0.0.0.0/0 | 10.0.0.20 | Salida a Internet con NAT | Existe |
| rt-servidores | 10.0.0.0/28 | 10.0.0.20 | Tráfico hacia la DMZ pasa por el firewall | **Nueva** |
| rt-dmz | 0.0.0.0/0 | 10.0.0.20 | Respuestas del DNAT y salida a Internet de srv-web | **Nueva** |
| rt-dmz | 10.10.0.0/16 | 10.0.0.20 | Respuestas a la VPN | **Nueva** |
| rt-dmz | 10.0.0.32/28 | 10.0.0.20 | Tráfico hacia Servidores pasa por el firewall | **Nueva** |
| Subred Firewall | sin tabla | — | Evita que fw-vpn se mande tráfico a sí mismo | Igual |

---

## 3. Orden, reparto y calendario

```
0. Suscripción nueva y cuota (hoy)           Dominio y página pública: HOY
1. infra/01-azure.sh: red, NSG, rutas, 4 VMs  (no necesitan Azure)
2. Reconstruir la Fase 3: fw-vpn → srv-planos (LDAP) → srv-render → OpenVPN
3. Comprobar la Fase 3 en la red nueva (regresión)
4. fw-vpn: BIND9, DNS en la VPN, SSH de root   5. srv-web ──► 6. Certbot (dominio + DNAT)
7. SNMPv3 ──► 8. Prometheus + Grafana          9. Carpeta de planos, NFS, Blender
10. Pruebas y capturas ──► 11. Reporte final, diagrama, presentación, ensayo
```

### Reparto

| Quién | Pasos |
|---|---|
| Joel (o quien ponga la tarjeta) | 0, 1, acceso del equipo y la captura de costos |
| Diego López | 2.1 y 2.4 (fw-vpn y OpenVPN), 3 y 4 |
| Diego Rosales | 2.2 (LDAP y SSSD) y 9 (carpeta y NFS) |
| Jose Pablo | 2.3 (intranet), dominio, 5 y 6 |
| Erick | 7, 8 y los firewalls de las 4 VMs |
| Fabian | Página pública (5a), Blender (9), 11 y juntar las capturas |

Todos: capturas de su parte para el reporte.

### Calendario

| Día | Objetivo |
|---|---|
| **10 nov (hoy)** | Paso 0 (suscripción y cuota), dominio registrado, contenido y HTML de la página pública. Si da tiempo, paso 1 |
| **11 nov** | Mañana: pasos 1–3 (red nueva y Fase 3 funcionando). Tarde: pasos 4–9 |
| **12 nov** | Paso 10 (pruebas y capturas) y paso 11 (reporte, diagrama, presentación); ensayo de la demo |
| **13 nov** | Entrega y demo. Encender las VMs 30 minutos antes |

---

## 4. Pasos

### Paso 0 · Suscripción nueva (Joel o quien ponga la tarjeta)

1. En https://portal.azure.com → **Subscriptions** → **Add** → **Pay-As-You-Go**, con la tarjeta de quien vaya a pagar. Si el portal la crea como "cuenta gratuita", convertirla a pago enseguida (en ese tipo sí hay botón **Upgrade**), porque la gratuita tiene límites bajos.
2. Revisar la cuota de vCPU en la región (hacen falta **8**):
   ```bash
   az account set --subscription <ID-NUEVO>
   az vm list-usage -l northcentralus -o table   # "Total Regional vCPUs" ≥ 8
   ```
   Si es menor, pedir 8 en Portal → **Quotas** → Compute. En suscripciones de pago estas solicitudes suelen aprobarse rápido, pero no está garantizado: hacerlo hoy.
3. Presupuesto con alerta (Cost Management → Budgets) de $20 al mes. *Hecho: `presupuesto-terranova`, alertas al dueño al 50%, 80% y 100% real y al 100% del pronóstico.*
4. Después del paso 1, dar acceso al equipo (rol Contributor sobre el grupo de recursos):
   ```bash
   az role assignment create --assignee <correo> --role Contributor \
     --scope /subscriptions/<ID-NUEVO>/resourceGroups/rg-redes-proyecto
   ```
5. **No borrar la suscripción vieja.** Dejar sus VMs apagadas (Stop, desasignar) hasta después de la entrega.

### Paso 1 · Crear la red en Azure con el script (Joel)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/terranova -C terranova     # llave nueva para azureuser
ADMIN_IP=<tu-ip-publica> SSH_PUB=~/.ssh/terranova.pub bash fase-4/infra/01-azure.sh
```

`fase-4/infra/01-azure.sh` crea, en este orden:
- Grupo de recursos `rg-redes-proyecto`, VNet `vnet-proyecto` 10.0.0.0/16 y las subredes DMZ, Firewall y Servidores (mismos rangos de siempre).
- Los 3 NSG con las reglas **finales**: las de la Fase 3 más la web pública y el DNAT en `nsg-firewall`, la DMZ que solo acepta la web, SSH de TI y SNMP, y en `nsg-servidores` NFS y SNMP, sin el 445 y con la DMZ fuera de todas las reglas (resumen en la tabla de NSG del diagrama).
- `rt-servidores` y `rt-dmz` con todas las rutas hacia 10.0.0.20; la subred Firewall sin tabla.
- La IP pública estática de fw-vpn y su tarjeta de red con **IP forwarding**.
- Las 4 VMs con IP privada fija: fw-vpn (Ubuntu 24.04, B2ats_v2), srv-planos y srv-render (Ubuntu 22.04, B2als_v2) y srv-web (Ubuntu 22.04, B2ats_v2). Solo fw-vpn tiene IP pública.

Antes de crear nada revisa que la cuota alcance. Al final imprime la **IP pública nueva**: anotarla, porque va en el dominio, en los perfiles de VPN y en `fase-4/config/fw-nftables.conf`. Guardar la llave privada en `fase-4/llaves/`, como en la Fase 3.

### Paso 2 · Reconstruir la Fase 3 en la red nueva

Los scripts se copian con `scp` a `/tmp` de cada VM y se corren con `bash` (lección de la Fase 3: no mandar comandos largos desde PowerShell). A los servidores se entra saltando por fw-vpn: `ssh -J azureuser@<IP-PUBLICA-FW> azureuser@10.0.0.36`.

**2.1 fw-vpn (Diego López)**
1. Reenvío de paquetes: `echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-terranova.conf && sudo sysctl --system`.
2. Firewall: `fase-4/config/fw-nftables.conf` con `<IP-ADMIN>` y `<IP-PUBLICA-FW>` reemplazados → `/etc/nftables.conf`, y `sudo systemctl enable --now nftables` (con el truco del borrado a los 5 minutos).
3. NTP: `sudo cp -n /etc/chrony/chrony.conf /etc/chrony/chrony.conf.orig` y luego `fase-3/config/ntp-servidor.sh`.
4. Desde srv-planos, `curl -s ifconfig.me` debe dar la IP de fw-vpn: con eso los servidores ya tienen Internet para instalar paquetes.

**2.2 srv-planos (Diego Rosales)**
1. LDAP igual al de la Fase 3 (sacado del servidor real con `slapcat`; referencia en `fase-4/infra/ldap-referencia.ldif`), con contraseñas **nuevas**: crear `claves.txt` con una línea `uid clave` por usuario (ana.arq, ivan.ing, tomas.ti, visita1) y correr `sudo LDAP_ADMIN_PW='<clave>' bash setup-ldap.sh claves.txt`. Guardar las claves en `fase-4/credenciales-fase4.txt`.
2. NTP: `fase-3/config/ntp-cliente.sh`.
3. SSH con LDAP: `sudo bash setup-sssd.sh arquitectos,ingenieros,ti` (`fase-3/config/setup-sssd.sh`).
4. Firewall: `fase-4/config/planos-nftables.conf`.

**2.3 srv-render (Jose Pablo)**
1. NTP: `ntp-cliente.sh`. SSH con LDAP: `sudo bash setup-sssd.sh arquitectos,ti`.
2. Intranet: copiar a `/tmp` `intranet.html`, `nginx-intranet.conf` y `archivo.woff2` y correr `fase-3/config/setup-nginx.sh` (después, `sudo cp /tmp/archivo.woff2 /var/www/intranet/`).
3. Firewall: `fase-4/config/render-nftables.conf`.

**2.4 OpenVPN en fw-vpn (Diego López)**
1. Antes de correrlo, cambiar el DNS que empuja `fase-3/config/setup-openvpn.sh`: para `arq`, `ing` y `ti`, `push "dhcp-option DNS 10.0.0.20"` y `push "dhcp-option DOMAIN terranova.local"`; para `vis`, se queda `1.1.1.1`. (El DNS interno se enciende en el paso 4; mientras tanto, la VPN puede usar 1.1.1.1.)
2. Copiar `ldap-auth.sh` a `/tmp` y correr `setup-openvpn.sh`: crea una **CA nueva**, los certificados y las 4 instancias.
3. Perfiles nuevos: `fase-3/config/perfil.sh <puerto> cliente1 <grupo>` para cada grupo, reemplazando `<IP-PUBLICA-FW-VPN>` por la IP nueva. Guardarlos en `fase-4/vpn-perfiles/`. Los de `fase-3/vpn-perfiles/` dejan de servir.

### Paso 3 · Comprobar la Fase 3 en la red nueva (Diego López)

Repetir las pruebas de `fase-3/demo-fase3.md` con los perfiles nuevos: IP por grupo, SSH por grupo, intranet, nadie hacia TI, Visitantes solo Internet, NAT y NTP. Guardar la salida en `fase-4/evidencia/`. Hasta que esto pase, no seguir con lo nuevo.

### Paso 4 · fw-vpn (Diego López)

#### 4.1 nftables

El archivo completo es `fase-4/config/fw-nftables.conf` y se aplica en el paso 2.1. Lo nuevo respecto de la Fase 3:

```
table inet filtro {
  chain input {
    ...igual que en la Fase 3, más:
    # DNS interno para servidores y departamentos (no Visitantes)
    meta l4proto { tcp, udp } th dport 53 ip saddr { 10.0.0.0/16, 10.10.1.0/27, 10.10.1.32/28, 10.10.1.48/29 } accept
    # SNMP solo desde el colector
    udp dport 161 ip saddr 10.0.0.36 accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    ct state invalid drop

    ip daddr 10.10.1.48/29 ct state new counter drop comment "nadie-hacia-TI"
    ip saddr 10.10.1.48/29 accept

    # NUEVO · Web pública: cualquiera (Internet, departamentos, Visitantes)
    ip daddr 10.0.0.4 tcp dport { 80, 443 } accept
    # NUEVO · Colector SNMP hacia la DMZ
    ip saddr 10.0.0.36 ip daddr 10.0.0.4 udp dport 161 accept
    # NUEVO · La DMZ no inicia nada hacia adentro; sí sale a Internet
    ip saddr 10.0.0.0/28 ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } counter drop comment "dmz-hacia-interno"
    ip saddr 10.0.0.0/28 oifname "eth0" accept

    ip saddr 10.10.1.64/28 ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } counter drop comment "visitantes-interno"
    ip saddr 10.10.1.64/28 oifname "eth0" accept

    ...reglas de Arquitectos, Ingenieros, ping y salida a Internet igual que en la Fase 3...

    counter comment "resto-bloqueado"
  }
}

table ip nat {
  chain prerouting {
    type nat hook prerouting priority dstnat; policy accept;
    # Visitas desde Internet (Azure entrega el paquete con destino 10.0.0.20)
    iifname "eth0" ip daddr 10.0.0.20 tcp dport { 80, 443 } dnat to 10.0.0.4
    # Usuarios de la VPN que abren el dominio (resuelve a la IP pública)
    ip daddr <IP-PUBLICA-FW> tcp dport { 80, 443 } dnat to 10.0.0.4
  }
  chain postrouting {
    type nat hook postrouting priority srcnat; policy accept;
    oifname "eth0" ip saddr { 10.10.1.0/24, 10.0.0.32/28, 10.0.0.0/28 } ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } masquerade
  }
}
```

**Importante:** la regla de la web va **antes** de `visitantes-interno` y de `dmz-hacia-interno`, porque fw-vpn tiene una sola tarjeta (`eth0`) y todo sale por ella. Las reglas de NSG y rutas que acompañan esto ya las crea `fase-4/infra/01-azure.sh`.

#### 4.2 BIND9 (zona interna)

```bash
sudo apt install -y bind9 bind9-dnsutils
```

`/etc/bind/named.conf.options`:

```
acl internos { 127.0.0.1; 10.0.0.0/16; 10.10.1.0/27; 10.10.1.32/28; 10.10.1.48/29; };
options {
  directory "/var/cache/bind";
  listen-on { any; };
  listen-on-v6 { none; };
  allow-query { internos; };
  allow-recursion { internos; };
  forwarders { 168.63.129.16; };   # DNS de Azure para todo lo demás
  forward only;
  dnssec-validation auto;
};
```

`/etc/bind/named.conf.local`:

```
zone "terranova.local" { type master; file "/etc/bind/db.terranova.local"; };
```

`/etc/bind/db.terranova.local`:

```
$TTL 300
@        IN SOA fw.terranova.local. ti.terranova.local. ( 2026111101 3600 600 86400 300 )
         IN NS  fw.terranova.local.
fw       IN A   10.0.0.20
web      IN A   10.0.0.4
planos   IN A   10.0.0.36
render   IN A   10.0.0.37
ntp      IN CNAME fw
dns      IN CNAME fw
vpn      IN CNAME fw
ldap     IN CNAME planos
grafana  IN CNAME planos
intranet IN CNAME render
```

Revisar y encender: `sudo named-checkconf && sudo named-checkzone terranova.local /etc/bind/db.terranova.local && sudo systemctl restart named`. Revisar que no choque con systemd-resolved: `sudo ss -lunp | grep ':53 '`.

**Quién usa este DNS:**
- VPN de Arquitectos, Ingenieros y TI: en `arq.conf`, `ing.conf` y `ti.conf` (no en `vis.conf`), cambiar `push "dhcp-option DNS 1.1.1.1"` por:
  ```
  push "dhcp-option DNS 10.0.0.20"
  push "dhcp-option DOMAIN terranova.local"
  ```
  y reiniciar esas tres instancias. Visitantes sigue con 1.1.1.1 y no ve los nombres internos.
- Servidores (srv-planos, srv-render, srv-web): DNS dividido, para que si fw-vpn se cae solo fallen los nombres internos. `/etc/systemd/resolved.conf.d/terranova.conf`:
  ```
  [Resolve]
  DNS=10.0.0.20
  Domains=~terranova.local
  ```
  `sudo systemctl restart systemd-resolved`.

#### 4.3 Hardening pendiente

En `/etc/ssh/sshd_config.d/terranova.conf` de fw-vpn: `PermitRootLogin no`. Probar con `sudo sshd -t` antes de `sudo systemctl reload ssh`.

### Paso 5 · Página pública y srv-web (Jose Pablo)

#### 5a. La página (se puede hacer hoy, sin Azure)

En el repo, `fase-4/web/`:
- `index.html` con: nombre de la inmobiliaria, los 2 edificios y el condominio (nombre, ubicación, número de unidades, estado de la obra, fecha estimada de entrega), una galería de renders por proyecto y datos de contacto. Formulario de contacto opcional (solo visual).
- `img/` con los renders. Mientras no estén los de Blender, usar imágenes de relleno.
- Mismo estilo visual que la intranet (`fase-3/intranet-DESIGN.md`) para que se vean de la misma empresa.

#### 5b. srv-web

```bash
sudo apt update && sudo apt install -y nginx chrony
sudo mkdir -p /var/www/terranova && sudo cp -r web/* /var/www/terranova/
```

- **nginx** (`/etc/nginx/sites-available/terranova`): `server_name <dominio> www.<dominio>;`, `root /var/www/terranova;`, `listen 80;` (Certbot agrega el 443). Ocultar la versión: `server_tokens off;` en `nginx.conf`. Desactivar el sitio `default`.
- **NTP:** `server 10.0.0.20 iburst prefer` en `/etc/chrony/chrony.conf` (como en los otros servidores).
- **Firewall** (Erick): `fase-4/config/web-nftables.conf` → `/etc/nftables.conf`.
- **SSH:** sin root, sin contraseña (`PermitRootLogin no`, `PasswordAuthentication no`). **No** se instala SSSD/LDAP: es un servidor público y no debe poder consultar el directorio de usuarios.

**Cómo llegan los renders a la página sin romper la DMZ:** la DMZ no puede pedir nada a los servidores, ni los servidores le escriben. Alguien de TI, conectado a su VPN, copia las imágenes **ya aprobadas**:

```bash
scp tomas.ti@planos.terranova.local:/srv/planos/renders/salida/casa_0001.png .
scp casa_0001.png azureuser@web.terranova.local:/var/www/terranova/img/
```

Así, si atacan srv-web, el atacante solo ve las imágenes públicas, no los planos.

### Paso 6 · Dominio y HTTPS (Jose Pablo)

1. **Dominio (hoy):** GitHub Student Pack → Namecheap → dominio `.me` gratis por un año, o comprar uno (~$10/año). Con el nombre de la inmobiliaria.
2. En el registrador: registro **A** `@` → `<IP-PUBLICA-FW>` y **A** `www` → `<IP-PUBLICA-FW>`. Verificar: `nslookup <dominio>`.
3. Con el dominio resolviendo y el DNAT del paso 4 funcionando:
   ```bash
   sudo apt install -y certbot python3-certbot-nginx
   sudo certbot --nginx -d <dominio> -d www.<dominio> --redirect -m <correo> --agree-tos -n
   ```
   `--redirect` agrega la redirección de http a https. La renovación queda en un timer: `systemctl list-timers | grep certbot`.
4. Pruebas: `curl -I http://<dominio>` → `301` hacia https; `curl -I https://<dominio>` → `200`; abrirlo en un celular con datos.

**Cuidado con los límites de Let's Encrypt:** si algo falla, probar primero con `--staging` y solo después sacar el certificado real.

### Paso 7 · SNMPv3 en las 4 VMs (Erick)

```bash
sudo apt install -y snmpd snmp libsnmp-dev
sudo systemctl stop snmpd
sudo net-snmp-create-v3-user -ro -a SHA -A '<clave-auth>' -x AES -X '<clave-priv>' monitor
```

En `/etc/snmp/snmpd.conf`: cambiar `agentaddress` por `udp:<IP-privada-de-la-VM>:161` y **borrar las líneas `rocommunity`** (v1/v2c mandan la comunidad en texto plano). Luego `sudo systemctl enable --now snmpd`.

Prueba desde srv-planos (para cada IP: .20, .4, .36, .37):

```bash
snmpwalk -v3 -l authPriv -u monitor -a SHA -A '<clave-auth>' -x AES -X '<clave-priv>' 10.0.0.4 system
```

Y que falle con v2c: `snmpwalk -v2c -c public 10.0.0.4 system` → timeout.

Firewall: fw-vpn y srv-web ya lo tienen en los pasos 4 y 5. En srv-render agregar `udp dport 161 ip saddr 10.0.0.36 accept`.

### Paso 8 · Prometheus + Grafana, solo para TI (Erick) · extra 10%

En srv-planos:

1. **snmp_exporter:** bajar el binario de una versión estable desde las releases de GitHub de `prometheus/snmp_exporter` (verificar el checksum) y correrlo como servicio de systemd en `127.0.0.1:9116`. En su `snmp.yml`, agregar la credencial v3:
   ```yaml
   auths:
     terranova_v3:
       version: 3
       username: monitor
       security_level: authPriv
       auth_protocol: SHA
       password: <clave-auth>
       priv_protocol: AES
       priv_password: <clave-priv>
   ```
   Usar el módulo `if_mib` (tráfico por interfaz) y, si vienen en el `snmp.yml` de esa versión, los de `hrStorage`/`ucd` para memoria y CPU.
2. **Prometheus:** `sudo apt install -y prometheus`. En `/etc/default/prometheus`: `ARGS="--web.listen-address=127.0.0.1:9090 --storage.tsdb.retention.time=7d"`. Scrape:
   ```yaml
   - job_name: snmp
     metrics_path: /snmp
     params: { auth: [terranova_v3], module: [if_mib] }
     static_configs:
       - targets: [10.0.0.20, 10.0.0.4, 10.0.0.36, 10.0.0.37]
     relabel_configs:
       - { source_labels: [__address__], target_label: __param_target }
       - { source_labels: [__param_target], target_label: instance }
       - { target_label: __address__, replacement: 127.0.0.1:9116 }
   ```
3. **Grafana:** instalar desde el repositorio oficial (`apt.grafana.com`). En `/etc/grafana/grafana.ini`: `http_addr = 10.0.0.36`, `http_port = 3000`, cambiar la clave de admin. Datasource: Prometheus `http://127.0.0.1:9090`. Tablero con: equipos arriba/abajo, tráfico por interfaz (`rate(ifHCInOctets[5m])`), uptime y memoria.
4. **Solo TI:** el firewall de srv-planos acepta todo de TI (regla de la Fase 3) y nada más llega al 3000. Prueba: abrir `http://grafana.terranova.local:3000` desde la VPN de TI (sí) y desde la de Arquitectos (no).

### Paso 9 · Planos y renders (Diego Rosales y Fabian)

**Carpeta de planos en srv-planos:**

```bash
sudo mkdir -p /srv/planos/{proyectos,renders}
sudo chgrp -R arquitectos /srv/planos && sudo chmod -R 2770 /srv/planos
sudo apt install -y acl
sudo setfacl -R -m g:ingenieros:rx -m d:g:ingenieros:rx /srv/planos    # Ingenieros: solo lectura
sudo setfacl -R -m g:ti:rwx -m d:g:ti:rwx /srv/planos                  # TI: todo
```

Acceso: `sftp ana.arq@planos.terranova.local` (o WinSCP/FileZilla) con el usuario de LDAP. Arquitectos sube y modifica, Ingenieros solo descarga, Visitantes no llega.

**NFS para que los renders se guarden en srv-planos:**
- srv-planos: `sudo apt install -y nfs-kernel-server`; `/etc/exports`: `/srv/planos/renders 10.0.0.37(rw,sync,root_squash,no_subtree_check)`; `sudo exportfs -ra`. Firewall de srv-planos: `tcp dport 2049 ip saddr 10.0.0.37 accept`.
- srv-render: `sudo apt install -y nfs-common`; en `/etc/fstab`: `planos.terranova.local:/srv/planos/renders /srv/renders nfs4 defaults,_netdev 0 0`.

**Blender en srv-render:**

```bash
sudo apt install -y blender
# un render de prueba, con prioridad baja para que la intranet siga respondiendo
nice -n 19 blender -b /srv/renders/escenas/casa.blend -o /srv/renders/salida/casa_#### -F PNG -f 1
```

La escena `casa.blend` puede ser un modelo simple del condominio. El PNG aparece en `/srv/planos/renders/salida/` de srv-planos y se usa en la página pública (paso 5b).

**Intranet:** confirmar qué versión está en `/var/www/intranet` de srv-render y copiarla al repo si es distinta de `fase-3/config/intranet.html`.

### Paso 10 · Pruebas y capturas (todos)

Las pruebas de la sección 5, con capturas para el reporte final. Aprovechar que las VMs están encendidas para tomar también las capturas de los servicios de la Fase 3.

### Paso 11 · Entregables (Fabian, con todos)

- **Diagrama:** `diagrama-fase4.drawio` (ajustar si algo cambia al implementar). Exportar a PNG para el reporte.
- **Reporte final:** un solo documento con todas las fases: informe de la Fase 2 + `fase-3/reporte-fase3.md` + la sección de la Fase 4 (qué se hizo, decisiones, pruebas con capturas, costos, problemas, referencias).
- **Presentación ejecutiva** y **ensayo de la demo** (sección 5).

---

## 5. Pruebas para el reporte y la demo

| # | Prueba | Desde | Resultado esperado |
|---|---|---|---|
| 1 | Abrir `http://<dominio>` | Celular con datos, sin VPN | Redirige a `https://`, candado válido |
| 2 | `curl -I https://<dominio>` | Cualquier lado | `200`, certificado de Let's Encrypt |
| 3 | Abrir la intranet | Celular con datos, sin VPN | No carga |
| 4 | Abrir la intranet | VPN de Arquitectos | Carga |
| 5 | `nmap -Pn <IP-PUBLICA-FW>` | Internet | Solo 80 y 443 TCP (+ UDP 1194–1197); 22 solo desde la IP del admin |
| 6 | SSH a 10.0.0.4 | Arquitectos / TI | Falla / entra |
| 7 | Desde srv-web: `ping 10.0.0.36`, `nc -zv 10.0.0.36 389` | srv-web | Fallan; el contador `dmz-hacia-interno` sube |
| 8 | Desde srv-web: `curl ifconfig.me` | srv-web | IP de fw-vpn (NAT) |
| 9 | `nslookup planos.terranova.local` | VPN de Arquitectos | 10.0.0.36 |
| 10 | `nslookup planos.terranova.local` | VPN de Visitantes | No resuelve |
| 11 | `snmpwalk -v3 ...` a las 4 VMs | srv-planos | Responden; con v2c no |
| 12 | Grafana | VPN de TI / de Arquitectos | Abre / no abre |
| 13 | SFTP: subir un archivo a `/srv/planos/proyectos` | ana.arq / ivan.ing | Sube / "Permission denied" |
| 14 | Render de Blender | srv-render | El PNG aparece en srv-planos |
| 15 | Regresión de la Fase 3 (`fase-3/demo-fase3.md`) | Las 4 VPN | Mismos resultados que en la Fase 3 |
| 16 | `ss -tulpn` y `nmap` interno | Las 4 VMs | Solo los puertos del plan |

---

## 6. Costos (estimado, pago por uso)

| Recurso | Precio | Al mes (60 h de uso) |
|---|---|---|
| fw-vpn y srv-web, B2ats_v2 | $0.0094/h c/u | $1.13 |
| srv-planos y srv-render, B2als_v2 | ≈ $0.038/h c/u (verificar en la calculadora) | ≈ $4.56 |
| 4 discos E4 | $2.40 c/u | $9.60 |
| IP pública estática | $0.005/h | $3.65 |
| Dominio | $0 (Student Pack) o ~$10/año | $0–0.83 |
| **Total** | | **≈ $19–20 al mes** |

Las VMs se apagan (Stop, desasignar) al terminar cada sesión. Los discos y la IP se cobran aunque estén apagadas. El presupuesto de $25 del paso 0 avisa si algo se pasa.

---

## 7. Riesgos

| Riesgo | Mitigación |
|---|---|
| La suscripción nueva sale con cuota baja | `01-azure.sh` lo revisa antes de crear nada; pedir 8 en Quotas hoy |
| Algo de la Fase 3 no levanta en la red nueva | Son los mismos scripts que ya funcionaron; el paso 3 lo detecta antes de seguir. La suscripción vieja queda apagada como respaldo |
| Credenciales viejas en el repo | Llave SSH, CA, certificados y contraseñas nuevas; las de `fase-3/` quedan obsoletas |
| El dominio tarda en resolver | Registrarlo hoy; TTL bajo |
| Límite de certificados de Let's Encrypt | Probar con `--staging` primero |
| Quedarse fuera de fw-vpn al cambiar nftables | Truco del borrado a los 5 minutos; Run command del portal |
| El tráfico DMZ ↔ Servidores no pasa por el firewall | Rutas del paso 3 en `rt-dmz` y `rt-servidores` |
| BIND9 choca con systemd-resolved en el puerto 53 | Revisar con `ss -lunp` después de encenderlo |
| El DNAT no funciona y no hay tiempo de arreglarlo | **Plan B (10 min):** darle a srv-web una IP pública estática, apuntar el dominio a esa IP, quitar la ruta 0/0 de `rt-dmz` y abrir 80/443 desde Internet en `nsg-dmz`. Es el diseño original de la Fase 1 |

---

## 8. Documentación de referencia

- Cuotas de vCPU: https://learn.microsoft.com/azure/quotas/per-vm-quota-requests
- Rutas definidas por el usuario: https://learn.microsoft.com/azure/virtual-network/virtual-networks-udr-overview
- Certbot con nginx: https://certbot.eff.org/
- nftables (NAT y DNAT): https://wiki.nftables.org
- BIND9: https://bind9.readthedocs.io/
- Net-SNMP: http://www.net-snmp.org/docs/
- snmp_exporter: https://github.com/prometheus/snmp_exporter
- Grafana: https://grafana.com/docs/grafana/latest/
