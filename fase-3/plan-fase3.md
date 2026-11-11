# Plan de la Fase 3 · Terranova (opción A)

Entrega: 29 de octubre. Este plan cubre todo lo que pide el PDF de la Fase 3, sobre lo que ya existe en Azure.
Opción A: la web interna corre en **srv-render** (no hay cuota para otra VM).

> **Pendiente:** Joel va a pedir subir la cuota de vCPU de 6 a 8. Si la aprueban, la intranet pasa a su propia VM (`srv-intranet`) en la subred Servidores. Los cambios están en la sección 6. Mientras tanto, todo este plan funciona sin esa VM.

> La salida de cada paso se guarda como evidencia.

---

## 1. Qué pide la fase y cómo lo cumplimos

| Requisito del PDF | Cómo lo cumplimos | Dónde |
|---|---|---|
| **DHCP** | Las VMs reciben su IP del DHCP de Azure (Azure no deja poner otro servidor DHCP en la red). Los usuarios reciben su IP de **OpenVPN**, que reparte IPs dinámicas del rango de su departamento y les manda opciones con `dhcp-option` | Azure + fw-vpn |
| **NTP** | chrony en fw-vpn reparte la hora; srv-planos y srv-render se sincronizan con él | fw-vpn |
| **LDAP** | OpenLDAP con usuarios y grupos. Se usa para entrar a la VPN y para entrar por SSH a los servidores | srv-planos |
| **Web interna** | nginx con una página de intranet. Sin IP pública; solo desde adentro | srv-render |
| **SSH de los usuarios** | Los usuarios de LDAP entran por SSH a los servidores que les tocan | srv-planos, srv-render |
| **Visitantes: Internet sí, red interna no** | Subred nueva **Visitantes** por VPN. Sale a Internet con NAT y no llega a nada interno | fw-vpn |
| **TI llega a todo; nadie llega a TI** | Reglas en nftables: TI pasa a todo, y se bloquea toda conexión nueva hacia TI | fw-vpn |
| **Web desde las demás subredes, menos visitantes y menos Internet** | nftables + NSG: Arquitectos, Ingenieros, TI y servidores sí; Visitantes e Internet no | fw-vpn + Azure |
| **NAT** | MASQUERADE en fw-vpn para la VPN y para los servidores | fw-vpn |
| **Hardening** | Firewall en cada VM, solo los puertos que se usan, SSH sin root y sin contraseña para la cuenta de admin | las 3 VMs |

---

## 2. Cambios al diseño de la Fase 1

| Antes (Fase 1) | Ahora (Fase 3) | Por qué |
|---|---|---|
| Un solo OpenVPN con pool 10.10.0.0/23 e IP fija por usuario | **4 instancias de OpenVPN**, una por grupo, cada una con su rango | Cada usuario recibe una IP dinámica dentro del rango de su grupo, sin mantener un archivo por persona. Es el papel de DHCP para la VPN |
| Sin visitantes | **Visitantes 10.10.1.64/28** | La fase lo pide. Uso: clientes en la sala de ventas o la casa modelo |
| Web pública en la DMZ | **Intranet en srv-render**, sin IP pública | La fase pide una web interna; no hay cuota para otra VM. La intranet no va en la DMZ: la DMZ es para lo que se expone a Internet, y queda reservada para la web pública de la fase final |
| Subredes temporales de departamentos en Azure | **Se borran** | Si se quedan, Azure manda las respuestas de la VPN a una subred vacía |

**Costo de las 4 instancias:** 4 puertos UDP, 4 archivos de configuración y 4 servicios. A cambio no hay que mantener un archivo por usuario. La alternativa sería una sola instancia con un script que elija la IP según el grupo, pero lleva más código.

### Direccionamiento final

| Subred | Rango | Máscara | IP del servidor VPN | IPs para usuarios | Puerto |
|---|---|---|---|---|---|
| DMZ (vacía) | 10.0.0.0/28 | 255.255.255.240 | — | — | — |
| Firewall | 10.0.0.16/28 | 255.255.255.240 | fw-vpn 10.0.0.20 | — | — |
| Servidores | 10.0.0.32/28 | 255.255.255.240 | planos .36 · render .37 | — | — |
| Arquitectos (VPN) | 10.10.1.0/27 | 255.255.255.224 | 10.10.1.1 | .2 – .30 (29) | UDP 1194 |
| Ingenieros (VPN) | 10.10.1.32/28 | 255.255.255.240 | 10.10.1.33 | .34 – .46 (13) | UDP 1195 |
| TI (VPN) | 10.10.1.48/29 | 255.255.255.248 | 10.10.1.49 | .50 – .54 (5) | UDP 1196 |
| Visitantes (VPN) | 10.10.1.64/28 | 255.255.255.240 | 10.10.1.65 | .66 – .78 (13) | UDP 1197 |

Visitantes: supuesto de hasta 10 personas a la vez, por eso /28 (2⁴ − 2 = 14).

---

## 3. Orden de trabajo (importa)

Hay una trampa: **los servidores hoy no tienen salida a Internet** (lo revisé: la subred Servidores tiene la salida por defecto de Azure apagada). Sin Internet no se puede instalar slapd, nginx ni sssd. Por eso el NAT de fw-vpn va primero.

```
1. Azure: encender VMs, borrar subredes temporales, ajustar NSG
2. fw-vpn: nftables + NAT  ──►  3. Azure: ruta 0.0.0.0/0 de Servidores hacia fw-vpn
                                     │
                                     ▼
4. srv-planos: OpenLDAP     5. srv-render: nginx      6. NTP (fw-vpn y servidores)
        │
        ▼
7. fw-vpn: 4 instancias de OpenVPN con login de LDAP
8. Servidores: SSSD (SSH con usuarios de LDAP) + hardening
9. Pruebas con capturas  ──►  10. Diagrama, reporte, slides, demo
```

### Reparto sugerido

| Quién | Tareas | Pasos |
|---|---|---|
| Joel | Cambios en el portal de Azure (NSG, rutas, subredes), captura de costos | 1, 3 |
| Diego López | fw-vpn: nftables, NAT y las 4 instancias de OpenVPN | 2, 7 |
| Diego Rosales | OpenLDAP en srv-planos y SSSD en los servidores | 4, 8 |
| Jose Pablo | nginx en srv-render y NTP | 5, 6 |
| Erick | Hardening de las 3 VMs y pruebas de la ACL | 8, 9 |
| Fabian | Diagrama, reporte sobre el documento de la Fase 2, slides, juntar capturas | 10 |

Para que varios trabajen a la vez en las VMs, cada uno necesita: su IP en la regla `Allow-SSH-Admin` y su llave pública en `~/.ssh/authorized_keys` de `azureuser`. Si no, trabajen desde la laptop de Diego.

---

## 4. Pasos

### Paso 1 · Azure (Joel)

1. Encender las 3 VMs.
2. Borrar las subredes **Arquitectos, Ingenieros y TI** de `vnet-proyecto` y después el espacio **10.10.1.0/26** (Virtual network → Address space).
3. `nsg-firewall`:
   - `Allow-OpenVPN`: puertos **1194-1197** UDP desde Internet.
   - Nueva `Allow-Salida-Servidores` (prioridad 150): origen 10.0.0.32/28, destino cualquiera, cualquier puerto, Permitir. Sin esta, el NSG bloquea el tráfico de los servidores que fw-vpn tiene que sacar a Internet.
   - `Allow-SSH-Admin`: agregar las IPs de quienes van a trabajar y la de donde se presenta.
   - Nueva `Allow-VPN-Hacia-Red` (**salida**, prioridad 100): origen 10.10.1.0/24, destino 10.0.0.0/16, Permitir. *Descubierta al probar:* sin ella, Azure bota el tráfico de la VPN que fw-vpn reenvía a los servidores.
4. `nsg-servidores` (cambiar las reglas amplias por reglas por grupo):

| Prioridad | Nombre | Origen | Destino | Puerto | Acción |
|---|---|---|---|---|---|
| 100 | Allow-TI-Todo | 10.10.1.48/29 | cualquiera | cualquiera | Permitir |
| 110 | Allow-SSH-Planos | 10.0.0.20, 10.10.1.0/27, 10.10.1.32/28 | 10.0.0.36 | 22 | Permitir |
| 120 | Allow-SSH-Render | 10.0.0.20, 10.0.0.36, 10.10.1.0/27 | 10.0.0.37 | 22 | Permitir |
| 130 | Allow-Web-Intranet | 10.0.0.0/16, 10.10.1.0/27, 10.10.1.32/28 | 10.0.0.37 | 80 | Permitir |
| 140 | Allow-LDAP | 10.0.0.16/28, 10.0.0.32/28 | 10.0.0.36 | 389, 636 | Permitir |
| 150 | Allow-ICMP | 10.0.0.0/16, 10.10.1.0/27, 10.10.1.32/28 | cualquiera | ICMP | Permitir |
| 4000 | Deny-Resto | cualquiera | cualquiera | cualquiera | Denegar |

   Borrar la vieja `Allow-SSH` (desde 10.10.0.0/16, que incluiría a Visitantes). `Allow-SMB-Planos` se puede dejar para la fase final.
5. `nsg-dmz`: borrar `Allow-HTTP` y `Allow-HTTPS` desde Internet. La DMZ queda vacía y la web no debe verse desde Internet.

### Paso 2 · nftables y NAT en fw-vpn (Diego López)

Archivo `/etc/nftables.conf` (cambiar `IP_ADMIN` por las IPs reales):

```
#!/usr/sbin/nft -f
flush ruleset

table inet filtro {
  chain input {
    type filter hook input priority 0; policy drop;
    iif lo accept
    ct state established,related accept
    ct state invalid drop
    udp sport 67 udp dport 68 accept
    udp dport 1194-1197 accept
    tcp dport 22 ip saddr { IP_ADMIN/32, 10.10.1.48/29 } accept
    udp dport 123 ip saddr { 10.0.0.0/16, 10.10.1.0/27, 10.10.1.32/28, 10.10.1.48/29 } accept
    icmp type echo-request ip saddr { 10.0.0.0/16, 10.10.1.0/27, 10.10.1.32/28, 10.10.1.48/29 } accept
  }

  chain forward {
    type filter hook forward priority 0; policy drop;
    ct state established,related accept
    ct state invalid drop

    # Nadie inicia conexiones hacia TI
    ip daddr 10.10.1.48/29 ct state new counter drop
    # TI llega a todo
    ip saddr 10.10.1.48/29 accept

    # Visitantes: nada interno, solo Internet
    ip saddr 10.10.1.64/28 ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } counter drop
    ip saddr 10.10.1.64/28 oifname "eth0" accept

    # Arquitectos: planos (SSH) y render (SSH y web)
    ip saddr 10.10.1.0/27 ip daddr 10.0.0.36 tcp dport 22 accept
    ip saddr 10.10.1.0/27 ip daddr 10.0.0.37 tcp dport { 22, 80 } accept
    # Ingenieros: planos (SSH) y solo la web de render
    ip saddr 10.10.1.32/28 ip daddr 10.0.0.36 tcp dport 22 accept
    ip saddr 10.10.1.32/28 ip daddr 10.0.0.37 tcp dport 80 accept
    # Ping de los departamentos a los servidores
    ip saddr { 10.10.1.0/27, 10.10.1.32/28 } ip daddr 10.0.0.32/28 icmp type echo-request accept

    # Salida a Internet (con NAT) para departamentos y servidores
    ip saddr { 10.10.1.0/27, 10.10.1.32/28, 10.0.0.32/28 } ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } oifname "eth0" accept

    counter drop
  }
}

table ip nat {
  chain postrouting {
    type nat hook postrouting priority srcnat; policy accept;
    oifname "eth0" ip saddr { 10.10.1.0/24, 10.0.0.32/28 } ip daddr != { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } masquerade
  }
}
```

Para no quedarse fuera por SSH al aplicarlo:

```bash
sudo nft -c -f /etc/nftables.conf                         # revisa la sintaxis sin aplicar
( sleep 300; sudo nft flush ruleset ) &                  # si me quedo fuera, se borra solo en 5 min
sudo nft -f /etc/nftables.conf
# abrir OTRA terminal y probar SSH; si entra, cancelar el borrado:
kill %1
sudo systemctl enable --now nftables
```

Si igual se pierde el acceso: portal → fw-vpn → **Run command** → `nft flush ruleset`.

### Paso 3 · Ruta de Servidores (Joel)

Route table `rt-servidores` en North Central US, asociada **solo** a la subred Servidores:

| Ruta | Destino | Siguiente salto |
|---|---|---|
| vpn-hacia-fw | 10.10.0.0/16 | Aplicación virtual 10.0.0.20 |
| internet-hacia-fw | 0.0.0.0/0 | Aplicación virtual 10.0.0.20 |

Agregar `0.0.0.0/0` **después** de que el NAT del paso 2 funcione. Prueba: desde srv-planos `curl -s ifconfig.me` debe mostrar la IP pública de fw-vpn. La DMZ está vacía, así que no lleva tabla de rutas. La subred Firewall nunca lleva.

### Paso 4 · OpenLDAP en srv-planos (Diego Rosales)

```bash
sudo apt update && sudo apt install -y slapd ldap-utils
sudo dpkg-reconfigure slapd        # dominio: terranova.local · organización: Terranova
```

Estructura (`base.ldif`):

```
dc=terranova,dc=local
├── ou=usuarios   →  uid=ana.arq, uid=ivan.ing, uid=tomas.ti, uid=visita1
└── ou=grupos     →  cn=arquitectos, cn=ingenieros, cn=ti, cn=visitantes (posixGroup con memberUid)
```

Cada usuario: `objectClass: inetOrgPerson, posixAccount, shadowAccount`, con `uidNumber`, `gidNumber`, `homeDirectory`, `loginShell` y clave con `slappasswd`. Cargar con `ldapadd -x -D cn=admin,dc=terranova,dc=local -W -f base.ldif`.

Evidencia: `ldapsearch -x -b dc=terranova,dc=local "(objectClass=posixGroup)" cn memberUid`.

Mejora si sobra tiempo: LDAPS (636) con un certificado propio. Sin eso, el tráfico LDAP va en texto plano dentro de la red interna, y hay que decirlo en el reporte.

### Paso 5 · Web interna en srv-render (Jose Pablo)

```bash
sudo apt install -y nginx
```

En `/etc/nginx/sites-available/default`: `listen 10.0.0.37:80;` (no en 0.0.0.0) y una página `index.html` de "Intranet Terranova" con los proyectos. Evidencia: `curl http://10.0.0.37` desde una laptop de Arquitectos, y que falle desde Visitantes y desde Internet.

Como la web comparte máquina con el render, hay que protegerla:
- nginx escucha solo en 10.0.0.37, nunca en todas las interfaces.
- El firewall de srv-render (paso 8) solo deja entrar al puerto 80 a quien corresponde.
- Cuando se instale Blender (fase final), limitar su CPU para que un render pesado no deje sin respuesta a la web. Por ejemplo, correrlo con `systemd-run --scope -p CPUQuota=150% blender ...`.
- En el reporte: "Por la cuota de 6 vCPU de Azure for Students, la intranet comparte VM con srv-render. Lo ideal es una VM propia en la subred Servidores".

### Paso 6 · NTP (Jose Pablo)

fw-vpn, en `/etc/chrony/chrony.conf` agregar:

```
allow 10.0.0.0/16
allow 10.10.1.0/24
```

srv-planos y srv-render: comentar las líneas `pool` y `refclock` y agregar `server 10.0.0.20 iburst prefer`. Reiniciar con `sudo systemctl restart chrony`.

Evidencia: en los servidores, `chronyc sources -v` debe mostrar `^* 10.0.0.20`; en fw-vpn, `sudo chronyc clients`.

### Paso 7 · OpenVPN con 4 instancias (Diego López)

1. `sudo apt install -y openvpn easy-rsa ldap-utils`
2. Una sola CA con easy-rsa: certificado del servidor (`fw-vpn`) y uno por laptop del equipo. `openvpn --genkey secret /etc/openvpn/server/ta.key`.
3. Un archivo por grupo en `/etc/openvpn/server/`: `arq.conf`, `ing.conf`, `ti.conf`, `vis.conf`. Plantilla (`arq.conf`):

```
port 1194
proto udp
dev tun-arq
dev-type tun
topology subnet
server 10.10.1.0 255.255.255.224
ca   /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/fw-vpn.crt
key  /etc/openvpn/server/fw-vpn.key
dh none
tls-crypt /etc/openvpn/server/ta.key
ifconfig-pool-persist /var/lib/openvpn/ipp-arq.txt
status /var/log/openvpn/arq-status.log
push "redirect-gateway def1"
push "dhcp-option DNS 1.1.1.1"
script-security 2
auth-user-pass-verify "/etc/openvpn/server/ldap-auth.sh arquitectos" via-file
username-as-common-name
keepalive 10 60
persist-key
persist-tun
user nobody
group nogroup
verb 3
```

| Archivo | `port` | `dev` | `server` | Grupo LDAP |
|---|---|---|---|---|
| arq.conf | 1194 | tun-arq | 10.10.1.0 255.255.255.224 | arquitectos |
| ing.conf | 1195 | tun-ing | 10.10.1.32 255.255.255.240 | ingenieros |
| ti.conf | 1196 | tun-ti | 10.10.1.48 255.255.255.248 | ti |
| vis.conf | 1197 | tun-vis | 10.10.1.64 255.255.255.240 | visitantes |

**No poner `client-to-client`**: con esa opción el tráfico entre usuarios no pasa por nftables y la regla de TI no se cumple.

Si OpenVPN no acepta `server` con el /29 de TI, usar en `ti.conf`: `mode server`, `tls-server`, `ifconfig 10.10.1.49 255.255.255.248`, `ifconfig-pool 10.10.1.50 10.10.1.54`, `push "topology subnet"` y `push "route-gateway 10.10.1.49"`.

4. Script `/etc/openvpn/server/ldap-auth.sh` (permisos 755). Revisa la clave en LDAP y que el usuario sea del grupo de esa instancia:

```bash
#!/bin/bash
# $1 = grupo requerido; $2 = archivo de OpenVPN con usuario (línea 1) y clave (línea 2)
GRUPO="$1"; ARCHIVO="$2"
BASE="dc=terranova,dc=local"; SERVIDOR="ldap://10.0.0.36"
USUARIO=$(sed -n 1p "$ARCHIVO")
[[ "$USUARIO" =~ ^[a-z0-9._-]+$ ]] || exit 1
CLAVE=$(mktemp); sed -n 2p "$ARCHIVO" | tr -d '\n' > "$CLAVE"
ldapwhoami -x -H "$SERVIDOR" -D "uid=$USUARIO,ou=usuarios,$BASE" -y "$CLAVE" >/dev/null 2>&1
OK=$?; rm -f "$CLAVE"
[ "$OK" -eq 0 ] || exit 1
ldapsearch -x -LLL -H "$SERVIDOR" -b "ou=grupos,$BASE" "(&(cn=$GRUPO)(memberUid=$USUARIO))" cn | grep -q "^cn: $GRUPO$"
```

5. Encender las 4: `sudo systemctl enable --now openvpn-server@arq openvpn-server@ing openvpn-server@ti openvpn-server@vis`
6. Un perfil `.ovpn` por grupo para las laptops (con `auth-user-pass`, el puerto de su grupo y su certificado).

### Paso 8 · SSH con usuarios de LDAP y hardening (Diego Rosales y Erick)

**SSSD en srv-planos y srv-render:** `sudo apt install -y sssd-ldap libpam-sss libnss-sss`. En `/etc/sssd/sssd.conf` (permisos 600): `id_provider = ldap`, `auth_provider = ldap`, `ldap_uri = ldap://10.0.0.36`, `ldap_search_base = dc=terranova,dc=local`, `access_provider = simple` y:
- srv-planos: `simple_allow_groups = arquitectos, ingenieros, ti`
- srv-render: `simple_allow_groups = arquitectos, ti`

Luego `sudo pam-auth-update --enable mkhomedir`.

**sshd** (`/etc/ssh/sshd_config.d/terranova.conf`):

```
PermitRootLogin no
PasswordAuthentication no
Match Group arquitectos,ingenieros,ti
    PasswordAuthentication yes
```

La cuenta `azureuser` sigue solo con llave; los usuarios de LDAP entran con su clave.

**Firewall en cada servidor** (nftables, política drop en input):
- srv-planos: 22 desde 10.0.0.20, Arquitectos, Ingenieros y TI; 389/636 desde 10.0.0.20, .36 y .37; ICMP interno; DHCP (udp 67→68).
- srv-render: 22 desde 10.0.0.20, 10.0.0.36, Arquitectos y TI; 80 desde 10.0.0.0/16, Arquitectos, Ingenieros y TI; ICMP interno; DHCP.

Usar el mismo truco del borrado a los 5 minutos del paso 2. Evidencia de hardening: `sudo ss -tulpn` antes y después en cada VM, y `nmap` desde la laptop de TI a cada VM.

---

## 5. Pruebas para el reporte y la demo

| # | Prueba | Desde | Resultado esperado |
|---|---|---|---|
| 1 | Conectar a la VPN de Arquitectos | laptop | Recibe una IP entre 10.10.1.2 y .30 |
| 2 | Conectar a la VPN de TI con un usuario de Arquitectos | laptop | Rechazado (no es del grupo) |
| 3 | SSH con usuario LDAP a srv-planos y srv-render | Arquitectos | Entra a los dos |
| 4 | SSH a srv-render | Ingenieros | Falla; a srv-planos sí entra |
| 5 | Ping y SSH a todo | TI | Funciona |
| 6 | Ping a la laptop de TI | srv-planos o Arquitectos | Falla (contador de drop en nftables) |
| 7 | `curl ifconfig.me` | Visitantes | Muestra la IP de fw-vpn (Internet con NAT) |
| 8 | Ping a 10.0.0.36 y `curl http://10.0.0.37` | Visitantes | Fallan |
| 9 | `curl http://10.0.0.37` | Arquitectos, Ingenieros, TI | Muestra la intranet |
| 10 | Abrir la intranet desde Internet | celular con datos | No hay forma: render no tiene IP pública |
| 11 | `curl ifconfig.me` | srv-planos | IP de fw-vpn (NAT de servidores) |
| 12 | `chronyc sources -v` | srv-planos | `^* 10.0.0.20` |
| 13 | `ldapsearch` de usuarios y grupos | srv-planos | Lista los 4 grupos |
| 14 | IP por DHCP | VM y laptop | `networkctl status eth0` en la VM; IP de la VPN en `ipconfig` y en el archivo de estado de OpenVPN |
| 15 | `ss -tulpn` y `nmap` | cada VM | Solo los puertos del plan |

Una sola laptop puede probar los 4 grupos conectándose a un perfil a la vez. Para la prueba 6 hacen falta dos: TI conectada y otra fuente intentando llegar a ella.

---

## 6. Pendientes y riesgos

### Pendiente: cuota para la VM de la intranet

Joel pide subir **Total Regional vCPUs** de North Central US de 6 a 8 (y la familia BASv2 si también está al límite). **No se convierte la suscripción a pago por esto.**

- **Si la niegan:** no cambia nada; la intranet se queda en srv-render.
- **Si la aprueban**, estos son los cambios:

| Qué | Cambio |
|---|---|
| VM nueva | `srv-intranet`, B2ats_v2, Ubuntu 24.04, subred **Servidores**, IP fija **10.0.0.38**, sin IP pública |
| Web | Instalar nginx en srv-intranet (`listen 10.0.0.38:80`) y quitarlo de srv-render |
| `nsg-servidores` | `Allow-Web-Intranet` con destino 10.0.0.38 en vez de 10.0.0.37 |
| nftables de fw-vpn | En las reglas de Arquitectos e Ingenieros, el puerto 80 va a 10.0.0.38. Ingenieros ya no necesita llegar a 10.0.0.37 |
| Firewall de srv-render | Quitar el puerto 80 |
| NTP y SSSD | Igual que en los otros servidores (paso 6 y paso 8) |
| Diagrama | Agregar srv-intranet en la subred Servidores |

### Otros pendientes

- **Confirmar con el profe:** que DHCP de Azure + OpenVPN cumple el requisito de DHCP, y que está bien agregar Visitantes al caso 4.
- **El más arriesgado:** OpenVPN + LDAP (paso 7). Si se atrasa, probar primero las instancias sin `auth-user-pass-verify` (solo certificados) y agregar LDAP después.
- **IP de la demo:** agregar a `Allow-SSH-Admin` la IP de donde se presenta.
- **Costo:** unas 10 horas con las 3 VMs encendidas son unos $0.28. Al terminar, Stop (deallocated).
- **Fuera de alcance de la Fase 3** (fase final): Samba, Blender, BIND9, respaldos en Blob y la web pública.

## 7. Documentación consultada

- DHCP en Azure: [Azure Virtual Network FAQ](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq), sección "Can I deploy a DHCP server in a virtual network?"
- NIC y suscripción: [Create, change, or delete Azure network interfaces](https://learn.microsoft.com/en-us/azure/virtual-network/virtual-network-network-interface)
