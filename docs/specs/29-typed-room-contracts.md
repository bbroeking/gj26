# 29 — Typed room contracts (+ playtest scale tuning)

> **Outcome**: every door is a *choice*. A treasure room actually holds a chest you open. A shrine offers a real buff at a real altar. A rest room hands you a heal + checkpoint before the boss. Rooms stop being scenery and start being mechanics.

## Why

Spec 25 gave rooms themes and a `role` label (`entrance / combat / treasure / shrine / boss / setpiece`). Spec 28 fixed where the props sat. But the `role` is still cosmetic — a "treasure" room just gets a vault theme with a chest *decor* in it; the chest is geometry, not loot. Players walk in, find nothing to do, walk out. Every door leads to the same room.

The level-design research is unambiguous: typed rooms with mechanical contracts are the #1 lever for "designed-feeling" dungeons (Isaac's eight room categories; Hades' chamber pools). This spec promotes role from a label to a contract — each non-combat role guarantees a specific interaction.

A second concern bundled here: the dungeon frame felt cramped at 34×34 grid + 6–12 tile rooms + zoom 13. Rooms were smaller than the camera frustum, so the player saw one room at a time with no margin. Const bumps (already shipped pre-spec) widen the world and pull the camera back so the Diablo "multiple rooms in frame" framing returns.

## Scope

**In:**
- **Playtest tuning (already shipped, document here)** — `GRID 34→48`, `ROOM_MIN/MAX 6-12 → 8-14`, `ZOOM_DEFAULT 13→17`, `arrow.SPEED 34→50`. No spec'd change beyond the const tweaks; this section is a paper trail.
- **New role `rest`** in `_assign_rooms` — guaranteed 1 per dungeon, placed adjacent to the boss room on the critical path. Plus guarantee that every dungeon has ≥1 `treasure` and ≥1 `shrine` (currently best-effort).
- **Interactable Chest** — replace the decorative `chest` GLB in treasure rooms with `Chest.tscn`. Press `E` near it → open animation → spawn `roll_drop("boss", depth)` × 1 + 1 currency-tier item using the existing `_spawn_drops` pipe.
- **Interactable Shrine** — replace the decorative `altar` in shrine rooms with `Shrine.tscn`. Press `E` near it → open `ShrineChoiceModal` with 3 buff cards. Selecting one applies to `player.derived_stats` for the rest of the run; the shrine becomes inert. (One-shot per shrine, max one shrine per dungeon.)
- **Interactable Hearth** — new decor kind in rest rooms. Reuses the `brazier` GLB for v1 (proper hearth GLB is a followup). Press `E` near it → heal to full HP + write a single checkpoint slot (room id + derived stats snapshot). On death, restart at the last checkpoint instead of dungeon entrance.
- **Interact prompt** — when the player is in range of any interactable, show a floating "[E] Open" / "[E] Pray" / "[E] Rest" label. Reuses the floating-text overlay from spec 27.
- **`Interactable` Area3D pattern** — a new physics layer (`INTERACT_LAYER := 32`) plus a scanner Area3D on the player (mirrors the pickup scanner from spec 27b). One `_try_interact()` method, dispatches to the nearest registered interactable.
- **Shrine buff pool** — 3 buffs picked deterministically per dungeon seed from a pool of 6: `+20 HP max`, `+25% arrow damage`, `+15% crit chance`, `+50% crit mult`, `+20% fire rate`, `+15% move speed`. (Plugs into the existing `derived_stats` system from spec 27e.)
- **Eval coverage** — `test_typed_rooms.gd`:
  - **T1** — across 10 runs, every dungeon has exactly 1 entrance, exactly 1 boss, ≥1 rest, ≥1 treasure, ≥1 shrine.
  - **T2** — the rest room is adjacent (graph distance ≤1) to the boss room.
  - **T3** — `Chest.tscn` instantiates cleanly and `interact()` returns a non-empty pile via `Drops.roll_drop`.
  - **T4** — `Shrine.tscn::interact()` writes to `derived_stats` and flips `consumed = true`.
  - **T5** — `Hearth.tscn::interact()` restores HP to `hp_max` and stores a checkpoint dict with `room_id` + `derived_stats` snapshot.

**Out (explicit non-goals):**
- **Puzzle rooms / story vignettes / Hollow challenge rooms** — roadmap items #4–5; later spec.
- **Lock-and-key cycle injection** — roadmap item #3; separate spec.
- **Chunk template library expansion** — roadmap item #2; separate spec (likely the biggest one).
- **Cross-session save** — checkpoint is in-memory only; resumes on death, lost on quit.
- **Authored Hearth GLB** — followup; v1 reuses brazier.
- **Sealed-doors-until-cleared in combat rooms** — significant gameplay shift; separate spec if we want it.
- **Lore fragment items** dropping from chests — bundled into spec 30+ alongside the world-bible integration.
- **Camera/scale tuning beyond the const bumps in the playtest-tuning section** — already shipped; revisit only if playtest reveals it's still wrong.
- **Fixing the 1/47 focal-placement edge case** from spec 28 that the bigger rooms re-exposed — followup; not blocking.

## Files

| Path | Action |
|---|---|
| `godot/scripts/dungeon_gen.gd` | modify `_assign_rooms` — guarantee 1 treasure + 1 shrine + 1 rest per dungeon, place rest adjacent to boss; add `rest` to ROOM_THEMES (theme: `hearthroom`, focal: brazier (centre), satellites: pottery (scatter)) |
| `godot/scripts/layout_loader.gd` | `_build_room` reads role; for treasure → instantiate `Chest.tscn` at focal cell instead of decor chest; for shrine → instantiate `Shrine.tscn` at focal cell instead of decor altar; for rest → instantiate `Hearth.tscn` at focal cell instead of decor brazier; existing decor pass otherwise unchanged |
| `godot/scenes/Chest.tscn` | new — Area3D (INTERACT_LAYER) + GLB child + optional open AnimationPlayer |
| `godot/scripts/chest.gd` | new — `class_name Chest` extends Node3D; `interact(player)`: returns pile via `Drops.roll_drop("boss", depth)` + 1 currency item, spawns ItemPickup nodes, plays SFX, sets `_opened = true` |
| `godot/scenes/Shrine.tscn` | new — Area3D + altar GLB + glowing decal |
| `godot/scripts/shrine.gd` | new — `class_name Shrine` extends Node3D; `interact(player)`: opens choice modal, on pick applies buff to `player.derived_stats`, sets `_consumed = true` |
| `godot/scenes/ShrineChoiceModal.tscn` | new — CanvasLayer + 3 buff Cards with name/value/icon |
| `godot/scripts/shrine_choice_modal.gd` | new — `signal chosen(buff_id)`; pauses tree while open |
| `godot/scenes/Hearth.tscn` | new — Area3D + brazier GLB + fire particles (existing) |
| `godot/scripts/hearth.gd` | new — `class_name Hearth` extends Node3D; `interact(player)`: heals player to full, writes checkpoint via `Checkpoint.save(player, current_room_id)` |
| `godot/scripts/checkpoint.gd` | new — `class_name Checkpoint` autoload; `save(player, room_id)` / `load() -> Dictionary` / `clear()`; in-memory dict |
| `godot/scripts/player_controller.gd` | add INTERACT_LAYER scanner (mirror of pickup scanner from 27b); `_try_interact()` on E-key, nearest registered interactable wins; floating prompt while in range; `respawn_at_checkpoint()` reads Checkpoint on death |
| `godot/scripts/sfx.gd` | add `chest_open`, `shrine_bless`, `hearth_rest` SFX paths (3 new ElevenLabs gens — confirm cost before spending) |
| `godot/test_typed_rooms.gd` | new — 5 evals above |
| `docs/GODOT_PIPELINE.md` | update — typed rooms section |

## Acceptance criteria

1. Walk a generated dungeon — every run has at least one of each: entrance, boss, treasure, shrine, rest. Verified by `test_typed_rooms.gd T1`.
2. The rest room sits next to the boss room (adjacent on the dungeon graph). `T2` green.
3. Approach a chest in a treasure room — a floating "[E] Open" appears; press E and 1–2 items drop nearby (using the spec 27b pickup pipe).
4. Approach the altar in a shrine room — "[E] Pray" appears; press E and the 3-buff choice modal pauses the game; selecting one applies the buff (verified by inspecting `derived_stats` before/after) and the altar dims/inert.
5. Approach the hearth in a rest room — "[E] Rest" appears; press E and HP refills to max, a "checkpoint saved" floater fires.
6. Die after a checkpoint — respawn at the rest room, not the dungeon entrance, with HP full and stats preserved.
7. `test_typed_rooms.gd` green (5/5).
8. Every existing harness still green (7 + 5 + 8 + 7 + 5 + 6 + 21 + 3 = 62).
9. World boots, score ≥ 0.9.

## Open decisions

- **Buff selection determinism** — should the same dungeon seed always offer the same 3 buffs at the same shrine? Lean: **yes** (seeded `RandomNumberGenerator` from `seed + shrine_room_id`); makes shrines feel authored and lets the player learn-and-route.
- **Interactable detection** — physics layer + scanner Area3D vs a global registered list. Lean: **physics layer + scanner** (consistent with the spec 27b pickup pattern; one code path).
- **Chest re-openability** — chest stays open and inert after one use? Lean: **yes** (visual state change; can't re-loot).
- **Checkpoint scope** — single slot per dungeon vs stack of all hearths visited. Lean: **single slot, overwrites** (simplicity; player can't "rewind" by triggering an older hearth).
- **Hearth GLB** — author new or reuse brazier? Lean: **reuse brazier** for v1; followup to author a proper hearth (kettle on stones + cozy flame).
- **Rest room being "discoverable" vs guaranteed mark on map** — lean: **discoverable** (no minimap indicator); but guarantee it's always adjacent to boss so a careful player learns the pattern.
- **SFX spend** — 3 new ElevenLabs gens (~$0.30 estimate); confirm cost before spending per project memory.

## References

- Spec 25 — themed dungeons (where role + theme came from).
- Spec 27b — pickup scanner pattern (mirror for interactables).
- Spec 27e — `derived_stats` (where shrine buffs apply).
- Spec 27f — SFX integration pattern.
- Spec 28 — focal placement (chest/altar/hearth occupy the focal cell).
- The level-design research synthesis from this conversation — Isaac room types, Hades chamber pools, Death's Door environmental storytelling.
- `godot/scripts/dungeon_gen.gd::_assign_rooms` — current role assignment.
- `godot/scripts/layout_loader.gd::_build_decor` / `_build_room` — decor → interactable swap point.
- `godot/scripts/combatant.gd::_spawn_drops` — loot pipe to reuse for chests.
- `godot/data/drops.gd::roll_drop` — drop table.

## Done check

- [ ] `_assign_rooms` guarantees entrance + boss + rest + treasure + shrine
- [ ] Rest room placed adjacent to boss on the graph
- [ ] `Chest.tscn` + `chest.gd` — opens, drops, inert after
- [ ] `Shrine.tscn` + `shrine.gd` + `ShrineChoiceModal.tscn` — choice applies to derived_stats, inert after
- [ ] `Hearth.tscn` + `hearth.gd` + `checkpoint.gd` — heal + checkpoint save
- [ ] `INTERACT_LAYER` scanner + E-key handler in `player_controller.gd`
- [ ] Floating "[E] …" prompt while in range
- [ ] Respawn at checkpoint on death
- [ ] 3 new SFX added (cost confirmed first)
- [ ] `test_typed_rooms.gd` 5/5
- [ ] Existing harnesses still green
- [ ] `GODOT_PIPELINE.md` typed-rooms section updated
- [ ] Playtest: walk a run, hit one of each interactable
