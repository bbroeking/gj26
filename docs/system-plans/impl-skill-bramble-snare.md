---
title: Bramble Snare — Implementation Plan
parent: "[[skill-bramble-snare]]"
domain: Combat Skills
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Bramble Snare — Implementation Plan

> Build doc for [[skill-bramble-snare]]. All three deferred gaps land: Beat 1 windup pose, thornwood pod pickup economy wired to the satchel, and the upgrade/synergy affordances (tooltip hints, mark-tether variant, briarbound shrug-off VFX).

## Definition of done

1. Firing BrambleSnare produces a visible ~160 ms arm/body anticipation before the seed arc begins (Beat 1 WINDUP no longer a no-op).
2. Walking through snare pods deposits `thornwood_pod` materials into `Game.materials`; the pack count increments in the satchel UI; pods not collected wither cleanly with zero leaked nodes.
3. BrambleSnare tooltip mentions the Rain of Thorns and Hunter's Mark combos; a rooted-and-marked enemy shows a gold tether; a briarbound elite's shrug-off shows a white disc flash.
4. `test_skills.gd` stays green throughout; new logic-level test asserts pod collection count.

## Preconditions / dependencies

- `wyrd/scripts/skills/bramble_snare.gd` — already exists (551 lines). All insertion points below are real.
- [[impl-system-animation]] — `bow_draw_modifier.gd` (the pattern Phase 1 clones) already exists and is live on the chibi skeleton. No new animation files needed.
- [[impl-system-status-effects]] — `apply_root` / `apply_status` in `combatant.gd:542` is live; briarbound immunity guard at `combatant.gd:495` is live.
- [[impl-system-items-affixes]] — `data/items.gd` `KINDS` dict must gain a `thornwood_pod` material entry (task 3). The pod is a raw material, not a gear item, so it lives in `game.materials` via `Game.add_material()` (confirmed at `game.gd:301`), not the Tetris inventory.
- [[impl-system-skills-hotbar]] — `skill_bar.gd:52` owns `SKILL_DESC`; tooltip hint lands there (task 7).
- [[impl-system-combat-juice-vfx]] — squash/tween primitives already in player (see `player_controller.gd:790` death squash). No new VFX primitives needed.
- `data/gather.gd` does NOT need a new entry — `thornwood_pod` is a spell-dropped material, not a gather-node output.
- `sfx.gd:24` has `"skill_snare"` mapped. A new `"skill_snare_throw"` key is absent — needs adding (task 5).
- `audio/skill_snare_throw.mp3` does not exist yet — generate via `tools/generate_audio.py` (task 5).
- Plan.md Part B / Phase B0 (`feel.gd`) is NOT yet shipped — do NOT migrate timing constants until it is.

## Tasks (ordered)

### Phase 1 — WINDUP cast animation (Beat 1)

**Task 1** — `bramble_snare.gd:fire()` — add public `play_cast_windup(player)` helper; call it at the top of `fire()` before `_spawn_seed_projectile`.

```gdscript
func _play_cast_windup(player: Node) -> void:
    var mod: SkeletonModifier3D = player.get("_bow_modifier")
    if mod == null:
        return
    var tw := player.create_tween()
    tw.tween_property(mod, "draw_amount", 1.0, SEED_FLIGHT_SEC * 0.4) \
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tw.tween_property(mod, "draw_amount", 0.0, SEED_FLIGHT_SEC * 0.6) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
```

Insert `_play_cast_windup(player)` at `bramble_snare.gd:96` (immediately after `apply_recoil`, before `_spawn_landing_reticle`). The `draw_amount` tween does not block movement — additive arm-only pose. No lock window, no Focus accounting changes.

_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` stays green. `WYRD_SHOT=1` screenshot at ~80ms post-cast shows arms raised before the seed arc (visual confirmation only — no new automated assertion needed here). _Effort:_ S.

---

**Task 2** — `bramble_snare.gd:fire()` — also apply a brief mesh scale squash for whole-body wind-back (complements the arm pose).

At `bramble_snare.gd:96` (inside `fire()`, after `_play_cast_windup`):
```gdscript
var mesh = player.get("_mesh")
var base_scale: Vector3 = player.get("_mesh_base_scale") if mesh != null else Vector3.ONE
if mesh != null:
    var sq := mesh.create_tween()
    sq.tween_property(mesh, "scale",
        Vector3(base_scale.x * 1.06, base_scale.y * 0.92, base_scale.z * 1.06),
        SEED_FLIGHT_SEC * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    sq.tween_property(mesh, "scale", base_scale, SEED_FLIGHT_SEC * 0.65) \
        .set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
```

Matches the Plan.md §1 "scale-Y down 0.92 for 160ms" spec. Does not override `_mesh_base_scale` — reads via `player.get(...)` so it stays compatible with the existing flinch squash at `player_controller.gd:431`.

_Verify:_ `test_skills.gd` green; `WYRD_SHOT=1` screenshot shows visible body cock-back. _Effort:_ S.

---

### Phase 2 — Audio timing fix

**Task 3** — `sfx.gd:PATHS` — add `"skill_snare_throw"` key.

At `sfx.gd:24` (after the existing `"skill_snare"` line):
```gdscript
"skill_snare_throw": "res://audio/skill_snare_throw.mp3",
```

Generate `audio/skill_snare_throw.mp3` with `tools/generate_audio.py` (short bow-release whoosh, ~0.4s). The file is a graceful no-op if absent.

_Verify:_ `test_skills.gd` green; file appears in `audio/`. _Effort:_ S.

---

**Task 4** — `bramble_snare.gd:fire()` — move the SFX call split: throw-sound at cast, snap-crack at landing.

Current at `bramble_snare.gd:99-100`:
```gdscript
var sfx = player.get_node_or_null("/root/Sfx")
if sfx != null:
    sfx.play("skill_snare")
```
Replace with:
```gdscript
var sfx = player.get_node_or_null("/root/Sfx")
if sfx != null:
    sfx.play("skill_snare_throw")   # cast: seed leaves the bow
```
Then in `_on_seed_land()` at `bramble_snare.gd:253`, after the `_spawn_snare_visuals` call:
```gdscript
var sfx2 = player.get_node_or_null("/root/Sfx")
if sfx2 != null:
    sfx2.play("skill_snare")        # Beat 3: thorn snap
```

Both calls use `sfx.play(key)` which already applies `randf_range` pitch jitter at `sfx.gd:92`.

_Verify:_ `test_skills.gd` green; manual playtest — two distinct sounds fire at cast and at snap. _Effort:_ S.

---

### Phase 3 — Thornwood pod pickup economy

**Task 5** — `data/gather.gd:MATERIALS` — add `thornwood_pod` material entry.

After the `"thorn_essence"` entry at approximately `gather.gd:24`:
```gdscript
"thornwood_pod": {"name": "Thornwood Pod", "icon": "✦", "group": "verdant",
    "desc": "A glowing seed-pod left by a bramble snare. Crush three for hedge ink or keep them to ink a Briar chart."},
```

`gather.gd` is the canonical material catalogue (`Game.add_material` keyed by string id). No `items.gd` entry needed — thornwood pods are stackable satchel materials, not gear items.

_Verify:_ `grep "thornwood_pod" wyrd/data/gather.gd` returns the new entry; `test_wyrd_loop.gd` green. _Effort:_ S.

---

**Task 6** — `bramble_snare.gd:_make_thornwood_pod()` and `_spawn_thornwood_pods()` — wrap each pod `MeshInstance3D` in an `Area3D` pickup body.

Replace the return value in `_make_thornwood_pod()` (currently `MeshInstance3D`) with a `Node3D` wrapper that contains the mesh + an `Area3D`:

```gdscript
func _make_thornwood_pod() -> Node3D:
    var root := Node3D.new()
    root.name = "ThornwoodPod"
    # --- mesh (unchanged visuals) ---
    var pod := MeshInstance3D.new()
    pod.name = "PodMesh"
    # ... (all existing SphereMesh + StandardMaterial3D setup, unchanged) ...
    root.add_child(pod)
    # --- pickup Area3D ---
    var area := Area3D.new()
    area.name = "ThornwoodPod_Area"
    area.collision_layer = 16   # PICKUP_LAYER (mirrors player_controller.gd:130)
    area.collision_mask = 0
    area.monitoring = false
    area.monitorable = true
    var cs := CollisionShape3D.new()
    var sp := SphereShape3D.new()
    sp.radius = 0.30
    cs.shape = sp
    area.add_child(cs)
    root.add_child(area)
    return root
```

The existing bob tween in `_spawn_thornwood_pods` already targets `pod` (the `Node3D` wrapper), so only the `pod.position:y` tween reference needs updating to `pod` instead of the inner `MeshInstance3D`.

_Verify:_ In-editor or `WYRD_DEV_CHART=1` run — pod has a `ThornwoodPod_Area` child visible in the remote scene tree. `test_skills.gd` green. _Effort:_ M.

---

**Task 7** — `player_controller.gd:_on_pickup_entered()` — detect `ThornwoodPod_Area` and auto-collect.

Current at `player_controller.gd:1195-1197`:
```gdscript
func _on_pickup_entered(a: Area3D) -> void:
    if a != null and not _overlapping_pickups.has(a):
        _overlapping_pickups.append(a)
```

Extend to intercept pod areas before the generic append:
```gdscript
func _on_pickup_entered(a: Area3D) -> void:
    if a == null:
        return
    if a.name == "ThornwoodPod_Area":
        var game_node := get_tree().root.get_node_or_null("Game")
        if game_node != null:
            game_node.add_material("thornwood_pod", 1)
        var pod_root := a.get_parent()
        if is_instance_valid(pod_root):
            pod_root.queue_free()
        return
    if not _overlapping_pickups.has(a):
        _overlapping_pickups.append(a)
```

Auto-collect on proximity (walk-through), same as `item_pickup.gd`-style. Pod `queue_free` fires immediately; because pods are parented to the snare holder, this simply removes one pod while the holder continues to wither normally. Pods not collected are destroyed by `_wither → holder.queue_free` at `bramble_snare.gd:539`.

_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` green. New test case in `test_skills.gd` (see Test Plan). _Effort:_ M.

---

### Phase 4 — Synergy affordances (polish)

**Task 8** — `skill_bar.gd:SKILL_DESC` — extend BrambleSnare tooltip with combo hint.

At `skill_bar.gd:56`, replace:
```gdscript
"BrambleSnare":  "Roots enemies in a bramble patch. Elites marked Briarbound shrug it off.",
```
with:
```gdscript
"BrambleSnare":  "Roots enemies in a bramble patch. Follows Rain of Thorns for a free-damage window. Mark a rooted target to burst it. Briarbound elites shrug after the first catch.",
```

_Verify:_ `WYRD_UI_SHOT=skill_bar` confirms updated text in-game. `test_skills.gd` green. _Effort:_ S.

---

**Task 9** — `bramble_snare.gd:_spawn_tether()` — gold tether variant when target is marked.

At `bramble_snare.gd:492`, in the per-segment material setup block, after `mat.set_shader_parameter("base_color", Color(0.20, 0.55, 0.18))`:

```gdscript
# Gold variant when the target carries Hunter's Mark
if (target as Node).has_method("has_status") and target.has_status("marked"):
    mat.set_shader_parameter("base_color", Color(1.00, 0.82, 0.30))
    mat.set_shader_parameter("edge_color", Color(1.00, 0.95, 0.55))
    mat.set_shader_parameter("edge_energy", 10.0)
```

Matches `MARKED_MULT` gold at `combatant.gd:104`. No new mechanic — purely colorimetric read.

_Verify:_ Screenshot via `WYRD_GALLERY_ATTACK=1` with a marked enemy in a snare shows gold tethers. `test_skills.gd` green. _Effort:_ S.

---

**Task 10** — `bramble_snare.gd:_on_seed_land()` — briarbound shrug-off disc flash when root is blocked.

At `bramble_snare.gd:264`, the `AoeQuery.query_circle` loop currently calls `enemy.apply_root(SNARE_DURATION)` unconditionally. Add a shrug-off flash when the root returns null (briarbound immunity):

```gdscript
for enemy in AoeQuery.query_circle(tree, aim, SNARE_RADIUS):
    if enemy.has_method("apply_root"):
        var result = enemy.apply_status("root", SNARE_DURATION, 0, 1.0, 0.0) \
            if enemy.has_method("apply_status") else enemy.apply_root(SNARE_DURATION)
        if result == null and is_instance_valid(holder):
            _shrug_off_flash(holder)
        elif result != null and is_instance_valid(holder) and enemy is Node3D:
            _spawn_tether(holder, enemy)
```

New helper at end of file:
```gdscript
func _shrug_off_flash(holder: Node3D) -> void:
    var disc := holder.get_node_or_null("SnareDisc")
    if disc == null:
        return
    var mat: StandardMaterial3D = disc.material_override
    if mat == null:
        return
    var tw := holder.create_tween()
    tw.tween_property(mat, "emission", Color.WHITE, 0.06)
    tw.tween_property(mat, "emission",
        Color(ACTIVE_COLOR.r, ACTIVE_COLOR.g, ACTIVE_COLOR.b), 0.22) \
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
```

Note: `apply_root` is a void alias at `combatant.gd:542`; the shrug-off path requires calling `apply_status` directly and checking its return for null. Guard with `has_method("apply_status")` for backward compatibility with test doubles.

_Verify:_ `WYRD_DEV_BOSS=` pointing at a briarbound elite shows white disc flash at the CC-immune hit. `test_skills.gd` green. _Effort:_ S.

---

## First commit (smallest shippable slice)

**Tasks 1 + 2 only** — WINDUP beat.

PR acceptance: `test_skills.gd` stays green; `WYRD_SHOT=1` screenshot shows a visible arm-raise / body-squash before the seed leaves the bow. No Focus, cooldown, or satchel changes. This is the one gap the parent note calls "highest-value" and it is the smallest possible diff (two tween blocks inside `fire()`).

---

## Test & verification plan

### Existing suites (all must stay green)

Run after every task:
```
cd wyrd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd
WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd
```

`test_wyrd_dungeon_scene.gd` and `test_wyrd_transitions.gd` are lower-risk for this work but should pass on the Phase 3 milestone.

### New logic test (task 7 milestone)

Add to `test_skills.gd` a case (or to `test_wyrd_loop.gd` if the scene fixture is a better host):

```gdscript
# Assert thornwood pod collection wires to satchel
func test_pod_collection() -> void:
    var bs := BrambleSnareScript.new()
    # fire snare at a point the dummy player overlaps
    bs.fire(_player)
    await get_tree().process_frame
    await get_tree().process_frame
    # Simulate player overlap with every ThornwoodPod_Area in scene
    for node in get_tree().get_nodes_in_group("thornwood_pods"):  # or iterate holder children
        var area: Area3D = node.get_node_or_null("ThornwoodPod_Area")
        if area != null:
            _player._on_pickup_entered(area)
    var game_node := get_tree().root.get_node_or_null("Game")
    assert(int(game_node.material_count("thornwood_pod")) == BrambleSnareScript.THORNWOOD_POD_COUNT,
        "pod_collection: expected %d pods, got %d" % [
            BrambleSnareScript.THORNWOOD_POD_COUNT,
            game_node.material_count("thornwood_pod")])
```

### Screenshot/playtest checkpoints

| Task | Method |
|------|--------|
| 1+2 (WINDUP) | `WYRD_SHOT=1` at ~80 ms post-cast; confirm arm raise + body squash |
| 4 (audio) | Manual playtest — two SFX fire at separate times |
| 7 (pods) | `WYRD_DEV_CHART=1` run — walk through pods, open satchel (M), confirm count |
| 9 (gold tether) | `WYRD_GALLERY_ATTACK=1` with HuntersMark + BrambleSnare — screenshot shows gold rope |
| 10 (shrug-off) | `WYRD_DEV_BOSS=briarbound` run — cast snare, confirm white disc flash |

---

## Risks & open questions

1. **Pod lifetime after wither** — the parent note's open question is still live: should pods that are NOT collected persist on the floor after `_wither` destroys the holder, or be destroyed with it? Task 6 as written destroys them with the holder (simplest; no leaks). If persistence is desired, pods must be reparented from holder to the scene root at wither time — a non-trivial change. **Decide before Task 6 ships.** The recommended default is destroy-with-holder (collectibles during the 2.0 s body window; no floor litter).

2. **`apply_root` is a void alias** — `combatant.gd:542` `apply_root` is `void`; checking its return is impossible. Task 10 branches on `has_method("apply_status")` and calls `apply_status` directly to get the nullable return. This means the shrug-off flash only fires when the target is a full `Combatant` node; bare test doubles calling `apply_root` skip the flash silently (correct behavior).

3. **Upgrade/mastery path deferred** — per the KB HORIZON note, named per-skill mastery knobs and cross-skill synergy stat amplification are out of demo scope. Tasks 8–10 add the visual/tooltip scaffolding only. The stat amplification (extended duration, wider radius, +damage on root, re-root window) is a follow-on item — do not build it until the KB HORIZON scope is confirmed.

4. **`thornwood_pod` crafting use** — Task 5 adds the material entry with a flavour desc hinting at Briar chart inking. No crafting recipe exists yet. The material is inert until a recipe is added in [[impl-system-crafting]]; harvesting it is safe and additive.

5. **SFX file cost** — `audio/skill_snare_throw.mp3` requires an ElevenLabs generate call (~$0.10). Confirm spend before Task 3. The key is a graceful no-op in `sfx.gd` until the file lands.
