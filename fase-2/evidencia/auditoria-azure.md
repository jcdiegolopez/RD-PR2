# Auditoría Azure (solo lectura) · Fase 2 CC3067

Fecha: 2026-10-15 · Suscripción: Azure for Students (`<SUBSCRIPTION-ID>`) · Grupo de recursos: `rg-redes-proyecto` (metadatos del grupo en swedencentral, pero todos los recursos están en northcentralus) · Salida cruda: `auditoria-raw.txt`

## 1. Checklist contra la Fase 1

| # | Punto | Resultado | Detalle |
|---|---|---|---|
| 1 | VNet | OK | `vnet-proyecto` 10.0.0.0/16 en northcentralus |
| 2 | Subredes | OK | DMZ 10.0.0.0/28, Firewall 10.0.0.16/28, Servidores 10.0.0.32/28 |
| 3 | fw-vpn | DIFERENTE | Subred Firewall, 10.0.0.20, IP pública `fw-vpn-ip` (Standard) e IP forwarding = True. Pero la IP privada es **Dynamic**, no Static |
| 4 | srv-planos | OK | Servidores, 10.0.0.36, Static, sin IP pública |
| 5 | srv-render | OK | Servidores, 10.0.0.37, Static, sin IP pública |
| 6 | web | FALTA | No existe la VM (esperado por cuota) ni `pip-web` |
| 7 | IPs públicas sobrantes | OK | Solo existe `fw-vpn-ip`. srv-planos no tiene IP pública |
| 8 | UDR Servidores | FALTA | No existe ninguna route table en el grupo |
| 9 | UDR DMZ | FALTA | Igual que el punto 8 |
| 10 | Subred Firewall sin route table | OK | No tiene (porque no hay ninguna) |
| 11 | NSG DMZ | OK | Tcp 443 y 80 desde Internet |
| 12 | NSG Firewall | OK | Udp 1194 desde Internet |
| 13 | NSG Servidores (+ ASG) | DIFERENTE | SMB 445 desde 10.10.1.0/27, .32/28, .48/29 (VPN); SSH 22 e ICMP desde 10.0.0.0/16 y 10.10.0.0/16; LDAP 389/636 desde Firewall **y** Servidores; Deny-Resto 4000. No hay ASG (se usan rangos IP, lo que es válido; los ASG eran opcionales) |
| 14 | Reglas temporales | FALTA LIMPIAR | `ssh-temporal` en nsg-servidores (prio 105, TCP 22 desde <IP-TEMPORAL-ANTERIOR>, no es tu IP actual <IP-ADMIN>). `Allow-SSH-Temporal` en nsg-dmz (prio 125, TCP 22 desde **Internet**). `Allow-SSH-Admin` en nsg-firewall deja el 22 abierto a **Internet** |
| 15 | Estado/apagado | Pendiente | Las 3 VMs están `VM running` |

## 2. No se pudo revisar

Nada falló por permisos. No revisé `effective-route-table` ni `effective-nsg` (son por NIC y no hacían falta para el checklist). Tampoco revisé costos.

## 3. Qué debe hacer Diego a mano (de más a menos importante)

1. **Crear la route table** `rt-proyecto` con las rutas de la Fase 1 y asociarla a Servidores y DMZ (nunca a Firewall). Hoy no existe y es lo que más falta para la entrega.
2. **Cerrar SSH a Internet:** en nsg-firewall cambiar el origen de `Allow-SSH-Admin` a tu IP pública /32, y borrar `Allow-SSH-Temporal` de nsg-dmz. Hoy cualquiera en Internet puede intentar SSH a fw-vpn.
3. **Borrar `ssh-temporal`** de nsg-servidores al terminar (su origen <IP-TEMPORAL-ANTERIOR> ya no es tu IP).
4. **Fijar la IP de fw-vpn como Static** (NIC `fw-vpn434`, IP configurations, ipconfig1), para que 10.0.0.20, que usa la ruta, no cambie.
5. **Activar `net.ipv4.ip_forward=1` dentro de fw-vpn** (la parte de Azure ya está; falta la de Linux).
6. Opcional: crear la VM `web` si la cuota lo permite; ajustar LDAP para que solo venga de fw-vpn (10.0.0.20/32).
7. **Al terminar: Stop (deallocated)** en las 3 VMs.

## 4. Datos para el informe

| Recurso | Nombre | Detalle |
|---|---|---|
| VM | fw-vpn | Standard_B2ats_v2, Ubuntu 24.04 LTS, 10.0.0.20, IP pública fw-vpn-ip, NIC fw-vpn434 (forwarding True), running |
| VM | srv-planos | Standard_B2ats_v2, Ubuntu 22.04 LTS Gen2, 10.0.0.36 Static, NIC srv-planosVMNic, running |
| VM | srv-render | Standard_B2ats_v2, Ubuntu 22.04 LTS Gen2, 10.0.0.37 Static, NIC srv-renderVMNic, running |
| NSG | nsg-dmz, nsg-firewall, nsg-servidores | Cada uno asociado a su subred |
| Discos | fw-vpn_disk1_…, srv-render_OsDisk_1_…, srv-planos_OsDisk_1_… | Siguen cobrando aunque las VMs estén apagadas |

Nota: srv-planos y srv-render usan Ubuntu **22.04**, no 24.04 como decía la guía. Hay que reportarlo así en el informe.


---

## Re-auditoría tras los cambios (2026-10-15)

Alcance: Fase 2. Las route tables (UDR) no se evalúan, son de la Fase 3. Salida cruda en `auditoria-raw-2.txt`.

| Punto | Antes | Ahora |
|---|---|---|
| IP de fw-vpn (NIC fw-vpn434) | Dynamic | OK, Static 10.0.0.20 |
| SSH a nsg-firewall (`Allow-SSH-Admin`) | Origen Internet | OK, solo <IP-ADMIN>/32 |
| `Allow-SSH-Temporal` (nsg-dmz) | Existía | OK, borrada |
| `ssh-temporal` (nsg-servidores) | Existía | OK, borrada |
| IP forwarding en la NIC de fw-vpn | True | OK, True |
| `ip_forward` dentro de fw-vpn | 0 | OK, 1 |
| IPs públicas | Solo fw-vpn-ip | OK, igual |
| VMs | 3 en Running | Siguen en Running, hay que apagarlas al terminar |

Sigue igual: no existe la VM `web` (cuota), ni ASG, ni route tables (Fase 3).
