# 24 — Dungeon readability + visuals rework

> **Outcome**: the crypt reads clearly during a fight and the walls look *made*, not like a flat grey maze. Corridors widen from 1 → 3 tiles, walls drop from 4.5 m → ~2.5 m, and the flat `BoxMesh` walls are replaced with the project's modular crypt wall GLBs. This fixes the root cause behind "the damage feedback / the fight is hard to see" — it was the dungeon all along.

## Why

A grill traced "the damage animations are hard to see" down to the dungeon itself: walls too tall (they swallow the actors + feedback), halls too narrow (1-tile corridors are cramped and unreadable), and walls visually flat (one repeated grey slab). Research on how ARPGs handle this:

- **Camera** — Diablo 3 / PoE / Torchlight sit at **~50°**; gj26's 55° is already right. *The angle is not the problem* — don't touch it. ([isometric ARPG camera/occlusion](https://www.gamedev.net/forums/topic/664146-isometric-visibility-problem/))
- **Corridors** — the standard is **~3 tiles wide**; it "makes layouts easier to read." 1-tile corridors are the readability anti-pattern. ([dungeon corridor design](https://critical-hits.com/blog/2012/07/25/the-architect-dm-structural-dungeon-design/))
- **Walls** — ARPG dungeons keep walls lower/partial so the camera reads over them; visual interest comes from a **modular tileset** (straight / corner / pillar / decorated pieces), not a flat slab. ([modular dungeon tilesets](https://www.boristhebrave.com/2021/04/10/dungeon-generation-in-unexplored/))

## Scope

**In:**

### A. Wider corridors (`dungeon_gen.gd`)
- Corridors carve **3 tiles wide** instead of 1 — the corridor-carving step brushes a 3-wide path between rooms.
- Account for the dungeon scorer (`dungeon_score.gd`) — `corridor_ratio` / `floor_ratio` shift; re-tune the metric weights or thresholds if the scores skew. The generate-and-test loop must still find good layouts.
- If wider corridors + bigger rooms overflow the fixed grid, grow the grid (cols/rows in `config`/the gen) so the dungeon still fits.

### B. Bigger rooms (`dungeon_gen.gd`)
- Bump the min/max room dimensions a notch — the earlier "rooms too small" complaint. Modest — readable, not cavernous.

### C. Lower walls (`layout_loader.gd`)
- `WALL_HEIGHT` **4.5 → ~2.5 m**. Update the wall mesh, the `BoxShape3D` collider, and the wall body Y (half-height).
- Re-check the camera framing at the new height (`ZOOM_DEFAULT` may want a small nudge — but the **angle stays 55°**).
- Confirm the spec-14 wall-occlusion fade still behaves (it matters far less with 2.5 m walls).

### D. Modular wall visuals (`layout_loader.gd`)
- Replace the flat `BoxMesh` wall with the project's **crypt wall GLBs** (`models/dungeon_crypt_wall-*.glb`). Each wall tile instances a wall-piece GLB, scaled to ~2.5 m, oriented to face the adjacent open space.
- Add variety so it's not one repeated piece — corner pieces and/or occasional pillars if the GLBs support it (see Open decisions).
- Keep a per-wall material instance (the occlusion fade still needs it).

### E. Verify
- Scene boots; a fight runs clean. `test_combat.gd` 20/20 and `test_movement.gd` 6/6 still pass (the procgen change must not break combat/movement).
- A screenshot confirms: wider halls, lower walls, the GLB wall look, the fight readable.

**Out (explicit non-goals):**
- The camera angle — stays 55° (research-validated).
- Damage-feedback juice (sparks, screen shake) — deferred; revisit only if the fight still reads poorly *after* the dungeon is fixed.
- New wall GLB art — use what the project already has.
- A full biome/environment-variety system.
- Floor texturing beyond the existing tint.

## Files

| Path | Action |
|---|---|
| `godot/scripts/dungeon_gen.gd` | modify — 3-wide corridors, bigger rooms, grid size if needed |
| `godot/scripts/dungeon_score.gd` | modify — re-tune metrics for the new corridor/room profile |
| `godot/scripts/layout_loader.gd` | modify — `WALL_HEIGHT` 2.5, GLB wall pieces instead of BoxMesh |
| `godot/scripts/camera_rig.gd` | modify — zoom nudge only if needed (angle unchanged) |
| `docs/GODOT_PIPELINE.md` | modify |

## Acceptance criteria

1. Corridors are visibly ~3 tiles wide — no more single-file halls.
2. Rooms are a notch larger than before.
3. Walls are ~2.5 m — the camera reads cleanly over them; the fight is no longer swallowed.
4. Walls render as crypt-stone GLB pieces, not flat grey boxes — with enough variety they don't read as one repeated slab.
5. The crypt still generates valid, connected, well-scored layouts (the scorer still passes its bar).
6. `test_combat.gd` 20/20 and `test_movement.gd` 6/6 still pass; scene boots clean.

## Open decisions

- **Corridor carve.** A 3-wide brush along the existing 1-wide path (recommended — minimal change to the gen) vs. re-architecting corridor generation. Recommend the brush.
- **Grid growth.** Only grow the procgen grid if 3-wide corridors + bigger rooms genuinely overflow — check first; keep the grid as-is if it still fits.
- **Wall GLB variety.** Inspect `models/` for the available crypt wall GLBs. If only a straight piece exists → use it for every wall tile (oriented to the open side) and add occasional pillar props for rhythm. If corner pieces exist → use them at corners. A full three.js-style wall-variant picker is a *followup*, not v1.
- **Wall height.** ~2.5 m recommended; tune by eye against readability once the GLB walls are in.
- **Scorer re-tuning.** Wider corridors raise `corridor_ratio` / `floor_ratio` — adjust the metric so a good dungeon still scores well; the generate-and-test loop must not start rejecting everything.

## References

- The grill that produced this plan (this conversation) + the three research sources above
- Spec 16 — set the 4.5 m walls + the flat tint (this rework reverses both)
- Spec 19 — the navmesh rebuilds from floor tiles, so it adapts to wider corridors automatically
- `dungeon_gen.gd`, `dungeon_score.gd`, `layout_loader.gd`
- `models/dungeon_crypt_wall-*.glb` — the modular wall pieces to use

## Done check

- [ ] Corridors carve 3 tiles wide
- [ ] Rooms bumped up
- [ ] `WALL_HEIGHT` 2.5 — mesh + collider + body Y
- [ ] Walls render as crypt-stone GLB pieces, with variety
- [ ] Procgen still produces valid well-scored layouts
- [ ] `test_combat.gd` 20/20 · `test_movement.gd` 6/6 · boots clean
- [ ] Screenshot confirms a readable, good-looking crypt
- [ ] `GODOT_PIPELINE.md` updated
