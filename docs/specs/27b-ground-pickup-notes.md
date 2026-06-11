# Implementation notes — 27b-ground-pickup

## Decisions
- **`ItemPickup` is itself the `Area3D`** (not a Node3D containing one).
  Fewer nodes, one script handles the visual + the trigger.
- **PICKUP_LAYER = 16** — adds a new physics layer alongside the existing
  `1 world · 2 player · 4 enemies · 8 hurtbox`.
- **Detection is one-sided** — pickups carry layer 16 but mask 0 (don't scan).
  The player's `PickupScanner` (an `Area3D` child built in code) is layer 0
  mask 16 and detects them. One place handles G, scans overlaps.
- **Player scanner built in code** (not in `Player.tscn`) — keeps the `.tscn`
  out of script/data churn; spec 27c will reuse the same pattern.
- **G** for grab (the spec lean).
- **Boss role hardcoded** in `_build_boss`: `role = "boss"`, `depth = 9` →
  always the boss-tier loot pile.
- **`force_readable_name=true`** on `add_child(pickup)` — gets `ItemPickup`,
  `ItemPickup2`, `ItemPickup3`… instead of Godot's cryptic `@Area3D@N`
  pattern.

## Tradeoffs
- **Pickup VFX is a scale-pop + label fade**, then the pickup `queue_free`s
  on a 0.22 s timer. Hooks for a `pickup` SFX wait for 27f.

## Surprises
- **Godot 4 `add_child` collision behaviour** — by default a name collision
  → `@<class>@<id>` (cryptic auto-rename), not `<name>2/3/…`. You need
  `force_readable_name = true` to get suffixed names. The first instance
  kept "ItemPickup"; the next 19 became `@Area3D@N`. Caught by debug
  name-dump in the eval.
- **Headless input timing** — `Input.action_press` → the player's
  `_physics_process` sees `is_action_just_pressed` on a *later* frame than
  the immediate next. D5 needs **3 awaits** after the press, not 1.

## Followups
- **Gold/currency kind + auto-pickup** — spec lean was "auto-pickup gold on
  overlap (no G)"; no gold kind exists in 27a yet, so deferred. Add gold to
  `items.gd`, special-case in `_try_grab` to fire on overlap.
- **Hover-fade labels** — PoE shows ground-item labels on Alt-hold; we show
  them always. With dense drops the cluster may read messy.
- **Pickup SFX** — wire to 27f's `Sfx.play("pickup")`.
- **Player-out-of-range cleanup** — pickups persist forever until grabbed;
  long-running runs accumulate. A timeout (~60 s) or area cap is a polish
  followup.

## Status
COMPLETE — drops fall on death (role/depth → tier), the player picks them up
with G, the stub inventory grows. `test_drops.gd` **5/5**, `test_combat.gd`
**21/21**, `test_movement.gd` **6/6**, `test_items.gd` **7/7**, World boots
score 1.00. Ready for 27c (the Tetris inventory UI).
