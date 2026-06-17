---
title: Drops & Loot Tables
domain: Gather · Craft · Economy
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Drops & Loot Tables

> The rarity-roll and loot-pipe are fully wired; the remaining work is targeted boss drops, shrine item integration, pickup feel (Plan.md B4), and a headless test suite that locks the math.

## Current state

`wyrd/data/drops.gd` implements the full role-biased drop table (lines 9–22): five roles (`combat` 50%, `elite` 100%, `treasure` 100%, `shrine` 25%, `boss` 100%), a `min(d10,d10)+bias` tier roll (line 44), depth scaling at `depth/2` (line 45), boss clamp ≥8 (line 47), and a `_tier_to_rarity` map (lines 51–58). Trade tools and capstone gear are explicitly excluded from `_pick_kind` (lines 62–66). `combatant._spawn_drops` (line 817) passes `role` and `depth` — both are set by `layout_loader` at spawn (lines 603, 666, 956, 1113). `chest.gd` rolls twice with `"treasure"` role using the room's BFS depth (lines 46–47). `item_pickup.gd` owns the full take transaction (`try_take`) including inventory fit, rarity beacon, pickup VFX, and SFX (lines 99–121). Co-op is wired: host broadcasts `drop_event(kind_id, rarity, pos)` via `net_game.gd:357–372`; each peer rolls its own affixes locally — the per-player instancing model is in place.

**What is partial:** (1) `"shrine"` role exists in the table but `shrine.gd` never calls `roll_drop` — it only offers buffs; the item-drop path is dead code. (2) Boss drops are generic `rare+` — no boss-specific targeted item (trophy/unique signature). (3) `_pick_kind` is pure uniform random across all non-excluded kinds; there is no category weight or depth-gated kind pool (e.g. deeper floors can't gate higher-tier base items). (4) Pickup feel is functional but flat — the beacon has no suck-toward-player tween and the satchel slot doesn't pulse on landing (Plan.md Phase B4 owns this). (5) There are no headless tests asserting the rarity distribution math.

## Gaps — what needs fleshing out

- **[blocker for economy feel]** Shrine item drop path never fires — `shrine.gd` never calls `roll_drop`. Either wire a post-bless item drop or remove the `"shrine"` role constant so the table is honest.
- Boss targeted drops: each boss kind should guarantee at least one kind-specific item (its "trophy" unique or a signature base kind) in addition to the 3 generic `rare+` rolls. Currently `BOSS_DROP_COUNT := 3` (line 23) are all from the uniform pool.
- Kind pool depth-gating: `_pick_kind` picks uniformly from all non-excluded kinds at any depth. Deeper floors should up-weight or unlock better base kinds (e.g. longbow over shortbow, copper_ring fades out in favor of starsilver at depth 8+).
- Shrine item drop: the `"shrine"` role in `ROLE_DROP_CHANCE` implies a post-prayer item bonus (25% chance, tier_bias 1). If the design intent is buff-only, delete the constant; if item-bonus is wanted, wire it in `shrine.gd:apply()` after `player.apply_shrine_buff`.
- Pickup feel (beacon suck, slot pulse, pickup chime): **owned by Plan.md Phase B4** — do not duplicate here; cross-link and depend on it.
- Headless math test: no suite currently asserts that boss drops never yield `"normal"`, that elite drops skew magic-and-up, or that depth 8 produces measurably more `rare+` results than depth 0.

## Plan

### Phase 1 — Honest table + shrine wiring (S)

Resolve the shrine dead-code gap and make the constants truthful.

- **Option A (item bonus):** in `shrine.gd:apply()`, after `player.apply_shrine_buff`, call `Drops.roll_drop("shrine", depth)` (pass depth set by layout_loader at spawn, same pattern as chest) and spawn any results via `ItemPickup.spawn`. Requires adding `var depth: int` to Shrine, wired in `layout_loader` like chest depth.
- **Option B (buff-only):** remove the `"shrine"` entries from `ROLE_DROP_CHANCE` and `ROLE_TIER_BIAS` in `drops.gd:13,20`. Leave a comment: shrines are buff-only.
- Decide which option, implement it, gate-test. This is the only blocker-level gap.
- **DoD:** `"shrine"` constant is either exercised (and a shrine interaction spawns a pickup 25% of the time in a headless smoke test) or deleted. No dead-code paths.
- **Effort: S**

### Phase 2 — Headless math test suite (S)

Lock the rarity math so future tuning doesn't silently break it.

- Add `test_drops.gd` in `wyrd/` alongside the existing suites. Tests:
  - `_test_boss_always_rare_plus`: loop 200 rolls of `roll_drop("boss", 5)`, assert every item's rarity is `"rare"` or `"unique"`.
  - `_test_elite_bias`: 500 rolls `("elite", 0)`, assert ≥60% `"magic"` or better.
  - `_test_depth_scaling`: compare `_roll_tier("combat", 0)` mean vs `_roll_tier("combat", 8)` over 1000 rolls; assert depth-8 mean is at least 3 higher.
  - `_test_tool_excluded`: roll 500 `("combat", 0)` items, assert no `category in ["pickaxe","axe"]` and no `kind_id in ["warbow","starsilver_band"]`.
- Run with `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_drops.gd`.
- **DoD:** `test_drops.gd` runs headless, all 4 assertions pass, suite added to CI gate.
- **Effort: S**

### Phase 3 — Boss targeted drops (M)

Give each boss kind at least one guaranteed signature drop alongside the generic pile.

- Add a `BOSS_SPECIFIC_DROPS` dict in `drops.gd` keyed by boss kind string (e.g. `"hedgemother": ["starsilver_band"]`). Boss kind is currently not passed into `roll_drop`; extend the signature: `roll_drop(role: String, depth: int = 0, boss_kind: String = "") -> Array`.
- When `boss_kind != ""` and a matching entry exists, push one `Items.make_item(kind_id, "rare")` into the pile unconditionally before the generic count loop.
- `layout_loader` (line 666, `boss.role = "boss"`) already has the boss kind string — pass it through: `boss.boss_kind = <kind_id>`, read in `_spawn_drops`.
- **DoD:** killing the Hedgemother always yields a `starsilver_band` (or whatever is mapped) in the drop pile, confirmed by `_test_boss_targeted_drop` headless assertion. Generic `rare+` pile still drops alongside.
- **Effort: M**

### Phase 4 — Depth-gated kind pool (M)

Make `_pick_kind` depth-aware so deeper floors feel meaningfully different.

- Add `KIND_DEPTH_MIN` dict in `drops.gd` mapping kind IDs to the minimum depth at which they appear in the pool: `{"longbow": 3, "starsilver_band": 7, "warbow": 8}` (shortbow/leather/copper_ring available at all depths). Trade tools and capstone items remain excluded via the existing filter.
- `_pick_kind(depth: int = 0)` filters `kind_ids()` by `KIND_DEPTH_MIN.get(id, 0) <= depth` before the random pick. `roll_drop` passes depth through.
- Requires updating `_pick_kind` call sites: only `roll_drop` calls it, so the change is contained.
- **DoD:** headless test `_test_depth_pool` verifies shortbow appears at depth 0, longbow never appears at depth 0, starsilver_band only appears at depth ≥7. Gate green.
- **Effort: M**

### Phase 5 — Pickup feel (Plan.md B4, cross-reference only)

The beacon suck-toward-player, satchel slot pulse, and pickup chime are owned by **Plan.md Part B / Phase B4**. This system note does NOT re-plan that work. Dependency: Phase B4 must ship before this gap is considered closed.

- The mechanic seam is already correct: `item_pickup.gd:try_take` → inventory fit → VFX/SFX. Plan.md B4 enriches `_play_pickup_vfx` (add suck tween) and adds a slot-pulse call on the HUD. No structural changes needed in `drops.gd`.
- **DoD (for this note):** Plan.md Phase B4 is marked done and the feel bench (`tools/feel_bench.gd` P-key) confirms the suck + slot-pulse. Not tracked here.

## Dependencies & links

- [[system-items-affixes]] — `_pick_kind` pulls from `Items.kind_ids()` and `Items.KINDS` for category filtering; affix rolling happens inside `Items.make_item` — the two are tightly coupled.
- [[system-inventory-equipment]] — `ItemPickup.try_take` calls `inv.find_first_fit` and `inv.try_place`; if the inventory is full the pickup stays on the ground. Phase B4 slot-pulse also reads the fit position.
- [[system-bosses]] — Phase 3 of this plan (targeted drops) requires passing `boss_kind` through `layout_loader → combatant._spawn_drops → drops.roll_drop`. Boss trophy progression is defined there.
- [[system-elites]] — `apply_elite(modifier_key)` sets `role = "elite"` (combatant.gd:866), so elite drops flow through the same pipe; the drop bias for elites is already live.
- [[system-interactables]] — Chest and Shrine are both Interactables; Phase 1 wires or removes the shrine drop path in `shrine.gd:apply()`.
- [[system-economy]] — gold/vendor economy is separate from item drops but competes for the same player attention; loot drop rate calibration should account for vendor sell pressure.
- [[system-charts-wayfinding]] — depth parameter passed to `roll_drop` comes from BFS room depth set by `layout_loader`; chart affix difficulty bands scale depth (ADR-0013).
- [[system-chart-affixes]] — chart affixes (e.g. Bursting, Volatile) affect enemy behaviour and kill conditions but currently do not modify drop rates; a future affix like `Bountiful` would hook into `ROLE_TIER_BIAS`.
- [[system-multiplayer-netcode]] — co-op drop pipe (`net_game.drop_event` → `_drop_event` RPC) is already wired; targeted boss drops (Phase 3) must also route through this pipe when `multiplayer.is_server()`.
- [[system-combat-juice-vfx]] — kill burst VFX (`combatant._kill_burst`) fires immediately before `_spawn_drops`; pickup beacon VFX is downstream. These compose well — no conflict.
- **Plan.md Part B / Phase B4** — pickup feel (beacon suck, satchel slot pulse, pickup chime) is owned there. This note depends on B4 for the "pickup feel" gap to be fully closed.

## Verification

- **Phase 1 (shrine):** run the full headless suite (`WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_wyrd_dungeon_scene.gd`); confirm gate stays green. If Option A: add a targeted smoke test that calls `shrine.apply(mock_player, buff)` with a seeded RNG and asserts an ItemPickup was spawned (or not) at the correct 25% rate over 100 calls.
- **Phase 2 (math tests):** `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_drops.gd` — all 4 assertions pass. Add this script to the CI gate alongside the existing five suites.
- **Phase 3 (targeted boss drops):** `_test_boss_targeted_drop` headless: spawn a boss combatant with `boss_kind = "hedgemother"`, call `_spawn_drops` directly, assert pile contains the mapped kind_id. Also confirm generic `rare+` count is still `BOSS_DROP_COUNT - 1` (one slot used by targeted drop, rest generic).
- **Phase 4 (depth-gated pool):** `_test_depth_pool` headless assertions (see Phase 4 DoD). Gate green.
- **Phase 5 (pickup feel):** deferred to Plan.md B4 verification (feel bench `P` key, suck tween screenshot, slot-pulse logic test).

## Open questions

- **Shrine intent:** should a shrine that blesses the player also have a 25% chance to drop an item (Option A), or should shrines be buff-only (Option B)? The constants in `drops.gd` imply Option A but the code implements Option B. Decide before shipping Phase 1.
- **Boss trophy count:** should the targeted boss drop consume one of the `BOSS_DROP_COUNT := 3` slots (total stays 3) or be additive (boss drops 4)? The current constant is a good baseline but this is a tuning call.
- **Affix-modified drop rates:** is a `Bountiful`/`Cursed` chart affix that bumps/nerfs drop rates on the roadmap? If so, `ROLE_TIER_BIAS` needs to become a mutable runtime value rather than a const, which is a small but meaningful refactor.
