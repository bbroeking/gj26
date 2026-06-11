# 32 — Pack scaling + elites

> **Outcome**: combat rooms feel populated (4–10 trash per room, scaled by depth) and each one *might* carry an elite. The elite reads as elite at spawn (golden tint + scale boost + feet-ring), travels with 2–3 same-kind retinue, drops better loot, and carries one of four storybook-flavoured modifiers that meaningfully change how the fight plays. Sunlit forces you to move out of its melee aura; Brambled punishes the kill with a bleed nova; Swift kites; Briarbound dodges your Bramble Snare for 4s after the first one lands.

## Why

This is the pack-scaling spec the entire `/improve-codebase-architecture` pre-arc (32a–d) cleaned the ground for:
- **32a (Pickup deepening)** — elite loot now flows through one `ItemPickup.spawn` seam; no per-spawn boilerplate to copy.
- **32b (Skill + SkillEffect)** — on-hit consequences are data; if elites ever fire projectiles, they plug into the same data structure.
- **32c (HitFeedback)** — the elite's golden tint coexists with hit flashes via the existing `_saved` material-override stack.
- **32d (Interactable base)** — orthogonal to elites, but the discipline of naming seams transfers (elite modifiers as data, not branches).

Today's dungeons feel sparse (2–5 trash per combat room, no elites). The research synthesis (`docs/specs/32-pack-scaling-research.md`) is unambiguous on what FATE/D3/PoE 2 converge on: density + elite hierarchy + visual unambiguity. This spec ships that.

## Scope

### In

- **`data/elites.gd`** *(new)* — modifier table + factory. Mirrors `data/affixes.gd` / `data/items.gd` shape:
  ```gdscript
  class_name Elites
  const MODIFIERS := {
    "brambled": {
      "name": "Brambled", "hp_mult": 1.25, "scale_mult": 1.25,
      "tint": Color(1.0, 0.92, 0.55),
      "on_death": "bleed_nova",       # dispatched by combatant._die when is_elite
    },
    "swift": {
      "name": "Swift", "hp_mult": 1.0, "scale_mult": 1.15,
      "tint": Color(1.0, 0.92, 0.55),
      "move_mult": 1.5, "attack_speed_mult": 1.2,
    },
    "sunlit": {
      "name": "Sunlit", "hp_mult": 1.5, "scale_mult": 1.25,
      "tint": Color(1.0, 0.92, 0.55),
      "on_attack": "burn_pulse",      # dispatched on melee swing
    },
    "briarbound": {
      "name": "Briarbound", "hp_mult": 1.3, "scale_mult": 1.15,
      "tint": Color(1.0, 0.92, 0.55),
      "cc_immune_window": 4.0,        # after first root/snared, immune for this long
    },
  }
  static func pick_random(rng: RandomNumberGenerator) -> String:
      var keys: Array = MODIFIERS.keys()
      return keys[rng.randi_range(0, keys.size() - 1)]
  ```
- **`combatant.gd::apply_elite(modifier_key: String)`** — new public method. Reads `Elites.MODIFIERS[modifier_key]`, applies:
  1. `is_elite = true`, `modifier = modifier_key`, `role = "elite"` (for the drops pipe)
  2. `hp_max *= hp_mult` and `hp = hp_max`
  3. `scale *= scale_mult` (the visual scale boost)
  4. Sets a persistent golden tint material on every `_meshes` entry (uses the spec 32c `apply_flash` infrastructure but bypasses the `_flash_t` timer — see Decisions below)
  5. Spawns a feet-ring `GPUParticles3D` child in the elite tint colour
  6. For "swift": stores `_move_mult` and `_attack_speed_mult` as Combatant fields, used by `_chase_move` and `_attack_cd` respectively
  7. For "briarbound": initializes `_cc_immune_until = 0.0`
- **`combatant.gd::is_elite: bool`** and **`modifier: String`** — new fields, default `false`/`""`.
- **`combatant.gd::_move_mult: float = 1.0`** and **`_attack_speed_mult: float = 1.0`** — new fields (used by Swift modifier; default 1.0 means no effect for non-elites). `_chase_move` multiplies `MOVE_SPEED * slow_product * _move_mult`. `_attack_cd` (in attack-resolve) divides by `_attack_speed_mult`.
- **`combatant.gd::_cc_immune_until: float = 0.0`** — new field for Briarbound. `apply_status` for `"root"` and `"snared"` checks this — if `Time.get_ticks_msec() / 1000.0 < _cc_immune_until`, return null; on first successful root/snared, set `_cc_immune_until = Time.get_ticks_msec() / 1000.0 + cc_immune_window`.
- **`combatant.gd::_die()` modifier dispatch** — if `is_elite` and `MODIFIERS[modifier].has("on_death")`:
  - `"bleed_nova"` (Brambled): `AoeQuery.query_circle(get_tree(), global_position, 2.5, "enemy")` → for each, `apply_status("bleed", 4.0, 1, 1.0, 1.0)`. Plus a quick visual: an emerald disc fading over 0.5s (reuses the spec 30 Snare disc pattern).
- **`combatant.gd::_attack_resolve()` modifier dispatch** — on the moment damage lands on the player (inside `_tick_ai`'s ATTACK state):
  - `"burn_pulse"` (Sunlit): `AoeQuery.query_circle(get_tree(), global_position, 2.5, "player")` → for each (just the player, normally), `apply_status("burn", 3.0, 1, 1.0, 0.5)`. Plus a brief orange flash patch under the elite (~0.5s fade).
- **`data/drops.gd::ROLE_DROP_CHANCE` and `ROLE_TIER_BIAS`** — add `"elite": 1.0` and `"elite": 1` respectively. Slots in cleanly between combat and treasure.
- **`layout_loader.gd::_build_enemies` rewrite**:
  - Per room, compute `n` per role with the new combat formula: `n = 4 + clampi(depth / 2, 0, 6)` for combat rooms (was `2 + clampi(depth / 2, 0, 3)`)
  - Elite roll: `if _rng.randf() < float(n) / 8.0:` → pick `elite_idx = _rng.randi_range(0, n - 1)`, save the modifier kind via `Elites.pick_random(_rng)`
  - In the spawn loop, if `k == elite_idx`: spawn the enemy with the chosen kind (idx) AND retinue alongside — spawn `_rng.randi_range(2, 3)` extra enemies of the *same kind* (`idx`) at positions within 2.5m of the elite's tile (use existing `_room_floor_tiles` to find adjacent valid tiles, fall back to nearest available)
  - After spawning the elite combatant, call `enemy.apply_elite(modifier_kind)`
- **`layout_loader.gd::_spawn_enemy` signature extension** — accept an optional `forced_idx: int = -1` so the retinue can be forced to use the same kind as the elite. Existing callers pass `-1` (no change to default behaviour).
- **Eval coverage**: extend `test_combat.gd` with three new evals in a new Section I:
  - **I1** — `combatant.apply_elite("brambled")` makes `is_elite == true`, `role == "elite"`, `hp_max == int(base_hp * 1.25)`, scale boosted by 1.25×, golden tint material override present on `_meshes`.
  - **I2** — Briarbound modifier: first `apply_status("root", 2.0, ...)` succeeds; second call within 4s returns null (immune).
  - **I3** — Brambled death-nova: kill an elite Brambled near a non-elite enemy; the non-elite has `bleed` status after death.

### Out (explicit non-goals)

- **`Hearthwarden`** (tank, ranged damage falloff) and **`Wisp-sworn`** (orbital projectile) modifiers from the research. Cut to v1 per the grill (Q2 lean: 4 modifiers, not 6). Both add new mechanics (damage-pipe falloff, orbital AI) too heavy for this spec.
- **All-elite packs** (D3 Champion model — 3–5 identical elites). Defer to spec 33+.
- **Champion / Rare hierarchy** (D3's two-tier). One elite tier in v1.
- **Elite name plates / boss-bar-style banners**. The visual triple-channel (tint + scale + ring) carries the load. Boss-bar territory.
- **Per-modifier SFX cue at spawn** (e.g. "fwoom" when a Sunlit appears). Skip; visual is enough. If playtest signals more contrast needed, add later (~$0.10 per gen).
- **Damage-number color for elite hits**. Spec 32c's HitFeedback handles hit visuals; elite-specific damage numbers are polish.
- **Spec 33 "loot rain" feel** — that's its own roadmap item (Phase A #4). Elite kills still drop 1 item via the new `"elite"` drop role, but the *celebration* (visual pop, slow-mo, screen flash) lands later.
- **Brambled visual upgrade** to actual bramble vines wrapping the elite. v1 uses the generic feet-ring + golden tint; species-specific elite visuals are an art-pipeline followup.
- **Modifier-on-modifier interactions** (e.g. "what if a Briarbound is also Swift?"). v1 picks ONE modifier per elite — structurally impossible. PoE-style modifier stacking is spec 33+.

## Files

| Path | Action |
|---|---|
| `godot/data/elites.gd` | **new** — modifier table + factory (~30 lines) |
| `godot/scripts/combatant.gd` | Add `is_elite`, `modifier`, `_move_mult`, `_attack_speed_mult`, `_cc_immune_until` fields. Add `apply_elite(modifier_key)` method. Extend `apply_status` to gate on `_cc_immune_until` for root/snared. Extend `_chase_move` to multiply by `_move_mult`. Extend `_attack_cd` decrement by `_attack_speed_mult`. Extend `_die` to dispatch `"on_death"` modifier effects. Extend the attack-resolve branch to dispatch `"on_attack"` modifier effects. |
| `godot/scripts/layout_loader.gd` | Rewrite `_build_enemies` to use the new pack formula + elite roll + retinue spawn. Extend `_spawn_enemy` with optional `forced_idx`. |
| `godot/data/drops.gd` | Add `"elite"` to `ROLE_DROP_CHANCE` and `ROLE_TIER_BIAS`. |
| `godot/test_combat.gd` | Add Section I (3 evals): elite stats, Briarbound CC-immunity, Brambled death-nova. |
| `CONTEXT.md` | Add `Elite` + `Modifier` (or just `Elite`) entry. |
| `docs/GODOT_PIPELINE.md` | Brief "Pack scaling + elites (spec 32)" section pointing here. |

## Acceptance criteria

1. Combat-room enemy counts: at depth 0, 4 trash; at depth 6, 10 trash. Verifiable via `test_combat.gd` or a layout_loader log line.
2. Elite roll: across 10 dungeons, total elite count ≈ `total_trash / 8` (probabilistic; the test uses a wide tolerance).
3. A combat room with an elite spawns that elite + 2–3 same-kind retinue within 2.5m of the elite's tile.
4. The boss room contains no elites.
5. Each elite is *visually* unambiguous: golden material tint on all meshes, scale ≥ 1.15×, GPUParticles3D feet-ring child node present.
6. `apply_elite("brambled")` bumps HP by 25%, sets `is_elite = true`, sets `role = "elite"`.
7. Killing a Brambled elite near a non-elite enemy applies `bleed` to the non-elite (death-nova).
8. A Sunlit elite's melee swing applies `burn` to anything within 2.5m (in v1: the player).
9. A Briarbound elite, after one successful `apply_status("snared", ...)`, refuses further `"root"`/`"snared"` applications for 4 seconds.
10. A Swift elite moves at 1.5× the base speed and attacks at 1.2× the base cadence.
11. Killing an elite drops at least one item (chance = 1.0 in the new `"elite"` drop role).
12. `test_combat.gd` Section I (3 evals) passes; every other harness still green.
13. World boots, manual playtest shows ~0–1 elite per combat room with depth-scaled trash density.

## Open decisions (resolved by grill)

All five core decisions resolved. Mini-decisions resolved by lean:

- **`apply_elite` bypasses `_flash_t`** — the elite's golden tint is *persistent*, not a flash. Implementation: apply the tint material directly via `material_override` on each `_meshes` entry at elite spawn (mirrors what `apply_flash` does, but doesn't set `_flash_t`). When a hit-flash fires, `_apply_flash`'s existing `_saved` dict captures the golden material, swaps to white, and the post-flash restoration brings the golden tint back. No new infrastructure — reuses the spec 32c restoration path.
- **`_attack_speed_mult` divides `_attack_cd`** — `_attack_cd = ATTACK_COOLDOWN / _attack_speed_mult`. Default 1.0 = no effect. Swift elites get 1.2× rate.
- **`Time.get_ticks_msec()` for the CC-immunity timer** — global time, unaffected by tree pause (intentional; pausing the game shouldn't reset CC immunity). Alternative would be a delta-decremented field; Time is simpler.
- **`Elites.pick_random(rng)` takes the rng** — deterministic per-dungeon for reproducible testing. Mirrors how `Drops.roll_drop` uses the global `randi()` but elite spawns are run-once-at-load so determinism is cheap.
- **Retinue position-picking falls back to nearest valid tile** if no in-room floor tiles within 2.5m of the elite's chosen tile. Doesn't crash; could end up further than 2.5m in pathological cases. v1 acceptable.
- **No CONTEXT.md entry for "Modifier"** — the term is too generic (overlaps "affix" and "status"). The CONTEXT.md `Elite` entry covers the concept: "An Elite enemy carries one of four modifiers...".
- **`_die()` dispatch order**: status visual cleanup → modifier on_death effect → tween + queue_free. The on_death fires while `is_instance_valid(self) == true` so AoeQuery sees us as a position source.
- **`_attack_resolve` dispatch** — at the moment damage lands on the player (inside the existing ATTACK state, `_did_hit = true` block). Adds 2 lines.

## References

- `docs/specs/32-pack-scaling-research.md` — genre synthesis (FATE Reawakened, D3, PoE 2)
- `docs/specs/32a-pickup-deepening.md` through `32d-interactable-base.md` — the pre-arc that cleaned the ground
- `CONTEXT.md` — Pickup, Skill, SkillEffect, HitFeedback, Interactable entries
- `scripts/combatant.gd::_tick_ai` (ATTACK state) — where on-attack modifier dispatch lives
- `scripts/combatant.gd::_die` — where on-death modifier dispatch lives
- `scripts/aoe_query.gd::query_circle` — used by Brambled death-nova + Sunlit burn-pulse

## Done check

- [ ] `data/elites.gd` written; 4 modifiers with hp_mult/scale_mult/tint + per-modifier behavior keys
- [ ] `Combatant.apply_elite(modifier)` sets is_elite/role/hp_max/scale/tint/ring, applies modifier-specific fields
- [ ] `_chase_move` multiplies by `_move_mult`; `_attack_cd` divides by `_attack_speed_mult`
- [ ] `apply_status` gates on `_cc_immune_until` for root/snared on elites
- [ ] `_die` dispatches `"on_death"` (Brambled bleed-nova)
- [ ] `_tick_ai`'s attack-resolve dispatches `"on_attack"` (Sunlit burn-pulse)
- [ ] `data/drops.gd` has `"elite"` role
- [ ] `layout_loader._build_enemies` uses the new pack formula + elite roll + retinue spawn
- [ ] `test_combat.gd` Section I (I1, I2, I3) green
- [ ] Every other harness still green (83/83 before this spec; 86/86 after)
- [ ] World boots; manual playtest shows golden elites with retinues at depth ≥ 2
- [ ] `CONTEXT.md` Elite entry present
- [ ] `GODOT_PIPELINE.md` Pack scaling section added
