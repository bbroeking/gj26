# 16 — Crypt visual + sizing pass

> **Outcome**: the Godot crypt reads like a chunky ARPG dungeon, not a grey box maze. The character is correctly small inside a tall, imposing space — character ~1.8 m, walls ~4.5 m (currently the player is *taller* than the walls). Walls have a real stone look with per-wall variation, and the lighting goes from flat to dramatic pools-of-light.

## Why

A grill on the spec 07–15 gaps set the near-term milestone: a polished, shareable browser demo. Two visual problems block "polished": (1) **sizing is inverted** — the Meshy-rigged Ranger is ~2.7 m and walls are only 2 m, so the hero towers over the dungeon; the reference ARPG has a *small* hero in a *towering* space; (2) **walls are flat grey boxes** with a single tint and flat ambient light. This spec fixes both. The Hedgemother boss-fight port and the browser re-export are separate specs after this.

## Scope

**In:**

### A. Sizing — chunky-ARPG proportions (1 tile = 1 m)
- **Character ~1.8 m.** The Ranger GLB renders at ~2.7 m — scale the player `Mesh` down (~0.66×) to ~1.8 m. Enemy GLBs were Meshy-rigged near sensible heights (skeleton 1.55, ghost 1.4, hedge-sprite 0.95, hedgemother 2.4) — verify they read proportionate to a 1.8 m player; nudge only if clearly off.
- **Walls ~4.5 m.** The wall `BoxMesh` goes from `1×2×1` to `1×4.5×1`; the wall `CollisionShape3D` `BoxShape3D` matches; wall body Y rises to 2.25 (half-height).
- **Camera.** With taller walls + a smaller hero the framing shifts — widen `ZOOM_DEFAULT` a touch and re-check the pitch so the hero sits well-framed in the taller space. The spec-14 wall-occlusion fade now matters more (4.5 m walls occlude a lot) — confirm it still fades correctly at the new height.
- Player capsule collider + hurtbox stay tied to the ~1.8 m visual.

### B. Walls — a real stone look
- Replace the flat single-tint wall material with a **stone material**: a darker base, modest roughness, and **per-wall colour jitter** (small HSV variation per wall instance) so a wall run isn't one dead-flat slab.
- Keep the per-wall material instance (spec 14 needs it for the occlusion fade) — the jitter is applied on top.
- A subtle top-vs-bottom shade (walls slightly darker at the base) if cheap — optional.

### C. Lighting — dramatic, not flat
- The crypt currently uses flat ambient (0.45) + one directional sun. Push toward the reference's **pools of light in darkness**: lower the ambient, add warm **point lights** at torch/brazier decor positions (the layout already places `torch_wall` decor — light those), and let the walls fall into shadow between lights.
- Keep it readable — the hero and nearby enemies must stay clearly lit. Tune so it's atmospheric but not unplayable-dark.

**Out (explicit non-goals):**
- The Hedgemother boss phase machine — spec 17.
- Browser re-export — separate, after the demo is content-complete.
- Real per-GLB textures — flat/jittered tints stay (deferred from spec 14).
- Authored crypt wall-GLB geometry (`dungeon_crypt_wall-straight_v1.glb` etc.) with corner-orientation — a nice followup, but the BoxMesh + good material + tall + lit reads well enough; the wall-variant picker is a port of its own.
- Enemy pathfinding, herbs/mining.
- Floor texturing beyond the existing tint.

## Files

| Path | Action |
|---|---|
| `godot/scripts/layout_loader.gd` | modify — wall height 4.5, wall collider, stone material + per-wall jitter, torch point lights |
| `godot/scenes/Player.tscn` | modify — scale the Ranger `Mesh` to ~1.8 m |
| `godot/scripts/camera_rig.gd` | modify — widen default zoom for the taller space |
| `godot/scenes/World.tscn` | modify — lower ambient for the dramatic-lighting pass |
| `docs/GODOT_PIPELINE.md` | modify — note the sizing constants |

## Acceptance criteria

1. The player character is visibly *shorter* than the walls — walls tower ~2–3× the hero's height.
2. Character height is ~1.8 m; walls ~4.5 m (verifiable via a debug AABB print or the eval-style probe).
3. Walls have visible per-wall variation — a wall run is not one flat slab.
4. Lighting reads as pools of light in darkness — torch decor casts warm light; areas between fall to shadow; the hero stays readable.
5. The camera frames the hero well in the taller space — not cramped, not lost.
6. Wall-occlusion fade still works at the new 4.5 m height (player never hidden behind a wall).
7. The scene boots and a fight runs with no errors; combat evals (`test_combat.gd`) still 15/15.

## Open decisions

- **How much to shrink the Ranger.** ~0.66× → ~1.8 m recommended. If the Ranger's authored height differs from the measured 2.7 m, compute the scale from a fresh AABB so the result is exactly ~1.8 m.
- **Wall colour jitter range.** ±0.04 HSV value, ±0.02 hue recommended — enough to break the slab, not enough to look noisy.
- **Point-light count / range.** One warm `OmniLight3D` per `torch_wall` decor, range ~6 m, modest energy. If the torch decor is sparse, also drop a few ambient fill lights so rooms aren't pitch black. Notes record final counts.
- **Ambient level.** Drop from 0.45 to ~0.20–0.28 so the point lights read; tune against criterion 4 (atmospheric but playable).
- **Camera zoom.** `ZOOM_DEFAULT` 15 → ~17–18 to fit the taller walls; tune by eye.

## References

- The reference ARPG screenshot the user supplied — small hero, towering walls, pools of light, ~55° camera.
- `godot/scripts/layout_loader.gd` — `_place_wall`, `_tint`, `_build_decor` (torch_wall placement)
- `godot/scripts/camera_rig.gd` — zoom + occlusion fade
- Spec 14 — per-wall material (occlusion fade depends on it)
- Spec 15 — current combat; `test_combat.gd` must still pass

## Done check

- [ ] Ranger scaled to ~1.8 m; enemies proportionate
- [ ] Walls 4.5 m — mesh + collider + body Y
- [ ] Camera zoom widened, hero well-framed
- [ ] Wall occlusion fade verified at 4.5 m
- [ ] Stone wall material + per-wall jitter
- [ ] Dramatic lighting — torch point lights, lowered ambient, readable hero
- [ ] Scene boots clean; `test_combat.gd` still 15/15
- [ ] `GODOT_PIPELINE.md` notes the sizing constants
