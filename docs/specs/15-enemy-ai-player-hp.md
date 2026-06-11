# 15 — A real fight: enemy AI, attacks, player HP + death

> **Outcome**: the Godot crypt becomes an actual fight, not a shooting gallery. Enemies wake when you get close, chase you, and hit you. You have HP, take damage with feedback, and can die — death respawns you at the entry. A headless eval harness proves the two-sided loop works.

## Why

Spec 14 made *landing a hit* feel good — but enemies are inert reacting targets and the player can't be hurt. There are no stakes. This spec closes the loop: enemies attack back, the player has health, and the player can lose. That's the difference between "shoot dummies" and "a playable game." Per the minimum-vertical-slice principle, this is the smallest two-sided combat that's actually a fight — not a port of the three.js AI/aggro stack.

## Scope

**In:**

### A. Enemies become mobile
- `Combatant` is currently a `StaticBody3D` (spec 14). Convert the enemy body to a `CharacterBody3D` so it can move. (Spec 10 notes flagged `_spawn_character` as the single place to change.)
- The boss stays the same body type as the enemies — it becomes a big tanky melee enemy for now (the spec-05 phase machine is three.js-side and not ported; note it).

### B. Enemy AI — a 3-state machine on `combatant.gd`
- **idle** — plays idle/bind pose, until the player enters `AGGRO_RADIUS`.
- **chase** — move toward the player (straight-line; `move_and_slide` handles wall-sliding — no A* pathfinding in v1, note as followup), play the walk clip.
- **attack** — within `ATTACK_RANGE`: stop, play a short **telegraph** (~0.35 s — a scale/tilt tell), then deal `ENEMY_DAMAGE` to the player once, then a cooldown, then back to chase/attack.
- A dead combatant (spec 14 death) leaves the state machine.

### C. Player HP + damage
- `player_controller` gets `hp` / `hp_max` and `take_damage(amount, from_dir)`.
- Hit feedback for the player: a brief **hitstop** (reuse the `Hitstop` autoload), a **screen flash** (red vignette / full-screen ColorRect pulse), a small **knockback**, and an i-frame window so a single enemy can't chain-stun.
- Damage numbers over the player on hit (reuse `DamageNumber.tscn`), optional.

### D. Player death + respawn
- `hp <= 0` → death: a brief freeze + a "Defeated" beat, then **respawn at the entry tile** with full HP (reuse `layout_loader`'s entry position / the kill-plane respawn path).
- Enemies are not reset on respawn (simplest) — note it.

### E. Minimal HP HUD
- An on-screen player HP readout — a `CanvasLayer` + a bar (`ColorRect` fill) or a `Label` (`HP 24 / 30`). Minimal, readable, updates on damage/heal/respawn.

### F. Evals — extend `test_combat.gd`
New headless checks (PASS/FAIL), alongside spec 14's E1–E10:
- enemy aggros when the player enters `AGGRO_RADIUS`
- enemy in `chase` moves measurably toward the player
- an enemy attack reduces player HP by `ENEMY_DAMAGE`, once per attack
- player i-frames block a second hit inside the window
- `player.take_damage` to 0 → death state
- respawn restores HP to `hp_max` and position to entry

**Out (explicit non-goals):**
- A* / navmesh pathfinding — straight-line chase only (followup).
- Ranged enemy attacks (bramble-archer firing arrows back) — melee only.
- The Hedgemother phase machine — boss is a big melee enemy for v1.
- XP, loot, skills, inventory.
- Enemy aggro propagation / packs / leashing.
- Difficulty tuning beyond first-pass constants.
- Three.js side.

## Files

| Path | Action |
|---|---|
| `godot/scripts/combatant.gd` | modify — CharacterBody3D, 3-state AI, telegraph, attack |
| `godot/scripts/player_controller.gd` | modify — hp, take_damage, i-frames, death, respawn |
| `godot/scripts/layout_loader.gd` | modify — `_spawn_character` builds a CharacterBody3D combatant; pass the player ref / entry |
| `godot/scripts/player_hud.gd` | new — HP readout |
| `godot/scenes/PlayerHUD.tscn` | new — CanvasLayer + bar |
| `godot/scenes/World.tscn` | modify — add the HUD |
| `godot/test_combat.gd` | modify — the Section F evals |
| `docs/GODOT_PIPELINE.md` | modify — combat loop + controls + eval note |

## Acceptance criteria

1. An enemy stays idle until the player approaches, then visibly chases.
2. A chasing enemy that reaches the player telegraphs, then deals damage — the player's HP drops.
3. The HP HUD shows the player's current HP and updates on every hit.
4. Getting hit produces feedback — screen flash + hitstop + knockback.
5. I-frames prevent a single enemy from chain-stunning the player to death instantly.
6. Player HP to 0 → death → respawn at the entry with full HP.
7. Arrows still kill enemies (spec 14 loop intact).
8. `test_combat.gd` — spec 14's E-checks still pass AND the Section F checks pass, all headless.
9. The scene boots and runs a full fight with no errors.

## Open decisions

- **Enemy body type.** `CharacterBody3D` (recommended — real movement + `move_and_slide` wall-sliding) vs `AnimatableBody3D`. Recommend `CharacterBody3D`.
- **Chase pathing.** Straight-line toward the player, let `move_and_slide` scrape along walls. Recommended for v1 — A* is a separate spec. Enemies may briefly hang on a wall corner; acceptable, noted.
- **Telegraph style.** A scale/tilt "wind-up" punch (recommended — works for every enemy regardless of clips, same approach as the spec-14 hit-react) vs a ground decal (spec 05's boss style — heavier). Recommend scale/tilt.
- **Player feedback.** Screen-edge red flash (recommended — clear, cheap, a `ColorRect` on a `CanvasLayer`) vs a 3D damage number only. Do both; the flash is the primary read.
- **Death handling.** Respawn-at-entry, full HP, enemies unchanged (recommended — simplest, keeps the run going). Alt: full scene reload. Recommend respawn.
- **Tunables** — first pass: `AGGRO_RADIUS` 7, `ATTACK_RANGE` 1.6, `ENEMY_DAMAGE` 5, `ENEMY_ATTACK_COOLDOWN` 1.5 s, `TELEGRAPH` 0.35 s, `PLAYER_HP` 30, `PLAYER_IFRAMES` 0.6 s, `ENEMY_MOVE_SPEED` 2.5. Tune after a play session.

## References

- Spec 14 (the one-sided combat this extends) + notes — `combatant.gd`, `Hitstop`, `arrow.gd`
- Spec 10 — collision layers; `_spawn_character` flagged as the place to swap the body type
- `godot/scripts/player_controller.gd`, `layout_loader.gd`, `test_combat.gd`
- Three.js combat for reference only (not ported): `src/game/combat.js`, `src/game/enemies.js`

## Done check

- [ ] Enemy body is `CharacterBody3D`
- [ ] idle → chase → attack state machine
- [ ] Enemy attack telegraph + damages the player
- [ ] Player HP + `take_damage` + i-frames
- [ ] Player hit feedback — screen flash + hitstop + knockback
- [ ] Player death → respawn at entry, full HP
- [ ] HP HUD renders + updates
- [ ] Arrows still kill enemies
- [ ] `test_combat.gd` — spec 14 E-checks + Section F checks all PASS
- [ ] No boot/runtime errors
- [ ] `GODOT_PIPELINE.md` updated
