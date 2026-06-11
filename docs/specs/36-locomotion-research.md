# Spec 36 — Godot 4 ARPG Locomotion Research

Research-only document. Covers AnimationTree wiring and `CharacterBody3D` controller patterns for **walk / run / roll / dash / jump** in Godot 4.3+. Feel references: FATE Reawakened, Diablo 3, Path of Exile 2 — used only as feel anchors, not as the primary subject.

---

## 1. State machine architecture

Godot ships two complementary `AnimationTree` root types: `AnimationNodeStateMachine` (discrete states + transitions) and `AnimationNodeBlendTree` (continuous interpolation graph) [1][2]. For an ARPG you almost always nest them: the **outer** node is a state machine (it discretises Idle/Locomotion/Roll/Dash/JumpStart/JumpFall/Land), and a **locomotion state** internally is a blend tree containing a BlendSpace1D or 2D that handles the walk↔run gradient [3][4].

Godot 4.3 also exposes `STATE_MACHINE_TYPE_ROOT`, `_NESTED`, and `_GROUPED` on `AnimationNodeStateMachine` — set the inner Locomotion state machine to `NESTED` so "seek to start" means seek to the start of the *current* sub-state instead of the outer Idle [2]. Grouped state machines require a parent ROOT/NESTED ancestor [2].

The "locomotion base + action overlay" pattern that experienced Godot devs use puts a `OneShot` between the state machine and the Output node, so attacks/hit-reacts can blend over locomotion without disturbing the underlying walk cycle [4][5]:

```
AnimationTree (root: AnimationNodeStateMachine)
└─ Output
   └─ OneShot ("ActionOverlay")        ← attack, hit-react, cast
      ├─ in:    StateMachine ("Locomotion")
      │        ├─ Idle  ──┐
      │        ├─ Move  ──┤  ← inner BlendTree → BlendSpace1D (walk↔run)
      │        ├─ Roll   (At End → Move)
      │        ├─ Dash   (At End → Move)
      │        └─ Jump   (Start → Air → Land → Move)
      └─ shot:  Animation ("Attack01" / swapped at runtime)
```

`OneShot`'s `fadein_time` and `fadeout_time` both default to `0.0`; for an ARPG attack overlay use `0.05–0.10s` so the swing pop is felt but doesn't snap [6]. Fire it with `ONE_SHOT_REQUEST_FIRE` and abort with `ONE_SHOT_REQUEST_ABORT`; the request param auto-resets to `NONE` next frame [6].

---

## 2. Locomotion blendspace

Use **`BlendSpace1D`** for a 3D ARPG with a strafe-free, "always face movement direction" controller (our case). Place Idle at `0.0`, Walk at a midpoint (`0.4`), Run at `1.0` [1][7]. Reserve `BlendSpace2D` for strafe-shooters where the body is decoupled from movement direction (Ratchet/Resident Evil layout) — it triangulates between 8 points (Idle centre, 4 cardinals, 4 diagonals) using Delaunay [7][8].

`BlendSpace1D` properties worth knowing: `min_space = -1.0`, `max_space = 1.0` defaults, `snap = 0.1`, `blend_mode = INTERPOLATED` (use `DISCRETE_CARRY` only for stepped pixel-art) [7].

Drive the blend from `velocity.length()`, but **lerp** so the gradient doesn't snap when input releases. Recommended per-frame update inside `_physics_process` [1][8][9]:

```gdscript
const MAX_SPEED := 6.0
const BLEND_LERP := 12.0      # higher = snappier; 8-15 feels right

var _blend := 0.0

func _update_locomotion_blend(delta: float) -> void:
    var target := clamp(velocity.length() / MAX_SPEED, 0.0, 1.0)
    _blend = lerpf(_blend, target, BLEND_LERP * delta)
    anim_tree.set("parameters/Locomotion/Move/BlendSpace1D/blend_position", _blend)
```

Recommended **xfade** on state-machine transitions: `0.15–0.25 s` for natural locomotion, `0.05–0.10 s` for action triggers (roll/dash/jump-start), `0.0` only for truly snap-on transitions like landing impact frames [4][10]. Zero xfade is an anti-pattern for locomotion — it pops.

---

## 3. The five moves

### 3.1 Walk

- **AnimationTree wiring**: lives inside the `Locomotion` sub-state-machine as the low end of the BlendSpace1D (point at `0.4`). No dedicated state.
- **Controller**: triggered passively when `0 < velocity.length() < MAX_SPEED * 0.6`. No "enter walk" call; the blend parameter does the work.
- **Defaults**:
  - Walk speed `3.0 m/s` [11]
  - Blend-position trigger point `0.4`
  - Lerp toward target velocity at `ACCEL = 10` (matches our current value) [12]
  - Turn lerp `10.0 * delta` for `lerp_angle` body yaw [11]
- **Motion source**: code-driven velocity. Root motion is unnecessary because animation plays at a single tuned speed and the blend handles the rest.
- **Feel reference**: FATE Reawakened — mouse-to-click pathing, walk is rarely seen because click-to-move snaps straight to run; only used for fine adjustments around shops [13].

### 3.2 Run

- **AnimationTree wiring**: top end of the BlendSpace1D (point at `1.0`). Optionally add an `AnimationNodeTimeScale` upstream of the run clip so playback rate can be nudged to match velocity (anti-foot-slide; see §4) [14].
- **Controller**: same lerp as walk; just a higher target speed when a "sprint" modifier is active or, in our case, just the standard speed (we currently have `SPEED=5.0`).
- **Defaults**:
  - Run speed `5.0–6.0 m/s` (GDQuest demo uses `6.0`; our spec currently uses `5.0`) [11][12]
  - ACCEL `10`, DECEL `15` (sharper stop than start reads as weighty without feeling sluggish)
  - TimeScale factor `0.85–1.15` mapped from `velocity.length() / RUN_SPEED` to mask foot-slide [14]
- **Motion source**: code-driven velocity.
- **Feel reference**: Diablo 3 base run — constant cadence, never stutters; tuning target is "no acceleration spike visible to the eye" [15].

### 3.3 Roll

- **AnimationTree wiring**: discrete `Roll` state in the outer state machine. Transition **in** via `travel("Roll")` (event-driven). Transition **out** is `At End → Locomotion/Idle` with `xfade_time = 0.10` and `reset = false` so the roll plays from frame 0 every fire [10][16].
- **Controller**: on input press, set `is_rolling = true`, capture roll direction from current `velocity.normalized()` (or input vector if stationary), apply a fixed-speed burst, start a duration timer. While `is_rolling`, ignore directional input. End on timer expiry → `is_rolling = false` and travel back to `Move`. Use a sub-window for i-frames.
- **Defaults**:
  - Burst velocity `9.0 m/s` (≈1.5–2× run) [17]
  - Duration `0.55 s` (PoE2's dodge covers ~3.7 m total; at 9 m/s that's ~0.4 s of distance + ~0.15 s of recovery) [17][18]
  - **i-frame window** = first 50% of duration (`0.0–0.275 s`); last half is vulnerable [17][18]
  - Cooldown `0.0 s` (PoE2 has none; gating is via stamina or just animation lock) [17]
  - Roll cannot be cancelled by anything except another action input ≥ end-of-i-frames [17]
- **Motion source**: code-driven velocity is standard in Godot ARPGs. Root motion is *possible* but bites you when stitching with `move_and_slide()` because mesh scale ≠ 1.0 breaks it (see §6). Code-driven also lets you keep i-frame timing decoupled from animation length.
- **Feel reference**: Path of Exile 2 dodge — first half phases through projectiles, second half is recovery, no cooldown but commits the player to the trajectory [17][18].

### 3.4 Dash

- **AnimationTree wiring**: separate `Dash` state (do NOT reuse Roll — different animation, different recovery). Transition in via `travel("Dash")`. Out via `At End → Move`. Optional: nest a tiny state machine inside `Dash` with `DashStart → DashLoop → DashEnd` if you want a visible windup.
- **Controller**: input press → set `dash_timer = DASH_DURATION`, set `dash_velocity = forward * DASH_SPEED`. While `dash_timer > 0`, override velocity each frame (don't add — overwrite) and decrement. On expiry, restore normal locomotion. Use a separate `dash_cooldown_timer` if gating [16][19].
- **Defaults**:
  - Burst speed `14–18 m/s` (~3× run) [19]
  - Duration `0.20–0.30 s` (shorter than roll; dashes are reflex-tier) [19]
  - i-frame window: optional, often `0` (dash is for repositioning, not survival)
  - Cooldown `1.0 s` typical [19]
  - Can be interrupted by jump in some controllers (PantheraOnline's modular controller cancels dash on jump after ~50% slide) [20]
- **Motion source**: code-driven velocity, always. Root motion is wrong for dash — you want a fixed distance regardless of animation length.
- **Feel reference**: Diablo 3 Crusader Steed Charge — +150% movement speed for the duration, locks other actions for 0.4 s; "committed reposition" rather than "evade" [15].

### 3.5 Jump

- **AnimationTree wiring**: three states stacked — `JumpStart` (short windup clip), `JumpAir` (looping or single-frame held mid-air), `JumpLand` (landing recovery). Transitions: `JumpStart → JumpAir` via `At End`; `JumpAir → JumpLand` via condition `is_on_floor`; `JumpLand → Move` via `At End`. Use `Immediate` xfade `0.05` for `JumpStart` so the takeoff pops.
- **Controller**: on input + `is_on_floor()`, set `velocity.y = JUMP_VELOCITY` and `travel("JumpStart")`. Gravity (we use `22.0 m/s²`) takes over each frame. On landing detect transition floor-edge with `is_on_floor()` going false→true.
- **Defaults**:
  - Jump impulse `8.0 m/s` upward (GDQuest demo) [11]
  - Gravity `20.0–22.0 m/s²` — higher than real 9.8 for snappy fall [11][12]
  - Air control `0.3` (30% of ground accel applied to horizontal input while airborne) [11]
  - Coyote time `0.10 s` (grace window for jumping after walking off edges) [11]
  - Jump-buffer `0.10 s` (queue jump press just before landing)
- **Motion source**: code-driven velocity for vertical; horizontal stays code-driven. Root motion on jump animations is rarely worth it.
- **Feel reference**: Diablo 3 has no jump; Path of Exile 2 has no free jump either — they're ARPG. The closest **feel** anchor is FATE Reawakened's animation-locked attacks-that-lurch-forward [13] which we should *not* replicate. Pull jump feel instead from Celeste-style coyote+buffer in 3D.

---

## 4. Foot-slide prevention

Three approaches available in Godot 4:

1. **`AnimationNodeTimeScale` synced to velocity** — cheap, no animation re-authoring. Multiply the run clip's playback rate by `velocity.length() / RUN_SPEED` (clamped `0.7–1.3`). Works because slide is mostly a "cadence ≠ speed" problem [14]. Cost: clips played outside `0.9–1.1` start to look obviously sped-up.
2. **Root motion from the AnimationTree** — set the root bone's track as the root-motion track in `AnimationPlayer`, then in the controller: `velocity = (global_transform.basis * anim_tree.get_root_motion_position()) / delta; move_and_slide()` [21][22][1]. Pixel-perfect foot lock, but couples velocity to animation (no free speed tuning) and breaks the moment your model has non-1.0 scale (see §6).
3. **Foot-IK** — `SkeletonIK3D` works but is **deprecated** in 4.4+; replacement is `SkeletonModifier3D` / `ManyBoneIK3D` (`TwoBoneIK3D`, `ChainIK3D`, `IterateIK3D`) introduced via PR landing in 4.5/4.6 [23][24][25]. Heavy: needs raycasts per foot, terrain-normal alignment, and a step-arc state. Mostly used for uneven terrain, not slide-fix.

**Recommendation for our chunky low-poly stylized case**: **#1 (TimeScale synced to velocity)**. The chunky 4-step toon gradient already eats subtle foot artifacts, our clips are short Meshy-rigged loops we don't want to re-author for root motion, and `move_and_slide()` plus code-driven velocity is the controller pattern the rest of our codebase already follows. Reserve root motion for cinematic moves (boss telegraphs) where exact distance matters.

---

## 5. Camera-relative input projection

Our `src/scene/.../09-camera.gd` already projects WASD through the camera basis. The standard Godot 4 idiom is [11][26]:

```gdscript
var input_dir := Input.get_vector("move_left","move_right","move_up","move_down")
var cam_basis := camera.global_transform.basis
var forward := -cam_basis.z;  forward.y = 0; forward = forward.normalized()
var right   :=  cam_basis.x;  right.y   = 0; right   = right.normalized()
var move    := (right * input_dir.x + forward * input_dir.y)
```

Two suboptimalities to check in our current spec 09 code:

- **Re-normalising the camera basis vectors after zeroing y.** If you skip `.normalized()`, diagonal speed drifts because `forward + right` is `√2` long when pitched. Make sure both vectors are normalized after the y-flatten [11].
- **Using `camera.global_transform.basis.z` raw** without negating — Godot's camera looks down `-Z`, so `forward = -cam.basis.z` is correct; `+z` will run the player away from where the camera is pointing.

Also: when projecting input, use `Input.get_vector()` (built-in deadzone + clamp) rather than four `is_action_pressed` reads [11].

---

## 6. Common pitfalls

1. **`travel()` vs `advance_condition` confusion.** `advance_condition` only auto-fires direct neighbour transitions; it does **not** override `travel()`'s A* pathfinding. Use conditions for ambient locomotion, `travel()` for combat events [4][27].
2. **`travel()` silently fails with no valid path.** If a transition between two states isn't drawn in the editor (or is disabled), `travel()` returns without error. Always sanity-check by playing each state from `state_machine.travel("X")` in `_ready` debug [4][28].
3. **Non-looping animations don't restart on re-travel.** After a non-looping clip finishes, `is_playing()` still returns true and `travel("RollAgain")` is a no-op. Fix: call `state_machine.start("Roll")` instead of `travel()` to force-restart [28].
4. **Scaled rig breaks root motion.** If your imported GLB has any non-`(1,1,1)` scale on the `Skeleton3D` or its parent, `get_root_motion_position()` returns garbage. Fix: in the Import dock set the model scale to 1.0, or apply scale in Blender before export [21][22].
5. **`OneShot` interruption-after-completion bug.** Triggering a OneShot, then a second OneShot before the first finishes, can cause the first to "come back" after the second ends. Workaround: a single OneShot whose embedded `AnimationNodeAnimation.animation` you swap at runtime, fired via `ONE_SHOT_REQUEST_FIRE` each time [6][29].
6. **AnimationLibrary cloning shares tracks silently.** Two scenes pointing at the same `AnimationLibrary` resource will share state and edits. Set Local-to-Scene on the AnimationTree, or duplicate the library per-character [4][1].
7. **`floor_snap_length` eats jumps.** Default `0.1` is fine, but if you raise it for slope-stick, the controller will yank the character back to the floor on small jump impulses. Disable snap during `JumpStart` (set `floor_snap_length = 0` while `velocity.y > 0`) [30].
8. **Setting `velocity = direction * speed * delta` instead of `velocity = direction * speed`.** `move_and_slide()` already integrates over delta — multiplying yourself produces a controller that runs at ~`delta²` (i.e. unusably slow). Common typo from `move_and_collide` muscle memory [30].

---

## 7. References

- [1] Godot Engine docs — *Using AnimationTree* (stable): https://docs.godotengine.org/en/stable/tutorials/animation/animation_tree.html
- [2] Godot Engine docs — *AnimationNodeStateMachine* (4.6): https://docs.godotengine.org/en/stable/classes/class_animationnodestatemachine.html
- [3] Kidscancode — *Using the AnimationTree StateMachine* (Godot 4 Recipes): https://kidscancode.org/godot_recipes/4.x/animation/using_animation_sm/index.html
- [4] godot-mcp.abyo.net — *AnimationTree State Machines in Godot 4 — Complete Guide*: https://godot-mcp.abyo.net/guides/godot4-animationtree
- [5] Godot proposals issue #5155 — *Better way of handling one shot action animations*: https://github.com/godotengine/godot-proposals/issues/5155
- [6] Godot Engine docs — *AnimationNodeOneShot*: https://docs.godotengine.org/en/stable/classes/class_animationnodeoneshot.html
- [7] Godot Engine docs — *AnimationNodeBlendSpace1D*: https://docs.godotengine.org/en/stable/classes/class_animationnodeblendspace1d.html
- [8] Godot Engine docs — *AnimationNodeBlendSpace2D*: https://docs.godotengine.org/en/stable/classes/class_animationnodeblendspace2d.html
- [9] Bugnet — *Fix: Godot AnimationTree Blend Values Not Transitioning Smoothly*: https://bugnet.io/blog/fix-godot-animationtree-blend-not-transitioning
- [10] BitSoul — *Godot 4 AnimationTree: Complete Guide to Character Animations*: https://bitsoulhosting.com/marketplace/blog/godot-4-animationtree-character-animation-guide
- [11] Coding Quests — *Godot 4 3D Character Controller Tutorial*: https://codingquests.io/blog/godot-4-3d-character-controller-tutorial
- [12] GDQuest — *Character Movement in 3D*: https://www.gdquest.com/library/character_movement_3d_platformer/
- [13] Niche Gamer — *FATE: Reawakened Review*: https://nichegamer.com/reviews/fate-reawakened-review/
- [14] Godot Engine docs — *AnimationNodeTimeScale*: https://docs.godotengine.org/en/stable/classes/class_animationnodetimescale.html
- [15] Diablo Wiki — *Steed Charge*: https://diablo.fandom.com/wiki/Steed_Charge
- [16] Godot Forum — *Dodge roll animation* (Godot 4.5): https://forum.godotengine.org/t/dodge-roll-animation/125793
- [17] Mobalytics — *PoE 2 Guide: Dodge Roll Explained*: https://mobalytics.gg/poe-2/guides/dodge-roll-mechanic
- [18] Deltia's Gaming — *How To Dodge and Block in Path of Exile 2*: https://deltiasgaming.com/how-to-dodge-and-block-in-path-of-exile-2/
- [19] Godot Forum — *Cooldowns on dashing?*: https://forum.godotengine.org/t/cooldowns-on-dashing/110961
- [20] PantheraOnline — *Godot Modular Character Controller*: https://pantheradigital.itch.io/godot-modular-character-controller
- [21] Godot Forum (archive) — *How to use root motion to make a 3D character move in Godot 4*: https://forum.godotengine.org/t/how-to-use-root-motion-to-make-a-3d-character-move-in-godot-4/1489
- [22] MoCap Online — *Motion Capture Animations in Godot 4*: https://mocaponline.com/blogs/mocap-news/motion-capture-godot-guide
- [23] Godot Engine docs — *SkeletonIK3D* (4.4): https://docs.godotengine.org/en/4.4/classes/class_skeletonik3d.html
- [24] Godot Forum — *How to Implement Foot/Leg IK in Godot 4.4?*: https://forum.godotengine.org/t/how-to-implement-foot-leg-ik-in-godot-4-4/112274
- [25] 80.lv — *IK-Driven Procedural Spider Locomotion In Godot 4.5*: https://80.lv/articles/ik-driven-procedural-spider-locomotion-in-godot-4-5
- [26] GDQuest demos — *godot-4-3d-third-person-controller* (open-source): https://github.com/gdquest-demos/godot-4-3d-third-person-controller
- [27] Godot issue #63921 — *AnimationNodeStateMachine overvalues node distances in pathfinding*: https://github.com/godotengine/godot/issues/63921
- [28] Godot issue #70318 — *travel() won't restart non-looping animations*: https://github.com/godotengine/godot/issues/70318
- [29] Godot issue #71195 — *AnimationTree OneShot cannot be interrupted*: https://github.com/godotengine/godot/issues/71195
- [30] Godot Engine docs — *CharacterBody3D*: https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html
- [31] GDQuest demos — *godot-3d-mannequin* (open-source character controller): https://github.com/gdquest-demos/godot-3d-mannequin

**Feel-reference videos / articles, one per move:**

- *Walk* — Niche Gamer's FATE Reawakened review: snappy mouse-driven walk used only for fine positioning [13]
- *Run* — Mobalytics PoE 2 dodge-roll guide notes "roll speed is affected by movement speed, and travels same total distance as base movement" — the spec for "run feels equal whether you sprint or roll" [17]
- *Roll* — Sportskeeda — *Path of Exile 2 dodge-roll system basics*: https://www.sportskeeda.com/mmo/path-exile-2-poe2-dodge-roll-system-iframes
- *Dash* — Diablo Fandom Wiki — *Steed Charge* (the "+150% movement speed for the duration, locks actions 0.4 s" reference) [15]
- *Jump* — N/A in the ARPG references; pull feel from Celeste-style coyote/buffer (not cited here, this is a known design pattern).
