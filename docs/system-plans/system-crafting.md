---
title: Crafting & Stations
domain: Gather · Craft · Economy
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Crafting & Stations

> Three functional stations (cookfire / forge / still), 29 recipes, and a complete `game.craft()` pipeline — the next work is the still's missing buff HUD, a `react()` hook so stations respond visually on success (Plan.md B5), and a dedicated SFX for the still.

## Current state

All three stations are spawned in town (`wyrd/scripts/town.gd:239–256`) with procedural primitive bodies and warm OmniLight3D glows. `CraftStation.interact()` (`wyrd/scripts/craft_station.gd:39–46`) opens `craft_panel.gd` (the recipe list UI) for cookfire and forge, and also for the still (same panel, different `station_id`). `game.craft()` (`wyrd/scripts/game.gd:355–412`) validates station membership, trade-level gate, affordability, pack space (for gear yields), then spends materials, awards XP, and plays SFX — the full happy path is solid. Perk procs are also wired: "Second Pour" for wilds station crafts (`game.gd:387–391`) and "Smith's Thrift" refund for forge (`game.gd:393–406`).

The recipe dataset in `wyrd/data/crafting.gd` defines 29 recipes across the three stations: 5 cookfire draughts (lv 1–15), 5 still tonics + 5 buff draughts (lv 3–16), and 24 forge recipes covering bars, tools, armor, and bows across 4 ore tiers (`crafting.gd:10–262`). `BUFF_DRAUGHTS` and `DRAUGHT_ORDER` are defined and `quaff_buff_draught()` + `apply_buff()` are implemented (`game.gd:492–531`). The `buffs_changed` signal exists (`game.gd:496`) but is **never connected to any HUD element** — active buff timers are invisible to the player. The still's `interact()` opens the generic `craft_panel.gd`, which lists recipes but shows no buff-timer readout.

SFX coverage: cookfire uses `craft_cook.mp3`, forge uses `craft_smith.mp3` (`game.gd:409`). The still falls through the `else` branch and also plays `craft_smith` — no dedicated brew SFX. Stations do nothing visually on a successful craft (the "station body does nothing" gap noted at Plan.md B-0).

The pre-filled status guess of "partial" is correct: structure and happy path exist, but the still's buff UI is missing and station-reaction feel (Plan.md B5) is unimplemented.

## Gaps — what needs fleshing out

- **[BLOCKER — still usability]** Active buff timers never shown in HUD. `buffs_changed` signal is emitted but no subscriber exists. Players brew tonics with no feedback that a buff is active, stacking, or expiring.
- **[BLOCKER — still SFX]** Still uses `craft_smith` SFX — a clang is wrong for a herbalist's distillery. Needs a dedicated `craft_still` key registered in `sfx.gd` and an ElevenLabs-generated file.
- **[Plan.md B5 gap]** `CraftStation` has no `react()` method. On a successful `craft()`, `game.gd` does not look up the active station and call any in-world reaction. Each station has a distinct OmniLight and prim body that could animate, but nothing does.
- **[Stretch — recipe count vs spec]** `crafting.gd` header references "~43 recipes" but the file has 29. The 14-recipe gap is likely the remaining `spec 45-earth/wilds` deep-tier recipes that were planned but not yet added.
- **Ink-discovery gating in the bench** is implemented in `crafting_bench.gd` (pot + codex, `crafting_bench.gd:133–172`), not in the crafting stations — this is correct by design (inks are a chart ingredient, not a station output). No gap here.
- **craft-station reaction feel** — owned entirely by Plan.md B5; do not re-plan here.

## Plan

### Phase 1 — Still buff HUD (the missing feedback loop)

The still is fully brewable but the player has no way to know whether a tonic is active or how long it has left. This is a usability gap, not a feel gap.

- In `player_hud.gd`, connect to `Game.buffs_changed` on `_ready` (after the `Game` node is confirmed live).
- Add a `_draw_buff_row()` helper that reads `game.buffs` (a `Dictionary` of `{id: {stat, value, left}}`) and renders one compact pill per active buff: tonic icon (`GatherDefs.material_icon(id)`), readable name, and a countdown bar whose width maps to `left / duration`. Draw using the existing canvas-draw pattern (preload nothing inside `_draw()` — use the `GatherDefs.material_icon()` string glyph, not a texture).
- Position the buff row above the skill bar (or below the globe gauges) — measure against the `_hp_globe` and `_focus_globe` anchor constants already in `player_hud.gd:50–55`.
- Redraw only when `buffs_changed` fires or `_process` ticks (throttle to every 0.25 s to avoid per-frame redraw while a tonic is draining).
- **DoD:** brew a `quickroot_tonic` at Quill's still; the buff pill appears immediately, its bar drains over 90 s, and it disappears on expiry. No pill shown when `buffs` is empty. Verified via `WYRD_SHOT=1` screenshot and manual playtest (`godot --path wyrd`).
- **Effort:** S

### Phase 2 — Dedicated still SFX

- Add `"craft_still"` key to `sfx.gd`'s sound registry (same pattern as `craft_cook` / `craft_smith`).
- Generate a bubbling-distillery SFX via `tools/generate_audio.py` (ElevenLabs pipeline); save to `wyrd/audio/craft_still.mp3`.
- Change `game.gd:409` from the two-branch conditional to a three-way match:
  ```
  "cookfire" -> sfx.play("craft_cook")
  "forge"    -> sfx.play("craft_smith")
  "still"    -> sfx.play("craft_still")
  ```
- **DoD:** brewing at Quill's still plays a distinct (non-clang) brew SFX. Cookfire and forge SFX unchanged. Verified manually.
- **Effort:** S

### Phase 3 — Station `react()` hook (Plan.md B5 implementation)

This phase implements exactly what Plan.md B5 specifies. Do not diverge from that spec — it is the authoritative design for this work. Cross-reference and follow it.

- Add `react()` to `CraftStation` (`craft_station.gd`). Route `game.craft()` success to find the active station by `station_id` and call `react()` — mirror how `game.gd` already calls `sfx.play()` immediately after the craft succeeds (line 407–409).
- Station-specific reactions (from Plan.md B5):
  - **cookfire** — ember OmniLight energy pulse (1.6 → 3.2 → 1.6 over ~0.4 s via `Tween`), flame-colored motes rising from the pot position (cap ≤6, short-lived `MeshInstance3D`, free on finish).
  - **forge/anvil** — spark burst off the anvil body (reuse mote pattern, ember-orange), a quick scale-punch on the anvil `_prim` (1.0 → 1.08 → 1.0), glow flash.
  - **still** — green vapor puff (the `glow` OmniLight pulse to green-lit, ≤4 motes rising off the catch-flask position).
- All constants read from `data/feel.gd` once that file exists (Plan.md B0, must ship first — add as a dependency). Until B0 ships, inline the tuning values with a `# TODO: move to Feel.*` comment.
- Co-op: reactions are cosmetic and LOCAL — no RPC, no host gate (Plan.md B-1 rule).
- Shake-toggle aware: if `game.reduce_shake` is true, skip the micro-flash on the forge (light flash counts as visual noise).
- **DoD:** each station has a visible, distinct in-world reaction on a successful craft; `react()` is **never** called on a failed/gated craft attempt. Logic test: mock a `CraftStation` node, call `game.craft()` with valid then invalid inputs, assert `react()` call count is 1 vs 0. Gate green.
- **Effort:** M
- **Dependency:** Plan.md B0 (`feel.gd` + SFX stubs) must land before this phase; the mote pattern is shared with Plan.md B2 (harvest pop).

### Phase 4 — Recipe depth expansion (deep-tier fill-out)

The spec notes ~43 recipes; 29 exist. This is an expansion pass, not a blocker.

- Audit the gap: compare `crafting.gd:RECIPES` against the `spec 45-earth` and `spec 45-wilds` comments already in the file. Add the ~14 missing deep-tier recipes following the existing pattern (req_lv, xp, inputs, yields, desc).
- Verify economy gate: new gear-yield recipes must pass the sell-back test noted at `crafting.gd:163` (selling smithed gear back to Hod always loses gold vs buying inputs). The economy autoload test suite covers this gate.
- The cookfire `DRAUGHT_ORDER` and still `BUFF_DRAUGHT_ORDER` arrays must be updated if new items are added — quaff logic iterates these arrays in order (`game.gd:483`, `game.gd:527`).
- **DoD:** `crafting.gd:RECIPES` has ≥43 entries; all new recipes appear in their station's `"recipes"` array; `test_wyrd_loop.gd` gate stays green; economy sell-back test passes.
- **Effort:** S–M (mostly data authoring, one loop-test assertion per new tier)

## Dependencies & links

- [[system-gathering]] — gather nodes produce the raw materials all station recipes consume; tier-2/3 materials (palechalk, starsilver, hedgesteel) gate the deep forge recipes.
- [[system-trades-progression]] — `game.trade_lv("wilds")` and `game.trade_lv("earth")` are the level gates in `game.craft()`; the perk system (Second Pour, Smith's Thrift) sits on the same trade ladder.
- [[system-economy]] — forge sell-back economy gate is tested in the economy suite; new recipes in Phase 4 must not crack that gate.
- [[system-items-affixes]] — forge `yields_item` recipes call `ItemsData.make_item(kind, rarity)` and place the result in the Tetris pack; affix rolls happen at that point.
- [[system-inventory-equipment]] — `inventory.find_first_fit()` and `inventory.try_place()` are called inside `game.craft()` for gear yields; pack-full guard is already implemented.
- [[system-charts-wayfinding]] — `crafting_bench.gd` (the Inscribing Table) is a separate panel that handles chart inscription, not station crafting; they share `Game` as the single mutation point but are independent panels.
- [[system-hud]] — Phase 1 (buff HUD) adds a buff-pill row to `player_hud.gd`; the globe gauge layout and toast stack are the siblings to position against.
- [[system-audio-music]] — Phase 2 (`craft_still` SFX) follows the ElevenLabs pipeline in `tools/generate_audio.py`; SFX keys are registered in `sfx.gd`.
- [[system-combat-juice-vfx]] — Phase 3 mote pattern (`MeshInstance3D` + tween, cap ≤8) is the same toolkit used for combat VFX and Plan.md B2 harvest pop; reuse, don't rebuild.
- **Plan.md Part B / Phase B5** — craft station reaction (Phase 3 here) is *owned* by Plan.md B5. This note does not re-plan that work; it records the integration hook (`react()` method on `CraftStation`, called from `game.craft()` success path) and notes Plan.md B0 as a prerequisite. Follow Plan.md B5 spec for all reaction details.
- **Plan.md Part B / Phase B0** — `feel.gd` tunables file must land before Phase 3's mote intensities can be driven from a single tuning block.

## Verification

- **Phase 1:** `WYRD_NO_SAVE=1 godot --path wyrd` → brew `quickroot_tonic` at Quill's still → buff pill appears on HUD → wait 90 s → pill disappears. `WYRD_SHOT=1` screenshot to capture pill visible state. No headless suite changes needed (buff display is cosmetic-only).
- **Phase 2:** Launch game, brew at each of the three stations, confirm distinct SFX per station. No headless gate impact.
- **Phase 3:** Add one logic assertion to `test_wyrd_loop.gd`: `game.craft("cookfire", "hearth_draught")` with valid materials → `react_call_count == 1`; repeat with missing materials → `react_call_count == 0`. All four headless suites stay green (`WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd`).
- **Phase 4:** All four suites stay green after recipe additions. Spot-check sell-back economy test passes. Visual check: open forge panel and confirm new recipes appear at the correct level gates.

## Open questions

- **Buff persistence across scene changes:** `buffs` in `game.gd` is runtime-only (`crafting.gd:278` comment confirms "runtime-only (a sip doesn't outlive the session)"). Is this intentional for the 90 s tonic duration, or should active buffs survive a Town→Dungeon transition? If the player brews before delving, the tonic should arguably still be active inside the dungeon.
- **Recipe count target:** The header in `crafting.gd:7` says "~43 recipes." Confirm whether the gap (29 vs 43) should be filled now (Phase 4) or is explicitly deferred until after the next biome/spec pass adds new ore tiers.
