# Animation pipeline

Bramblewood uses two animation strategies in parallel:

1. **Procedural animation** (default) — per-frame rotation of named
   groups in a GLB, driven by JS state. Cheap, easy to retune, plays
   well with hit-stop and FOV pulses. No skeletal rigging required.
2. **Skinned animation** (rare) — Blender-authored bone-driven clips
   exported into the GLB and played via `THREE.AnimationMixer`.
   Reserved for characters whose joint-bend matters (e.g. an
   apprentice bowing).

Both flow through `src/data/animations.js` so the codex Animations tab
can list every animation in the game with its status.

---

## Process — every new animation

### 1. Design (one paragraph)

Write down what the animation **expresses** before touching geometry:

- Who performs it (player / enemy kind / NPC kind).
- What action it accompanies (idle / walk / run / attack / dodge /
  hurt / death / cast / interact).
- How long it should read on screen — typical: 0.2–0.5s for attacks,
  0.6–1.2s for walks, 0.4s for dodges, 0.25s for hurt.
- The *feeling word* — "tired", "playful", "menacing", "frantic".
  This is what the procedural amplitude or clip easing should embody.

### 2. Concept (one reference)

Pick **one** reference: a still frame, a 2-second video clip, or a
verbal "the right arm leads, the left lags by 1/3 second" description.
Save it to `docs/anim-refs/<name>.png` if it's an image.

### 3. Author

#### Procedural path

- Open `src/anim/<entity>.js` — there's already a file per major entity
  type (`knight.js`, `goblin.js`, `cow.js`, `bird.js`, `quadruped.js`).
- Add or modify a function that takes `(mesh, entity, dt)` and rotates
  the mesh's named subgroups (`Body`, `Head`, `Arm_L`, `Arm_R`,
  `Leg_L`, `Leg_R`, sometimes `Tail`).
- Drive the rotation amplitude off entity state — `e.moving`,
  `e.running`, `e.attackT`, `e.hurtT`, etc. The state lives on the
  entity object, set by gameplay code.
- Use `procedural.js`'s `spring1D` helper for any state that needs to
  ease in/out smoothly (e.g. body lean while running).

#### Skinned path

- Author the clip in Blender against the GLB's armature.
- Name the action after its purpose (`Walk`, `Idle`, `Attack`).
- Export with `export_animations=True, export_skins=True,
  export_apply=True`.
- Load via `src/anim/clips.js` helpers: `setupKnightMixer(mesh)` is
  the reference pattern. The mixer is updated each frame with `dt`.
- Crossfade between actions when state changes (idle → walk →
  attack). Don't snap.

### 4. Wire

- Register the animation in `src/data/animations.js` so the codex
  Animations tab picks it up. Set `status: 'live'` once it's in the
  game loop.
- Find the gameplay site that should trigger it (e.g. `triggerAttack`
  in `src/anim/knight.js`, called from `attackEnemy` in combat.js).
  Add the trigger call.
- For skinned animations, call `mixer.clipAction(clip).play()` on the
  state transition, and `crossFadeTo(otherClip, dur)` to blend.

### 5. Polish

- Test in the game with the actual entity at the actual scale. If the
  joint bends look broken, check that the GLB's named groups were
  re-parented (per `feedback_blender_bevel_pipeline.md` memory — sub-
  parts like eyes/fangs need to be children of `Head`).
- Sound cue — every triggered animation should have an `sfx.<verb>()`
  call paired with it. Footsteps are tile-aware via
  `sfx.footstepOn(kind)`.
- Hit-stop — combat animations call `sampleHitStop(dt)` so impactful
  swings briefly slow time.
- FOV / shake — big impacts pair with `fovPulse(amount, dur)` and/or
  `shakeCamera(amount)` from camera.js.

---

## Animation taxonomy

| Kind           | Examples                                   | Lives in                                    |
|----------------|--------------------------------------------|---------------------------------------------|
| Locomotion     | walk, run, idle bob                        | `src/anim/<entity>.js` per-entity functions |
| Action         | swing, charge-up, recoil                   | `procedural.js` triggerSwing / triggerHurt  |
| Reaction       | hurt-flinch, death-fall, dodge-roll        | `procedural.js` trigger* helpers            |
| Channel        | mining swing, chopping swing, fishing cast | reuses swing animation; gameplay holds      |
| Effect / VFX   | sparks, telegraph rings, smoke             | `src/scene/sparks.js`, `telegraph.js`, etc. |
| Camera         | shake, fov pulse, hit-stop                 | `src/core/camera.js` + `hitstop.js`         |
| HUD / UI       | floating text, level-up burst              | `src/core/floaters.js` + DOM CSS keyframes  |

The data file `src/data/animations.js` declares one entry per
animation and tags it with one of these `kind` values so the codex
can filter.

---

## Status flags

Every entry in `src/data/animations.js` has a `status` field:

| Status      | Meaning                                                           |
|-------------|-------------------------------------------------------------------|
| `live`      | Currently in the game loop, called by gameplay code.              |
| `legacy`    | Still in the codebase but no longer triggered. Cleanup candidate. |
| `planned`   | Designed and named but not yet authored.                          |
| `broken`    | Authored but currently disabled (e.g. swap regression).           |

The codex Animations tab shows status as a colored chip so you can
scan what's missing.

---

## Pitfalls (learned)

1. **Re-parent before exporting** — sub-parts (eyes, fangs, hooves,
   tail tip) must be children of the right top-level group in
   Blender, otherwise procedural rotation leaves them behind.
   See `feedback_blender_bevel_pipeline.md`.
2. **Don't mix procedural + skinned on the same character.** Pick
   one. Mixing causes the procedural rotation to fight the bone
   transform and the rig looks broken.
3. **Hit-stop overrides dt.** If your animation needs a fixed
   cadence regardless of hit-stop (e.g. a falconer's wing flap),
   use `rawDt` instead of the loop's already-modulated `dt`.
4. **Crossfading from a stopped action** can look sticky — call
   `action.reset().play()` first to ensure it's "alive" before
   crossfade-to.
5. **Clone materials before tinting.** If two NPC instances share the
   cottage GLB, calling `.material.color.set()` on one tints both.
   Clone the material first (`o.material = m.clone()`).
