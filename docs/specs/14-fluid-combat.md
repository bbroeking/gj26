# 14 — Fluid ranged combat for the Godot build

> **Outcome**: arrows fired from the Ranger's bow actually *hit* — enemies have HP, take damage, react, and die. And it **feels fluid**: input is buffered, hits land with hitstop + a flash + a floating damage number + knockback + an impact spark. A headless eval harness (`test_combat.gd`) measures the fluidity proxies against numeric thresholds, so "fluid" is a pass/fail, not a vibe.

## Why

Spec 13 wired the Ranger to fire arrows, but the arrows do nothing — they fly and despawn. There's no damage, no enemy HP, no feedback. This spec turns that into a combat *loop* — fire → hit → react → kill — and invests in the game-feel layer (hitstop, juice, responsiveness) that makes an ARPG combat system read as "fluid." Per the minimum-vertical-slice decision, this is the smallest combat that proves the loop and the feel; it is not a port of the three.js `combat.js` formula stack.

The research the spec is built on: input buffering, hitstop/hitlag, animation-cancel, the "juice" feedback layer, and Godot 4's Area3D hitbox/hurtbox pattern (with single-hit dedup) — see References.

## Scope

**In:**

### 0. Prerequisite fixes (spec 13 carryover — combat can't be evaluated without these)
- **Player disappears when moving** — the Ranger's `walking_man` clip carries root motion that translates the skeleton off the `CharacterBody3D`. Strip the root-motion track on import (or zero the root track at runtime) so the walk plays in place.
- **Bow renders as a giant white orb** — `prop_bow_v1.glb` parented to `socket_hand_R` inherits a large bone-space scale. Counter-scale the bow against the socket's world scale (or attach via a fixed local transform) so it reads as a bow.

### A. Damage pipeline (Area3D hitbox / hurtbox)
- Arrows get a **hitbox** Area3D (on the `enemies` collision mask) that reports the first body/area it overlaps.
- Enemies get a **hurtbox** Area3D + an `hp` / `hp_max` and a `take_damage(amount, from_dir)` method. A small `enemy.gd` (or `combatant.gd`) script holds the state.
- **Single-hit dedup** — an arrow damages a given enemy exactly once, then despawns (research flagged the Area3D duplicate-hit race; use a "already hit" guard).
- Arrow `damage` is a tunable constant.

### B. Hit feedback — the "juice"
- **Hitstop** — on a hit, freeze for a short window (~80–120 ms) via `Engine.time_scale` or a per-actor freeze. Restores automatically.
- **Enemy flash** — the struck enemy flashes white/bright for ~120 ms (material albedo override, restored after).
- **Floating damage number** — a number spawns at the hit point and rises + fades (`damage_number.gd` + a label/Sprite3D).
- **Knockback** — the enemy is shoved a short distance along the arrow's travel direction.
- **Impact spark** — a brief particle/flash burst at the hit point.

### C. Responsiveness
- **Input buffering** — a fire press during the cooldown is queued (one slot) and fires the instant the cooldown clears, so a slightly-early press is never dropped.
- Fire cooldown stays a tunable (from spec 13).
- Animation-cancel: minimal — firing should not be gated behind a long animation; note anything deeper as a followup.

### D. Enemy reaction + death
- On `take_damage`: play a hit-react (stagger — a quick scale/tilt punch if no hit clip exists) + the flash + knockback.
- HP ≤ 0 → death: a brief death tween (sink + fade or topple), then despawn. No respawn.
- Enemies remain **stationary targets** for v1 — they react and die but do not chase or attack back (see Open decisions).

### E. Evals — `test_combat.gd` headless harness
A `SceneTree` script, run `godot --headless --path godot --script res://test_combat.gd`, that drives the combat systems directly and prints `PASS`/`FAIL` per metric with a final summary. Automatable metrics + thresholds in the **Evals** section below.

**Out (explicit non-goals):**
- Melee combat — the player is the Ranger (ranged); the knight isn't the Godot player.
- Enemy attack AI / enemy chasing / player HP + player death (Open decisions — recommend defer).
- Porting `src/game/combat.js` formulas, XP, levels, loot.
- The boss phase machine (spec 05 is three.js-side).
- Three.js — Godot-only.
- Status effects, crits, elemental damage.

## Files

| Path | Action |
|---|---|
| `godot/scripts/player_controller.gd` | modify — root-motion fix, bow scale fix, fire input buffer |
| `godot/scripts/arrow.gd` | modify — hitbox Area3D, damage on overlap, single-hit guard |
| `godot/scenes/Arrow.tscn` | modify — add the hitbox Area3D + CollisionShape3D |
| `godot/scripts/combatant.gd` | new — hp, take_damage(), hit-react, flash, knockback, death |
| `godot/scripts/damage_number.gd` | new — floating rise+fade number |
| `godot/scenes/DamageNumber.tscn` | new |
| `godot/scripts/hitstop.gd` | new — global hitstop helper (autoload or static) |
| `godot/scripts/layout_loader.gd` | modify — attach `combatant.gd` + hurtbox to spawned enemies |
| `godot/test_combat.gd` | new — the eval harness |
| `docs/GODOT_PIPELINE.md` | modify — combat + how to run the eval |

## Acceptance criteria

1. The player (Ranger) is visible and stays visible while moving — no disappearing.
2. The bow reads as a bow on the Ranger's hand — no white orb.
3. Firing an arrow into an enemy reduces that enemy's HP by the arrow's damage, exactly once.
4. A hit produces: hitstop, an enemy flash, a floating damage number, and visible knockback.
5. An enemy reduced to 0 HP plays a death effect and despawns.
6. A fire press during cooldown is buffered and fires when the cooldown clears.
7. Arrows always despawn (hit or lifetime) — no accumulation.
8. `test_combat.gd` runs headless and every automatable eval prints `PASS`.
9. The scene boots and runs combat with no errors.

## Evals

`test_combat.gd` — deterministic, headless, prints `PASS`/`FAIL` + a summary line. Automatable metrics:

| # | Metric | Threshold |
|---|---|---|
| E1 | **Fire→spawn latency** — frames from `fire()` to the arrow existing | ≤ 2 physics frames |
| E2 | **Hit registration** — enemy HP delta after one arrow | exactly `arrow.damage`, once |
| E3 | **No duplicate hits** — one arrow vs one enemy | exactly 1 damage event |
| E4 | **Hitstop fires** — freeze window after a hit | within [60, 160] ms, then restored |
| E5 | **Knockback** — enemy position delta along arrow dir | > 0.05 m |
| E6 | **Damage number** — a DamageNumber node spawned per hit | exactly 1 |
| E7 | **Death** — enemy at low HP, hit → death state | within 90 frames |
| E8 | **Arrow cleanup** — arrow nodes in scene after all resolve | 0 |
| E9 | **Frame budget** — avg physics frame time over a 10-arrow volley | < 16.6 ms |
| E10 | **Input buffer** — fire pressed mid-cooldown | fires exactly once when cooldown ends |

Observational evals (need a human / screenshot — can't be auto-asserted):
- O1 — the flash + hitstop *read* as an impact (not too subtle, not jarring).
- O2 — knockback distance feels proportional, not floaty or rigid.
- O3 — firing feels instant — no perceptible lag from key to arrow.

The spec is "done" when E1–E10 all `PASS` and O1–O3 are confirmed in a play session.

## Open decisions

- **Enemy attack-back / player HP.** Recommend **defer** — v1 enemies are reacting targets. "Fluid" is about how *landing a hit* feels (responsiveness + feedback); enemies fighting back is a separate axis (challenge) and pulls in enemy AI + player HP + player damage feedback. Note as the obvious next spec.
- **Hitstop scope.** Global `Engine.time_scale` (everything freezes — strong, simple) vs per-actor freeze (only the hit pair pauses). Recommend **global** for v1 — one helper, classic ARPG feel; per-actor is a followup if global feels too heavy.
- **Damage number rendering.** `Label3D` (world-space, billboarded) vs a 2D overlay projected from world pos. Recommend **`Label3D`** — no projection math, billboards itself.
- **Hit-react animation.** The crypt enemies have only an idle clip; no hit clip. Recommend a **procedural stagger** (quick scale-punch + tilt) so it works for every enemy regardless of clips.
- **Arrow hitbox vs the existing raycast.** Spec 13's arrow despawns on a world raycast. Add a separate Area3D hitbox for *enemies* (the raycast still handles walls). Recommend keeping both — ray for walls, Area3D for enemy hits.
- **Tunables** — starting values: `ARROW_DAMAGE` 6, `HITSTOP_MS` 90, `FLASH_MS` 120, `KNOCKBACK` 0.6 m, `INPUT_BUFFER_MS` 150. Tune against the observational evals.

## References

- [Hitstop / hitlag — Celia Wagar's CritPoints](https://critpoints.net/2017/05/17/hitstophitfreezehitlaghitpausehitshit/)
- [Combat Design: Animation Priority vs Cancellable Offense — ResetEra](https://www.resetera.com/threads/combat-design-in-action-games-animation-priority-vs-cancellable-offense.169357/)
- [The "Juice" Factor: Designing Game Feel](https://hackread.com/the-juice-factor-designing-game-feel/)
- [Hitbox/hurtbox in Godot 4 — GDQuest](https://www.gdquest.com/library/hitbox_hurtbox_godot4/) + [demo repo](https://github.com/gdquest-demos/godot-4-hitbox-hurtbox)
- [Area3D duplicate-hit race + fix — Dre Dyson](https://dredyson.com/fix-using-area3d-for-hurt-hit-boxes-and-getting-duplicate-hits-in-under-5-minutes-actually-works-a-quick-step-by-step-fix-guide-for-godot-4-developers/)
- Spec 13 (Ranger weapon) + notes — the 2 prerequisite bugs
- `godot/scripts/arrow.gd`, `player_controller.gd`, `layout_loader.gd`

## Done check

- [ ] Player visible while moving (root-motion fix)
- [ ] Bow reads as a bow (socket-scale fix)
- [ ] Arrow hitbox + enemy hurtbox + HP + `take_damage`
- [ ] Single-hit dedup
- [ ] Hitstop, flash, damage number, knockback, impact spark
- [ ] Input buffering for fire
- [ ] Enemy hit-react + death + despawn
- [ ] `test_combat.gd` — E1–E10 all PASS headless
- [ ] O1–O3 confirmed in a play session
- [ ] No boot/runtime errors
- [ ] `GODOT_PIPELINE.md` updated (combat + eval-run command)
