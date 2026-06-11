# 31 — Status effects + AoE foundation

> **Outcome**: every existing skill gets a distinct identity through a status it applies. PowerShot *ignites*, MultiShot *snares* (soft slow), crits *bleed*, Bramble Snare keeps its root (now part of the unified status dict). The framework generalises from spec 30's one-off `_root_t` into a `StatusEffect` + per-Combatant `_statuses` dictionary, and AoE shape queries get formalised into reusable helpers so future skills (ExplosiveArrow, melee cleaves) can drop in without copy-paste.

## Why

Spec 30 shipped 4 skills with distinct *mechanics* (single-target / cone / AoE root) but their *combat feel* was still mostly "shoot it with arrows of different speed and number." Diablo and PoE 2 differentiate skills not just by shape but by the **ailment they leave behind** — fire feels different from cold because fire LEAVES burn, not because it does +5 more damage on hit. The genre research (see `31-status-and-aoe-research.md`) argues this is the lever that turns a 4-skill kit from "different damage curves" into "different gameplay verbs."

Spec 30's `apply_root` was deliberately a one-off. Spec 31 generalises it: one `StatusEffect` RefCounted, one `_statuses` dict on Combatant, one `apply_status` method that handles refresh / duration / stacking — then ships 3 new statuses on top. The AoE side gets the same treatment: Snare's hand-rolled enemy loop becomes a reusable `aoe_query.gd::query_circle` that the next AoE skill (whenever it lands) plugs into without rebuilding the radius scan.

## Scope

### In

- **`StatusEffect` (RefCounted, new file `scripts/status_effect.gd`).** Fields: `kind: String`, `time_left: float`, `tick_interval: float`, `next_tick: float`, `damage_per_tick: int`, `slow_factor: float = 1.0`. No methods — pure data; Combatant owns the tick loop.
- **`_statuses: Dictionary` on Combatant** keyed by `kind` (`"root" / "burn" / "bleed" / "snared"`). Replaces the spec 30 single `_root_t` field. The existing root logic migrates into `_statuses["root"]` so spec 30 callers (Bramble Snare) don't change semantically.
- **`apply_status(kind, duration, dpt, slow_factor, tick_interval)` on Combatant.** Highest-wins / refresh-duration stacking — if a status of `kind` already exists, take `max(time_left, duration)` and `max(damage_per_tick, dpt)`; otherwise create a new StatusEffect entry. Returns the (possibly extended) StatusEffect.
- **`has_status(kind)` + `get_status(kind)`** on Combatant. `is_rooted()` (spec 30) becomes `has_status("root")` (the old method stays as an alias for back-compat).
- **Tick loop in `_physics_process`** — for each status, decrement `time_left`. If `tick_interval > 0`, decrement `next_tick`; when ≤ 0, call `take_damage(damage_per_tick, Vector3.ZERO)` and add `tick_interval` to `next_tick`. When `time_left ≤ 0`, free the status's visual and remove the entry. **Fixed-interval ticks — never `delta`-scaled damage** (the cardinal DoT rule from research).
- **Bleed-on-crit hook** inside `combatant.take_damage`. When `tier == "crit"` or `"super"`, call `apply_status("bleed", 4.0, max(1, int(round(dmg * 0.0625))), 1.0, 1.0)` — totals to ~25% of the crit damage over 4 one-second ticks. **Only enemy combatants** (the player has `take_damage` but isn't in the `enemy` group; gated by `is_in_group("enemy")`).
- **Burn applied by PowerShot.** `player_controller._fire_powershot` already spawns one arrow; pass `skill_type = "power"` into the arrow (already wired) and on hit, the arrow tells the target `apply_status("burn", 3.0, 1, 1.0, 0.5)`.
- **Snared applied by MultiShot.** `player_controller._fire_multishot` spawns 3 arrows with `skill_type = "multi"`; each on hit calls `apply_status("snared", 1.5, 0, 0.5, 0.0)` — re-applying just refreshes duration.
- **Slow factor in `_chase_move`.** Compute `slow := 1.0`; multiply by every `_statuses[kind].slow_factor`. Clamp to `≥ 0.25` (a slowed enemy still creeps; never frozen via slow-stack). Replace `MOVE_SPEED` in the chase with `MOVE_SPEED * slow`.
- **AoE query helpers (new file `scripts/aoe_query.gd`, static RefCounted-style).**
  - `query_circle(tree, center: Vector3, radius: float, group := "enemy") -> Array[Combatant]` — returns every combatant in the group within `radius` of `center`.
  - `query_cone(tree, origin: Vector3, dir: Vector3, range_m: float, half_angle_deg: float, group := "enemy") -> Array[Combatant]` — sketched for future skills; spec 31 ships it but only `query_circle` has a caller (Snare).
  - Refactor `player_controller._cast_bramble_snare` to use `query_circle(get_tree(), aim, SNARE_RADIUS)` instead of its hand-rolled loop.
- **Visual: particle above head per status.** GPUParticles3D child node on the Combatant; small box particles in the status color (orange / red / green / emerald for burn / bleed / snared / root). Owned by the StatusEffect; freed when the status expires. **Cap simultaneous particle systems per enemy at 2** — if a 3rd status applies, the 3rd one only gets tint + apply-text.
- **Visual: mesh tint pulse on tick.** Reuse the spec 14 `_flash_mat` infra — on each tick, briefly flash the meshes in the status color (Burn = orange, Bleed = red). Snared doesn't pulse (no tick). Tint duration ≈ 0.08s, weaker than the hit flash so it doesn't drown the existing combat feedback.
- **Visual: italic apply-text under DamageNumber.** On *first* apply only (not every tick), a small italic Label3D appears under the floating damage number with the status verb: `"singed!"` / `"bleeding!"` / `"snared!"` / `"rooted!"`. Reuses the DamageNumber spawn pipeline.
- **Boss immunity table** on `boss.gd`. Replace the existing `apply_root` pass-through with a generalised `apply_status` override:
  - `kind == "root" or kind == "snared"` → **return immediately** (full immunity to lock-down).
  - `kind == "burn" or kind == "bleed"` → call `super.apply_status(kind, duration * 0.5, ...)` (50% reduced duration).
  - "Unyielding" tag added to the boss bar label (`boss_bar.gd` — appended to the existing boss name like "Hedgemother — Unyielding") so the player sees *why* their snare fizzled.
- **Eval: `test_statuses.gd`** — 7 evals:
  - T1: `apply_status("burn", 3.0, 1, 1.0, 0.5)` → 6 ticks land over 3s (verify total damage = 6).
  - T2: PowerShot arrow hits enemy → enemy has status "burn".
  - T3: MultiShot arrow hits enemy → enemy has status "snared" with `slow_factor = 0.5`.
  - T4: Critical hit on enemy → enemy has status "bleed"; non-crit doesn't apply.
  - T5: Re-applying burn refreshes to max duration + max damage_per_tick (highest-wins).
  - T6: Boss (`boss.gd`) `apply_status("root", 2.0, ...)` → no status added (full immunity).
  - T7: `aoe_query.query_circle` returns only enemies within radius, excludes those just outside.

### Out (explicit non-goals)

- **ExplosiveArrow** (or any new skill). Spec 31 ships AoE *helpers* the future skill plugs into; no slot 5 or replacement skill in v1.
- **Freeze / Shock / Stun / Confusion / Charm.** Research-recommended skip — Freeze overlaps Root; Shock needs lightning fantasy; Stun makes fast combat oppressive; Confusion/Charm needs AI rewrite.
- **Chain AoE shape.** Expensive (nearest-not-already-hit, arc renderer); skip until spec 34+ class paths give a class fantasy that wants it.
- **Spatial AoE falloff.** All 3 reference games agree: full damage inside, zero outside. No edge attenuation.
- **Hidden DR system** (D3-style). Boss immunity is binary + duration multiplier; no resistance counter.
- **Status icons in the HUD bar.** The entity-level visuals (particle + tint + apply-text) carry the load; HUD layer is more work than it's worth at this stage.
- **Status-affecting affixes** (`fire_damage`, `bleed_chance`, `burn_duration`). Status effects in v1 are deterministic per-skill; affixes scale them in spec 36 (expanded item pool).
- **Player slow_factor.** Statuses can `apply_status` on the player technically, but no enemy applies one in v1; the slow product applies to `_chase_move` only.
- **New SFX.** Apply event is silent (visual only). Existing hit/crit SFX carry the moment.
- **Nova shape** — sketched in `aoe_query.gd` *only if cheap*; no skill uses it in v1.
- **Removing the spec 30 `is_rooted()` method** — kept as an alias of `has_status("root")` for back-compat (test_skills T4 reads it).

## Files

| Path | Action |
|---|---|
| `godot/scripts/status_effect.gd` | **new** — RefCounted; fields only |
| `godot/scripts/aoe_query.gd` | **new** — `query_circle`, `query_cone` (sketched), `query_nova` (sketched) |
| `godot/scripts/combatant.gd` | migrate `_root_t` → `_statuses` dict; new `apply_status`/`has_status`/`get_status`; status tick loop in `_physics_process`; bleed-on-crit in `take_damage`; slow_factor product in `_chase_move`; `_die` clears all status visuals; `is_rooted()` aliases `has_status("root")` |
| `godot/scripts/boss.gd` | replace `apply_root` pass-through with `apply_status` override (full immune to lock-down; 50% reduced duration on damage statuses) |
| `godot/scripts/player_controller.gd` | `_fire_powershot` → arrow signals enemy `apply_status("burn", ...)`; `_fire_multishot` → arrows signal `apply_status("snared", ...)`; `_cast_bramble_snare` refactored to use `aoe_query.query_circle` |
| `godot/scripts/arrow.gd` | on hit, after `take_damage`, switch on `skill_type` and call `c.apply_status(...)` for `"power"` (burn) and `"multi"` (snared) |
| `godot/scripts/boss_bar.gd` | append " — Unyielding" to the boss name display |
| `godot/scripts/damage_number.gd` | add `setup_apply(text, kind_color)` — spawns the italic apply-text variant (or extend the existing setup with a new tier) |
| `godot/test_statuses.gd` | **new** — 7 evals above |
| `docs/GODOT_PIPELINE.md` | brief "Status framework (spec 31)" section pointing here |

## Acceptance criteria

1. Hit an enemy with PowerShot — orange flame particle appears above its head; "singed!" floats once; 1 damage ticks 6 times over 3s.
2. Critical-hit an enemy — red drip particle appears; "bleeding!" floats once; 4 small ticks land over 4s totaling ~25% of the crit damage.
3. Hit an enemy with MultiShot — green vine particle appears; "snared!" floats once; the enemy visibly moves at half speed for 1.5s.
4. Cast Bramble Snare — every enemy in the 2.5m circle gets the emerald root disc (existing) AND the "rooted!" apply-text; refactored to call `aoe_query.query_circle`.
5. Two statuses concurrent (e.g. Burn + Snared) both visibly tick on the same enemy with their own particles.
6. Cast Bramble Snare on the Hedgemother — visual disc casts; boss is *not* rooted (moves and attacks through it). Boss bar reads "Hedgemother — Unyielding."
7. Hit Hedgemother with PowerShot — flame particle appears; burn ticks for 1.5s (not 3s) — duration halved.
8. `test_statuses.gd` 7/7 green.
9. Existing harnesses still green (73/73 before this spec).
10. World boots, score ≥ 0.9.

## Open decisions

All resolved by the grill (see `31-status-and-aoe-research.md`). Mini-decisions resolved by lean:

- **StatusEffect = RefCounted** (not Node3D) — no transform cost; the visual particle is a separate Node3D the StatusEffect owns and Combatant frees.
- **Stacking = highest-wins + refresh duration** for all 4 statuses (D3 model). Skip PoE 2's per-status rules (too complex for v1).
- **Tick interval = per-status** (Burn 0.5s, Bleed 1.0s, Snared/Root never tick — `tick_interval = 0` skips the tick branch).
- **Particle type** = `GPUParticles3D` with small box particles in the status color (matches spec 26 arrow trail aesthetic); single emitter per status; offset 1.6m above the combatant origin.
- **Tint pulse color** = status-themed: Burn warm orange (1.0, 0.6, 0.2), Bleed red (1.0, 0.25, 0.25), Snared/Root no pulse (no tick to pulse on).
- **Apply-text style** = italic, ~14px, color matches the status particle, floats up-and-fade like DamageNumber but 0.6s lifetime (shorter).
- **Slow product cap** = `clampf(slow_product, 0.25, 1.0)` — a slowed enemy never freezes from stacking soft slows.
- **Bleed-on-crit only on enemies** — `if not is_in_group("enemy"): return` in the bleed apply path. Player crits don't bleed the player.
- **"Unyielding" tag is a display-only suffix** in `boss_bar.gd`; no new boss state.
- **Burn damage = flat 1/tick** (not % of hit). Cap PowerShot's total burn contribution at ~40% of one PowerShot direct hit. Keeps statuses additive but not dominant.
- **Snare's existing emerald disc** stays for the AoE visual; the per-enemy root particle is the SMALLER one added by this spec (so a single rooted enemy still gets a personal indicator inside the disc).
- **`aoe_query.query_cone` ships but is unused in v1** — built so the future melee/cleave spec can drop in without re-architecting.

## References

- `docs/specs/31-status-and-aoe-research.md` — genre synthesis (FATE Reawakened, Diablo 3, Path of Exile 2)
- Spec 30 (`docs/specs/30-skills-and-cooldowns.md`) — the skill system + `apply_root` v1 prototype this spec generalises
- Spec 26 — visual variants on arrow (color palette to mirror for status particles)
- Spec 14 — `_flash_mat` hit-flash infra reused for the tint pulse
- Spec 27e — `derived_stats` (no new derived stats in v1; status numbers are constants for now)
- `godot/scripts/combatant.gd` — `_root_t`, `apply_root`, `take_damage` (where the migration happens)
- `godot/scripts/boss.gd` — `apply_root` pass-through (becomes `apply_status` override)
- `godot/scripts/player_controller.gd` — `_fire_powershot`, `_fire_multishot`, `_cast_bramble_snare` (where on-hit status applies wire in)
- ARPG roadmap memory: [[project-arpg-roadmap]]

## Done check

- [ ] `scripts/status_effect.gd` exists, RefCounted, fields only
- [ ] `scripts/aoe_query.gd` exists with `query_circle` + `query_cone` sketched
- [ ] `combatant.gd::_statuses` dict; `apply_status` / `has_status` / `get_status` / `is_rooted` alias
- [ ] Status tick loop in `_physics_process`; fixed interval, never `delta`-scaled damage
- [ ] Bleed-on-crit hook in `take_damage` (enemy-only)
- [ ] Slow factor product in `_chase_move`; clamped ≥ 0.25
- [ ] PowerShot applies Burn on hit via arrow.gd's on-hit switch
- [ ] MultiShot applies Snared on hit
- [ ] Bramble Snare uses `aoe_query.query_circle`
- [ ] Each status spawns a colored particle above the enemy + tint pulse on tick + apply-text on first apply
- [ ] Hedgemother is immune to root + snared; takes burn + bleed at 50% reduced duration
- [ ] "Unyielding" suffix in boss bar
- [ ] `test_statuses.gd` 7/7 green
- [ ] Existing harnesses still green (73/73)
- [ ] World boots; cast each skill, verify each status applies visually
