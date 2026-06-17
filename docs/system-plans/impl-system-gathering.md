---
title: Gathering & Nodes — Implementation Plan
parent: "[[system-gathering]]"
domain: Gather · Craft · Economy
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Gathering & Nodes — Implementation Plan

> Build doc for [[system-gathering]]. When done: `herbal_patch` fallback item is correct, the ink-discovery hint chain fires reliably for the `still`/`forge` inks, and the deep-tier glow pass makes starsilver/hedgesteel/foxglove/stonebreak visually distinct at play distance.

## Definition of done

- `dungeon_gen.gd:291` — `GATHER_BY_AFFIX["herbal_patch"]` has `"item": ""` (no misleading fallback).
- A headless dungeon scene log confirms a `herbal_patch` decor entry whose `item` field is never `"wild_herb"` unless `herb_tier == "wild"`.
- `gather_node.gd:_tint_tier` extends to emit a point light child for `ore_tier in ["starsilver","hedgesteel"]` and a slow modulate pulse for `herb_tier in ["foxglove","stonebreak"]`.
- `game.gd:first_time_hint` fires correctly for `"still"` and `"forge"` on first station visit — verified by checking `craft_station.gd:42` call path and adding a targeted logic test.
- Feel beats (Plan.md B1 arm articulation, B2 harvest pop, B7 town regrowth) are **not** handled here — they are tracked by [[impl-system-animation]] and [[impl-system-audio-music]] respectively.

## Preconditions / dependencies

- **None blocking for Tasks 1–3.** All files already exist; no missing scripts.
- [[impl-system-trades-progression]] — `req_lv` gating is already live; this plan does not re-implement it.
- [[impl-system-crafting]] — ink discovery is downstream of gather materials; the `try_pot_mix` path is already wired (game.gd:574–625). Task 3 adds a test fixture only.
- [[impl-system-dungeon-generation]] — the `_scatter_gather_nodes` and `_roll_tier` functions are complete; Task 1 is a one-line data fix inside the same file.
- Plan.md Part B / B0 must land before the feel tasks (B1, B2, B7) — NOT required for Tasks 1–4 in this plan.

## Tasks (ordered)

### Task 1 — Fix `herbal_patch` fallback item (data bug)
**`wyrd/scripts/dungeon_gen.gd:291`** — Change `"item": "wild_herb"` → `"item": ""` in `GATHER_BY_AFFIX["herbal_patch"]`.

```gdscript
# Before (line 291)
"herbal_patch": {"kind": "forage_node", "item": "wild_herb", "count": [6, 9]},
# After
"herbal_patch": {"kind": "forage_node", "item": "",          "count": [6, 9]},
```

Rationale: `_scatter_gather_nodes` always calls `_roll_tier(FORAGE_ROLLS_PATCH, ...)` for `herbal_patch` (lines 340–342), so `entry_d["herb_tier"]` is always set, and `layout_loader.gd:532` calls `gn.setup_herb_tier()` which overwrites `item_id`. The `"item"` field in the decor dict is only used as the initial `setup()` arg (line 529), which is immediately overridden. An empty string makes the fallback intent clear and removes the misleading `wild_herb` value.

_Verify:_ `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` — all assertions green. Optionally add a `print` in `_scatter_gather_nodes` after append to log `herbal_patch` item field and confirm it is `""`.
_Effort:_ S (one-liner).

---

### Task 2 — Add a debug assertion to `test_wyrd_dungeon_scene.gd` for the `herbal_patch` item field
**`wyrd/test_wyrd_dungeon_scene.gd`** — After the existing layout generation assertion, iterate the decor array and assert that no `herbal_patch`-kind entry has `item == "wild_herb"` for a non-wild tier.

```gdscript
# In test body, after layout generation:
for d in layout.decor:
    if String(d.get("kind","")) == "forage_node" and d.has("herb_tier"):
        var ht: String = String(d.herb_tier)
        if ht != "" and ht != "wild":
            assert(String(d.get("item","")) != "wild_herb",
                "herbal_patch fallback: item should not be wild_herb for tier %s" % ht)
```

_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` — no assertion fires on tier-2 or tier-3 charts.
_Effort:_ S.

---

### Task 3 — Verify `still`/`forge` hint-key path (ink-discovery UX)
**`wyrd/scripts/craft_station.gd:42`** — The `first_time_hint(station_id)` call already fires `"still"` and `"forge"` correctly on first station interaction (`craft_station.gd:42` is the only call site for these station IDs). The gap noted in [[system-gathering]] is a *playtest* question, not a code bug.

Write a minimal headless logic test in **`wyrd/test_skills.gd`** (append to its existing suite, or create `wyrd/test_gather_hints.gd` if test_skills is too coupled) that:
1. Calls `game.first_time_hint("still")` twice and asserts `seen_hints["still"] == true` after the first call.
2. Calls `game.first_time_hint("forge")` and asserts it does not re-open the panel (i.e. `seen_hints["forge"]` is already set).

```gdscript
# Pseudocode — adapt to match harness pattern
game.first_time_hint("still")
assert(bool(game.seen_hints.get("still", false)), "still hint should be marked seen")
game.first_time_hint("still")   # second call must be no-op
game.first_time_hint("forge")
assert(bool(game.seen_hints.get("forge", false)), "forge hint should be marked seen")
```

_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` — new assertions pass; no regressions in existing hotbar dispatch cases.
_Effort:_ S.

---

### Task 4 — Tier-tint glow: point light for deep ores
**`wyrd/scripts/gather_node.gd:_tint_tier`** (line 179) — After applying the albedo tint, if `ore_tier in ["starsilver", "hedgesteel"]`, add a child `OmniLight3D` to `_body` with tier-specific warm/cool hues and a short range. Gate on `_body != null`.

```gdscript
# Append inside _tint_tier(), after the mesh loop (line ~187):
if ore_tier in ["starsilver", "hedgesteel"]:
    var glow := OmniLight3D.new()
    glow.light_color = Color(0.75, 0.82, 1.0) if ore_tier == "starsilver" \
        else Color(0.45, 0.90, 0.55)
    glow.light_energy = 0.6
    glow.omni_range = 3.0
    glow.omni_attenuation = 2.0
    glow.position = Vector3(0.0, 0.4, 0.0)
    _body.add_child(glow)
```

_Verify:_ Visual QA — `WYRD_DEV_CHART=tier3 WYRD_SHOT=1 godot --path wyrd` — screenshot at `/tmp/wyrd_town.png` shows a faint coloured halo around vein props. Also `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` stays green (no crash from the new child).
_Effort:_ S.

---

### Task 5 — Tier-tint glow: modulate pulse for deep herbs
**`wyrd/scripts/gather_node.gd:_tint_tier`** (line 179) — Mirror Task 4 for herb tiers. After the mesh loop, if `herb_tier in ["foxglove", "stonebreak"]`, start a looping `Tween` on `_body.modulate` that ping-pongs between the tier colour at full alpha and a slightly lighter/darker variant.

```gdscript
# Append inside _tint_tier(), after the OmniLight block:
if herb_tier in ["foxglove", "stonebreak"]:
    var pulse_col: Color = GatherDefs.HERB_TIERS[herb_tier].color
    var tw := create_tween()
    tw.set_loops()
    tw.tween_property(_body, "modulate",
        Color(pulse_col.r, pulse_col.g, pulse_col.b, 1.0), 1.2) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tw.tween_property(_body, "modulate", Color.WHITE, 1.2) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
```

Note: GDScript `Tween.set_loops()` is valid on a `SceneTreeTween`; `create_tween()` returns one. No `class_name` needed — `_tint_tier` is an instance method.

_Verify:_ Visual QA — load a tier-2 or tier-3 chart with `herbal_patch` affix and confirm foxglove/stonebreak patches have a visible slow colour pulse; wild/bittergrass patches are unaffected. `test_wyrd_dungeon_scene.gd` stays green.
_Effort:_ S.

---

### Task 6 — Deplete glow cleanup
**`wyrd/scripts/gather_node.gd:_deplete`** (line 351) — When a glow-equipped node depletes, the `OmniLight3D` child and any running `Tween` vanish with `_body` already (the body is scale-tweened to 0.05 then hidden). No extra code needed for the light. However, the looping herb pulse tween needs to be killed on deplete to avoid a freed-object error.

Store the tween reference as `_pulse_tween: Tween = null` and kill it in `_deplete`:

```gdscript
var _pulse_tween: Tween = null   # add to class vars

# In _tint_tier, replace tw := create_tween() with:
_pulse_tween = create_tween()
# ...

# In _deplete(), before the tween-to-scale block:
if _pulse_tween != null:
    _pulse_tween.kill()
    _pulse_tween = null
```

_Verify:_ `test_wyrd_dungeon_scene.gd` green; no `freed object` errors in editor or headless output when harvesting a tier-2 herb patch.
_Effort:_ S.

---

### Task 7 — Regrow glow resume
**`wyrd/scripts/gather_node.gd:_regrow`** (line 362) — Town herb patches (respawns = true) that have `herb_tier in ["foxglove","stonebreak"]` need the pulse tween restarted after regrowth (town teaches the bittergrass tier but could eventually have higher tiers via affix). Call `_tint_tier(_body)` (if `_body != null and herb_tier != ""`) at the end of `_regrow`:

```gdscript
# Append to _regrow(), after the scale tween:
if herb_tier in ["foxglove", "stonebreak"] and _body != null:
    _tint_tier(_body)
```

`_tint_tier` already guards against duplicate lights (it creates new children each call — acceptable since `_deplete` hides but does not free `_body`'s children; add a guard to `_tint_tier` to skip if a child `OmniLight3D` already exists):

```gdscript
# At start of the OmniLight block in _tint_tier:
if ore_tier in ["starsilver", "hedgesteel"] \
        and _body.get_node_or_null("GlowLight") == null:
    var glow := OmniLight3D.new()
    glow.name = "GlowLight"
    # ... rest of light setup ...
    _body.add_child(glow)
```

_Verify:_ Town scene playtest (`WYRD_SHOT=1 godot --path wyrd`): deplete a foxglove-tier town patch, wait for regrowth, observe pulse resumes. `test_wyrd_transitions.gd` green.
_Effort:_ S.

---

## First commit (smallest shippable slice)

**Tasks 1 + 2** as one commit: fix the `herbal_patch` fallback item in `dungeon_gen.gd:291` and add the regression assertion to `test_wyrd_dungeon_scene.gd`. This is a pure data correctness fix — no visual change, no gameplay change, one-line edit + one test assertion. Acceptance: `test_wyrd_dungeon_scene.gd` green, no `herbal_patch` entry logs `wild_herb` for a non-wild tier.

## Test & verification plan

| Task | Suite | Notes |
|---|---|---|
| 1 | `test_wyrd_dungeon_scene.gd` | Run after the one-line fix; check decor log |
| 2 | `test_wyrd_dungeon_scene.gd` | New assertion added; confirm it catches a re-regression if `wild_herb` is put back |
| 3 | `test_skills.gd` | New `seen_hints` assertions; run full suite to confirm no hotbar regressions |
| 4–5 | Visual QA | `WYRD_DEV_CHART=tier3 WYRD_SHOT=1 godot --path wyrd`; inspect `/tmp/wyrd_town.png` |
| 6 | `test_wyrd_dungeon_scene.gd` | Headless harvest simulation; no freed-object errors |
| 7 | `test_wyrd_transitions.gd` | Scene-transition suite stays green after regrow wiring |

New test to author: **`wyrd/test_gather_hints.gd`** (or appended to `test_skills.gd`) — a minimal script that instantiates Game, calls `first_time_hint("still")` and `first_time_hint("forge")`, and asserts `seen_hints` entries are set. Run with `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_gather_hints.gd`.

Playtest sign-off checklist (manual, not headless):
- [ ] Tier-2 chart with `mineral_vein` affix: confirm starsilver veins glow faint blue, hedgesteel veins glow faint green.
- [ ] Tier-2 chart with `herbal_patch` affix: confirm foxglove patches pulse blue-violet; no wild-tier patch pulses.
- [ ] Visit Quill's still for the first time: confirm `still` hint dialog fires once.
- [ ] Visit Hod's forge for the first time: confirm `forge` hint dialog fires once.
- [ ] Harvest and deplete a foxglove patch in a dungeon: confirm no error in output log.

## Risks & open questions

1. **`_tint_tier` called on GLB instance vs primitive**: The function iterates `find_children("*","MeshInstance3D",true,false)` over the root node. When a GLB is loaded the root is the GLB instance child; when falling back to `_build_primitive`, `_body` is the body node with MeshInstance3D children. Both paths are already handled correctly for tinting. The new `OmniLight3D` child is added to `_body`, not to the mesh root — this is intentional so it persists through GLB-vs-primitive regardless.

2. **`_tint_tier` called before `_body` has children**: `_ready_interactable()` adds the GLB or calls `_build_primitive()` before `_tint_tier` is ever invoked (lines 119–123 of `gather_node.gd`). Safe.

3. **Looping tween on freed node**: GDScript `Tween` bound to a scene tree node is auto-killed when the node is freed. However, `_body` is never freed — only hidden via `visible = false`. The `_pulse_tween.kill()` guard in Task 6 handles the deplete case cleanly.

4. **`still`/`forge` hint reliability (open question from [[system-gathering]])**: Code audit confirms `craft_station.gd:42` fires `first_time_hint(station_id)` on every first interaction. The risk is that a player visits the forge before ever going to the bench (skipping the bench hint) — `first_time_hint` is keyed only to the station name, so the bench and forge hints are independent. No code change needed; the open question resolves to "works as intended."

5. **Deeper inks (chalkwash, mothglow) require palechalk and mothmint** — both gated at Earthcraft 7 / Wildcraft 10. Ensure `ORE_ROLLS_BY_TIER` tier-2 weights (palechalk at 35) and `FORAGE_ROLLS_BY_TIER` tier-2 weights (mothmint at 25) are large enough to expose materials without excessive grinding. These are data values in `data/gather.gd:215–222` — no code change needed; flag for economy tuning pass in [[impl-system-economy]].

6. **Evergreen grotto affix (future)**: Dungeon nodes currently never respawn (`respawns = false`). A future `perennial_groves` good affix could flip this. No code stub needed now — note in [[system-gathering]] gap 6.
