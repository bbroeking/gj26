---
type: system
tags: [camera, game-feel, locomotion, combat, juice, animation, physics]
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
  - "wyrd/scripts/camera_rig.gd"
  - "wyrd/scripts/player_controller.gd"
---

# Camera and Game Feel

The camera rig, locomotion state machine, hit feedback, and feel-tuning philosophy that together make Wayfinder feel like a cozy ARPG rather than a tech demo.

---

## The FATE framing model

The primary design reference for the camera is *Fate* (2005, Travis Baldree). The chosen framing is a **low-pitch telephoto** that reads as a 3/4 view toward a horizon rather than a top-down map look:

- **Pitch default: 38°** above the horizon — "FATE's low 3/4": silhouettes instead of rooftops. (`docs/specs/09-godot-camera.md`)
- **Narrow FOV: 35°** (set on the `Camera3D` in `CameraRig.tscn`) — perspective compression enlarges the character and reduces peripheral clutter.
- **Zoom default: 14 m** (range 8–22 m, step 2 m) — with the long lens the character reads ~80% larger on screen than the earlier 17 m / 50° setup.

The combination of a *low* pitch and a *telephoto* lens is the key: distance goes up while the character stays large, the world appears to have a horizon, and the frame holds less junk. (`wyrd/scripts/camera_rig.gd` TUNABLES block, comment "FATE (2005) framing.")

---

## Camera rig implementation

The live camera rig lives at `wyrd/scripts/camera_rig.gd`, on a standalone pivot `Node3D` that is *not* parented to the player so the follow can be smoothed. The camera is placed on a sphere around the pivot and uses `look_at()` — it always faces the player at any pitch (fixing an earlier `SpringArm3D` bug where steep top-down angles pointed the camera away from the player).

### Follow and lead

```
FOLLOW_SPEED = 12.0  # responsive catch-up; cozy tone stays in framing, not latency
LEAD_FACTOR  = 0.14  # seconds of velocity to nudge pivot ahead
MAX_LEAD     = 1.0   # world-unit cap so quick movement stays centered
```

The pivot is nudged ahead of the player along the horizontal velocity vector (`LEAD_FACTOR × velocity`, capped at `MAX_LEAD`). This makes the camera feel alive rather than glued. (`docs/specs/36-locomotion-research.md`, Batch B decisions.)

### Orbit controls

- **Right-mouse drag** — yaw + pitch orbit; `ORBIT_SENSITIVITY = 0.006` rad/pixel.
- **Z / C keys** — keyboard yaw (was Q/E; E was re-bound to Interact to resolve the double-bind that accidentally opened chests while rotating the camera).
- **Pitch clamped** to `[PITCH_MIN 25°, PITCH_MAX 70°]` — can't flip under the floor or past the horizon.
- **Scroll wheel** — adjusts zoom (`ZOOM_LERP = 10.0`).

### Wall occlusion

When geometry sits between the camera and the player, `_update_wall_occlusion()` casts a ray from camera to player and fades all wall nodes in the path to `transparency = 0.75` (i.e. 25% alpha). When the wall clears, it restores to `transparency = 0.0`. Walls are found via the `"wall"` group. This is a raycast-step approach (up to 10 steps per frame) rather than `SpringArm3D` collision, allowing transparency fade instead of camera spring-in.

### Screen shake

`shake(amount: float)` is called by `combatant.gd` on hits. The rig stores `_shake_amt` and applies a random `Vector3` jitter after `look_at()` each frame, decaying at `14.0 × delta`. The strongest pending shake wins (`maxf`).

---

## Physics and collision model (spec 10)

`player_controller.gd` uses `CharacterBody3D` + `move_and_slide()`. Key constants:

| Constant | Value | Notes |
|---|---|---|
| `RUN_SPEED` | 5.2 m/s | Combat-readable travel speed from spec 61 |
| `WALK_SPEED` | 2.6 m/s | Hold Shift to walk |
| `ACCEL` | 28.0 | Fast speed-up and direction-maintenance |
| `DECEL` | 34.0 | Immediate release response |
| `TURN_DECEL` | 44.0 | Direction reversal |
| `GRAVITY` | 22.0 m/s² | Higher than 9.8 for snappy descent |

The split decel rates (`DECEL` vs `TURN_DECEL`) were introduced in spec 36 Batch B. Previously a single `ACCEL` handled both speed-up and stop, making stops feel skiddy and direction-reversals feel laggy.

Floor collision uses per-tile `StaticBody3D` + `BoxShape3D` (not the infinite `WorldBoundaryShape3D` placeholder from spec 07). A kill-plane `Area3D` at y = -6 returns the player to the entry tile if they fall. Named collision layers (`world`, `player`, `enemies`) are declared in `project.godot`.

---

## Locomotion state machine

The player has three move states (`enum Move { NORMAL, DASH, ROLL }`). Fire is a layered action on top — you can fire in NORMAL but not during DASH or ROLL (a fire press is buffered and fires when the burst ends).

### Walk / run (NORMAL)

- **Always-run** model: default speed is RUN_SPEED; holding Shift slows to WALK_SPEED.
- Input direction is **camera-relative**: WASD projects through the camera's yaw basis, flattening y and normalizing, so "forward" always means "toward where the camera is looking." (`wyrd/scripts/player_controller.gd` `_input_dir()`)
- The mesh yaw interpolates toward the travel direction at rate 10 rad/s (18 rad/s during bursts for crisper snap-and-go).

### Dash (NORMAL → DASH)

- **Key**: Ctrl (ADR 0004 — kept numeric/modifier, not click-to-move).
- Burst: `DASH_SPEED = 11.0 m/s` for `DASH_TIME = 0.18 s`, cooldown `0.7 s`.
- No i-frames — dash is a reposition tool, not a survival tool.
- Direction locked at burst start; velocity set directly (no lerp) for instant responsiveness.

### Roll (NORMAL → ROLL)

- **Key**: Space — matches the industry standard for the defensive verb (PoE 2, Hades, Lost Ark, post-SOTE Elden Ring all put dodge on Space). (`docs/specs/36-bindings-research.md` §2, Recommendation Option B.)
- Burst: `ROLL_SPEED = 6.5 m/s` for `ROLL_TIME = 0.45 s`, cooldown `0.85 s`.
- **i-frame window**: `ROLL_IFRAMES = 0.27 s` = first 60% of ROLL_TIME. The last 40% is a punishable recovery tail. (Was 0.4 s / 89% — effectively full invuln; cut per spec 36.)
- Visual: the `Mesh` node rotates a full `TAU` about local X over `ROLL_TIME` plus a sin-arc hop (`sin(prog × π) × 0.55`) to read as a waist-centred tumble rather than a floor-clipping wiper.

### Recovery-cancel window (spec 36)

During the **last 30%** of a dash or roll, a fresh dash/roll input restarts the burst. Active frames (first 70%) stay committed. This is the Souls/PoE/DMC pattern — refusing recovery-cancel made the locomotion suite feel "jail-stiff." (`docs/specs/36-locomotion-research.md` §3.3–3.4, `wyrd/scripts/player_controller.gd` `_physics_process`.)

---

## Animation

### Clip source

The player uses **Meshy v5 Ranger** clips (idle/walk/run). Three separate GLBs share the same rig; `_setup_clips()` merges them into one `AnimationLibrary` at runtime by copying `Animation` resources. Clip names are matched by substring (case-insensitive) so Meshy naming variants don't break lookup. (`docs/specs/23-fluid-movement-sandbox-notes.md`)

The chibi Wayfinder (2026-06-10) follows the same merge pattern from `player_chibi_v1_rigged.glb`, `_walk.glb`, `_run.glb`. A Meshy baked root-scale track (idle: 1.176×) was stripping the character's size on transition; `_strip_scale_tracks()` removes all `TYPE_SCALE_3D` tracks at load.

### Foot-slide fix

`AnimationPlayer.speed_scale` is set per-frame to `clamp(horizontal_speed / WALK_REF_SPEED, 0.5, 1.3)` while the player is moving, keeping the stride cadence proportional to the distance covered. At rest the scale is 0.85. `WALK_REF_SPEED = 5.2` matches current run speed. (`docs/specs/36-locomotion-research.md` §4; responsive retune in spec 61.)

### Enemy animations

Enemies use `anim_driver.gd` to crossfade between `idle` and `walk` clips from their Meshy-rigged GLBs. Layout loader prefers `_rigged.glb` variants and falls back to static `_v1` GLBs. (`docs/specs/11-godot-animation.md`)

---

## Hit feedback (juice)

Seven simultaneous feedback layers fire on a hit — the "juice stack." The goal is that the player cannot consciously count the layers; they just feel "the hit landed." (Steve Swink, *Game Feel*; Jan Willem Nijman, "Art of Screenshake"; `docs/design/arpg-game-feel.md` §2.)

| Layer | Value |
|---|---|
| Screen shake | `shake()` called on `camera_rig`; amplitude decays at 14× delta |
| Hitstop | `Hitstop.freeze(0.07 s)` — global `Engine.time_scale` pause; 90 ms designed value (`HITSTOP_MS`) |
| Enemy flash | Albedo brightens ~30% for 120 ms (`FLASH_MS`) via material override |
| Floating damage number | `Label3D` spawned at hit point, rises + fades |
| Knockback | Enemy and player velocities get an impulse along hit vector |
| Impact spark | Particle/flash burst at hit point |
| Death flourish | 0.12 s extended hitstop + larger spark burst + brief FOV nudge (planned) |

Hit feedback evals (`test_combat.gd` E1–E10) measure: fire→spawn latency ≤ 2 frames, hit registration exactly once, hitstop in `[60, 160] ms`, knockback > 0.05 m, damage number spawned, arrow cleanup to 0. (`docs/specs/14-fluid-combat.md`)

---

## Input responsiveness

Three mechanisms keep the game feeling immediate:

1. **Input buffering (fire)**: `_fire_buffer = INPUT_BUFFER_SEC` (0.15 s) is set on press. If the cooldown clears while the buffer is live, the shot fires automatically. No dropped presses.
2. **Input buffering (skills 1-4)**: Same pattern via `_skill_cooldowns`.
3. **Camera-relative direction snap**: `_input_dir()` always projects through the *current* camera basis, not a stale cached vector, so direction change is single-frame.

`docs/design/arpg-game-feel.md` §1 sets the target at ≤ 100 ms button-to-first-visible-response; Hades achieves ~33 ms (single-frame at 30 fps). Wayfinder's current score on that pillar was rated 8/10 (1.15 s swing cooldown, but buffer + relative input make every press feel honored).

---

## Controls decision (ADR 0004)

**Locked 2026-06-11**: the control scheme is WASD + F (basic shot) + 1-4 (skills) + E (interact) + Space (roll) + Ctrl (dash) + Q (quaff). Click-to-move + QWER was considered (the Fate/PoE fork) and rejected without prototyping — it would require rethinking gather channels, roll, and interact targeting. The numeric/modifier scheme was evaluated against real B3/B4a combat (per-kind enemy stats, Boar charge) and kept. (`docs/adr/0004-controls-stay-numeric.md`)

The camera-yaw keys were Z/C rather than Q/E after E was assigned to Interact; the previous Q/E double-bind accidentally opened chests while rotating the camera.

---

## Seven-pillar self-assessment

`docs/design/arpg-game-feel.md` defines seven independent feel axes and scored Wayfinder's prototype (pre-spec-36):

| Pillar | Score | Gap |
|---|---|---|
| 1. Input→action latency | 8/10 | Buffer + camera-relative input work; minor cooldown gaps |
| 2. Hit feedback density | 6/10 | Missing enemy emissive flash at 30 fps precision; crit FOV pulse |
| 3. Damage curve readability | 5/10 | No HP-bar ghost trail; no log-scaled crit font |
| 4. Power fantasy curve | 4/10 | No AoE unlock arc; needs more content tiers |
| 5. Animation timing & weight | 6/10 | No distinct wind-up/active/recovery per weapon class |
| 6. Targeting forgiveness | 8/10 | Snap radius works; needs auto-camera follow on lock |
| 7. World response | 5/10 | Missing stagger threshold, dramatic death frames |

Average 6/10. The spec-36 locomotion overhaul, clip-based animation, and split-decel rates improve pillars 1, 5, and 6. The remaining gaps (3, 4, 7) are lower-priority followups.

> ⚠️ The seven-pillar assessment in `docs/design/arpg-game-feel.md` references `src/main.js` left-click forgiveness — this is the deprecated three.js prototype, removed 2026-06-12. The Godot equivalent is the soft aim-assist in `_soft_aim()` in `wyrd/scripts/player_controller.gd`.

---

## Playtest constants (spec 22)

`docs/specs/22-playtest-feel-tuning.md` defines a 21-row checklist in `docs/PLAYTEST.md`. Key tunable constants and their locations:

| Dimension | Constant | Location |
|---|---|---|
| Aggro radius | `AGGRO_RADIUS` | `combatant.gd` |
| Telegraph readability | `TELEGRAPH_SEC` | `combatant.gd` |
| Hitstop | `HITSTOP_SEC` | `hitstop.gd` |
| Knockback | `KNOCKBACK`, `HIT_KNOCKBACK` | `combatant.gd`, `player_controller.gd` |
| Fire cadence | `FIRE_COOLDOWN` | `player_controller.gd` |
| Input buffer | `INPUT_BUFFER_SEC` | `player_controller.gd` |
| Camera angle/distance | `ZOOM_DEFAULT`, `PITCH_DEFAULT` | `camera_rig.gd` |
| i-frames | `IFRAMES_SEC`, `ROLL_IFRAMES` | `player_controller.gd` |
| Difficulty | `ENEMY_HP`, `ENEMY_DAMAGE`, `PLAYER_HP` | `combatant.gd`, `player_controller.gd` |

The feel bar for the tuning pass is FATE/Diablo: "movement and hits have weight, attacks are readable, the camera sits at a comfortable ARPG distance, and the moment-to-moment loop is satisfying before it's hard."

---

## See also

- [[Combat]] — damage pipeline, hitstop, and the ranged combat loop
- [[Animation Pipeline]] — Meshy rig+animate workflow that feeds clip-based characters
- [[Design Influences]] — Fate (2005), Hades, Path of Exile 2 as feel references
- [[Design Decisions]] — ADR 0004 (controls scheme) and the camera orbit key re-bind
- [[Onboarding and Tutorial]] — first encounter with the camera and controls
- [[Dungeon Generation]] — the dungeon geometry the camera navigates and occludes

## Sources

- `docs/fate-2005-deep-dive.md` — Fate design philosophy, the cozy-ARPG lineage
- `docs/fate-implementation-summary.md` — concrete numbers and feel references
- `docs/design/arpg-game-feel.md` — seven-pillar framework + current scores
- `docs/specs/09-godot-camera.md` — third-person rig spec (smooth follow, orbit, zoom, wall-aware)
- `docs/specs/10-godot-physics.md` — collision model, movement constants
- `docs/specs/11-godot-animation.md` — Meshy rig+animate pipeline
- `docs/specs/14-fluid-combat.md` — hit feedback, hitstop, input buffer, evals
- `docs/specs/22-playtest-feel-tuning.md` — playtest checklist and tuning constants
- `docs/specs/23-fluid-movement-sandbox.md` — locomotion state machine, projectile rework
- `docs/specs/23-fluid-movement-sandbox-notes.md` — implementation decisions, surprises
- `docs/specs/36-locomotion-research.md` — AnimationTree patterns, five-move defaults, foot-slide fix
- `docs/specs/36-bindings-research.md` — default binding heatmap, cancel-grammar survey
- `docs/adr/0004-controls-stay-numeric.md` — click-to-move fork closed
- `wyrd/scripts/camera_rig.gd` — live implementation (code is tiebreaker)
- `wyrd/scripts/player_controller.gd` — locomotion, bursts, i-frames, aim assist
