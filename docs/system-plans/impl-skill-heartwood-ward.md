---
title: Heartwood Ward — Implementation Plan
parent: "[[skill-heartwood-ward]]"
domain: Combat Skills
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# Heartwood Ward — Implementation Plan

> Build doc for [[skill-heartwood-ward]]. Done when: `_ward_hp`/`_ward_t` are read-only properties on the player, the HUD shows a live arc counter on the Ward hotbar slot, the mesh carries a bark-brown modulate tint while the ward holds, absorb/break events play distinct SFX, the dedicated icon `skill_ward.png` is registered in both icon dicts, and four absorb-math unit tests pass headless.

## Definition of done

- `player_controller.gd` exposes `get_ward_hp() -> int` and `get_ward_frac() -> float`.
- `skill_bar.gd._process` pushes ward arc data to the correct `HotbarSlot` when the slot's skill is `HeartwoodWard`.
- `HotbarSlot` draws a bark-brown arc (fill proportional to remaining ward HP) below the cooldown wedge when `ward_frac > 0`.
- `apply_ward` in `player_controller.gd` starts a bark-brown `modulate` tint on `_mesh`; tint clears on expiry and on ward-break.
- `sfx.gd::PATHS` contains `"ward_absorb"` and `"ward_break"`; `take_damage` plays the right one.
- `skill_bar.gd::SKILL_ICON` and `loadout_panel.gd::SKILL_ICON` both have a `"HeartwoodWard"` entry pointing to `res://assets/ui/icons/skill_ward.png` (file may be a placeholder copy of `skill_basic.png` until art lands).
- `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` is green with four new absorb assertions passing.

## Preconditions / dependencies

- [[impl-system-skills-hotbar]] — `HotbarSlot` and `skill_bar.gd` are the extension points for the arc; those files must remain stable during this work.
- [[impl-system-hud]] — `player_hud.gd` is NOT directly modified here; the ward readout lives on the hotbar slot, not the HP/Focus globes.
- [[impl-system-combat-juice-vfx]] — Phase 2 bark-chip particles are blocked on the VFX scatter pattern from that system; they are a separate pass (Task 7) and not required for the first commit.
- `wyrd/audio/ward_absorb.mp3` and `wyrd/audio/ward_break.mp3` must be generated (Task 4) before the SFX calls become audible; `Sfx.play()` is a graceful no-op until the files exist, so the commit order is flexible.
- No missing files block tasks 1-3 (all target existing files).

## Tasks (ordered)

### Phase 1 — HUD arc + mesh tint (first commit)

**Task 1 — Expose ward state as read-only getters** — `player_controller.gd` near line 1374.

Add two public methods below `apply_ward`:

```gdscript
func get_ward_hp() -> int:
    return _ward_hp

func get_ward_frac() -> float:
    if _ward_hp <= 0:
        return 0.0
    return clampf(float(_ward_hp) / float(HeartwoodWard.WARD_HP), 0.0, 1.0)
```

Note: `HeartwoodWard` is already `preload`-ed at line ~1413; `HeartwoodWard.WARD_HP` is accessible as a const from that preload handle — verify with `const HeartwoodWard := preload(...)`.

_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` stays green (no regressions). _Effort:_ S.

---

**Task 2 — Add `ward_frac` property to `HotbarSlot`** — `wyrd/scripts/ui/hotbar_slot.gd`.

Add `var ward_frac: float = 0.0` alongside `cd_ratio` (line 9). In `set_state`, accept the ward value:

```gdscript
func set_state(ratio: float, can_cast: bool, p_ward_frac: float = 0.0) -> void:
    ...  # existing logic unchanged
    if not is_equal_approx(p_ward_frac, ward_frac):
        ward_frac = p_ward_frac
        queue_redraw()
```

In `_draw()` (after the cooldown wedge block, ~line 58), add the bark arc:

```gdscript
if ward_frac > 0.001:
    var c2 := size * 0.5
    var h2 := size.x * 0.5
    var arc_end := -PI * 0.5 + TAU * ward_frac
    draw_arc(c2, h2 + 5.0, -PI * 0.5, arc_end, 32,
        Color(0.45, 0.28, 0.10, 0.80), 3.5, true)
```

The +5 px radius keeps the ward arc outside the cooldown wedge so they never visually collide.

_Verify:_ `test_skills.gd` green. Manual playtest: arc visible on the Ward slot while ward is active, absent otherwise. _Effort:_ S.

---

**Task 3 — Push ward data from `skill_bar.gd._process`** — `wyrd/scripts/skill_bar.gd`, `_process` function (line 155).

Inside the `for i in _slots.size()` loop, after the existing `slot.set_state(ratio, ...)` call, detect the Ward slot and pass the fraction:

```gdscript
var wf: float = 0.0
if skill.name == "HeartwoodWard" and _player.has_method("get_ward_frac"):
    wf = float(_player.get_ward_frac())
slot.set_state(ratio, not (on_cd or no_focus), wf)
```

The default `p_ward_frac = 0.0` means all non-Ward slots are unaffected.

_Verify:_ `test_skills.gd` green. Screenshot with `WYRD_SHOT=1` showing arc draining on the Ward slot. _Effort:_ S.

---

**Task 4 — Bark-brown mesh modulate tint in `apply_ward` + clear on expiry/break** — `player_controller.gd`, `apply_ward` (line 1386) and `take_damage` / `_physics_process` ward tick (lines 447-451, 751-758).

In `apply_ward`, after the existing tween, add a modulate tween to `_mesh`:

```gdscript
if _mesh != null:
    var tw2 := create_tween()
    tw2.tween_property(_mesh, "modulate",
        Color(0.72, 0.52, 0.28, 1.0), 0.12)
```

Add a private helper to clear the tint:

```gdscript
func _clear_ward_tint() -> void:
    if _mesh != null and _ward_hp <= 0:
        var tw := create_tween()
        tw.tween_property(_mesh, "modulate", Color.WHITE, 0.20)
```

Call `_clear_ward_tint()` in two places:
- After `_ward_hp = 0` in the `_physics_process` ward-expiry branch (line 451).
- After `_ward_hp -= soak` in `take_damage` when `_ward_hp` reaches 0 (after line 753, inside the `if amount <= 0` early-return block, before `return`).

_Verify:_ `test_skills.gd` green. Playtest: mesh visibly amber-tinted while ward is active, fades back on expiry and on drain-break. _Effort:_ S.

---

### Phase 2 — Absorb-hit SFX

**Task 5 — Register `ward_absorb` and `ward_break` in `sfx.gd`** — `wyrd/scripts/sfx.gd`, `PATHS` dict (line 8).

```gdscript
"ward_absorb": "res://audio/ward_absorb.mp3",
"ward_break":  "res://audio/ward_break.mp3",
```

`Sfx.play()` is a no-op for missing files — add the entries now so call sites compile; generate the audio files separately.

_Verify:_ `test_skills.gd` green (no new errors). _Effort:_ S.

---

**Task 6 — Play absorb/break SFX from `take_damage`** — `player_controller.gd`, `take_damage` soak block (lines 751-758).

```gdscript
if _ward_hp > 0 and amount > 0:
    var soak: int = mini(_ward_hp, amount)
    _ward_hp -= soak
    amount -= soak
    var sfx_node := get_node_or_null("/root/Sfx")
    if sfx_node != null:
        if amount <= 0:
            sfx_node.play("ward_absorb")   # full soak
        else:
            sfx_node.play("ward_break")    # ward drained, damage bleeds through
            _clear_ward_tint()
    if amount <= 0:
        _iframe_t = IFRAMES_SEC
        _combat_t = COMBAT_TIMER
        return
```

Move the `_clear_ward_tint()` call from Task 4's break-path here so it's co-located with the SFX call.

_Verify:_ Playtest confirms muffled-thud SFX on a fully absorbed hit, crack SFX when ward is drained by a single large hit. No regressions on `test_skills.gd`. _Effort:_ S.

---

**Task 7 — Generate `ward_absorb.mp3` and `ward_break.mp3`** — `wyrd/tools/generate_audio.py`, `SOUNDS` dict (line 28).

Add two entries:

```python
"ward_absorb": ("Muffled hollow wooden thud, like a bark shield taking a heavy "
                "blow and absorbing it, no pain, 0.5 seconds.", 1),
"ward_break": ("Sharp woody crack and splinter burst as a bark shield shatters "
               "under impact, bright and punchy, 0.6 seconds.", 1),
```

Run: `python3 tools/generate_audio.py --only ward_absorb,ward_break` from `wyrd/`.

_Verify:_ `ward_absorb.mp3` and `ward_break.mp3` appear in `wyrd/audio/`; in-game absorb and break play distinct sounds. _Effort:_ S.

---

### Phase 3 — Icon + test coverage

**Task 8 — Register `skill_ward.png` placeholder in both icon dicts** — `wyrd/scripts/skill_bar.gd` `SKILL_ICON` (line 35) and `wyrd/scripts/ui/loadout_panel.gd` `SKILL_ICON` (line 31).

Until a painted icon lands, use the existing `skill_basic.png` as an explicitly-declared entry (removes the silent fallback):

```gdscript
# skill_bar.gd SKILL_ICON
"HeartwoodWard": "res://assets/ui/icons/skill_ward.png",
```

```gdscript
# loadout_panel.gd SKILL_ICON
"HeartwoodWard": "res://assets/ui/icons/skill_ward.png",
```

Copy `wyrd/assets/ui/icons/skill_basic.png` → `wyrd/assets/ui/icons/skill_ward.png` as a placeholder (Bash: `cp wyrd/assets/ui/icons/skill_basic.png wyrd/assets/ui/icons/skill_ward.png`). When the Midjourney/painted icon arrives, drop the file in place.

Also remove the stale `"HeartwoodWard": "res://assets/ui/icons/skill_basic.png"` line from `loadout_panel.gd` (line 39) — it is now superseded.

_Verify:_ Hotbar and loadout panel both show the icon (not the `❦` glyph fallback). `test_skills.gd` green. _Effort:_ S.

---

**Task 9 — Add four absorb unit tests to `test_skills.gd`** — `wyrd/test_skills.gd`, after the existing `_test_gates` block.

Add a `_test_ward_absorb(p: Node3D)` function called from `_run()`:

```gdscript
func _test_ward_absorb(p: Node3D) -> void:
    print("[ward absorb]")
    var HW := preload("res://scripts/skills/heartwood_ward.gd")
    HW.new().fire(p)
    _check("ward_hp set to WARD_HP after cast",
        p.get_ward_hp() == HW.WARD_HP)
    p.take_damage(8, Vector3.FORWARD)
    _check("partial soak: ward_hp decremented, vigor untouched",
        p.get_ward_hp() == HW.WARD_HP - 8 and p.hp == p.hp_max)
    # Reset
    HW.new().fire(p)
    p.take_damage(32, Vector3.FORWARD)
    _check("overflow hit: ward drained, excess damages vigor",
        p.get_ward_hp() == 0 and p.hp == p.hp_max - 2)
    # Timer expiry — simulate WARD_SEC + 0.1 s of _physics_process ticks
    HW.new().fire(p)
    var steps := int((HW.WARD_SEC + 0.1) / 0.016) + 1
    for _i in steps:
        p._physics_process(0.016)
    _check("ward_hp zeroed on timer expiry",
        p.get_ward_hp() == 0)
```

Note: `_physics_process` is not `@export` but is accessible in script mode; the test calls it directly as the headless harness pattern allows. The `p.hp_max` reset between sub-cases may require `p.hp = p.hp_max` — add it after the overflow sub-case.

_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_skills.gd` shows four new ✓ lines under `[ward absorb]`. _Effort:_ S.

---

### Phase 4 — Balance tuning (post-playtest, deferred)

**Task 10 — Promote balance constants to `feel.gd` when it exists** — `wyrd/scripts/skills/heartwood_ward.gd` lines 8-9.

Currently `WARD_HP = 30` and `WARD_SEC = 8.0` are compile-time constants in `heartwood_ward.gd`. Once Part B B0 creates `feel.gd`, move them:

```gdscript
# heartwood_ward.gd — replace consts with feel.gd reads
const WARD_HP: int   = 30   # tuning target: 2-3 hits at den depth ~2 (lv 7)
const WARD_SEC: float = 8.0  # lower = more urgency (5.0s); higher = comfort (10.0s)
```

Blocked on [[impl-system-combat-juice-vfx]] B0 `feel.gd` landing. Until then, comment the tuning target inline.

_Verify:_ After three playtest sessions, ward present in <100% of loadouts at lv 7+ confirms the HP/CD ratio is competitive. _Effort:_ S (tuning only).

---

## First commit (smallest shippable slice)

**Tasks 1 + 2 + 3 + 4** in one commit: getter methods in `player_controller.gd`, `ward_frac` property + arc drawing in `hotbar_slot.gd`, arc push in `skill_bar.gd._process`, bark-brown modulate tint in `apply_ward`/`_clear_ward_tint`.

Acceptance: `test_skills.gd` green, arc is visible on the Ward slot during an active ward, mesh is amber-tinted while ward holds and fades on expiry/drain. No new scene files or autoloads.

## Test & verification plan

| Suite | When | Covers |
|---|---|---|
| `test_skills.gd` | After every task | Regression on dispatch + gates + (Task 9) four absorb cases |
| `test_wyrd_loop.gd` | After Tasks 1-4 | No regressions in the game loop from controller changes |
| `test_wyrd_dungeon_scene.gd` | After Tasks 1-4 | Dungeon scene boots without errors |
| Screenshot `WYRD_SHOT=1` | After Task 3 | Arc visible on Ward slot in the bottom-center cluster |
| Playtest | After Tasks 5-7 | Absorb SFX audible; break SFX distinct; no phantom ward tint after expiry |
| Playtest balance log | Task 10 | Ward soaks at least once per crypt run; not in 100% of loadouts |

New test to author: `_test_ward_absorb` in `test_skills.gd` (Task 9) — four cases as specified above.

## Risks & open questions

1. **`HeartwoodWard.WARD_HP` from preload** — `skill_bar.gd` and `test_skills.gd` both use `preload` for `HeartwoodWard`; accessing `HeartwoodWard.WARD_HP` in `get_ward_frac()` requires the preload handle at `player_controller.gd:~1413`. Confirm the const is reachable as `preload("res://scripts/skills/heartwood_ward.gd").WARD_HP` in GDScript (it should be, but verify before shipping Task 1). If not, store `WARD_HP` as a `var` in `player_controller.gd` set at cast time.
2. **`_physics_process` direct call in test** — The headless harness calls `_physics_process` directly on the player node in `test_wyrd_loop.gd`; confirm `player_controller._physics_process(delta)` is accessible in the test suite's scope (it is, GDScript methods are public by default unless prefixed with `__`). If the method is inlined via `_internal_*`, expose a `sim_tick(delta)` shim instead.
3. **Mesh modulate tint vs ink outline** — `_add_ink_outline` sets `material_override` on `MeshInstance3D` children. Setting `_mesh.modulate` (a `Node3D` property) affects the entire subtree's rendering. Verify the modulate tint propagates correctly through the Blender GLB hierarchy by doing a quick in-editor check; if it washes out the ink outline, switch to a `modulate` tween on `_mesh` itself vs. each `MeshInstance3D` child.
4. **Self-only vs ally-cast** — Phase 5 co-op design question (from [[skill-heartwood-ward]] Open questions §1) is deferred; no decision needed before Tasks 1-9.
5. **Icon art** — `skill_ward.png` placeholder is a copy of `skill_basic.png`. Commission the painted icon (Midjourney: `bark-wood shield crest, bold ink outline, flat cel-shaded, Bramblewood cozy style --ar 1:1`) before the next playtesting milestone so the slot reads clearly.
