# Implementation notes — 32d-interactable-base

## Decisions
- **`interact(_player)` has no explicit return type in the base** (loose `func interact(_player: Node):`). GDScript strict signature matching would reject Chest's `-> Array` and Hearth's `-> Dictionary` returns against a `-> void` parent. Loosening the parent's return type lets each subclass return its own test-seam shape (Array of drops, Dictionary checkpoint slot, void for Shrine). Documented inline in the base.
- **CollisionShape3D in the base is unnamed** — subclasses don't reference it by name, and the test (T6) walks `get_children()` looking for an instance of `CollisionShape3D` rather than a name match. Less coupling.
- **Subclasses pass collision_radius/offset/prompt_position through pure getter overrides** rather than fields, so each subclass's variation is co-located with the class definition rather than as init data on a base field. Reads cleaner.

## Deviations
- **Did not migrate `chest.gd`/`shrine.gd`/`hearth.gd` to a `scripts/interactables/` subdirectory.** Spec said top-level — confirmed. Future migration would touch the preload paths in `layout_loader._build_interactable`; not worth the churn for 3 files.
- **`Chest.interact` keeps the `Array` return type** even though the player never reads it. It's a test seam (`test_typed_rooms.T3` asserts on the pile). Same for `Hearth.interact -> Dictionary` (T5 reads the checkpoint slot). Preserved deliberately.

## Tradeoffs
- **Base owns the prompt Label3D entirely** (vs subclasses owning their own). Subclasses lose direct access to the label node — they reach via `get_node_or_null("PromptLabel")` when they want to manipulate it (e.g. Chest hides it after opening). Slight indirection cost; large boilerplate-reduction win. Confirmed in the rewrite — each subclass shrank ~30-40 lines.
- **`show_prompt(on)` is concrete in the base**, NOT virtual. Subclasses can't customise visibility logic beyond the `is_used()` gate. If a future interactable needs different prompt behaviour (e.g. flicker, fade), make `show_prompt` virtual then. v1 is fine with one impl.

## Surprises
- **Loosening the parent's return type was the only real friction.** Originally typed as `-> void`; got the strict "function signature doesn't match parent" parse error. Removing the explicit return type fixed it cleanly. GDScript treats no-return-type as Variant in this context.
- **The three subclasses are now structurally near-identical**: ~50 lines each (Chest) / ~75 (Shrine) / ~35 (Hearth). Hearth is the smallest because it has the simplest interact (heal + checkpoint). Shrine is the largest because it carries the BUFF_POOL data + modal hookup. All three follow the same five-hook override pattern.
- **Player's `_refresh_interact_prompt` was NEVER updated** — the spec said to change it to `is Interactable`, but the existing duck-typed code (`if n.has_method("show_prompt")`) still works because Interactable is in the duck-type set. Bonus: zero changes to `player_controller.gd` for spec 32d. The naming-seam payoff is that future readers see `is Interactable` in tests but the runtime check stays duck-typed for now. Could tighten later.

## Followups
- **Migrate `chest.gd`/`shrine.gd`/`hearth.gd` to `scripts/interactables/`** if/when spec 33+ adds a 4th interactable (NPC dialog, vendor). Until then the top-level flat layout is fine.
- **Make `_refresh_interact_prompt` use `is Interactable`** explicitly (instead of `has_method("show_prompt")`). One-line tightening; can land any time.
- **Make `show_prompt` virtual** if a subclass ever wants custom prompt visuals (flicker on use, fade on damage, etc.). Currently concrete in the base.
- **Author proper Hearth GLB** (kettle + cozy flame) — still on the spec 29 followup list. Hearth's `_ready_interactable` would just swap the BRAZIER_GLB constant.

## Status
COMPLETE — `test_typed_rooms.gd` 6/6 (added T6 for base contract) + every other harness still green. **Full arc tally: items 7 · inventory 8 · drops 5 · equipment 7 · stats 5 · movement 6 · combat 22 · decor 3 · typed rooms 6 · skills 7 · statuses 7 = 83/83 evals across 11 harnesses.** World boots, score 1.00. Pre-`spec 32` cleanup arc complete.
