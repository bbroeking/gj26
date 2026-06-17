---
title: HUD & Readouts
domain: UI & Presentation
type: system
status: partial
effort: M
tags: [wayfinder, plan]
---

# HUD & Readouts

> Core meters and feedback are functional; the biggest unshipped work is the level-up perk banner (Plan.md Phase B3), buff/debuff icons, and toast polish — all compounding on an otherwise solid foundation.

## Current state

The HUD is built entirely in code (`wyrd/scripts/player_hud.gd`), extending `CanvasLayer`, with no `.tscn` scene. The following elements are live and functional:

- **HP globe** (red `GlobeGauge`, bottom-left of skill bar at offset −220) and **Focus globe** (blue, +220) — procedurally drawn orbs with a wood-ring bezel, liquid level, danger pulse below 30%, and spec labels. (`player_hud.gd:48–55`, `GlobeGauge` class lines 391–475.)
- **Hurt vignette** — radial `GradientTexture2D` `TextureRect`, transparent center → terracotta rim, snaps to `modulate.a = 1.0` and fades in 0.25s via `hurt_vignette()`. Wired through `player_controller.gd:774`. (`player_hud.gd:335–373`.)
- **Damage flash** — flat red full-screen `ColorRect` `_flash`, 0.35s fade. (`player_hud.gd:327–331`.)
- **Death white-out** — `_whiteout` ColorRect fades in/out 0.5s each; called by `player_controller.gd:795,814`. (`player_hud.gd:377–383`.)
- **Draught chip** — small parchment label bottom-left showing hearth/deep draught count, refreshed via `materials_changed`. (`player_hud.gd:103–131`.)
- **Mute indicator** — chip bottom-right of Focus globe; connects `mute_changed` signal. (`player_hud.gd:74–100`.)
- **Wayfinding readout** (`_skills_lbl`) — bottom-right chip showing `{gold}g · Wayfinding {lv}`. Updates on `xp_gained`, `leveled_up`, `gold_changed`. No flash or animation on level-up. (`player_hud.gd:291–296`.)
- **Quest tracker** — sealed-scroll parchment panel top-center: "✦ Quest" header, objective text, progress counter, wax-seal art (`QuestScrollArt` inner class). Visibility auto-driven by `game.objective_text()`; hidden when empty. (`player_hud.gd:134–199`, `483–501`.)
- **Toast stack** — `VBoxContainer` above the skill bar; toasts are parchment-chip labels that pause-immune tween (2.4s hold + 0.6s fade). Buffered toasts from scene changes drain on `_ready`. (`player_hud.gd:201–312`.)
- **Action bar** — bottom-right: Gear (I), Satchel (M), Trades (K) kit buttons. (`player_hud.gd:249–289`.)
- **Status suffix** — active player statuses appear as a text suffix on the HP globe (e.g. `"30/30 — Burning · Rooted"`). Driven by `player_controller._status_suffix()` via `set_hp(cur, mx, status_suffix)`. (`player_hud.gd:314–318`; `player_controller.gd:1591–1601`.)

**What is absent:** there are no buff/debuff icon sprites; status is text-only in the HP label. The `_refresh_trades()` / `leveled_up` path calls `_skills_lbl.text = ...` with no burst, flash, or perk banner. Toast duration and fade are hardcoded magic numbers (2.4s + 0.6s, lines 310–311), not keyed to a `feel.gd` tunables block.

## Gaps — what needs fleshing out

1. **Level-up perk banner** (Plan.md Phase B3) — `leveled_up` signal fires but `player_hud.gd:227` only calls `_refresh_trades()`, updating a plain text chip with no burst, count-up, or named-perk reveal. The `PERKS` dict in `game.gd:415` has every perk name and level; a banner just needs to query it.
2. **Buff/debuff icon row** — statuses (burn, root, bleed, slow, HeartwoodWard, HuntersMark) are legible only as a text suffix inside the HP globe number. No icon strip; no duration indicator. `system-status-effects` owns the effect data; the HUD needs to consume it.
3. **Toast polish** — magic-number timing (2.4s / 0.6s `player_hud.gd:310–311`). No `feel.gd` key. No priority or dedup (a rapid chain of identical toasts stacks visibly). No category color-coding (level-up gold vs damage red vs info parchment).
4. **Wayfinding readout animation** — the `_skills_lbl` chip silently updates; no count-up, no color flash, no scale punch when a level is crossed.
5. **Skills readout expansion** — currently shows only Wayfinding level. Earthcraft and Wildcraft trades (when multiple trades are active) are not surfaced; no tooltip or panel link.
6. **Quest tracker gaps** — plate exists and is functional, but `objective_text()` and `objective_progress()` are the only data feeds. There is no support for multi-step quests, a pin/unpin toggle, or a dungeon-run objective (den depth, boss found). These are a `game.gd` / `system-charts-wayfinding` concern, but the HUD panel needs space reserved.

## Plan

### Phase 1 — Level-up perk banner (Plan.md B3)

The Plan.md already owns this beat (Part B / Phase B3). The HUD side is:

- In `_build_wyrd_overlay()`, register a second connection to `game.leveled_up` that calls a new `_show_levelup_banner(trade, lv)` method.
- `_show_levelup_banner`: find the unlocked perk for `(trade, lv)` in `Game.PERKS` (query via `get_tree().root.get_node("Game")`). Build a toast-style Label with the perk name in GOLD, styled with `WyrdUi.style_chip`. Scale-punch it from 0.85 → 1.05 → 1.0 (reuse the `creature_anim` back-out pattern, pure Tween), then fade out after 3.5s.
- Flash `_skills_lbl` gold for 0.4s via `add_theme_color_override("font_color", WyrdUi.GOLD)` then restore (one `Tween`).
- **DoD:** crossing any Wayfinding level fires a visible burst-chip naming the unlocked perk within one frame of the `leveled_up` signal; the chip shows the correct perk name (verifiable by a new headless logic test that signals `leveled_up("wayfinding", 2)` and asserts the banner text equals "Mara's Marginalia"); `_skills_lbl` flashes gold. Gate stays green.
- **Effort: S.** Pure code, no assets, reuses existing Tween + WyrdUi patterns.

### Phase 2 — Buff/debuff icon row

- Add a `_status_bar: HBoxContainer` anchored bottom-left of the HP globe (offset ~`(-380, -200)` from bottom-center), growing rightward.
- Wire `player_controller`'s `_tick_statuses` exit path: when a status is applied or expires, call `_hud.refresh_statuses(active_dict)` where `active_dict` is `{kind: remaining_sec}`.
- `refresh_statuses` rebuilds the row: one small `GlobeGauge`-style drawn circle per status (16px radius), filled with a status color (burn = orange, root = green, bleed = red, slow = blue, ward = teal, mark = purple), the status glyph centered, and a thin arc-drain showing remaining duration (reuse the `GlobeGauge` arc-draw pattern).
- Glyph map: `{"burn": "🔥", "root": "❋", "bleed": "✦", "slow": "❄", "ward": "❦", "mark": "◎"}` — same set as `SKILL_GLYPH` and `STATUS_WORD` in `player_controller.gd`.
- Remove the text suffix from `set_hp` (or retain it as an accessibility fallback, toggled by an `accessibility_mode` flag in `feel.gd`).
- **DoD:** all six status kinds show a colored icon when active; duration drains visibly; icons disappear within one frame of expiry; no icon leaks across a scene change (parent to the HUD node). Verified by a headless call to `apply_status("burn", 3.0, ...)` + `set_process(true)` + advance 4 frames + assert icon count == 0.
- **Effort: M.** New drawn Control subclass, one new signal path, glyph map.

### Phase 3 — Toast polish and feel.gd hookup

- Add toast constants to `data/feel.gd` (Plan.md B0 creates this file): `TOAST_HOLD_SEC = 2.4`, `TOAST_FADE_SEC = 0.6`, `TOAST_LEVELUP_HOLD_SEC = 3.5`.
- Replace the magic numbers at `player_hud.gd:310–311` with `Feel.TOAST_HOLD_SEC` / `Feel.TOAST_FADE_SEC`.
- Add toast category: `show_toast(msg, category = "info")` — `"levelup"` gets `WyrdUi.GOLD` font, `"damage"` gets `WyrdUi.TERRACOTTA`, `"info"` stays parchment.
- Add a dedup guard: if the last toast in `_toast_box` has identical text and was added within 1.0s, skip adding a new one (prevents stacking "Level up!" repeated toasts on rapid XP).
- **DoD:** `Feel.TOAST_HOLD_SEC` resolves headless; a rapid chain of 5 identical toasts produces only 1 visible chip; a level-up toast renders in gold. Gate stays green.
- **Effort: S.** Mechanical cleanup.

### Phase 4 — Wayfinding readout animation + multi-trade expansion

- On `leveled_up`, animate `_skills_lbl`: tween `modulate` to `WyrdUi.GOLD` then back over 0.5s; scale-punch to 1.08 then 1.0 (reuse Phase 1 tween).
- When multiple trades are active (Earthcraft / Wildcraft), expand `_refresh_trades()` to show all active trades (not just Wayfinding). Use a VBoxContainer replacing the single label, one chip per trade, right-anchored.
- Add a `tooltip_text` on `_skills_lbl` (or the container) pointing to "K — Trades panel for full detail."
- **DoD:** `_skills_lbl` visibly flashes on level-up; a second active trade appears as a second line in the readout. Verified by signalling `leveled_up("earthcraft", 2)` in headless and asserting the chip count is 2.
- **Effort: S.** Dependent on Phase 1 Tween pattern being established.

### Phase 5 — Quest tracker hardening (when charts/dungeon-run objectives land)

This phase is blocked by `system-charts-wayfinding` and `system-dungeon-generation` shipping a richer objective API. The HUD side pre-work:

- Reserve a third label slot in `_quest_plate` for a sub-objective (e.g. "Boss: Hedgemother — 2 rooms away").
- Add a `set_objective(text, progress, sub)` method to replace the raw signal-driven `_refresh_objective`, so callers can set sub-objective text explicitly without requiring a game-level `objective_subtext()` method.
- **DoD:** calling `set_objective("Find the Hedgemother", "0/1", "Deeper crypt — 2 rooms")` shows all three lines on the plate. No game.gd change required yet.
- **Effort: S.** Purely additive; doesn't break the existing signal-driven path.

## Dependencies & links

- [[system-status-effects]] — the status kinds, durations, and the `_statuses` dict on `player_controller` that Phase 2 must consume. Phase 2 is blocked only on agreement about the signal/callback interface.
- [[system-skills-hotbar]] — the skill bar sits between the two globes; layout constants (`ROW_BOTTOM = 114`, `SLOT_SIZE = 72`) in `skill_bar.gd` constrain the globe and icon-row placement.
- [[system-trades-progression]] — `Game.PERKS` (defined at `game.gd:415`) is the source of perk names for the Phase 1 banner. Level-up signal defined at `game.gd:28`.
- [[system-combat-juice-vfx]] — the Part A toolkit (tween patterns, scale punches, hurt flash) is the shared vocabulary Phase 1–2 extend. Do not rebuild; import the same Tween style.
- [[system-charts-wayfinding]] — quest tracker Phase 5 awaits a richer `objective_text()`/`objective_progress()` API; the chart run state is owned here.
- [[system-ui-panels]] — `WyrdUi` tokens (`TERRACOTTA`, `GOLD`, `SAGE`, `INK`), `style_chip`, `chip_stylebox`, `font_header` are used throughout the HUD. Any new drawn elements must follow the same kit grammar.
- [[system-audio-music]] — Plan.md B3 specifies a "level-up chord" layered over the existing `level_up` SFX. Phase 1's audio side (chord key in `sfx.gd`) is owned by the audio system but must be triggered from this file.

Plan.md cross-references:
- **Plan.md Part B / Phase B3** owns the level-up burst (player-side scale punch + perk banner + HUD flash + chord). This note's Phase 1 is the HUD half of B3 — do not re-plan the player body burst here.
- **Plan.md Part B / Phase B0** (`feel.gd` tunables) must land before Phase 3 (toast polish) to have a file to add constants into.
- **Plan.md Part A** (combat feel, shipped) — Phase 2 buff icons reuse the same drawn-arc / `GlobeGauge` pattern already proven in the HUD file.

## Verification

- **Phase 1:** new headless test (sibling to `test_wyrd_loop.gd`): signal `leveled_up("wayfinding", 2)` via `game`, assert banner `Label.text == "Mara's Marginalia"` after one frame. Run with `WYRD_NO_SAVE=1 godot --headless --path wyrd --script res://test_hud_levelup.gd`. Screenshot of the gold banner in-game.
- **Phase 2:** headless test: call `player.apply_status("burn", 3.0, 0)`, advance 4 frames via `await get_tree().create_timer(0.1).timeout`, assert `_status_bar.get_child_count() == 1`; advance 5 more seconds, assert count == 0. Five-suite gate green.
- **Phase 3:** headless smoke test: call `show_toast("Level up!", "levelup")` five times within one frame, assert `_toast_box.get_child_count() == 1`. `Feel.TOAST_HOLD_SEC` resolves without error.
- **Phase 4:** headless test: signal `leveled_up("earthcraft", 1)`, assert `_skills_lbl` or its VBox child count ≥ 2. All five suites green (`WYRD_NO_SAVE=1`).
- **Phase 5:** no headless test — purely additive layout. Manual visual check that three-line quest plate renders within the 82px plate height.

## Open questions

- **Buff icon glyphs vs painted icons:** Phase 2 uses Unicode glyphs (matches the `SKILL_GLYPH` approach in `skill_bar.gd`). Should the buff strip eventually get painted icons like `skill_basic.png`? No urgency, but the glyph path should be the same upgrade path as skills.
- **Status text suffix retirement:** once buff icons land (Phase 2), should the `_status_suffix()` text-in-HP-globe be removed or kept as an accessibility fallback? Recommend keeping it behind an `accessibility_mode` bool in `feel.gd`.
- **Multi-trade readout layout:** when Earthcraft and Wildcraft are active alongside Wayfinding, three chips right-anchored may crowd the bottom-right corner vs the Trades button bar above. May need a popover or a compact `{W3 / E2 / Wc1}` single-line format.
