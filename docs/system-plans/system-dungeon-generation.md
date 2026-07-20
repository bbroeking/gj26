---
title: Dungeon Generation & Scoring
domain: Wayfinding & Dungeons
type: system
status: partial
effort: L
tags: [wayfinder, plan]
---

# Dungeon Generation & Scoring

> **2026-07-19 correction:** the production spatial pipeline is now scatter →
> separation → Delaunay → MST plus loops → topology semantics → carve/dress.
> The current cross-system gap and next implementation phases for creatures,
> gathering, and rewards are tracked in
> [dungeon-content-generation-manifests.md](dungeon-content-generation-manifests.md).

> The TinyKeep procgen pipeline (Delaunay → MST → loops → generate-and-test) is fully shipped and working; the next most valuable step is multi-floor descent and per-scope room-archetype expansion so each biome feels distinct.

## Current state

The core pipeline lives in `wyrd/scripts/dungeon_gen.gd` and its companion `wyrd/scripts/dungeon_score.gd`. All three stages are implemented and active:

**Generation** (`dungeon_gen.gd:139–277`): rooms are placed at random on a 48-tile grid (`GRID=48`, `ROOM_MIN=8`, `ROOM_MAX=14`), connected via Delaunay triangulation of room centers using `Geometry2D.triangulate_delaunay`, a Kruskal MST over those edges, then ~32 % of non-MST Delaunay edges re-added for loops (`LOOP_EDGE_FRACTION=0.32`). Three-wide corridors are carved along the final edge set (`CORRIDOR_HALF=1`). Boss room = BFS-farthest room from entry (`_farthest_room`); boss room is forced to a full rectangle for the arena seal.

**Room roles and themes** (`dungeon_gen.gd:682–781`): each room is tagged entrance / boss / rest / treasure / shrine / combat / setpiece in priority order. Seven themes exist — `tomb_hall`, `ossuary`, `archive`, `shrine`, `vault`, `antechamber`, `hearthroom` — with focal + satellite dressing rules. A `_pick_setpiece` step tags the largest eligible combat room with one of two authored ASCII templates (`wyrd/data/rooms/vault.txt`, `shrine.txt`), stamped by `_stamp_setpiece`. Interaction roles (treasure chest, Shrine.tscn, Hearth.tscn) are flagged on focal decor so `layout_loader.gd:591–617` can swap static GLBs for live scenes.

**Scoring** (`dungeon_score.gd:18–78`): five soft metrics (room count, floor ratio, corridor ratio, critical-path length, dead-end fraction) are averaged into a 0–1 total; connectivity is a hard gate that collapses total to `connectivity × 0.5` when any floor tile is unreachable. Generate-and-test runs up to `MAX_ATTEMPTS=12` seeds and returns the first that clears `SCORE_THRESHOLD=0.70` (or best-of-12 on failure). Score breakdown is printed on every load when `DEBUG_SCORE=true` (`layout_loader.gd:267–273`).

**Chart integration** (`dungeon_gen.gd:139–145`): `generate(seed, cfg)` accepts the chart's generation block — `grid`, `room_min/max`, `loop_fraction`, `scope`, `tier`, `affixes`, `boss_kind` — so chart affixes shape gather-node scatter (`GATHER_BY_AFFIX`), enemy density, and boss selection. Four biome scopes exist: `snug`, `hollow`, `briar_maze`, `crypt`; each has a spawn table in `layout_loader.gd:131–136`.

**What is absent or skeletal**: (1) multi-floor descent — `dungeon_gen.gd` has no staircase or floor-depth concept; spec 03 (`docs/specs/03-multi-floor-descent.md`) was written for the old three.js prototype and was never ported to Godot; (2) room archetypes are all crypt-flavored — `biome` is a spawn-table switch but room themes/decor don't vary by scope; (3) only two authored setpiece templates exist (`vault`, `shrine`); (4) generation knobs (GRID, ROOM_MIN/MAX, LOOP_EDGE_FRACTION) are not surfaced to the Inscribing Table UI as tunable chart parameters beyond what `run_cfg()` already plumbs; (5) the boss room is always `tomb_hall` theme regardless of scope.

## Gaps — what needs fleshing out

1. **[Blocker for deep-den chain] Multi-floor descent** — no staircase generation, no depth-seeded floor sequence, no depth display in HUD. The trophy chain (`snug → hollow → briar_maze → summit`) currently means four separate charts, not a connected descent. Spec 03 is the design blueprint; needs a Godot implementation.
2. **Per-scope room themes and decor** — all biomes share the seven crypt themes. A briar maze should have thorn-bower / root-tangle / glade archetypes; a snug cellar should have larder / wine-rack / root-cellar rooms. Room dressing is the primary source of biome identity.
3. **Set-piece library is two entries** — only `vault.txt` and `shrine.txt` exist. The generator picks one per run, so a player sees the same vault or shrine every time. Three to five more templates (crypt hall, ritual circle, collapsed passage, hedge circle, ambush crossing) would add real run-to-run variety.
4. **Generation tuning knobs not fully surfaced** — `run_cfg()` forwards `grid`, `room_min/max`, `loop_fraction`, `corridor_ratio_max` to the generator but there is no affix or chart property that sets them except the raw override dict. A "cramped" chart affix (small grid, many rooms) vs a "sprawling" chart affix (large grid, few rooms) would express meaningful layout variance from chart authorship.
5. **Boss room theme is always `tomb_hall`** — fixed at `dungeon_gen.gd:688–689` regardless of scope. Each scope should have its own boss room dressing (e.g. `hedge_glade` for briar_maze, `root_cellar_deep` for snug).
6. **Scoring tuning for non-crypt scopes** — score bands were tuned for crypt profile (48-grid, 8–14 rooms). Snug's smaller grid (`grid=24`, per `charts.gd:20–34`) uses the same bands and the gate silently degrades to best-of-12. `_score_cfg(cfg)` already reads overridable bands from the chart but the chart templates don't set them.
7. **No `test_wyrd_dungeon_scene.gd` coverage for multi-floor or scope variance** — current dungeon test exercises single-floor crypt only.

## Plan

### Phase 1 — Per-scope room themes and boss room dressing
*(Expansion/polish — generation core is complete)*

- Add a `SCOPE_THEMES` dict to `dungeon_gen.gd` mapping each scope to its allowed combat themes and boss-room theme; replace the hardcoded `COMBAT_THEMES` and the `"tomb_hall"` boss-room assignment in `_assign_rooms`.
- Add minimal new theme entries to `ROOM_THEMES` for at least two non-crypt scopes (snug: `root_cellar`, `wine_rack`; briar_maze: `thorn_bower`, `glade`). Each needs 2–3 decor kinds with corresponding GLB paths in `layout_loader.DECOR_MODEL` (or fall back to existing GLBs with different placement rules if new models aren't ready).
- Ensure `_dress_rooms` picks themes from the scope-appropriate pool; `_pick_setpiece` can skip if no scope-appropriate template exists rather than silently stamping a crypt vault into a briar maze.
- **DoD:** running a briar_maze chart produces rooms with `hedge`/`glade` themes in the score print; running a snug chart produces `root_cellar`/`wine_rack` rooms. Verified by adding a scope assertion to `test_wyrd_dungeon_scene.gd` (`WYRD_NO_SAVE=1 godot --headless ...`). All five suites green.
- **Effort: M**

### Phase 2 — Setpiece library expansion (5 templates)

- Author three to five new ASCII templates in `wyrd/data/rooms/`, one or two per scope: e.g. `crypt_hall.txt` (double-column hall), `ritual_circle.txt` (altar ring), `ambush_crossing.txt` (corridor-crossing chamber), `hedge_circle.txt` (briar-maze glade boss-vestibule), `larder.txt` (snug storage room).
- Add the new template names to `SETPIECES` (and scope-gated `SCOPE_SETPIECES` if scopes diverge). Ensure `_stamp_setpiece` does not overwrite typed-room interactables (already guarded by the `role != "combat"` check in `_pick_setpiece`).
- Add any new SETPIECE_DECOR letter mappings (`dungeon_gen.gd:108–111`) for glyphs used by the new templates.
- **DoD:** across 10 fresh seeds for each of crypt and briar_maze scopes, at least two distinct setpiece templates appear. Verified by printing `layout.rooms[i].setpiece` in `test_wyrd_dungeon_scene.gd` and asserting the distribution. All five suites green.
- **Effort: S**

### Phase 3 — Scope-aware score bands

- In `dungeon_gen.gd:_score_cfg`, populate default score-band overrides per scope if `cfg` doesn't specify them: snug gets tighter `room_count_min/max` (4–8) and narrower `floor_ratio` to match its smaller grid; briar_maze gets a higher `dead_end_max_frac` (0.55) to allow dead-end clearance rooms.
- Add scope to the score print line in `layout_loader.gd:267–273` so it reads `score=0.84 (scope=snug …)`.
- **DoD:** `test_wyrd_dungeon_scene.gd` generates a snug chart and asserts `score.total >= SCORE_THRESHOLD` (0.70) rather than the silent best-of-12 fallback. No false failures. All five suites green.
- **Effort: S**

### Phase 4 — Generation tuning knobs surfaced via chart affixes

- Define two layout-shaping affix families in `wyrd/data/charts.gd` (or `affixes.gd`):
  - `cramped` (good twin): sets `grid=32`, `room_max=10`, `room_count_max=9` — many small rooms, high density.
  - `sprawling` (bad twin): sets `grid=56`, `room_min=10`, `room_max=18`, `room_count_min=4` — wide open, few rooms.
- Wire them through `run_cfg()` → `dungeon_gen.generate(seed, cfg)` alongside the existing affix modifiers.
- Update `_score_cfg(cfg)` to shift bands when grid/room sizes shift, so `cramped` layouts aren't penalised by the default floor-ratio band.
- **DoD:** inscribing a `cramped` chart and opening `DEBUG_SCORE` shows a grid-32 run with 7–9 rooms; a `sprawling` chart shows a grid-56 run with 4–6 rooms. Room counts agree with the chart's cfg overrides. Verified by `test_wyrd_dungeon_scene.gd` asserting `layout.rooms.size()` is within the cfg band. Effort: S–M.
- **Effort: S–M**

### Phase 5 — Multi-floor descent (Deepening)

*(Large, self-contained; depends on no other phase here but pairs with [[system-charts-wayfinding]] chart-chain design)*

- Extend `dungeon_gen.generate(seed, cfg)` to accept `depth: int` (default 1). On floors 1…(N−1) of a multi-floor chart, add a `staircase: {x, y}` entry to the returned layout dict, placed on a floor tile adjacent to the exit that is not the boss room.
- Add a `FLOOR_DEPTH_MAX` const; the boss floor (depth = max) suppresses the staircase and gates the exit waystone on boss death (existing behavior).
- In `layout_loader.gd:_build_exit_waystone`, check `layout.staircase`; if present, instantiate a `StaircaseNode` scene at that tile instead of (or alongside) the exit waystone. `StaircaseNode` emits `descended(next_seed)` which `game.gd` handles by reloading World.tscn with the new seed and depth.
- Seed each floor deterministically: `floor_seed = base_seed * 31 + depth` (mirrors the spec-03 pattern).
- HUD: add a `depth` readout to `player_hud.gd` visible only during a multi-floor chart run.
- Enemy difficulty follows existing tier-scaling: `den_level` in `run_cfg()` increments with depth (tie to ADR 0013 band: every 2 floors = +1 tier).
- **DoD:** entering a multi-floor chart, reaching the staircase, and descending produces a new floor with `depth+1` shown in HUD; the same `base_seed` always produces the same sequence; the boss floor (depth = max) has no staircase; all five suites green; `test_wyrd_dungeon_scene.gd` generates a depth-3 layout and asserts staircase presence on floors 1–2 and absence on floor 3. **Effort: L.**
- **Effort: L**

## Dependencies & links

- [[system-charts-wayfinding]] — the chart's `run_cfg()` dict is the primary input to `generate()`; scope, tier, boss_kind, and all affix modifiers flow from here. Phase 4 tuning knobs and Phase 5 multi-floor depth need new chart properties added there first.
- [[system-chart-affixes]] — chart affixes (`GATHER_BY_AFFIX`, `tyrannical`, `festival_pace`, `cramped`/`sprawling`) shape density, gather nodes, and layout parameters. Phase 4 adds two new affix families here.
- [[system-biomes-decor]] — Phase 1 (per-scope room themes) and Phase 2 (setpiece templates) both depend on biome-side decor assets (GLB paths, breakable tables) being in sync with what `DECOR_MODEL` and `DECOR_BREAKABLE` in `layout_loader.gd` expose.
- [[system-combatant-ai]] — multi-floor depth scaling (Phase 5) uses `den_level` via ADR 0013 bands; the combatant's HP/damage multipliers (`_hp_mult`, `_dmg_mult`) are already computed from `den_level` in `layout_loader._read_chart_modifiers()`.
- [[system-bosses]] — boss room selection (`bossKind` from chart `cfg`) and arena-gate logic in `layout_loader.gd:643–709` depend on the procgen boss-room placement; Phase 1 adds per-scope boss-room dressing.
- [[system-elites]] — elite spawning in `layout_loader._build_enemies()` uses `room_depths` from the generator's BFS output. Phase 5 multi-floor depth needs to preserve the BFS depth array per floor.
- [[system-interactables]] — typed-room interactables (Chest, Shrine, Hearth) are instantiated by `layout_loader._build_interactable()` based on `interact_role` flags set in `dungeon_gen._dress_rooms()`; any new typed rooms added in Phase 1 need matching scenes.
- [[system-save-load]] — multi-floor descent (Phase 5) requires arc state (`base_seed`, `depth`, `scope`) to survive scene reloads; this is not yet a save concern (in-memory run state) but must not overwrite the real save path (`WYRD_NO_SAVE=1`).
- [[system-hud]] — Phase 5 adds a depth readout; wired into `player_hud.gd`.
- Plan.md Part B / Phase B6 (inscribe ritual feel) — the chart's visible affixes and the dungeon-scope label shown at inscribe time overlap with how scope/depth are surfaced. Do not re-plan the inscription UX here; B6 owns it.

## Verification

**Each phase uses `WYRD_NO_SAVE=1` and runs from `wyrd/`.**

- **Phase 1:** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` with a new assertion that `layout.rooms` contains at least one room whose `theme` is scope-appropriate (e.g. `root_cellar` for a snug run). Also a visual check: run `WYRD_SHOT=1 godot --path .` with a briar_maze chart and confirm room decor diverges from crypt defaults in the screenshot.
- **Phase 2:** `test_wyrd_dungeon_scene.gd` — generate 10 seeds for each of two scopes; assert `layout.rooms.filter(r -> r.get("role") == "setpiece").map(r -> r.setpiece)` contains at least two distinct values across the set.
- **Phase 3:** `test_wyrd_dungeon_scene.gd` — generate a snug chart (override `cfg.grid=24`, `cfg.scope="snug"`) and assert `score.total >= 0.70`. Before this fix the snug run reliably hits best-of-12.
- **Phase 4:** `test_wyrd_dungeon_scene.gd` — generate a `cramped` chart and assert `layout.rooms.size() >= 7`; generate a `sprawling` chart and assert `layout.rooms.size() <= 6`. `DEBUG_SCORE` print shows grid size matches cfg.
- **Phase 5:** extend `test_wyrd_dungeon_scene.gd` (or a new `test_wyrd_descent.gd`) — generate a depth-3 run using `base_seed=12345`; assert staircase exists on floors 1 and 2, is absent on floor 3; assert floor 2's `layout.seed == 12345 * 31 + 2`; assert `layout.rooms` is non-empty on each floor. All five existing suites must stay green.

## Open questions

1. **Multi-floor chart shape** — does Phase 5 add depth as a property of specific chart templates (e.g. `summit` is always 3 floors) or as a generic `floor_count` knob any chart can set? The summit already has `"scope": "crypt"` in `charts.gd:63`; a dedicated `floor_count` field there is the cleaner path.
2. **Between-floor HP** — spec 03 recommends no mid-arc healing; the Hearth rest room complicates this. Decision needed before Phase 5 wire-up: does the rest room heal between floors or is it restricted to floor-end?
3. **Scope-gated setpiece templates** — Phase 2 can share templates across scopes (a `vault` room reads fine in any biome) or gate them by scope. Gate-by-scope produces more identity but needs more templates; shared works immediately. Recommend shared for Phase 2, gate-by-scope in a follow-up.
