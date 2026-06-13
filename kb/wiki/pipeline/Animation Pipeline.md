---
type: pipeline
tags: [animation, procedural, skeletal, glb, tween, godot]
status: draft
updated: 2026-06-13
sources: ["docs/ANIMATION_PIPELINE.md", "docs/wyrd-animation-backlog.md", "docs/GODOT_PIPELINE.md", "docs/character-pipeline/MESHY_OPERATIONS.md"]
---

# Animation Pipeline

Wayfinder uses two animation strategies in parallel: **procedural** (default — per-frame rotation of named GLB groups driven by GDScript/JS state) and **skeletal** (Meshy-rigged clips played via Godot's `AnimationPlayer` or three.js `AnimationMixer`).

## The two strategies

### Procedural animation

Per-frame rotation of named empty objects in a GLB, driven by entity state (`moving`, `running`, `attackT`, `hurtT`). The animators live in `src/anim/<entity>.js` (three.js) or `wyrd/scripts/anim/` (Godot). Uses `spring1D` (three.js `procedural.js`) or Tween for smooth state transitions.

**When to use:** everything by default. Cheap, easy to retune, plays well with hit-stop and FOV pulses. No skeletal rigging required.

**Godot note:** the Ranger walks via a procedural cycle (`ranger_anim.gd` poses leg/arm bones each frame — the baked GLB clips are broken). The crypt rat hop-bobs procedurally too (`rat_anim.gd`) since Meshy cannot rig a quadruped.

### Skeletal animation (Meshy → Godot AnimationPlayer)

Full Meshy rig + clip pipeline for humanoid characters only:

1. Regenerate the character in Meshy with `pose_mode="t-pose"` (`meshy_image_to_3d` or `meshy_text_to_3d`). The source must be a Meshy-native generation — `clean_ai_mesh.py` low-poly GLBs fail Meshy's pose estimation.
2. Remesh if over 300K faces (`meshy_remesh`, target ~50K).
3. `meshy_rig` the model — includes walk + run clips free (5 credits).
4. `meshy_animate` with `action_id: 0` for Idle (3 credits). Check the Meshy Animation Library Reference for the full action list.
5. Download `Animation_<Name>_withSkin.glb` → save as `models/<name>_rigged.glb`.

`layout_loader.gd` in Godot prefers `<name>_rigged.glb` when it exists; `anim_driver.gd` finds the `AnimationPlayer`, matches the idle clip by case-insensitive substring, sets it looping, and plays it.

Probe a rigged GLB's clips headlessly:

```bash
godot --headless --path wyrd --script res://test_anim.gd
```

**Rule:** do not mix procedural + skeletal on the same character. Mixing causes the procedural rotation to fight the bone transform, and the rig looks broken.

## Process — every new animation

### 1. Design
Write down: who performs it, what action it accompanies, duration (attacks 0.2–0.5s, walks 0.6–1.2s, dodges 0.4s, hurts 0.25s), and the *feeling word* (tired / playful / menacing / frantic).

### 2. Reference
Pick one reference: a still frame, a 2-second video clip, or a verbal description. Save image refs to `docs/anim-refs/<name>.png`.

### 3. Author

**Procedural path (three.js):** edit `src/anim/<entity>.js`. Functions take `(mesh, entity, dt)` and rotate named subgroups. Drive amplitude off entity state.

**Procedural path (Godot):** edit `wyrd/scripts/anim/<entity>.gd`. Drawn-UI "animation" uses timed state + `queue_redraw` (the result-stamp pattern in `crafting_bench.gd`) — do not reach for AnimationPlayer in panels.

**Skeletal path:** author the clip in Blender against the GLB's armature. Name the action after its purpose (`Walk`, `Idle`, `Attack`). Export with `export_animations=True, export_skins=True, export_apply=True`. Load via `src/anim/clips.js` (three.js) or Godot's AnimationPlayer.

### 4. Wire
- (three.js) Register in `src/data/animations.js` (codex Animations tab). Set `status: 'live'` once in the game loop.
- (Godot) Wire the trigger at the gameplay site (`wyrd/scripts/`).
- For skeletal (three.js): `mixer.clipAction(clip).play()` on transition, `crossFadeTo(otherClip, dur)` to blend.

### 5. Polish
- Sound cue — every triggered animation gets an `sfx.<verb>()` call. Footsteps are tile-aware via `sfx.footstepOn(kind)`.
- Hit-stop — combat animations call `sampleHitStop(dt)` (three.js) or use the `Hitstop` autoload (Godot) for the time-freeze effect.
- FOV / shake — big impacts pair with `fovPulse(amount, dur)` and `shakeCamera(amount)`.

## Animation taxonomy

| Kind | Examples | Lives in |
|---|---|---|
| Locomotion | walk, run, idle bob | `src/anim/<entity>.js` or `wyrd/scripts/anim/` |
| Action | swing, charge-up, recoil | `procedural.js` trigger* helpers |
| Reaction | hurt-flinch, death-fall, dodge-roll | `procedural.js` trigger* helpers |
| Channel | mining swing, chopping swing, fishing cast | reuses swing animation |
| Effect / VFX | sparks, telegraph rings, smoke | `src/scene/sparks.js`, `telegraph.js`, `assets/vfx/` |
| Camera | shake, fov pulse, hit-stop | `src/core/camera.js` + `hitstop.js` |
| HUD / UI | floating text, level-up burst | `src/core/floaters.js` + DOM CSS; `queue_redraw` in Godot panels |

## Animation backlog (from `docs/wyrd-animation-backlog.md`, as of 2026-06-12)

### P1 — verbs players repeat constantly

| Interaction | Animation needed | Notes |
|---|---|---|
| Gather channel (mine/chop/forage) | Player swing/kneel poses per verb + tool in hand | Biggest gap: chibi stands while bar fills. Models for tools exist. Loop a swing every ~0.5s with hit-spark on node. |
| Quaff (Q) | Drink pose + bottle prop + green heal sparkle | Currently instant |
| Bench: socket snap | Dropped item scale-pop (0.9→1.05→1.0, ~120ms) | Fake with per-socket "pop" timer like result stamp |
| Bench: pot mix | Puff of steam + swirl + pot wobble on recipe complete | Tutorial's first magic moment |
| Bench: craft | Scroll rolls up + wax-seal press; replaces bare gold flash | Signature craft of the game |
| Chart socket at Waystone | Chart flies from case to stone; stone glow ramps | |

### P2 — combat reads

PiercingBolt pierce flash, RainOfThorns falling particles, boar charge dust trail, wolf pack-lunge afterimage, loadout swap slot-flip.

### P3 — ambient + UI polish

HP/Focus globe liquid slosh, tooltip fade/slide-in, craft station particle effects (cookfire bubbles, anvil embers), pack equip flash, cursor swaps.

## Common pitfalls

1. **Re-parent before exporting** — sub-parts (eyes, fangs, tail tip) must be children of the right top-level group in Blender. Procedural rotation leaves un-parented sub-parts behind.
2. **Don't mix procedural + skeletal** on the same character.
3. **Hit-stop overrides dt** — animations that need a fixed cadence regardless of hitstop should use `rawDt` (three.js).
4. **Crossfading from a stopped action** can look sticky — `action.reset().play()` before crossfade.
5. **Clone materials before tinting** — two instances of the same GLB share materials; calling `.material.color.set()` on one tints both. Clone first.

## Status flags (three.js `src/data/animations.js`)

| Status | Meaning |
|---|---|
| `live` | In the game loop, called by gameplay code |
| `legacy` | Still in codebase but no longer triggered — cleanup candidate |
| `planned` | Designed, not yet authored |
| `broken` | Authored but currently disabled |

## See also

- [[Blender Pipeline]] — how the GLB rigs are authored upstream
- [[Asset Pipeline]] — Meshy rigging steps and the `_rigged.glb` output
- [[Godot Pipeline]] — AnimationPlayer integration and `anim_driver.gd`
- [[Gathering]] — the channel interactions that need P1 animation work
- [[Skills]] — combat skills that need P2 VFX animations

## Sources

- `docs/ANIMATION_PIPELINE.md`
- `docs/wyrd-animation-backlog.md`
- `docs/GODOT_PIPELINE.md` (spec 11 — Meshy rig + idle; spec 18 — procedural walk)
- `docs/character-pipeline/MESHY_OPERATIONS.md` (Recipe B — bow-draw clip)
