# 32a — Pickup module deepening

> **Outcome**: the loot pipe — every drop from a corpse, chest, or future elite — flows through one deep `ItemPickup` module. `spawn()` owns world placement; `try_take(player)` owns the full place-into-inventory transaction. Callers (`combatant._spawn_drops`, `chest.interact`, `player._try_grab`) become one-liners. No new gameplay; pure refactor.

## Why

The `/improve-codebase-architecture` review (run 2026-05-26, artifact at `/var/folders/85/.../architecture-review-20260526-084353.html`) flagged the loot pipe as the **strongest deepening candidate**. Tracing one drop from corpse to player hand currently crosses 4 modules:

1. `combatant._spawn_drops` rolls the pile via `Drops.roll_drop(role, depth)`
2. `combatant._spawn_one_pickup` instantiates the scene + adds + positions + setups
3. `chest.interact` duplicates the same instantiate/add/setup pattern in its own loop
4. `player._try_grab` peeks via `get_item()`, runs `inventory.find_first_fit`, calls `grab()`, then `inventory.try_place`, then plays SFX, then logs

The `item_pickup.gd` setup body is nearly the entire interface — **shallow**. The spawn boilerplate is duplicated across two callers with slightly different kick ranges. The grab-then-place sequence is split between the pickup (grab) and the player (find_first_fit + try_place + SFX + log).

The deletion test: if `ItemPickup` absorbed the spawn helper + take transaction, removing it forces the beacon/label/rarity-colour code back across `combatant.gd` and `chest.gd`, and forces the find_first_fit + try_place + SFX dance back into the player. **Complexity reappears in N callers → the module earns its depth.**

This spec is a pure refactor. No new gameplay, no new tests for new features — existing tests update to match the new seams. Lands cleanly as a prerequisite for spec 32 (pack scaling + elites), whose elite drops will reuse the same pipe.

## Scope

### In

- **`class_name ItemPickup`** declared in `scripts/item_pickup.gd` so callers can write `ItemPickup.spawn(...)` directly without a preload const at each call site.
- **`static ItemPickup.spawn(host: Node, item: Dictionary, position: Vector3) -> ItemPickup`** — instantiates `ItemPickup.tscn`, calls `host.add_child(pk, true)` (force_readable_name), positions at `position`, calls the internal `_setup(item)` which builds the beacon + label + collision sphere. Returns the ready node. Owns the entire spawn-time boilerplate that's currently duplicated.
- **`ItemPickup.try_take(player: Node) -> bool`** — the full pickup transaction:
  1. If already grabbed (`_grabbed = true`) → return `false`
  2. Preview the item; call `player.inventory.find_first_fit(_item)`
  3. If `fit.is_empty()` → log `"[loot] inventory full — %s left on the ground"`, return `false`
  4. Mark `_grabbed = true`; stop detection (`collision_layer = 0`); play pickup VFX; schedule `queue_free` after 0.22s
  5. Call `player.inventory.try_place(_item, fit.pos, fit.rotated)`
  6. Log `"[loot] +1 %s [%s] → %s%s"`
  7. Play `Sfx.play("pickup")` via `get_node_or_null("/root/Sfx")`
  8. Return `true`
- **`setup(item)` becomes `_setup(item)`** (private). The only public entry is `spawn`.
- **`grab()` and `get_item()` become `_grab()` and `_get_item()`** (private). `try_take` is the only public consume path.
- **`combatant._spawn_one_pickup`** collapses from 8 lines to 1:
  ```gdscript
  ItemPickup.spawn(host, it, center + Vector3(cos(ang), 0, sin(ang)) * randf_range(0.4, 1.0))
  ```
  The kick math + center+kick stays at the caller per Q1.2.
- **`chest.gd::interact`** loop body collapses from 9 lines per item to 1, matching the same call shape (with its own kick range 0.6–1.2 and y-offset 0.1m).
- **`player._try_grab`** collapses from ~25 lines to ~8: find the nearest overlapping pickup, call `best.try_take(self)`. No more preview-then-grab dance; no more SFX/log/inventory calls on this side.
- **`test_drops.gd` update**:
  - D3 — calls `ItemPickup.spawn(host, item, Vector3.ZERO)` instead of instantiate + setup, asserts on Beacon + Label children unchanged.
  - D4 — replaces direct `pk.grab()` test with `pk.try_take(stub_player)` where `stub_player` carries a real `Inventory`; asserts the item lands in the inventory and the pickup self-frees.
  - D5 — unchanged behaviour (full G-press flow through player); internals are now thinner but the test surface is identical.
- **`CONTEXT.md`** gains a "Pickup" entry — already added mid-grill (this is documentation that the discipline ran).
- **`docs/GODOT_PIPELINE.md`** gains a brief "Loot pipe" section pointing at this spec.

### Out (explicit non-goals)

- **`Drops.roll_drop(role, depth)`** — pure-data tier rolling math. Already deep, untouched. Stays at `data/drops.gd`.
- **`PICKUP_LAYER=16` vs `INTERACT_LAYER=32`** — separate physics layers with separate scanners on the player. Pickups auto-grab via G; interactables (chests/shrines/hearths) press-E. Different gameplay roles — don't merge.
- **`_make_pickup_scanner` / `_overlapping_pickups`** on the player — scanner code stays on the player. The seam is the pickup, not the detection.
- **Renaming** the file/scene from `item_pickup.gd` → `pickup.gd` / `ItemPickup.tscn` → `Pickup.tscn`. Keeping existing filenames avoids churn across the preload sites already in tests + spec files. The CONTEXT.md term "Pickup" and the code class "ItemPickup" coexist; the conceptual term is broader than the Godot type name.
- **Renaming `bolt_*` / `pickup` SFX keys** — sfx.gd entries stay as-is.
- **A "scatter" helper** that takes a `pile: Array` and a `center: Vector3` and bursts them out. Considered in the grill (Q1.2 option C); rejected for v1 — each caller's kick math is its own concern. Easy to add later if spec 32+ elite-death loot pops want it.
- **Updating `boss.gd`** — boss uses combatant's `_spawn_drops` path; no direct loot code on boss. No edit needed.
- **An `ItemPickup.grab` public preservation** — fully privatised; if a future caller needs raw consume-without-place, they should think about whether that's actually a feature or whether `try_take` covers it.

## Files

| Path | Action |
|---|---|
| `scripts/item_pickup.gd` | Add `class_name ItemPickup`; add `static spawn(host, item, position)`; add `try_take(player) -> bool`; privatise `setup` → `_setup`, `grab` → `_grab`, `get_item` → `_get_item` |
| `scripts/combatant.gd` | Simplify `_spawn_one_pickup` to a single `ItemPickup.spawn(...)` call. The 80ms stagger from spec 27f stays (it's caller-side timing). |
| `scripts/chest.gd` | Replace the per-item loop body with a single `ItemPickup.spawn(...)` call. Drop the local preload `ItemPickupScene` const (use the class_name directly). |
| `scripts/player_controller.gd` | Shrink `_try_grab`: find nearest, call `best.try_take(self)`. Drop the find_first_fit / try_place / Sfx.play / log code on this side (now in the pickup). Keep `_make_pickup_scanner`, `_on_pickup_entered/_exited`, `_overlapping_pickups`. |
| `test_drops.gd` | Update D3 to call `ItemPickup.spawn(...)`; rewrite D4 to call `try_take(stub_player)` with a real Inventory; D5 unchanged. |
| `CONTEXT.md` | Already updated mid-grill. (No change as part of /spec.) |
| `docs/GODOT_PIPELINE.md` | Add a short "Loot pipe (spec 32a)" section pointing here. |

## Acceptance criteria

1. `ItemPickup.spawn(host, item, position)` returns a node attached to `host`, positioned at `position`, with `Beacon` and `Label` children built per rarity.
2. `ItemPickup.try_take(player)` with an inventory that has space → item lands in `player.inventory`, pickup VFX plays, pickup self-frees in 0.22s, SFX plays, function returns `true`.
3. `ItemPickup.try_take(player)` with a full inventory → returns `false`, pickup remains on the ground, the "inventory full" log fires, no VFX, no SFX.
4. Repeated `try_take` on an already-grabbed pickup returns `false` and does nothing.
5. `combatant._spawn_one_pickup` is a single call to `ItemPickup.spawn` (visually verified in diff).
6. `chest.interact` loop body is a single call to `ItemPickup.spawn` per item.
7. `player._try_grab` no longer references `inventory.find_first_fit`, `inventory.try_place`, `Sfx.play("pickup")`, or the loot-print directly.
8. `test_drops.gd` 5/5 green.
9. Every existing harness still green (80/80 before this spec).
10. World boots, score ≥ 0.9, manually killing one enemy still spawns and grabs loot.

## Open decisions

All resolved by the grill (3 questions). Mini-decisions resolved by lean:

- **Class declaration**: `class_name ItemPickup` (matches existing file/scene naming). CONTEXT.md "Pickup" term is the conceptual broader name.
- **Kick math location**: stays at the caller per Q1.2 (chosen "minimal spawn signature").
- **What `try_take` does with `_grabbed = true`** — returns false silently. No log, no warning. Re-entrancy guard.
- **Inventory-full log message** — preserves the existing wording (`"[loot] inventory full — %s left on the ground"`) for grep continuity.
- **`Sfx.play("pickup")` lookup** — stays via `get_node_or_null("/root/Sfx")` (consistent with the spec 27f pattern, doesn't assume the autoload is loaded in test harnesses).
- **Privatising `grab` / `get_item`** — yes. The seam should be `spawn` + `try_take` only; raw consume-without-place isn't a feature, so the helpers don't need public access.
- **`test_drops` D4 stub**: build a tiny `_make_stub_player()` helper in the test harness that returns a Node with a real `Inventory` + a Sfx autoload. Keeps the test self-contained.
- **ADR**: no. The decisions are reversible and not "future architecture review would re-suggest"-shaped.

## References

- Architecture review HTML at `/var/folders/85/24ylx5853k791kpbpq8qzkjm0000gn/T/architecture-review-20260526-084353.html` (candidate #1).
- `CONTEXT.md` — "Pickup" definition (just added).
- Spec 27a (`docs/specs/27a-item-data.md`) — item dict shape consumed by `ItemPickup`.
- Spec 27b (`docs/specs/27b-pickup.md`) — original pickup implementation; this spec deepens it.
- Spec 27c (`docs/specs/27c-inventory.md`) — `inventory.find_first_fit` / `try_place` interface that `try_take` now owns.
- Spec 27f (`docs/specs/27f-polish.md`) — stagger timing pattern in `combatant._spawn_drops` (preserved).
- Skill: `/Users/bbroeking/.claude/skills/improve-codebase-architecture/SKILL.md` — the LANGUAGE.md vocabulary (module / interface / depth / seam / leverage / locality) used throughout this spec.

## Done check

- [ ] `class_name ItemPickup` declared
- [ ] `static spawn(host, item, position)` implemented + returns `ItemPickup`
- [ ] `try_take(player)` implemented per the 8-step contract above
- [ ] `setup` / `grab` / `get_item` privatised
- [ ] `combatant._spawn_one_pickup` one-liner
- [ ] `chest.interact` loop one-liner per item
- [ ] `player._try_grab` shrinks to find-nearest + `try_take`
- [ ] `test_drops` 5/5 green (D3 + D4 rewritten, D5 unchanged)
- [ ] Every existing harness still green (80/80)
- [ ] World boots, manual loot grab works
- [ ] `CONTEXT.md` "Pickup" entry confirmed present
- [ ] `GODOT_PIPELINE.md` "Loot pipe (spec 32a)" section added
