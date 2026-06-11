# 25 — Interesting procedural dungeons

> **Outcome**: gj26's "correct but bland" rooms-and-corridors generator becomes one that makes *characterful* crypts — rooms that read as **places**, varied spaces, hand-authored setpieces, a layout worth exploring — all still fully automated. Built in five checkpointed phases.

## Why

The generator produces connected rooms and corridors with random decor scatter — structurally valid, but every dungeon is a grey grid that plays the same. Research (specs grill, this conversation): *interesting ≠ more random.* Diablo injects authored intent via hand-built room **chunks**; Unexplored "feels varied because of the amount of authored **rules**." gj26 has neither. This spec adds both — a rules layer for the bulk, authored setpieces for the memorable rooms (the **hybrid** route, grill-confirmed).

## Approach — five phases, each independently shippable

Each phase boots clean, keeps `test_combat` 20/20 + `test_movement` 6/6, keeps the crypt scoring well, and gets a screenshot checkpoint before the next.

---

### Phase 1 — Room roles + themed dressing  *(the first step — everything keys off this)*

The room model gains a **role** and a **theme**; decor is placed *by rule per room* instead of randomly scattered.

- **Roles** (drive enemy density + which themes are eligible): `entrance` · `combat` · `treasure` · `shrine` · `boss` (already special).
- **Themes** (drive set-dressing — Bramblewood crypt, storybook not grim): `tomb_hall` (sarcophagi in rows) · `ossuary` (bones/skulls clustered) · `archive` (bookshelves along walls) · `overgrown` (the Hedgemother's creep) · `shrine` (altar centred + braziers) · `vault` (chest + pottery + columns) · `antechamber` (sparse — columns, braziers).
- **Dressing rules** — each theme has a placement rule: *along-walls* (bookshelves, sarcophagi), *centre* (altar, chest), *clustered* (bones), *corners* (columns, braziers). Replaces the random `decor` scatter.
- **Wire the unused crypt decor GLBs** — `altar`, `brazier`, `chest`, `column`, `pottery`, `rug`, `sarcophagus` are in `models/` but not in `layout_loader.DECOR_MODEL`. Add them (+ collider sizes).
- `dungeon_gen` assigns role+theme per room; `layout_loader._build_decor` consumes them.

**Files:** `dungeon_gen.gd` (role/theme assignment), `layout_loader.gd` (themed dressing, more decor GLBs).
**Acceptance:** rooms visibly read as different *kinds* of place; no two adjacent rooms feel identical; decor sits where it belongs (shelves on walls, altars centred).

### Phase 2 — Varied room shapes

Rooms stop being all rectangles.

- Add shape variants to the room-carve step: **rectangular** (default), **circular** (carve a disc), **irregular** (rectangle with corners bitten off, or two overlapped rects), **great hall** (an oversized room — rarer).
- Shape is chosen per room, weighted; the boss/setpiece rooms keep controlled shapes.
- The scorer + navmesh already work off the floor grid — no change needed there.

**Files:** `dungeon_gen.gd`.
**Acceptance:** a generated crypt shows a mix of room shapes; circular/irregular rooms read clearly.

### Phase 3 — Authored setpieces (ASCII templates)

A handful of hand-built rooms, authored as text files.

- New `godot/data/rooms/*.txt` — each an ASCII grid (`W` wall · `F` floor · `D` door · markers for decor/enemy/loot anchors).
- A `dungeon_gen` routine: stamp a template into the grid at a valid spot, register its `D` tiles as corridor connection points so the graph wires to it.
- **2–3 setpieces** for v1: a **treasure vault**, a **shrine**, an **ambush gallery** (a long pillared hall). Author them Bramblewood-flavoured.
- The boss room stays code (it needs logic — seal gates, phases).

**Files:** `dungeon_gen.gd` (the stamp + connect routine), `godot/data/rooms/*.txt` (new), possibly `layout_loader.gd` (read template decor/enemy markers).
**Acceptance:** at least one authored setpiece appears per run, correctly connected, recognisably hand-designed.

### Phase 4 — Loops + optional side-rooms

The room graph gains real branches.

- Raise the loop-edge fraction so dungeons have genuine alternate routes (not a near-tree).
- Tag dead-end rooms (single connection) as **optional** → give them the `treasure` role (a reward for detouring).
- The critical path (entrance → boss) stays guaranteed; optional rooms hang off it.

**Files:** `dungeon_gen.gd`, `dungeon_score.gd` (the dead-end metric must not punish *intentional* optional dead-ends).
**Acceptance:** generated dungeons have multiple routes + opt-in side rooms; the entrance→boss path is always valid.

### Phase 5 — Pacing curve

The dungeon sequences itself.

- Order rooms by BFS depth from the entrance (already computed for boss placement).
- Map depth → escalation: shallow rooms = sparse/easy, deep rooms = denser/harder; the strongest setpiece sits just before the boss; entrance room is always calm.
- Role + enemy-tier assignment becomes depth-aware instead of uniform-random.

**Files:** `dungeon_gen.gd`, `layout_loader.gd` (enemy spawn density by room depth/role).
**Acceptance:** a playthrough escalates — the first room is calm, it gets denser toward the boss.

---

## Out of scope (explicit non-goals)

- **Locked doors + keys** — deferred to its own spec (a gameplay system with a procedural-solvability burden; risks generating unbeatable dungeons).
- New GLB art — use what `models/` already has.
- Verticality / multi-floor.
- Biome variety beyond the crypt (one themed dungeon for now).
- Reworking combat, the boss, or the camera.

## Acceptance criteria (whole spec)

1. Generated crypts show varied room shapes + sizes.
2. Rooms read as distinct *places* — themed, rule-dressed, not random scatter.
3. At least one authored setpiece per run, correctly connected.
4. The layout has real branches + optional side-rooms; entrance→boss always valid.
5. A run escalates in difficulty/density from entrance to boss.
6. Every phase: `test_combat` 20/20 · `test_movement` 6/6 · crypt scores well · boots clean.

## Open decisions

- **Theme → decor mapping** — the exact decor list + placement rule per theme. I'll design it in Phase 1 from the world bible; the user reviews the screenshot.
- **Setpiece template format** — the exact char legend (decor/enemy/loot markers). I'll define it in Phase 3; keep it close to `map.txt`.
- **Shape weights** — how often circular/irregular/hall vs rectangular. Start conservative (mostly rectangular, ~30% varied); tune by eye.
- **Scorer** — Phase 4's optional dead-ends fight the existing `dead_end_max_frac` metric; re-tune so *tagged* optional rooms don't tank the score.

## References

- The grill that produced this plan (this conversation)
- Research: [Diablo chunks](https://www.gamedeveloper.com/programming/procedural-dungeon-generation-algorithm), [Unexplored authored rules](https://www.boristhebrave.com/2021/04/10/dungeon-generation-in-unexplored/)
- Spec 24 — the wider corridors / GLB walls this builds on
- `dungeon_gen.gd` (the TinyKeep pipeline), `dungeon_score.gd`, `layout_loader.gd`
- `docs/WORLD_BIBLE.md` — Bramblewood tone for the theming
- `models/dungeon_crypt_*.glb` — the decor GLBs to wire up

## Done check

- [ ] Phase 1 — room roles + themes + rule-based dressing + decor GLBs wired
- [ ] Phase 2 — varied room shapes
- [ ] Phase 3 — ASCII setpiece templates + stamp/connect routine + 2-3 setpieces
- [ ] Phase 4 — loops + optional side-rooms
- [ ] Phase 5 — pacing curve
- [ ] Each phase: evals green, scores well, boots, screenshot
- [ ] `GODOT_PIPELINE.md` updated
