# 23 — Fluid character movement + procedural animation (sandbox)

> **Outcome (plan)**: a clean **movement sandbox** — no dungeon — where the Ranger has *fluid* locomotion: walk, run, dash, roll, and a reworked fire, each with animation hooked up. The goal is to nail the moment-to-moment character feel in isolation before it goes back into the crypt.

## Why

The current player does two things — walk and fire — and both feel poor: the projectile "feels terrible," and movement is a flat single-speed slide. A cozy ARPG (Bramblewood — FATE/Diablo as the reference) lives or dies on how the character *moves*. This spec sets the dungeon aside (rooms, hallways, GLB walls — all deferred) and builds a focused sandbox to get walk / run / dash / roll / fire feeling fluid and responsive.

## Research findings (web + project probe)

- **Game feel** — modern ARPGs (Hades, Wolcen) set the bar with *responsive* dash/dodge: input registers instantly, the dodge interrupts whatever you were doing, and it has i-frames. Diablo-lineage games historically lacked free movement because they were mouse-built; adding sprint + dodge-roll is the modern upgrade. ([ResetEra — ARPG movement](https://www.resetera.com/threads/does-there-exist-an-arpg-with-fun-movement.281411/))
- **Godot animation** — the standard is an `AnimationTree` state machine + `BlendSpace` (walk↔run by speed), crossfades 0.15–0.25 s. ([Godot AnimationTree guide](https://godot-mcp.abyo.net/guides/godot4-animationtree), [Godot 4 Recipes](https://kidscancode.org/godot_recipes/4.x/3d/assets/character_animation/index.html))
- **Project probe — decisive**: *no Ranger GLB has working baked clips.* `npc_ranger_body_v3.glb` explodes the skeleton (spec 16), `ranger_anim_v1.glb` explodes worse (a bone flung 162 m), `green_ranger_anims.glb` is degenerate (all bones at origin, no mesh). **So `AnimationTree` + clips is off the table** — all animation is **procedural**, extending the spec-18 approach.

## Scope

**In:**

### A. Movement sandbox scene
- A `Sandbox.tscn` — a flat ground plane, the Ranger player, the ARPG camera rig, and 2–3 static target dummies for fire testing. No `layout_loader`, no procgen, no walls.
- Becomes the dev scene for movement work; `World.tscn` is untouched.

### B. Movement state machine
A code state machine on the player — `idle / walk / run / dash / roll` — with **fire** as an action layered on top (you can fire while moving). Responsiveness is the priority: dash and roll interrupt anything and fire on the frame they're pressed (input-buffered).
- **Walk / run** — run is the higher gear; walk a held modifier (see Open decisions).
- **Dash** — a short, fast directional burst on a cooldown; covers ground quickly, no i-frames.
- **Roll** — a dodge: a burst + an **i-frame window** + a tumble; the defensive option.
- **Fire** — reworked (Section D).

### C. Procedural animation — a state-driven animator
Grow `ranger_anim.gd` into a full procedural animator keyed off the state machine (the only viable path — no working clips):
- **idle** — a subtle breathing bob.
- **walk** — the spec-18 leg/arm cycle.
- **run** — a faster, larger cycle + a forward lean.
- **dash** — a hard brief forward lean.
- **roll** — a whole-mesh forward tumble (rotate the `Mesh` node 360° about local X over the roll's duration — easy + reads clearly procedurally).
- **fire** — an upper-body draw pose (arms pull the bowstring), layered so it overlaps locomotion.
- Ease between poses (the procedural equivalent of a crossfade).

### D. Projectile rework — fire that feels good
The arrow currently "feels terrible." Rework for game feel:
- Snappier arrow — faster travel, a clearer arrow visual, instant spawn (input buffer already in).
- Fire feedback — a small "pop" on release (bow flex / a brief muzzle flash / a light camera kick).
- Confirm the hit feedback (hitstop, spark) still reads.
- A fire pose (Section C) so firing has weight.

### E. Evals
A `test_movement.gd` headless harness: dash covers its distance in its window; roll grants i-frames for its window; state transitions fire correctly; fire still spawns an arrow ≤2 frames.

**Out (explicit non-goals):**
- The dungeon — procgen, room/hallway sizing, GLB-built walls. All deferred to a separate dungeon-rework spec (the user's "rooms too small / walls should use the GLB models" grievances are noted there, not here).
- Combat depth, enemy AI (dummies are static targets only).
- Jumping, vertical traversal, climbing.
- A Meshy regen of the Ranger (procedural is the chosen path).
- Multiplayer.

## Files (anticipated)

| Path | Action |
|---|---|
| `godot/scenes/Sandbox.tscn` | new — the movement test scene |
| `godot/scripts/player_controller.gd` | modify — the movement state machine |
| `godot/scripts/ranger_anim.gd` | modify — full state-driven procedural animator |
| `godot/scripts/arrow.gd` + `Arrow.tscn` | modify — projectile feel rework |
| `godot/test_movement.gd` | new — movement eval harness |
| `docs/GODOT_PIPELINE.md` | modify |

## Decisions (locked — the leans, accepted)

- **Run model** — **always-run; walk is a held modifier** (Shift). Cozy ARPGs keep you moving.
- **Dash trigger** — a **dedicated key** (e.g. Space or a side key); no double-tap.
- **Roll** — **~0.4 s i-frame window + a short cooldown.**
- **Dash AND roll** — **both.** Dash = a fast reposition (no i-frames); roll = the defensive i-frame dodge. Distinct keys.
- **Fire during roll/dash** — **locked out**; a fire press is buffered and fires when the roll/dash ends.
- **Stamina** — **none for v1** — dash/roll gated by cooldowns only. Stamina is a later layer.
- **Default keys** (programmatically bound, like the rest): walk-modifier Shift · dash Space · roll Ctrl (or right-click — tune in playtest) · fire F.

## Done check (this spec produces a *plan*; implementation is a later /spec)

- [x] Research — ARPG movement feel + Godot animation + the project clip probe
- [x] Animation strategy decided — procedural (no working baked clips exist)
- [x] Decisions locked (the leans, accepted)
- [ ] Sandbox scene + state machine + procedural animator + projectile rework
- [ ] `test_movement.gd` evals
- [ ] Play-test the feel

## References

- Spec 18 — `ranger_anim.gd`, the procedural walk cycle this extends
- Spec 16 — the broken-clip discovery
- Spec 14 — fluid-combat research (hitstop, input buffering) — the same feel bar
- `docs/WORLD_BIBLE.md` — Bramblewood tone (cozy, nimble, not grimdark)
