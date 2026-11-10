# RD-PR2 · Terranova

Proyecto final de Redes (CC3067, Sección 30, UVG): la red de una desarrolladora de bienes raíces en Microsoft Azure.

> **Repositorio privado.** Contiene credenciales de prueba, perfiles de VPN y llaves. No hacerlo público. En la Fase 4 se reconstruye todo con llaves y contraseñas nuevas.

La historia completa, con decisiones y problemas, está en **[BITACORA.md](BITACORA.md)**.

## Estructura

| Carpeta | Contenido |
|---|---|
| [`fase-1/`](fase-1/) | Diseño de la red |
| [`fase-2/`](fase-2/) | Implementación de la red en Azure: configuración de NSG, evidencia de conectividad, auditoría, presentación |
| [`fase-3/`](fase-3/) | Servicios y seguridad: plan, configuraciones, evidencia, diagrama, demo, credenciales |
| [`fase-4/`](fase-4/) | Pendiente |

## Lo que hay en cada fase

### Fase 1
- Diagrama original: Google Drive, "Diagrama bienes racies".
- **Falta agregar:** enunciado (PDF), documento de diseño (PDF) y presentación (PDF).

### Fase 2
- `config/nsg/`: script con el que se crearon los NSG y sus reglas exportadas.
- `config/openvpn/`: diseño inicial de la VPN (una sola instancia). **Reemplazado en la Fase 3.**
- `evidencia/`: pruebas de conectividad, auditoría de Azure y capturas del portal.
- `guion-presentacion-fase2.md` y `demo-en-vivo-fase2.md`.
- Presentación (artifact): https://claude.ai/artifact/Y1rqBdre5vYgRvYrA3H2cx
- **Falta agregar:** enunciado (PDF) y reporte.

### Fase 3
- `plan-fase3.md`: el plan completo, con las decisiones.
- `config/`: nftables, OpenVPN, LDAP, SSSD, nginx y NTP tal como están desplegados.
- `evidencia/`: 13 archivos de pruebas (01 a 13).
- `diagrama-fase3.drawio`: diagrama de la fase (el `-borrador` es la primera versión).
- `demo-fase3.md` y `demo-ssh-config`: guion y comandos de la demo.
- `credenciales-fase3.txt`: usuarios de LDAP de prueba y sus contraseñas.
- `intranet-DESIGN.md` y `intranet-PRODUCT.md`: diseño de la intranet.
- Guía de estudio (artifact): https://claude.ai/artifact/T8pgkrySdJ7qTGuD2vdXqi
- **Falta agregar:** enunciado (PDF), reporte, presentación, capturas de los servicios, perfiles `.ovpn` y llaves SSH (ver abajo).

## Agregar los perfiles de VPN y las llaves

No se copiaron automáticamente. Desde la carpeta `RD-PR2`:

```powershell
New-Item -ItemType Directory -Force fase-3\vpn-perfiles, fase-3\llaves
Copy-Item "$HOME\fase3-vpn-perfiles\*.ovpn" fase-3\vpn-perfiles\
Copy-Item C:\Windows\System32\redes_key, C:\Windows\System32\redes_key.pub fase-3\llaves\
Copy-Item "$HOME\.ssh\llave_compa" fase-3\llaves\
```

## Datos de la red

| Subred | Rango | Equipos |
|---|---|---|
| DMZ | 10.0.0.0/28 | vacía (fase 4: web) |
| Firewall | 10.0.0.16/28 | fw-vpn 10.0.0.20 |
| Servidores | 10.0.0.32/28 | srv-planos 10.0.0.36 · srv-render 10.0.0.37 |
| Arquitectos (VPN) | 10.10.1.0/27 | UDP 1194 |
| Ingenieros (VPN) | 10.10.1.32/28 | UDP 1195 |
| TI (VPN) | 10.10.1.48/29 | UDP 1196 |
| Visitantes (VPN) | 10.10.1.64/28 | UDP 1197 |
