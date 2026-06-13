---
type: pipeline
tags: [ui, design-pipeline, claude-design, midjourney, ninepatch, reference-to-ui]
status: draft
updated: 2026-06-13
sources: ["docs/wyrd-ui-design-pass.md", "docs/reference-to-ui-playbook.md", "docs/character-pipeline/UI_MOCK_WORKFLOW.md", "docs/UI_BIBLE.md", "docs/specs/39-panel-redesign.md", "docs/specs/41-ui-cohesion.md"]
---

# UI Workflow

Wayfinder's UI design pipeline converts locked aesthetic constraints into measured Godot implementations through a three-stage loop: Claude Design artboard → measurement → GDScript `_draw`/Control rebuild, with ninepatch verification as a quality gate.

## Overview

The pipeline is documented in `docs/wyrd-ui-design-pass.md` and the reference playbook `docs/reference-to-ui-playbook.md`. Its core insight: Claude Design produces working HTML/React, none of which ports to Godot. Its output is a **visual specification** — an artboard to measure (geometry, type scale, spacing, colour) and reimplement. Any design that leans on web-only affordances (hover transitions, real scrollbars, drop-shadows) gets simplified at design time, not discovered at port time.

## Stage 0 — UI Bible (locked stem)

`docs/UI_BIBLE.md` is the locked aesthetic contract. It defines the master Midjourney/Claude Design prompt stem (parchment backdrop, sepia ink linework, aged grain, watercolor washes) and locks the five-color palette, fonts (IM Fell English SC headers / IM Fell English body / Caveat hand-jotted), and three-together check (same paper texture, same ink stroke, same wash palette, same serif feeling across `hero_hud.png / hero_inventory.png / hero_dialog.png`).

The stem is never edited after approval. A deviation in a future generation goes back through Stage 0–3 before proceeding.

## Stage 1 — Claude Design artboard

All UI design lives in the **`wayfinder-ui`** Claude Design project. One persistent "Wayfinder UI Kit" page holds the design system (palette swatches, type scale, the carved-wood frame, button/chip/bar/emblem components). Page artboards compose from the kit so revisions propagate.

**Seeding a page session:**
1. Paste the locked constraint block verbatim (chrome, layouts, palette, type, canvas 1280×720, windows ≤ 630×600).
2. Use text-only seeding — no file uploads through the connector (they error out).
3. Keep prompts short; long prompts error out (retro lesson from the pilot).
4. Name every data cell in briefs — the design agent invents data when given bare numbers.

**Approval loop:** design round → user reacts → ≤1 revision round → approve. Time box is one design + one revision round per page. If not approved by then, ship the closest version and move on.

**Pilot (2026-06-11, Trades page):** complete in one session. Retro: the loop works. Lessons encoded above.

**Phase-3 page queue** (in player-value order): Pack/Gear, Dialog, Vendor, Craft, Satchel, Charts, Crafting Bench.

## Stage 2 — Measure and extract

From the approved artboard, extract a measured contract written into `docs/specs/40-ui-from-design-notes.md` (and appended per page). The contract captures:
- Window chrome: frame asset path, title font/size/colour, tab row geometry
- Component geometry: emblem size, bar dimensions, cell sizes and gaps
- Exact colour tokens matched to `WyrdUi` palette constants
- Data corrections vs the artboard (the artboard invents data from underspecified briefs; the contract fixes them)

## Stage 3 — Godot implementation

Implement in GDScript using `WyrdUi` helpers — never hand-build a stylebox outside `wyrd/scripts/ui/wyrd_ui.gd`. Constraints:
- **Never `load()` a texture inside `_draw()`** — renders as a white rect forever (preload in `_ready`).
- Pure-vector `_draw` calls for carved detail (wells, buttons, flourishes, grain) from `WyrdUi` spec-44 primitives.
- Nine-patch frames built via `StyleBoxTexture` with `WyrdUi.panel_stylebox()`.

After implementation: **side-by-side fidelity check** (capture screenshot vs artboard). User sign-off required. All headless suites must stay green.

## Ninepatch verification

`wyrd/tools/check_ninepatch.py` — mandatory gate before any frame-like art ships. Checks:
- Center region of the texture contains only low-variance parchment (no art bleeding into the tileable area).
- Border thickness within ±15% across all four sides.

The spec-39 lesson: organic asymmetric vine art (hedgewood direction, rejected) fought ninepatch — margins guessed three times, tendril tiled across panel interiors. The rule encoded: **generate frame art that is symmetric, border-only, and interior-clean** — or don't nine-patch it.

## Midjourney mock pipeline (fallback / reference images)

When Claude Design isn't available or for generating reference art (not artboards), the Midjourney flow from `docs/wyrd-ui-reference-prompts.md` applies:

1. Locked stem (carved pale-oak, parchment-cream, bold ink linework, flat storybook illustration, `--ar 16:9 --stylize 250 --v 7`).
2. Run prompts in Midjourney → save picks to `docs/ui-refs/round2/<slug>.png`.
3. Claude measures/crops picked references → treatments lifted into `_draw` implementations.
4. Frame sheets pass `check_ninepatch.py` before becoming textures.

Alternatively, `mcp__meshy__meshy_text_to_image` (3–9 credits/image) can generate the same reference images without Midjourney.

## Character codex preview (parallel workflow)

`docs/character-pipeline/UI_MOCK_WORKFLOW.md` describes a 4-step pre-Blender flow that touches UI: Step 4 wires a finished GLB back to its concept image in `codex.html` via `MODEL_OVERLAY_MAP`. The codex viewer follows the same UI Bible rules (tokens, frame-ink decoration, dialog patterns). This is distinct from the panel design loop above.

## Connector mechanics

The Chrome connector drives the `wayfinder-ui` Claude Design project tab in the user's personal browser. **Fallback** if the connector fights us twice in a session: user drives Claude Design by hand from the same seed text (kept in `docs/wyrd-ui-design-pass.md`), or revert to the Midjourney mock → measure → implement flow.

## Risks

- **Web-native drift** — countered by the constraint block and simplify-at-design-time rule.
- **Asset gaps** (painted trade emblems, tool icons) — queue as Midjourney one-offs; don't block the page.
- **Scope creep into systems** ("vendor page needs a buyback tab") — design only what the code already does; new features go to the build plan.
- **Connector flakiness** — fallback above; never burn >15 min on tab wrangling.

## Success metric

Each page: (a) 3-second read test — a newcomer can say what the page is for from the capture alone; (b) side-by-side fidelity sign-off; (c) all suites stay green after implementation.

## See also

- [[UI and HUD]] — the kit tokens, HUD layout, and page inventory
- [[Art Bible]] — the equivalent pipeline for 3D character/environment art
- [[Asset Pipeline]] — how GLBs and textures flow from tools to Godot
- [[Blender Pipeline]] — the 3D art production pipeline
- [[Content Generation and Evals]] — broader AI-generation workflows

## Sources

- `docs/wyrd-ui-design-pass.md` — the design-pass plan, pilot retro, lessons, phase queue
- `docs/reference-to-ui-playbook.md` — the six-stage reference-to-UI process
- `docs/character-pipeline/UI_MOCK_WORKFLOW.md` — pre-Blender mock flow and codex wiring
- `docs/UI_BIBLE.md` — locked aesthetic stem and three-together check
- `docs/specs/39-panel-redesign.md` — ninepatch lessons and check_ninepatch.py gate
- `docs/specs/41-ui-cohesion.md` — cohesion inventory, Phase-3 design queue
