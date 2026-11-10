---
name: Intranet Terranova
description: The developer's preventa folder. Projects are fichas técnicas and network access is a cuadro de disponibilidad, printed cell by cell.
colors:
  papel: "#eef0ec"
  papel-hondo: "#e3e7e1"
  tinta: "#13302a"
  tinta-suave: "#4a5d57"
  linea-tenue: "#b9c3bd"
  tinta-velo: "rgba(19, 48, 42, 0.07)"
  si: "#2f8a57"
  si-texto: "#1e6a40"
  no: "#c4362b"
  reserva: "#b8860f"
  grupo-arquitectos: "#1e4f8f"
  grupo-arquitectos-fondo: "#dde6f1"
  grupo-ingenieros: "#9a4a17"
  grupo-ingenieros-fondo: "#f2e3d8"
  grupo-ti: "#5a3d8a"
  grupo-ti-fondo: "#e7e1f0"
  grupo-visitantes: "#55605b"
  grupo-visitantes-fondo: "#e4e7e5"
  grupo-neutro-fondo: "#dfe6e2"
typography:
  display:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "clamp(3rem, 7.2vw, 6rem)"
    fontWeight: 800
    lineHeight: 0.9
    letterSpacing: "-0.01em"
    fontVariation: "'wdth' 68"
  headline:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "clamp(2.25rem, 4vw, 3.25rem)"
    fontWeight: 800
    lineHeight: 0.92
    fontVariation: "'wdth' 68"
  title:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "clamp(1.5rem, 2.4vw, 2rem)"
    fontWeight: 800
    lineHeight: 1.05
    letterSpacing: "0.01em"
    fontVariation: "'wdth' 75"
  body:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.5
    fontVariation: "'wdth' 100"
  body-lead:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 400
    lineHeight: 1.45
  data:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "0.9375rem"
    fontWeight: 600
    lineHeight: 1.5
    fontFeature: "'tnum' 1"
  label:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 700
    lineHeight: 1.25
    letterSpacing: "0.02em"
    fontVariation: "'wdth' 85"
  stamp:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "0.08em"
    fontVariation: "'wdth' 75"
  small:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 400
    lineHeight: 1.5
  code:
    fontFamily: "ui-monospace, Cascadia Mono, Menlo, monospace"
    fontSize: "0.8125rem"
    fontWeight: 400
rounded:
  none: "0"
spacing:
  gutter: "clamp(1rem, 3vw, 2.5rem)"
  section: "clamp(2.5rem, 5vw, 4rem)"
  column-gap: "clamp(2rem, 4vw, 4rem)"
  row: "0.55rem"
  cell: "0.75rem 0.6rem"
  page-max: "88rem"
components:
  cuadro-head:
    backgroundColor: "{colors.papel-hondo}"
    textColor: "{colors.tinta}"
    typography: "{typography.label}"
    rounded: "{rounded.none}"
    padding: "0.6rem 0.5rem"
  celda:
    backgroundColor: "transparent"
    textColor: "{colors.si-texto}"
    rounded: "{rounded.none}"
    padding: "0.5rem 0.25rem"
    height: "3.6rem"
  celda-hover:
    backgroundColor: "{colors.tinta-velo}"
  sello:
    backgroundColor: "transparent"
    textColor: "{colors.no}"
    typography: "{typography.stamp}"
    rounded: "{rounded.none}"
    padding: "0.3rem 0.5rem"
  ficha-row:
    textColor: "{colors.tinta}"
    typography: "{typography.data}"
    padding: "0.55rem 0"
  etapa:
    backgroundColor: "transparent"
    textColor: "{colors.tinta-suave}"
    rounded: "{rounded.none}"
    padding: "0.45rem 0.3rem"
  etapa-hecha:
    backgroundColor: "{colors.papel-hondo}"
    textColor: "{colors.tinta}"
  etapa-actual:
    backgroundColor: "{colors.tinta}"
    textColor: "{colors.papel}"
  lectura:
    backgroundColor: "{colors.papel}"
    textColor: "{colors.tinta}"
    rounded: "{rounded.none}"
    padding: "0.75rem 0.9rem"
  soporte:
    backgroundColor: "{colors.papel}"
    textColor: "{colors.tinta}"
    rounded: "{rounded.none}"
    padding: "clamp(1.25rem, 2.5vw, 2rem)"
---

# Design System: Intranet Terranova

## Overview

**Creative North Star: "The Preventa Folder"**

The intranet reads like the printed folder a real-estate developer hands across the sales desk: cool matte stock, green-black ink, 1px rules, and availability inks borrowed from a unit-availability sheet. Projects are fichas técnicas (fixed-capacity spec tables with right-aligned figures), and network access is a cuadro de disponibilidad where every cell is a printed mark: a green square for allowed, a red rubber stamp for blocked.

Density is that of a technical sheet, not a dashboard. Hierarchy comes from width, weight and case within a single family. Condensed heavy caps name things, normal-width text explains them, and tabular figures hold the numbers in columns. Nothing floats, nothing is rounded, and nothing casts a shadow. Depth is paper laid on paper, one tone deeper.

The visitor's group is a single variable. One attribute on the root swaps the group ink and its tint, and that recolors the big group name, the visitor's own row in the cuadro, the IP figure, focus rings and selection, and decides which copy is shown. The page is the same sheet printed for a different reader.

**Key Characteristics:**
- Cool matte paper ground, green-black ink, 1px linework only.
- One variable family (Archivo) carries the whole ramp through width: 68% for names, 75–85% for labels, 100% for reading.
- Availability inks (si, no, reserva) are semantic and appear only as state marks.
- One group variable rewrites color, the highlighted row and copy.
- Zero radius, zero shadow. The only motion is the stamps pressing in once.

## Colors

A restrained print palette: a cool neutral stock and one green-black ink, plus three availability inks and four group inks that are never decorative.

### Primary
- **Ledger Green-Black** (tinta): all text, all structural linework (`--linea` is the same ink), the current-stage fill, and the default group ink when no group is recognized.

### Secondary (availability inks)
- **Disponible Green** (si): the solid allowed mark in the cuadro and the outline of available units. Mark only, never text.
- **Disponible Text Green** (si-texto): the "Sí" label beside the mark. It is darker than the mark to clear 4.5:1 on paper.
- **Stamp Red** (no): the blocked rubber stamp (1px border and text) and sold units.
- **Reservado Amber** (reserva): reserved units. It is deliberately darker than the contract's #d9a21f so the filled cell holds 2.8:1 against the paper.

### Tertiary (group inks, one active at a time)
- **Arquitectos Blueprint** (grupo-arquitectos / -fondo), **Ingenieros Rust** (grupo-ingenieros / -fondo), **TI Violet** (grupo-ti / -fondo), **Visitantes Slate** (grupo-visitantes / -fondo). The active pair becomes `--grupo` and `--grupo-fondo`. When no group is recognized, `--grupo` falls back to tinta over grupo-neutro-fondo.

### Neutral
- **Matte Stock** (papel): page ground, readout panel, support box.
- **Deeper Stock** (papel-hondo): cuadro column heads, completed stages, inline code, scrollbar track.
- **Muted Ink** (tinta-suave): secondary text, row labels in fichas, captions, the footer.
- **Hairline Grey-Green** (linea-tenue): inner rules of fichas and notice rows, the readout border.
- **Ink Veil** (tinta-velo): the hover, focus and pressed wash on cuadro cells.

### Named Rules
**The Availability Ink Rule.** Green, red and amber mean available, blocked/sold and reserved. They appear only as state marks (a square, a stamp, a unit cell) and never as decoration, headings or buttons.

**The One Variable Rule.** The group is one root attribute (`html[data-grupo]`) driving `--grupo` and `--grupo-fondo`. Every group-dependent color, the highlighted row and the shown copy derive from it. Never hard-code a group color on a component.

**The Mark-Versus-Text Rule.** When an availability ink can't carry text contrast, split it: the mark keeps the ink and the label takes a darker sibling (si vs si-texto).

## Typography

**Display Font:** Archivo variable (wght 100–900, wdth 62–125), self-hosted beside the page, with system-ui, sans-serif fallback
**Body Font:** Archivo at 100% width
**Label/Mono Font:** Archivo condensed caps for labels. ui-monospace only for firewall rules quoted in the readout.

**Character:** A single grotesque stretched across its width axis. Condensed 800 caps feel like the stencilled project names on a hoarding, and the normal width reads like the fine print of a spec sheet.

### Hierarchy
- **Display** (800, clamp 3–6rem, 0.9, width 68%, uppercase, group ink): the detected group name only.
- **Headline** (800, clamp 2.25–3.25rem, 0.92, width 68%, uppercase): project names on fichas.
- **Title** (800, clamp 1.5–2rem, 1.05, width 75%, uppercase): section heads.
- **Body** (400, 1rem, 1.5): explanatory notes, capped at 62ch. **Body-lead** (1.125rem, 1.45) is used for the group sentence (34ch) and the support contact.
- **Data** (600, 0.9375rem, tabular figures): ficha values, right-aligned against muted 400 row labels.
- **Label** (700, 0.875rem, width 85%, 0.02em, uppercase): cuadro heads, row heads, notice table heads, stage names (0.75rem).
- **Stamp** (800, width 75%, 0.08em, uppercase): the BLOQUEADO mark.
- **Small** (0.8125rem): legends, footer, quoted code.

### Named Rules
**The Width-Not-Family Rule.** Rank is made by width, weight and case within Archivo. Never introduce a second display face.

**The Tabular Rule.** Every table, IP, date and percentage uses tabular figures. In fichas, values sit right-aligned.

## Layout

A centered sheet (max 88rem) with fluid gutters (1–2.5rem). Bands are separated by full-width 1px ink rules rather than by whitespace or cards. The first band splits 5fr/7fr (connection ficha, then cuadro). Projects are 4/4/4 rows (name and stages, spec ficha, unit grid), each opened by a 1px ink rule. Notices and support split 7fr/5fr. Section padding is clamp(2.5rem, 5vw, 4rem), and column gaps are clamp(2rem, 4vw, 4rem).

At 64rem and below, the two-column bands stack and projects go 2-up with the name spanning. At 40rem and below, projects go single-column, and the cuadro compresses: column sub-labels, row subnets, the "Sí" text and the "· tú" tag drop, and the stamp shortens to "NO". The notice area folds under the date.

## Elevation & Depth

Flat by construction. There are no shadows anywhere. Depth is tonal: papel-hondo marks a surface one sheet deeper (column heads, completed stages, code), and the group tint lays a wash on the visitor's row. Boxes (support, readout) exist only as 1px outlines on the same paper.

### Named Rules
**The Paper-On-Paper Rule.** A surface is distinguished by one tone step or a 1px rule, never by a shadow, blur or lift.

## Shapes

Square corners everywhere (0 radius). Every edge is a 1px line: tinta for structure and the cuadro grid, linea-tenue for inner rows. State marks are flat geometry: a solid 0.9rem square for allowed, a 1px-bordered stamp rotated −5° for blocked, and unit cells as small rectangles (2.4:1 for tower floors, 1:1 for lots). Unit states use printed devices: solid fill (sold, reserved, obra gris), a green outline (available), 135° hatching (cimentación) and a dashed outline (in design).

### Named Rules
**The One-Pixel Rule.** Rules and borders are 1px. The only exception is the 2px focus ring in the group ink.

## Components

### Cuadro de disponibilidad (signature)
Printed availability grid: groups as rows, services as columns, a full 1px ink grid.
- **Heads:** deeper-stock fill, condensed caps service name over a regular port line. The corner cell is blank and borderless at top and left.
- **Cells:** full-bleed buttons at least 3.6rem tall, showing a green square + "Sí" or a red stamp. Hover, focus and pressed lay the ink veil. Focus also draws an inset 2px group ring.
- **Visitor row:** group tint background, row head in group ink, plus "· tú".
- **Readout:** a 1px hairline box under the grid, at least 4.5rem tall. It shows the exact rule deciding the hovered, focused or pinned cell (click toggles a pin), and opens on the rule that most defines the visitor's group.

### Sello (blocked stamp)
Stamp-red 1px border and text, condensed 800 caps, rotated −5°. It is the system's only motion: on load it presses in from 1.7× scale over 420ms (cubic-bezier(0.16, 1, 0.3, 1)), staggered 60ms per stamp after 200ms. It is static under reduced motion.

### Ficha técnica
A borderless spec table between hairline rules. Labels are muted and left-aligned. Values are 600 weight, tabular and right-aligned. The progress figure steps up to 1.25rem.

### Etapas (stage strip)
Six equal cells in a 1px ink box with 1px dividers, using small condensed labels. Done stages use deeper stock. The current stage is reversed (ink fill, paper text, 700).

### Unit grid
A 2px-gap grid of unit cells with a matching inline legend (0.95rem swatches, counts in tabular figures). It is decorative to assistive tech, which reads a single labelled image.

### Containers
The support box is a 1px ink outline with fluid padding. Its IP figure is set in the group ink at 1.25rem over a hairline. There are no cards elsewhere.

### Navigation
A top band: a stepped-block SVG mark with the wordmark in condensed 800 caps and "INTRANET" in muted 400 caps (hidden on narrow screens). Server time sits right in tabular figures. It is closed by a 1px ink rule.

## Do's and Don'ts

### Do:
- **Do** derive every group-dependent color from `--grupo` / `--grupo-fondo`, set once by `html[data-grupo]`.
- **Do** use reservado #b8860f for filled reserved cells, and si-texto #1e6a40 for "Sí" text while the mark stays #2f8a57.
- **Do** separate bands and rows with 1px rules (tinta for structure, linea-tenue for inner rows).
- **Do** set names in Archivo condensed caps (68–85% width, 700–800) and keep reading text at 100% width.
- **Do** use tabular figures for every number, and right-align values in fichas.
- **Do** show state as printed marks: square, stamp, fill, outline, hatch or dash.
- **Do** keep the stamp press-in as the only motion, once on load, behind `prefers-reduced-motion: no-preference`.

### Don't:
- **Don't** round any corner or add any box-shadow.
- **Don't** use availability inks (green, red, amber) for anything but state.
- **Don't** hard-code a group color on a component, or show group copy by any means other than the group variable.
- **Don't** add transitions, hover lifts or scroll animation. Hover is the flat ink veil.
- **Don't** load fonts or assets from a CDN. Archivo ships beside the page.
