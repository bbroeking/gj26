# 28 — Dungeon decor: placement polish + focal-point arrangement

> **Outcome**: rooms read as designed *places* instead of scattered props. Decor sits flush against the actual walls, oriented toward open space, and never blocks a corridor mouth. Each themed room has one clear centerpiece with satellites arranged around it.

## Why

Playtest of spec 25's themed dungeons surfaced three placement bugs and a flatness problem:

- **B — wrong spot.** `_pattern_tiles`'s `walls` pattern uses `ix0 = r.x+1` — one tile *inboard* from the actual wall. Decor visibly floats ~1m off the wall it's meant to hug.
- **A — wrong orientation.** Every GLB renders at its native facing; bookshelves all point the same world direction regardless of which side of the room they're on.
- **C — blocks movement.** "walls"-pattern decor can land on the room's corridor-mouth tiles → a sarcophagus across the entrance makes the room *unplayable*.
- **Interestingness.** Each room is a scatter of like decor; there's no visual anchor that says "this is the centerpiece."

## Scope

### A. Placement bugs (B+A+C, all in `dungeon_gen._pattern_tiles`)
- **Flush** — `iy0 = r.y` / `iy1 = r.y+r.h-1` / `ix0 = r.x` / `ix1 = r.x+r.w-1`. Decor sits on the room's actual edge cells (adjacent to the wall).
- **Orient** — each tile candidate carries an `orient` (`"n"` / `"e"` / `"s"` / `"w"` / `"center"`) telling layout_loader which cardinal it faces. Wall tiles face *away* from their wall toward room interior; corner tiles face the diagonal; centre tiles get `"center"` (no enforced rotation).
- **Corridor-mouth filter** — drop any candidate whose 4-neighbours include a *floor tile outside the room*. That's a corridor entry; decor there blocks the only way in.

### B. layout_loader applies the orient
- `_build_decor` reads each decor entry's `orient`; maps to a Y rotation:
  - `n` → 0 (face south / +Z)
  - `e` → −π/2
  - `s` → π
  - `w` → +π/2
  - `corner_*` → 45° diagonals (or pick the nearer cardinal)
  - `center` → random small jitter, or 0
- Symmetric kinds (column, pottery, brazier, bones) ignore orient visually — harmless.
- Per-kind rotation tweaks (a future polish if a GLB faces differently) live in a small `DECOR_FACING_OFFSET` dict — `0` for all kinds in v1.

### C. ROOM_THEMES restructure — focal + satellites
Each theme is now `{focal: rule, satellites: [rule, ...]}` instead of a flat list. The focal is always *one* item placed in the room's *center* (or near it); satellites use the existing patterns (walls / corners / cluster / scatter).

- `tomb_hall`   focal **sarcophagus** (center×1)  · sats: sarcophagus×3-5 (walls) · torch_wall (walls)
- `ossuary`    focal **bones** (center×1)         · sats: bones (cluster) · torch_wall (walls)
- `archive`    focal **bookshelf** (center×1)     · sats: bookshelf×3-5 (walls) · torch_wall (walls)
- `shrine`     focal **altar** (center×1)         · sats: brazier (corners) · rug (center, offset)
- `vault`      focal **chest** (center×1)         · sats: pottery (scatter) · column (corners)
- `antechamber` focal **column** (corner pair)    · sats: brazier (walls)

`_dress_rooms` walks the focal first (so it owns the center cell), then the satellites — `_pattern_tiles` already filters tiles via `cells` lookups so satellites won't overlap the focal.

### D. Eval coverage
- Extend `test_inventory.gd`? No — this is dungeon-gen. A new `test_decor_placement.gd`:
  - **T1** — generate 10 dungeons; every solid-decor tile is *not* a corridor-mouth tile.
  - **T2** — every "walls"-pattern tile is on the room's actual edge (the row/column of the wall), not one inboard.
  - **T3** — each themed room contains its focal kind at its center cell.

## Out of scope
- **More setpieces** (the spec-25 followup — bump from 1/run to 3-4 with richer interiors).
- **Themed lighting per room** (shrines glow, vaults shimmer) — own pass.
- **Encounter design** (enemies posed purposefully near the focal) — own pass.
- **Per-kind GLB facing offsets** beyond the `0`-default `DECOR_FACING_OFFSET` dict.
- Wall GLB re-author, item sprite art, character-sheet panel — backlog.

## Files

| Path | Action |
|---|---|
| `godot/scripts/dungeon_gen.gd` | rewrite `_pattern_tiles` (flush + orient + filter); restructure `ROOM_THEMES`; `_dress_rooms` walks focal then satellites |
| `godot/scripts/layout_loader.gd` | `_build_decor` applies the `orient` field as Y rotation; add `DECOR_FACING_OFFSET` dict (all 0 for v1) |
| `godot/test_decor_placement.gd` | new — three evals above |
| `docs/GODOT_PIPELINE.md` | update |

## Acceptance criteria
1. Walk through a generated dungeon — no decor blocks a corridor entry; the player can reach every room.
2. Bookshelves / sarcophagi sit *against* the wall, not floating one tile in.
3. Wall-placed decor faces *toward* the room interior (not all uniformly +Z).
4. Each themed room has a clear centerpiece — a sarcophagus at the centre of a tomb hall, an altar in a shrine, a chest in a vault.
5. `test_decor_placement.gd` green; existing harnesses still 7/7 · 8/8 · 5/5 · 7/7 · 5/5 · 6/6 · 21/21.
6. World boots, score still ≥0.9.

## Open decisions
- **Symmetric kinds and orient** — column/pottery/bones are visually symmetric; setting their rotation is harmless. Lean: still set it (uniform code path).
- **Corner tile orient** — face the diagonal vs the nearer cardinal? Lean: nearer cardinal (no GLB rotates well on a diagonal in this kit).
- **Focal overflow** — if a focal would land on the room center but the center is on the critical path, fall back to the nearest valid cell. Lean: yes; never reject a focal.

## References
- The grill that produced this plan (this conversation).
- Spec 25 — the themed-dressing system this fixes.
- `dungeon_gen.gd::_pattern_tiles`, `_dress_rooms`, `ROOM_THEMES`.
- `layout_loader.gd::_build_decor`.

## Done check
- [ ] `_pattern_tiles` — actual-edge bounds + per-tile orient + corridor-mouth filter
- [ ] `ROOM_THEMES` restructured to {focal, satellites}; `_dress_rooms` places focal first
- [ ] `_build_decor` applies orient as Y rotation
- [ ] `test_decor_placement.gd` green
- [ ] Existing harnesses still green
- [ ] World boots; play a run — corridors clear, rooms anchored
- [ ] `GODOT_PIPELINE.md` updated
