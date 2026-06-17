---
title: Player Controller & Movement
domain: Player & Abilities
type: system
status: complete
effort: M
tags: [wayfinder, plan]
---

# Player Controller & Movement

> The Ranger's locomotion + combat-state machine is fully implemented and tuned; the work left is movement-*feel* polish and wiring the few remaining co-op authority seams — not building anything new.

## Current state
`wyrd/scripts/player_controller.gd` (`extends CharacterBody3D`) is a complete, shipped controller. Camera-relative input drives a `Move` state machine (`NORMAL / DASH / ROLL`, `player_controller.gd:88`). Locomotion is always-run with Shift-to-walk: `RUN_SPEED 4.0`, `WALK_SPEED 2.0`, split accel/decel curves (`ACCEL 12`, `DECEL 20`, `TURN_DECEL 28` — Spec 36 Batch B, lines 35–45) so starts feel weighted but reversals snap. Dash is a no-i-frame reposition burst (`DASH_SPEED 11`, `DASH_TIME 0.18`, `DASH_COOLDOWN 0.7`, lines 54–57); the dodge-**roll** carries the i-frame window (`ROLL_SPEED 6.5`, `ROLL_TIME 0.45`, `ROLL_IFRAMES 0.27` ≈ 60% with a punishable recovery tail, `ROLL_COOLDOWN 0.85`, lines 59–63). Survival: `PLAYER_HP 30`, `IFRAMES_SEC 0.6`, `HIT_KNOCKBACK 4.5`, plus the shipped Plan.md Part-A "getting hit" feel block — `STUN_SEC 0.10` micro-stun, `FLINCH_SEC 0.16` mesh squash, `BLINK_PERIOD 0.12` i-frame tell (lines 73–81). Two body paths: the chibi Meshy rig (`CHIBI_BODY_PATH`, line 21) replaces the `Player.tscn` ranger mesh when present, with the ranger as a never-fail fallback. The bow rides the RightHand bone socket each frame (`_bow_socket`, lines 96–101); the Phase-4 `BowDrawModifier` layers the draw pose over locomotion (lines 10, 67, 93–94). Foot-slide is fixed by per-frame anim `speed_scale` against ground speed (`WALK_REF_SPEED 4.7`, lines 47–52). Skills dispatch through `_try_skill(slot)`; gather swing, level-up reaction, and ink-outline are wired here too.

## Gaps — what needs fleshing out
- **Movement still reads slightly robotic at constant velocity** — the linear-feel that Plan.md flags as needing Blender clip-easing (parked); a player movement-lean is an un-shipped Phase-5 item.
- **Gather pose is a whole-mesh swing**, not arm-articulated — the clearest cozy-feel win (owned by Plan.md Part B / Phase B1, not re-planned here).
- **Co-op authority seams**: a few `get_first_node_in_group("player")` style lookups can resolve to the wrong peer's body (flagged in [[system-multiplayer-netcode]]); local-vs-remote ownership of stun/i-frames/flinch is correct but the residual wrong-player bugs touch this file.
- **No movement accessibility options** (hold-to-run vs toggle, dash/roll on same or separate inputs) — controls are numeric/hardcoded per ADR 0004.
- **Death/respawn flow** lives here but cross-session checkpoints don't (see [[system-save-load]]); the down/revive co-op question is unscoped.

## Plan
### Phase 1 — Movement-feel polish (Plan.md Part-A leftovers)
- Add the un-shipped Phase-5 **player movement-lean** (tilt the mesh into travel, lerp back at rest — clone the enemy `creature_anim` lean) and an overshoot-settle on stop.
- Land-squash on the locomotion bob valley if the chibi clip exposes a vertical phase.
- **DoD:** at constant run speed the body visibly leans into travel and straightens within ~0.2s of stopping; verified by a feel-bench screenshot (see [[system-animation]]); 5-suite gate green.
- **Effort:** S.

### Phase 2 — Co-op authority hardening
- Audit every cross-peer node lookup in this file; replace group-first lookups with the authoritative-local resolution used by [[system-camera]]; confirm stun/i-frame/flinch stay strictly local while damage forwards via `take_damage`.
- **DoD:** in a 2-peer session each player's hit-state, roll i-frames, and bow draw animate only on the owner; no wrong-player binding. Verified by the netcode checklist in [[system-multiplayer-netcode]].
- **Effort:** M.

### Phase 3 — Movement options & accessibility (optional)
- Run/walk toggle vs hold; expose dash/roll cooldown + i-frame window through a tuning block (mirror the Plan.md "one feel block" pattern) so playtests are one-file-fast.
- **DoD:** a single constants block governs all movement timings; a toggle changes walk/run binding without code edits elsewhere.
- **Effort:** S–M.

### Phase 4 — Parked: Blender clip-easing
- Re-curve walk/run/idle fcurves to Bézier + retime + re-export the chibi GLBs. No code dependency; runs whenever Blender + the MCP add-on are open. Interim feel comes from Phase 1's lean + the per-frame speed-scale.
- **DoD:** clips no longer read linear at off-calibration speeds. **Effort:** M (asset, parked).

## Dependencies & links
- [[system-skills-hotbar]] — the hotbar dispatch (`_try_skill`) and Focus spend live in this controller; movement state gates casting.
- [[system-status-effects]] — snared/root modify movement speed here; stun/flinch are this file's hit-state.
- [[system-combat-juice-vfx]] — the shipped Part-A hit-feedback (flash/knockback/stun/flinch) is driven from `take_damage`; see Plan.md Part A.
- [[system-animation]] — clip selection, foot-slide fix, bow-draw modifier, and the parked clip-easing all bind to this controller's mesh/skeleton.
- [[system-camera]] — the FATE rig follows the local-authority player; the same authority check this file needs.
- [[system-multiplayer-netcode]] — local vs remote ownership of body state; the residual wrong-player lookups.
- [[system-interactables]] / [[system-gathering]] — `begin_gather`/`end_gather` and interaction input gating route through the controller.
- Plan.md **Part A** (combat-feel P1–P5, shipped) and **Part B / B1** (gather arm-articulation, planned) own the feel work this note only references.

## Verification
- `cd wyrd && WYRD_NO_SAVE=1 godot --headless --path . --script res://test_wyrd_loop.gd` (movement + state) and `res://test_skills.gd` (hotbar dispatch path) must stay green.
- Phase 1 lean: feel-bench / gallery screenshot mid-run.
- Phase 2: a 2-peer `WYRD_NET=host` / `join:` session, confirm per-peer hit-state isolation.

## Open questions
- Should run be a toggle or hold-Shift-to-walk stay the default? (Affects muscle memory; ADR 0004 currently locks numeric/hardcoded controls.)
- Is co-op **down/revive** in scope for the first multiplayer pass, or does death stay per-peer respawn-at-checkpoint as today?
