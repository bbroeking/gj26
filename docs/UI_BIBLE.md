# Lumbridge 3D · UI Bible

**Status:** locked 2026-04-29.

The 3 hero refs in `docs/ui-refs/hero_*.png` and the component sheet in
`comp_sheet.png` define the look. Anything not derivable from the heroes
(or this stem) is a deviation and goes back through Stage 0–3.

## Master prompt stem

```
[FRAME]: hand-drawn pen-and-ink RPG game UI mockup, cream paper backdrop with
visible aged grain, brown ink linework with slight wobble, light watercolor
washes (sage green, terracotta red, dusty teal), painterly storybook feel,
no photorealism, no glossy plastic, no neon.

[LAYOUT]: {SCREEN | COMPONENT | ICON} on cream parchment, 3:4 aspect for side
panels, 1:1 for component sheets, frontal view, isolated.

[SUBJECT]: {changes per generation}

[PALETTE]: cream paper #f3e6cb, sepia ink #3a2c20, mid-ink #6b574a, light-ink
#a08770, terracotta accent #b14c33, sage-green accent #6f8a3f, dusty-teal wash
#7a99a8, burnished gold #b58637.

[NEGATIVE]: no neon, no cyberpunk, no chrome, no glossy plastic, no hard cel
outlines, no busy backgrounds, no realistic photo textures, no 3D bevels.

Generator flags:
- Midjourney: --ar 3:4 (panels) | --ar 1:1 (sheets) --stylize 250 --v 7
- Flux / Imagen / SDXL: drop the flags
```

## Locked aesthetic decisions

- **Headers** — IM Fell English SC, ALL CAPS, ~13px with 2px letter-spacing.
- **Drop-cap** — first letter of every section header rendered ~26px in
  terracotta (`--hp` token) using `::first-letter`. Storybook-illuminated feel.
- **Body / numbers** — IM Fell English serif at 12–13px.
- **Hand-jotted text** — Caveat (handwritten) for slot quantities, floating
  XP/damage numbers, tooltips that should feel like a margin note. Never use
  Caveat for anything load-bearing (combat readout, stats).
- **Dividers** — squiggly SVG underline below each section header (60px
  tile, repeating-x). No straight `border-bottom` on headers.
- **Frames** — wobbly hand-drawn `border-image` (inline SVG) on `#stage` and
  `#panel`. Other interior boxes use 1px ink-light borders.
- **Watercolor washes per section role:**
  - Combat (red wash) — danger / target affordance
  - Quest (green wash) — goal / progress
  - Equipped (teal wash) — character state
  - Log (cream + ruled lines) — chronicle / journal
  - Inventory (cream paper, untinted) — neutral storage
- **Canvas (`#stage`)** stays dark behind the hand-drawn frame — the 3D scene
  reads best on near-black, and the paper frame separates it cleanly from the
  side panel.

## Three-together check

Lay `hero_hud.png`, `hero_inventory.png`, `hero_dialog.png` side by side. Pass
criteria:
1. Same paper texture and aged grain in all three.
2. Same brown ink stroke style (no mix of fine pen + thick brush).
3. Same wash palette (sage / terracotta / dusty teal — not introducing new hues).
4. Same serif font feeling for headings.

If a future generation breaks any of those four, refine the stem and regenerate
before moving on.

## What this Bible does NOT cover

- Iconography for individual items — these go through the existing
  `assets/icons/*.png` Blender pipeline, not Midjourney. The heroes show
  illustrated icons but those are placeholders; in-game icons are 3D-rendered
  thumbs of the actual GLB items.
- 3D assets — see `ART_BIBLE.md` (Blender bevel + toon) and the live
  `feedback_blender_bevel_pipeline.md` memory.
- Mobile / small-screen — out of scope for now; stage will eventually need a
  separate mockup pass and a `@media` breakpoint.
