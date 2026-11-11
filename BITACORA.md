# Bitácora del proyecto · Terranova (CC3067 Redes, Sección 30)

Registro cronológico del proyecto final: qué se hizo, qué se decidió, qué falló y cómo se resolvió.
Las fechas salen de los documentos, de los commits del repo y de la evidencia guardada.

Equipo: Jose Pablo · Joel Jaquez · Diego López · Erick Guerra · Diego Rosales · Fabian Morales.

---

## Fase 1 · Diseño de la red

**21 ago 2026 · Entrega del diseño** (documento y presentación "Terranova").

- Caso 4: desarrolladora de bienes raíces con 2 edificios de apartamentos y un condominio en desarrollo.
- Toda la red en **Microsoft Azure for Students** ($100 de crédito por 12 meses, sin tarjeta).
- **6 subredes:** 3 en Azure (DMZ, Firewall y Servidores, cada una /28) y 3 de usuarios por VPN (Arquitectos /27, Ingenieros /28, TI /29).
- **Firewall propio** (fw-vpn, Ubuntu con nftables) en lugar de OPNsense, porque el crédito de estudiante no cubre el Marketplace.
- Servicios previstos: OpenVPN, NAT, BIND9, chrony, OpenLDAP, Samba, Blender, Nginx con Certbot, Azure DNS y Blob Storage.
- Plan: 4 VMs B1s en Sweden Central. Costo estimado: **$20.10 al mes**.

**1–2 oct 2026 · Diagrama de red** en draw.io (Google Drive, "Diagrama bienes racies").

---

## Fase 2 · Implementación de la red

**15 oct 2026 · Red y VMs creadas en Azure, pruebas de conectividad.**

| Se planeó | Pasó | Se decidió |
|---|---|---|
| Región Sweden Central | No está permitida por la política de la suscripción | North Central US |
| VMs B1s | Tamaño no disponible para estudiantes | Standard_B2ats_v2 (2 vCPU, 1 GiB) |
| 4 VMs | Cuota de 6 vCPU | 3 VMs (fw-vpn, srv-planos, srv-render); la web se pospone |
| Ubuntu 24.04 | srv-planos y srv-render quedaron con 22.04 | Se documenta; no afecta la red |

- **Pruebas:** SSH a fw-vpn, salto a srv-planos y srv-render, ping en ambos sentidos con 0% de pérdida y ping desde fw-vpn a los servidores. Evidencia: `fase-2/evidencia/01–04`.
- **Auditoría de Azure contra el diseño** (`fase-2/evidencia/auditoria-azure.md`). Correcciones aplicadas:
  - IP privada de fw-vpn: de dinámica a **estática** (10.0.0.20).
  - SSH al firewall abierto a Internet: se limitó a la IP del administrador.
  - Se borraron las reglas temporales `Allow-SSH-Temporal` y `ssh-temporal`.
- `net.ipv4.ip_forward = 1` en fw-vpn, persistente (`fase-2/evidencia/05`).
- **Subredes de departamentos en Azure:** se agregó el espacio 10.10.1.0/26 a `vnet-proyecto`, con Arquitectos, Ingenieros y TI, para mostrar el subnetting. Se sabía que había que borrarlas antes de la VPN, porque su ruta local le gana a la ruta de la VPN (`fase-2/evidencia/08`).
- Configuración de los NSG exportada y diseño inicial de OpenVPN (una sola instancia con IP fija por usuario), en `fase-2/config/`.
- Presentación, guion y guía de la demo en `fase-2/`.

**23 oct 2026 · Entrega de la Fase 2.**

---

## Fase 3 · Servicios y seguridad

**27 oct 2026 · Análisis de lo que existía en Azure y lo que faltaba.** Hallazgos clave:
- La cuota de vCPU está en 6 de 6: no cabe otra VM.
- La subred Servidores no tiene salida a Internet por defecto.

**Decisiones de diseño:**

| Decisión | Por qué |
|---|---|
| **4 instancias de OpenVPN**, una por grupo, con IPs dinámicas (UDP 1194–1197) | Cada usuario recibe una IP de su departamento sin un archivo por persona. Reemplaza el diseño de una sola instancia de la Fase 2 |
| **Visitantes** 10.10.1.64/28 | El enunciado lo pide: solo Internet, nada interno |
| **Intranet en srv-render** (temporal) | No hay cuota para una VM web. En la Fase 4 va en su propia VM |
| **DHCP:** Azure para las VMs + pools de OpenVPN para las laptops | Azure no permite un servidor DHCP propio en la VNet |
| **LDAP en srv-planos** (OpenLDAP) | Login de la VPN y SSH de los servidores (SSSD) por grupo |

**28 oct 2026 · Implementación** (en este orden):
1. Azure: se borraron las subredes temporales de departamentos y se ajustaron los 3 NSG.
2. nftables y NAT en fw-vpn.
3. Tabla de rutas `rt-servidores` (10.10.0.0/16 y 0.0.0.0/0 hacia 10.0.0.20). Con esto los servidores salieron a Internet.
4. OpenLDAP en srv-planos: 4 usuarios y 4 grupos.
5. Intranet con nginx en srv-render (solo en 10.0.0.37:80).
6. NTP: fw-vpn como servidor; los servidores sincronizados con él.
7. 4 instancias de OpenVPN con login de LDAP por grupo.
8. SSSD, sshd endurecido y firewall en cada servidor.
9. Pruebas grupo por grupo desde una laptop real.

**Problemas y soluciones:**

| Problema | Causa | Solución |
|---|---|---|
| No se podía instalar nada en los servidores | La subred Servidores no tiene salida por defecto | Hacer el NAT y la ruta 0.0.0.0/0 antes de instalar |
| La VPN conectaba pero no llegaba a nada | `tcpdump`: el paquete salía de fw-vpn y nunca llegaba a srv-planos. Lo botaba Azure | Regla de salida `Allow-VPN-Hacia-Red` en `nsg-firewall` |
| SSH a fw-vpn con timeouts intermitentes | Probable: el proveedor de Internet usa más de una IP de salida y solo una estaba permitida (no verificado) | Administrar por la VPN de TI, que no depende de la IP |
| chrony no arrancaba en fw-vpn | Un comando mal citado desde PowerShell dejó una línea inválida | Restaurar el archivo original y aplicar con un script |

**28 oct 2026 · Rediseño de la intranet** (commits de r0sv): detección del grupo por la IP de la VPN, `intranet-DESIGN.md` e `intranet-PRODUCT.md`.

**29 oct 2026 · Verificación y presentación.**
- Después de apagar y encender las VMs, todos los servicios arrancaron solos (`fase-3/evidencia/13-arranque.txt`).
- Guía de la demo con el guion: `fase-3/demo-fase3.md`.

**Resultado de las pruebas** (`fase-3/evidencia/`):

| Requisito | Resultado |
|---|---|
| DHCP | VMs por Azure; laptops con IP dinámica de su pool (.2, .34, .50, .66) |
| NTP | srv-planos y srv-render con `^* fw-vpn` |
| LDAP | Login de VPN y SSH aceptados o rechazados según el grupo |
| Web interna | Arquitectos, Ingenieros, TI y servidores sí; Visitantes e Internet no |
| TI llega a todo, nadie llega a TI | Contador de la regla "nadie-hacia-TI" de 0 a 8 paquetes |
| Visitantes | Sale a Internet con la IP de fw-vpn; nada interno |
| NAT | Servidores y VPN salen con la IP pública de fw-vpn |
| Hardening | Firewall con política DROP, SSH sin root ni clave para el administrador, solo los puertos del plan |

**Deuda técnica conocida:**
- LDAP sin cifrar (389, no LDAPS).
- Un solo certificado de cliente compartido; sin lista de revocación.
- La llave de la CA vive en fw-vpn.
- La intranet comparte VM con el render.

---

## Fase 4 · Parte pública, DMZ y monitoreo

**10 nov 2026 · Planificación.** Plan final en `fase-4/plan-fase4.md` y diagrama en `fase-4/diagrama-fase4.drawio`. Entrega: 13 nov.

Hallazgos al revisar el documento del proyecto (caso 4):
- El caso pide las dos máquinas (planos y render) y que Ingenieros solo entre a planos, así que srv-render no se puede borrar.
- El caso pide una **zona interna de DNS**, que no se había hecho.
- La intranet viene del enunciado de la Fase 3, no del caso 4. Se mantiene.

**Decisiones:**

| Decisión | Por qué | Alternativas descartadas |
|---|---|---|
| Convertir la suscripción de Joel a **pago por uso** (la misma suscripción) y pedir cuota de 8 vCPU | Azure for Students no permite subir la cuota; convertirla no obliga a reconstruir nada | Borrar srv-render (rompe el caso 4), otra región con peering, ACI, cuenta nueva |
| **srv-web en la DMZ, detrás de fw-vpn con DNAT** (sin IP pública) | Todo el tráfico público pasa por el firewall; una sola entrada; una IP menos | IP pública propia, como en la Fase 1 (queda como plan B) |
| **BIND9 en fw-vpn** para `terranova.local` | Una sola pieza, gratis, sirve directo a la VPN | Azure Private DNS (no responde a la VPN sin un reenviador) |
| SNMPv3 + Prometheus + Grafana (solo TI) | Lo pide la Fase 4; Grafana es el 10% extra | SNMP v2c (comunidad en texto plano) |
| srv-planos y srv-render a **B2als_v2** (4 GiB) | Con 1 GiB no caben Grafana ni Blender; misma cuota de vCPU | — |
| Planos por **SFTP** con permisos por grupo | Cumple "almacenar planos" sin otro servicio | Samba |
| Fuera de alcance: **Samba, Blob Storage, LDAPS** | No los pide ni la fase ni el caso | — |

Estado al 10 nov: la suscripción todavía figura como Azure for Students y la cuota sigue en 6/6.

---

## 10 nov 2026 · Reorganización del repo como bitácora

El repo se ordenó por fase (`fase-1/` a `fase-4/`) y se agregó esta bitácora.
