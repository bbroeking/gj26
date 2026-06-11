# 21 — Rat rigging / animation

> **Outcome**: the rat enemy animates instead of sliding as a static mesh — it's the one crypt enemy that never got a working rig (Meshy's auto-rig is humanoid-only; the rat is a quadruped).

## Why

Spec 11 rigged the skeleton, ghost, hedge-sprite, and Hedgemother via Meshy; the rat failed ("Pose estimation failed" — quadruped). It's been a static `enemy_rat_v1.glb` ever since. In a polished demo a frozen rat among animated enemies reads as broken.

## Scope

**In:** an animated rat — by whichever path the grill picks (see Open decisions). Whatever the path, the result is: the rat has at least an **idle** and ideally a **moving** state, driven through the same `anim_driver` hook the other enemies use, or a procedural equivalent.

**Out:**
- A realistic quadruped gait — a readable bob/scurry is enough.
- Re-rigging other enemies.
- New rat designs.

## Open decisions — the approach (the main thing to grill)

| Option | What | Cost | Trade-off |
|---|---|---|---|
| **A. Procedural** | Per-frame node rotation — bob the body, twitch the tail/legs — the three.js `src/anim/cow.js` approach. No skeleton. | free | Reliable, no Meshy; limited to what un-skinned node rotation can do. |
| **B. Regenerate humanoid-ish** | Re-generate the rat in a more upright/bipedal pose Meshy *can* auto-rig. | ~40 cr | A working skeletal rig, but the rat stops looking like a quadruped rat. |
| **C. Hand-rig in Blender** | Author a quadruped skeleton + walk clip by hand. | free (time) | Full control; the most effort; needs the Blender pipeline. |
| **D. Accept static** | Leave it; cut the rat from the demo roster. | free | Zero work; one fewer enemy. |

**DECIDED (grill): A — procedural.** It's free, reliable (no failed-rig risk), and a low-poly rat reads fine with a body-bob + tail-twitch. The rat is a minor enemy; a skeletal rig is overkill. The three.js project already has this exact pattern in `src/anim/`.

## Scope (assuming A)

- A `rat_anim.gd` (or extend `anim_driver`) — per-frame rotation/offset of the rat GLB's body + tail nodes: an idle bob, a faster scurry when moving.
- Hook it into `combatant.gd`'s animation update so it's driven by the same idle/chase signal as the rigged enemies.
- If the rat GLB has no separable body/tail child nodes to rotate, fall back to a whole-mesh bob/squash.

## Files

| Path | Action |
|---|---|
| `godot/scripts/rat_anim.gd` | new — procedural rat animation (if A) |
| `godot/scripts/combatant.gd` | modify — drive rat animation alongside the rigged-enemy path |
| `godot/scripts/layout_loader.gd` | modify — tag/wire the rat |
| `docs/GODOT_PIPELINE.md` | modify |

## Acceptance criteria

1. The rat visibly animates — idle bob at rest, faster movement when chasing.
2. The rigged enemies are unaffected.
3. Combat evals still pass; boots clean.

## References

- Spec 11 notes — the rat rig failure
- `src/anim/cow.js` — three.js procedural quadruped animation (the pattern for A)
- `anim_driver.gd`, `combatant.gd`

## Done check

- [ ] Approach chosen (grill)
- [ ] Rat animates — idle + moving
- [ ] Rigged enemies unaffected
- [ ] Evals pass; boots clean
