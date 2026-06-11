# Implementation notes — 28-dungeon-placement-polish

## Decisions
- **Bounds are now the actual room edges** (`ix0 = r.x`, `ix1 = r.x+r.w-1`)
  rather than the inboard ring — decor on the "walls" pattern sits *flush*
  against the wall instead of one tile in.
- **Per-tile `orient` cardinal** (`n / e / s / w / center`) ridden by every
  candidate. `layout_loader._build_decor` maps cardinal → Y rotation via
  `ORIENT_RY`; the rotation is applied to the wrapping `StaticBody3D` so
  the box collider rotates with the GLB.
- **Corridor-mouth filter** — `_is_corridor_mouth(r, x, y, grid)` rejects
  any tile whose 4-neighbour is a floor *outside the room rect*. That's a
  corridor entry; decor there is the bug that made the game unplayable.
- **`ROOM_THEMES` shape** is now `{focal, satellites}` instead of a flat
  array. The focal is always placed first so it owns the centre cell;
  satellites arrange around. Per-room readability follows.
- **"center" pattern widened to a 3×3 cluster** (was 3 fixed tiles) — gives
  the focal more candidates so it lands even when the dead-centre tile is
  a corridor mouth.
- **`_apply_rule` scatter fallback** — if a rule with `n≥1` finds zero
  pattern tiles (everything filtered), it falls back to `_pattern_tiles
  "scatter" 1`. A focal never silently disappears.
- **Corner tiles get `orient: "center"`** (not a diagonal) — none of the
  GLBs in the kit read well at 45°; centre = no rotation. Tunable per kind
  via `DECOR_FACING_OFFSET` later if needed.
- **`DECOR_FACING_OFFSET` dict empty in v1** — extend if a specific GLB's
  native facing makes wall decor face the wrong way after orient is
  applied (the spec called this out as a v1 stub).

## Deviations
- Spec's "Open decision — corner tile orient" landed on **center** (no
  rotation) rather than the nearer cardinal. Symmetric kinds (column,
  brazier) are visually unaffected; if a kind in the future wants the
  diagonal, add it as a `_pattern_tiles` change for that pattern alone.

## Tradeoffs
- **Body-level rotation vs. per-mesh rotation.** Rotating the body
  rotates the box collider with the GLB — for sarcophagi (1.0 × 0.9 × 1.6,
  long in Z), a 90° rotation correctly puts the long axis along X, so it
  *occupies* the wall it sits on. Rotating only the mesh would have left
  the collider axis-aligned, which would either over-hug or under-cover
  the actual shape. Body rotation is the right call.

## Surprises
- **Eval T3 caught the silent-drop bug.** First pass missed 2/30 focal
  placements because every "center" candidate was filtered (corridor
  mouth at the room's dead centre — small rooms with a 3-wide corridor).
  The widen-then-fallback fix gets 30/30.
- **No `var ok :=` parse errors this time** — staying ahead of the
  GDScript inference pitfall.

## Followups
- **Per-kind `DECOR_FACING_OFFSET`** if a play-test shows a specific GLB
  (e.g. sarcophagus with its head at +X instead of -Z) faces the wrong
  way after orient — one-line entry.
- **More setpieces** — spec-25 followup: bump from 1 setpiece per run to
  3-4 with richer interiors. Now that placement reads cleanly, this lift
  starts to matter more.
- **Themed lighting per room** — shrines warm-gold, ossuaries cold-blue,
  vaults shimmer. The focal-point arrangement makes lighting the focal a
  natural composer.
- **Encounter design** — enemies posed around the focal (guards flanking
  a chest, ambushers behind columns) rather than uniform-random.
- **The wall GLB re-author** still in the backlog — distinct from this
  spec; the placement-bug fixes don't touch wall geometry.

## Status
COMPLETE — `test_decor_placement.gd` **3/3**, every other harness still
green (items 7 · inventory 8 · drops 5 · equipment 7 · stats 5 · movement
6 · combat 21 = **62 evals across 8 harnesses**), World boots score 1.00.
Decor sits where it should, faces the right way, never blocks a room.
