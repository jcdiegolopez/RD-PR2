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

**28 oct 2026 · Rediseño de la intranet** (commits de r0sv): detección del grupo por la IP de la VPN, `intranet-DESIGN.md` e `intranet-PRODUCT.md`. *Pendiente confirmar si esa versión está desplegada en srv-render.*

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

## Fase 4 · Pendiente

- Pasar a una **suscripción de pago** para tener todas las máquinas y reconstruir la red completa.
- Separar la web pública (DMZ) y la intranet en sus propias VMs.
- Servicios pendientes del diseño: Samba, Blender, BIND9, Azure DNS, Blob Storage, web pública con HTTPS.
- Al reconstruir: **llaves, certificados y contraseñas nuevas**; las de este repo quedan obsoletas.

---

## 10 nov 2026 · Reorganización del repo como bitácora

El repo se ordenó por fase (`fase-1/` a `fase-4/`) y se agregó esta bitácora.
