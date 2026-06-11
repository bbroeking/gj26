# Implementation notes — 16-crypt-visual-sizing

## Decisions
- **Ranger scale 0.66×** — measured AABB height was 2.726 m; 1.8 / 2.726 ≈ 0.66 → ~1.8 m rendered. Applied as the `Mesh` node transform in `Player.tscn`.
- **Walls 4.5 m**, body Y at 2.25 (half-height) — mesh + collider both `1×4.5×1`.
- **Camera zoom 15 → 18** for the taller space.
- **Wall jitter** — per-wall HSV value ±0.05 on a warmer stone base, applied on the duplicated per-wall material the spec-14 occlusion fade already requires.
- **Lighting** — ambient energy 0.45 → 0.24; one warm `OmniLight3D` per `torch_wall` decor (range 7, energy ~2.2). The directional Sun stays as base fill so rooms without a torch aren't black.

## Status
COMPLETE. Walls (tall, jittered stone), lighting (torch pools, hero light),
HUD, and a reference-calibrated sizing pass all landed; combat evals 15/15.

## Sizing — the calibration process (revised section A)
Built `Calibration.tscn` / `calibration.gd` — renders the player + every
enemy on a checkerboard tile floor by a wall at the crypt camera, for
side-by-side comparison with the reference ARPG screenshot.

**Surprise — the GLBs are at wildly inconsistent native sizes.** Measured
heights: ranger 1.63 m, skeleton 0.81 m, ghost 1.34 m, hedge-sprite 0.77 m,
rat 1.37 m, hedgemother **1.29 m** (the boss was *smaller than the hero*).
That inconsistency — not the wall height — was why "everything looks the
same size."

**Calibrated per-model scales** (locked into the game):
ranger 1.30 · skeleton 1.45 · ghost 2.00 · hedge-sprite 2.00 · rat 0.55 ·
hedgemother 3.75 (the boss now towers at ~2× a mob). Camera zoom pulled
15→18→**13** so the hero reads prominently.

**Surprise — skinned-mesh height can't be measured reliably.** Meshy bakes
rigged meshes with verts at the origin, so `MeshInstance3D.get_aabb()`
reads ~0.01 m; the skeleton bone-rest extent is a rough proxy but warps
per-creature. So the calibration scales are eyeballed against the
screenshot, not computed — which is exactly why the calibration *scene* is
the deliverable, not a formula.

## The "disappears when moving" bug — ROOT CAUSE FOUND + FIXED
A bug chased since spec 13. Decisive diagnostic: when the player's walk
clip plays, the bow (parented to the hand socket) flies to **Y = −5.74 m**.
The `npc_ranger_body_v3.glb` **walk/run clips are broken** — they drive the
skeleton to garbage coordinates, so the skinned mesh explodes/vanishes.
The player was visible standing still (clip stopped) and vanished on the
first step (clip plays). **Fix:** `player_controller` no longer plays those
clips — it stops the AnimationPlayer in `_ready` and holds bind pose. The
player is now always visible. (Earlier spec-14 diagnostics missed this
because they measured node transforms, not the skinned render / the bow.)

## Deviations
- Added a `HeroLight` (OmniLight3D on the player) — not in the spec, but
  the lowered ambient left the hero too dark to spot; a pool of light on
  the hero matches the reference and satisfies "hero stays readable."

## Tradeoffs
- _pending_

## Surprises
- _pending_

## Browser export
Re-exported to Web (`build/web/`, ~51 MB: 37.7 MB wasm runtime + 13.3 MB
pck). **Gotcha:** `export_filter="scenes"` does NOT follow `preload()`
chains — `combatant.gd`, `anim_driver.gd`, `arrow.gd`, `damage_number.gd`,
`Arrow.tscn`, `DamageNumber.tscn` were silently dropped, so the build ran
but the dungeon never built (parse errors). Fix: every dynamically-
preloaded script/scene must be listed explicitly in `include_filter`.
Updated `export_presets.cfg` accordingly. Verified rendering + no console
errors in Chrome. `thread_support=false` → serves from any static host.

## Followups
- **Regenerate the Ranger with working walk/run clips** (or fix the
  existing ones) — the player currently slides in bind pose, no leg
  movement. This is the same Meshy rig+animate pipeline used for the
  enemies in spec 11.
- The Ranger model's internal proportions (oversized pale head) — a model-
  quality issue uniform scaling can't fix; regeneration would address it.
- `Calibration.tscn` is a kept dev tool — re-run it whenever a model
  changes to re-check proportions.
- Enemy capsule colliders are a single (0.4, 1.4) for all mobs — fine, but
  the rat (scaled 0.55) has a slightly oversized collider.
