# Plan final de la Fase 4 · Terranova

**Entrega: 13 de noviembre de 2026.** Diagrama: [`diagrama-fase4.drawio`](diagrama-fase4.drawio).

Este plan parte de lo que ya existe en Azure (Fase 3) y agrega lo que piden el enunciado de la Fase 4, el caso 4 del documento del proyecto y el profesor.

> La salida de cada paso se guarda como evidencia en `fase-4/evidencia/`.
> Los valores entre `<...>` (contraseñas, dominio, IP del admin) se completan al aplicar. Las contraseñas van en `fase-4/credenciales-fase4.txt`, no en este archivo.

---

## 0. Estado de partida (verificado el 10 de noviembre)

| Qué | Estado |
|---|---|
| Suscripción | **Todavía es Azure for Students** (`quotaId: AzureForStudents_2018-01-01`, límite de gasto activo). Hay que convertirla a pago (paso 0) |
| Cuota de vCPU en North Central US | 6 de 6 usadas (familia Basv2: 6 de 10) |
| VMs | fw-vpn, srv-planos y srv-render existen, apagadas (B2ats_v2) |
| Fase 3 | Todo implementado y probado: VPN ×4 con LDAP, NAT, ACL, NTP, DHCP, intranet, hardening |
| Página pública | **No existe** (ni VM ni contenido) |
| Intranet | Existe en srv-render. Falta confirmar si está desplegada la versión rediseñada de r0sv |
| Zona DNS interna | **No existe** (la pide el caso 4) |

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
| fw-vpn | Firewall 10.0.0.16/28 | 10.0.0.20 (pública 52.162.223.107) | B2ats_v2 (2 vCPU, 1 GiB) | nftables (ACL, NAT, **DNAT**), OpenVPN ×4, chrony, **BIND9**, **snmpd** |
| **srv-web** (nueva) | **DMZ 10.0.0.0/28** | **10.0.0.4**, sin IP pública | B2ats_v2 (2 vCPU, 1 GiB) | **nginx + Certbot**, snmpd |
| srv-planos | Servidores 10.0.0.32/28 | 10.0.0.36 | **B2als_v2 (2 vCPU, 4 GiB)** | OpenLDAP, **carpeta de planos**, **NFS para renders**, **Prometheus + Grafana**, snmpd |
| srv-render | Servidores 10.0.0.32/28 | 10.0.0.37 | **B2als_v2 (2 vCPU, 4 GiB)** | intranet (nginx), **Blender**, snmpd |

**Cuota necesaria:** 4 VMs × 2 vCPU = **8**.
**Por qué se agrandan srv-planos y srv-render:** con 1 GiB no caben LDAP + Prometheus + Grafana, ni un render de Blender. B2als_v2 tiene las mismas 2 vCPU (no gasta más cuota) y 4 GiB.

### Decisión: la web entra por el firewall (DNAT), no con IP propia

En la Fase 1 se diseñó srv-web con su propia IP pública. Se cambia a DNAT por tres razones (van en el reporte):
1. La Fase 4 pide modificar el firewall para los nuevos requerimientos: con DNAT, todo el tráfico público pasa por fw-vpn.
2. Una sola puerta de entrada y ninguna VM interna con IP pública; la DMZ queda aislada por la regla `dmz-hacia-interno`.
3. Una IP pública menos (~$3.65/mes).

Costo: más configuración, y si fw-vpn se apaga, la web se cae. Plan B en la sección 7.

El dominio funciona igual: su registro A apunta a la IP de fw-vpn. La redirección de http a https la hace nginx en srv-web; el firewall solo reenvía 80 y 443. Certbot valida el dominio por el puerto 80 a través del DNAT.

### Recorrido de una visita a la página web

```
Celular ──► https://<dominio>  (DNS público: A → 52.162.223.107)
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
0. Joel: convertir a pago y pedir cuota 8 ──┐        Dominio (Jose Pablo): HOY,
                                            │        la propagación puede tardar
1. Agrandar srv-planos y srv-render ◄───────┤        Página pública (paso 5a): HOY,
2. Crear srv-web ◄──── necesita la cuota ───┘        no necesita Azure
3. Rutas y NSG
4. fw-vpn: nftables (DNAT + DMZ) + BIND9 + SSH de root
5. srv-web: nginx, página, firewall ──► 6. Certbot (necesita dominio + DNAT)
7. SNMPv3 en las 4 VMs ──► 8. Prometheus + Grafana
9. Carpeta de planos + NFS + Blender
10. Pruebas y capturas (también las que faltan de la Fase 3)
11. Diagrama, reporte final, presentación, ensayo
```

Lo que no necesita la VM nueva (paso 4 sin el DNAT, 5a, 7, 8 y 9) puede empezar mientras llega la cuota.

### Reparto

| Quién | Pasos |
|---|---|
| Joel | 0, 1, 2, 3 y la captura de costos |
| Diego López | 4 (nftables, BIND9, DNS en la VPN, SSH de root) |
| Jose Pablo | Dominio, 5 y 6 |
| Erick | 7, 8 y el firewall de srv-web |
| Diego Rosales | 9 (carpeta, NFS) y confirmar qué versión de la intranet está en srv-render |
| Fabian | Blender (9), renders para la página, 11 y juntar las capturas |

Todos: capturas de su parte para el reporte.

### Calendario

| Día | Objetivo |
|---|---|
| **10 nov (hoy)** | Paso 0 (conversión y cuota), dominio registrado, contenido y HTML de la página pública |
| **11 nov** | Pasos 1–9: todo implementado |
| **12 nov** | Paso 10 (pruebas y capturas) y paso 11 (reporte, diagrama, presentación); ensayo de la demo |
| **13 nov** | Entrega y demo. Encender las VMs 30 minutos antes |

---

## 4. Pasos

### Paso 0 · Suscripción de pago y cuota (Joel)

1. Revisar cuánto crédito queda (Cost Management). **Al convertir, lo más probable es que se pierda el crédito de estudiante que quede.**
2. Portal → **Subscriptions** → la suscripción del proyecto (`17bfaf33-…`) → **Upgrade** → tarjeta. Es la misma suscripción: no se borra ni se mueve nada.
3. **Verificar** que la conversión quedó hecha (debe dejar de decir `AzureForStudents`):
   ```bash
   az rest --method get --url "https://management.azure.com/subscriptions/17bfaf33-8d04-4cd4-8549-276b18b372ec?api-version=2022-12-01" --query "subscriptionPolicies.quotaId"
   ```
4. Portal → **Quotas** → Compute → North Central US → **Total Regional vCPUs**: pedir **8** (hoy 6). Si no se habilita (hay reportes de demora después de convertir), abrir un caso de soporte.
5. Verificar: `az vm list-usage -l northcentralus -o table` → "Total Regional vCPUs" con límite 8.
6. Crear un presupuesto con alerta (Cost Management → Budgets) de $25 al mes.

### Paso 1 · Agrandar los servidores (Joel)

```bash
az vm deallocate -g rg-redes-proyecto -n srv-planos
az vm resize     -g rg-redes-proyecto -n srv-planos --size Standard_B2als_v2
az vm deallocate -g rg-redes-proyecto -n srv-render
az vm resize     -g rg-redes-proyecto -n srv-render --size Standard_B2als_v2
```

Las IPs privadas son estáticas, no cambian. Después de encender, verificar que la VPN, LDAP, la intranet y NTP siguen funcionando (`fase-3/demo-fase3.md` sirve de guía).

### Paso 2 · Crear srv-web (Joel)

```bash
az vm create -g rg-redes-proyecto -n srv-web -l northcentralus \
  --image Ubuntu2204 --size Standard_B2ats_v2 \
  --vnet-name vnet-proyecto --subnet DMZ --private-ip-address 10.0.0.4 \
  --public-ip-address "" --nsg "" \
  --admin-username azureuser --ssh-key-values fase-3/llaves/redes_key.pub
```

- `--public-ip-address ""`: sin IP pública. `--nsg ""`: sin NSG en la tarjeta (manda el de la subred).
- Se administra desde fw-vpn o desde la VPN de TI: `ssh -J azureuser@52.162.223.107 azureuser@10.0.0.4`.
- No tiene salida a Internet hasta el paso 3 (ruta) y el paso 4 (NAT).

### Paso 3 · Rutas y NSG (Joel)

**Rutas:**

```bash
az network route-table create -g rg-redes-proyecto -n rt-dmz -l northcentralus
az network route-table route create -g rg-redes-proyecto --route-table-name rt-dmz -n internet-hacia-fw   --address-prefix 0.0.0.0/0    --next-hop-type VirtualAppliance --next-hop-ip-address 10.0.0.20
az network route-table route create -g rg-redes-proyecto --route-table-name rt-dmz -n vpn-hacia-fw        --address-prefix 10.10.0.0/16 --next-hop-type VirtualAppliance --next-hop-ip-address 10.0.0.20
az network route-table route create -g rg-redes-proyecto --route-table-name rt-dmz -n servidores-hacia-fw --address-prefix 10.0.0.32/28 --next-hop-type VirtualAppliance --next-hop-ip-address 10.0.0.20
az network vnet subnet update -g rg-redes-proyecto --vnet-name vnet-proyecto -n DMZ --route-table rt-dmz

az network route-table route create -g rg-redes-proyecto --route-table-name rt-servidores -n dmz-hacia-fw --address-prefix 10.0.0.0/28 --next-hop-type VirtualAppliance --next-hop-ip-address 10.0.0.20
```

**`nsg-firewall`** (lección de la Fase 3: el NSG de la subred Firewall también filtra el tráfico que fw-vpn reenvía):

| Dirección | Prioridad | Nombre | Origen | Destino | Puerto | Para qué |
|---|---|---|---|---|---|---|
| Entrada | 105 | Allow-Web-Publico | Internet | cualquiera | TCP 80, 443 | Visitas a la página |
| Entrada | 150 | Allow-Salida-Servidores | **10.0.0.32/28, 10.0.0.0/28** | cualquiera | cualquiera | Agregar la DMZ: salida a Internet de srv-web |
| Entrada | 155 | Allow-SNMP-Colector | 10.0.0.36 | cualquiera | UDP 161 | Monitoreo de fw-vpn y de srv-web (pasa por fw-vpn) |
| Salida | 110 | Allow-DNAT-Web | cualquiera | 10.0.0.4 | TCP 80, 443 | Reenviar las visitas a srv-web |

Las reglas actuales (`Allow-OpenVPN`, `Allow-SSH-Admin`, `Allow-DNS-NTP`, `Allow-ICMP`, `Allow-Retorno-VPN`, `Allow-VPN-Hacia-Red`, `Deny-Resto`) se mantienen. `Allow-DNS-NTP` ya cubre el DNS de BIND9.

**`nsg-dmz`** (reemplaza las reglas actuales `Allow-SSH-Interno` y `Allow-ICMP`, que aceptan toda la red):

| Prioridad | Nombre | Origen | Destino | Puerto |
|---|---|---|---|---|
| 100 | Allow-Web | cualquiera | 10.0.0.4 | TCP 80, 443 |
| 110 | Allow-SSH-Admin-TI | 10.0.0.20, 10.10.1.48/29 | 10.0.0.4 | TCP 22 |
| 120 | Allow-SNMP-Colector | 10.0.0.36 | 10.0.0.4 | UDP 161 |
| 130 | Allow-ICMP-TI | 10.0.0.20, 10.10.1.48/29 | 10.0.0.4 | ICMP |
| 4000 | Deny-Resto | cualquiera | cualquiera | cualquiera |

**`nsg-servidores`:**
- `Allow-Web-Intranet` y `Allow-ICMP`: cambiar el origen `10.0.0.0/16` por `10.0.0.16/28, 10.0.0.32/28` para que **la DMZ no entre**.
- **Borrar `Allow-SMB-Planos`**: el 445 no se usa (no hay Samba). Es hardening.
- Agregar `Allow-NFS-Renders` (prioridad 145): 10.0.0.37 → 10.0.0.36, TCP 2049.
- Agregar `Allow-SNMP-Colector` (prioridad 150): 10.0.0.36 → 10.0.0.37, UDP 161.
- Grafana no necesita regla: `Allow-TI-Todo` ya lo cubre.

### Paso 4 · fw-vpn (Diego López)

#### 4.1 nftables

Cambios sobre `fase-3/config/fw-nftables.conf` (guardar el nuevo como `fase-4/config/fw-nftables.conf`):

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
    ip daddr 52.162.223.107 tcp dport { 80, 443 } dnat to 10.0.0.4
  }
  chain postrouting {
    type nat hook postrouting priority srcnat; policy accept;
    oifname "eth0" ip saddr { 10.10.1.0/24, 10.0.0.32/28, 10.0.0.0/28 } ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } masquerade
  }
}
```

**Importante:** la regla de la web va **antes** de `visitantes-interno` y de `dmz-hacia-interno`, porque fw-vpn tiene una sola tarjeta (`eth0`) y todo sale por ella. Aplicar con el truco de la Fase 3 (borrado automático a los 5 minutos si se pierde el SSH).

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
- **Firewall** (Erick), `/etc/nftables.conf`:
  ```
  table inet filtro {
    chain input {
      type filter hook input priority 0; policy drop;
      iif lo accept
      ct state established,related accept
      ct state invalid drop
      udp sport 67 udp dport 68 accept
      tcp dport { 80, 443 } accept
      tcp dport 22 ip saddr { 10.0.0.20, 10.10.1.48/29 } accept
      udp dport 161 ip saddr 10.0.0.36 accept
      icmp type echo-request ip saddr { 10.0.0.20, 10.10.1.48/29 } accept
      counter
    }
  }
  ```
- **SSH:** sin root, sin contraseña (`PermitRootLogin no`, `PasswordAuthentication no`). **No** se instala SSSD/LDAP: es un servidor público y no debe poder consultar el directorio de usuarios.

**Cómo llegan los renders a la página sin romper la DMZ:** la DMZ no puede pedir nada a los servidores, ni los servidores le escriben. Alguien de TI, conectado a su VPN, copia las imágenes **ya aprobadas**:

```bash
scp tomas.ti@planos.terranova.local:/srv/planos/renders/salida/casa_0001.png .
scp casa_0001.png azureuser@web.terranova.local:/var/www/terranova/img/
```

Así, si atacan srv-web, el atacante solo ve las imágenes públicas, no los planos.

### Paso 6 · Dominio y HTTPS (Jose Pablo)

1. **Dominio (hoy):** GitHub Student Pack → Namecheap → dominio `.me` gratis por un año, o comprar uno (~$10/año). Con el nombre de la inmobiliaria.
2. En el registrador: registro **A** `@` → `52.162.223.107` y **A** `www` → `52.162.223.107`. Verificar: `nslookup <dominio>`.
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
| 5 | `nmap -Pn 52.162.223.107` | Internet | Solo 80 y 443 TCP (+ UDP 1194–1197); 22 solo desde la IP del admin |
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
| La conversión a pago o la cuota tardan | Hacerlo hoy; avanzar mientras tanto con los pasos 4, 5a, 7, 8 y 9; abrir caso de soporte |
| Se pierde el crédito de estudiante al convertir | Revisarlo antes; el costo de pago por uso es bajo |
| El dominio tarda en resolver | Registrarlo hoy; TTL bajo |
| Límite de certificados de Let's Encrypt | Probar con `--staging` primero |
| Quedarse fuera de fw-vpn al cambiar nftables | Truco del borrado a los 5 minutos; Run command del portal |
| El tráfico DMZ ↔ Servidores no pasa por el firewall | Rutas del paso 3 en `rt-dmz` y `rt-servidores` |
| BIND9 choca con systemd-resolved en el puerto 53 | Revisar con `ss -lunp` después de encenderlo |
| El DNAT no funciona y no hay tiempo de arreglarlo | **Plan B (10 min):** darle a srv-web una IP pública estática, apuntar el dominio a esa IP, quitar la ruta 0/0 de `rt-dmz` y abrir 80/443 desde Internet en `nsg-dmz`. Es el diseño original de la Fase 1 |

---

## 8. Documentación de referencia

- Pasar Azure for Students a pago: https://learn.microsoft.com/azure/cost-management-billing/manage/upgrade-azure-subscription
- Rutas definidas por el usuario: https://learn.microsoft.com/azure/virtual-network/virtual-networks-udr-overview
- Certbot con nginx: https://certbot.eff.org/
- nftables (NAT y DNAT): https://wiki.nftables.org
- BIND9: https://bind9.readthedocs.io/
- Net-SNMP: http://www.net-snmp.org/docs/
- snmp_exporter: https://github.com/prometheus/snmp_exporter
- Grafana: https://grafana.com/docs/grafana/latest/
