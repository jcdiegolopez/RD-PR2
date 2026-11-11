# Proyecto Final, Fase 3 · Servicios de red y seguridad en Azure

Informe de la Fase 3 del Caso 4: desarrolladora de bienes raíces (Terranova).
Curso: Redes de Computadoras 2026 (CC3067, Sección 30). Docente: Juan Carlos Canteo Boix.
Integrantes: Jose Pablo, Joel Jaquez, Diego López, Erick Guerra, Diego Rosales, Fabian Morales. Octubre de 2026.

## Resumen ejecutivo

Sobre la red de la Fase 2 se levantaron los servicios de administración, la web interna y la seguridad que pide la Fase 3:

- **DHCP:** las VMs reciben su IP del DHCP de Azure y los usuarios reciben una IP dinámica del rango de su departamento por OpenVPN.
- **NTP:** fw-vpn reparte la hora con chrony; los dos servidores se sincronizan con él.
- **LDAP:** OpenLDAP en srv-planos, con usuarios y grupos. Controla quién entra a cada VPN y quién entra por SSH a cada servidor.
- **Web interna:** nginx en srv-render, sin IP pública. La ven Arquitectos, Ingenieros, TI y los servidores; Visitantes e Internet no.
- **Firewall y ACL:** nftables en fw-vpn con NAT. TI llega a todo y nadie inicia conexiones hacia TI. Visitantes solo sale a Internet.
- **Hardening:** firewall con política DROP en las 3 VMs, solo los puertos en uso y SSH sin contraseña para el administrador.

Todo se implementó el 28 de octubre y se probó grupo por grupo desde una laptop real conectada a la VPN.

## 1. Cambios respecto a la Fase 2

| Fase 2 | Fase 3 | Por qué |
|---|---|---|
| Un solo OpenVPN (diseño) con pool 10.10.0.0/23 e IP fija por usuario | **4 instancias de OpenVPN**, una por grupo, cada una con su rango (UDP 1194–1197) | Cada usuario recibe una IP dinámica del rango de su grupo sin mantener un archivo por persona. Es el papel de DHCP para los usuarios remotos |
| Sin subred de visitantes | **Visitantes 10.10.1.64/28** | El enunciado pide una subred de visitantes con Internet y sin acceso interno. Se asumen hasta 10 personas a la vez (sala de ventas o casa modelo), por eso /28 (14 hosts) |
| Web pública en la DMZ (diseño) | **Intranet en srv-render**, sin IP pública | La fase pide una web interna. La cuota de Azure for Students está en 6 de 6 vCPU y no cabe otra VM. La DMZ queda vacía y reservada para la web pública de la Fase 4 |
| Subredes temporales de departamentos dentro de la VNet | **Se borraron** | Los departamentos llegan por VPN. Si esas subredes se quedan, Azure envía las respuestas a una subred vacía en vez de a fw-vpn |

### Direccionamiento final

| Subred | Rango | Máscara | Equipos o IP del servidor VPN | IPs para usuarios | Puerto |
|---|---|---|---|---|---|
| DMZ | 10.0.0.0/28 | 255.255.255.240 | vacía (Fase 4) | — | — |
| Firewall | 10.0.0.16/28 | 255.255.255.240 | fw-vpn 10.0.0.20 | — | — |
| Servidores | 10.0.0.32/28 | 255.255.255.240 | srv-planos .36 · srv-render .37 | — | — |
| Arquitectos (VPN) | 10.10.1.0/27 | 255.255.255.224 | 10.10.1.1 | .2 – .30 (29) | UDP 1194 |
| Ingenieros (VPN) | 10.10.1.32/28 | 255.255.255.240 | 10.10.1.33 | .34 – .46 (13) | UDP 1195 |
| TI (VPN) | 10.10.1.48/29 | 255.255.255.248 | 10.10.1.49 | .50 – .54 (5) | UDP 1196 |
| Visitantes (VPN) | 10.10.1.64/28 | 255.255.255.240 | 10.10.1.65 | .66 – .78 (13) | UDP 1197 |

## 2. Cambios en Azure

**Rutas.** Se creó la tabla `rt-servidores`, asociada solo a la subred Servidores:

| Ruta | Destino | Siguiente salto |
|---|---|---|
| vpn-hacia-fw | 10.10.0.0/16 | Aplicación virtual 10.0.0.20 |
| internet-hacia-fw | 0.0.0.0/0 | Aplicación virtual 10.0.0.20 |

La primera ruta lleva las respuestas de los servidores hacia los usuarios de la VPN. La segunda hace que los servidores salgan a Internet por el NAT de fw-vpn: la subred Servidores no tiene salida por defecto, así que sin esta ruta no se podía instalar ningún paquete.

**NSG.**
- `nsg-firewall`:
  - Se abrió UDP 1194–1197 para las 4 VPN.
  - Se agregó `Allow-Salida-Servidores` para que fw-vpn pueda sacar a Internet el tráfico de los servidores.
  - Se agregó `Allow-VPN-Hacia-Red` (salida, 10.10.1.0/24 → 10.0.0.0/16, prioridad 100). Sin ella, Azure descartaba el tráfico de la VPN que fw-vpn reenviaba a los servidores.
- `nsg-servidores`: las reglas amplias de la Fase 2 se reemplazaron por reglas por grupo. Visitantes no aparece en ninguna regla de permiso:

| Prioridad | Nombre | Origen | Destino | Puerto |
|---|---|---|---|---|
| 100 | Allow-TI-Todo | 10.10.1.48/29 | cualquiera | cualquiera |
| 110 | Allow-SSH-Planos | 10.0.0.20, Arquitectos, Ingenieros | 10.0.0.36 | 22 |
| 120 | Allow-SSH-Render | 10.0.0.20, 10.0.0.36, Arquitectos | 10.0.0.37 | 22 |
| 130 | Allow-Web-Intranet | 10.0.0.0/16, Arquitectos, Ingenieros | 10.0.0.37 | 80 |
| 140 | Allow-LDAP | 10.0.0.16/28, 10.0.0.32/28 | 10.0.0.36 | 389, 636 |
| 150 | Allow-ICMP | 10.0.0.0/16, Arquitectos, Ingenieros | cualquiera | ICMP |
| 4000 | Deny-Resto | cualquiera | cualquiera | cualquiera |

- `nsg-dmz`: se borraron `Allow-HTTP` y `Allow-HTTPS` desde Internet, porque la DMZ queda vacía en esta fase.

Registro de los cambios: `fase-3/evidencia/01-azure-cambios.txt`.

## 3. Administración de la red

### 3.1 DHCP

Azure no permite poner un servidor DHCP propio dentro de una VNet: las VMs siempre reciben su IP del DHCP de la plataforma (168.63.129.16). Por eso el requisito se cumple en dos partes:

- **VMs:** DHCP de Azure con la IP privada reservada en la tarjeta de red. Ejemplo: srv-planos recibe `10.0.0.36/28` con puerta de enlace 10.0.0.33 y DNS 168.63.129.16.
- **Usuarios:** cada instancia de OpenVPN reparte IPs dinámicas de su pool (directiva `server`) y envía opciones al cliente: la ruta hacia `10.0.0.0/16`, `redirect-gateway def1` (todo el tráfico pasa por la VPN) y el DNS `1.1.1.1` con `dhcp-option`.

| Usuario | Grupo | IP entregada |
|---|---|---|
| ana.arq | Arquitectos | 10.10.1.2 |
| ivan.ing | Ingenieros | 10.10.1.34 |
| tomas.ti | TI | 10.10.1.50 |
| visita1 | Visitantes | 10.10.1.66 |

Evidencia: `fase-3/evidencia/12-dhcp.txt`.

### 3.2 NTP

- **Servidor:** fw-vpn con chrony. Se sincroniza con fuentes externas y atiende a `10.0.0.0/16` y `10.10.1.0/24` (`allow` en `chrony.conf`). El firewall solo deja entrar UDP 123 desde la red interna y los departamentos.
- **Clientes:** srv-planos y srv-render quitaron los `pool` por defecto y usan `server 10.0.0.20 iburst prefer`.

Resultado: los dos servidores muestran `^* fw-vpn` (fuente seleccionada) con estrato 2 y un desfase de microsegundos, y fw-vpn los lista en `chronyc clients`.

Evidencia: `fase-3/evidencia/05-ntp.txt`. Scripts: `config/ntp-servidor.sh` y `config/ntp-cliente.sh`.

### 3.3 LDAP

OpenLDAP (slapd) en srv-planos, con dominio `dc=terranova,dc=local`:

```
dc=terranova,dc=local
├── ou=usuarios  →  ana.arq (10001), ivan.ing (10002), tomas.ti (10003), visita1 (10004)
└── ou=grupos    →  arquitectos (20001), ingenieros (20002), ti (20003), visitantes (20004)
```

Los usuarios son `inetOrgPerson` + `posixAccount`, y los grupos son `posixGroup` con `memberUid`. LDAP se usa en dos lugares:

1. **Login de la VPN.** Cada instancia de OpenVPN llama a `ldap-auth.sh <grupo>` (`auth-user-pass-verify`). El script hace un bind con el usuario y la clave para comprobar la contraseña, y después revisa que el usuario sea miembro del grupo de esa instancia. Si alguna de las dos cosas falla, rechaza la conexión. El log de fw-vpn registra los dos casos:
   - `rechazado ana.arq (ti): no es del grupo`
   - `rechazado ana.arq (arquitectos): clave`
2. **SSH a los servidores.** SSSD en srv-planos y srv-render consulta a LDAP. `access_provider = simple` limita el acceso por grupo: srv-planos acepta arquitectos, ingenieros y ti; srv-render acepta arquitectos y ti. El home se crea en el primer login (`mkhomedir`).

El puerto 389 de srv-planos solo es alcanzable desde fw-vpn, srv-render y TI. Desde Arquitectos, Ingenieros y Visitantes está bloqueado.

Evidencia: `03-ldap.txt`, `07-vpn-ldap-auth.txt` y `08-sssd-ssh.txt`. Configuración: `config/ldap-auth.sh` y `config/setup-sssd.sh`.

## 4. Lógica del negocio: web interna

nginx en srv-render sirve la página "Intranet Terranova". Es de solo lectura y muestra la información según el grupo, que detecta por la IP de la VPN. Cómo se mantiene interna:

- nginx escucha solo en `10.0.0.37:80`, no en todas las interfaces.
- srv-render no tiene IP pública: desde Internet no hay dirección a la cual conectarse.
- El firewall de fw-vpn solo reenvía el puerto 80 a Arquitectos e Ingenieros (TI pasa por su regla general). El NSG y el firewall de srv-render repiten esa misma restricción.
- Visitantes queda bloqueado por la regla "visitantes-interno" de fw-vpn.

| Desde | `http://10.0.0.37` |
|---|---|
| Arquitectos, Ingenieros, TI | OK, muestra la intranet |
| Visitantes | Bloqueado |
| Internet (laptop sin VPN) | Sin acceso: render no tiene IP pública y el puerto 80 de fw-vpn está cerrado |

**Limitación:** por la cuota de 6 vCPU de Azure for Students, la intranet comparte VM con el servidor de render. Lo correcto es una VM propia en la subred Servidores, y así se hará en la Fase 4.

Evidencia: `04-nginx.txt`, `10-web-desde-internet.txt` y `11-pruebas-vpn.txt`. Configuración: `config/nginx-intranet.conf`, `config/intranet.html` y `config/setup-nginx.sh`.

## 5. Seguridad: firewall, ACL y NAT

El firewall es nftables en fw-vpn. Todo el tráfico entre los departamentos y los servidores, y hacia Internet, pasa por él. La configuración completa está en `config/fw-nftables.conf`. La cadena `forward` tiene política DROP y aplica estas reglas en orden:

| Regla | Implementación |
|---|---|
| Nadie inicia conexiones hacia TI | `ip daddr 10.10.1.48/29 ct state new drop` (va primero) |
| TI llega a todo | `ip saddr 10.10.1.48/29 accept` |
| Visitantes: Internet sí, nada interno | `drop` hacia 10.0.0.0/8, 172.16.0.0/12 y 192.168.0.0/16; `accept` hacia `eth0` |
| Arquitectos | SSH a srv-planos; SSH y web a srv-render |
| Ingenieros | SSH a srv-planos; solo la web de srv-render |
| Salida a Internet | Departamentos y servidores, solo hacia direcciones públicas |
| Todo lo demás | Bloqueado |

Las respuestas de las conexiones permitidas pasan por `ct state established,related`. Por eso TI recibe las respuestas de lo que inicia, pero nadie puede abrirle una conexión nueva. No se usa `client-to-client` en OpenVPN: con esa opción el tráfico entre usuarios no pasaría por nftables y la regla de TI no se cumpliría.

**NAT.** En la tabla `ip nat`, `masquerade` en `eth0` para 10.10.1.0/24 (VPN) y 10.0.0.32/28 (servidores) cuando el destino es público. Prueba: `curl ifconfig.me` desde srv-planos y desde Visitantes devuelve la IP pública de fw-vpn. `net.ipv4.ip_forward = 1` está activo desde la Fase 2.

**SSH de los usuarios.** Los usuarios de LDAP entran con su clave solo a los servidores de su grupo:

| Usuario | srv-planos | srv-render |
|---|---|---|
| ana.arq (arquitectos) | Entra | Entra |
| ivan.ing (ingenieros) | Entra | Rechazado |
| tomas.ti (ti) | Entra | Entra |
| visita1 (visitantes) | Rechazado | Rechazado |

### Resultados de la ACL desde la VPN

Pruebas desde una laptop real, conectada a un perfil por vez:

| Prueba | Arquitectos | Ingenieros | TI | Visitantes |
|---|---|---|---|---|
| Ping a srv-planos / srv-render | Sí / Sí | Sí / Sí | Sí / Sí | No / No |
| SSH a srv-planos | Abierto | Abierto | Abierto | Bloqueado |
| SSH a srv-render | Abierto | Bloqueado | Abierto | Bloqueado |
| LDAP 389 en srv-planos | Bloqueado | Bloqueado | Abierto | Bloqueado |
| Intranet | OK | OK | OK | Bloqueado |
| Internet | Sí (NAT) | Sí (NAT) | Sí (NAT) | Sí (NAT) |

- **Nadie hacia TI:** con la laptop de TI conectada (10.10.1.50), un ping y un intento TCP desde srv-planos fallaron. El contador de la regla `nadie-hacia-TI` subió de 0 a 8 paquetes.
- **Visitantes:** el contador de la regla `visitantes-interno` registró 14 paquetes bloqueados.

Evidencia: `02-nat-servidores.txt`, `08-sssd-ssh.txt` y `11-pruebas-vpn.txt`.

## 6. Hardening

| Medida | fw-vpn | srv-planos | srv-render |
|---|---|---|---|
| Firewall de entrada con política DROP | nftables | nftables | nftables |
| Puertos abiertos | 22 (admin y TI), 123/udp, 1194–1197/udp | 22, 389 | 22, 80 |
| Origen permitido | SSH: IP del admin y TI | SSH: fw-vpn, Arquitectos, Ingenieros y TI · LDAP: fw-vpn, srv-render y TI | SSH: fw-vpn, srv-planos, Arquitectos y TI · web: red interna, Arquitectos, Ingenieros y TI |
| SSH | Sin contraseña, solo llave. Root permitido con llave (`without-password`, valor de la imagen) | Sin root; contraseña solo para grupos de LDAP | Sin root; contraseña solo para grupos de LDAP |

- Los servicios escuchan solo donde hace falta. nginx escucha en 10.0.0.37 y no en 0.0.0.0; los servicios locales de chrony y del resolvedor quedan en 127.0.0.1.
- Un `nmap` de los 1000 puertos TCP más comunes, desde fw-vpn, solo encontró:
  - srv-planos: 22 y 389. El 636 aparece cerrado porque LDAPS no está configurado.
  - srv-render: 22 y 80.
- La cuenta `azureuser` no acepta contraseña: el intento con clave fue rechazado.
- Después de apagar y encender las VMs, todos los servicios y los firewalls arrancaron solos (`13-arranque.txt`).

Evidencia: `09-hardening.txt` y `13-arranque.txt`. Firewalls de los servidores: `config/planos-nftables.conf` y `config/render-nftables.conf`.

## 7. Problemas encontrados y cómo se resolvieron

| Problema | Causa | Solución |
|---|---|---|
| No se podía instalar nada en los servidores | La subred Servidores no tiene salida a Internet por defecto | Se configuró primero el NAT en fw-vpn y la ruta 0.0.0.0/0 hacia él |
| La VPN conectaba, pero no llegaba a los servidores | Con `tcpdump` se vio que el paquete salía de fw-vpn y no llegaba a srv-planos: lo descartaba el NSG de la subred Firewall | Regla de salida `Allow-VPN-Hacia-Red` en `nsg-firewall` |
| No cabe una VM para la intranet | Cuota de 6/6 vCPU en Azure for Students | Intranet temporal en srv-render, con nginx limitado a su IP privada |
| chrony no arrancaba en fw-vpn | Un comando enviado desde PowerShell dejó una línea mal citada en `chrony.conf` | Se restauró el archivo original y los cambios se aplicaron con scripts |
| Cortes intermitentes del SSH de administración | Probablemente el proveedor de Internet usa más de una IP de salida y solo una estaba permitida (no verificado) | Administrar por la VPN de TI, que no depende de la IP pública |

## 8. Deuda técnica conocida

- LDAP va sin cifrar (389). Como alternativa queda LDAPS (636) con un certificado propio.
- Las laptops del equipo usan un certificado de cliente compartido y no hay lista de revocación. La identidad de cada persona la da el login de LDAP.
- La llave de la CA de OpenVPN está en fw-vpn. Lo ideal es guardarla fuera del firewall.
- La intranet comparte VM con el render (sección 4).
- En fw-vpn, `PermitRootLogin` sigue en `without-password`: root puede entrar con llave. Hay que cambiarlo a `no`, como en los servidores.

## 9. Costos

Las 3 VMs son Standard_B2ats_v2 a 0.0094 USD por hora. Los discos E4 cuestan 2.40 USD al mes cada uno y la IP pública estática 0.005 USD por hora. Con unas 60 horas de uso al mes, el estimado es de **12.54 USD al mes**. Con las VMs apagadas (Stop con desasignación) quedan **10.85 USD al mes**, por los discos y la IP pública. Las VMs se encienden solo para trabajar, probar y presentar.

## 10. Archivos de configuración y documentación

En el repositorio (https://github.com/jcdiegolopez/RD-PR2), carpeta `fase-3/`:

- `config/`: nftables de las 3 VMs, OpenVPN, `ldap-auth.sh`, SSSD, nginx, intranet y NTP, tal como están desplegados.
- `evidencia/`: salida de las pruebas 01 a 13.
- `plan-fase3.md`: el plan con las decisiones de diseño.
- `diagrama-fase3.drawio`: el diagrama actualizado.
- `demo-fase3.md`: el guion de la demostración en vivo.
- `presentacion-fase3.pdf`: la presentación ejecutiva.

## Referencias

- Universidad del Valle de Guatemala (2026). Proyecto Final, Fase 3: Implementación de una Red en la nube. CC3067 Redes, Sección 30.
- Microsoft (2026). Azure Virtual Network FAQ: "Can I deploy a DHCP server in a virtual network?". https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-faq
- Microsoft (2026). Virtual network traffic routing (rutas definidas por el usuario). https://learn.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview
- Microsoft (2026). Network security groups. https://learn.microsoft.com/en-us/azure/virtual-network/network-security-groups-overview
- OpenVPN Inc. Reference manual for OpenVPN 2.6. https://openvpn.net/community-resources/reference-manual-for-openvpn-2-6/
- nftables wiki. https://wiki.nftables.org
- OpenLDAP Foundation. OpenLDAP Software 2.6 Administrator's Guide. https://www.openldap.org/doc/admin26/
- SSSD documentation. https://sssd.io/docs/
- chrony documentation. https://chrony-project.org/documentation.html
- nginx documentation. https://nginx.org/en/docs/
