---
name: Terranova
description: Developer marketing site for Terranova — navy and brass, real building photography, played straight.
colors:
  navy: "#0b2340"
  navy-deep: "#081a30"
  navy-soft: "#16365c"
  gold: "#b8902f"
  gold-deep: "#8f6f22"
  cream: "#eef1f5"
  paper: "#ffffff"
  ink: "#1c2430"
  gray: "#5c6672"
  line: "#dde2ea"
  line-navy: "rgba(255,255,255,.16)"
  white-on-navy: "rgba(255,255,255,.88)"
  white-on-navy-dim: "rgba(255,255,255,.72)"
typography:
  display:
    fontFamily: "Source Serif 4, Georgia, serif"
    fontSize: "clamp(2.1rem, 4.6vw, 3.4rem)"
    fontWeight: 700
    lineHeight: 1.12
    letterSpacing: "-0.01em"
  heading:
    fontFamily: "Source Serif 4, Georgia, serif"
    fontSize: "clamp(1.9rem, 3.2vw, 2.6rem)"
    fontWeight: 700
    lineHeight: 1.12
  metric:
    fontFamily: "Source Serif 4, Georgia, serif"
    fontSize: "1.875rem"
    fontWeight: 700
  body:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "Public Sans, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 600
rounded:
  sm: "6px"
  md: "10px"
  pill: "999px"
spacing:
  sm: "14px"
  md: "22px"
  lg: "44px"
  xl: "80px"
components:
  button-primary:
    backgroundColor: "{colors.gold}"
    textColor: "{colors.navy-deep}"
    rounded: "{rounded.sm}"
    padding: "12px 22px"
  button-primary-hover:
    backgroundColor: "#cba542"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "#ffffff"
    rounded: "{rounded.sm}"
    padding: "12px 22px"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.navy}"
    rounded: "{rounded.sm}"
    padding: "12px 22px"
---

# Design System: Terranova

## Overview

**Creative North Star: "The Established Developer"**

Terranova's site reads like a real, established real-estate developer's marketing site: navy and brass, serif headlines over clean sans body copy, real photography of buildings in every card, generous whitespace. It is the category standard played straight and at full craft, not a concept — the previous direction (industrial site-hoarding signage, stencil type, monumental numerals) was explicitly discarded by the client as looking generated/AI-styled, so this system never borrows its devices.

Trust comes from photography and clear facts (specs, a labeled progress bar, a named process), never from a visual gimmick. Each project card carries a real stock photograph standing in for its finished look; captions are honest that these are reference photos, not the final renders.

**Key Characteristics:**
- Navy (`#0b2340`) + cool mist (`#eef1f5`) + a restrained brass/gold accent (`#b8902f`) for CTAs and small emphasis only — never a background wash.
- Serif headlines (Source Serif 4) paired with a plain sans body/UI face (Public Sans) — a conventional, trustworthy pairing.
- Every project card carries a real photograph; progress is a conventional labeled percentage bar, not a display device.
- Flat, soft-shadowed cards with rounded corners (10px) — not the sharp 2px-radius industrial plates of the discarded world.

## Colors

### Primary
- **Brass Gold** (`#b8902f`): every primary CTA background, the serif logotype's second word, metric numbers, progress-bar fill. Never a large background field.

### Secondary
- **Deep Navy** (`#0b2340`): header, hero overlay, the "Why Terranova" section background, dark footer. The dominant dark surface.

### Neutral
- **Cool Mist** (`#eef1f5`): the page's light background between navy sections.
- **Paper White** (`#ffffff`): card surfaces.
- **Ink** (`#1c2430`): body text on light backgrounds.
- **Slate Gray** (`#5c6672`): secondary/supporting text on light backgrounds.
- **Hairline** (`#dde2ea`): dividers and card borders on light surfaces.

### Named Rules
**The One Accent Rule.** Gold never fills a section background or a card; it is reserved for CTAs, the logotype's second word, metric figures, and the progress-bar fill.

## Typography

**Display/Heading Font:** Source Serif 4 (self-hosted variable, weight 300–800), Georgia fallback.
**Body/UI Font:** Public Sans (self-hosted variable, weight 100–900), system-ui fallback.

**Character:** Source Serif 4 signals an established, premium developer on headlines and the logotype; Public Sans stays plain and highly legible everywhere people actually read — nav, body copy, specs, buttons, form-like contact details.

### Hierarchy
- **Display** (700, `clamp(2.1rem, 4.6vw, 3.4rem)`, line-height 1.12): the hero headline only.
- **Heading** (700, `clamp(1.9rem, 3.2vw, 2.6rem)`): section headings (`h2`).
- **Title** (700, 1.5rem): project names (`h3`).
- **Metric** (700, 1.875rem, tabular figures): the four hero trust-bar numbers only.
- **Body** (400, 1.0625rem, line-height 1.6): paragraphs.
- **Label** (600, .75–.9375rem): nav links, specs labels, tags/badges, buttons.

## Layout

Single-column, `.marco` container (`max-width: 1180px`, 22px gutter). Project cards: 1 column under 880px, 3 equal columns above. Section rhythm: 80px vertical padding per section, alternating cream/white/navy backgrounds (no two consecutive sections share a background) instead of hairline dividers between every section.

## Elevation & Depth

Flat sections, lifted cards. Project cards and the contact map lift off their background with one soft, blurred shadow (`--shadow-card`); hovering a project card raises the shadow one step (`--shadow-card-hover`) with a small translateY. No hard-offset or neobrutalist shadows anywhere in this system.

### Shadow Vocabulary
- **card** (`0 14px 32px -18px rgba(11,35,64,.28)`): resting state for project cards and the map embed.
- **card-hover** (`0 20px 40px -16px rgba(11,35,64,.34)`): project card hover/focus state, paired with `translateY(-3px)`.

## Shapes

Rounded corners throughout (10px on cards, 6px on buttons, pill badges for status tags) — a deliberate contrast with the discarded industrial-signage world's sharp 2px plates. Photography always fills a 4:3 frame with `object-fit: cover`.

## Components

### Buttons
- **Shape:** 6px radius.
- **Primary (gold):** brass background, navy-deep text, 12px/22px padding; hover lightens to `#cba542`.
- **Ghost (on navy/photo):** transparent, white text, translucent white border; hover fills `rgba(255,255,255,.12)`.
- **Outline (on light):** transparent, navy text and border; hover fills solid navy with white text. Used for the per-project "Agendar visita" action.

### Cards
- **Corner Style:** 10px radius.
- **Background:** solid white.
- **Shadow Strategy:** see Elevation & Depth.
- **Photo:** 4:3 frame, `object-fit: cover`, a pill status badge (`En construcción` navy / `Preventa` brass) overlaid top-left.
- **Progress bar:** label + percentage row, then a 7px pill track filled in gold, animated from 0 to its target width once when the card scrolls into view (respects `prefers-reduced-motion`).

### Navigation
Sticky navy header, 76px tall, translucent with a light blur and bottom hairline. Text links in Public Sans, a phone number with an inline icon, and the primary gold CTA at the end. Below 900px, links and phone collapse into a hamburger-triggered full-width navy panel.

### Trust bar (signature component)
A four-figure strip (`3 · 168 · +15 · 100%`) inside a translucent navy band under the hero photo, each figure in the serif Metric style over a short Public Sans label. States the developer's scale in facts, not a slogan.

## Do's and Don'ts

### Do:
- **Do** keep gold to CTAs, metric figures, the progress-bar fill, and the logotype's second word (The One Accent Rule).
- **Do** give every project card a real photograph; caption honestly when it is a reference photo standing in for the final render.
- **Do** alternate section backgrounds (cream/white/navy) instead of relying on dividers to separate sections.
- **Do** keep all specs (m², unit counts, years, percentages) in tabular figures.

### Don't:
- **Don't** add a kicker/eyebrow label above any heading — the heading carries its own weight.
- **Don't** reach for the discarded world's devices: stencil display type, monumental numerals, hazard stripes, or sharp 2px-radius plates.
- **Don't** let gold cover a section background or a full card — it is an accent, not a field color.
- **Don't** use a hard-offset flat shadow; cards lift with a soft blurred shadow only.
