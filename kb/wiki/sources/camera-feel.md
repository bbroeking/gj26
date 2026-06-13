---
type: source
tags: [camera, game-feel, locomotion, combat, animation, physics, controls]
status: draft
updated: 2026-06-13
sources:
  - "docs/fate-2005-deep-dive.md"
  - "docs/fate-implementation-summary.md"
  - "docs/design/arpg-game-feel.md"
  - "docs/specs/09-godot-camera.md"
  - "docs/specs/10-godot-physics.md"
  - "docs/specs/11-godot-animation.md"
  - "docs/specs/14-fluid-combat.md"
  - "docs/specs/22-playtest-feel-tuning.md"
  - "docs/specs/23-fluid-movement-sandbox.md"
  - "docs/specs/36-locomotion-research.md"
  - "docs/specs/36-bindings-research.md"
  - "docs/adr/0004-controls-stay-numeric.md"
---

# Source digest — camera and game feel

Source cluster read to produce [[Camera and Game Feel]]. All files are raw docs under `docs/` or `docs/specs/`; code (`wyrd/scripts/`) is the tiebreaker per KB schema.

---

## Files read

| File | Summary |
|---|---|
| `docs/fate-2005-deep-dive.md` | Full Fate (2005) breakdown: design pillars, pet system, heirloom retirement, cozy-ARPG lineage. Camera framing not explicit — but the game's low-pitch isometric look is the named design reference for Wayfinder. |
| `docs/fate-implementation-summary.md` | Implementation-focused companion: concrete schemas, numbers (heirloom +25%/gen, final boss floor 40–50), per-floor loop timing (~8–10 floors/hour). Feel references used for "how does Fate's camera make you feel?" |
| `docs/design/arpg-game-feel.md` | Seven-pillar game-feel framework (input latency, juice density, damage readability, power curve, animation weight, targeting forgiveness, world response). Wayfinder prototype scored ~6/10 average. "Cheap next wins" list: killing-blow flourish, enemy emissive flash, crit camera FOV pulse, HP-bar ghost trail. **Key contradiction**: references `src/main.js` (three.js prototype, removed 2026-06-12) for snap-radius. Godot equivalent is `_soft_aim()` in `player_controller.gd`. |
| `docs/specs/09-godot-camera.md` | Spec for the third-person rig: smooth follow, right-drag + Q/E orbit, pitch clamp, scroll zoom, SpringArm3D wall-aware collision. Note: the live code deviates from the spec — the live rig uses a sphere-placement + `look_at()` approach, not SpringArm3D, because SpringArm at steep pitch pointed away from the player. |
| `docs/specs/10-godot-physics.md` | Floor collision (per-tile BoxShape vs infinite WorldBoundaryShape), kill-plane Area3D, enemy/boss/decor colliders, named collision layers, movement constant tuning. Spec is complete as of the wyrd codebase. |
| `docs/specs/11-godot-animation.md` | Meshy auto-rig + idle/walk animation pipeline for crypt cast (5 GLBs). `anim_driver.gd` idle/walk selection. Meshy MCP gate noted. Quad enemy fell back differently — the rat uses `rat_anim.gd` procedural. |
| `docs/specs/14-fluid-combat.md` | Fluid ranged combat: hitbox/hurtbox Area3D pattern, single-hit dedup, hitstop (global Engine.time_scale), enemy flash, floating damage number, knockback, input buffering. Evals E1–E10 with numeric thresholds. Starting tunables: ARROW_DAMAGE 6, HITSTOP_MS 90, FLASH_MS 120, KNOCKBACK 0.6 m, INPUT_BUFFER_MS 150. |
| `docs/specs/22-playtest-feel-tuning.md` | Structured feel checklist (21 dimensions) and one tuning-pass workflow. Feel bar: FATE/Diablo — weight, readability, comfortable ARPG camera distance. Status at time of notes: checklist prepared, playtest pending. |
| `docs/specs/22-playtest-feel-tuning-notes.md` | Notes: web build chrome-sphere bug fixed (`_unmetal()` zeroes metallic on spawn). Tuning pass pending user playtest. |
| `docs/specs/23-fluid-movement-sandbox.md` | Spec for movement sandbox: walk/run/dash/roll state machine, always-run model, procedural animation (no working baked clips found), projectile rework, movement key decisions (Space=dash at spec time, later flipped to Space=roll per spec 36). |
| `docs/specs/23-fluid-movement-sandbox-notes.md` | Implementation: `enum Move {NORMAL, DASH, ROLL}`; burst velocity is direct-set (no lerp); roll tumble is full TAU rotation of the Mesh node; Meshy v5 Ranger confirmed with working clips; clip merge by substring. Arrow speed 18→28. Chibi Wayfinder swap path documented. |
| `docs/specs/36-locomotion-research.md` | Godot 4 locomotion research: AnimationTree state-machine nesting (outer SM + inner BlendSpace1D), five-move defaults (walk 3 m/s, run 5–6 m/s, roll 9 m/s burst 0.55 s, dash 14–18 m/s 0.20–0.30 s), foot-slide fix options (TimeScale recommended), camera-relative input projection idiom, common pitfalls (travel() vs advance_condition, non-1.0 scale breaks root motion). |
| `docs/specs/36-bindings-research.md` | Binding survey across 9 shipped ARPGs. Conclusion: Space = defensive verb (roll/dodge) in every shipped ARPG that has one (PoE 2, Lost Ark, Hades, post-SOTE Elden Ring). Cancel grammar: active frames uncancellable, recovery opens cancel window. Recommendation for Wayfinder: Space=Roll, Ctrl=Dash, Alt=Jump (if ever added). |
| `docs/adr/0004-controls-stay-numeric.md` | Decision 2026-06-11: WASD + F + 1-4 + E + Space + Q. Click-to-move + QWER fork closed without prototyping. Q stays quaff. Revisit only if WASD fights the camera under B4b+ playtests. |

---

## What these sources fed

All material flows into [[Camera and Game Feel]] (one wiki page). Sub-topics within that page:

- **FATE framing model** — `docs/fate-2005-deep-dive.md`, `docs/fate-implementation-summary.md`, camera rig source comment in `wyrd/scripts/camera_rig.gd`
- **Camera rig implementation** — `docs/specs/09-godot-camera.md`, live code in `wyrd/scripts/camera_rig.gd`
- **Physics / collision** — `docs/specs/10-godot-physics.md`
- **Locomotion state machine** — `docs/specs/23-fluid-movement-sandbox.md`, notes, live code in `wyrd/scripts/player_controller.gd`
- **Animation** — `docs/specs/11-godot-animation.md`, `docs/specs/36-locomotion-research.md`, notes
- **Hit feedback / juice** — `docs/design/arpg-game-feel.md`, `docs/specs/14-fluid-combat.md`
- **Input responsiveness** — `docs/specs/14-fluid-combat.md`, live code in `player_controller.gd`
- **Controls ADR** — `docs/adr/0004-controls-stay-numeric.md`, `docs/specs/36-bindings-research.md`
- **Seven-pillar self-assessment** — `docs/design/arpg-game-feel.md`
- **Playtest constants** — `docs/specs/22-playtest-feel-tuning.md`

---

## Contradictions and flags

1. **`docs/design/arpg-game-feel.md` references `src/main.js`** for snap-radius / targeting forgiveness. `src/` is the removed three.js prototype; in Godot the equivalent is `_soft_aim()` in `wyrd/scripts/player_controller.gd`. Flagged inline on [[Camera and Game Feel]].

2. **Spec 09 describes `SpringArm3D` collision** as the wall-aware mechanism. The live `camera_rig.gd` uses an iterative raycast approach with transparency fade instead. The SpringArm3D wall-aware mechanism from the spec was superseded because `SpringArm3D` at a steep downward pitch pointed the camera *away* from the player. The live implementation is correct; the spec is design history.

3. **Spec 23 lists `dash = Space`, `roll = Ctrl`**; the spec 36 bindings research and live `player_controller.gd` flip these: **`roll = Space`, `dash = Ctrl`** (spec 36 Batch binding decision, `docs/adr/0004` confirms the current layout). The spec-23 note doc still records the old mapping — the live code is authoritative.

4. **Foot-slide fix in spec 36** recommends `AnimationNodeTimeScale` (AnimationTree-based). The live implementation uses `AnimationPlayer.speed_scale` set per-frame in `_physics_process` — effectively the same concept but outside an AnimationTree (which was never used because Wayfinder uses direct `AnimationPlayer` clips, not an AnimationTree state machine).
