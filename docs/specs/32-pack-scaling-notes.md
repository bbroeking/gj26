# Implementation notes — 32-pack-scaling

## Decisions
- **Sunlit's "burn pulse" deals +3 immediate damage**, not a Burn DoT on the player. The player (`player_controller.gd`) doesn't extend the Combatant hierarchy that owns `apply_status`, so the spec 31 status framework can't be applied to the player out of the box. Punted on extending the player; +3 immediate damage is the v1 stand-in (matches Burn's total damage budget of 6 over 3s, halved for the "instant" payoff). Flagged in the followups for the player-status work.
- **`_make_elite_ring` uses an actual ring-shaped emission** (`EMISSION_SHAPE_RING`) rather than the simple upward spray the status particles use. Gave the elite a distinctive feet-ring silhouette right from the visual that doesn't read as "this enemy is burning."
- **`_attack_cd = ATTACK_COOLDOWN / _attack_speed_mult`** — Swift elite's bonus is a clean division, not a special-case branch. Default `_attack_speed_mult = 1.0` means non-elites compute exactly as before.
- **`apply_elite` is idempotent** — checks `if is_elite or modifier_key == "" or not Elites.MODIFIERS.has(modifier_key): return`. Re-calling is a no-op. Prevents double-tinting if a future spec tries to re-promote.
- **`_make_enemy` in `test_combat.gd` doesn't add to the "enemy" group by default.** I3 (Brambled death-nova) needs the test enemies in the group for `AoeQuery.query_circle` to find them — added the group inline in I3 setup rather than changing `_make_enemy`'s contract (other tests may depend on the existing behavior).

## Deviations
- **`Sunlit` ships as +3 damage, not Burn-on-player**, as explained in Decisions. The spec said "applies Burn (3s, 1/tick)" but spec 31's status framework lives on Combatant which the player doesn't extend. Documented; followup is to add a player-side status system.
- **Elites in the test (`_make_enemy`) don't naturally inherit the "enemy" group** like real layout_loader spawns do. Added explicit `add_to_group("enemy")` in I3 setup. Doesn't affect production code.
- **`_base_scale` is reassigned after apply_elite's scale bump.** The hit-react punch in `_tick_feedback` returns to `_base_scale`; if I didn't update it, the punch would shrink the elite back to non-elite size on every hit. Important detail.

## Tradeoffs
- **Retinue uses `forced_idx`** to match the elite's kind, requiring a new optional param on `_spawn_enemy`. Backward-compatible (default -1 preserves spec 27b round-robin). Alternative was passing a "kind override" through `_build_enemies`' loop in a more invasive way; the optional param won.
- **Elite roll happens AT spawn time** (each room rolls independently). Means dungeons can have 0 elites or 5 elites depending on luck. Tighter would be a "guarantee at least 1 elite per dungeon after depth N", but adds state to `_build_enemies` that v1 doesn't need.
- **AoeQuery filter group is `"enemy"`** for the Brambled death-nova. Elites themselves are in the "enemy" group (via `_spawn_character` → `add_to_group("enemy")` in `layout_loader.gd:_spawn_character`). So a dying elite catches other elites' retinues + their leaders in its nova. Intentional — elite-led packs hit hard on the death pop.
- **Brambled's bleed nova fires `apply_status("bleed", 4.0, 1, 1.0, 1.0)`** — 1 dpt × 4 ticks = 4 total damage per affected enemy. Modest. Tunable in `_trigger_bleed_nova` if playtest signals more impact wanted.

## Surprises
- **Boot smoke shows 11/14/18 enemies per dungeon** — much denser than pre-spec (5–9). 4–10 trash per combat room × 3–5 combat rooms per dungeon, plus 2–3 retinue per elite, plus 1 in treasure, 0–1 in shrine. Adds up faster than I'd intuited.
- **The `cc_immune_until` gate fires on FIRST snare** (it both grants the snare AND arms the immunity, in one `apply_status` call). Test I2 confirms: first snare lands, second is rejected. Reading the code, it took a re-read to confirm the timing is right — the gate runs BEFORE the `existing` check, and only sets `_cc_immune_until` when the call would otherwise succeed.
- **Spec 31's `_die()` already cleared status visuals**; spec 32 added the `_elite_ring` cleanup. Both live in `_die()` now — a small reminder that `_die()` is becoming a place where multiple "destroy this visual" concerns accumulate. If it grows further, factor out a `_clear_all_visuals()` helper.

## Followups
- **Player-side status system** (so Sunlit's Burn-on-player works as DoT, not +3 immediate damage). `player_controller.take_damage` currently has no `apply_status` interface. Could mirror Combatant's `_statuses` dict + `_tick_statuses` loop. Probably a small spec.
- **Elite-killed loot pop** (spec 33's "loot rain feel"). Elite drops one item via the new `"elite"` role; the celebration (slow-mo, screen flash, multi-particle burst) is its own spec.
- **Per-modifier SFX** — Sunlit's burn-pulse, Brambled's nova, Briarbound's CC-resist could each get an audio cue. ~$0.10/gen ElevenLabs spend each. Defer until playtest signals they're needed.
- **Brambled visual upgrade** — actual bramble vines wrapping the elite (instead of the generic golden tint + feet-ring) is an art-pipeline followup.
- **Modifier stacking** (PoE-style: 2-3 affixes per elite) for spec 33+. v1 picks one modifier; structurally impossible to brick.
- **Multi-elite packs** (D3 Champion model — 3-5 identical elites). Defer to spec 33+.
- **Hearthwarden + Wisp-sworn modifiers** from the research, deferred from Q2 grill. Hearthwarden needs distance-falloff damage modification (touches the damage pipe); Wisp-sworn needs orbital projectile AI (new sub-system). Both expansion-spec territory.

## Status
COMPLETE — `test_combat.gd` 25/25 (added I1/I2/I3 for elite stats, Briarbound CC-immunity, Brambled death-nova) + every other harness still green. Full tally: **86/86 evals across 11 harnesses** (was 83/83 before; +3 new). World boots, score ~0.97, 11–18 enemies per dungeon with ~0–2 elites visible per run.
