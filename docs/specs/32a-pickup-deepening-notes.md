# Implementation notes — 32a-pickup-deepening

## Decisions
- **D4 uses a real `PlayerScene`**, not a stub. Spec said "stub_player with a real Inventory" — but stubbing in GDScript requires either inline subclassing of Node3D (verbose) or `set()` dynamic-property assignment (which doesn't satisfy `"inventory" in player`). PlayerScene already has Inventory + Sfx wiring; the test runs in ~3 frames either way. Outcome identical; one less indirection.
- **`PickupScene` const preload lives inside `item_pickup.gd`** (used by `spawn`). The class loads its own scene; callers don't need a separate preload const. Removed the now-orphan `ItemPickupScene` from `combatant.gd`, `chest.gd`, and `test_drops.gd`.
- **`try_take` does duck-typing on the player arg** (`"inventory" in player`, `inv.has_method("find_first_fit")`). Two defensive if-checks instead of a strict signature — the seam survives bad input by returning false, which fits the existing "inventory full" fail-mode.
- **`_grab` returns `{}` on re-entrance**, not nothing — preserves the existing API shape for any future caller that wants the consumed item dict. Internally `try_take` checks `is_empty()`.

## Deviations
- None material — the implementation matches the spec's contract. The "stub_player" wording vs the real PlayerScene is cosmetic.

## Tradeoffs
- **Owned both the spawn-time logic and the take logic in one class** vs splitting them across `PickupSpawner` + `Pickup`. Spec went with one class per Q1.1 + Q1.3 grills (user picked max absorption both times). Single class is simpler; the `class ItemPickup` definition is ~140 lines, well-scoped.
- **Kick math still lives at each caller** (combatant: 0.4–1.0, chest: 0.6–1.2 + y offset). Per Q1.2 lean. If a third caller appears with the same kick pattern, abstract into `ItemPickup.spawn_with_kick(host, item, center, min, max)`. v1: not worth it for 2 callers.

## Surprises
- **`chest.gd` had its own `const ItemPickupScene`** — third cleanup site I hadn't initially noticed (combatant + test_drops were the expected ones). Confirms the value of the deepening: the orphan preload would have lingered through future specs.
- **D5 unchanged behaviour-wise** even though its internals shifted. Player's `_try_grab` is now ~12 lines (was ~25) but the eval contract — "press G, item in inventory" — survives identically. Good sign that the seam is at the right level.

## Followups
- `combatant.gd::_spawn_drops` still has the 80ms-stagger callback from spec 27f. Stays — that's caller-side timing, not pickup-side concern. Documented here so a future eye doesn't try to absorb it.
- `data/drops.gd` (the role+depth → pile rolling) untouched. Already deep; the architecture review flagged it as a non-candidate. Leave alone.
- If a future test wants to assert on `_grab` or `_get_item` directly (private now), it should go through `try_take` instead. The seam intentionally hides those.

## Status
COMPLETE — `test_drops.gd` 5/5 + every other harness still green (80/80 across 11 harnesses). Pickup module is the deep seam for the loot pipe; future elite drops (spec 32) plug into `ItemPickup.spawn` without change.
