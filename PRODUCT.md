# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static HTML/CSS, self-contained: one `index.html` with inline SVG and minimal JS, plus the Archivo variable font self-hosted beside it (`archivo.woff2`, with `archivo-OFL.txt`). No CDNs or external requests. Served by nginx on srv-render (`/var/www/intranet`, `listen 10.0.0.37:80`) with SSI for the visitor group. Small nginx changes on srv-render are allowed when a feature needs them.

## Users

Employees of Terranova, a fictional real-estate developer (Proyecto Final CC3067, Caso 4), who reach the intranet only through the company VPN:

- Arquitectos (15): design and render the projects.
- Ingenieros (10): review plans for construction.
- TI (3): administer and support the network.

Secondary audience: the course instructor during the live demo, who watches the same page opened from different VPN profiles.

## Product Purpose

Internal home page of the company network. An employee opens `http://10.0.0.37` after connecting to their group's VPN and should be able to:

1. See the projects in development and how far along each one is.
2. Know which group the network recognized them as and what they can reach (derived from their VPN IP).
3. Read internal notices and know how to get help from TI.

Success: in the demo, the page visibly changes by VPN profile and proves the network's ACL is real, while still reading as a believable company intranet.

## Positioning

The page is the visible face of the Phase 3 network: it can show the visitor's real VPN address and group because traffic from the VPN reaches srv-render without internal NAT. Only that network can truthfully do this.

## Operating Context

- VPN groups and address ranges: Arquitectos 10.10.1.0/27 (UDP 1194), Ingenieros 10.10.1.32/28 (1195), TI 10.10.1.48/29 (1196), Visitantes 10.10.1.64/28 (1197). Internal network 10.0.0.0/16.
- Who reaches the intranet (port 80 on srv-render): Arquitectos, Ingenieros, TI and the internal network. Visitantes are blocked by fw-vpn, the NSG and srv-render's firewall, so they never see the page.
- Access per group (ACL): Arquitectos SSH to srv-planos and srv-render; Ingenieros SSH to srv-planos only; TI reaches everything and nobody can start a connection toward TI; all groups exit to the Internet through fw-vpn NAT.
- Servers: fw-vpn 10.0.0.20 (VPN, firewall, NAT, NTP), srv-planos 10.0.0.36 (OpenLDAP, plans), srv-render 10.0.0.37 (intranet, render). SSH uses LDAP users (SSSD).
- LDAP sample users: ana.arq (arquitectos), ivan.ing (ingenieros), tomas.ti (ti), visita1 (visitantes).
- Presented live in class; a fallback is the saved evidence in `evidencia-fase3/`.

## Capabilities and Constraints

- No public exposure: srv-render has no public IP; the page must not depend on Internet access.
- The client IP (`$remote_addr`) is the real VPN address, so group detection can be done server-side by nginx.
- Content may be fictional but must stay consistent with the repo (project names, users, IPs, servers, ACL).
- Not in scope: Samba, Blender, public web in the DMZ (no vCPU quota), LDAP login on the page itself.

## Brand Commitments

- Company name: Terranova. Page title so far: "Intranet Terranova".
- Projects already named: Torre Norte (apartments, plans in review), Torre Sur (apartments, renders ready), Condominio Las Lomas (houses, obra gris).
- Language: Spanish (Guatemala).

## Evidence on Hand

- Current page: `config-fase3/intranet.html`; nginx site: `config-fase3/nginx-intranet.conf`.
- Network facts: `config-fase3/*.conf`, `evidencia-fase3/`, `Diagrama bienes raices - Fase 3.drawio`.
- No real logo, photos or renders exist. Do not present invented content as real company data beyond the fictional case.

## Product Principles

1. The network is the feature: what the page shows about access must match the real ACL exactly.
2. Useful before decorative: an employee finds project status, their access and TI contact in seconds.
3. Self-contained and robust: works with nothing but the VPN and nginx.
4. Demo-legible: differences between groups are obvious at a glance from across a classroom.
