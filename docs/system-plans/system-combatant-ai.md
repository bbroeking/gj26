---
title: Enemy AI & Combatant
domain: Enemies & Combat
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Enemy AI & Combatant

> The 3-state FSM, melee, and ranged attacks are all shipped; the next priority is chain-aggro (solo enemies are trivially kited) followed by two new enemy archetypes to broaden the combat vocabulary.

## Current state

`wyrd/scripts/combatant.gd` implements a 3-state FSM (`IDLE → CHASE → ATTACK`, line 47) with
`AGGRO_RADIUS = 7.0m`, `LEASH_RADIUS = 11.0m`, and `ATTACK_RANGE = 1.8m` (lines 32–36). Melee
enemies chase via `NavigationAgent3D` repath 4×/sec (line 43), deal damage on the ATTACK state
transition with a `TELEGRAPH_SEC = 0.35s` windup, and fire through `HitFeedback` for flash +
knockback + hitstop. Ranged enemies (ghost archetype) keep a `RANGED_MIN = 4.0m` standoff and
back away when the player closes (lines 312–319), spawning telegraphed spectral orbs via
`enemy_projectile.gd`. `creature_anim.gd` provides idle breathing/sway, hop-bob, spawn pop-in,
and the attack wind-back → lunge tell — Plan.md Part A Phases 1–5 are all gate-green.

Six enemy kinds are defined in `layout_loader.gd::ENEMY_KINDS` (lines 97–117): skeleton, rat,
ghost, hedge_sprite, bramble_imp, skitterling — each with distinct HP/speed/damage tuned for
archetype feel (B3). Four elite modifiers exist in `data/elites.gd`: brambled (death bleed-nova),
swift (speed + attack rate), sunlit (burn pulse on attack), briarbound (CC-immune window). Status
effects (burn, bleed, snared, root, marked) tick correctly. Per-scope spawn tables in
`SPAWN_TABLES` (layout_loader line 131) make biome encounters feel distinct.

**What is missing:** enemies never alert each other (each wakes individually), there is no
wander/patrol in IDLE, the ranged co-op replication gap is documented-but-open
(`enemy_projectile.gd` line 11), and the archetype roster has no support/buffer enemy and no
slow-heavy bruiser role.

## Gaps — what needs fleshing out

1. **[blocker] Chain aggro / mutual alert** — a player who pulls one enemy can pick off the rest
   one-by-one; rooms have no social tension. No code exists for this.
2. **IDLE wander** — enemies stand frozen at spawn until the player enters range; IDLE does
   nothing except `velocity = 0` (combatant.gd line 305). No patrol or shuffle.
3. **Ranged co-op replication** — orbs + telegraph are host-local only; a guest takes damage from
   an invisible projectile (enemy_projectile.gd known follow-up #1).
4. **Support / buffer archetype** — no enemy that buffs or heals allies; the kit has no "kill
   this one first" priority target.
5. **Bruiser archetype** — no slow, hard-hitting enemy with a long telegraph window (the current
   cast clusters around medium speed). Fills the "read the windup or get chunked" slot.
6. **Telegraph variety** — all melee enemies share the same wind-back→lunge tell; a ground-slam
   AoE telegraph (ring expanding on the floor) would diversify the read-set.
7. **Patrol / random wander** — idle enemies standing stock-still breaks immersion and removes
   the "sneak up" option the FATE camera affords.
8. **Elite modifier depth** — only 4 modifiers; no "protector" modifier that guards nearby allies
   or a "herald" that boosts pack speed within a radius.

## Plan

### Phase 1 — Chain aggro (makes rooms threatening)
- Add `_alert_nearby(radius: float)` to `combatant.gd`: on entering CHASE, query
  `get_tree().get_nodes_in_group("enemy")` within `radius` (start 5m) and transition any IDLE
  ones to CHASE.
- Call from `_tick_ai` on the IDLE→CHASE transition only (not on leash-return) so the chain does
  not propagate infinitely.
- Wire `_aggro_mult` already in `layout_loader` into the alert radius as well: `fog_of_hedge`
  (good affix) shrinks it, bad twin expands it.
- **DoD:** entering a crypt room and shooting one skeleton wakes every skeleton within 5m; a lone
  rat in the far corner stays asleep. Verify with `WYRD_DEV_CHART=crypt` + manual play-test.
- **Effort:** S

### Phase 2 — IDLE wander / shuffle
- Add a `WANDER` sub-state inside IDLE (can be a bool flag, not a new enum value): every
  `WANDER_REPATH = 2.5s` pick a random `NavigationAgent3D` target within 2m of spawn origin;
  move at `move_speed * 0.4` so it reads as "milling around" not "charging".
- Store spawn origin in a `_spawn_pos` var set in `setup()`.
- Wander stops immediately on IDLE→CHASE.
- **DoD:** skeletons shuffle randomly in their spawn cell; they do not wander into adjacent rooms
  (NavMesh + leash radius handles this). Verify visually with `godot --path wyrd` dev boot.
- **Effort:** S

### Phase 3 — Ranged co-op replication
- Add `@rpc("authority", "call_remote", "unreliable")` `spawn_ranged_cosmetic(from, dir)` to
  `combatant.gd`; call it from `_fire_projectile` when `multiplayer.is_server()`.
- Guest-side cosmetic orb sets `_damage = 0` so it cannot double-deal; the host orb carries the
  real damage (existing path unchanged).
- Same pattern for the floor aim-line telegraph: broadcast `spawn_telegraph_cosmetic(dir, length)`.
- **DoD:** two-player session (`WYRD_NET=host` / `join`) — guest sees the orb and its telegraph
  glow before it arrives; damage still routes correctly once only. Headless test is insufficient
  here — requires a two-instance manual play-test.
- **Effort:** M (netcode touch; follow existing `drop_event` broadcast pattern)

### Phase 4 — Support archetype: the Warden
- Add `"warden"` to `ENEMY_KINDS` in `layout_loader.gd`: slow (speed 1.1), moderate HP (20),
  low personal damage (3), `support: true` flag.
- In `combatant.gd _tick_ai`: if `is_support` is true, in CHASE state query for the nearest
  non-self enemy in group `"enemy"` within 6m and move toward it instead of the player (escort
  positioning). When adjacent to an ally AND ally is CHASE/ATTACK, emit a `heal_pulse` every
  `HEAL_INTERVAL = 4.0s` restoring 2 HP to that ally.
- Visually: give the Warden a faint green ring (reuse `_make_root_disc` with green tint, floating
  at chest height) so the player can identify it at a glance.
- Add `"warden"` to the `"hollow"` and `"crypt"` spawn tables at low weight (10).
- **DoD:** killing the Warden first prevents 2-HP heals landing on adjacent skeletons; leaving it
  alive on a 3-skeleton pack makes the skeletons tankier. Verify via manual play-test.
- **Effort:** M

### Phase 5 — Bruiser archetype + AoE telegraph variant
- Add `"barrow_brute"` to `ENEMY_KINDS`: very slow (speed 1.0), high HP (32), high damage (14),
  `atk_cd: 3.0`. Reuse `bramble_imp` model at scale 1.9 until a dedicated asset ships.
- In `combatant.gd _tick_ai` CHASE→ATTACK: if `is_bruiser` flag is set, spawn a floor ring
  `MeshInstance3D` (hollow `CylinderMesh` disc) at `global_position` with the telegraph colour,
  scaling radius 0→`ATTACK_RANGE * 1.6` over `_telegraph_t`. Free on strike. This gives a ground
  AoE read distinct from the current wind-back→lunge tell.
- **DoD:** a brute's 0.7s ring telegraph is readable from 3m away; a player who does not sidestep
  takes 14 damage; one who does takes 0. Verify in play-test with `WYRD_DEV_CHART=crypt`.
- **Effort:** S–M

### Phase 6 — Elite modifier expansion (Herald + Protector)
- Add `"herald"` modifier to `data/elites.gd`: `on_tick` (every 3s) broadcasts a `speed_aura`
  that grants `_move_mult *= 1.25` to all non-elite enemies within 5m for 3s.
- Add `"protector"` modifier: while the elite lives, adjacent non-elite allies within 3m gain
  `_hp_mult` capped at `+4 HP` (one-time bonus applied at spawn via `_elite_on_ready`).
- Both follow the existing dispatch-key pattern in `combatant.gd::_elite_on_attack /
  _elite_on_death` — add `_elite_on_tick(delta)` for the herald.
- **DoD:** a herald elite makes the whole pack visibly faster for 3s bursts; a protector elite
  makes its escorts more durable. Verify by spawning with `WYRD_DEV_CHART=crypt` + forced elite
  kind (dev console).
- **Effort:** M

## Dependencies & links

- [[system-elites]] — elite modifiers (brambled/swift/sunlit/briarbound) already drive runtime
  dispatch in combatant.gd; new herald/protector modifiers extend the same pattern.
- [[system-bosses]] — boss.gd re-uses `_chase_move` from combatant.gd (line 367); chain-aggro
  must not fire for boss bodies (boss rooms are already cleared of regular enemies at build time,
  layout_loader line 814).
- [[system-status-effects]] — snared/root interrupts CHASE (combatant.gd line 286); warden
  heal_pulse must not land while an enemy is rooted-dead or mid-death-tween.
- [[system-combat-juice-vfx]] — the AoE ring telegraph (Phase 5) and the Warden green ring
  (Phase 4) are VFX; they must follow the same `MeshInstance3D`/emissive-unshaded recipe used
  by hit_spark and status visuals.
- [[system-charts-wayfinding]] — `fog_of_hedge` good/bad affix already scales `aggro_radius`
  via `_aggro_mult` (layout_loader line 297); chain-alert radius should use the same multiplier.
- [[system-chart-affixes]] — tyrannical, erratic, festival_pace, lockstep affixes modify HP/speed
  at spawn; a new "volatile pack" affix could enable chain-aggro at longer radius.
- [[system-multiplayer-netcode]] — Phase 3 ranged replication follows the existing host-
  authoritative `drop_event` broadcast pattern; keep authority on the host for both orbs and
  damage.
- [[system-dungeon-generation]] — spawn tables per scope (snug/hollow/briar_maze/crypt) dictate
  where warden and bruiser archetypes first appear; weight them low in early scopes.
- Plan.md Part A (combat-feel Phases 1–5) is **shipped**; this note does not re-plan those. Plan.md
  Part B (loop-feel B0–B7) owns gather/craft/inscribe feel — the Warden's heal ring borrows the
  OmniLight + emissive disc pattern from B2/B6 but does not duplicate those phases.

## Verification

- **Phase 1 (chain aggro):** manual play-test with `WYRD_DEV_CHART=crypt`; confirm a single arrow
  wakes nearby enemies but not the distant pack. No headless coverage needed (pure spatial query).
- **Phase 2 (wander):** visual inspection — run `godot --path wyrd` and watch enemies shuffle.
  Confirm they do not path outside their spawn cell.
- **Phase 3 (ranged co-op):** two-instance local test with `WYRD_NET=host` / `WYRD_NET=join:127.0.0.1`.
  Confirm orb + telegraph visible on guest, damage lands once. Run existing headless suites
  (`WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd`) to
  confirm no regression in host-only mode.
- **Phases 4–5 (new archetypes):** add a targeted smoke-test in `test_wyrd_dungeon_scene.gd`:
  force-spawn a warden + two skeletons, tick several frames, assert that skeleton HP increases by
  2 after `HEAL_INTERVAL`; force-spawn a brute, assert `take_damage` lands 14 on player when
  not dodged.
- **Phase 6 (new elites):** extend the existing elite-modifier test path in
  `test_wyrd_dungeon_scene.gd`: spawn a herald elite + two rats, tick 3s, assert rats have
  `_move_mult > 1.0`.
- All headless runs: `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://<suite>.gd`

## Open questions

- **Warden model:** use an upscaled `hedge_sprite` as placeholder (same GLB, tinted green-gold)?
  Or block out a unique silhouette (staff-carrier) before Phase 4 ships?
- **Chain aggro radius vs. fog_of_hedge affix:** should the alert radius be a separate affix knob
  or always track `_aggro_mult`? Unified tracking is simpler but blends two readable concepts.
- **Bruiser telegraph timing:** 0.7s is longer than any current tell (skeleton = 0.35s, ghost ≥ 0.6s).
  Play-test should confirm whether it reads as "readable danger" or "free punish window."
