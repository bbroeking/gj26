---
title: Town Hub (Chartmakers Yard)
domain: World & Interactables
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Town Hub (Chartmakers Yard)

> The 40x40 clearing is structurally complete — all stations, NPCs, and dressing are placed — but the hub lacks an arrival beat, a Living Atlas board, co-op spawn polish, and the ambient life that makes returning from a delve feel like coming home (Plan.md Part B / Phase B7).

## Current state

`wyrd/scripts/town.gd` builds the yard procedurally in `_ready`: ground (`PlaneMesh` + `TownEnvironment.ground_material()` noise shader), invisible boundary walls, five core stations (Wayfinder NPC / Mara at `(20,0,17)`, Inscribing Table at `(15.5,0,15)`, Waystone at `(27,0,12)`, Hod the Vendor near the forge, Quill the Herbalist at `(11,0,29.5)`), two craft stations (cookfire, anvil), a distillation still, six forage herb patches (regrowth enabled, `respawn_sec=20`), three ore rocks (copper×2, bogiron×1, `respawn_sec=40`), three log piles (`respawn_sec=30`), and a bittergrass tier-locked patch (town.gd:286–315). `TownEnvironment` adds dirt paths, a 34-oak treeline ring, 700 MultiMesh grass tufts, scatter dressing (lanterns, bushes, brambles, drying rack, practice dummy, fence runs), and wildflower clumps (town_environment.gd:37–259). All GLB models are live (cottage, forge, tower, well, signpost, stall). The town_theme.mp3 plays on `_ready` via `Sfx.music("town_theme")` (town.gd:62–64). Co-op: `NetGame.setup_scene(self)` replaces the baked single-player body with per-peer `NetPlayer<id>` nodes offset 1.2m apart along X (net_game.gd:202–218). Gather node regrowth already uses an overshoot `TRANS_BACK` tween (gather_node.gd:368–370) — the grow-in animation exists but fires silently (no SFX, no ambient swell). No Living Atlas / chart board exists; no arrival beat plays when returning from a delve.

## Gaps — what needs fleshing out

- **[BLOCKER for B7] No arrival beat** — `game.gd:return_to_town` calls `change_scene_to_file` with no signal or flag for the town to read; the town `_ready` fires music immediately but has no camera ease-in or ambient swell distinct from a cold boot. Plan.md B7 owns the full ritual; this note tracks the wiring point in `town.gd`.
- **No Living Atlas / chart board** — no in-world object reacts when a den tier unlocks (trophy chain) or the Summit is cleared; `game.summit_cleared` and `game.den_tiers_unlocked` have no town-side visual. Plan.md B7 names the board as "glow + a stamp" but no implementation exists anywhere.
- **Co-op spawn spread is naive** — `_spawn_player` offsets peers by `1.2 * index` along world +X (net_game.gd:207–208); if two peers arrive simultaneously they overlap for one frame, and the offset direction ignores terrain. No `net_spawn` override is set on the Town scene.
- **Ambient town SFX stubs missing** — `Sfx` has `town_theme` music and `play()` stubs but no keys for town-specific sounds (birdsong, fire crackle, smithing ambient, wind-in-trees). Plan.md B0 must register these; they are not yet stubbed (sfx.gd:44).
- **Regrowth animation fires silently** — `gather_node._regrow()` already tweens scale with `TRANS_BACK` (gather_node.gd:368–370) but plays no grow-in SFX and emits no signal `town.gd` can listen to for a pop effect. The Plan.md B7 "sprout grows in" is half-done visually.
- **No `net_spawn` export on the Town scene** — `_spawn_pos` falls through to `Vector3(20,0,26)` hardcoded (net_game.gd:218) because Town.tscn exposes `PLAYER_SPAWN` as a const not an exported var; a class-level `var net_spawn` would let the host offset guests into a small fan.
- **Quill has no tonic-sell / still workflow hooked** — `quill_npc.gd` opens a dialog-only panel; the still craft station is placed but the herbalist's "buy a tonic" flow (from the prototype's `npcs.js`) is not wired to a vendor-style panel. Low priority until Wildcraft skills land.

## Plan

### Phase 1 — Arrival wiring & ambient SFX stubs (foundation)
Pre-requisite for B7; also unblocks Phase 2. Aligns with Plan.md Phase B0.

- In `game.gd:return_to_town`, set a one-frame autoload flag before `change_scene_to_file` (e.g. `game._returning_from_delve = true`); town `_ready` reads and clears it.
- In `town.gd:_ready`, if `_returning_from_delve`: delay the music call by 0.3s and fire a placeholder `sfx.play("town_arrival_swell")` (silent stub OK until generated). Camera ease-in: emit a signal to the `CameraRig` to ease from a zoomed-out position back to tracking distance over 1.2s (reuse the existing `tween_spring` in `camera_rig.gd`).
- Register ambient SFX stubs in `sfx.gd`: `"town_arrival_swell"`, `"town_ambient_birds"`, `"town_fire_crackle"`, `"regrow_pop"`. Silent stubs so later audio generation just drops an .mp3 in `audio/`.
- Add `var net_spawn: Vector3` (exported) to `town.gd` and assign it `PLAYER_SPAWN + Vector3(0, 0, 1.0)` so `_spawn_pos` in `net_game.gd` picks it up and peers spawn fanned slightly behind the solo spawn.
- **DoD:** cold-boot plays music immediately; return-from-delve delays 0.3s and fires swell (silent stub is fine); `WYRD_NET=host godot --path wyrd` with two clients has peers spawn without overlap; four test suites green (`WYRD_NO_SAVE=1 cd wyrd`).
- **Effort: S**

### Phase 2 — Regrowth pop + ambient life (Plan.md B7 town side)
Implements the visible half of Plan.md Phase B7 that lives in `town.gd` / `gather_node.gd`.

- Add a `regrew` signal to `gather_node.gd`; emit it at the top of `_regrow()` before the tween. Connect in `town.gd:_place_herb_patches` (and ore/log placement loops) to a handler that calls `sfx.play("regrow_pop")` and drops a 0.4s ember/leaf mote burst (≤6 cheap `MeshInstance3D` back-out tweens, freed on finish — the B2 mote pattern).
- Add `var _ambient_timer: float` to `town.gd:_process`; every 8–15s (jittered, seeded from `rng.seed=26`) call `sfx.play("town_ambient_birds", 0.12)` to layer a low-volume ambient. Fire `"town_fire_crackle"` on a 6-10s timer parented to the cookfire station.
- For the Living Atlas board: place a simple `MeshInstance3D` (parchment plane quad, 0.8×0.6m) on the Chartmaker Tower's south wall at approx `(20.5, 1.6, 8.0)`. On `_ready`, read `game.den_tiers_unlocked` and set material emissive per unlocked tier. Connect `game.leveled_up` (carto trade) and `game.summit_cleared` to a `_on_board_update()` that pulses emissive energy 0→2→0.6 over 0.6s with a `TRANS_BACK` tween.
- **DoD:** a depleted herb patch grows back visibly (overshoot scale, existing) and plays the pop SFX; ambient bird sound fires at least once per 20s in-town; the atlas board lights a new entry when a den tier unlocks in a session. Verified by `WYRD_SHOT=1` screenshot of a mid-grow node and a log assert in `_on_board_update`. Four test suites stay green.
- **Effort: M**

### Phase 3 — Co-op town polish & Quill tonic shelf (nice-to-have)
Lower priority; wait for Wildcraft trade (ADR 0005) and multiplayer Phase C.

- Replace the hard `1.2 * index` X-spread in `net_game.gd:_spawn_player` with a fan: use `Vector2(cos, sin)` with index-spread angles × 1.5m radius so three players form a tight arc facing the Wayfinder rather than a line toward the treeline.
- When `NetGame.roster_changed` fires in `town.gd`, run a brief "campfire warmth" pulse on the plaza lanterns (energy 2→3.5→2 over 0.4s) to acknowledge a peer joining — cosmetic, local only (aligns with B-1 co-op rule: cosmetics are local).
- Wire Quill's `interact()` to open a read-only `VendorPanel` (reuse `vendor_panel.gd`, a different stock array) for tonic buffs; only show if `game.trade_level("wilds") >= 3` (mirrors the bittergrass lock).
- **DoD:** three-player session spawns in an arc, not a line; a new peer joining pulses the lanterns once; Quill opens her tonic shelf at Wildcraft 3+. Verified by a two-client smoke test (`WYRD_NET=host`/`join`) and a screenshot of the spawn spread.
- **Effort: S–M**

## Dependencies & links

- [[system-interactables]] — `Interactable` base class that all four town stations (`WayfinderNpc`, `PortalWaystone`, `InscribingTable`, `VendorNpc`, `QuillNpc`) extend; any new interactable in the yard must follow its prompt/collision pattern.
- [[system-npc-story-tutorial]] — Mara Linnet's dialog tree (tutorial steps 0–7 in `wayfinder_npc.gd`) is the primary town narrative; the plan here must not break tutorial step sequencing.
- [[system-charts-wayfinding]] — the Waystone and Inscribing Table are the town's Wayfinding entry points; the Living Atlas board visualizes the den-tier chain that charts unlock.
- [[system-gathering]] — herb/ore/log patches with regrowth timers are the town's only gather verbs; Phase 2 adds the grow-in pop signal.
- [[system-crafting]] — cookfire, anvil, and still stations are placed by `town.gd`; Phase B5 (craft station reactions, Plan.md) lives in `craft_station.gd` but the station positions and IDs originate here.
- [[system-economy]] — Hod's vendor position and stall GLB are placed in `_place_stations` / `_place_dressing`; any new vendor NPC (Quill Phase 3) reuses `VendorScript`.
- [[system-multiplayer-netcode]] — co-op spawn spread and the `net_spawn` export (Phase 1) directly touch `net_game.gd:_spawn_player` / `_spawn_pos`; changes here must keep the five-suite gate green.
- [[system-audio-music]] — `sfx.gd` is the single registration point for all new ambient/arrival SFX keys; Phase 1 stubs go there.
- [[system-camera]] — Phase 1's arrival ease-in reuses `camera_rig.gd`'s existing tween spring; must not break the FATE camera tracking during normal play.
- **Plan.md Part B / Phase B7** — the canonical spec for the arrival beat, regrowth grow-in, and atlas board. This note tracks the `town.gd` wiring and new signals; do not duplicate Plan.md's feel constants — those live in the forthcoming `data/feel.gd` (Plan.md B0).
- **Plan.md Part B / Phase B0** — `data/feel.gd` and SFX stub registration must land before Phase 2 motes/timers so town ambient constants live in one tuning block.

## Verification

- **Phase 1:** `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_transitions.gd` (scene change to town) stays green; `WYRD_NET=host godot --path wyrd` + a second client spawns without node-name clash (check the `[net] spawned` print lines, not just visual); `WYRD_SHOT=1 godot --path wyrd` screenshot shows music fires (logprint the swell key).
- **Phase 2:** `WYRD_SHOT=1 godot --path wyrd` timed screenshot at 25s (after one herb respawn) captures the grow-in mid-tween (node scale < 1); add a `print("[town] board updated: %s" % tier)` in `_on_board_update` and grep the output after a test run that grants carto XP to a new tier level.
- **Phase 3:** run the two-process smoke test (`WYRD_NET_RUN=5 WYRD_NET=host godot --path wyrd` + `WYRD_NET=join:localhost godot --path wyrd`) and assert no overlap warning in the log; screenshot the spawn arc.
- All phases: four headless suites (`test_wyrd_loop`, `test_wyrd_dungeon_scene`, `test_wyrd_transitions`, `test_skills`) must stay green with `WYRD_NO_SAVE=1` from `wyrd/`.

## Open questions

- Should the Living Atlas board be an `Interactable` (E to inspect unlocked dens, a lore-flavored panel) or purely ambient decoration? Making it interactable aligns with the chart-board design intent but adds a UI panel to scope.
- Does the arrival beat camera ease-in trigger on every delve return, or only the first return of a session? (Repeated returns could feel intrusive; a `_arrived_once` bool would suppress it after the first.)
- Quill's tonic shelf (Phase 3): should she sell pre-made tonics for gold (simpler, needs economy balance) or only accept wild herbs via a craft-panel flow (deeper, but duplicates the still)?
