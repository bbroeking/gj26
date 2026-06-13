---
type: source
tags: [ui, hud, design-pipeline, source-digest]
status: draft
updated: 2026-06-13
sources: ["docs/UI_BIBLE.md", "docs/wyrd-ui-design-pass.md", "docs/wyrd-ui-reference-prompts.md", "docs/design/hud-design.md", "docs/reference-to-ui-playbook.md", "docs/character-pipeline/UI_MOCK_WORKFLOW.md", "docs/specs/35-hud-upscale.md", "docs/specs/38-tools-mute-globes-ui.md", "docs/specs/39-panel-redesign.md", "docs/specs/40-ui-from-design-notes.md", "docs/specs/41-ui-cohesion.md", "docs/specs/42-chart-crafting-ui.md"]
---

# Source Digest — UI and HUD

Digest of all UI-related source files read during the 2026-06-13 ingest. Feeds [[UI and HUD]] and [[UI Workflow]].

## Raw sources read

| File | Summary | Fed pages |
|---|---|---|
| `docs/UI_BIBLE.md` | Locked aesthetic stem: sepia ink on aged cream, five-color palette, IM Fell fonts, three-together pass criteria. Status: locked 2026-04-29. | [[UI and HUD]], [[UI Workflow]], [[Art Bible]] |
| `docs/wyrd-ui-design-pass.md` | The Claude Design project plan (wayfinder-ui): UI Kit artboard, pilot Trades loop (complete 2026-06-11), Phase-3 page queue, connector mechanics and fallback, lessons (short prompts, text seeding, name every cell). | [[UI and HUD]], [[UI Workflow]] |
| `docs/wyrd-ui-reference-prompts.md` | Round-2 Midjourney prompt batch for 8 page heroes + 4 element sheets (bench, forge, pack, trades, vendor, dialog, HUD, loadout; frames, sockets, bottles, icons). Locked stem: carved pale-oak, flat storybook, no photorealism. | [[UI and HUD]], [[UI Workflow]] |
| `docs/design/hud-design.md` | Research synthesis: 4 HUD principles (info hierarchy, show-when-relevant, diegetic, reduce-decision-frequency); pattern catalogue from Hades/Dead Space/Diablo/Persona 5; anti-patterns audit; "6 always, 4 contextual" cleanup rule. | [[UI and HUD]] |
| `docs/reference-to-ui-playbook.md` | Six-stage reference-to-UI process: UI Bible → hero screens → component sheet → design tokens → HTML/CSS translation → integration test. Includes CSS techniques (9-slice, pixel rendering, progress bars) and tools roundup. | [[UI Workflow]] |
| `docs/character-pipeline/UI_MOCK_WORKFLOW.md` | 4-step pre-Blender mock workflow: silhouette trace, palette card, animation card, codex preview entry. Step 4 wires GLBs to concept art in `codex.html` via `MODEL_OVERLAY_MAP`. UI Bible tokens apply to the codex viewer. | [[UI Workflow]], [[Asset Pipeline]] |
| `docs/specs/35-hud-upscale.md` | HUD upscale spec: UI_SCALE knob → `data/ui_config.gd`, ornate gold 9-slice `frame_gold.png`, status icon strip (4 slots), HP/Mana orbs (Sprite2D + alpha-mask), 12-slot action bar. Phased plan, Phase 1 = foundation. | [[UI and HUD]] |
| `docs/specs/38-tools-mute-globes-ui.md` | Tool slots (pickaxe/axe equip slots), mute toggle (F10, persisted), HP/Focus potion globes (bottom-center cluster, red left / blue right), UI audit (screenshot every surface). Open: mute input, globe rendering approach. | [[UI and HUD]], [[Gathering]] |
| `docs/specs/39-panel-redesign.md` | Replaced hedgewood vine frames with pale carved-wood (`panel_frame_v2_9p.png`); lesson: symmetric, border-only, interior-clean frames only. Introduced `check_ninepatch.py`. WyrdUi consolidated as single stylebox source. | [[UI and HUD]], [[UI Workflow]] |
| `docs/specs/40-ui-from-design-notes.md` | Implement contract for Trades page (pilot): carved-wood frame, 4 butt-joined tabs, 3 profession rows (60px disc, Fell SC 21 name, 14px XP bar, 30×30 unlock cells, Next line). Data corrections vs artboard included. | [[UI and HUD]], [[Trades and Leveling]] |
| `docs/specs/41-ui-cohesion.md` | Cohesion pass: inventory every surface against which style dialect it uses, extend kit with HUD components (globe treatment, skill slot, boss bar, draught chip, toast), Phase-3 page designs, implement HUD from kit, full audit. | [[UI and HUD]], [[UI Workflow]] |
| `docs/specs/42-chart-crafting-ui.md` | Crafting Bench spec (replaces list-menu inscribing): satchel tray (left), drag-to-socket bench (center: 1 base + 3 ink + 1 trophy socket), result slot with live odds preview (right), ink mixing pot. Kit styling throughout. | [[UI and HUD]], [[Charts]], [[Onboarding and Tutorial]] |

## Key code files read

| File | What it tells us |
|---|---|
| `wyrd/scripts/ui/wyrd_ui.gd` | The kit implementation: palette constants, `panel_stylebox()`, `chip_stylebox()`, `make_meter()`, `style_*` helpers, and all spec-44 draw primitives (draw_well, draw_round_well, draw_carved_button, draw_parchment_grain, draw_flourish, draw_ink_bottle, draw_scroll). |
| `wyrd/scripts/player_hud.gd` | Globe layout (GlobeGauge nodes at ±220px, anchored bottom), mute indicator, quest plate, toast stack. Legacy HPRoot/FocusRoot ColorRects hidden but still in the scene tree. |
| `wyrd/scripts/skill_bar.gd` | 4-slot tray (72px, 8px gap, 114px from bottom), painted icon map, glyph fallback for iconless skills, SKILL_DESC for hover tooltips. |
| `wyrd/scripts/inventory_panel.gd` | 5×6 Tetris grid (64px cells), paper-doll equipment slots (helmet/ring/weapon/chest/boots/pickaxe/axe), painted item icon preload table. |

## Contradictions and flags

> ⚠️ Spec 35 planned to centralise `UI_SCALE` into a `data/ui_config.gd` static class. As of the last code read, `player_hud.gd` still holds `const UI_SCALE := 1.5` as a local constant. `wyrd/scripts/data/ui_config.gd` may or may not exist — verify before assuming centralisation is live.

> ⚠️ `docs/UI_BIBLE.md` title says "Lumbridge 3D" — an earlier project name now superseded by Wayfinder / Bramblewood (renamed 2026-06-10). The aesthetic content is unchanged and still authoritative; only the title is stale.

> ⚠️ The hedgewood bramble globe direction (spec 38) and the carved-wood window direction (spec 39) are both present in code. Spec 41 is the cohesion pass that reconciles them; until that lands, HUD and windows speak partially different style dialects.
