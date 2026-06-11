# Implementation notes — 14-fluid-combat

## Decisions
- **Section 0 re-scoped after diagnosis.** The spec assumed two clean bugs (walk root motion, bow socket scale). Diagnosis disproved both: the walk clip has no root-motion track (all 40 tracks are bone tracks); the bow is correctly sized (~1.6 m, scale 1) and `socket_hand_R` scale is (1,1,1). The real issues are (a) wall occlusion at the 55° ARPG angle and (b) GLB textures not reading in Godot (white-blob look). Section 0 became: wall-occlusion fade + solid stylized tints.
- **Solid tints over real textures.** Fighting Godot's per-GLB texture import is an open-ended rabbit hole; solid per-kind toon colors are deterministic, on-style for low-poly, and the minimum-vertical-slice call. Tints: skeleton bone, rat brown, ghost cyan, hedge-sprite moss, hedgemother bramble, Ranger green, bow wood-brown.
- **Wall occlusion = raycast + alpha fade.** Each frame the camera rig raycasts camera→player; walls (group `"wall"`, per-wall alpha material) in the path drop to alpha 0.25, restore to 1.0 when clear.

## Deviations
- Section 0 ≠ the spec's "two clean bug fixes" — see Decisions. Same intent (player visible, build not broken-looking), different actual work.

## Tradeoffs
- Flat tint loses per-character texture detail. Acceptable at the eval's ARPG zoom + low-poly toon style; real textures are a followup if the engine decision lands on Godot.

## Surprises
- **The "disappearing player" could not be reproduced as a hard bug.** Verified: camera aims at the player (dot 0.999), player Y stable, Mesh/Armature don't drift. Strongest explanation was wall occlusion — addressed by the fade. Spent a large number of diagnostic cycles ruling out root motion / camera / falling before reaching this.
- **Diagnosis cost.** Section 0 alone consumed a disproportionate number of run/screenshot iterations. The Godot evaluation has hit asset/rendering friction at nearly every spec (07–14).

## Status
COMPLETE. Section 0 (occlusion + tints) + Sections A–E (combat + juice +
evals) all implemented. The engine decision landed on **Godot** mid-spec.

## Sections A–E — decisions
- **Hitstop = `Engine.time_scale` near-zero** for 0.09 s via a `Hitstop`
  autoload, restored by an `ignore_time_scale` timer. A `_token` counter
  means rapid hits don't end the freeze early.
- **Hitstop autoload referenced by path**, not by global name —
  `get_node_or_null("/root/Hitstop")`. Autoloads are NOT registered under a
  headless `--script` run, so a direct `Hitstop.` reference fails to
  compile; the path lookup compiles fine and the eval harness stands up its
  own Hitstop node.
- **`KNOCKBACK` is a distance, not a speed.** First implementation used the
  0.6 value as the initial velocity → only ~0.05 m of travel (eval E5
  failed at 0.024 m). Fixed: initial velocity = `KNOCKBACK * KNOCKBACK_DECAY`
  so the decaying slide integrates to ~0.6 m. E5 now reports 0.599 m.
- **Combatant = `StaticBody3D` + script**, built by `layout_loader` via
  `CombatantScript.new()`. Enemy HP 18, boss 60. Hit-react is a procedural
  scale-punch (the GLBs have no hit clip).
- **Eval harness covers 8 of 10 metrics automated** (E2–E9). E1 (fire→spawn
  latency) is ≤1 frame by construction — `_fire_arrow()` instantiates
  synchronously. E10 (input buffering) is deterministic timing logic in
  `player_controller`; not Input-simulated headlessly.

## Evals — baseline result
`godot --headless --path godot --script res://test_combat.gd` → **9 PASS,
0 FAIL** (E2 hit registers, E3 no dup, E4/E4b hitstop fires+restores, E5
knockback 0.599 m, E6 damage number, E7 death, E8 arrow cleanup, E9 60 fps
under a 10-arrow volley).

## Followups
- Real GLB textures (vs the flat tints) — deferred; tints are the
  vertical-slice call.
- Wall-occlusion fade implemented but not confirmed in a live play session
  (verified only that it boots clean).
- Observational evals O1–O3 (does the hit *feel* fluid) need a human play
  session — the harness can't judge feel.
- Enemy attack-back / player HP — deliberately out of scope (next spec).
- E1/E10 are covered-by-design, not in the automated harness.
