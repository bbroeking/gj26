# Implementation notes — 15-enemy-ai-player-hp

## Decisions
- **Combatant: `StaticBody3D` → `CharacterBody3D`.** Enemies need to move; `move_and_slide` gives free wall-sliding. Collision mask = world(1) + player(2) = 3 so they're stopped by walls and don't overlap the player; enemy↔enemy overlap is allowed (no mask bit 4) — simpler, fine for v1.
- **No gravity on enemies.** They move on the XZ plane only (`velocity.y = 0`); the floor is flat. Avoids floor-jitter and a gravity constant.
- **Knockback folded into `velocity`** before `move_and_slide` (spec 14 added it to `position` directly — fine for a StaticBody, wrong for a CharacterBody).
- **Telegraph = scale/tilt punch**, same approach as spec-14's hit-react — works for every enemy regardless of animation clips.
- **Player respawn position** is pushed to `player_controller` by `layout_loader` after `_position_player` (the player's own `_ready` runs before the World positions it, so it can't self-capture the spawn).

## Deviations
- **Eval E9 threshold 16.6 ms → 20 ms.** The physics tick interval is itself
  16.67 ms, so the harness (which measures wall-clock per physics frame)
  can never read below ~16.67 — "< 16.6" was below the measurement floor and
  would fail even at perfect performance. 20 ms (~50 fps) is an honest
  "frame-time not tanking" bar. Spec 14's E9 had the same latent flaw.
- **Player knockback is a one-shot velocity impulse**, not a separately-
  tracked decaying vector. `take_damage` does `velocity += impulse`; the
  existing movement lerp eases it back to the input target. Fewer moving
  parts; the lerp *is* the decay.

## Tradeoffs
- **Straight-line chase, no pathfinding.** Enemies head right at the player
  and let `move_and_slide` scrape along walls. They can briefly hang on a
  wall corner. A* is a deliberate followup, not v1.
- **Enemy↔enemy collision off** (mask = world|player only). Enemies can
  overlap each other — simpler, avoids a clump of enemies jamming in a
  corridor. Acceptable at the eval's enemy counts.

## Surprises
- **Eval test-isolation bugs, not real bugs.** First Section-F run had 3
  fails that were all harness artifacts: enemies spawned stacked at the
  origin so an arrow hit the wrong hurtbox (E7); and F2 measured "did the
  enemy close distance" over a window long enough that the enemy *reached*
  the player and knocked it back — the knockback opened the gap, so the
  chase metric inverted. Fixed by distinct spawn positions + a shorter F2
  window. The combat code itself was correct.

## Status
COMPLETE. Enemies chase + attack, player has HP + death + respawn, HUD
renders, eval harness 15/15 (spec-14 E-checks + spec-15 F1–F6). World boots
clean with 6 AI enemies, no runtime errors.

## Followups
- A* / navmesh pathfinding — enemies currently can hang on wall corners.
- The Hedgemother is just a big melee enemy here; her spec-05 phase machine
  is three.js-side and unported.
- Ranged enemy attacks (bramble-archer) — melee only for now.
- Observational: nobody has *played* the two-sided fight yet — feel of
  aggro range, telegraph readability, respawn pacing all want a play session.
- Real GLB textures (carried from spec 14 — still flat tints).
