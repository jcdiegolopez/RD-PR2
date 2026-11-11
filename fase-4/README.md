# Fase 4 · Red y servicios públicos

Entrega: 13 de noviembre. Enunciado: `enunciado-fase4.pdf`.

- **Plan final:** [`plan-fase4.md`](plan-fase4.md). Estado de partida, avance, qué hay que cumplir (enunciado, caso 4 y pedidos del profesor), orden de trabajo, reparto, calendario, configuraciones, pruebas, costos y riesgos.
- **Diagrama:** [`diagrama-fase4.drawio`](diagrama-fase4.drawio). Se abre con la extensión Draw.io Integration de VS Code o en app.diagrams.net.

## Dónde está

| Qué | Dato |
|---|---|
| Suscripción | `terranova-fase4` (pago por uso), presupuesto con alertas de $20/mes |
| IP pública de fw-vpn | 52.159.123.60 (VPN UDP 1194–1197 y web pública por DNAT) |
| Página pública | http://52.159.123.60 (HTTPS cuando haya dominio). Las VMs están apagadas: encender fw-vpn y srv-web para verla |
| Pendientes | Sección 0 de `plan-fase4.md` |
| Acceso SSH | `ssh -F fase-4/ssh-config fw` · `planos` · `render` · `web` (llave `~/.ssh/terranova`) |
| Credenciales | `credenciales-fase4.txt` (LDAP, SNMP, Grafana) |
| Perfiles de VPN | `vpn-perfiles/` (uno por grupo; usuario y clave de LDAP) |

## Carpetas

| Carpeta | Contenido |
|---|---|
| `infra/` | Scripts que crean y configuran todo: `01-azure.sh` (red y VMs), `setup-fw-base.sh`, `setup-ldap.sh`, `setup-planos-base.sh`, `setup-render-base.sh`, `setup-openvpn.sh`, `setup-web-base.sh`, `setup-snmp.sh`, `setup-monitoreo.sh`, `setup-planos-archivos.sh`, `setup-render-blender.sh`, `render-casa.py`, y `ldap-referencia.ldif` (el directorio de la Fase 3) |
| `config/` | Firewalls de las 4 VMs, zona DNS `db.terranova.local`, sitio nginx de la página y tablero de Grafana |
| `web/` | Página pública (HTML, fuente Archivo y el render del condominio) |
| `evidencia/` | Salida de cada paso y de cada prueba, del 01 al 14 |

## Decisiones

- Se reconstruyó todo en una suscripción nueva de pago por uso, porque la de estudiante no se podía convertir desde el portal.
- La web pública entra por fw-vpn con DNAT y srv-web no tiene IP pública. Es un cambio respecto de la Fase 1; el plan B, darle IP propia, está en el plan.
- Se mantienen srv-planos y srv-render, porque el caso 4 pide las dos máquinas y que Ingenieros solo entre a planos.
- Se agregó la zona interna de DNS (BIND9), que pide el caso 4 y no se había hecho.
- Samba y Blob Storage quedan fuera: no los pide ni la fase ni el caso.
