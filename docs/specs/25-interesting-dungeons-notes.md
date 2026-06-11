# Implementation notes — 25-interesting-dungeons

All five phases implemented in one pass.

## Decisions
- **Phase 1 — themes** are a data dict (`ROOM_THEMES`): each theme is a list
  of `{kind, pattern, count}` dressing rules. Patterns: `walls / corners /
  center / cluster / scatter` (`_pattern_tiles`). Roles: entrance / combat /
  treasure / shrine / boss / setpiece.
- **Phase 1 — wired 7 unused crypt decor GLBs** (sarcophagus, altar, brazier,
  chest, column, pottery, rug) into `layout_loader.DECOR_MODEL` + colliders.
- **Phase 2 — shapes** assigned *before* the carve (`rect / circle /
  irregular`, ~55/25/20). Room 0 stays rect; the boss room is re-carved to a
  full rect after the graph resolves (the arena seal needs a rectangle).
- **Phase 3 — setpieces stamp into an existing room**, not as a newly placed
  room. `_pick_setpiece` tags the largest eligible room (≥8×8) as a setpiece;
  `_stamp_setpiece` paints a 7×7 ASCII template (`data/rooms/*.txt`) centred
  in it. The room is already in the graph with corridors — so "connect the
  setpiece" is free, no door-registration logic needed.
- **Phase 4 — `LOOP_EDGE_FRACTION` 0.15 → 0.32** (real alternate routes);
  dead-end rooms (graph degree ≤1) are auto-tagged `treasure`.
- **Phase 5 — enemy count is now variable** — per room, by role × BFS depth
  (`combat` 2–5 deeper-is-more, `treasure` 1, `shrine` 0–1, `setpiece` 2).
  Replaces the fixed `ENEMY_COUNT = 6`.

## Deviations
- **Phase 3 "stamp + connect doors"** — the spec described setpieces as
  templates placed as new rooms with door markers wired into the graph. I
  stamp into an *existing* room instead — same authored-room result, but it
  reuses that room's graph edges, so there's no new connection/door system.
  Templates therefore have no `D` markers; corridors already reach the room.
- **"Great hall" shape** (Phase 2 list) skipped — rooms are already sized
  6–12, so size variety exists; shapes are rect/circle/irregular.
- **One setpiece per run** (the largest eligible room), not 2–3 — the
  *library* has 2 templates (vault, shrine), one is picked per run.

## Tradeoffs
- Setpiece templates are a fixed 7×7 stamped centred into a ≥8×8 room. If no
  room qualifies, no setpiece that run (graceful). Simpler than resizing
  rooms to match templates or supporting arbitrary template sizes.
- A setpiece's interior `#` walls *could* in principle wall a room off — the
  connectivity hard-gate in the scorer catches it (regenerates), so it's
  safe, but a bad template costs regeneration attempts.

## Surprises
- The crypt still scores **1.00** with all five phases — wider loops + varied
  shapes + setpieces didn't fight the scorer (after the spec-24 re-tune).

## Followups
- **Decor density** — themed dressing produces ~28–30 pieces/run; some rooms
  may read cluttered. Tune the per-theme `count` ranges by play-test.
- Decor GLBs aren't `_unmetal`'d — fine on native (Forward+), may chrome on
  the web build; add `_unmetal` to `_build_decor` before the next export.
- `ENEMY_COUNT` const is now unused (left in place, harmless).
- Could stamp more than one setpiece per run; add more templates.
- Integer-division warnings in dungeon_gen/layout_loader are intentional
  (tile-coord math) — silence with `@warning_ignore` if noise matters.

## Status
COMPLETE — all 5 phases. Crypt scores 1.00; `test_combat` 20/20,
`test_movement` 6/6; World boots clean. Rooms now have roles + themes + rule-
placed decor, varied shapes, a stamped setpiece, looped layout, and depth-
paced enemy density.
