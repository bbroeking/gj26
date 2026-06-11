# Implementation notes — 24-dungeon-readability-rework

## Decisions
- **Grid 28 → 34.** 3-wide corridors + bigger rooms (6–12 vs 4–9) need
  more room; 34² keeps the dungeon from feeling cramped. `ROOM_TRIES`
  60 → 90 (bigger rooms are harder to place).
- **3-wide corridor carve** — a `±CORRIDOR_HALF` brush perpendicular to the
  existing 1-wide path (`_carve_tile` clamps to keep the 1-tile border).
  Minimal change to the gen, as the spec recommended.
- **Scorer re-tune** — `CORRIDOR_RATIO_MAX` 0.60 → 1.5 (3-wide corridors
  legitimately ~3× the corridor tiles), `FLOOR_RATIO` band 0.18–0.45 →
  0.22–0.66. Verified: the crypt still scores 1.00 on the first attempt.
- **Full wall-variant picker, not straight-only.** The three.js side
  already had `cryptWallVariant()` — ported it verbatim to
  `layout_loader._wall_variant()`. So walls use straight + inner/outer
  corner GLBs, oriented by the open-floor neighbours — better than the
  spec's "straight-only v1" minimum, at no extra cost.
- **Wall collision stays a `BoxShape3D`** — the GLB is purely visual; a box
  collider is gap-free and robust.
- **`WALL_HEIGHT` 4.5 → 2.5.** Camera angle untouched (55°, research-validated).
- **Occlusion fade** now uses `GeometryInstance3D.transparency` on the wall
  GLB's mesh instances (camera_rig `_set_wall_alpha`) — the old path set
  `material_override` alpha on a single `WallMesh`, which a multi-mesh GLB
  doesn't have.

## Surprises
- **The crypt wall GLBs are mis-proportioned for tiling.** Probed extents:
  `wall-straight` is 1.90 × **1.23** × 0.40 (wide + short), but the corner
  pieces are ~1.9 m *tall*. No uniform scale fits the straight piece into a
  1×2.5×1 tile, so `_place_wall` scales each piece **non-uniformly** to fill
  the tile (in local space, so the scale follows the variant rotation). The
  straight piece stretches ~2× vertically — at the ARPG zoom it reads fine
  as stone, but see Followups.

## Followups
- **Re-author the crypt wall GLBs to a clean 1×H×1 module** so they tile
  without the non-uniform stretch. Until then the straight piece is ~2×
  vertically stretched.
- **The GLB walls render pale/bright** (their native light-stone material) —
  lighter than the old warm-grey tint. May want a darker material pass for
  crypt mood; deferred — "looks made" was the spec goal and that's met.
- Web export — the three crypt wall GLBs were already whitelisted (spec 01);
  no export-filter change needed. Re-export for the browser build.
- Damage-feedback juice (sparks, screen shake) — still deferred; revisit now
  that the dungeon reads clearly.

## Status
COMPLETE. Corridors 3-wide, rooms bigger, walls 2.5 m built from the modular
crypt wall GLBs (variant-picked). Crypt scores 1.00; `test_combat` 20/20,
`test_movement` 6/6; World boots clean.
