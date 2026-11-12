# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack

Static HTML/CSS, no build step, no backend. Decided by infrastructure constraint: the page ships from `fase-4/web/` and is served by nginx on `srv-web`, a VM in the DMZ subnet with no outbound access to internal servers (Fase 4 of a Redes/Networking course project). Any form on the page is visual only; nothing can submit to a backend.

## Users

Prospective buyers browsing Terranova's current real-estate projects from the open internet (no VPN, no login) — on mobile data as much as desktop — deciding whether to book a sales visit or leave contact info.

## Product Purpose

Terranova is a (fictional, academic) real-estate developer. The public page exists to show its three active projects and their construction progress, build trust, and move a visitor to book a visit or contact sales. Success = a visitor understands the three projects and takes the contact/visit step.

## Positioning

Not a generic agency listing page — a developer's own site for its own named, in-progress projects, each with real construction-stage proof (% avance, delivery estimate), not a marketplace of third-party listings.

## Operating Context

Part of a 4-phase university Networking course project (CC3067, UVG). This page is "Fase 4 · Persona 1" deliverable: public web server in a DMZ, reached only through the firewall's DNAT (no direct public IP on the web VM). Delivery deadline: 13 nov 2026. A real domain is not yet decided; the page currently ships under the "Terranova" name with no bound domain.

## Capabilities and Constraints

- Three projects, fixed content, used as-is: Torre Aurora (edificio, Zona 15, 14 niveles, 84 aptos, 68–120 m², entrega 2028, 45% avance), Residencial Vista Norte (edificio, Zona 16, 10 niveles, 60 aptos, 55–95 m², entrega 2027, 70% avance), Condominio Los Robles (casas, Carretera a El Salvador, 24 casas, 160–220 m², 3–4 hab., entrega 2028, preventa, 15% avance).
- Contact block (sala de ventas, teléfono, correo) and a "Cómo comprar" 4-step flow are existing content to keep.
- No analytics, no CMS, no image pipeline beyond static files committed to the repo (`fase-4/web/img/`). Render images (Blender output) land there later; until then, placeholders are fine but must read as placeholders, not final art.
- Any contact form stays non-functional (`mailto:`/`tel:` links or a visual-only form) — there is no backend to receive submissions.

## Brand Commitments

Name is "Terranova" (desarrolladora inmobiliaria). No logo, no locked palette, no locked typeface yet — free to establish a visual world for this surface.

## Evidence on Hand

All project data, numbers, and contact details are invented for the academic exercise. No real photography or renders exist yet; `img/condominio.png` referenced in the current HTML is a placeholder slot, not a real asset. State clearly: nothing here should be mistaken for a real company's real listings.

## Product Principles

1. Prove progress, don't just claim it — numbers (% avance, unit counts, delivery year) are the trust device, not adjectives.
2. One clear next step per visitor: book a visit / contact sales, never competing CTAs.
3. Each project keeps its own identity (edificio vs. condominio) rather than three identical cards.
4. The page must work believably with zero real photography today and read even better once renders land.
5. Mobile-first in practice: most visits are a phone on data, not a desktop.
