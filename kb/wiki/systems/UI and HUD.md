---
type: system
tags: [ui, hud, design-system, panels, globes, skill-bar, wyrd-ui-kit]
status: draft
updated: 2026-06-13
sources: ["docs/UI_BIBLE.md", "docs/wyrd-ui-design-pass.md", "docs/design/hud-design.md", "docs/wyrd-ui-reference-prompts.md", "docs/specs/35-hud-upscale.md", "docs/specs/38-tools-mute-globes-ui.md", "docs/specs/39-panel-redesign.md", "docs/specs/40-ui-from-design-notes.md", "docs/specs/41-ui-cohesion.md", "docs/specs/42-chart-crafting-ui.md", "wyrd/scripts/ui/wyrd_ui.gd", "wyrd/scripts/player_hud.gd", "wyrd/scripts/skill_bar.gd"]
---

# UI and HUD

The Wayfinder UI and HUD is a hand-drawn storybook design system centered on pale carved-wood panel frames, a five-color parchment palette, and IM Fell English typography — all authored in `wyrd/scripts/ui/wyrd_ui.gd` as a single shared kit.

## The Wayfinder UI Kit

`wyrd/scripts/ui/wyrd_ui.gd` (`class_name WyrdUi`) is the single source of truth for every palette token, stylebox, and drawing primitive used across the game. No panel constructs its own styleboxes; all consume helpers from this class.

### Palette tokens (from `docs/UI_BIBLE.md`)

| Token | Hex | Role |
|---|---|---|
| `INK` | `#3a2c20` | Body text, ink edges |
| `INK_MID` | `#6b574a` | Secondary / hints |
| `TERRACOTTA` | `#b14c33` | Titles, accents, danger |
| `SAGE` | `#6f8a3f` | Good-twin affixes, gains |
| `GOLD` | `#b58637` | Burnished highlights, XP |
| `CREAM` | `#f3e6cb` | Parchment background |

Aliases `PARCHMENT`, `PARCH_DIM`, `GREEN`, `RUST` exist for back-compat.

### Fonts

- **IM Fell English SC** (`FONT_HEADER_PATH`) — section headers, HUD labels, panel titles. All-caps small-caps, TERRACOTTA color.
- **IM Fell English** (`FONT_BODY_PATH`) — body text, row data.
- **Caveat** (`FONT_HAND_PATH`) — hand-jotted text: toasts, slot quantities, cost scribbles. Never used for load-bearing readouts.

### Panel frame

The canonical panel chrome is `assets/ui/panel_frame_v2_9p.png` — a pale carved-wood nine-patch (spec 39). Margins: L 34 / T 37 / R 32 / B 40 px. Every window (Pack, Satchel, Trades, Vendor, Craft, Dialog, Bench) uses `WyrdUi.panel_stylebox()`. New frame-like art must pass `wyrd/tools/check_ninepatch.py` before use (center-region variance and ±15% margin spread checks).

### Drawn-detail primitives (spec 44)

`wyrd_ui.gd` provides pure-vector `_draw` helpers so panels share carved detail without asset dependencies (avoiding the `load()`-in-`_draw` white-texture gotcha):

- `draw_well(c, r)` — recessed rectangular socket (stepped inner shadow, light lip)
- `draw_round_well(c, center, r)` — circular socket for ink wells
- `draw_carved_button(c, r)` — plate with top/bottom bevel + pinstripe
- `draw_parchment_grain(c, r, seed)` — deterministic sepia fibre strokes
- `draw_flourish(c, center, w)` — `── ◆ ──` section divider
- `draw_ink_bottle(c, center, h, ink)` — glass-body ink bottle icon
- `draw_scroll(c, r, sealed)` — rolled parchment with optional wax seal

### Kit components

- `chip_stylebox()` / `style_chip()` — the smallest container: parchment plate + ink border + soft drop-shadow (spec 44). Used for toasts, counters, draught hints.
- `style_kit_button()` — carved-button treatment with hover/pressed states.
- `make_meter() / set_meter()` — parchment meter (boss bar, any bar): KIT_WELL trough + fill rect + ink label.

## HUD layout

The HUD follows a **"6 always, 4 contextual"** rule (from `docs/design/hud-design.md`):

**Always visible:**
- HP globe (bottom-left of center cluster) — red liquid, glass highlight, wood-ring frame
- Focus globe (bottom-right of center cluster) — blue liquid
- Skill tray (bottom-center, between the globes) — 4 slots, 72px each, keybind tags 1-4 and F
- Mute indicator (near Focus globe)
- Quest tracker plate (top-center, floats above 3D scene)
- Compact log / toast stack (bottom-left)

**Contextual (appear only when needed):**
- Boss bar (boss fights only)
- Panel HUD tools (when a window is open)
- Floating damage/XP numbers (combat / pickup — diegetic)
- Hover tooltips (on cursor)

### HP and Focus globes (spec 38)

`player_hud.gd` builds two `GlobeGauge` nodes at `±220px` from the viewport horizontal center, anchored to the bottom (`offset_top = -148`, `offset_bottom = -16`). The liquid level tracks `current/max` in real time. The old top-left ColorRect bars (`$HPRoot`, `$FocusRoot`) are hidden. Damage flash and Pokémon-style white-out remain as full-viewport ColorRects applied after scale.

### Skill tray (spec 38 / 30)

`skill_bar.gd` — 4 slots (72px, 8px gap), 114px from bottom, no CanvasLayer scale (anchors resolve against raw window size). Each slot shows a painted icon (`assets/ui/icons/skill_*.png`) when available; otherwise an inked glyph (`➸ ❋ ✺ ◎ ❦ ✜`). Hover tooltips from `SKILL_DESC`. Cooldown shown as a fading alpha sweep. Keybinds 1-4 and F (BasicShot).

## The page windows

Eight full-screen panels, all using the carved-wood chrome:

| Page | Key | Purpose |
|---|---|---|
| **Pack / Gear** | I | Tetris grid (5×6, 64px cells) + paper-doll equipment slots |
| **Satchel** | J | Gathered materials, pouch counts |
| **Trades** | T | Three trade rows (emblem, XP bar, unlock cells, Next line) |
| **Craft (Forge/Hearth)** | varies | Recipe list with SMITH/COOK buttons |
| **Vendor** | V (NPC) | Buy/sell counter split ledger |
| **Dialog** | automatic | Bottom-anchored speech panel with NPC portrait |
| **Waystone** | automatic | Chart selection before a run |
| **Crafting Bench** | automatic | Drag-socket bench (spec 42, replaces list-menu inscribing) |

The Trades page design (approved 2026-06-11, spec 40): carved-wood frame, four butt-joined tabs (Fell SC 16), three profession rows (60px disc emblem, Fell SC 21 name, 14px XP bar, 30×30 unlock cells, "Next:" line below).

## In-progress UI clarity overhaul

Spec 41 is the cohesion pass: every surface is inventoried against which style system it uses (wood-kit / bramble / old-parchment / bare-label). Phases:
- **A** — full surface capture and orphan-style table
- **B** — extend the kit with HUD components (globe treatment, skill slot, boss bar, draught chip, toast)
- **C** — Phase-3 page designs (Pack, Dialog, Vendor, Craft, Satchel, Charts, Bench) via the Claude Design project
- **D** — implement HUD redesign from the extended kit
- **E** — full audit, 3-second read test per surface

The usability ruling (2026-06-10): ornament belongs on frames and headers only; body text and data rows use clean, high-contrast type.

> ⚠️ `player_hud.gd` still contains the legacy `UI_SCALE := 1.5` constant as a local value (spec 35 planned to centralise this into `data/ui_config.gd`); as of the last read the centralisation was specified but not yet confirmed complete — check `wyrd/scripts/data/ui_config.gd` existence before assuming it is live.

## See also

- [[UI Workflow]] — how UI is designed (Claude Design project, reference→measure→implement)
- [[Art Bible]] — master prompt stem and locked aesthetic decisions
- [[Charts]] — the Crafting Bench (spec 42) is the inscribing surface
- [[Wayfinding]] — Trades page shows the three trade rows
- [[Skills]] — skill tray slot layout and icon pipeline
- [[Camera and Game Feel]] — diegetic floating numbers, FATE camera
- [[Onboarding and Tutorial]] — tutorial highlights and guided crafting steps

## Sources

- `docs/UI_BIBLE.md` — locked palette, fonts, frame style
- `docs/wyrd-ui-design-pass.md` — Claude Design project plan and pilot retro
- `docs/design/hud-design.md` — HUD principles, anti-patterns, "6 always, 4 contextual" rule
- `docs/wyrd-ui-reference-prompts.md` — reference image prompts for all UI surfaces
- `docs/specs/35-hud-upscale.md` — UI_SCALE, 9-slice frames, orbs, 12-slot bar plan
- `docs/specs/38-tools-mute-globes-ui.md` — potion globes, mute toggle, UI audit
- `docs/specs/39-panel-redesign.md` — carved-wood frame choice, WyrdUi consolidation
- `docs/specs/40-ui-from-design-notes.md` — Trades page implement contract
- `docs/specs/41-ui-cohesion.md` — cohesion inventory and HUD kit extension
- `docs/specs/42-chart-crafting-ui.md` — Crafting Bench drag-socket UI
- `wyrd/scripts/ui/wyrd_ui.gd` — the kit implementation (palette, styleboxes, draw primitives)
- `wyrd/scripts/player_hud.gd` — globe layout, mute indicator, quest plate
- `wyrd/scripts/skill_bar.gd` — skill tray, slot sizes, icon/glyph/tooltip tables
