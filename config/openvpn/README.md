# OpenVPN en fw-vpn: diseño documentado

Estado: **documentado para la Fase 3**. En la Fase 2 no se instaló. La subred Firewall ya tiene abierto UDP 1194 en `nsg-firewall`, así que el puerto está listo.

## Datos

| Dato | Valor |
| --- | --- |
| Servidor | fw-vpn, IP privada 10.0.0.20, IP pública <IP-PUBLICA-FW-VPN> |
| Protocolo y puerto | UDP 1194 |
| Pool de la VPN | 10.10.0.0/23 (servidor 10.10.0.1) |
| Ruta enviada a los clientes | 10.0.0.0/16 por el túnel |
| Autenticación | Certificado por usuario (easy-rsa) + `tls-crypt`. En la Fase 3 se suma LDAP |

## IP fija por departamento

Cada usuario tiene un archivo en `ccd/` con su IP. Con `ccd-exclusive`, quien no tenga archivo no puede conectarse. Como la IP dice a qué departamento pertenece cada persona, el firewall (nftables, Fase 3) puede aplicar la ACL del caso.

| Departamento | Rango | Usuarios de ejemplo |
| --- | --- | --- |
| Arquitectos (15) | 10.10.1.0/27 (.1 a .30) | arq01 → 10.10.1.1 |
| Ingenieros (10) | 10.10.1.32/28 (.33 a .46) | ing01 → 10.10.1.33 |
| TI (3) | 10.10.1.48/29 (.49 a .54) | ti01 → 10.10.1.49 |

## Flujo de un paquete

Laptop (10.10.1.1) → túnel UDP 1194 → fw-vpn (10.0.0.20) → reenvío de IP → srv-planos (10.0.0.36).
La respuesta vuelve por la tabla de rutas `rt-proyecto` (10.10.0.0/16 → 10.0.0.20). Sin esa ruta, el servidor no sabría devolver el tráfico a la VPN.

## Pendiente para la Fase 3: choque con las subredes de departamentos

En la Fase 2 se agregó 10.10.1.0/26 al espacio de la VNet y se crearon las subredes Arquitectos, Ingenieros y TI dentro de Azure (`evidencia/08-subredes-departamentos.txt`). Esos rangos son los mismos que este diseño asigna a los usuarios de la VPN. Antes de instalar OpenVPN hay que elegir una de dos opciones:

1. Quitar 10.10.1.0/26 de la VNet y dejar esos rangos solo para la VPN, como en este diseño.
2. Mantener las subredes en Azure y mover la VPN a otro bloque (por ejemplo 10.20.0.0/23), cambiando `server.conf`, `ccd/` y las reglas de NSG que usan 10.10.x.x.

Si los dos usan el mismo rango, Azure entrega el tráfico hacia 10.10.1.x a la subred de la VNet y no a fw-vpn, y las respuestas nunca llegan al túnel.

## Requisitos en Azure (ya cubiertos o pendientes)

- `nsg-firewall` permite UDP 1194 desde Internet ✅
- Reenvío de IP activado en la NIC de fw-vpn y `net.ipv4.ip_forward=1` en Ubuntu (Diego López)
- Tabla de rutas `rt-proyecto` asociada a DMZ y Servidores (Diego López)

## Instalación (Fase 3)

```bash
sudo apt update && sudo apt install -y openvpn easy-rsa
make-cadir ~/easy-rsa && cd ~/easy-rsa
./easyrsa init-pki
./easyrsa --batch --req-cn="CA-Proyecto-Redes" build-ca nopass
./easyrsa --batch build-server-full server nopass
sudo cp pki/ca.crt pki/issued/server.crt pki/private/server.key /etc/openvpn/server/
sudo openvpn --genkey secret /etc/openvpn/server/tc.key
sudo mkdir -p /etc/openvpn/server/ccd
# copiar server.conf a /etc/openvpn/server/ y client-base.conf + nuevo-cliente.sh a ~/
sudo systemctl enable --now openvpn-server@server
~/nuevo-cliente.sh arq01 10.10.1.1
~/nuevo-cliente.sh ing01 10.10.1.33
~/nuevo-cliente.sh ti01  10.10.1.49
```

Las llaves privadas (`ca.key`, `server.key`, `tc.key`) y los `.ovpn` no se suben al repositorio.

## Archivos de esta carpeta

- `server.conf`: configuración del servidor
- `client-base.conf`: plantilla del cliente
- `nuevo-cliente.sh`: crea un usuario con su IP fija y su `.ovpn`
- `ccd/arq01`, `ccd/ing01`, `ccd/ti01`: IP fija de cada usuario de ejemplo
