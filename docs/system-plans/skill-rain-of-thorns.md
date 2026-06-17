---
title: Rain of Thorns
domain: Combat Skills
type: skill
status: partial
effort: M
tags: [wayfinder, plan]
---

# Rain of Thorns

> Delayed AoE nuke whose mechanics are fully wired but whose telegraph VFX is prototype-quality — the next step is a Spec-34-style 4-beat visual stack to match the bar BrambleSnare already sets.

## Current state

The skill class lives at `wyrd/scripts/skills/rain_of_thorns.gd`. `_init()` (line 16) sets `name`, `cost = 32.0`, and `base_cd = 5.0`. `fire()` (line 21) computes a center point clamped at `minf(RANGE, 6.0)` — note `RANGE = 9.0` so this always clamps to 6.0 m, making the constant misleading (line 26–27). A 0.6 s timer (line 32) runs `AoeQuery.query_circle` at `RADIUS = 2.6`, deals `1.8×` damage, and applies a 2s bleed at 0.5 s tick via `SkillEffect.bleed` (line 38). The gameplay contract — damage, bleed, cooldown, Focus cost — is complete and covered by headless tests in `test_wyrd_loop.gd:158-160` and `test_skills.gd:95-100`.

The telegraph (`_telegraph`, line 44) is a bare alpha-cylinder `StandardMaterial3D` disc that sits on the ground and `queue_free`s 0.15 s after the delay. It has no windup animation, no impact beat, no wither, and no landing reticle. It plays `skill_snare` (line 41) — the wrong SFX key (shared with BrambleSnare). Contrast with `bramble_snare.gd`'s Spec-34 5-beat stack: seed projectile, landing reticle, telegraph fill, thorn-snap, wither. Rain of Thorns has none of those beats. Status is **partial**: the mechanical skeleton is complete and tested; the VFX/audio read is a stub.

## Gaps — what needs fleshing out

- **[blocker] Misleading RANGE constant** — `minf(RANGE, 6.0)` always resolves to 6.0; `RANGE = 9.0` is dead. Either remove the cap or expose a separate `CAST_RANGE` constant so the two distances are readable (line 26–27).
- **[blocker] Wrong SFX key** — plays `skill_snare` instead of a thorn-volley-specific key; shares the read with BrambleSnare. Needs a `skill_rain_of_thorns` (or `skill_thorn_volley`) key registered in `sfx.gd` (line 41).
- **Telegraph visual stack is prototype** — the current disc is a single static cylinder. It lacks: a landing reticle snapped at cast time, a growing amber-to-thorn-green fill, a "thorns fall" impact beat at detonation, and a wither dissipation. Benchmark is BrambleSnare's 5-beat structure in `bramble_snare.gd:13-58`.
- **No impact/hit-land beat** — the detonation frame has no visual payoff. Enemies just take damage silently from the engine's perspective; there is no scale-punch, mote burst, or screen micro-kick. See Plan.md Part A §1 (impact-punch pattern) for the toolkit.
- **`take_damage` called without crit args** — line 37 passes `dmg` and a knockback dir but omits `crit_chance` / `crit_mult_bonus`. Compare with `thornburst.gd:27` which passes both. This means Rain of Thorns ignores the player's crit stats.
- **Bleed tick damage is hardcoded to 1** — `SkillEffect.bleed(2.0, 1, 0.5)` on line 38 ignores `player.derived_stats`; bleed never scales with gear. A `max(1, int(dmg * 0.10))` formula would tie it to the attack.
- **No soft-circle texture on the disc** — BrambleSnare uses `res://assets/vfx/soft_circle.png` for billboard particles; RainOfThorns uses a raw `CylinderMesh` with no texture, giving a flat unlit disc.
- **No upgrade/node path defined** — no mastery-tree node or SKILL_REQS entry. Not a gap today (no upgrade system exists), but the expansion phase should reserve a level gate if warranted.

## Plan

### Phase 1 — Correctness fixes (no VFX, just logic)
- Remove or rename the `RANGE`/`6.0` cap: add `const CAST_RANGE := 6.0` and `const MAX_RANGE := 9.0`; use `CAST_RANGE` in `fire()` so intent is explicit. File: `rain_of_thorns.gd:26-27`.
- Pass crit args to `take_damage` matching the `Thornburst` pattern (`crit_chance`, `crit_mult_bonus` from `player.derived_stats`). File: `rain_of_thorns.gd:37`.
- Replace hardcoded bleed `dpt = 1` with `max(1, int(dmg * 0.10))` so bleed tracks gear. File: `rain_of_thorns.gd:38`.
- Register `skill_rain_of_thorns` SFX key in `sfx.gd`; swap the `sfx.play` call. File: `rain_of_thorns.gd:41`.
- **DoD:** `test_wyrd_loop.gd` test at line 158 still passes; a new assertion in `test_skills.gd` verifies `RainOfThorns.fire()` on a mock player with `crit_chance = 0.5` delivers crit-eligible damage; bleed `damage_per_tick` is > 1 when `player.derived_stats.damage = 50`. Run: `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_skills.gd`.
- **Effort: S**

### Phase 2 — Telegraph visual upgrade (Spec-34 4-beat stack)
Bring Rain of Thorns up to the same visual bar as `BrambleSnare` using the same cookbook patterns. Rain of Thorns differs in identity: BrambleSnare *binds*; Rain of Thorns *calls down* — so the visual language should read as a falling volley, not a ground eruption. Four beats:

1. **Landing reticle** — snap a thin amber emissive ring to the ground at cast time (before the delay timer fires), identical to `bramble_snare.gd:_spawn_landing_reticle`. Scale pops in with `TRANS_BACK`; 6 Hz pulse shows it's live. Stays visible through DELAY.
2. **Telegraph fill** — the existing disc grows from a pinprick to `RADIUS` over 0.40 s (longer than BrambleSnare's 0.30 s because Rain of Thorns has 0.6 s total; the fill consumes ~2/3 of the window leaving ~0.2 s at full size before impact). Color: amber `Color(0.95, 0.55, 0.15, 0.40)`.
3. **Impact beat** — at the detonation frame: disc snaps thorn-green, a ring of 6–8 thorn prisms springs up around the perimeter with `TRANS_BACK` overshoot (reuse `_make_thorn` from BrambleSnare), a brief emission burst on the disc (`emission_energy_multiplier` 1.5 → 5.0 → 1.5 over 0.10 s), and a tiny camera micro-kick (`WYRD_SHAKE` toggle-aware; see Plan.md Part A §3).
4. **Wither** — thorns retract + disc alpha-out over 0.25 s; `queue_free` the holder. Reuse `_wither_subtree` pattern from `bramble_snare.gd:541`.

Attach all visuals to a holder `Node3D` parented to the scene root (not the player) so they survive if the player dies mid-delay. Holder `queue_free`d after wither.

- **DoD:** in the Animation Gallery (extend `tools/animation_gallery.gd` with key `R` for RainOfThorns), the 4 beats are visually distinguishable in a screenshot sequence: reticle ring → disc fill → thorn-snap + burst → wither. The fill color is amber, not thorn-green. The disc is never white. Screenshot captured with `WYRD_SHOT=1`. Gate suites green.
- **Effort: M**

### Phase 3 — Polish & balance tuning
These are expansion/polish beats after Phase 2 ships:

- **Projectile anticipation** — add a brief bow-raise + recoil (`player.apply_recoil(-0.3)`) to match the BrambleSnare cast feel; currently `fire()` has no recoil at all (line 21–41).
- **Bleed visual tell** — a small puff of thorn-green particles on each enemy hit at detonation, distinct from the disc itself. Keeps the AoE radius legible when enemies are inside it. Use `GPUParticles3D` parented to the holder, emitting a single burst (not looped). Cap at 6 per cast.
- **Balance review** — compare against BrambleSnare (30 Focus, 4 s CD, root) and Thornburst (30 Focus, 8 s CD, instant AoE). Rain of Thorns at 32 Focus / 5 s CD / 0.6 s delay is defensible but the delay lowers effective value. Playtest with a focus-heavy build to ensure it earns its slot. Target: ≥2 enemies reliably hit per cast at density-light crypt spawns; bleed should extend kill-efficiency by ~15%.
- **Unlock level gate (if warranted)** — Rain of Thorns has no SKILL_REQS entry today (compare `HuntersMark: 4`, `HeartwoodWard: 7`). Consider adding `"RainOfThorns": 5` in `game.gd:118` once the skill pool is more populated and gating makes sense.
- **DoD:** recoil fires at cast time; bleed motes visible on at least 1 enemy in a screenshot; balance pass is sign-off from playtest session. Gate green.
- **Effort: S**

## Dependencies & links

- [[skill-bramble-snare]] — the Spec-34 5-beat VFX pattern is the direct template for Phase 2; `_make_thorn`, `_wither_subtree`, `_spawn_landing_reticle` are all reusable without modification.
- [[system-combat-juice-vfx]] — covers the shared toolkit: disc growth, emission bursts, camera micro-kick. Phase 2 beats draw from the same vocabulary.
- [[system-status-effects]] — `SkillEffect.bleed` factory and `apply_status` on Combatant; Phase 1 bleed scaling lands here.
- [[system-skills-hotbar]] — hotbar dispatch, slot registration in `player_controller.gd:1410`, and the skill pool / SKILL_REQS table in `game.gd:113-118` that Phase 3's gate touches.
- [[system-combatant-ai]] — `take_damage` signature (crit args) that Phase 1 corrects; `apply_status` duck-typing that bleed relies on.
- [[system-audio-music]] — new `skill_rain_of_thorns` SFX key is registered here; Phase 1 is blocked until the key exists.
- Plan.md Part A §1 — the shared animation-toolkit vocabulary (impact punch, TRANS_BACK overshoot, emission burst) that Phase 2 reuses. **Already shipped; do not re-plan.**
- Plan.md Part A §3 — the cross-cutting concerns: centralized tunables, camera shake toggle. Phase 2's micro-kick must respect the shake toggle defined there.

## Verification

**Phase 1 — Correctness:**
```
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
```
Both must stay green. Add a targeted `_check` in `test_skills.gd` asserting: (a) `RainOfThorns` passes crit args through take_damage on a mock target, (b) bleed `damage_per_tick > 1` when `derived_stats.damage = 50`.

**Phase 2 — VFX:**
Extend `tools/animation_gallery.gd` with key `R` firing a `RainOfThorns.fire()` on a stationary dummy. Run gallery under `WYRD_SHOT=1` and capture: (1) reticle ring at t=0, (2) mid-fill amber disc at t≈0.3s, (3) thorn-snap burst at t=0.6s, (4) wither at t≈0.75s. All four frames must be non-white, with the correct colors. Gate suites green.

**Phase 3 — Polish:**
`WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` stays green. Bleed-mote screenshot from the gallery. Balance sign-off is a manual playtest (user).

## Open questions

- Should `CAST_RANGE` stay at 6.0 m or expand to the full `RANGE = 9.0` m? At 6.0 m the caster is inside a 2.6 m burst radius for enemies in melee — intentionally risky, or an oversight? Decision determines whether the Phase 1 rename is cosmetic or a gameplay change.
- Should Rain of Thorns get a level gate (e.g. Wayfinding 5) before the skill pool grows large enough to require pruning? Currently all B5-wave1 skills are ungated; only wave-2 skills (HuntersMark, HeartwoodWard, MercyShot) have SKILL_REQS.
- The bleed tick of `1 dpt` at `0.5s` interval for `2.0s` is currently cosmetic. Scaling to `dmg * 0.10` could make it a real secondary damage source — confirm whether bleed should be "flavor" or "meaningful DoT" before Phase 1 ships.
