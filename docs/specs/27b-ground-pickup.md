# 27b — Ground pickup

> Make loot exist *in the world*. Enemies drop items on death; each drop is a 3D beacon + a floating rarity-coloured label; the player picks up with F when overlapping.

## Why

27a built the data; 27b makes it visible and interactable. After this you can kill enemies and *see* loot drop, even though the inventory UI (27c) is the next subspec — drops accumulate in a stub inventory list until 27c renders it.

## Scope

### A. `ItemPickup` scene + script
- `scenes/ItemPickup.tscn` + `scripts/item_pickup.gd`.
- A `Node3D` containing: a small **glowing beacon** (a thin upward capsule, unshaded emissive in the rarity colour — same recipe as the bolt), a **world-space label** (`Label3D`, billboarded, text = the item name in the rarity colour), and a small **Area3D pickup trigger** (~1m radius).
- `setup(item: Dictionary)` — caches the item, builds the beacon + label coloured by rarity.

### B. Drop on death
- In `combatant.gd::_die()`, call `Drops.roll_drop(self.role, self.depth)` (role/depth passed in from layout_loader at spawn time, or default to "combat" / 0). For each item in the returned array, instance `ItemPickup`, position at the corpse with a small random outward kick, add to the world.

### C. Picking up
- Player presses **F when overlapping** a pickup → the pickup transfers itself into a stub player inventory and `queue_free`s.
- For 27b, the inventory is a **stub `Array[Dictionary]`** on the player (`player.inventory_stub`) — just appends. The Tetris grid (27c) replaces it with the real container.
- A small pickup VFX: the beacon scales up + fades over 0.2s, label rises and fades — visible "+1 item" beat. SFX hook for 27f.

### D. F-key reuse
- The fire key is **F**. To avoid clashing, pickup uses a different key — **G** for "grab" (or hold-F if overlapping a pickup, fire otherwise). Lean: **G**, no special-casing.

### E. Eval coverage
- `test_drops.gd`: simulate a Combatant `_die()` with a forced loot table, verify pickups appear in the host. Simulate a player overlap + grab, verify the stub inventory grows.

## Files

| Path | Action |
|---|---|
| `godot/scenes/ItemPickup.tscn` | new |
| `godot/scripts/item_pickup.gd` | new |
| `godot/scripts/combatant.gd` | wire `_die()` to spawn pickups |
| `godot/scripts/player_controller.gd` | bind `grab` (G); overlap check + grab |
| `godot/test_drops.gd` | new — drop + pickup eval |

## Acceptance
1. Kill an enemy → at least sometimes a beacon + label appear at the corpse.
2. Walk over the beacon, press G → it disappears and the player's `inventory_stub` has it.
3. Beacon + label colour matches the item's rarity.
4. `test_combat.gd` 21/21 · `test_movement.gd` 6/6 · `test_drops.gd` green · boots clean.

## Open decisions
- **Pickup key** — `G` vs hold-`F`. Lean G.
- **Outward kick** — drops scatter ~0.5-1m randomly from the corpse so a multi-drop reads as a small loot pile.
- **Auto-pickup for gold** — gold currency auto-pickup on overlap (no key). Other items require G. Lean: yes, gold auto-pickup is friendly.
