---
title: FATE Camera Rig
domain: World & Interactables
type: system
status: complete
effort: M
tags: [wayfinder, plan]
---

# FATE Camera Rig

> The core rig is fully shipped and working; the expansion roadmap is polish — boss framing, a shake-accessibility toggle wired to Settings, and a town arrival ease-in (Plan.md Part B / Phase B7).

## Current state

`wyrd/scripts/camera_rig.gd` and `wyrd/scenes/CameraRig.tscn` together implement the FATE-style telephoto rig: 35° FOV, a standalone pivot that follows via `lerp` at `FOLLOW_SPEED 12.0`, and velocity lead capped at `MAX_LEAD 1.0` with `LEAD_FACTOR 0.14`. [Spec 61](../specs/61-responsive-locomotion-checkpoint.md) tightened those response values while deliberately preserving camera angle, zoom, and composition. Right-mouse drag and `Z`/`C` orbit the view; the wheel zooms between 8–22 m. Screen shake is a decaying jitter keyed through `HitFeedback.SHAKE_BY_TIER`, and wall occlusion fades geometry between the camera and player.

**What is missing vs. the scope brief:** there is no boss-framing mode (pull-back, wider FOV, or re-frame on boss entry); no accessibility toggle for shake (Plan.md §8 names it as wanted, but no `Settings` key or UI wires it — the toggle does not yet exist in any `.gd`); and there is no explicit arrival ease-in when returning from a delve to town (that beat belongs to Plan.md Part B / Phase B7).

## Gaps — what needs fleshing out

- **Shake accessibility toggle** — Plan.md §8 says "Reduce screen shake" toggle; no Settings key or UI hook exists yet. `HitFeedback.play_hit` calls `cr.shake()` unconditionally (hit_feedback.gd:63–65). Plan.md Part B §B-1 notes the same toggle "also damps Part B camera micro-kicks." This is the highest-value gap: accessibility and it unblocks Part B.
- **Boss framing** — no pull-back or FOV-widen on boss entry. The current fixed FOV/zoom means large bosses clip or the player loses spatial context. A `set_boss_mode(active: bool)` on the rig (tweening `_zoom_target` and pitch toward a wider view) would cover this.
- **Town arrival ease-in** — Plan.md Part B / Phase B7 calls for a "gentle camera ease-in" on dungeon→town transition. The rig snaps (`_snapped` flag line 116–118); an "arriving" state that starts `_snapped = false` and lets the follow lerp play out naturally on scene load would cover it at zero cost.
- **Shake toggle co-op propagation** — because shake is cosmetic and local (Plan.md B-1 principle), each peer reads their own setting; this is the correct design but needs to be spelled out clearly when wiring the toggle.
- **Wall occlusion: instant snap** — `_set_wall_alpha` instantly sets transparency (line 184); a short tween (0.1s) would feel less jarring on a fast orbit. Minor polish.
- **No headless test coverage** — the rig is not exercised by any of the four suites (it requires a live scene + Camera3D). A simple logic test asserting `shake()` sets `_shake_amt` and it decays to zero is missing.

## Plan

### Phase 1 — Shake accessibility toggle  *(expansion)*
Wire the existing "reduce screen shake" design intent into real code.

- Add `shake_enabled: bool = true` to `game.gd` settings dict (persisted via `save_game.gd`; default true).
- In `camera_rig.gd:shake()`: guard with `var g := get_node_or_null("/root/Game"); if g != null and not g.shake_enabled: return`.
- Add a toggle row to the Settings panel (reuse the existing `WyrdUI` toggle style).
- Part B micro-kicks (gather impact, craft clang — Plan.md B1/B5) read the same flag from `Feel.gd` or inline the same guard pattern.
- **DoD:** toggling "Reduce screen shake" in Settings makes `shake()` a no-op; super-tier hits (0.30 amplitude) produce zero camera movement when off; normal gameplay is unaffected when on; the setting round-trips through save/load. Verified by a new headless logic test (`test_wyrd_loop.gd` or a sibling) that calls `shake(0.3)` with the flag off and asserts `_shake_amt == 0.0`.
- **Effort: S.**

### Phase 2 — Boss framing mode  *(expansion)*
Give the camera a distinct "reading a big enemy" state when a boss room is entered.

- Add `func set_boss_mode(active: bool, zoom_override: float = 18.0, pitch_override: float = 32.0) -> void` to `camera_rig.gd`. When active, tween `_zoom_target` and `_pitch` toward the overrides over ~1.0s (`ZOOM_LERP` already drives the zoom lerp; add a `_pitch_target` mirroring `_zoom_target`).
- Call `set_boss_mode(true)` from `boss.gd` on `_ready` (boss scenes already in the "bosses" group — `system-bosses` owns the logic), and `set_boss_mode(false)` on boss death signal.
- Tune: zoom 18 m (vs 14 default), pitch 32° (vs 38° default) pulls back and flattens slightly so a large boss fits the frame with the player visible.
- **DoD:** entering a boss room visibly pulls the camera back within 1s; exiting (boss death) returns to ZOOM_DEFAULT/PITCH_DEFAULT within 1s; zoom-scroll still works (player can override the target further); orbit still works. Screenshot-verified (use `WYRD_SHOT=1` after the boss spawns).
- **Effort: S–M.**

### Phase 3 — Town arrival ease-in  *(see Plan.md Part B / Phase B7)*
Wire the camera's snap logic into the scene-transition beat.

- The rig already knows how to ease-in: `_snapped = false` makes `global_position` lerp from wherever it currently is toward the new player position. The only needed change: when the Town scene loads, force `_snapped = false` on the rig so the first ~0.5s of town is a smooth glide-in rather than a hard cut.
- Implement by having `town.gd` (or the transition logic) call `camera_rig.reset_snap()` — a one-line method that sets `_snapped = false`.
- **DoD:** returning from a dungeon delve, the camera visibly eases into the town player position (the ease length is determined by `FOLLOW_SPEED 12.0` and the offset distance at scene load — no new constant needed). Verified by `test_wyrd_transitions.gd` asserting the rig's `global_position` is not already at the player position on frame 1 after scene switch.
- **Effort: S.** This is the town-side contribution to Plan.md B7; do not expand further here — B7's full scope (regrowth, ambient, atlas board) lives in Plan.md.

### Phase 4 — Wall-occlusion fade tween  *(polish)*
Replace the instant alpha snap with a short tween.

- In `_set_wall_alpha`: instead of setting `GeometryInstance3D.transparency` directly, create a `Tween` (or reuse the node's `create_tween()`) that interpolates transparency over 0.1s. Cancel and restart the tween if the same wall transitions again before it finishes.
- **DoD:** orbiting the camera behind a wall shows a smooth fade-in of the transparent effect (no instant pop); orbiting away fades back smoothly. No performance regression (one tween per wall, walls are few). Verified by screenshot with `WYRD_SHOT=1` mid-orbit.
- **Effort: S.**

## Dependencies & links

- [[system-combat-juice-vfx]] — `HitFeedback.SHAKE_BY_TIER` (hit_feedback.gd:27–29) is the upstream caller of `shake()`; Phase 1's accessibility toggle must be visible to both the rig and this module.
- [[system-bosses]] — Phase 2's `set_boss_mode()` is called from boss entry/death; boss scene lifecycle is defined there.
- [[system-player-controller]] — the player `CharacterBody3D.velocity` is read each frame for lead-targeting (camera_rig.gd:109–114); the controller's movement constants (sprint speed) directly affect lead distance.
- [[system-multiplayer-netcode]] — `_acquire_player` uses `is_multiplayer_authority()` (line 68) to find the local player in co-op; the shake toggle must remain per-peer local (cosmetic local rule from Plan.md B-1).
- [[system-hud]] — the Settings panel where the shake toggle lives; Phase 1 adds a toggle row there.
- [[system-town-hub]] — Phase 3's arrival ease-in is triggered by town scene load; the town-side of the beat belongs here.
- [[system-animation]] — Plan.md Part B / Phase B1 gather micro-kick and B5 craft clang both call `shake()` with small amplitudes; Phase 1's toggle damps those too.
- Plan.md Part A §8 — "Reduce screen shake" toggle is named there as the accessibility guardrail; Phase 1 delivers it. Part B §B-1 extends it to cozy-loop micro-kicks. Part B / Phase B7 owns the full town-arrival beat; Phase 3 here is only the camera's contribution (a single `reset_snap()` call).

## Verification

- **Phase 1 (shake toggle):** headless test — add a case to `test_wyrd_loop.gd` (run with `WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd`) that instantiates the rig, sets `Game.shake_enabled = false`, calls `rig.shake(0.3)`, advances one physics frame, asserts `rig._shake_amt == 0.0`. Also a manual play-test with super-tier hits.
- **Phase 2 (boss framing):** `WYRD_SHOT=1 WYRD_DEV_BOSS=<any_den_affix> godot --path wyrd` — screenshot at boss spawn and at boss death confirms zoom and pitch values. All five headless suites stay green (the rig change is additive).
- **Phase 3 (arrival ease-in):** `test_wyrd_transitions.gd` — add an assertion that `camera_rig.global_position != player.global_position` on the first frame of town load (i.e., `_snapped` was reset). Visual confirmation by running the game through a dungeon→town cycle.
- **Phase 4 (occlusion tween):** `WYRD_SHOT=1` screenshot mid-orbit while standing next to a wall. Gate suites (`WYRD_NO_SAVE=1`) must stay green.
- All runs: `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` (and the other four suites) must pass after every phase.

## Open questions

- **Boss framing values**: zoom 18 m / pitch 32° are a first guess. User should play-test Phase 2 and tune via the TUNABLES block — should these live in `feel.gd` (Plan.md B0) or stay in `camera_rig.gd`? Lean toward `camera_rig.gd` since they are camera-only constants.
- **Shake toggle location**: the scope brief says the toggle "already exists" — but no code was found wiring it. Confirm with user whether a UI stub exists in the Settings panel already or whether Phase 1 must add the toggle row from scratch.
