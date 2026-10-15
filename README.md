# RD-PR2

Proyecto final de Redes (CC3067, UVG), Fase 2: implementación del prototipo en Azure para una desarrolladora de bienes raíces.

Contenido de `evidencia/`:

- `01` a `04`: pruebas de conectividad (SSH, ping entre srv-planos y srv-render, ping desde fw-vpn).
- `05`: activación de `net.ipv4.ip_forward` en fw-vpn.
- `06`: software y servicios instalados en las 3 VMs.
- `07`: cambios hechos en Azure (IP estática de fw-vpn, SSH restringido, reglas temporales borradas).
- `auditoria-azure.md`: auditoría contra el diseño de la Fase 1 y re-auditoría.
- `auditoria-raw*.txt`: salida cruda de la auditoría.
- `capturas/`: capturas del portal de los NSG y de las subredes.

Contenido de `config/`:

- `nsg/`: script con el que se crearon los 3 NSG (`crear-nsg.sh`) y sus reglas exportadas (`nsg-*.json`).
- `openvpn/`: diseño de la VPN documentado para la Fase 3 (`README.md`, `server.conf`, plantilla de cliente, script de usuarios e IP fija por departamento en `ccd/`).

Las IP públicas, la IP del administrador y el ID de la suscripción aparecen como `<IP-PUBLICA-FW-VPN>`, `<IP-ADMIN>` y `<SUBSCRIPTION-ID>`.
