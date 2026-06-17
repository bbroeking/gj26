---
title: NPCs, Story & Tutorial — Implementation Plan
parent: "[[system-npc-story-tutorial]]"
domain: World & Interactables
type: implementation-plan
status: ready-to-build
effort: M
tags: [wayfinder, impl]
---

# NPCs, Story & Tutorial — Implementation Plan

> Build doc for [[system-npc-story-tutorial]]. All four NPC/tutorial gaps are closed: shrine/status/affix hints fire on first contact, Quill reacts to tonic use and level gates, Hod greets before opening the panel, and the Summit arc ends with a voiced payoff from all three NPCs; portrait plumbing is wired but gated on art delivery.

## Definition of done

- Shrine hint fires exactly once on first shrine encounter (before the choice modal).
- Bleed and slow status hints fire exactly once each on first application to the player.
- Affix-reading hint fires exactly once when `tutorial_step` crosses 6.
- Quill delivers three mutually exclusive reactive states: pre-tonic, post-first-quaff, and the Clearwater Philter gate; the `still` first-time hint already works (no code change needed).
- Hod shows a one-page greeting on first interact, then opens the vendor panel; repeat visits skip to panel; `summit_cleared` triggers a one-off congratulation.
- After `summit_cleared`, each NPC delivers a unique one-time reaction (Mara 4–6 pages, Quill 1 page, Hod 1 page) on the first post-summit talk; subsequent visits fall through to normal post-tutorial dialog.
- `PortraitWell` accepts an optional `portrait_texture: Texture2D`; silhouette fallback stays until art ships.
- All four headless suites stay green. Playtest sign-off on Phase 4 summit lines before merge.

## Preconditions / dependencies

- [[impl-system-interactables]] — `Shrine`, `WayfinderNpc`, `QuillNpc`, and `VendorNpc` all `extend Interactable`; that base must be stable before touching interact hooks.
- [[impl-system-status-effects]] — `player_controller.gd:apply_status` (line 1521) is the injection point for status hints; the player-side status framework (spec 33a) must be merged first.
- [[impl-system-charts-wayfinding]] — the affix-reading hint fires from `game.gd:add_chart` at the step-6 branch (line 655); chart logic must be stable.
- [[impl-system-save-load]] — `seen_hints` is serialized by `save_game.gd:24,87`; any new hint keys are automatically persisted without schema changes.
- [[impl-system-ui-panels]] — `dialog_panel.gd` is the delivery vehicle; the `PortraitWell` inner class (line 137) is the portrait insertion point.
- Phase 5 (portraits) is additionally **blocked on art delivery** — painted PNGs for Mara, Quill, and Hod must exist before the texture swap can be tested.
- Plan.md Part B / Phase B6 (inscribing-table ritual) and B7 (town arrival beat) compose with Phases 1 and 4 respectively; either order is safe, they touch different files.

## Tasks (ordered)

### Phase 1 — In-dungeon first-contact hints

**1. Add `"shrine"` key to `SKILL_HINTS` in `game.gd`.**
File: `wyrd/scripts/game.gd` — insert after the `"still"` entry at line 163.
```gdscript
"shrine": ["Mara Linnet, the Wayfinder", [
    "One-shot — choose and the altar goes dark. There's no cancelling a prayer.",
    "Each colour is a different boon: the gold ones sharpen attack, the blue ones thicken your hide. Pick the one that fits the hollow ahead.",
]],
```
_Verify:_ `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` — confirm no crash. Manual: fresh save, enter crypt, approach shrine, hint fires before modal. _Effort:_ S.

**2. Call `game.first_time_hint("shrine")` from `Shrine.interact()` before opening the modal.**
File: `wyrd/scripts/shrine.gd:71–79` — at the top of `interact()`, after the `_consumed` guard.
```gdscript
func interact(player: Node) -> void:
    if _consumed:
        return
    var game := get_tree().root.get_node_or_null("Game")
    if game != null:
        game.first_time_hint("shrine")
    # ... existing modal code ...
```
_Verify:_ same as task 1; manual: hint shows before the choice modal on first shrine. _Effort:_ S.

**3. Add `"status_bleed"` and `"status_slow"` keys to `SKILL_HINTS` in `game.gd`.**
File: `wyrd/scripts/game.gd` — insert after `"shrine"` entry added in task 1.
```gdscript
"status_bleed": ["Mara Linnet, the Wayfinder", [
    "That thorn essence in your blood — it'll drain you one tick at a time until it clears. Roll through a gap; bleed can't keep up with a moving target.",
]],
"status_slow": ["Mara Linnet, the Wayfinder", [
    "Something's fouling your stride. The icon fades on its own — keep moving and let the hollow clear it.",
]],
```
_Verify:_ suites green. Manual: take a bleed hit, hint fires once. _Effort:_ S.

**4. Fire status hints from `player_controller.gd:apply_status()` on first application.**
File: `wyrd/scripts/player_controller.gd:1521` — at the end of the "new status" branch (after `_statuses[kind] = s`, before the final `return s`).
```gdscript
var _hint_key: String = "status_" + kind
var _game := get_tree().root.get_node_or_null("Game")
if _game != null and _game.has_method("first_time_hint"):
    _game.first_time_hint(_hint_key)
```
Only `"status_bleed"` and `"status_slow"` are in `SKILL_HINTS`; other kinds (burn, root, snared) silently no-op through the `not SKILL_HINTS.has(kind)` guard in `first_time_hint`. No new gate variable needed.
_Verify:_ `test_wyrd_dungeon_scene.gd` — enemies apply bleed on crit; confirm suite stays green, no crash. Manual: enter crypt, take a bleed hit from an enemy, status hint fires exactly once. _Effort:_ S.

**5. Add `"affix_reading"` key to `SKILL_HINTS` in `game.gd`.**
File: `wyrd/scripts/game.gd` — insert after `"status_slow"` entry.
```gdscript
"affix_reading": ["Mara Linnet, the Wayfinder", [
    "Those coloured tabs — gold twin leans lucky, red twin leans hard. The ink quantity in the round socket slides the odds. More ink: the result drifts toward its label.",
    "You can't control which twin lands, only how far each can lean. That's the whole craft.",
]],
```
_Verify:_ suites green. Manual: complete step 6 inscribe, affix hint fires immediately after. _Effort:_ S.

**6. Call `game.first_time_hint("affix_reading")` from `game.gd:add_chart()` at the step-6 branch.**
File: `wyrd/scripts/game.gd:655` — after `advance_tutorial()` in the `elif tutorial_step == 6` branch.
```gdscript
elif tutorial_step == 6 and String(chart.get("template_id", "")) != "snug":
    advance_tutorial()
    first_time_hint("affix_reading")
```
`first_time_hint` is a method on `Game` itself, called without a node lookup.
_Verify:_ `test_wyrd_loop.gd` — loop inscribes a Tier 1 chart; confirm suite stays green. Manual: step 6 completes, affix hint fires once per save. _Effort:_ S.

---

### Phase 2 — Quill reactive dialog

**7. Extend `QuillNpc.interact()` to branch on `seen_hints` and `trade_lv`.**
File: `wyrd/scripts/quill_npc.gd:29–36` — replace the static `dlg.open()` call with a branching helper. The `still` first-time hint already fires via `craft_station.gd:42` — no change needed there.
```gdscript
func interact(_player: Node) -> void:
    var game := get_tree().root.get_node_or_null("Game")
    var pages: Array = _quill_pages(game)
    var dlg: CanvasLayer = DialogPanelScript.new()
    dlg.open("Quill, the Herbalist", pages)
    get_tree().current_scene.add_child(dlg)

func _quill_pages(game: Node) -> Array:
    if game == null:
        return _quill_static()
    # Deepest-gate first so only one branch fires.
    if bool(game.get("summit_cleared")) \
            and not bool(game.seen_hints.get("summit_quill", false)):
        return []   # Phase 4 handles this branch — see task 13
    if int(game.trade_lv("wayfinding")) >= 6 \
            and game.material_count("clearwater_philter") > 0:
        return [
            "The Clearwater Philter — double duration, and it doesn't sit heavy on the stomach. The still takes twice the makings, but the hollow's a kinder place when it clears your eye.",
        ]
    if bool(game.seen_hints.get("tonic_quaffed", false)):
        return [
            "Tastes like the yard in late summer, doesn't it. That's the mint — I dry it on the south wall.",
            "Keeps a week if you don't shake it too hard. The effect fades before the bottle does.",
        ]
    return _quill_static()

func _quill_static() -> Array:
    return [
        "Mind the beds — the yellow-tipped ones are nearly ready.",
        "The hearth feeds you; my still sharpens you. Bring wild herbs and I'll show you what a proper tonic does.",
        "They keep a week if you don't shake them too hard.",
    ]
```
_Verify:_ `test_wyrd_loop.gd` — loop visits Quill; suite stays green. Manual: fresh save, brew+quaff tonic, talk to Quill — reactive branch shows. _Effort:_ S.

**8. Set `seen_hints["tonic_quaffed"]` in `game.gd:quaff_buff_draught()` on success.**
File: `wyrd/scripts/game.gd:526–536` — after `notify(def.toast)` and before `save_now()`.
```gdscript
seen_hints["tonic_quaffed"] = true
```
_Verify:_ `test_wyrd_loop.gd` — quaff a tonic via the hotbar path; confirm flag is set and saved. _Effort:_ S.

---

### Phase 3 — Hod greeting + voice

**9. Add `"hod_intro"` and `"hod_summit"` dialog keys and refactor `VendorNpc.interact()`.**
File: `wyrd/scripts/vendor_npc.gd:28–30` — replace direct panel open with dialog-first pattern.
Add `DialogPanelScript` preload constant at top of file alongside `VendorPanelScript`.
```gdscript
const DialogPanelScript = preload("res://scripts/ui/dialog_panel.gd")

func interact(_player: Node) -> void:
    var game := get_tree().root.get_node_or_null("Game")
    var dlg_pages: Array = _hod_greeting(game)
    if dlg_pages.is_empty():
        _open_vendor_panel()
        return
    var dlg: CanvasLayer = DialogPanelScript.new()
    dlg.open("Old Hod Tenter", dlg_pages)
    get_tree().current_scene.add_child(dlg)
    dlg.finished.connect(_open_vendor_panel)

func _hod_greeting(game: Node) -> Array:
    if game == null:
        return []
    if bool(game.get("summit_cleared")) \
            and not bool(game.seen_hints.get("hod_summit", false)):
        game.seen_hints["hod_summit"] = true
        return ["Heard the waystone ring different when you came back. That's the Summit bell. Buy yourself something useful — you earned it."]
    if not bool(game.seen_hints.get("hod_intro", false)):
        game.seen_hints["hod_intro"] = true
        return [
            "Bring me ore or coin — I'll make either work.",
            "Left side buys; right side sells. Gear you're done with melts back down for fair metal.",
        ]
    return []   # subsequent visits skip straight to panel

func _open_vendor_panel() -> void:
    var panel: CanvasLayer = VendorPanelScript.new()
    get_tree().current_scene.add_child(panel)
```
_Verify:_ `test_wyrd_loop.gd` — loop visits Hod; confirm no crash. Manual: fresh save, first Hod interact shows greeting then panel; second interact goes direct to panel. _Effort:_ S.

---

### Phase 4 — Summit narrative payoff

**10. Extend `WayfinderNpc.interact()` to distinguish first-post-summit from subsequent visits.**
File: `wyrd/scripts/wayfinder_npc.gd:31–36` — the current `summit_cleared` branch (lines 31–36) always fires. Replace it with a gated first-visit branch and a short repeat branch.
```gdscript
if game != null and bool(game.get("summit_cleared")):
    if not bool(game.seen_hints.get("summit_mara", false)):
        game.seen_hints["summit_mara"] = true
        pages = _pages_summit_first()
    else:
        pages = _pages_summit_repeat()
else:
    pages = _pages_for(step)
```
_Verify:_ `test_wyrd_loop.gd` — loop completes a summit chart; confirm no crash. Manual: clear Summit, talk to Mara — extended arc fires; talk again — short repeat. _Effort:_ S.

**11. Author `_pages_summit_first()` and `_pages_summit_repeat()` in `wayfinder_npc.gd`.**
File: `wyrd/scripts/wayfinder_npc.gd` — add two new helper functions after `_pages_for()`.
```gdscript
func _pages_summit_first() -> Array:
    return [
        "You're back. I've been watching the waystone since the Roost chart left your case.",
        "Say it out loud — the Summit. Most wayfinders spend a season just convincing themselves the chart is real.",
        "The Hedgemother. The Boar. The Wolf. The Queen's own nest. You inked every hollow on that chain and walked each one back.",
        "There are deeper hollows — the old charts hint at them. We don't have names for what keeps them yet. But the ink is yours. When you're ready, we start drawing again.",
        "Tonight: rest. The yard isn't going anywhere.",
    ]

func _pages_summit_repeat() -> Array:
    return [
        "The hollows keep moving. When you're ready, we draw the next chart.",
    ]
```
_Verify:_ playtest sign-off required — user reads summit lines and approves tone before merge. Headless suites stay green (no logic change). _Effort:_ S.

**12. Add Quill post-summit page to `_quill_pages()` in `quill_npc.gd`.**
File: `wyrd/scripts/quill_npc.gd` — in `_quill_pages()`, the summit branch (task 7 stub) returns `[]` guarded by `summit_quill`. Replace the stub with real content and set the flag.
```gdscript
if bool(game.get("summit_cleared")) \
        and not bool(game.seen_hints.get("summit_quill", false)):
    game.seen_hints["summit_quill"] = true
    return ["The roots go deeper than the maps say. I saw the elder herbs once — far past the Roost. One day someone's going to bring me a cutting and I'll know we've found the bottom of it."]
```
_Verify:_ suites green. Manual: post-summit, talk to Quill — her reaction fires once. _Effort:_ S.

**13. Hod post-summit reaction is already handled by task 9** (`_hod_greeting` checks `summit_cleared` before `hod_intro`). No additional task needed — the ordering ensures the summit line fires once, then the normal intro logic takes over on subsequent visits.
_Verify:_ already covered by task 9 verify. _Effort:_ 0.

---

### Phase 5 — Portrait plumbing (art-gated)

**14. Extend `PortraitWell` in `dialog_panel.gd` to accept a `portrait_texture`.**
File: `wyrd/scripts/ui/dialog_panel.gd:137–145` — extend `PortraitWell` with a `portrait_texture: Texture2D` property and a conditional draw path. The silhouette remains the fallback.
```gdscript
class PortraitWell extends Control:
    var portrait_texture: Texture2D = null   # set by the NPC; null = silhouette

    func _draw() -> void:
        var c := size * 0.5
        var r := minf(c.x, c.y)
        if portrait_texture != null:
            draw_texture_rect(portrait_texture,
                Rect2(c - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false)
            draw_arc(c, r, 0, TAU, 48, Color(0.26, 0.19, 0.13), 2.5, true)
            return
        # existing silhouette code unchanged below ...
```
_Verify:_ `wyrd/tools/check_ninepatch.py` (portraits are drawn, not nine-patches — no-op regression check). Suites green. _Effort:_ S. **Blocked on art delivery.**

**15. Expose portrait texture on `DialogPanel.open()` and wire NPC calls.**
File: `wyrd/scripts/ui/dialog_panel.gd` — add an optional `portrait: Texture2D = null` parameter to `open()` and pass it to the `PortraitWell`. Update `wayfinder_npc.gd`, `quill_npc.gd`, and `vendor_npc.gd` to preload their portrait PNGs in `_ready_interactable()` and pass them into `open()`.  
Rule: preload in `_ready_interactable()`, never inside `_draw()` (see `feedback_godot_draw_load_white_texture`).
_Verify:_ Manual screenshot — each NPC's dialog panel shows their painted portrait. `check_ninepatch.py` no-op. _Effort:_ S. **Blocked on art delivery.**

---

## First commit (smallest shippable slice)

**Tasks 1–6 (Phase 1):** Add the three new `SKILL_HINTS` entries (`shrine`, `status_bleed`, `status_slow`, `affix_reading`) and their call sites in `shrine.gd`, `player_controller.gd`, and `game.gd:add_chart`. This is entirely additive, zero risk to existing paths, and closes both player-confusion BLOCKERs from the parent note. All four suites must stay green.

Acceptance: fresh save → enter crypt → approach shrine → Mara hint fires before choice modal; take bleed → hint fires once; complete step 6 → affix hint fires once.

## Test & verification plan

| Phase | Suite(s) | Manual check |
|-------|----------|--------------|
| 1 — shrine + status + affix hints | `test_wyrd_dungeon_scene.gd`, all four suites | Fresh save: shrine hint before modal; bleed hit: status hint once; step 6: affix hint once |
| 2 — Quill reactive | `test_wyrd_loop.gd`, all four suites | Fresh save: brew+quaff tonic, talk Quill → reactive branch; WF lv 6 → Clearwater gate |
| 3 — Hod greeting | `test_wyrd_loop.gd`, all four suites | First Hod: greeting → panel; second Hod: panel direct; post-summit Hod: one-line congrats |
| 4 — Summit payoff | All four suites | **Playtest sign-off required**: user reads Mara/Quill summit lines; second visit each NPC → normal loop |
| 5 — Portraits | `check_ninepatch.py`; all four suites | Screenshot of dialog with painted portrait; silhouette fallback when texture is null |

No new headless test scripts are needed — the existing four suites exercise all affected code paths (loop = crafting/quaff/town; dungeon_scene = shrine/status; transitions = scene changes; skills = hotbar). If Phase 1 status hints cause unexpected crashes in the headless bleed path, a narrow `test_status_hints.gd` isolating `apply_status → first_time_hint` via a mock game node can be added then.

## Risks & open questions

1. **Shrine hint timing vs. choice modal.** Current plan: `first_time_hint("shrine")` fires before the `ShrineChoiceModal` is instantiated. If the dialog panel and choice modal both try to call `Game.modal_opened()` in the same frame, the modal counter could double. Mitigate: `dialog_panel.gd:_ready` calls `modal_opened()`; verify the counter is symmetric with `modal_closed()` at `_finish()`. If there is a double-open, chain: connect `dialog.finished` to a lambda that instantiates the shrine modal, rather than firing both at once. **Decision needed only if the counter misbehaves in playtest.**

2. **Quill branch ordering.** The `summit_cleared` check runs before the `tonic_quaffed` check in `_quill_pages()`. A player who clears the Summit before ever quaffing a tonic will see the summit reaction first, then the static lines — never the tonic reaction. This is probably correct (summit supersedes) but the user should confirm.

3. **Phase 4 tone approval required.** The summit lines in tasks 11 and 12 carry narrative weight and must match `docs/WORLD_BIBLE.md` voice. Do not merge Phase 4 without the user reading the draft lines in playtest. The headless suites cannot assert tone.

4. **`"still"` hint already works.** `craft_station.gd:42` already calls `game.first_time_hint(station_id)` where `station_id == "still"`, and `"still"` is already in `SKILL_HINTS` at `game.gd:160`. No work needed — noted here to avoid re-implementing it.

5. **Hod intro on every fresh install vs. once per save.** Current plan: `seen_hints["hod_intro"]` is set per-save, so it fires on first Hod visit per save file and never again. If the user wants it to greet every fresh game session (i.e. not persist), the flag must be excluded from `save_game.gd:24` serialization. **User decision pending.**

6. **Phase 5 portrait delivery.** Until painted PNGs exist, tasks 14–15 can be merged speculatively (the silhouette fallback is unchanged). Art assets are the only blocker.

---

## Build status — 2026-06-16

**Scope:** `wyrd/scripts/wayfinder_npc.gd` and `wyrd/scripts/ui/dialog_panel.gd` only.

### Completed

**Phase 4 (Tasks 10–11) — Summit narrative payoff (Mara):**
- `interact()` refactored: `summit_cleared` branch now gates on `seen_hints["summit_mara"]`. First post-summit visit sets the flag and serves `_pages_summit_first()` (5 pages). All subsequent visits serve `_pages_summit_repeat()` (1 page). Previously the summit branch always fired the same 3 lines with no flag.
- `_pages_summit_first()` added — 5-page arc: watching the waystone, naming the chain (Hedgemother → Boar → Wolf → Queen), looking ahead to unnamed deeper hollows, rest tonight.
- `_pages_summit_repeat()` added — 1-page short return: "The hollows keep moving. When you're ready, we draw the next chart."

**Dialogue depth — step-appropriate richer copy:**
- Step 0: unchanged first-page hook; herb-gather page reworded for warmth ("shimmer about them").
- Step 1: expanded from 1 page to 2 — adds "Crouch into them — the plants won't bite."
- Step 2: expanded from 1 page to 2 — adds flavour note about what the ink smells like.
- Step 3: expanded from 1 page to 3 — separates "you have ink" from Snug explanation, adds "Don't crease it."
- Step 4: expanded from 2 pages to 3 — separates Waystone action from combat controls.
- Step 5: expanded from 1 page to 2 — adds reassurance ("I'll still be here when you get back").
- Step 6: expanded from 2 pages to 4 — acknowledges crossing back, separates Tier-1 instruction from affix dance explanation.
- Step 7: new explicit arm (previously fell through to `_`) — 3 pages reading affixes.
- Default (`_`): expanded from 3 pages to 4 — names the trophy chain more precisely (Hedgemother → Wallow → Roost → Summit).

**Phase 5 (Task 14) — Portrait plumbing (art-gated):**
- `PortraitWell` gains `var portrait_texture: Texture2D = null`. `_draw()` now branches: if texture is set, renders it via `draw_texture_rect` then overlays ink rings; otherwise falls through to the existing silhouette. Silhouette is the live path until art ships.
- `_well: PortraitWell` member added to outer class, assigned in `_ready()` (replaces local `well`).
- `open()` gains optional third param `portrait: Texture2D = null`. Existing two-arg callers are unaffected. When a portrait texture is passed, `open()` writes it to `_well.portrait_texture`.

### Deferred (needs out-of-scope files)

- **Phase 1 (Tasks 1–6):** shrine, status_bleed, status_slow, affix_reading SKILL_HINTS entries — require `game.gd`. Call sites in `shrine.gd`, `player_controller.gd`, and `game.gd:add_chart` are also out of scope.
- **Phase 2 (Tasks 7–8):** Quill reactive dialog — requires `quill_npc.gd` (just changed, forbidden) and `game.gd:quaff_buff_draught`.
- **Phase 3 (Tasks 9, 13):** Hod greeting — requires `vendor_npc.gd` and `game.gd`.
- **Phase 4 (Tasks 12):** Quill post-summit page — requires `quill_npc.gd`.
- **Phase 5 (Task 15):** NPC portrait wire-up (preload in `_ready_interactable`, pass to `open()`) — requires each NPC file and art delivery. The plumbing in `dialog_panel.gd` is ready; callers just need to pass a preloaded texture.

### Parse-clean notes

- `var _well: PortraitWell` type-hint on outer class member referencing inner class is valid GDScript 4 (inner classes are visible within the same file without `class_name`).
- `open(..., portrait: Texture2D = null)` — `null` default for an object type is valid in GDScript 4.
- All `Array` returns are explicit literal arrays — no "inferred from Variant" traps.
- No `load()` calls in `_draw()` — portrait texture must be pre-assigned before `queue_redraw()` fires.
