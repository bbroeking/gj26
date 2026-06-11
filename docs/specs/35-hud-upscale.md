# 35 — HUD upscale

> **Outcome**: the gj26 HUD moves from "polished-minimal" (4 ability slots + HP/Focus bars at fixed-pixel offsets) to a recognizably AAA-MMO-rich frame: ornate gold-leaf scrollwork as a unified visual language, large HP/Mana orbs anchoring the bottom, a 24-slot dual-row hotbar between them, a buff/status row with duration timers, a player portrait, and seats for minimap / quest / chat / party / inventory that later specs can fill in. Phase 1 of this spec ships the **foundation** (UI_SCALE knob, Theme.tres, ornate frame 9-slice, status icon row, orb conversion); later phases ship the substantial elements (action bar expansion, minimap, quests) when their backing systems exist.

## Why

The HUD currently reads as "indie test scaffold." User shared a reference image of a polished AAA HUD (Aric the Level 50, gold-leaf scrollwork frames, dual-row 24-slot action bar, painted character portrait, HP+Mana orbs, buff row with timers, minimap with region label, quest tracker, party panel, chat with tabs) and asked "how does the UI work for the game. I want to figure out how to upscale the game." Separately said "the bleed and the burn don't make sense" — i.e. status communication is failing.

Survey of current state (`scripts/skill_bar.gd`, `scripts/player_hud.gd`, `scripts/boss_bar.gd`, `scenes/PlayerHUD.tscn`):
- Everything is **fixed-pixel layout** with hard-coded `offset_*` values assuming 1920×1080
- **No `Theme.tres`** — all styling inline in GDScript via `add_theme_font_size_override` and inline `ColorRect.color = …`
- **No ornate framing** — every UI element is a flat `ColorRect`
- **Status effects communicate via text suffix** (`"HP 25/30 — burning · snared"`) and world particles only — no UI icon strip showing active statuses
- **No portrait, no XP/level, no buff bar, no minimap, no quest UI, no chat, no party UI**

The visible-quality cliff between current and the reference image is wide. But most of the gap is **frame styling + status icons + orbs** — those three changes alone close ~60% of the gap without needing the deferred systems (quests/chat/party) to exist.

This is **spec 35** — sequencing as a foundational HUD pass before any future content specs whose UX would benefit from a richer HUD seat.

## Goals (in priority order)

1. **Single UI_SCALE knob** — bump the whole HUD's rendered size with one constant. Already partially landed (`skill_bar.gd::UI_SCALE = 1.5`, same in `player_hud.gd` and `boss_bar.gd` per task #276). Spec formalizes this as a global `data/ui_config.gd` constant + Theme.tres so future HUD elements pick it up automatically.
2. **Ornate frame 9-slice** — a single `frame_gold.png` 9-slice texture authored once, applied to every HUD container via Theme. This is the move that binds 10 disparate UI islands into "one HUD" per the reference's visual consistency.
3. **Status icon strip** — solve "bleed/burn don't make sense" with 4-icon row above HP bar, slots light up when active, duration text under each. Plus floating mini-icons above affected enemies/dummy via Label3D.
4. **HP/Mana orbs** — replace `ColorRect` bars with circular orbs (`Sprite2D` + alpha-mask texture). The single biggest "this looks like a real game" change in the reference.
5. **Player portrait + level badge** — small painted bust top-left with name + level. Stub data for now (no progression spec yet; level = 1, name = "Ranger").
6. **Action bar expansion to 12 slots** (single row, not the reference's 24) — the rest of the row spawns as locked/empty slots ready for future ability specs. Keybinds 1234567890-=.
7. **Buff/duration timer row above the action bar** — same data path as the status strip but for *positive* effects (currently none in-game; layout-only stub).

## Non-goals (deferred to later specs)

- **Quest tracker UI** — needs a quest system spec first
- **Chat panel + tabs** — single-player game; no chat spec
- **Party panel** — single-player; no party spec
- **Minimap with region label** — needs an exploration / cartography spec (already in roadmap memory `project_arpg_roadmap`)
- **Inventory grid panel** — `scenes/InventoryPanel.tscn` skeleton exists; full UI is a separate spec
- **XP / level progression** — no leveling spec yet; portrait shows level 1 as a stub
- **Cooldown radial sweep** — current sweep is a fading alpha rect; a real radial fill (shader) is a polish followup
- **Animated portrait** — the reference's portrait is static; we ship static too. Future spec can add idle breathing
- **Per-ability painted icons** — current "Bow / Pow / Mlt / Snr" text labels stay v1. Painted icons are a separate art-authoring pass aligned with the MJ concept-art pipeline

## Phased roadmap

The full upscale ships in **4 phases**. Each phase is self-contained and reviewable.

### Phase 1 — Foundation (this spec's MVP)

**Files touched:** `scripts/data/ui_config.gd` (new), `scripts/skill_bar.gd`, `scripts/player_hud.gd`, `scripts/boss_bar.gd`, `assets/ui/theme.tres` (new), `assets/ui/frame_gold.png` (new authored asset), `scenes/PlayerHUD.tscn`.

- Promote per-script `UI_SCALE` constants into `scripts/data/ui_config.gd` static class — single source of truth
- Create `assets/ui/theme.tres` Theme resource with: base `Label` font size (multiplied by UI_SCALE), default `PanelContainer` stylebox using `frame_gold.png` as 9-slice, default `Button` stylebox same
- Author `assets/ui/frame_gold.png` — single 9-slice texture, ornate gold-leaf scrollwork on the four corners and edges, fully transparent center. Initial draft can be procedurally generated (Python + PIL geometric pattern); polish pass later replaces with hand-authored or AI-generated art
- Wire every existing HUD scene to use the Theme as their `theme` property (per-CanvasLayer or per-Control root)
- Acceptance: all three existing HUD elements (skill bar, HP bar, boss bar) now have visible ornate frames + use the Theme's font sizes. UI_SCALE 1.5 → everything 1.5× larger. Capture rig screenshots show the changes.

### Phase 2 — Status awareness

**Files touched:** `scripts/status_icon_strip.gd` (new), `scenes/StatusIconStrip.tscn` (new), `scripts/combatant.gd`, `scripts/player_controller.gd`, `assets/ui/status_{burn,bleed,snared,root}.png` (already generated in task #277, deferred from there).

- Build a 4-slot `StatusIconStrip` Control that lives above the HP bar (or beside, per design tweak)
- Each slot:
  - Background panel using the Theme's frame style
  - Status icon `TextureRect` (one of the 4 PNGs)
  - Duration label (small, bottom of slot, format `"4.2s"`)
  - Faded out (alpha 0.3) when status is not active; full color when active
  - Time-remaining sweep overlay (same pattern as skill_bar.gd's cooldown sweep)
- Bind to `player._statuses` dict — strip auto-updates each frame based on what's there
- **Plus mini status icons above enemies/dummy**: when a combatant has an active status, spawn a small `Label3D` (or `Sprite3D` if icon authoring lands first) above their hurtbox showing the status icon, color-matched to the status. Lifetime = status duration; auto-frees when status expires.
- Acceptance: PowerShot hitting the dummy → burn icon appears above the dummy AND lights up in the player's status strip (if it ever applies back, which spec 33a allows). Bleed-on-crit → bleed icon appears above the crit'd enemy AND on the player's strip if any reverse-flow ever applies. Each status reads "at a glance" without text.

### Phase 3 — HP/Mana orbs

**Files touched:** `scripts/player_hud.gd`, `scenes/PlayerHUD.tscn`, `assets/ui/orb_red.png` + `assets/ui/orb_blue.png` + `assets/ui/orb_fill_mask.png` (new authored assets), `assets/ui/orb_frame.png` (the gold-leaf scrollwork around the orbs from the reference image).

- Replace `HPRoot/Fill` (ColorRect bar) with a circular orb:
  - `Sprite2D` for the orb body (red sphere texture, ~120×120)
  - Overlay `Sprite2D` for the fill mask (alpha clip showing how full the orb is — driven by HP %)
  - `Sprite2D` frame overlay (gold ornate scrollwork from the reference)
  - `Label` numeric readout floating over the center ("4,850 / 4,850")
- Same pattern for Focus → blue mana orb on the right
- Anchored bottom-corners of the screen, with the action bar between them
- Acceptance: HP bar is now a glowing red orb. Focus bar is now a glowing blue orb. Each tracks the numeric value in real time. Visible gold scrollwork frames. The reference image's bottom-anchored layout is recognizable.

### Phase 4 — Action bar expansion

**Files touched:** `scripts/skill_bar.gd`, `scenes/SkillBar.tscn` (if not yet a .tscn), `assets/ui/slot_frame.png`.

- Expand from 4 slots to 12 slots in a single row (deferring the reference's 24-slot dual-row to a later content spec when 24 abilities exist)
- Slots 5–12 render as **locked empty** — same frame, dimmed background, no keybind label, faded "—" placeholder text
- All 12 slots use the Theme's frame style + the new gold scrollwork
- Flank menus (small icon column on each side of the orbs from the reference) — 2 buttons each side, placeholder content (settings gear, help icon, inventory icon, party icon). Open/close stubs that log "not implemented yet"
- Acceptance: HUD bottom row reads like the reference image's bottom row (orb · 12-slot bar · orb · flank menus). Keybinds 1-4 still fire skills; 5-= are visible but inert.

## Asset authoring requirements

| Asset | Format | Size | Authored where | Used by phase |
|---|---|---|---|---|
| `frame_gold.png` | PNG 9-slice | 192×192 (border ~32px) | Python+PIL initial draft → MJ-augmented refinement | 1 |
| `theme.tres` | Godot Theme | — | Godot editor (or text-edit .tres) | 1 |
| `status_{burn,bleed,snared,root}.png` | PNG | 96×96 each | Python+PIL (done — `assets/ui/status_*.png`) | 2 |
| `orb_red.png`, `orb_blue.png` | PNG | 256×256 each | Python+PIL initial draft → MJ-augmented refinement | 3 |
| `orb_fill_mask.png` | PNG (alpha only) | 256×256 | Python+PIL — radial gradient | 3 |
| `orb_frame.png` | PNG | 320×320 | Hand-authored or MJ-augmented | 3 |
| `slot_frame.png` | PNG 9-slice | 96×96 (border ~12px) | Python+PIL initial → MJ refinement | 4 |
| `portrait_ranger.png` | PNG | 192×192 | MJ-authored (use existing concept-art pipeline) | optional in Phase 3 |

The procedurally-generated initial drafts let each phase ship without blocking on art. MJ-augmented refinement is a polish pass that can happen between phases or after Phase 4.

## Tech decisions

- **CanvasLayer.transform vs Control.scale** — using `transform = Transform2D().scaled(...)` on each CanvasLayer (current approach for skill_bar + boss_bar). PlayerHUD scales sub-Controls individually to keep `Flash` + `Whiteout` viewport-sized. Same pattern through Phase 4.
- **9-slice via StyleBoxTexture** — the canonical Godot way to apply ornate frames at any size. `StyleBoxTexture` resource with margins; Theme references it as the default for `PanelContainer` and other Container types.
- **No global Theme override on the root viewport** — set Theme per-CanvasLayer to avoid affecting any future dialog/menu UI that might want a different style.
- **Status icons as Sprite3D vs Label3D vs CanvasLayer billboards** — Phase 2 uses Sprite3D (3D billboard, follows the combatant in world). Cleaner than Label3D since we have real icon textures. CanvasLayer billboards would require manual 3D→2D projection; not worth.
- **UI_SCALE source of truth** — `data/ui_config.gd` static class. Default `UI_SCALE := 1.5`. Future user-settings menu can bump this to 2.0 / 2.5 for accessibility.

## Files (Phase 1 only — later phases get their own file lists when executed)

| Path | Action |
|---|---|
| `scripts/data/ui_config.gd` | NEW — `class_name UIConfig` with `const UI_SCALE := 1.5` + theme path const + helper functions |
| `scripts/skill_bar.gd` | Read `UIConfig.UI_SCALE` instead of local constant; set `theme = UIConfig.HUD_THEME` |
| `scripts/player_hud.gd` | Same |
| `scripts/boss_bar.gd` | Same |
| `assets/ui/theme.tres` | NEW — Theme resource with Label/PanelContainer styleboxes referencing `frame_gold.png` |
| `assets/ui/frame_gold.png` + `.import` | NEW — 192×192 9-slice ornate frame texture |
| `tools/gen-ui-assets.py` | NEW — Python+PIL script that generates `frame_gold.png` (and Phase 3 orb textures later) procedurally; rerunnable for iteration |

## Eval coverage (Phase 1)

- **U1** — Smoke: `UIConfig.UI_SCALE` exists, defaults to 1.5, all 3 HUD scenes can `preload` and reference it
- **U2** — `assets/ui/theme.tres` loads cleanly via `preload` (catches malformed resource)
- **U3** — Skill bar renders 4 slots at the larger size in a capture; capture filesize > previous (more pixels of content)
- **U4** — Each HUD CanvasLayer has its Theme set after `_ready`

Phase 2+ get their own eval suites when executed.

## Risks / open questions

- **The 9-slice ornate frame is the art bottleneck.** Procedural Python can generate a baseline, but the reference image's gold scrollwork is hand-painted ornate metalwork — there's a fidelity floor below which the frame looks "trying too hard." Plan: ship Phase 1 with the procedural baseline, immediately follow with an MJ-augmented polish pass before Phase 2 starts.
- **Status icons need to read across the chunky-toon aesthetic.** Current procedurally-generated icons (`status_burn.png` etc, already authored in task #277) are flat-colored geometric shapes. The chunky-toon style from the MJ concept art has ink outlines + flat cel-shaded fills — Phase 2 should re-author the icons with that language. Possible MJ-augmented authoring run.
- **Phase 3 orbs might fight the chunky-toon style.** Glossy red/blue orbs are classic MMO style but visually different from the storybook ink-line aesthetic. Need a visual test: does a chunky-toon orb (ink outline + flat sphere fill) read as "an orb" or as "a circle with a frame"? Build a single test orb in Phase 3 before committing to the layout.
- **The reference image's "24-slot dual-row" hotbar requires 24 abilities.** gj26 has 4. Phase 4 caps at 12 with locked-empty slots. If future ability specs ramp to 12+, the dual-row layout can be revisited as Phase 5 of this spec.

## What to do next

When this spec is run via `/spec`:
1. Phase 1 → execute fully, capture screenshots
2. Brief check-in with user before Phase 2
3. Phase 2 → execute, capture, check-in
4. Phase 3 → check-in (orb style decision moment), then execute
5. Phase 4 → execute as time permits

The default `UI_SCALE = 1.5` is already shipped via task #276. Phase 1 builds on top of that.
