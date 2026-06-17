---
title: Elite Enemies
domain: Enemies & Combat
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Elite Enemies

> The 4-modifier data-driven elite system is fully wired and functional; the expansion roadmap is adding depth-scaled spawn density, 2–3 new affixes, biome-distinct tints, and per-modifier reward differentiation.

## Current state

`wyrd/data/elites.gd` (lines 10–46) defines four modifiers in a pure-data `MODIFIERS` dict: **brambled** (hp ×1.25, on_death bleed_nova), **swift** (move ×1.5, atk_speed ×1.2), **sunlit** (hp ×1.5, on_attack burn_pulse), and **briarbound** (hp ×1.3, 4s CC-immune window). Pick is deterministic off the caller-supplied RNG (`pick_random`, line 44) so the same dungeon seed always produces the same elites.

`wyrd/scripts/combatant.gd::apply_elite` (line 860) reads the data dict and mutates hp_max, scale, material tint, and modifier-specific state flags. On-death dispatch fires in `_elite_on_death` (line 959) via a `match` on the `on_death` key; on-attack dispatch fires similarly in `_elite_on_attack` (line 1000). Briarbound CC-immunity gates inside `apply_status` (line 495). A persistent golden feet-ring GPUParticles3D provides visual signal (line 915).

`wyrd/scripts/layout_loader.gd::_build_enemies` (line 832) rolls for an elite with probability `n / 8.0` in combat rooms only; adds a same-kind retinue of 2–3 trash; boss and entrance rooms are exempt (line 814). `wyrd/data/drops.gd` (lines 11, 18) gives elites 100% drop chance and a +1 tier bias (magic-leaning floor).

**Status correction:** pre-fill said "complete." The system is **partial**: the four modifiers ship and run correctly, but depth-dependent spawn rate, per-modifier reward differentiation, new affixes, biome tinting, and a named-elite display are all missing.

## Gaps — what needs fleshing out

- **No depth scaling on elite spawn rate.** `n / 8.0` is flat across all room depths (`layout_loader.gd:838`). Tier-1 rooms and Summit rooms feel identical in elite threat.
- **All four modifiers share one golden tint** (`Color(1.0, 0.92, 0.55)` for every modifier in `elites.gd:15,20,28,35`). Players cannot read the threat type from sight alone.
- **No named-elite text display.** `combatant.gd` applies a suffix-less tint; the modifier name (e.g. "Swift") never appears above the head or in the HUD, so players learn modifier rules only by dying to them.
- **Modifier catalogue is thin.** Four entries handle two damage archetypes (DoT-burst, burn-AoE). Missing: a shielded/tanky affix (forced player priority), a teleporting/repositioning affix, and a chain-lightning / aura AoE archetype.
- **Elite reward is undifferentiated.** All elites pay the same drop tier (+1 bias, always drops). High-threat modifiers (sunlit, briarbound) should reward more; a rare-guaranteed-on-modifier path would make hunting specific modifiers legible.
- **Density tuning per chart depth is absent.** ADR 0013 scales HP/damage by `den_level` (`layout_loader.gd:315`) but does not push elite frequency up at deeper dens. Summit-depth rooms should reliably have an elite; tier-1 starter rooms should be rare.
- **Retinue count is flat.** 2–3 trash regardless of depth (`layout_loader.gd:865`). Deeper dens warrant 3–5.

## Plan

### Phase 1 — Visual differentiation per modifier

- Give each modifier a distinct tint and ring color in `elites.gd::MODIFIERS`:
  - brambled: `Color(0.55, 0.90, 0.40)` (sap green — bleeder)
  - swift: `Color(0.50, 0.80, 1.0)` (ice blue — fast)
  - sunlit: `Color(1.0, 0.70, 0.20)` (ember gold — fire)
  - briarbound: `Color(0.85, 0.40, 0.90)` (deep violet — armored)
- Add a `"ring_color"` key to each entry; `combatant.gd::_make_elite_ring` reads `mod.get("ring_color", tint)` so ring and body tint can differ.
- Add a `"label_color"` key; `combatant.gd::apply_elite` spawns a `DamageNumber`-style floating modifier name ("Swift", "Sunlit" etc.) in that color that appears once and drifts up — reusing the existing `_spawn_apply_text` pattern (line 737).
- **DoD:** load any crypt dungeon; four elite types are visually distinguishable from 5m without reading a tooltip. Named label appears on promotion.
- **Effort:** S

### Phase 2 — Depth-scaled spawn rate and retinue

- In `layout_loader.gd::_build_enemies`, replace the flat `float(n) / 8.0` with `(float(n) / 8.0) * (1.0 + 0.12 * float(depth))` clamped to `0.05..0.60`. Depth comes from `depths[ri]` already in scope.
- Scale retinue count: `2 + clampi(depth / 3, 0, 3)` (2–5) instead of the flat `randi_range(2, 3)`.
- Add a chart-config hook: `cfg.get("elite_density", 1.0)` multiplier (mirrors `enemy_density`) so the Marked Quarry affix can double elite rate instead of just trophy odds.
- **DoD:** WYRD_DEV_LEVEL=1 vs WYRD_DEV_LEVEL=10 dungeon runs show visibly different elite frequency; at depth ≥ 5 rooms almost every combat room has one elite.
- **Effort:** S

### Phase 3 — Two new modifier archetypes

Add to `elites.gd::MODIFIERS` (follow the existing pure-data pattern; all behaviour lives in `combatant.gd` dispatch):

1. **thornshelled** — armored/tanky: `hp_mult: 2.0`, `cc_immune_window: 8.0`, `on_attack: "spine_burst"` (apply Snared to the player for 1.5s on each melee hit). Adds a dedicated counter-play: players must snare the retinue and kite, not stand and slug.
   - Implement `_trigger_spine_burst` in `combatant.gd` mirroring `_trigger_burn_pulse` (line 1010). Calls `_player.apply_status("snared", 1.5, 0, 0.55, 0.0)`.
2. **blightwalker** — AoE-field: `hp_mult: 1.2`, `on_death: "blight_pool"` (2m poison pool that persists 5s dealing 1 dpt at 0.5s intervals, blocking the floor). Forces players to reposition rather than stand over the corpse.
   - Implement `_trigger_blight_pool` in `combatant.gd`. Spawn a `MeshInstance3D` disc and tick its damage via a `SceneTreeTimer` chain; after 5s call `queue_free`. Mirror the bleed-nova disc pattern (`combatant.gd:975`).

- **DoD:** both new modifiers are rollable in normal dungeon play; `pick_random` automatically includes them (no code change — dict growth is sufficient). Each has a distinct tint, label, and at least one playtest death to their mechanic.
- **Effort:** M

### Phase 4 — Per-modifier reward differentiation

- Add an optional `"reward_tier_bonus"` key to each modifier entry (default 0). Start: thornshelled +2, blightwalker +1, sunlit +1, briarbound +1, swift +0 (it's dangerous but escapable).
- In `combatant.gd::_spawn_drops`, after `role = "elite"`, compute `depth += int(Elites.MODIFIERS.get(modifier, {}).get("reward_tier_bonus", 0))` before calling `Drops.roll_drop(role, depth)`.
- Guarantee a magic-or-better drop from thornshelled: pass a `minimum_rarity = "magic"` argument or clamp the tier floor inside `drops.gd::roll_drop` when `role == "elite"` and bonus >= 2.
- **DoD:** killing a thornshelled elite with WYRD_DEV_LEVEL=8 drops at least a magic item >90% of the time across 10 manual kills. Trophy-track tooltip (currently "thorn essence gleams") names the modifier for huntcraft context.
- **Effort:** S

## Dependencies & links

- [[system-combatant-ai]] — `combatant.gd` owns the runtime elite state machine; every new modifier behavior is a new `_trigger_*` private func there.
- [[system-status-effects]] — Sunlit applies Burn to the player; thornshelled applies Snared; blightwalker applies Burn (via pool). All route through `apply_status`.
- [[system-chart-affixes]] — `marked_quarry` already multiplies trophy drops from elites (`layout_loader.gd:857`); `elite_density` config hook in Phase 2 would let an affix modulate spawn rate directly.
- [[system-drops-loot]] — `drops.gd` ROLE_DROP_CHANCE and ROLE_TIER_BIAS are the reward levers touched in Phase 4.
- [[system-dungeon-generation]] — room depth values (`room_depths` array) drive the Phase 2 density formula; dungeon scope selects the spawn table that elites are drawn from.
- [[system-bosses]] — elites drop `thorn_essence` that unlocks the Hedgemother den; keeping elite spawn density meaningful is a prereq for the trophy chain staying paced.
- [[system-combat-juice-vfx]] — Phase 1 ring/tint work lives at the combatant visual layer; keep changes consistent with the kit tokens in `wyrd/scripts/ui/wyrd_ui.gd`.
- [[system-biomes-decor]] — biome scope (crypt vs briar maze) selects the spawn table but not yet the elite tint palette. A future pass could give Crypt elites bone-white tints vs Maze elites bark-brown.

**Plan.md overlap:** Part A (combat-feel P1–P5) is SHIPPED and covers hit-feedback, knockback, and the spark/ring kill-burst that elites already use — no re-implementation needed. Part B loop-feel (B0–B7 all SHIPPED as of wyrd-roadmap.md line 68) covered the B6 Bursting/Marked Quarry affix interactions with elites; Phase 2 here extends that pattern rather than replacing it.

## Verification

- **Phase 1:** Run `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd`; the suite must stay green. Manual check: run `WYRD_DEV_CHART=tier_1 godot --path wyrd`, find an elite — all four modifier types should be visually distinct and show a floating label.
- **Phase 2:** Run `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd` — green. Manual spot: compare `WYRD_DEV_LEVEL=1` (elites rare) vs `WYRD_DEV_LEVEL=10` (elites near-guaranteed in each combat room). Count elites by watching the tint glow.
- **Phase 3:** All 4 headless suites green after adding new modifiers (`pick_random` changes the dict length — verify the deterministic seed test still passes). Manual: provoke `thornshelled` melee hit (check Snared text floats); die to a `blightwalker` corpse (check green pool persists on the floor).
- **Phase 4:** `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_loop.gd` — green (drop roll exercised). Manual: kill 10 thornshelled elites at depth 5+, log rarity; expect ≥9/10 magic or better.

## Open questions

- Should new modifier archetypes be biome-locked (thornshelled only in Briar Maze, blightwalker only in Crypt) or fully cross-biome? Locking creates clearer mental models per den but reduces variety per run.
- Is a floating modifier name (Phase 1) sufficient readability, or does the HUD need a persistent "Elite: Swift" readout while targeting? (Simpler = floating name only for v1.)
- Should `pick_random` weight modifiers unequally at depth — e.g. thornshelled more likely at deeper dens where the player has better tools to counter CC-immunity? Or keep uniform pick and let depth frequency carry the difficulty curve?
