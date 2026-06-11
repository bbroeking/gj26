# 32d — Interactable base class

> **Outcome**: the implicit "anything press-E-able" protocol (currently a convention: add to group `"interactable"`, implement `interact(player)` + `show_prompt(bool)` + `is_used()`) becomes an explicit `Interactable` base class. Chest, Shrine, and Hearth shrink to ~half their current size by deleting duplicated Area3D + collision + Label3D setup. Future interactables (NPC dialog, vendor, lore fragment) follow the named contract instead of copy-pasting from the example trio.

## Why

The `/improve-codebase-architecture` review flagged candidate #4 as "Worth exploring — clarity deepening, not a complexity reduction." The grill (Q4.1) upgraded it to maximal absorption: the base owns Area3D + collision sphere + Label3D prompt + group registration in addition to naming the protocol.

Today's three interactables (Chest, Shrine, Hearth) each duplicate ~15 lines of identical boilerplate in `_ready()`:

```gdscript
# Same in chest.gd, shrine.gd, hearth.gd:
add_to_group("interactable")
collision_layer = INTERACT_LAYER
collision_mask = 0
var sh := CollisionShape3D.new()
var sp := SphereShape3D.new()
sp.radius = 0.9  # or 1.0 or 1.1 per subclass
sh.shape = sp
sh.position = Vector3(0.0, 0.5, 0.0)  # or 0.6
add_child(sh)
# ... + ~10 lines of Label3D prompt building (text, billboard, font, outline, color, position)
```

The protocol the player-side scanner relies on (`add_to_group("interactable")`, `interact(player)`, `show_prompt(on)`, `is_used()`) is named nowhere. It's a convention inferred from three examples. Spec 33+ will add a fourth interactable (NPC dialog, vendor) and the implicit pattern will scale by example, not by contract.

Deletion test: remove the base. Boilerplate stays in 3 implementations + 1 caller (player). Future interactables continue copy-pasting. Complexity doesn't disappear — it stays unnamed and unverifiable. The deepening earns its depth by **naming the seam** and absorbing the common setup.

This ships as **spec 32d**, the last of the pre-`spec 32` cleanup arc (32a Pickup → 32b Skill → 32c HitFeedback → 32d Interactable → spec 32 pack scaling).

## Scope

### In

- **`scripts/interactable.gd`** (`class_name Interactable extends Area3D`) at top-level (parallel to `status_effect.gd`, `aoe_query.gd`, `hit_feedback.gd` — established convention; no subdir migration).
- **Base `_ready()` builds the common setup**:
  - `collision_layer = INTERACT_LAYER`
  - `collision_mask = 0`
  - `add_to_group("interactable")`
  - Spawns a `CollisionShape3D` with a `SphereShape3D` (radius from `get_collision_radius()`, default 1.0; position from `get_collision_offset()`, default `Vector3(0, 0.5, 0)`)
  - Spawns a `Label3D` named `"PromptLabel"` using `get_prompt_text()` + `get_prompt_color()`, billboard enabled, font_size 48, outline_size 12, no_depth_test, position from `get_prompt_position()` (default `Vector3(0, 1.7, 0)`), visible=false initially
  - Calls `_ready_interactable()` virtual for subclass setup (their GLB + glow etc.)
- **Virtual hooks** (subclasses override):
  - `interact(player: Node) -> void` — abstract, pushes error on base
  - `is_used() -> bool` — default `return false` (multi-use); Chest + Shrine override to track their one-shot state
  - `get_prompt_text() -> String` — default `"[E] Interact"`; each subclass returns its own ("[E] Open" / "[E] Pray" / "[E] Rest")
  - `get_prompt_color() -> Color` — default `Color(1.0, 0.95, 0.65)` (warm); shrines override to cool blue, hearths to warm amber
  - `get_collision_radius() -> float` — default `1.0`; subclasses override if they want (Chest=0.9, Shrine=1.1, Hearth=1.0)
  - `get_collision_offset() -> Vector3` — default `Vector3(0, 0.5, 0)`; subclasses override if they want
  - `get_prompt_position() -> Vector3` — default `Vector3(0, 1.7, 0)`; subclasses override for their model
  - `_ready_interactable() -> void` — virtual hook called after base setup; subclasses do their GLB + glow + other unique setup here. Default is empty.
- **`show_prompt(on: bool)`** — concrete on base. Toggles the PromptLabel's visibility, gated by `is_used()`:
  ```gdscript
  func show_prompt(on: bool) -> void:
      var lbl := get_node_or_null("PromptLabel") as Label3D
      if lbl != null:
          lbl.visible = on and not is_used()
  ```
  Subclasses don't override unless their `is_used()` semantics need a different gate.
- **`scripts/chest.gd` rewrite** — extends `Interactable`. Loses ~40 lines:
  - `_ready()` becomes `_ready_interactable()`: just spawn the chest GLB, add as child; no collision/Label/group code.
  - Override `get_prompt_text() -> String: return "[E] Open"`.
  - Override `get_prompt_color() -> Color: return Color(1.0, 0.95, 0.65)`.
  - Override `is_used() -> bool: return _opened`.
  - `interact(player)` body unchanged (rolls drops + spawns pickups + plays SFX + `_opened = true`).
- **`scripts/shrine.gd` rewrite** — extends `Interactable`. Loses ~30 lines:
  - `_ready_interactable()`: altar GLB + OmniLight3D glow.
  - `get_prompt_text() -> String: return "[E] Pray"`.
  - `get_prompt_color() -> Color: return Color(0.85, 0.95, 1.0)` (cool blue).
  - `is_used() -> bool: return _consumed`.
  - `interact(player)` body unchanged (instantiates modal + sets up callback).
- **`scripts/hearth.gd` rewrite** — extends `Interactable`. Loses ~30 lines:
  - `_ready_interactable()`: brazier GLB + warm OmniLight3D glow.
  - `get_prompt_text() -> String: return "[E] Rest"`.
  - `get_prompt_color() -> Color: return Color(1.0, 0.85, 0.7)`.
  - `is_used()` stays default (returns false — multi-use).
  - `interact(player)` body unchanged (heal + Checkpoint.save).
- **`player_controller.gd::_refresh_interact_prompt`** — minor cleanup: now reads `Interactable` type explicitly instead of duck-typing `has_method("show_prompt")`. The for-loop and nearest-finder logic stay.
- **`test_typed_rooms.gd`** — no behavior change expected (interact + is_used still work identically). T3, T4, T5 still assert on the same observable outcomes. Add one new test: T6 — instantiating `Chest.new()` (after class_name registration) sets `collision_layer = INTERACT_LAYER` and adds itself to group `"interactable"` (verifies the base contract).
- **`CONTEXT.md`** addition:
  - **Interactable** — a world object the player presses E to engage. Single-use (Chest, Shrine) or multi-use (Hearth). Spawned by typed-room contracts (spec 29). Detected via INTERACT_LAYER + the player's InteractScanner. _Avoid_: triggerable, usable, prompt-target.
- **`docs/GODOT_PIPELINE.md`** — add "Interactable system (spec 32d)" pointing here.

### Out (explicit non-goals)

- **Priority field for multi-interactable rooms**. The Explore agent's sketch suggested `priority: int = 0` for cases where two interactables overlap. v1 has at most one per room; defer until a use case appears.
- **Auto-detection of the player's facing direction**. v1 selects the nearest interactable by distance; facing-cone selection is spec 33+ if needed.
- **File migration to `scripts/interactables/` subdirectory**. Chest/Shrine/Hearth stay at top-level; only `interactable.gd` is added. Adds zero new files for unrelated concepts.
- **An `Interactable` test harness** of its own. The existing `test_typed_rooms.gd` covers the three concrete subclasses through the player. One new T6 added there.
- **Renaming `interact(player)` to something like `engage` or `activate`**. Keep the existing verb — it matches the convention and the player key (E for "interact").
- **Generalising to non-Area3D interactables** (e.g. UI button + 3D world combined). Stays Area3D-only.
- **An "interactable scanner" base class** that the player uses. The player's existing `_make_interact_scanner` + `_overlapping_interactables` + `_refresh_interact_prompt` stay as-is.

## Files

| Path | Action |
|---|---|
| `scripts/interactable.gd` | **new** — base class with Area3D setup + Label3D prompt + virtual hooks |
| `scripts/chest.gd` | Rewrite to extend Interactable; lose ~40 lines of duplicated setup |
| `scripts/shrine.gd` | Rewrite to extend Interactable; lose ~30 lines |
| `scripts/hearth.gd` | Rewrite to extend Interactable; lose ~30 lines |
| `scripts/player_controller.gd` | `_refresh_interact_prompt` reads Interactable type (minor) |
| `test_typed_rooms.gd` | Add T6 verifying the base contract |
| `CONTEXT.md` | Add Interactable entry |
| `docs/GODOT_PIPELINE.md` | Brief "Interactable system (spec 32d)" section pointing here |

## Acceptance criteria

1. `Chest.new()` (after class_name registration) is an `Area3D` whose `collision_layer == INTERACT_LAYER`, is in group `"interactable"`, has a child `CollisionShape3D` with a `SphereShape3D`, and has a child `Label3D` named `"PromptLabel"` showing `"[E] Open"` in warm gold.
2. Same for `Shrine.new()` (`"[E] Pray"`, cool blue) and `Hearth.new()` (`"[E] Rest"`, warm amber).
3. `Chest._ready_interactable()` is called and spawns the chest GLB. (Verify by checking `chest.get_children()` contains a Node3D loaded from the chest GLB.)
4. `chest.show_prompt(true)` makes the label visible. `chest._opened = true` then `chest.show_prompt(true)` keeps it hidden (because `is_used()` gates).
5. `chest.interact(player)` still rolls drops, spawns pickups, plays SFX, sets `_opened = true` — same as spec 29.
6. Shrine + Hearth's interact paths are observable-identical to spec 29 (modal opens, choice applies; HP refills + checkpoint saves).
7. `test_typed_rooms.gd` 6/6 green (5 existing + 1 new T6).
8. Every other harness still green.
9. World boots; manual playtest confirms approaching chest/shrine/hearth shows the prompt, pressing E behaves identically to spec 29.

## Open decisions

All load-bearing decisions resolved by the grill (#4.1, #4.2). Mini-decisions resolved by lean:

- **`Interactable` extends `Area3D`** directly (not a wrapper around Area3D). Subclasses are Area3D nodes in the scene tree, instantiated via `Chest.new()` / `Shrine.new()` / `Hearth.new()` and `add_child`-ed by layout_loader.
- **`_ready()` is FINAL on the base** — subclasses don't override `_ready` (they'd lose the boilerplate). The hook is `_ready_interactable()`. Documented in the base file's header comment.
- **Default prompt text is `"[E] Interact"`** — useful fallback if a subclass forgets to override. Doesn't conflict with the three current ones.
- **`is_used()` default returns false** (multi-use) — the safer default; subclasses opt into one-shot via override.
- **Class registration via `class_name Interactable`** — lets `is Interactable` checks work in `player_controller._refresh_interact_prompt` without preloads.
- **The base does NOT own any glow / particle / GLB** — those are unique to each subclass. Only the universal setup (Area3D, collision, group, Label3D prompt) is absorbed.
- **No collision layer for interactables that should not be detected** (used / consumed). Subclasses set `collision_layer = 0` themselves when consumed (existing pattern in Chest + Shrine). The base doesn't manage this.
- **Spec 29 SFX paths (`chest_open`, `shrine_bless`, `hearth_rest`) stay in subclasses** — they're not universal.
- **No ADR** — pure refactor, clarity deepening; the protocol is reversible.

## References

- Architecture review HTML at `/var/folders/85/24ylx5853k791kpbpq8qzkjm0000gn/T/architecture-review-20260526-084353.html` (candidate #4).
- Spec 29 (`docs/specs/29-typed-room-contracts.md`) — original typed-room interactables this generalizes.
- `CONTEXT.md` — Interactable entry added here.
- Skill: `~/.claude/skills/improve-codebase-architecture/LANGUAGE.md` — naming-seam vocabulary used throughout.

## Done check

- [ ] `scripts/interactable.gd` written with full base setup + virtual hooks
- [ ] `chest.gd` rewritten as Interactable subclass; ~40 lines removed
- [ ] `shrine.gd` rewritten; ~30 lines removed
- [ ] `hearth.gd` rewritten; ~30 lines removed
- [ ] `player_controller._refresh_interact_prompt` uses `is Interactable` type check
- [ ] `test_typed_rooms.gd` T6 added; full harness 6/6 green
- [ ] Every other harness still green
- [ ] World boots; manual playtest of all 3 interactables works
- [ ] `CONTEXT.md` Interactable entry present
- [ ] `GODOT_PIPELINE.md` Interactable section added
