---
title: Interactables (chest/hearth/shrine/waystone)
domain: World & Interactables
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# Interactables (chest/hearth/shrine/waystone)

> A well-factored Interactable base exists and all five types are functional; the remaining work is polish: shrine modal restyling to the WyrdUi kit, hearth GLB swap, buff variety, and interaction feedback that Plan.md Part B (B4/B5 pattern, not yet extended here) will unblock.

## Current state

The `Interactable` base (`wyrd/scripts/interactable.gd`) is a clean `Area3D` on `INTERACT_LAYER = 32` (line 19) that owns collision, the floating `[E]` prompt on a parchment plate (lines 39–72), a always-on bobbing diamond marker (lines 77–93), and virtual hooks (`interact`, `is_used`, `get_prompt_text`, `_ready_interactable`). The player's `InteractScanner` Area3D (`player_controller.gd:1221–1277`) picks it up, calls `show_prompt`, and dispatches `interact(self)` on E.

All five subclasses are wired and have audio:

- **Chest** (`chest.gd`) — rolls two `Drops.roll_drop("treasure", depth)` calls (line 46–47), spawns `ItemPickup`s, sinks the GLB via tween (line 61), plays `sfx.play("chest_open")` (line 65). Model: `dungeon_crypt_chest_v1.glb`. Open animation is a simple sink (-0.20 y, 0.35 s); no lid-open anim.
- **Hearth** (`hearth.gd`) — calls `player.heal_to_full()` + `Checkpoint.save(player, room_id)` + opens `loadout_panel.gd` as a `CanvasLayer` (lines 47–63). Multi-use. Uses the `dungeon_crypt_brazier_v1.glb` (line 9 comment: "a proper hearth GLB is still a followup").
- **Shrine** (`shrine.gd`) — 6-entry `BUFF_POOL` (lines 13–26), seeded 3-of-6 offer via `RandomNumberGenerator` (lines 86–97), opens `ShrineChoiceModal.tscn` (line 75), `apply()` writes to `player.shrine_buffs` via `apply_shrine_buff` (line 106), fades the glow to 0 (lines 111–113). One-shot.
- **PortalWaystone** (`portal_waystone.gd`) — town waystone, opens `waystone_panel.gd` to socket a chart. Cairn GLB normalized to 2.4 m.
- **ExitWaystone** (`exit_waystone.gd`) — in-dungeon exit; `abandoning = true` variant at entry prevents soft-lock (spec 45-gaps, line 9). Calls `game.return_to_town(player, abandoning)` or `net.request_end(abandoning)` for co-op. One-shot (`_used`, line 17).

All four interactable SFX keys (`chest_open`, `hearth_rest`, `shrine_bless`, `waystone`) have `.mp3` files under `wyrd/audio/` and are registered in `sfx.gd:18–38`. Test coverage: `test_typed_rooms.gd` covers T3 (chest drops), T4 (shrine buff seeding + apply), T5 (hearth heal + checkpoint), T6 (Interactable base contract for all three room interactables).

**Gaps that keep status at partial:** (1) `ShrineChoiceModal` uses raw `Panel/Button` styling, not WyrdUi kit (`shrine_choice_modal.gd:14–71` — no `WyrdUi.style_panel` call). (2) Hearth visual is a reused brazier, not a dedicated hearth model. (3) Shrine `BUFF_POOL` has only 6 entries (lines 13–26); all 6 are combat-stat buffs (hp/damage/crit/firerate/speed) — no off-stat variety (focus regen, dodge, run-speed-after-roll). (4) Chest open is a sink (no lid animation). (5) Hearth loadout panel opens via `load()` not `preload()` (`hearth.gd:59` — minor, not a bug but inconsistent with the no-`load()`-in-`_draw` convention). (6) No test covers `PortalWaystone` or `ExitWaystone` directly.

## Gaps — what needs fleshing out

1. **(Polish blocker)** `ShrineChoiceModal` styling — raw `Panel/Button`, not WyrdUi kit. Breaks visual consistency; the buff cards read as debug UI next to the Loadout panel.
2. **(Art)** Hearth uses `dungeon_crypt_brazier_v1.glb` — a brazier, not a rest/hearth model. Noted as a followup in `hearth.gd:8`.
3. **(Design)** Shrine buff pool is 6 stat-only buffs; offers feel samey across a run. Needs 3–4 more entries covering off-stat effects (focus-regen, dodge-window extension, regrowth-speed) to create meaningful choices.
4. **(Feel)** Chest open is a Y-sink tween — functional but anticlimactic. A lid-open (rotate a lid bone/child node up on interact) would read as an actual chest opening. Plan.md Part B / Phase B4 (pickup suck + slot pulse) is the natural pair for this.
5. **(Code hygiene)** `hearth.gd:59` uses `load()` not `preload()` for `loadout_panel.gd`. Low risk (it's not in `_draw()`) but inconsistent — preload to match codebase pattern.
6. **(Testing)** No headless test covers `PortalWaystone.interact()` (opens a panel) or `ExitWaystone.interact()` (calls `game.return_to_town`). The dungeon-scene test only asserts two waystones are standing (`test_wyrd_dungeon_scene.gd:62–76`), not that interact dispatches correctly.
7. **(Deferred)** Abandoning-exit waystone is implemented (`exit_waystone.gd:9–12`, `layout_loader.gd:1087–1096`) — this gap is **closed**. No work needed.

## Plan

### Phase 1 — ShrineChoiceModal restyling (kit conformance)

Restyle `shrine_choice_modal.gd` to use the WyrdUi kit: swap the raw `Panel` for `WyrdUi.style_panel(panel)`, replace raw `Button` cards with drawn `Control` cards matching the `_SkillCard` pattern in `loadout_panel.gd` (icon well + name + desc + a SAGE ring on hover, parchment plate background). Good/bad buff tinting is not needed here — all shrine buffs are blessings — so all cards are neutral/warm.

- **Concrete first step:** Copy the `_SkillCard` drawn-control pattern from `loadout_panel.gd:169–265` into a `_BuffCard` inner class in `shrine_choice_modal.gd`; replace the three `Button` nodes with `_BuffCard` instances.
- **DoD:** Opening a shrine displays three cards that use the WyrdUi parchment/ink palette, match the Loadout panel's visual weight, and are screenshot-verifiable via `WYRD_UI_SHOT`.
- **Effort: S**

### Phase 2 — Shrine buff pool expansion (design depth)

Add 4 entries to `Shrine.BUFF_POOL` (`shrine.gd:13–26`) covering off-stat effects that create meaningful trade-offs against the existing six. Candidate entries (confirm with user):

- `{"id": "channeling", "stat": "focus_regen", "value": 0.08, "name": "Channeling of the Root", "desc": "+8 Focus/s regen"}`
- `{"id": "resilience", "stat": "iframes_sec", "value": 0.12, "name": "Resilience of Bark", "desc": "+0.12s i-frames after dodge"}`
- `{"id": "wanderer", "stat": "gather_speed", "value": 0.25, "name": "Wanderer's Bounty", "desc": "+25% gather channel speed"}`
- `{"id": "clarity", "stat": "skill_cd_mult", "value": -0.15, "name": "Clarity of the Glade", "desc": "–15% skill cooldowns"}`

Stats `focus_regen`, `iframes_sec`, `gather_speed`, `skill_cd_mult` must be added to `player_controller.gd:shrine_buffs` dict (line 151) and wired into `_derive_stats` (line 1096 loop already handles any key in the dict).

- **DoD:** Pool has 10 entries; `test_typed_rooms.gd:_t4_shrine_buff` still passes; a seeded shrine with pool size 10 still returns exactly 3 unique buffs; at least one off-stat buff appears in a 5-seed sweep.
- **Effort: S**

### Phase 3 — Chest lid-open animation

Replace the Y-sink tween in `chest.gd:60–62` with a two-part animation: (1) raise a "lid" sub-node of the GLB by rotating it ~130° on local X over 0.3 s (ease-out), then (2) after a 0.25 s pause, sink the base to -0.20 y over 0.4 s. This requires the `dungeon_crypt_chest_v1.glb` to have a separable lid node — if not, a `MeshInstance3D` QuadMesh stand-in (a tapered quad) can substitute until the asset is reworked in Blender.

Pair with Plan.md Part B / Phase B4 (pickup suck + slot pulse) — the chest open and the item-suck should be sequenced so the lid raise → items scatter → items suck to player reads as one beat.

- **DoD:** Opening a chest shows a lid rotate up before the base sinks; items scatter after lid-open, not before; the existing T3 `test_typed_rooms` test (drops and pickups) stays green.
- **Effort: S–M** (depends on GLB lid node availability; if absent, M for the mesh stand-in)

### Phase 4 — Hearth GLB swap + loadout load() hygiene

1. Commission or generate a dedicated hearth GLB via the Meshy pipeline (`docs/character-pipeline/MESHY_OPERATIONS.md`). Until it arrives, the brazier is acceptable — this is art-asset-gated, so track as a parking lot item.
2. Change `hearth.gd:59` from `load("res://scripts/ui/loadout_panel.gd").new()` to `preload` at the top of the file (matches every other script in the codebase; sidesteps the remote chance this path ends up in `_draw`).

- **DoD (hygiene only, doable now):** `hearth.gd` uses `preload`; `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` stays green. GLB swap is a separate asset commit when the model is ready.
- **Effort: S** (hygiene); asset commission is a separate pipeline step.

### Phase 5 — ExitWaystone / PortalWaystone test coverage

Add two lightweight headless tests:

1. `_t7_exit_waystone_interact()` in `test_wyrd_dungeon_scene.gd` — spawn a mock `Game` node with a `return_to_town` stub, instantiate `ExitWaystone`, call `interact(mock_player)`, assert `_used` is true and the stub was called once. Test `abandoning = true` variant separately (stub called with `true`).
2. `_t8_portal_waystone_no_crash()` — instantiate `PortalWaystone`, confirm `_ready_interactable()` runs without error, `interact(null)` doesn't crash (currently the panel creation would fail on null scene — add a null guard to `portal_waystone.gd:34`).

- **DoD:** Both new tests pass in the headless suite; `test_wyrd_dungeon_scene.gd` gate stays green. `portal_waystone.interact(null)` no longer crashes.
- **Effort: S**

## Dependencies & links

- [[system-dungeon-generation]] — typed-room layout assigns roles (`treasure`/`shrine`/`rest`) that drive which interactable spawns; `_build_interactable` in `layout_loader.gd:591–618` is the wiring point.
- [[system-drops-loot]] — `Chest.interact()` calls `Drops.roll_drop("treasure", depth)` directly; rarity / depth bias lives there.
- [[system-save-load]] — `Checkpoint` autoload is written by `Hearth.interact()`; cross-session persistence (currently in-memory only) is a Save/Load concern.
- [[system-skills-hotbar]] — `Hearth` opens the Loadout panel (`loadout_panel.gd`) which is the kit-swap UI; the skill pool and unlock gates are owned by skills/hotbar.
- [[system-combat-juice-vfx]] — chest open / shrine bless / hearth rest are interaction-feedback beats; Plan.md Part B / Phase B4 (pickup suck + slot pulse) and Phase B5 (craft station react) establish the pattern these should reuse.
- [[system-status-effects]] — shrine buffs (`apply_shrine_buff`) write into `player.shrine_buffs` which flows through `_derive_stats`; any new buff stat needs a matching entry in the status/derived-stats pipeline.
- [[system-hud]] — when a shrine buff or hearth heal lands, the HUD health/focus readout must reflect the change immediately; no separate work needed (the `_derive_stats` call triggers the HUD signal chain already).
- [[system-town-hub]] — `PortalWaystone` lives in town; the Wayfinding intro and town ambient feel (Plan.md Part B / Phase B7) affect the context in which it's encountered.
- [[system-multiplayer-netcode]] — `ExitWaystone.interact()` already branches on `net.active` (line 60); co-op run-end is handled. Any new interact behavior must respect the same host-authoritative model.

**Plan.md cross-references:**
- Part A (combat feel, Phases 1–5) is **shipped** — the interactable prompt/bob/parchment-plate polish was done as part of that work.
- Part B / Phase B4 (pickup suck + slot pulse) pairs directly with chest-open feel (Phase 3 above) — sequence B4 first or together.
- Part B / Phase B5 (craft station react) establishes the `react()` hook pattern; if a future "hearth flicker on use" beat is wanted, use the same pattern.
- Part B / Phase B6 (inscribe ritual) is unrelated but defines the ceremony bar interactables should match in feel.

## Verification

- **Phase 1 (modal restyling):** `bash wyrd/tools/capture_ui.sh` with `WYRD_UI_SHOT=shrine` screenshots the choice modal; compare against Loadout panel palette. `WYRD_NO_SAVE=1` headless suites stay green (ShrineChoiceModal never runs in headless — no regression risk).
- **Phase 2 (buff pool):** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T4 asserts 3-unique-buff offer; extend T4 with a 5-seed sweep confirming off-stat buffs appear. Gate: all 4 suites green.
- **Phase 3 (chest animation):** `WYRD_NO_SAVE=1` T3 (chest drops) stays green. Visual: run the game and open a chest, or extend `tools/animation_gallery.gd` with `C` trigger for chest-open capture.
- **Phase 4 (preload hygiene):** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_typed_rooms.gd` — T5 (hearth) stays green after the preload refactor.
- **Phase 5 (waystone tests):** `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_dungeon_scene.gd` — new T7/T8 assertions pass.

All commands run as: `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://<test>.gd`

## Open questions

1. **Shrine buff pool content (Phase 2):** The four candidate off-stat buffs above need design sign-off — particularly `gather_speed` (cozy-skilling flavour vs. combat-only) and `iframes_sec` (power level). Confirm which 4 to add.
2. **Chest GLB lid node:** Does `dungeon_crypt_chest_v1.glb` have a separable lid child that can be rotated? If not, Phase 3 needs a Blender edit or a mesh stand-in — confirm before scoping Phase 3 effort.
3. **Hearth dedicated GLB:** Is a `dungeon_crypt_hearth_v1.glb` planned in the next Meshy batch? If yes, Phase 4's art slot is already in the queue and just needs a note here.
